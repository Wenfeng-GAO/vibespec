# VibeSpec Change Router（变更路由器）设计

> 日期: 2026-06-24
> 状态: 设计完成，待实现
> 关联: `docs/agent-integration.md` §回退和失效（已有 CR/stale 规则但 skills 未实现）、Phase 4/5 的回退机制

## 1. 问题

VibeSpec 5 个 phase skill 都是"新建/推进"导向，硬约束禁止改上游产物（"不修改 PRD/DESIGN/TECH"）。但项目进行中**用户必然要改已确认的设计**——当前没有机制支持"改 X"这类变更，只能手改 artifact 乱状态，或绕过门禁。

`docs/agent-integration.md` §回退和失效 已经定义了协议层规则（CR 结构、stale cascade），但**没有任何 skill 实现它**，且协议要求用户自己懂该回退到哪层。

**核心诉求（用户）**: 用户只说明修改需求（"我想让模型能配多个网关"），VibeSpec 自己判断回退到哪层、生成 CR、cascade stale、指引重做。

## 2. 设计决策（brainstorming 四问四答）

1. **形态**: 独立 skill `vibespec-change`（变更路由器），不融入现有 phase。变更判断是横切所有阶段的元操作，与 Phase 5 的"验证触发下游修复"(FT/阶段往返) 解耦——change = 用户主动改上游；Phase 5 FT = 验证发现被动修下游。触发源不同，分开。
2. **分层判定**: agent 读"改 X" + 全部已确认 artifact，**语义匹配**命中哪层（PRD/DESIGN/TECH/TASKS/VERIFY），**输出判定依据**（命中哪个 artifact 的哪节）供用户否决。继承 Phase 4/5 的"机械化判定 + 可审查"哲学。
3. **跨层处理**: 一个变更意图 = 一个 CR，**入口取最高上游层**（DESIGN+TECH 命中 → 入口 P2）。单向依赖链决定上游变连带下游重做，从最高上游一次到位。CR 记 `affectedPhases` 全集。
4. **重做粒度**: **增量重做**——只改受影响 artifact 节，未触及部分标 unchanged 保留。CR 记 `changedSections`，重做后该 phase 只对 changedSections 局部确认，而非整文档重确认。与 PRD/DESIGN skill 现有"分节确认"机制兼容。

## 3. 与现有回退机制的关系（重要边界）

| 机制 | 触发源 | 方向 | 走哪个 skill |
|------|--------|------|-------------|
| **Change Router**（本设计） | 用户主动改设计/需求 | 上游回退（P5→P1/2/3） | `vibespec-change` |
| Phase 5 阶段往返 | VT 判 defect | 下游修复（P5→P4→P5） | `phase5-verify` 内 FT |
| Phase 4 Step 3.5 rescope | task 内实现错位 | task 边界修正 | `phase4-implement` 内 |

三者触发源、方向、归属不同，互不替代。Change Router 是唯一处理**用户主动变更上游**的入口。

## 4. Change Router 执行流程

```
用户: "改 X"  (调用 vibespec-change，args = 变更描述)
  Step 0: 加载 state.json + 全部已确认 artifact
  Step 1: 语义分层判定
  Step 2: 生成 CR + cascade stale + 确定入口
  Step 3: 用户确认判定（可否决/修正回退层）
  Step 4: 交还控制——指引重做入口 phase 的受影响节
```

### Step 0: 加载上下文

读 `.vibespec/state.json`（确认哪几层已 confirmed）+ 已确认的 PRD/DESIGN/TECH/TASKS/VERIFY。若无可确认 artifact → 提示"尚无已确认产物，无需变更路由，直接走对应 phase"。

### Step 1: 语义分层判定

agent 对照"改 X"与各 artifact 内容，按以下判据匹配（机械化，输出依据）:

| 命中 artifact 节 | 回退入口 |
|------------------|----------|
| PRD: 功能需求/目标用户/场景/成功标准/不做什么 | Phase 1 |
| DESIGN: 路由表/页面清单/组件树/交互状态/数据流向/视觉方向 | Phase 2 |
| TECH: 技术栈/目录结构/数据模型/API 契约/依赖/安全边界 | Phase 3 |
| 已实现代码的 bug/占位/回归 | 留 Phase 4（FT，非上游回退） |
| 验证维度的缺口 | 留 Phase 5（VT/FT，非上游回退） |

**判定依据必须透明**: skill 输出"命中 PRD§功能需求 R2 / DESIGN§路由表 / TECH§API契约"这类具体节引用，而非笼统"回 Phase 2"。

**跨层**: 若命中多层，入口取最高上游层，CR.affectedPhases 记全部命中层。

**模糊兜底**: 若 agent 无法明确分层（如"模型配置"可能 DESIGN 设置页也可能 TECH 契约），**列出候选层 + 各自依据**，让用户在 Step 3 选，不强行猜。

### Step 2: 生成 CR + cascade stale

写入 `.vibespec/change-requests/CR{N}.json`:

```json
{
  "id": "CR1",
  "createdAt": "ISO8601",
  "reason": "用户变更: {改 X 描述}",
  "changeIntent": "{agent 归纳的变更意图}",
  "affectedPhases": ["design", "tech"],
  "entryPhase": "design",
  "changedSections": {
    "design": ["路由表", "页面清单"],
    "tech": ["API契约", "安全边界"]
  },
  "staleArtifacts": ["TECH.md", "TASKS.md", "VERIFY.md"],
  "blockingCurrentWork": false,
  "status": "pending-confirm"
}
```

**Stale cascade**（实现 agent-integration §回退和失效 规则）:
- 改 PRD → DESIGN/TECH/TASKS/VERIFY stale
- 改 DESIGN → TECH/TASKS/VERIFY stale
- 改 TECH → TASKS/VERIFY stale
- 改 TASKS → VERIFY stale

