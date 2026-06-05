# VibeSpec 工作流规格

## 结论

VibeSpec 的最终交付物是 **Codex Skill + Claude Skill + 共享 repo-local protocol + TypeScript validators**。

核心定位是 agent-neutral：VibeSpec 不直接替代 coding agent，也不做一个独立运行 agent 的 CLI。它把 workflow 安装进 Codex 和 Claude Code 的 skill 体系里，同时用 `.vibespec/` 协议统一阶段、产物、门禁、状态和回退。

## 设计目标

- 让 vibecoding 从一句话想法开始，也能逐步收敛到清晰规格。
- 在写代码前强制产出 PRD、设计规约和技术方案。
- 用状态机避免 agent 跳阶段、漏产物或一口气盲跑到底。
- 用门禁把“看起来完成了”改成有证据的 pass/fail 判断。
- 让 Codex 和 Claude Code 在不同运行时里遵守同一套 workflow。
- 用 TypeScript validators 承担确定性检查，减少纯提示词约束的不稳定性。

## 非目标

- 不做完整 web dashboard。
- 不做多人协作和权限系统。
- 不做通用 app builder。
- 不内置复杂项目管理系统。
- 不做独立 agent runner。
- 不把 CLI 作为核心产品形态。

## 最终架构

```mermaid
flowchart LR
    U["用户"] --> CODEX["Codex Skill"]
    U --> CLAUDE["Claude Skill"]
    CODEX --> PROTOCOL[".vibespec/ Protocol"]
    CLAUDE --> PROTOCOL
    PROTOCOL --> STATE["state.json"]
    PROTOCOL --> ART["规格产物"]
    PROTOCOL --> RUNS["runs"]
    PROTOCOL --> GATES["gate reports"]
    PROTOCOL --> CR["change requests"]
    CODEX --> VAL["TypeScript Validators"]
    CLAUDE --> VAL
```

### Codex Skill

Codex Skill 负责：

- 在 Codex 中触发 VibeSpec 工作流；
- 读取 `.vibespec/state.json` 和当前产物；
- 按当前阶段生成或更新 artifact；
- 运行或调用 TypeScript validators；
- 生成 run report 和 gate report；
- 在满足条件时更新状态文件；
- 在需要人工确认时停止并等待用户明确确认。

### Claude Skill

Claude Skill 负责同一套 workflow 在 Claude Code 中的执行。

它可以使用 Claude Code 自己的 skill 组织方式，但必须遵守同一套 repo-local protocol、artifact 模板、gate report 格式和状态流转规则。

### Repo-local Protocol

推荐目录：

```text
.vibespec/
  state.json
  config.json
  runs/
  gates/
  change-requests/
  overrides/
docs/vibespec/
  PRD.md
  DESIGN.md
  TECH.md
  TASKS.md
  VERIFY.md
```

协议内容：

- 当前阶段；
- artifact 版本；
- artifact 依赖关系；
- 阶段确认状态；
- gate report；
- run report；
- change request；
- override 记录；
- 失败次数；
- 下一步推荐动作。

### TypeScript Validators

TypeScript validators 负责确定性检查：

- 状态文件 schema；
- 配置文件 schema；
- artifact 是否存在；
- artifact 必填章节是否存在；
- gate report 格式是否合法；
- artifact 依赖是否失效；
- override 是否记录完整；
- task 失败次数是否触发人工介入。

Validators 不负责判断“产品方向是否正确”或“审美是否好”，但要强制 agent 输出足够证据，让人工或 LLM reviewer 能基于 rubric 判断。

## 配置文件

推荐文件名：`.vibespec/config.json`。

配置内容：

- 项目类型；
- 启用的 skill；
- 产物路径；
- 阶段启用状态；
- 验证命令；
- 门禁策略；
- override 策略；
- task 粒度限制。

## 状态文件

推荐路径：`.vibespec/state.json`。

状态文件记录：

- 当前阶段；
- 每个阶段是否完成；
- 每个阶段的产物路径；
- 门禁结果；
- 用户确认记录；
- task 执行记录；
- 连续失败次数；
- override 记录；
- 下一步推荐动作。

状态文件是跨 Codex 和 Claude Code 的共享事实来源。

