# VibeSpec Change Router（变更路由器）设计 v2

> 日期: 2026-06-24（v2，按 document-review 5-persona 对抗审查修订）
> 状态: 设计完成（MVP 主线），待实现
> 关联: `docs/agent-integration.md` §回退和失效（协议层 CR/stale 规则，本设计落地为 skill）
> 审查: v1 经 coherence/feasibility/product-lens/scope-guardian/adversarial 五人审查，主要修订见 §11 变更日志

## 1. 问题与前提修正

**问题**：VibeSpec 5 个 phase skill 都是"新建/推进"导向，硬约束禁止改上游产物。但项目进行中用户必然要改已确认设计——当前无机制，只能手改 artifact 乱状态或绕过门禁。`agent-integration.md` §回退和失效 已定义协议层 CR/stale 规则，但无 skill 实现。

**前提修正（v2，来自 product-lens/adversarial 审查）**：
v1 把核心价值押在"自动判层"。审查指出：能说"改 X"的用户几乎总是**已经知道** X 属于需求/设计/技术层（他们写了那些 artifact）；真正痛点是"cascade + 安全重确认"的繁琐。§10 v1 例子自证——"让模型配网关"秒 match TECH，因用户本就知道。

→ **v2 调整**：自动判层降为 P1（验证后视需要再做）。MVP 主路径是**用户显式声明层**，skill 核心价值 = cascade stale + 安全增量重确认 + CR 追溯。这与 agent-integration 协议层"用户该自己懂层"的现实一致，且把高风险的 LLM 分类后置。

## 2. 与现有回退机制的关系（边界）

| 机制 | 触发源 | 作用对象 | 走哪个 skill |
|------|--------|----------|-------------|
| **Change Router**（本设计） | 用户主动改**已确认产物**（PRD/DESIGN/TECH/已实现代码契约） | 上游 artifact + 连带 cascade | `vibespec-change` |
| Phase 5 阶段往返 | VT 判 defect | 已实现代码（FT） | `phase5-verify` 内 |
| Phase 4 Step 3.5 rescope | task 内实现错位 | task 边界 | `phase4-implement` 内 |

注：v1 "上游/下游方向"列误导（两者都向低 P 号回退）。真正区分是**触发源 + 作用对象**：Change Router 改 artifact 层，Phase 5 FT 改代码层。两者共享 state.json，故需 §7 优先级规则避免冲突。

## 3. 两阶段演进

### MVP（先做，低风险高杠杆）

- §5 phase skill 的 **CR 感知 + stale 机制**（含下游 re-verify 分支与状态转换，修 M1）
- §6 state.json stale 扩展
- cascade **含 `phases.implement`**（修 M2）：改 TECH/DESIGN 触发代码契约 stale，CR 直接驱动 FT（不依赖 Phase 5 判 defect）
- **phase 级粒度**：无 changedSections（砍 M3），整 phase 重做或整 phase 重核验
- **禁并发 CR + 排队**（修 M4）
- 最小 `vibespec-change`：**用户显式 `--phase`**（接 §1 前提修正，不做自动判层）
- CR vs VT 优先级（修 M6）

### P1（MVP 验证后视需要做）

- §4 Step 1 语义自动判层（仅当 MVP 验证发现用户真判不准层，且数据支持时才做）
- 多层命中的入口策略 + 中途收窄阀（修 M5）

## 4. Change Router 执行流程（MVP，显式声明层）

```
用户: vibespec-change --phase=<N> "变更描述"
  Step 0: 加载 state.json + 全部已确认 artifact + 检查并发 CR
  Step 1: 记录 CR（显式层，不自动判）
  Step 2: cascade stale（含 implement）+ 禁并发检查
  Step 3: 用户确认 CR（可否决/修正层）
  Step 4: 交还控制——指引入口 phase 重做 + 后续 re-verify 链
```

### Step 0: 加载上下文

读 state.json（确认已 confirmed 层）+ 已确认 artifact。检查是否有未关闭 CR：
- 有 `status != closed` 的 CR → **拒绝新 CR**（修 M4 禁并发），提示"先关闭 CR{N}（完成或 reject）再发起新变更"。这是 MVP 排队规则，简单可靠。

若无可确认 artifact → 提示"尚无已确认产物，直接走对应 phase"。

### Step 1: 记录 CR（不自动判层）

用户 `--phase=N` 显式声明入口。CR 记录入口层（不判定，用户已给）。skill 仍读对应 artifact 内容，**仅作"变更描述 vs 声明层"的合理性提示**（如用户声明 TECH 但描述明显是产品功能 → 提示"描述更像 PRD 变更，确认入口是 TECH？"，用户可坚持）。这是廉价纠偏，非自动判层——决定权在用户。

### Step 2: cascade stale（含 implement）

按 agent-integration §回退和失效 规则 + **关键补充：代码层**：

