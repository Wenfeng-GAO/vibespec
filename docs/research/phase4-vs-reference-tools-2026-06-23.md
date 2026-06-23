# Phase 4（分步实现）vs 参考工具：对比分析

> 日期：2026-06-23
> 方法：动态工作流（9 份并行 web 研究 + synthesis + 对抗性 critic 审查）
> 分析对象：`skills/phase4-implement/SKILL.md` vs README「可借鉴工具」全部 7 类
> 涉及工具：GitHub Spec Kit、Kiro Specs、BMad Method、GSD Core、Task Master AI、OpenSpec/SpecDD/Colign、Lovable/Bolt/v0/Replit/Firebase Studio/Figma Make

## 一、Phase 4 的真实独特优势（已对抗校验）

1. **count-based 升级 + 多 session checkpoint 的组合，独此一家**
   `consecutiveFailures>=3 → human-intervention-needed` 的硬性升级，参考工具里只有 BMad 有类似的 3 连失败 HALT。但 BMad 默认走单 session 连续跑（"do NOT stop for session boundaries until COMPLETE"），而 Phase 4 是每次调用一个 task、写完 state.json 就停。
   - ⚠️ 校准：BMad 并非"无 checkpoint"——它有 review-continuation detection / Dev Agent Record / sprint-status.yaml 支持续跑。正确的对比是"默认极性相反"：BMad 默认连续、Phase 4 默认每 task checkpoint。把"3 连失败升级"和"多 session checkpoint 续跑"绑在一起做默认值，参考工具都没有。

2. **双账本设计（spec ledger / runtime ledger 分离）**
   `TASKS.md`（规格）与 `state.json`（运行时尝试/失败/计数）壳分离。Spec Kit/Kiro/SpecDD 都把进度塞进 markdown 复选框。Phase 4 让 fresh-context 调用只读一个 JSON 就能拿到 `currentTask + attempt + consecutiveFailures`，不用 parse markdown 还原位置——对父 orchestrator 友好。

3. **量化的硬范围上限：每 task 3-5 文件 + 固定 11 层依赖排序**
   Spec Kit 无文件数上限；BMad 只说"严格按 story Tasks"；GSD 按 PLAN 的 files-to-touch 约束但无数值天花板。Phase 4 是唯一把数值硬约束写进硬规则、且在 Step 3 自检里校验的。
   - ⚠️ 校准：仍是真优势，但 Replit/Bolt 用"隔离副本"做单 feature 改动，事实上也隔离了范围——只是没用文件数表达，措辞应承认这一等价路径。

4. **sloppiness→stop 的一等反馈回路**
   placeholder/scope/typecheck 任意 fail 直接喂同一个 `consecutiveFailures` 计数器，"越 sloppy 越快触发人工介入"是 first-class 机制。Spec Kit 的 anti-placeholder 是 constitution 层劝告；GSD 的反 stub 是独立 verifier pass——Phase 4 把它耦合进计数器，设计上更紧。

## 二、差异维度速览

| 维度 | Phase 4 | 参考工具 |
|------|---------|---------|
| 失败升级 | count-based 确定性（3 连停） | 仅 BMad 有 3 strike；其余 report-and-halt 或人工审查 |
| 状态追踪 | repo-local `state.json`，task/spec 分离 | Spec Kit 复选框即状态；GSD `.planning/` 多文件；仅 Colign 用 Postgres |
| 范围控制 | 硬性 3-5 文件/task | 合同/审查级，均无数值上限 |
| 任务派生 | TECH.md+P0 自动派生，固定 11 层 | Kiro 自生成依赖图 wave；Task Master DAG 拓扑聚类 |
| 验证 | typecheck+lint+placeholder+scope 自检，**无独立 verifier** | BMad 多层 LLM 代码审查；GSD adversarial verifier + UAT；Spec Kit constitution/checklist 门禁 |
| 上下文鲜度 | 一 call 一 task，最细粒度 | GSD 一 PLAN 一 ~200k 窗口；BMad 单 session 连续 |
| 跨 runtime 对等 | 单 agent，JSON 理论可移植 | GSD ~20 runtime；OpenSpec 25+ 工具；Colign MCP |
| 循环拓扑 | 每 task checkpoint 停 | BMad 单 session 连续（反向极性）；Kiro wave 并发 |

