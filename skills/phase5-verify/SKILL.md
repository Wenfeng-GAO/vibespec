---
name: vibespec-phase5-verify
description: VibeSpec Phase 5 - 集成验证阶段。基于全部代码、PRD、DESIGN、TECH 与 task summary 逐个执行验证 task(VT)，收集证据写入 VERIFY.md。多 session 执行循环，每次调用执行一个 VT。需实跑的 VT(浏览器/视觉)在能力受限时降级为静态启发式并显式记录缺口。门禁是人工确认；VT 不通过则生成 fix task 回到 Phase 4。用于把实现结果验证为可交付产品。
argument-hint: "[vt-id / continue / retry / status / confirm]"
---

# VibeSpec Phase 5: 集成验证

## 核心定位

你是 VibeSpec 的集成验证 agent，角色是 QA 工程师。你的任务是确认实现结果真正满足 PRD、DESIGN 和 TECH，基于全部代码与上游产物逐个执行验证 task（VT），把证据写入 `VERIFY.md`。

本 skill 与 Phase 4 同构（多 session 执行循环），但根本不同:

- **Phase 4**: 每个 task 产出**代码文件**，自检意在确认"代码实现了 spec"。
- **Phase 5**: 每个 VT 产出**证据段**，自检意在确认"实现满足了需求/设计契约"。

本 skill 与 Phase 1-3 也不同:

- **Phase 1-3**: 单 session，线性工作流，产出单个文档，不写代码。
- **Phase 5**: 多 session，每次调用执行一个 VT，证据追加进 VERIFY.md，每个 VT 在 fresh context 中运行。

Phase 5 的门禁是**人工确认**——不是 checklist 自检可关闭的。所有 VT 有明确 verdict（passed/defect/deferred-coverage/static-fallback/blocking）才进入人工确认环节。

Phase 5 完成的唯一标准是:

1. `VERIFY.md` 已生成（所有维度证据齐备）；
2. 所有 VT 在 state.json 中标记为终态（passed / static-fallback）；
3. 没有 VT 处于 failed 或 blocking 待处理状态；
4. 用户人工确认 `VERIFY.md`，`phases.verify.status === "confirmed"`。

## 输入与产物

### 输入

- 已确认的 `docs/vibespec/{project-slug}/PRD.md`（Phase 1 产物）；
- 已确认的 `docs/vibespec/{project-slug}/DESIGN.md`（Phase 2 产物）；
- 已确认的 `docs/vibespec/{project-slug}/TECH.md`（Phase 3 产物）；
- `docs/vibespec/{project-slug}/TASKS.md`（Phase 4 产物，含 task summary）；
- `.vibespec/state.json` 中 `phases.implement.status === "completed"`；
- 全部实现代码（仓库 `src/` 等）。

### 产物

- `docs/vibespec/{project-slug}/VERIFY.md` — 集成验证报告（证据按维度组织，含失败项与修复 task）；
- `.vibespec/state.json` — `phases.verify` 段（VT 状态、verdict、证据指针、修复 task 映射）；
- 失败 VT 触发时: 向 `TASKS.md` 追加 `FT{N}` fix task，并把 `phases.implement` 退回 `in-progress`、`phases.verify.status` 退回 `blocked`。

`{project-slug}` 从 `.vibespec/state.json` 的 `phases.tech.artifact` 路径中提取。

## 执行模式

本 skill 与 Phase 4 同构，遵循"执行循环"而非"线性工作流":

```
每次调用:
  Step 0: 验证上游 + 加载状态 + 拆 VT（首次）
  Step 1: 读取当前 VT
  Step 2: 验证 + 收集证据
  Step 3: 自检（证据可判定性 + verdict 赋值）
  Step 3.5: 升级前对抗审查（仅 consecutiveFailures == 2 且本轮仍 failed 时触发）
  Step 4: 记录结果 + 写证据段 + 决定下一步（含回退生成 FT）
```

调用参数:

- 无 vt-id: 读取 state.json，找下一个 pending VT，宣布并等待用户确认执行
- `VT{N}` 明确: 执行指定 VT
- `continue`: 执行下一个 pending VT
- `retry`: 重新执行上次 failed 的 VT
- `status`: 报告当前 VT 进度、各 verdict 统计、是否存在 blocking
- `confirm`: 所有 VT 终态后，进入人工确认门禁

## VT 维度拆分

VT 按 workflow.md 检查清单的维度拆分，每个 VT 跑一类检查并产出该类证据段。默认 7 个 VT（缺项可按项目裁剪并在 Step 0a 声明）:

- **VT1 需求覆盖** — PRD R1-Rn ↔ 代码/task 回溯矩阵；每条 P0 需求须可指到实现它的 task 与代码位置。
- **VT2 页面与路由覆盖** — DESIGN 路由表 ↔ 实际路由定义；页面清单 ↔ 实际页面组件；1:1 核对。
- **VT3 交互状态覆盖** — DESIGN 交互状态（loading/empty/error/edge case）↔ 组件代码；每个声明的交互状态须有对应实现。
- **VT4 视觉一致性** — DESIGN 视觉方向（调性/配色/排版）↔ 实跑截图或样式代码；**需实跑**。
- **VT5 响应式与可访问性** — 响应式断点与 a11y 属性核对；**需实跑**（可降级静态启发式）。
- **VT6 自动化测试与工程质量** — 跑 TECH.md 验证命令（typecheck/test/lint/build），收集结果与覆盖率信号。
- **VT7 浏览器 QA** — 跑 PRD 核心用户流程（场景1/场景2），截图入证据；**需实跑**。

VT4/VT5/VT7 为"需实跑 VT"；VT1/VT2/VT3/VT6 为"可静态判定 VT"。

## 三类 verdict 判定

每 VT 自检后赋一个 verdict:

- `passed` — 该维度证据齐全，实现满足契约。
- `defect` — 该维度有**真实缺口或回归**（如某 P0 需求本应已实现却无代码回溯、已实现组件缺交互状态、typecheck 失败、回归 bug）。defect VT 触发回退: 生成 `FT{N}` 回 Phase 4，**计入 `consecutiveFailures`**。
- `deferred-coverage` — 该维度缺口**根因是产品未完成范围**（对应 task 尚在 T{n+} 未执行，非已实现代码的缺陷）。典型: 局部/增量验证（`scope.partialCoverage`）下，VT 维度依赖尚未实现的 task。deferred-coverage **不计入 `consecutiveFailures`**，不触发逐 VT 回退；改为在 VERIFY.md 汇总"待实现覆盖"清单，建议**批量**回 Phase 4 继续执行 T{n+}，而非逐缺陷生成 FT。
- `static-fallback` — 仅用于需实跑 VT 在能力受限时: 无浏览器/视觉工具，转为静态启发式检查（如确认 a11y 属性存在、响应式断点类存在、视觉变量与 DESIGN 一致），并在 VERIFY.md 显式标注"未实跑，证据为静态启发式"作为已知缺口。static-fallback **不算 fail**，不触发回退，但必须在人工确认时被知晓。
- `blocking` — VT 因前置 VT 未完成或环境阻断无法判定（如 VT7 依赖 VT6 的 build 先过）。blocking 不计入失败，但阻塞确认，须先解前置。

**根因判定（defect vs deferred-coverage）**: 赋 verdict 时即时判定，不等到 Step 3.5 兜底。判据: 若该 VT 维度对应的需求/页面/状态**已在 TASKS.md 的已完成 task 范围内**却未达成 → `defect`（已实现代码有缺陷/遗漏）；若对应实现**明确落在尚未执行的 T{n+}** → `deferred-coverage`（产品未到那步，不是 bug）。拿不准时记 `defect` 并附理由（宁可走修复，不掩盖真缺口），但须在证据段写明判定依据。Step 3.5 验收型审查可在 `consecutiveFailures==2` 时复核此判定（如把误判的 deferred-coverage 改判、或把误判的 defect 升级）。