在 state.json 各 phase 段加 `stale: true` + `staleReason: "CR1"` + `staleSince: ISO8601`。stale phase 不允许推进/确认，必须先解 CR。

### Step 3: 用户确认判定

向用户呈现:
```
变更意图: {归纳}
判定回退入口: Phase {N}（{层名}）
判定依据: 命中 {artifact}§{节}
受影响层: {affectedPhases}
将标记 stale: {staleArtifacts}

确认此回退判定？(可修正层 / 否决 / 调整 changedSections)
```

用户可:
- **确认** → CR.status = "confirmed"，进入 Step 4
- **修正回退层** → 改 entryPhase/affectedPhases（如 agent 判 P2，用户说其实是 P3）
- **否决** → CR.status = "rejected"，不 cascade，归档

### Step 4: 交还控制——增量重做指引

CR confirmed 后，skill **不自己重做**（重做是各 phase skill 的职责），而是:
1. 标入口 phase 状态为 `stale-needs-revision`（区别于"未开始"）
2. 指引用户调用入口 phase skill 重做 changedSections:
   ```
   请回 Phase {N} 重做以下节（其余 unchanged 保留）:
     - {节1}
     - {节2}
   完成后该 phase 只对这些节局部确认。
   确认后，staleArtifacts（{list}）需在各自 phase 重新核验受影响部分。
   ```

各 phase skill 需在 Step 0 增 **CR 感知**（见 §5）：检测是否有 confirmed CR 以本 phase 为入口 → 只重做 changedSections[本phase] → 局部确认而非全量。

## 5. 现有 phase skill 需要的最小改动（CR 感知）

每个 phase skill 的 Step 0 加一段:

```
检查 .vibespec/change-requests/ 是否有 status=confirmed 且 entryPhase=本phase 的 CR:
- 有 → 进入"变更重做模式": 只改 CR.changedSections[本phase] 列出的节，
       未列出的节标 unchanged 跳过；确认时只对 changedSections 局部确认，
       确认后该 phase stale 解除，CR.status → "phase-revised"
- 无 → 正常新建/推进流程（现有逻辑不变）
```

同时各 phase Step 0 检查 `state.json.phases.{本phase}.stale === true`:
- stale 且非入口 → 阻止推进，提示"因 CR{N} 标记 stale，需待入口 phase 重做完成后回来核验"
- stale 且是入口 → 进入变更重做模式

**改动量**: 5 个 phase skill 各加 ~15 行 CR 感知段，不破坏现有线性流程。

## 6. state.json 扩展

```json
{
  "phases": {
    "design": {
      "status": "stale-needs-revision",
      "stale": true,
      "staleReason": "CR1",
      "staleSince": "ISO8601",
      "artifact": "docs/.../DESIGN.md",
      "activeCR": "CR1",
      "changedSections": ["路由表", "页面清单"]
    }
  },
  "changeRequests": {
    "CR1": { "status": "confirmed | phase-revised | rejected", ... }
  }
}
```

stale 语义: `stale=true` 阻止该 phase 推进/确认；入口 phase 重做确认后 `stale` 转 false、CR 转 `phase-revised`，受影响下游 phase 仍 stale 直到各自核验。

## 7. 约束与边界（反模式防御）

1. **不绕过门禁**: CR 确认 ≠ 跳过重做。改了 PRD 仍须重新确认 PRD，不能"CR 批了就当 TECH 也对"。
2. **不手改状态**: 用户不许直接编辑 state.json stale 字段，必须经 change router 生成 CR。
3. **判定必须给依据**: 不许"回 Phase 2"无依据输出；必须指到 artifact 节。
4. **增量不误伤**: 未列入 changedSections 的节原样保留，agent 不得借重做之机改无关内容。
5. **CR 可追溯**: CR 永久存档（含 rejected），便于审计变更历史。
6. **不替代 Phase 5 回退**: 验证缺口走 Phase 5 的 defect/FT，不走 change router（除非用户明确要改验证标准本身的设计）。

## 8. 不做（YAGNI）

- 不做 CR 之间的依赖图（一个 CR 一个变更意图，复杂链式变更拆多个 CR）。
- 不做自动重做（agent 不替用户改 artifact，只判定+指引）。
- 不做 CR 合并/拆分编辑器（MVP 一个 CR 一个意图）。
- 不做 stale 的细粒度节级标记（粒度到 phase + changedSections 名单，不到单节 stale）。

## 9. 落地计划

1. 新建 `skills/vibespec-change/SKILL.md`（change router 主体，§4 流程）。
2. 5 个 phase skill 各加 Step 0 CR 感知段（§5）。
3. state.json 扩展字段（§6）—— 各 phase skill 引用 `stale`/`activeCR`。
4. 端到端验证: 用 CouncilKit 的"模型配置可配网关"变更跑一次 change router（CR → cascade → 回 Phase 3 改 TECH → 重验），验证 §3 的边界不与 Phase 5 冲突。
5. 验证发现回灌 SKILL（与 Phase 4/5 同样闭环）。

## 10. 与 CouncilKit 当前场景的关系

你之前问的"模型配置走哪层"——若 change router 已实现，流程会是:
- 你调 `vibespec-change "让模型能配多个 Anthropic 兼容网关"`
- Step 1 判定: 命中 TECH§API契约 + TECH§技术决策（base_url 可配）→ 入口 Phase 3（也可能命中 DESIGN 若要设置页 UI）
- 生成 CR1，TASKS.md/VERIFY.md stale
- 指引: 回 Phase 3 改 TECH§API契约/技术决策 → 局部确认 → Phase 4 改 `claude.ts`(FT) → Phase 5 重验

这正是 §9.4 的验证场景。