Agent 不应该只凭主观判断推进状态。任何状态推进都必须有对应 artifact、run report、gate report；人工确认型门禁还必须有用户明确确认记录。

## 五阶段状态机

```mermaid
stateDiagram-v2
    [*] --> ProductDefinition
    ProductDefinition --> DesignSpec: PRD 通过人工确认
    DesignSpec --> TechPlan: DESIGN 通过人工确认
    TechPlan --> StepImplementation: TECH 通过门禁
    StepImplementation --> IntegrationVerify: 全部 task 完成
    IntegrationVerify --> Done: VERIFY 通过人工确认
    IntegrationVerify --> StepImplementation: 生成修复 task
    StepImplementation --> HumanIntervention: 连续 3 次失败
    HumanIntervention --> StepImplementation: 人工决策后继续
    Done --> [*]
```

## 阶段 1：产品定义

### 目标

把一句话想法转成可执行的产品需求文档。

### 输入

- 用户的一句话想法；
- 可选的背景资料、竞品链接、目标用户描述。

### Agent 角色

产品经理。

### 产物

`PRD.md`

建议包含：

- 产品目标；
- 目标用户；
- 核心场景；
- 用户旅程；
- P0/P1/P2 功能；
- 成功标准；
- 不做什么；
- 风险和未决问题。

### 门禁

人工确认。

用户确认前，不允许进入设计规约阶段。

### 反模式防御

- 不写代码；
- 不跳过边界讨论；
- 不擅自推断核心需求；
- 不把功能列表当成 PRD；
- 不在未确认 PRD 时生成实现任务。

## 阶段 2：设计规约

### 目标

把 PRD 转成页面、流程、交互状态和视觉方向的设计契约。

### 输入

- 已确认的 `PRD.md`。

### Agent 角色

产品设计师。

### 产物

`DESIGN.md`

建议包含：

- 信息架构；
- 路由表；
- 页面清单；
- 组件树；
- 核心用户流程；
- loading / empty / error / edge case 状态；
- 数据流向；
- 视觉方向；
- 响应式要求；
- 可访问性要求。

### 门禁

人工确认。

用户确认前，不允许进入技术方案阶段。

### 反模式防御

- 不写样式代码；
- 不跳过交互状态；
- 没有路由表不进入技术方案；
- 没有页面清单不进入技术方案；
- 不把“看起来现代”当成视觉方向。

## 阶段 3：技术方案

### 目标

把已确认的产品和设计规格转成可执行的技术方案。

### 输入

- 已确认的 `PRD.md`；
- 已确认的 `DESIGN.md`；
- 当前仓库上下文。

### Agent 角色

Tech Lead。

### 产物

`TECH.md`

建议包含：

- 技术栈；
- 目录结构；
- 数据模型；
- API 契约；
- 状态管理；
- 外部依赖；
- 安全和权限边界；
- 测试策略；
- 验证命令；
- 实现风险。

### 门禁

LLM checklist 自检。关键技术选择、数据模型和外部依赖可以要求人工确认。

### 反模式防御

- 不引入未验证依赖；
- 不跳过数据模型；
- 不跳过 API 契约；
- 目录结构必须对应设计规约；
- 验证命令必须可执行或明确说明原因。

## 阶段 4：分步实现

### 目标

把技术方案拆成独立 task，并让 coding agent 分阶段实现。

### 输入

- `PRD.md`；
- `DESIGN.md`；
- `TECH.md`；
- 当前代码仓库。

### Agent 角色

执行工程师。

### 产物

`TASKS.md`

每个 task 建议包含：

- task 目标；
- 输入上下文；
- 允许修改范围；
- 预期产出；
- 验证方式；
- 完成 summary。

### 门禁

每个 task 完成后自检。连续 3 次失败时进入人工介入。

### 反模式防御

- 不一次性改动过大范围；
- 不写 TODO 留坑；
- 不跨 task 随意跳转；
- 不忽略验证命令；
- 不在失败后无限自动重试。

## 阶段 5：集成验证

### 目标

确认实现结果真正满足 PRD、DESIGN 和 TECH。

### 输入

