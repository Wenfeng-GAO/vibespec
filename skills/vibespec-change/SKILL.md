---
name: vibespec-change
description: VibeSpec 变更路由器 - 当用户要修改已确认的产物(PRD/DESIGN/TECH/已实现代码契约)时，显式声明入口层，生成 change request(CR)、cascade stale(含已实现代码)、指引增量重做与下游 re-verify。禁并发 CR，CR 优先于 Phase 5 VT。用于在守门禁前提下安全回退到上游 phase 修订。
argument-hint: "--phase=<define|design|tech> \"变更描述\""
---

# VibeSpec Change Router: 变更路由器

## 核心定位

你是 VibeSpec 的变更路由器，处理**用户主动修改已确认产物**的场景。当项目进行中需要改 PRD/DESIGN/TECH（或已实现代码契约）时，本 skill 生成 change request(CR)、cascade stale、指引用户回上游 phase 重做并 re-verify 下游——在守门禁前提下让"改设计"可恢复、可检查、可追溯。

本 skill 与现有机制的边界:

| 机制 | 触发源 | 作用对象 | 归属 |
|------|--------|----------|------|
| **Change Router（本 skill）** | 用户主动改已确认产物 | 上游 artifact + 连带 cascade | `vibespec-change` |
| Phase 5 阶段往返 | VT 判 defect | 已实现代码（FT） | `phase5-verify` 内 |
| Phase 4 Step 3.5 rescope | task 内实现错位 | task 边界 | `phase4-implement` 内 |

Change Router 改 **artifact 层**（PRD/DESIGN/TECH），Phase 5 FT 改**代码层**。两者共享 state.json，故 §7 定 CR 优先 VT。

## MVP 设计说明

本 skill 为 MVP：**用户显式声明入口层**（`--phase`），不做自动判层。理由：能说"改 X"的用户通常已知 X 属于哪层；真正痛点是 cascade + 安全重确认，而非"不知层"。自动判层为 P1，待 MVP 验证数据支持后再做。

## 输入与产物

### 输入

- `--phase=<define|design|tech>`：用户显式声明的入口层（必填）
- 变更描述（自然语言）
- `.vibespec/state.json`（已有确认状态 + 是否有未关闭 CR）
- 已确认的 PRD/DESIGN/TECH（按入口层读对应及上游）

### 产物

- `.vibespec/change-requests/CR{N}.json`：变更请求记录
- `.vibespec/state.json`：受影响 phase 标 stale；入口 phase 标 `stale-needs-revision`；若入口为 tech，`phases.implement` 标 `stale-code-contract`

## 硬约束

1. **必填入口层**。无 `--phase` 不前进（MVP 不自动判层）。
2. **禁并发 CR**。state.json 中存在 `status != closed && status != rejected` 的 CR 时，拒绝新 CR，提示先关闭现有 CR。
3. **不自动重做**。本 skill 只生成 CR + cascade stale + 指引；重做是各 phase skill 的职责。
4. **不手改 stale**。stale 状态只能由 change router 生成 CR 时设置、由各 phase re-verify 通过时清除。（MVP 靠 skill 自律；TS validator 强制为 P1）
5. **CR 必给依据**。CR 记录入口层 + cascade 列表 + 变更描述；若合理性提示被触发（§4 Step1），记提示与用户选择。
6. **CR 优先 VT**。有未 closed CR 涉及某 phase 时，该 phase 的 Phase 5 VT 暂停（§7）。

## 交互规则

- 显式确认制: Step 3 必须用户确认 CR 才 cascade。否决则 CR rejected 归档，不动 state。
- 合理性质疑不等于否决: Step 1 若发现"声明层 vs 描述"不符，提示但用户可坚持。
- 不诊断: 本 skill 不评判变更对错，只路由。

## 执行流程

### Step 0: 加载上下文 + 并发检查