## 三、Phase 4 的真实弱点（诚实指出）

- **验证最轻**：无 GSD 的 EXISTS/SUBSTANTIVE/WIRED 逐项验证；无 BMad 的跨 LLM 对抗审查；无 GSD 的 UAT；无 Spec Kit 的 constitution/checklist 前置门禁。一个 typecheck 能过但从未被 import 的 service 文件，Phase 4 今天标 completed 能过。
- **失败处理单杠杆**：单一 count-based 计数器 + 刻意不诊断，缺少 BMad 那种富 HALT 分类（新依赖/缺配置/回归/需求歧义）。
- **无跨 runtime 原生对等、无状态对账**：缺 Kiro Sync Files 那种"对照实际代码库重算 task 状态"的机制。

## 四、值得借鉴的点（含如何适配 + 风险）

**A. 最高优先级：GSD 的 EXISTS/SUBSTANTIVE/WIRED 自管验证（已采纳，见下节）**
- 现状：Step 3 自检粗糙——typecheck 过但近 stub、或写了却没接线，都能蒙混。
- 适配：Step 3 加派生自"预期产出"+TECH 契约的逐项 MUST-HAVE（每文件 EXISTS / 非 stub 有真实接线 / 匹配 TECH 字段），在 `tasks.Tn.selfCheck.evidence` 记 PASS/FAIL/WIRED。不新增 agent、不动 3-5 文件上限、不加 TODO、不防腐上游——全在硬约束内。
- ⚠️ 风险：自评 SUBSTANTIVE/WIRED 会变软（正是 GSD 警告的反模式）。缓解：保持机械化判断（文件存在 + 无 placeholder + 不引用未实现模块，除已标前置）而非行为级。

**B. 原子提交 = task 完成检查点（+ safe-resume 门禁）**
- 现状：durable 状态只有 state.json 字符串 + TASKS.md 末尾自由文本总结，无机器可查的"代码先验态"链接。
- 适配：Step 4 自检过时记 `tasks.Tn.committedAt`，"completed 但无 commit"在 status 报告里标异常。失败只是又一个自检失败，不破 3-strike。设为 best-effort。
- ⚠️ 风险：单次脚手架或宿主不暴露 git 时会冲突。→ 设为记录规范，非每项目阻塞门禁。

**C. 显式 [depends-on] / [P] 字段（可机械化校验"不跨 task"）**
- 适配：TASKS.md 模板标准化每个 task 的 `[depends-on]`，加 `may-block` 状态。Step 1/Step 3 可机械校验。
- ⚠️ 风险：[P] 语义会诱导单 fresh context 内并行，违反"一 call 一 task"。→ [P] 仅作 Phase 5 规划标注，不在 Phase 4 内并行。
- 归属校准：复杂度感知自动细分最强来源是 **Task Master 的 `analyze-complexity`（1-10 评分）+ `expand`**，比归给 Spec Kit/BMad 更贴切。

**D. Pre-task 实现就绪门禁（前置 task 真完成 + 引用可解析）**
- 适配：Step 2 前扫允许文件集是否 import 了仍 pending 的 task 模块 → 失败计数。复用现有 import-path 检查，是 scope 执行非新门禁。
- ⚠️ 风险：barrel export 可能假阳。→ 仅当引用模块属 pending/failed task 才判失败。

**E. 失败原因轻量分类（仍人工升级）**
- 适配：state.json 加 `tasks.Tn.failureType`（type-error/lint-error/out-of-scope/placeholder），升级消息带类型。是数据记录非诊断，守住"不诊断只记录"。
- ⚠️ 风险：归一化会误并根因。→ 分类保持 3-5 桶，自由文本 reason 始终为真源。