- 全部实现代码；
- `PRD.md`；
- `DESIGN.md`；
- `TECH.md`；
- task summary；
- 测试和浏览器验证结果。

### Agent 角色

QA 工程师。

### 产物

`VERIFY.md`

建议包含：

- 功能完整性；
- 需求覆盖；
- 页面和路由覆盖；
- 交互状态覆盖；
- 视觉一致性；
- 响应式检查；
- 可访问性检查；
- 浏览器 QA 证据；
- 自动化测试结果；
- 未解决问题；
- 修复 task。

### 门禁

人工确认。

通过后进入完成状态；不通过则生成修复 task，回到分步实现阶段。

### 反模式防御

- 不只给主观完成声明；
- 不跳过浏览器验证；
- 不忽略视觉和响应式问题；
- 不把测试通过等同于用户验收通过；
- 不隐藏未解决风险。

## 门禁类型

### 人工确认

用于产品定义、设计规约和集成验证。

适合判断：

- 产品方向是否正确；
- 体验是否符合预期；
- 视觉质量是否可接受；
- 最终结果是否能交付。

### LLM 自检

用于技术方案和单个 task 完成后。

适合判断：

- checklist 是否覆盖；
- 产物是否完整；
- 验证命令是否执行；
- 是否存在明显实现缺口。

### 人工介入

触发条件：

- 连续 3 次 task 失败；
- agent 判断需求冲突；
- 门禁无法自动判断；
- 需要用户做产品或技术取舍。

### Override

默认门禁不可跳过。确实需要跳过时，必须记录：

- override 阶段；
- override 原因；
- 操作人；
- 时间；
- 风险说明；
- 后续补偿动作。

## Skill 入口草案

### 初始化 VibeSpec

创建 `.vibespec/` 目录、默认配置、状态文件和 `docs/vibespec/` 产物目录。

### 查看状态

展示当前阶段、已完成产物、门禁状态、失败次数和下一步动作。

### 推进阶段

推进到下一阶段。只有当前阶段门禁通过后才允许执行。

### 执行门禁

执行当前阶段门禁检查，并记录 pass/fail 结果。

### 执行 task

执行或生成当前 task 的 agent 指令。

### 集成验证

执行集成验证，生成或更新 `VERIFY.md`。

### Override

显式跳过某个门禁，并记录原因和风险。

## TypeScript 实现建议

TypeScript 不作为核心产品形态，而是用于 deterministic validators 和辅助脚本：

- schema 校验：`zod`；
- 文件系统：Node.js `fs/promises`；
- 状态文件：JSON；
- Markdown 产物：先检查必填章节，后续再支持结构化 AST；
- 测试：Vitest；
- 脚本运行：`tsx` 或打包后的 Node.js 脚本；
- 发布：随 Codex skill 和 Claude skill 分发。

实现原则：

- 先做最小可跑通版本；
- skill 指令和 protocol 规则分离；
- validators 只做确定性检查；
- 状态更新必须能追溯到 run report 和 gate report；
- 不为尚未支持的 agent 提前写复杂抽象。

## 首个可用版本成功标准

- 能通过 Codex Skill 初始化一个 VibeSpec 项目。
- 能通过 Claude Skill 初始化同一套 VibeSpec 项目结构。
- 能从 idea 生成并确认 `PRD.md`。
- 能基于 PRD 生成并确认 `DESIGN.md`。
- 能生成 `TECH.md` 并通过 checklist。
- 能生成 task 列表并逐个推进。
- 能记录 task 成功、失败和连续失败次数。
- 能生成 `VERIFY.md`。
- 能阻止未通过门禁的阶段跳转。
- 能通过 override 显式跳过门禁并留下记录。
- Codex 和 Claude Code 能读写同一套 `.vibespec/` protocol。
- TypeScript validators 能检查状态、产物和 gate report 的基本合法性。

## 下一步

1. 定义 `.vibespec/config.json` 的 schema。
2. 定义 `.vibespec/state.json` 的 schema。
3. 定义 run report 和 gate report 格式。
4. 定义 Codex Skill 目录结构和 `SKILL.md`。
5. 定义 Claude Skill 目录结构和 `SKILL.md`。
6. 实现第一批 TypeScript validators。