1. 读 `.vibespec/state.json`
2. 检查 `changeRequests` 是否有 `status != closed && status != rejected` 的 CR:
   - 有 → 拒绝: "存在未关闭 CR{N}（status={status}）。请先完成或 reject 它再发起新变更。" 停止。
3. 读已确认的 PRD/DESIGN/TECH（入口层及其上游；下游暂不读，cascade 时按层算）
4. 确定下一个 CR 编号（CR1, CR2...）

#### Step 0 完成标准
- 无并发 CR
- 入口层已明确
- PRD/DESIGN/TECH 按需读取

### Step 1: 合理性提示（不判层，只纠偏）

入口层由用户 `--phase` 给定，本 skill 不改判。但读入口层 artifact 内容，做一次廉价纠偏:

- 若用户声明 `--phase=tech` 但变更描述明显是产品功能/需求（含"加功能""改目标用户""新增 P0"等）→ 提示: "描述更像 PRD 变更，确认入口是 TECH？"
- 若声明 `--phase=define` 但描述明显是技术细节（含"改 API""换依赖""目录结构"）→ 提示: "描述更像 TECH 变更，确认入口是 DEFINE？"
- 提示仅为提醒，**用户可坚持原声明**

记录提示与否、用户选择，写入 CR。

#### Step 1 完成标准
- 入口层 confirmed（用户坚持或修正后）
- 若有提示，已记录

### Step 2: 计算 cascade stale

按入口层算受影响 phase（含 implement，关键）:

| 入口 | stale cascade 目标 |
|------|-------------------|
| define | design / tech / implement / verify |
| design | tech / implement / verify |
| tech | implement / verify |

> 注: cascade 含 `phases.implement`（M2 修复）。改 TECH 时，已实现代码契约可能失效——`phases.implement` 标 `stale-code-contract`，Phase 4 据此核对代码 vs 新 TECH，受影响 task 转 `pending-revision`，**CR 驱动 FT**（不依赖 Phase 5 判 defect）。改 DESIGN/PRD 同理波及 implement（页面/数据模型变则代码变）。

#### Step 2 完成标准
- cascade 列表已算（含 implement 若入口非 define 上游无代码；实际 implement 总在 cascade 内，因为代码总依赖最上游产物）

### Step 3: 用户确认 CR

向用户呈现:
```
变更: {描述}
入口: Phase {N}（{层}）
{若 Step1 有提示: 提示内容 + 用户已选择}
将标记 stale: {cascade 列表，含 implement}
入口 phase 将进入 stale-needs-revision（待重做）

确认此变更路由？(确认 / 修正入口层 / 否决)
```

- **确认** → CR.status = "confirmed"；写 CR.json；按 §Step4 cascade state；停止，交还控制
- **修正入口层** → 用户给新 `--phase`，回 Step 1
- **否决** → CR.status = "rejected"，归档，不动 state，停止

#### Step 3 完成标准
- CR.json 已写（含 id/reason/entryPhase/affectedPhases/status=confirmed）
- 或 CR rejected 归档

### Step 4: cascade stale + 交还控制

CR confirmed 后:

1. 写 state.json:
   - 入口 phase: `status = "stale-needs-revision"`, `stale = true`, `staleReason = "CR{N}"`, `staleSince`
   - cascade 下游 phase: `status = "stale-pending"`, `stale = true`, `staleReason = "CR{N}"`
   - 若入口含 tech → `phases.implement`: `status = "stale-code-contract"`, `stale = true`（与下游 verify 同样 stale-pending）

2. 指引用户:
```
CR{N} 已确认。变更路由完成。

回 Phase {N} 重做 {入口 artifact}（phase 级，整 artifact 重核验）。
  → 调用 phase{N} skill，它会检测到 stale-needs-revision 进入变更重做模式。
  → 重做 + 局部重确认后，本 phase stale 清除，CR{N} → phase-revised。

随后按依赖链 re-verify 下游（phase skill 会自动进入 re-verify 模式）:
  {cascade 下游列表}
  → 各 phase 核对本 artifact 与修订后上游一致性。
  → 一致 → stale 清除；不一致 → 触发本 phase 重做。

全部 re-verify 完成且 stale 清除 → CR{N} → closed。

{若 implement 在 cascade: "Phase 4 将核对已实现代码 vs 新 {入口}，受影响 task 转 pending-revision，CR 驱动 FT 修复。"}
```