**F. 补审新增：Replit Agent 的 checkpoint + 隔离副本生命周期**
- 价值：Replit checkpoint 不仅含文件，还含"AI 累积对话上下文"；两阶段生命周期（Draft→Active→Ready→Applying→Done）在隔离副本里跑、显式 Apply 合并、冲突自动解决。与 Phase 4 的 fresh-context 续跑高度相关。
- 适配方向（Phase 4 不一定照搬，记录备查）：state.json 可试点"task 完成时快照 working tree + 关键上下文摘要"，给 resume 和 Phase 5 审计一个可 diff 的先验态；"隔离副本 + 显式 Apply"对 single-agent 难落地，但理念与方案 B（原子提交）相通。
- ⚠️ 这一条 synthesis 本身遗漏，由 critic 补审补入。

## 五、关于是否引入 BMad 跨 LLM 对抗审查（推荐结论）

**结论：采纳，但作为事件触发的可选 pass，不做每个 task 的强门禁。**

理由：

- **价值明确**：跨 LLM 对抗审查（BMad 三猎手：Blind Hunter 仅看 diff、Edge Case Hunter 看 diff+项目、Acceptance Auditor 看 diff+spec+AC）恰好补上方案 A 自评会变软的弱点——方案 A 是自管验证，独立 LLM 能查"近 stub/没接线/偏离 spec"这类自检盲点。这是全部工具里最严的验证。
- **为什么不全量强制**：Phase 4 定位是 solo dev 中等规模、轻量、一 call 一 task + STOP。每个 task 都派一个第二 LLM 会显著增加延迟/成本，与"轻量默认"冲突；而且并非所有 runtime 都能干净地调度异构模型。
- **为何事件触发可接受**：在关键节点跑而不是每 task 跑，既在最需要的地方拿到最严检查，又不破坏默认路径的轻量性，也不破硬约束——
  - 不破坏"一 call 一 task"：审查作为 Step 3.5 在同一次调用内运行，审查完仍 STOP；
  - 不触发"不诊断"红线：审查输出的是结构化 findings，写入 state.json 作为 escalation 前的证据，不自动修复，本质是"补强记录"而非"自愈"；
  - 不防腐上游、不放大 scope：审查者只读 diff（盲型）或 diff+spec（验收型），只写 findings 不写代码。
- **触发时机建议**：
  1. `consecutiveFailures == 2`（升级前最后一搏）：派盲型 + 验收型审查，判定是该升人工还是自检过软导致的误判；
  2. task 自检标 completed 但 WIRED=uncertain（低信心）：派验收型审查兜底；
  3. 项目级可选 flag：高风险 task（auth/payments/data 改动）强制审查。
- **盲型 vs 验收型**：借鉴 BMad，盲型（仅 diff、无 PRD/DESIGN 上下文）查实现层 bug/边界；验收型（diff + spec + AC）查需求/AC 回溯。不必一上来铺三猎手，先两型。

> 落地建议：先实现方案 A（自管验证）作为基线，方案 F/G（对抗审查）作为后续增量，受 `consecutiveFailures` 与高风险 flag 驱动。本轮 SKILL.md 仅落地方案 A。

## 六、总评

Phase 4 在三个宣称差异化点上确实领先：3-strike+multi-session-checkpoint 组合、双账本、量化范围上限 + sloppiness 反馈回路。但也有三个清晰硬伤：验证最轻、失败处理单杠杆、无跨 runtime 对等与状态对账。

- **单点最强升级**：方案 A（GSD EXISTS/SUBSTANTIVE/WIRED 自管验证入 Step 3）——补最大短板不破任何硬约束，本轮已落地。
- **最遗憾遗漏（补审补入）**：Replit 的"checkpoint 含上下文"+ 隔离副本生命周期（方案 F）；complexity 评分自动细分归属应改 Task Master（校准方案 C）。
- **后续高价值增量**：BMad 跨 LLM 对抗审查做事件触发可选 pass（方案 G），补方案 A 自评软化风险。