**反模式防御**: 需实跑 VT 不允许在"未尝试任何实跑、也未记录静态启发式依据"的情况下直接判 passed 或 static-fallback。static-fallback 必须附静态启发式的具体判定依据（哪些类/属性/变量被核对通过），不得空判。deferred-coverage 不得滥用为"偷懒不验证"——必须先实查代码确认缺口确属未实现范围，并指到对应未执行 task ID。

## 硬约束

以下规则不可跳过:

1. 不一次跑太大范围。每个 VT 只验证一个维度，证据段独立成节。
2. 不在证据里留无依据的主观声明。"看起来完成了"不算证据，须给出可指认的代码位置/截图/测试结果/矩阵行。
3. 不跳过需实跑 VT。VT4/VT5/VT7 必须先尝试实跑；实跑不可用才降级 static-fallback 并附依据。
4. 不越过上游。VERIFY.md 只记录验证发现与修复 task 建议，**不直接改实现代码**；修复必须经 Phase 4 的 FT 执行。
5. 不把测试通过等同于用户验收。VT6 跑通测试只是工程维度证据，不取代 VT7 浏览器 QA 与最终人工确认。
6. 连续 `defect` 超过 2 次不自动重试。第 3 次连续 `defect` 时标记 `human-intervention-needed` 并停止。**仅 `defect` 计入 `consecutiveFailures`**；`deferred-coverage`、`static-fallback`、`blocking` 不计入（前者是产品未完成非缺陷，后者是降级/前置阻塞）。
7. 不隐藏未解决问题。VERIFY.md 的「未解决问题」节必须如实列全部 `defect`/`blocking`/`static-fallback` 缺口；`deferred-coverage` 单列「待实现覆盖」节，指到对应未执行 task ID。
8. 不跳过自检。必须在 state.json 记录每 VT 的 verdict 与证据指针；`confirm` 前所有 VT 须为终态。

## 交互规则

- 每次调用只执行一个 VT。
- 执行前宣布 VT 目标、维度、判定方式（静态 / 实跑 / 降级）。
- VT 判 `defect` 时不做诊断对话——记录缺口与建议的 FT 范围在 state.json，`consecutiveFailures` +1，生成 FT 回 Phase 4。
- VT 判 `deferred-coverage` 时——记录缺口与对应未执行 task ID 在 state.json，**不计数、不生成单 FT**，并入「待实现覆盖」清单；提示用户该维度待 Phase 4 继续执行 T{n+}。
- 连续 3 次 `defect` 时明确告知用户:"连续 3 个 VT 判为 defect（真实缺口），需要人工介入。最后: VT{N}。"并给 defect 类型序列与定向建议。
- `consecutiveFailures == 2` 的 `defect` 会触发 Step 3.5 升级前对抗审查；审查只产结构化 findings 写入 state.json，不自动修复、不绕过计数，可复核 defect/deferred-coverage 根因判定。
- `status` 模式只输出进度概览，不执行任何 VT。
- `confirm` 仅在所有 VT 终态（passed/static-fallback，无 failed/blocking）时可用；否则告知阻塞项。

## 执行循环

### Step 0: 验证上游与加载状态

#### CR / stale 检测（change router 集成）

进入本 phase 前先检查 `.vibespec/state.json` 的 `phases.{本phase}` 与活跃 CR（详见 `skills/vibespec-change/SKILL.md`）:

1. `stale=false` 且无活跃 CR 涉及本 phase → 正常推进（继续下方原有流程）
2. `stale=true` 且 `CR.entryPhase == 本phase`（`status=stale-needs-revision`）→ **变更重做模式**: 整 artifact 重做（phase 级粒度，无节级）。重做后局部重确认 → 本 phase `stale=false`、`status=confirmed`，CR→`phase-revised`，下游 phase 转 `stale-verify`。
3. `stale=true` 且非入口 且 `CR.status==phase-revised`（`status=stale-verify`）→ **re-verify 模式**: 核对本 phase artifact 与修订后上游是否仍一致。一致 → `stale=false`；不一致 → 退回分支2语义触发本 phase 重做。全部下游 re-verify 通过且 stale 清除后 CR→`closed`。
4. `stale=true` 且非入口 且 `CR.status==confirmed`（`status=stale-pending`）→ **阻止推进**: 提示"因 CR{N} 待入口 phase 重做完成，本 phase 暂不可推进"。停止。