停止。本 skill 职责结束，控制交还用户调用对应 phase。

## state.json 扩展（Change Router 增量）

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
      "staleCodeContractTasks": []
    },
    "verify": {
      "status": "stale-pending",
      "stale": true,
      "staleReason": "CR1"
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

**phase.status 状态机**:
- `stale-needs-revision`：入口 phase，待重做（CR confirmed 后）
- `stale-pending`：下游 phase，待入口完成（CR confirmed，入口未 phase-revised）
- `stale-verify`：下游 phase，可 re-verify（CR phase-revised 后，§5 分支3）
- `stale-code-contract`：implement 专属，核对代码 vs 新上游（同 stale-verify 语义但触发 FT）

**CR.status 状态机**:
```
pending-confirm → confirmed → phase-revised(入口重做完成) → closed(全部 re-verify 完成)
                   ↘ rejected(否决归档)
```

stale 清除规则:
- 入口 phase: 重做+重确认 → stale=false，CR→phase-revised，下游 phase 转 stale-verify
- 下游 phase: CR.phase-revised 后进入 re-verify（phase skill §5 分支3）→ 核验通过 stale=false
- CR.closed: 所有 affectedPhases stale 清 false 时，CR→closed

## §5 各 phase skill 的四分支 stale 检测（本 skill 依赖）

phase skill Step 0 检查 `phases.{本phase}`:
1. `stale=false` 且无 active CR → 正常推进
2. `stale=true` 且是 CR 入口（`CR.entryPhase == 本phase`）→ 变更重做模式: 重做 artifact + 局部重确认 → stale=false，CR→phase-revised
3. `stale=true` 且非入口 且 `CR.status == phase-revised` → re-verify 模式: 核对本 artifact vs 修订后上游 → 一致 stale=false / 不一致退回重做
4. `stale=true` 且非入口 且 `CR.status == confirmed`（入口未完成）→ 阻止，提示等待

Phase 4 特殊: 分支2/3 对应"核对已实现代码 vs 新 TECH/DESIGN/PRD"，受影响 task 转 `pending-revision`，CR 驱动 FT。

## §7 CR vs VT 优先级

CR 与 Phase 5 VT 共享 state。冲突场景: CR 标 verify stale，同时 Phase 5 VT 想确认 VERIFY。规则:

1. 有未 closed CR 涉及某 phase → 该 phase 的 Phase 5 VT **暂停**（不确认 VERIFY），先走 CR re-verify。
2. CR re-verify 完成（stale 清除）后，Phase 5 可继续。
3. CR re-verify 发现代码不一致 → 走 §5 分支3 退回重做，不掺 Phase 5 defect 判定。

**CR 优先，VT 让位**: 主动变更进行中时，验证结果可能基于旧 artifact，故暂停 VT 等通道清空。

## 反模式防御

- 不绕门禁: CR 确认 ≠ 跳过重做。改 PRD 仍须重确认 PRD。
- 不并发 CR: 一次一个未 closed CR。
- 不手改 stale 状态: 须经 change router。（MVP 靠 skill 自律，TS validator 为 P1）
- CR 可追溯: 含 rejected 永久归档。
- 不替代 Phase 5: 代码 defect 走 Phase 5 FT；CR 驱动契约变更走 implement stale + 分支3。
- CR 优先 VT: §7。

## 不做（YAGNI）

- 不做自动判层（P1 视数据）
- 不做 changedSections / 节级 stale（phase 级粒度）
- 不做并发 CR / CR 依赖图（禁并发）
- 不做中途收窄阀（P1）
- 不做自动重做（agent 只判定+指引）