| 入口改动 | stale cascade 目标 |
|----------|-------------------|
| PRD | DESIGN / TECH / TASKS / VERIFY |
| DESIGN | TECH / TASKS / VERIFY |
| TECH | TASKS / VERIFY + **`phases.implement`（已实现代码契约）** |
| 已实现代码的契约改动 | 视入口而定 |

**修 M2 关键**：改 TECH 时，`phases.implement.status` 标 `stale-code-contract` + staleReason=CR。Phase 4 Step 0 检测到此状态 → 需核对已实现代码是否仍满足新 TECH，受影响 task 转 `pending-revision`，CR 驱动生成 FT（**不依赖 Phase 5 判 defect**）。这是 CR → 代码的直连路径，修 v1 的 silent-inconsistency。

在 state.json 各受影响 phase 加 `stale: true` + `staleReason: "CR{N}"` + `staleSince`。stale phase 不允许推进/确认。

### Step 3: 用户确认 CR

```
变更: {描述}
入口: Phase {N}（{层}）
受影响将 stale: {cascade 列表，含 implement 若 TECH}
{若 Step 1 有合理性提示，附上}
确认？(确认 / 修正入口层 / 否决)
```

- 确认 → CR.status = "confirmed"，进入 Step 4
- 修正层 → 改 entryPhase，重算 cascade
- 否决 → CR.status = "rejected"（归档），不动 state

### Step 4: 交还控制

CR confirmed 后，skill **不自己重做**。set 入口 phase `status = "stale-needs-revision"`（见 §6 状态语义），指引:

```
回 Phase {N} 重做受影响 artifact（整 phase 重做，phase 级粒度）。
完成后该 phase 局部重确认 → stale 解除。
随后按依赖链 re-verify 下游:
  {cascade 列表} 各自在对应 phase 跑 re-verify（见 §5 第三分支）。
全部 re-verify 完成且 stale 清除 → CR.status = "closed"。
```

## 5. 现有 phase skill 的 CR 感知改动（修 M1）

每个 phase skill Step 0 加 stale/CR 检测，**三个分支**（v1 只有两个，缺下游 re-verify 分支，导致 M1 死锁）:

```
检查 phases.{本phase}:
1. stale=false 且无 activeCR → 正常推进（现有逻辑）
2. stale=true 且是 CR 入口 (entryPhase==本phase) → 变更重做模式:
   重做 artifact，局部重确认，确认后本 phase stale=false，CR 转 phase-revised
3. stale=true 且非入口 (受影响下游) 且 CR.status==phase-revised → re-verify 模式:  ← 修 M1 的关键分支
   核对本 phase artifact 与上游修订是否仍一致，
   一致 → stale=false；不一致 → 触发本 phase 重做（退回分支2语义）
4. stale=true 且非入口 且 CR 仍 confirmed(入口未完成) → 阻止推进，提示等待
```

分支 3 是 v1 缺失的"下游解除 stale"路径。其 re-verify 内容: phase 级粒度——核对本 phase 整个 artifact 与修订后的上游一致性，不依赖节级标记（砍 changedSections）。

Phase 4 特殊: 分支2/3 对应"核对已实现代码 vs 新 TECH"（修 M2），受影响 task 转 pending-revision，CR 驱动 FT。

**改动量**: 5 phase skill 各加 ~20 行四分支 stale 检测。

## 6. state.json 扩展

```json
{
  "phases": {
    "tech": {
      "status": "stale-needs-revision",
      "stale": true,
      "staleReason": "CR1",
      "staleSince": "ISO8601"
    },
    "implement": {
      "status": "stale-code-contract",
      "stale": true,
      "staleReason": "CR1",
      "staleCodeContractTasks": ["T5"]
    }
  },
  "changeRequests": {
    "CR1": {
      "id": "CR1",
      "createdAt": "ISO8601",
      "reason": "用户变更: {描述}",
      "entryPhase": "tech",
      "affectedPhases": ["tech", "implement", "verify"],
      "status": "confirmed | phase-revised | closed | rejected",
      "confirmedAt": "ISO8601"
    }
  }
}
```

**status 状态机**（修 M1 + CR 终态）:
```
phase.status: ... | stale-needs-revision(入口待重做) | stale-pending(下游待入口完成) | stale-verify(下游可 re-verify)
CR.status:    pending-confirm → confirmed → phase-revised(入口完成) → closed(全部 re-verify 完成)
                   ↘ rejected(否决归档)
```

stale 清除规则:
- 入口 phase: 重做+重确认 → 本 phase stale=false，CR→phase-revised
- 下游 phase: CR.phase-revised 后进入 re-verify 模式(§5分支3) → 核验通过 stale=false
- CR.closed: 所有 affectedPhases 的 stale 都清 false 时，CR→closed

**砍掉的 v1 字段**（scope 审查）: `changeIntent`(并入 reason)、`staleArtifacts`(可派生)、`blockingCurrentWork`(无用)、`changedSections`(砍 M3)、单值 `activeCR`(改禁并发，CR.id 直接查)。

## 7. CR vs VT 优先级（修 M6）