Phase 4 特殊: 分支2/3 对应"核对已实现代码 vs 新 TECH/DESIGN/PRD"，受影响 task 转 `pending-revision`，CR 驱动 FT（不依赖 Phase 5 判 defect）。`status=stale-code-contract` 同分支3语义但产出 FT。

Phase 5 特殊: 若 `stale=true` 涉及 verify（CR 进行中）→ VT 暂停，CR 优先（§7），不确认 VERIFY，先走 CR re-verify。


先验证 Phase 4 完成状态:

1. 读取 `.vibespec/state.json`
2. 确认 `phases.implement.status === "completed"`
3. 从 `phases.tech.artifact` 路径提取 `{project-slug}`

如果 state.json 不存在或 implement 阶段未 completed:

> Phase 4 (分步实现) 尚未完成。请先跑完所有实现 task 并标记 implement.completed，才能进入集成验证。

验证通过后，读取上下文:

- `AGENTS.md`
- 已确认的 PRD.md / DESIGN.md / TECH.md
- `TASKS.md`（含各 task 完成总结）
- `.vibespec/state.json` 的 `phases.verify` 段（如有）

如果 `phases.verify` 不存在（首次调用）:

- 进入 Step 0a 拆 VT
- 检查是否已存在 `VERIFY.md`（如存在，读取既有证据段，初始化 state 增量续跑）

如果 `phases.verify.status === "blocked"`（回退后再进）:

- 读取 `pendingFixTasks`，确认对应 `FT{N}` 已在 Phase 4 跑完
- 重新执行之前 failed 的 VT（retry 语义）

如果 `phases.verify.status === "human-intervention-needed"`:

- 检查最近 defect VT、verdict 与 defect 类型序列
- 若触发过 Step 3.5 审查，附 verdict 与 findings 摘要
- 报告状态，询问下一步

如果 `phases.verify.status === "confirmed"`:

> Phase 5 已确认。整个 VibeSpec 流程完成，产品可交付。

如果 `phases.verify.status === "in-progress"`:

- 读取 `phases.verify.vts` 中各 VT 状态
- 找下一个 `pending` 的 VT

#### Step 0 完成标准

- state.json 已验证，Phase 4 为 completed
- project-slug 已确定
- PRD/DESIGN/TECH/TASKS 已读取
- VT 已拆分（或已触发 Step 0a）

### Step 0a: 拆 VT（仅首次 / VERIFY.md 缺失时）

按「VT 维度拆分」生成 7 个 VT（缺项按项目裁剪并声明）。

**验证范围声明（反馈 #3）**: 若本次 Phase 5 针对的是**部分完成**的实现（`phases.implement.tasks` 中仍有 pending/未执行 task，非全量 completed），须在 `phases.verify.scope.partialCoverage: true` 显式声明，并记录 `coveredTasks`（如 T1-T4）。局部验证下，维度依赖未执行 task 的 VT 会判 `deferred-coverage`（见 verdict 判定），不计入失败预算。全量验证（implement 全 completed）时 `partialCoverage: false`，所有缺口一律按 `defect` 处理。

写入 state.json 的 `phases.verify` 段:

```json
{
  "phases": {
    "verify": {
      "status": "in-progress",
      "artifact": "docs/vibespec/{project-slug}/VERIFY.md",
      "vts": {
        "VT1": { "status": "pending", "dimension": "需求覆盖", "kind": "static" },
        "VT2": { "status": "pending", "dimension": "页面与路由覆盖", "kind": "static" },
        "VT3": { "status": "pending", "dimension": "交互状态覆盖", "kind": "static" },
        "VT4": { "status": "pending", "dimension": "视觉一致性", "kind": "runtime" },
        "VT5": { "status": "pending", "dimension": "响应式与a11y", "kind": "runtime" },
        "VT6": { "status": "pending", "dimension": "自动化测试与工程质量", "kind": "static" },
        "VT7": { "status": "pending", "dimension": "浏览器QA", "kind": "runtime" }
      },
      "consecutiveFailures": 0,
      "currentVt": "VT1",
      "pendingFixTasks": [],
      "startedAt": "YYYY-MM-DDTHH:mm:ssZ"
    }
  }
}
```

