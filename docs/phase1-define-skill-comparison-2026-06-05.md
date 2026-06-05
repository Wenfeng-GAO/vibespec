# Phase 1 Define Skill 开源实现对比

日期: 2026-06-05

## 结论

VibeSpec Define skill 的合理定位不是复刻任一开源流程，而是吸收它们在“想法到规格”上的有效机制，并保持自己的阶段边界:

- 采用 Compound Engineering 的产品压力测试、单问题澄清、right-sized requirements 思路；
- 采用 Spec Kit 的覆盖扫描、clarify 优先级和规格质量 checklist；
- 采用 Superpowers 的硬门禁、逐段确认和 spec self-review；
- 采用 GSD Core 的阶段节奏、状态持久化思想和 REQ-ID 覆盖意识，但不采用它的实现决策 Discuss 作为 Define 主模板；
- 仅借鉴 Task Master 的 PRD 输入结构，不借鉴其技术架构、roadmap 和 task 管理内容。

当前实现落在 `skills/phase1-define/SKILL.md`。它是一个完整 Define 阶段 skill，不包含 CLI，不依赖 `.vibespec/state.json`，以 `PRD.md` frontmatter 和用户逐段确认作为阶段门禁。

## 已拉取并翻译/整理的来源

| 来源 | 拉取内容 | 当前 stars | 中文化后的核心流程 |
|------|----------|-----------:|--------------------|
| Superpowers | `skills/brainstorming/SKILL.md` | 218607 | 先读项目上下文，再一次一问澄清，提出 2-3 个方案，分段展示设计，写 spec，自检，等待用户确认后才进入 plan。 |
| Compound Engineering | `plugins/compound-engineering/skills/ce-brainstorm/SKILL.md` | 19858 | 先判断范围，读取项目上下文，做产品压力测试，进行协作式对话，探索方案，写 requirements doc，document-review 后交接到 plan。 |
| GitHub Spec Kit | `templates/commands/specify.md`、`clarify.md`、`spec-template.md` | 108959 | `specify` 从自然语言生成 feature spec；`clarify` 用 taxonomy 扫描不明确项，最多问 5 个高价值问题，并把答案增量写回 spec。 |
| GSD Core | `docs/how-to/discuss-a-phase.md`、`docs/explanation/the-phase-loop.md` | 2772 | Phase loop 是 Discuss -> Plan -> Execute -> Verify -> Ship；Discuss 捕获实现决策并写 `CONTEXT.md`，供后续研究和计划读取。 |
| Task Master | `.taskmaster/templates/example_prd.txt` | 27326 | PRD 是 task 管理的输入，模板包含产品概览、核心功能、用户体验、技术架构、roadmap、依赖链和风险。 |

stars 为 2026-06-05 通过 GitHub API 查询结果。

## 各实现的中文翻译摘要

### Superpowers brainstorming

中文化流程:

1. 在做任何创造性工作前触发 brainstorming。
2. 先探索项目上下文，包括文件、文档和近期提交。
3. 一次只问一个澄清问题，理解目的、约束和成功标准。
4. 提出 2-3 个不同方案，并说明取舍和推荐。
5. 将设计按复杂度拆成短段展示，逐段征求用户确认。
6. 写入设计文档并做自检，检查占位符、矛盾、范围和歧义。
7. 用户确认 written spec 后，才允许进入 implementation plan。

对 VibeSpec 的价值:

- 强硬门禁非常适合 Define；
- 逐段确认非常适合 PRD；
- 但它会覆盖 architecture、components、data flow、testing，已经越过 VibeSpec Define 边界，不能照搬。

### Compound Engineering ce-brainstorm

中文化流程:

1. Brainstorm 只回答 WHAT，不回答 HOW。
2. 先判断任务是否适合 brainstorm，并按 Lightweight / Standard / Deep 控制深度。
3. 读取本地上下文、项目约束和相关文档。
4. 做产品压力测试，检查证据缺口、用户具体性、当前替代方案、最小可证明版本和长期风险。
5. 协作式对话，一次只问一个问题。
6. 如有多个方向，提出 2-3 个方案，避免过早锚定。
7. 写 requirements doc，确保 plan 不需要发明产品行为。
8. document-review 后交接到 plan。

对 VibeSpec 的价值:

- 是 Define skill 的主参考；
- “Plan 不能发明产品行为”应改写为“Design 不能发明产品行为”；
- 输出路径和 handoff 需要改成 VibeSpec 的 `PRD.md` 与 Design 阶段。

### GitHub Spec Kit specify / clarify

中文化流程:

`specify`:

1. 从自然语言描述生成 feature spec。
2. 提取 actor、action、data、constraints。
3. 对不明确但影响范围、隐私、安全或 UX 的地方标记 `[NEEDS CLARIFICATION]`。
4. 生成用户场景、功能需求、成功标准和实体。
5. 创建规格质量 checklist，验证无实现细节、需求可测、成功标准可衡量、边界清楚。

`clarify`:

1. 读取当前 spec。
2. 用 taxonomy 扫描不明确项，覆盖功能、数据、UX、NFR、依赖、边界、约束、术语、完成信号、占位符。
3. 选择最多 5 个最高价值问题。
4. 一次只问一个问题。
5. 用户回答后，将澄清结果写回 spec，并重跑 checklist。

对 VibeSpec 的价值:

- taxonomy 和 checklist 非常适合 Define；
- 最多 5 题适合后置 clarify，不适合完整 Define 全流程；
- Spec Kit 的目录、branch、hook 和 plan handoff 不应进入当前 skill。

### GSD Core discuss / phase loop

中文化流程:

1. 工作按 Discuss -> Plan -> Execute -> Verify -> Ship 循环推进。
2. Discuss 的目标是捕获实现偏好和灰区决策，写入 `CONTEXT.md`。
3. Plan 读取 `CONTEXT.md`，不重复询问已锁定决策。
4. Verify 检查 requirement coverage 和 decision coverage。
5. `.planning/STATE.md` 负责跨会话定位。

对 VibeSpec 的价值:

- 状态持久化、阶段节奏、REQ-ID 覆盖检查值得借鉴；
- Discuss 是实现决策，不是产品定义；
- 当前 Define skill 不应引入 `.planning/`、worktree、Plan/Execute/Ship。

### Task Master PRD template

中文化流程:

1. PRD 先描述产品概览和核心功能。
2. 描述用户体验、用户画像和关键流程。
3. 继续描述技术架构、开发 roadmap、逻辑依赖链、风险和附录。
4. 后续由 Task Master 解析 PRD，生成 tasks 和 subtasks。

对 VibeSpec 的价值:

- 产品概览、核心功能、用户体验部分可借鉴；
- 技术架构、roadmap、依赖链是 PRD 后的阶段内容，不应出现在 Define skill；
- Task Master 更适合 VibeSpec 后续 Task 阶段。

## 横向对比

| 维度 | Superpowers | CE Brainstorm | Spec Kit | GSD Core | Task Master | VibeSpec Define |
|------|-------------|---------------|----------|----------|-------------|-----------------|
| 核心目标 | 想法到设计 spec | 想法到 requirements | 自然语言到 feature spec | 阶段循环和实现决策 | PRD 到任务系统 | 想法到已确认 PRD |
| 角色定位 | 设计/工程混合 | 产品 + 规划前置 | 规格生成器 | 工程流程编排 | 任务管理输入 | 产品经理 |
| 是否一次一问 | 是 | 是 | clarify 是 | 可选模式 | 否 | 是 |
| 是否做压力测试 | 部分 | 强 | 部分 | 否 | 否 | 强 |
| 是否提供方案对比 | 是 | 是 | 弱 | 可选 analyze | 否 | 是，限产品形态 |
| 是否允许技术内容 | 会进入架构/测试 | 默认不进实现 | 禁止实现细节但含实体 | 主要讨论实现决策 | 明确包含技术架构 | 禁止技术实现 |
| 产物 | design spec | requirements doc | spec.md + checklist | CONTEXT/PLAN 等 | PRD 文本 | PRD.md |
| 门禁 | 用户确认后 plan | doc review + handoff | checklist + clarify | phase state | task parse 前输入 | PRD frontmatter + 逐段确认 |
| 状态持久化 | spec 文件 + commit | requirements 文件 | specs 目录 | `.planning/STATE.md` | `.taskmaster/` | `PRD.md` 本身 |
| 后续动作 | writing-plans | ce-plan | plan/tasks | plan/execute | parse/expand tasks | 只提示进入 Design |

## VibeSpec Define 的实现取舍

### 明确采用

- 单问题澄清；
- 产品压力测试；
- 本地上下文读取；
- 竞品/外部研究，但仅用于发现问题，不替用户确认需求；
- 2-3 个产品方向对比；
- 覆盖扫描；
- 稳定 ID: `R1`、`SC-1`、`A1`；
- PRD 逐段确认；
- `status: draft | confirmed` frontmatter；
- document-review 风格自检。

### 明确不采用

- CLI 状态机；
- `.vibespec/state.json`；
- `.planning/STATE.md`；
- worktree、commit、PR、merge；
- 技术架构、API、数据模型、目录结构；
- task/subtask 生成；
- 自动进入 Design、Tech 或 implementation。

### 需要特别防守的边界

1. Superpowers 和 Task Master 容易把 Define 推向工程设计。
2. GSD Discuss 容易把 Define 推向实现偏好收集。
3. Spec Kit specify 容易一次生成过多“合理默认”，VibeSpec 的 P0/P1 必须等用户确认。
4. CE 的 handoff 默认进入 plan，VibeSpec 只能提示进入 Design。

## 对 `skills/phase1-define/SKILL.md` 的落地映射

| VibeSpec skill 模块 | 来源借鉴 | 实现方式 |
|---------------------|----------|----------|
| 硬约束 | Superpowers + VibeSpec | 禁止代码、架构、task、自动进入下一阶段 |
| 恢复与上下文读取 | CE + GSD | 读取 README、docs、已有 PRD，不读取 CLI state |
| 研究包 | GSD + BMAD 思路 | 用户与场景、产品边界、风险假设、对标模式 |
| 产品压力测试 | CE | 证据、替代方案、最小可证明版本、失败条件 |
| 方案对比 | Superpowers + CE | 只比较产品方向，不比较技术方案 |
| 覆盖扫描 | Spec Kit clarify | 12 维扫描，发现 Missing/Partial 后继续提问 |
| PRD 模板 | BMAD + Spec Kit + VibeSpec | Persona、旅程、P0/P1/P2、成功标准、Anti-Features、假设 |
| 质量门禁 | Spec Kit checklist + document-review | 自检 + 可选文档评审 |
| 逐段确认 | Superpowers | 5 组确认后才能 confirmed |
| 完成协议 | VibeSpec | `PRD.md` frontmatter 标记 confirmed，只提示 Design |

## 当前结论

`skills/phase1-define/SKILL.md` 已经按上述对比落地为完整 Define skill。它不是轻量 MVP，也不是 CLI 入口；它是一个可复用 workflow skill，负责把一句话想法稳定转成可确认的 `PRD.md`。