CR 与 Phase 5 VT 共享 state。冲突场景: CR 标 VERIFY stale，同时 Phase 5 VT 想确认 VERIFY。规则:

1. **有未 closed 的 CR 涉及某 phase** → 该 phase 的 Phase 5 VT **暂停**（不确认 VERIFY），先走 CR re-verify。
2. CR re-verify 完成清除 stale 后，Phase 5 可继续。
3. 若 CR re-verify 发现代码不一致 → 走 §5 分支3 退回重做，不掺 Phase 5 的 defect 判定。

一句话: **CR 优先，VT 让位**。CR 是主动变更通道，VT 是被动验证；主动变更进行中时，验证结果可能基于旧 artifact，故暂停 VT 等通道清空。

## 8. 约束与反模式防御

1. **不绕门禁**: CR 确认 ≠ 跳过重做。改 PRD 仍须重确认 PRD。
2. **不手改 stale 状态**: 须经 change router 生成 CR。（注: v1 此条未强制；MVP 现实承认——MVP 无 TS validator，靠 skill 自律 + 后续 validator 补强。审查 feasibility #5 已指出，记为已知限制。）
3. **不并发 CR**: 一次一个未 closed CR（修 M4）。
4. **CR 可追溯**: 含 rejected 永久归档。
5. **不替代 Phase 5**: 代码 defect 走 Phase 5 FT；但 CR 驱动的契约变更走 §5 分支3+implement stale（修 M2，两者分别有路径）。
6. **CR 优先 VT**: §7。

## 9. 不做（YAGNI，v2 收紧）

- 不做自动判层（P1 视需要）
- 不做 changedSections / 节级 stale（砍 M3，phase 级粒度）
- 不做并发 CR / CR 依赖图（禁并发，修 M4）
- 不做中途收窄阀（P1，M5）
- 不做自动重做（agent 只判定+指引）

## 10. 落地计划（v2 重排，MVP 优先）

**MVP**:
1. `skills/vibespec-change/SKILL.md`（§4 显式 --phase 流程，无自动判层）
2. 5 phase skill 各加 §5 四分支 stale 检测（~20行）
3. state.json §6 扩展（含 implement stale-code-contract）
4. 端到端验证: CouncilKit "模型 endpoint 可配" — `vibespec-change --phase=tech "模型 base_url 可配，复用 Anthropic 兼容网关"` → cascade verify+implement stale → 回 Phase3 改 TECH → Phase4 FT 改 claude.ts → re-verify → CR closed。**一举两得：验证 MVP + 完成你要的模型配置改动**。
5. 验证发现回灌 SKILL

**P1（MVP 验证 2 轮后视数据决定）**:
6. §4 Step 1 语义自动判层（仅当用户真判不准层数据支持时）
7. M5 多层入口策略 + 中途收窄阀
8. TS validator 真正强制 stale 门禁（补 feasibility #5）

## 11. v1→v2 变更日志（审查响应）

| 审查发现 | v2 响应 |
|---------|---------|
| S1 前提错（自动判层非痛点）| §1 前提修正；自动判层降 P1，MVP 显式 --phase |
| S2 顺序倒置 | §3/§10 重排，stale 机制(§5/§6)优先 |
| M1 下游永久死锁 | §5 加分支3 + §6 状态机 + CR closed 终态 |
| M2 代码不进 cascade | §2/§5/§6 cascade 含 implement + stale-code-contract + CR 驱动 FT |
| M3 changedSections 矛盾脆弱 | 全砍，phase 级粒度 |
| M4 单值 activeCR | 禁并发 CR + 排队 |
| M5 最高上游放大误判 + §10 矛盾 | MVP 无多层判定（显式单层）；P1 处理 |
| M6 CR/VT 共享 state 死锁 | §7 CR 优先 VT 让位 |
| 冗余字段 | §6 砍 changeIntent/staleArtifacts/blockingCurrentWork/changedSections |
| stale-needs-revision 与 entryPhase 重复 | 保留为入口 phase 状态值，下游用 stale-pending/stale-verify 区分（§6 状态机） |
| FT/VT 未定义 | 本设计内明确: FT=代码修复 task，VT=验证维度(继承 Phase 5) |
| §3 方向列误导 | §2 改为"作用对象"列 |
| CR 无终态 | §6 加 closed 终态 |
| §7.2 不手改状态未强制 | §8.2 承认 MVP 靠自律，validator 后置 P1 |

## 12. 与 CouncilKit 模型配置场景

MVP 实现后流程:
- `vibespec-change --phase=tech "模型 endpoint base_url 可配，复用 Anthropic 兼容网关（cld provider）"`
- Step 2: cascade → verify + **implement stale-code-contract**（修 M2 后，T5 的 claude.ts 会被标待核对）
- Step 3: 确认 → 回 Phase 3 改 TECH§API契约/技术决策（phase 级，整 TECH 重核验）
- Phase 4: 分支3 核对 claude.ts vs 新 TECH → 改 base_url 可配 → FT 通过
- re-verify verify → CR closed
- 顺带完成你要的模型配置改动