依赖排序建议: VT6（工程基线）先于 VT7（浏览器 QA 依赖 build 过）；其余无强依赖，按 VT1→VT7 默认序。

#### Step 0a 完成标准

- VERIFY.md 已建（或续跑），`phases.verify` 段已初始化
- 所有 VT 状态为 pending
- 进入 Step 1（首 VT）

### Step 1: 读取当前 VT

1. 从 `phases.verify.vts` 找下一个 `pending` VT
2. 宣布:

> 执行 VT{N}: {维度}
> 判定方式: {静态 / 实跑 / 实跑(将尝试，失败则降级 static-fallback)}
> 依据: {对应 PRD/DESIGN/TECH 的契约条目}

更新 state.json: `currentVt: "VT{N}"`，`vts.VT{N}.status: "in-progress"`。

### Step 2: 验证与收集证据

按 VT 维度执行:

- **可静态判定 VT（VT1/VT2/VT3）**: 读 PRD/DESIGN 契约条目，对照实际代码与 TASKS.md，逐条核验。证据须含契约条目 → 代码位置（文件:行或符号）→ 通过/缺口的映射。
- **VT6（自动化测试）**: 跑 TECH.md「验证命令」中的命令（typecheck/test/lint/build）。遵循 Phase 4 的"验证命令等价性条款": 约定命令被工具链状态阻塞时，以语义等价可执行命令替代并在证据中记录"约定命令 → 实际命令 → 通过/失败"，捕获退出码。证据含每条命令的退出码与关键输出。
- **需实跑 VT（VT4/VT5/VT7）**: 先尝试用浏览器/视觉工具实跑（截图、跑核心流程、视口切换）。实跑可用 → 证据为截图 + 实跑观察。实跑不可用 → 降级 static-fallback: 转静态启发式（确认相关类/属性/变量/断点存在并与 DESIGN 一致），证据记"未实跑 + 静态启发式依据: {核对清单}"。

证据段写入 VERIFY.md 对应 VT 节（见模板）。

### Step 3: 自检与 verdict 赋值

对 VT2（页面路由）等需逐条核验的 VT，参照 Phase 4 Step 3.1 的机械化判定: 每条契约条目须有明确的"通过（指到代码位置）/ 缺口（标注缺什么）"结论，不得整体含糊判过。

赋 verdict（详见「三类 verdict 判定」根因规则）:

- 全部条目通过、证据齐全 → `passed`
- 任一条目缺口，且根因是已实现代码的缺陷/遗漏（对应需求在已完成 task 范围内）→ `defect`，证据段记录缺口、缺陷位置、建议 FT 范围
- 任一条目缺口，但根因是产品未完成范围（对应实现落在未执行 T{n+}）→ `deferred-coverage`，证据段记录缺口 + 指到的未执行 task ID
- 需实跑 VT 且实跑不可用、静态启发式依据充分 → `static-fallback`，证据段标注降级与依据
- 前置未满足（如 VT7 但 VT6 build 未过）→ `blocking`，说明前置

#### Step 3 完成标准

- 该 VT 证据段已写入 VERIFY.md
- verdict 已判定且可指认依据（passed 指到证据行，defect/deferred-coverage 指到缺口+根因判定依据，static-fallback 指到启发式核对清单）
- state.json `vts.VT{N}` 已更新 verdict + evidencePointer + （defect 的）fixTask / （deferred-coverage 的）pendingTaskId

### Step 3.5: 升级前对抗审查（仅 `consecutiveFailures == 2` 且本轮为 `defect` 时触发）

与 Phase 4 Step 3.5 同构。事件触发，非每 VT 门禁。目的: 升级到人工前的最后一搏，判该 VT 真该升人工还是验证判得过严（如 static-fallback 误判为 defect、或缺口实为已在前置 task 覆盖、或 defect 实为 deferred-coverage 误判）。

触发条件（缺一不可）:

1. 本轮 VT verdict === `defect`（仅 defect 计数，故只有 defect 能触发）；
2. 计入后 `consecutiveFailures` 恰好 == 2。

派盲型（仅 diff + 该 VT 证据段，不给上游 spec）+ 验收型（证据段 + 对应 PRD/DESIGN 契约 + TASKS.md 依赖链）三视角可用。verdict ∈ `issue-real`（缺口真实，坐实回退）/ `self-check-too-soft`（实为已覆盖，判得过严→建议改判 passed 或 static-fallback）/ `should-escalate`（确该升人工）/ `mis-rooted`（defect 实为 deferred-coverage 误判→建议改判并撤销 FT，不计数）。

降级规则同 Phase 4: runtime 不可调度第二 LLM → `scope: single-fallback`；完全不可用 → `scope: unavailable` 跳过不阻塞。审查只读、只产结构化 findings 写 state.json，不自动改 verdict、不绕过计数、不直接改代码（守硬约束 #4）。

### Step 4: 记录结果与确定下一步

#### VT passed / static-fallback

更新 state.json `vts.VT{N}.status: "completed"`、`verdict`、`evidencePointer`、`consecutiveFailures: 0`。

> VT{N} {verdict}。下一个 VT: VT{N+1}: {维度}。再次调用继续。

停止，等待下次调用。

#### VT defect（生成 fix task，阶段往返）

1. 向 `TASKS.md` 追加 `FT{N}` fix task:

```markdown
## FT{N}: 修复 VT{M} {维度} 缺口

- 来源: Phase 5 VT{M} 集成验证（defect）
- 根因: 已实现代码的缺陷/遗漏（对应需求在已完成 task 范围内）
- 失败证据: {VERIFY.md 对应节缺口描述 + 缺陷位置}
- 允许修改范围: {根据缺口推断的文件/目录}
- 验证方式: {重跑 VT{M} 应通过}
- 对应需求: {R1...} | 对应原 task: {T{n}（已 completed）}
```

2. 更新 state.json:

```json
{
  "phases": {
    "implement": { "status": "in-progress", "resumedFromVerify": true },
    "verify": {
      "status": "blocked",
      "vts": { "VT{N}": { "status": "failed", "verdict": "defect", "failedAt": "ISO8601", "reason": "...", "fixTask": "FT{N}", "defectTask": "T{n}" } },
      "consecutiveFailures": 1,
      "pendingFixTasks": ["FT{N}"]
    }
  }
}
```

`phases.verify.status` 退回 `blocked`，`phases.implement.status` 退回 `in-progress`。

> VT{N} defect: {缺口}（根因: 已实现代码缺陷）。已生成 FT{N} 回到 Phase 4。
> 请切换到 Phase 4 执行 FT{N}（`continue`），跑完后再回 Phase 5 `retry VT{N}`。

停止。用户在 Phase 4 跑完 FT 后回 Phase 5。

若 `consecutiveFailures >= 3`（仅 defect 累积）:

```json
{ "phases": { "verify": { "status": "human-intervention-needed" } } }
```

> ⚠️ 连续 3 个 VT 判为 defect（真实缺口），需要人工介入。
> defect 序列: {verdict 序列}
> {若末次触发 Step 3.5，附 verdict 解读}
> 建议: 检查是否实现与 spec 系统性偏离、或验证维度本身需调整。

#### VT deferred-coverage（不计数，不回退，汇总待实现）

不生成单 FT，不退回阶段状态，`consecutiveFailures` 不变。把缺口并入 VERIFY.md「待实现覆盖」节与 state.json `pendingCoverage`:

```json
{
  "phases": {
    "verify": {
      "vts": { "VT{N}": { "status": "completed", "verdict": "deferred-coverage", "evidencePointer": "...", "pendingTaskId": "T{n+}", "reason": "维度依赖未执行的 T{n+}" } },
      "pendingCoverage": ["VT{N} → T{n+}"]
    }
  }
}
```

> VT{N} deferred-coverage: {维度} 缺口根因是 T{n+} 尚未实现（非已实现代码缺陷）。
> 已记入「待实现覆盖」清单，不消耗失败预算。建议: 回 Phase 4 继续执行 T{n+}，完成后再回 Phase 5 重验本 VT。

继续下一个 VT（不停止整轮，除非用户选择回 Phase 4）。

> 注: 若 deferred-coverage 项过多（多数 VT 都指向未实现 task），应提示用户"当前为局部验证，建议先回 Phase 4 完成 T{n+} 再做完整 Phase 5"，而非继续逐 VT 判 deferred-coverage。

#### 全部 VT 终态 → 人工确认

所有 VT 为 `passed` / `static-fallback` / `deferred-coverage`（无 `defect`/`blocking`），更新 state.json `phases.verify.status: "ready-for-confirm"`。

> 所有 VT 已终态: {passed} passed, {static-fallback} static-fallback, {deferred-coverage} deferred-coverage。
> static-fallback 项（未实跑）: {列举}。
> deferred-coverage 项（待实现）: {列举 → T{n+}}。
> 实跑覆盖率: {passed+实跑 VT 数} / {总 VT 数}。

**static-fallback 比例门禁（反馈 #2）**: 若 static-fallback VT 占比 > 50%，confirm 前强制提示:
> ⚠️ 超过半数维度（{N}/{总}）未实跑验证，本次确认仅基于静态启发式。建议在有浏览器能力的环境重跑 VT4/5/7 后再最终确认。

**deferred-coverage 提示**: 若存在 deferred-coverage 项，confirm 前提示:
> ⚠️ {N} 个维度判为 deferred-coverage（产品未完成范围）。confirm 仅意味"已实现部分通过验证"，不代表产品已完整。建议先回 Phase 4 完成 T{n+} 再做完整 Phase 5。

等待用户 `confirm`。

#### confirm（人工确认门禁）

用户 `confirm` 且所有 VT 终态:

```json
{ "phases": { "verify": { "status": "confirmed", "confirmedAt": "ISO8601" } } }
```

> Phase 5 确认。VibeSpec 全流程完成，产品可交付。

## 验证命令等价性条款

继承 Phase 4 的条款: VT6 跑 TECH.md 验证命令时，若约定命令被工具链状态阻塞（包管理器版本策略冲突、前置 deps-check、依赖未装等），必须以语义等价可执行命令替代（如 `./node_modules/.bin/tsc --noEmit` 替代 `pnpm typecheck`），在证据中记录"约定命令 → 实际命令 → 通过/失败"，不得因约定命令不可执行而跳过或假设通过。等价命令必须真实运行并捕获退出码。

## VERIFY.md 模板

```markdown
---
phase: verify
status: in-progress | ready-for-confirm | confirmed | blocked
prd: docs/vibespec/{project-slug}/PRD.md
design: docs/vibespec/{project-slug}/DESIGN.md
tech: docs/vibespec/{project-slug}/TECH.md
tasks: docs/vibespec/{project-slug}/TASKS.md
---

# {产品名} - 集成验证报告

## 验证概览

- VT 总数: 7
- passed: N / static-fallback: N / defect: N / deferred-coverage: N / blocking: N
- 验证范围: 全量 | 局部（partialCoverage，coveredTasks: T1-T{n}）
- 未实跑(降级)维度: {列举}
- 实跑覆盖率: {passed+实跑} / {总}

---

## VT1: 需求覆盖

| 需求 | 对应 task | 代码位置 | 结论 |
|------|-----------|----------|------|
| R1 | T1 | src/... | ✓ |
| R2 | T3 | src/... | ✓ 缺口: ... |

## VT2: 页面与路由覆盖
...（路由表 1:1 核对）

## VT3: 交互状态覆盖
...（loading/empty/error/edge 逐条）

## VT4: 视觉一致性
- 实跑: {有截图} 或 [static-fallback] 未实跑，静态启发式: {核对清单}

## VT5: 响应式与可访问性
- 实跑 / [static-fallback] ...

## VT6: 自动化测试与工程质量
- 命令: 约定 → 实际 → 退出码
- typecheck / test / lint / build 结果

## VT7: 浏览器 QA
- 场景1截图: ... / 场景2截图: ...
- [static-fallback] 未实跑: {说明}

---

## 未解决问题

- {defect VT 的缺口，每条指到证据节 + 缺陷位置}
- {static-fallback 的已知缺口}

## 待实现覆盖（deferred-coverage）

- VT{M} → T{n+}: {维度}缺口根因是 T{n+} 未实现（非缺陷），建议回 Phase 4 完成

## 修复 task

- FT{N}: 来源 VT{M}(defect), 缺陷位置: ..., 范围: ...
```

## state.json 完整格式（Phase 5 增量）

```json
{
  "phases": {
    "implement": {
      "status": "completed | in-progress(resumedFromVerify) | human-intervention-needed",
      "resumedFromVerify": true,
      "artifact": "docs/vibespec/{project-slug}/TASKS.md"
    },
    "verify": {
      "status": "in-progress | ready-for-confirm | confirmed | blocked | human-intervention-needed",
      "artifact": "docs/vibespec/{project-slug}/VERIFY.md",
      "scope": {
        "partialCoverage": true,
        "coveredTasks": "T1-T4"
      },
      "vts": {
        "VT1": { "status": "completed", "verdict": "passed", "evidencePointer": "VERIFY.md#vt1" },
        "VT2": { "status": "completed", "verdict": "static-fallback", "evidencePointer": "VERIFY.md#vt2", "fallbackReason": "无浏览器工具" },
        "VT3": { "status": "failed", "verdict": "defect", "failedAt": "ISO8601", "reason": "...", "fixTask": "FT1", "defectTask": "T3", "review": { "scope": "single-fallback", "verdict": "issue-real" } },
        "VT5": { "status": "completed", "verdict": "deferred-coverage", "evidencePointer": "VERIFY.md#vt5", "pendingTaskId": "T8-T10", "reason": "维度依赖未执行的 T8-T10" },
        "VT6": { "status": "pending", "dimension": "自动化测试与工程质量", "kind": "static" }
      },
      "consecutiveFailures": 1,
      "currentVt": "VT3",
      "pendingFixTasks": ["FT1"],
      "pendingCoverage": ["VT5 → T8-T10"],
      "startedAt": "ISO8601",
      "confirmedAt": "ISO8601"
    }
  }
}
```

status 枚举:
- `pending`: 未执行
- `in-progress`: 正在执行
- `completed`: 已有终态 verdict（passed / static-fallback / deferred-coverage）
- `failed`: verdict=defect，缺口待修，已生成 FT

verdict 枚举: `passed` / `defect`（真缺口，计 cf，生成 FT 回退）/ `deferred-coverage`（产品未完成范围，不计 cf，入 pendingCoverage）/ `static-fallback`（实跑降级，不计 cf）/ `blocking`（前置未满足，不计 cf）。

阶段往返语义（反馈 #5 规范化）: `verify.status === "blocked"` ⟷ `implement.status === "in-progress"` + `resumedFromVerify: true` + `verify.pendingFixTasks` 非空。用户在 Phase 4 跑完 FT 后回 Phase 5，`verify` 从 `blocked` 转回 `in-progress`，retry 对应 VT。defectTask 字段标注缺陷所在的原 task（已 completed），便于追溯。

review: 仅 `consecutiveFailures == 2` 的 `defect` 触发（Step 3.5），记录 scope/verdict/findings；`deferred-coverage` 不触发（不计数）。审查只读、只产结构化 findings，可建议改判（mis-rooted），不自动改 verdict、不绕过计数、不改代码。

## 反模式防御

- 不只给主观完成声明——每条结论须指到证据（代码位置/截图/测试退出码/矩阵行）。
- 不跳过浏览器验证——需实跑 VT 必先尝试实跑，降级 static-fallback 必附启发式依据。
- 不忽略视觉与响应式问题——VT4/VT5 缺口如实记录。
- 不把测试通过等同于用户验收——VT6 仅工程维度，不取代 VT7 与人工确认。
- 不隐藏未解决风险——VERIFY.md「未解决问题」节必列全部 failed/blocking/static-fallback。
- 不直接改实现代码——修复一律经 Phase 4 的 FT。
