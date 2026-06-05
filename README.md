# VibeSpec

VibeSpec 是一个面向 AI coding agent 的工作流层，目标是帮助用户更稳定地 vibe coding 出正常的中等规模 app 和 web。

它不想做成又一个 AI app builder。它要解决的是：把一个模糊想法变成清晰的产品规格、分阶段实现任务、可见 checkpoint 和明确质量门禁，让 vibe coding 不再只靠 LLM 自由发挥。

第一版产品可以先收敛成 **CLI 工具 + 配置文件 + Agent workflow pack**：通过状态机和强约束门禁，驱动 AI coding agent 按阶段完成产品定义、设计规约、技术方案、分步实现和集成验证。

## 问题

Vibe coding 在开始阶段很快，但中等规模产品很容易漂移：

- 产品想法没有被转成清晰的 PRD、功能规格、用户流程和验收标准。
- Agent 过早开始实现，并自由补全模糊处，最后做出来的东西不是用户真正想要的。
- 验证标准模糊，agent 容易在 UX、视觉质量、边界情况和工程质量上降低要求。
- 反馈发生得太晚，用户往往到最后才知道方向是否正确，返工成本高。

## 产品方向

VibeSpec 应该成为一个 **Vibecoding Product OS**：

```mermaid
flowchart LR
    A["想法"] --> B["产品规格"]
    B --> C["设计契约"]
    C --> D["实现计划"]
    D --> E["分阶段 Agent 工作"]
    E --> F["浏览器 QA"]
    F --> G["用户验收"]
    G --> H["发布"]
```

它位于 Codex、Claude Code、Cursor、Gemini CLI、Windsurf 等 coding agent 之上，负责定义要做什么、什么时候允许继续、每个阶段如何验收。

第一版可以先适配一个主 agent，但核心设计应该保持 agent-neutral：VibeSpec 管理流程、状态和门禁，具体代码实现交给不同 coding agent。

## 第一版形态

VibeSpec 的 MVP 推荐先做成开发者可直接安装和试跑的工作流框架：

- **CLI 工具**：初始化项目、推进阶段、检查状态、执行门禁、生成修复任务。
- **配置文件**：定义项目类型、阶段策略、产物路径、验证命令、门禁规则和允许的例外。
- **状态文件**：持久化当前阶段、已确认产物、失败记录、用户确认和下一步动作。
- **Agent workflow pack**：把产品经理、设计师、Tech Lead、执行工程师、QA 工程师等角色沉淀为可复用指令和 checklist。
- **强约束门禁**：默认不可跳过；确实需要跳过时，必须显式记录 override 原因。

## 核心工作流

VibeSpec 使用 5 阶段门禁流水线：

1. **产品定义**：从一句话想法生成 `PRD.md`，覆盖目标用户、核心场景、P0/P1/P2 功能、成功标准和不做什么。门禁是人工确认，确认前不允许写代码。
2. **设计规约**：基于已确认 PRD 生成 `DESIGN.md`，覆盖路由表、页面清单、组件树、交互状态、数据流向和视觉方向。门禁是人工确认，确认前不进入技术方案。
3. **技术方案**：基于 `PRD.md` 和 `DESIGN.md` 生成 `TECH.md`，覆盖技术栈、目录结构、数据模型、API 契约、依赖列表和验证命令。门禁是 checklist 自检，关键技术选择可要求用户确认。
4. **分步实现**：基于 PRD、DESIGN 和 TECH 拆分独立 task。每个 task 尽量在 fresh context 中执行，完成后必须自检并输出 summary；连续 3 次失败时转人工介入。
5. **集成验证**：基于全部代码、PRD 和 DESIGN 生成 `VERIFY.md`，检查功能完整性、交互状态覆盖、视觉一致性、技术质量和浏览器 QA 证据。门禁是人工确认；不通过则生成修复 task 回到分步实现。

这个流程的重点不是“建议 agent 按顺序做”，而是让阶段推进变成可恢复、可检查、默认不可跳过的状态机。

## 反模式防御

VibeSpec 应该把常见 vibe-coding 失败模式写进规则里：

- 产品定义阶段：不写代码，不跳过边界讨论，不擅自推断核心需求。
- 设计规约阶段：不写样式代码，不跳过 loading、empty、error、edge case 等交互状态；没有路由表不进入技术方案。
- 技术方案阶段：不引入未验证依赖，不跳过数据模型和 API 契约；目录结构必须能对应设计规约。
- 分步实现阶段：不一口气改太大范围，不写 TODO 留坑，不跨 task 随意跳转。
- 集成验证阶段：不能只说“看起来完成了”，必须给出需求覆盖、浏览器验证、视觉检查和失败修复记录。

## MVP

第一版应该优先做三件高杠杆的事：

- **Spec Builder**：把 idea 转成 `PRD.md`、`DESIGN.md`、`TECH.md`、任务列表和验收标准。
- **Stateful Workflow Runner**：用 CLI 和状态文件追踪当前阶段、门禁结果、失败次数、用户确认和下一步动作。
- **Quality Gates**：提供产品定义、设计规约、技术方案、分步实现、浏览器 QA 和最终用户验收的 pass/fail 门禁。

这能避开和全栈 app builder 正面竞争，直接解决用户在 vibe coding 中最痛的控制感、清晰度和返工问题。

## 可借鉴工具

最值得参考的工具和方法：

- [GitHub Spec Kit](https://github.com/github/spec-kit)：spec-driven development、constitution、clarification、checklist，以及 specify、plan、tasks、implement 等命令式流程。
- [Kiro Specs](https://kiro.dev/docs/specs/)：requirements / design / tasks 结构、spec task UI、状态追踪，以及 spec mode 和 vibe mode 的分流。
- [BMad Method](https://github.com/bmad-code-org/BMAD-METHOD)：PM、Architect、UX、Developer 等多角色 agentic agile 方法，以及前置 planning artifacts。
- [GSD Core](https://github.com/open-gsd/gsd-core)：phase loop、planning artifacts、UI spec、verification workflow 和 conversational UAT。
- [OpenSpec](https://github.com/Fission-AI/OpenSpec)、[SpecDD](https://specdd.ai/) 和 [Colign](https://www.colign.co/)：轻量 repo-local spec，可被多个 AI coding assistant 读取。
- [Task Master AI](https://docs.task-master.dev/getting-started/quick-start/prd-quick)：从 PRD 生成 tasks、subtasks 和 dependencies。
- [Lovable](https://docs.lovable.dev/)、[Bolt](https://bolt.new/)、[Replit Agent](https://docs.replit.com/references/agent/overview)、[v0](https://v0.app/docs)、[Firebase Studio](https://firebase.google.com/docs/studio/get-started-ai) 和 [Figma Make](https://developers.figma.com/docs/code/intro-to-figma-make/)：快速生成、preview、点选修改、部署分享和设计系统感知。
- [Agent Skills](https://agentskills.io/) 和 [Claude Code Skills](https://code.claude.com/docs/en/skills)：把 workflow、脚本、参考资料和 assets 封装成可复用能力包。

## 定位

VibeSpec 不应该只是：

- prompt pack；
- task manager；
- QA checklist；
- 某个 coding agent 的 wrapper；
- 或 one-shot app generator。

更强的机会是：

> 一个 spec-first、checkpoint-driven 的 workflow layer，帮助用户把 AI 生成原型推进成产品质量更稳定的 app。

第一阶段市场定位可以更窄：先服务 solo developer，优先解决“我自己用 AI agent 做中等规模产品时如何少返工”。等 CLI/workflow 跑通后，再考虑做 dashboard、模板市场或多人协作。

## GSD Core 适配度

GSD Core 是一个很强的工程流程底座。它已经覆盖了 phase planning、execution、UI spec、verification 和 UAT，比大多数 vibe-coding 流程更完整。

但它还不能完全覆盖 VibeSpec 的产品目标：

- 它更像 CLI/repo-local development framework，不是产品定义工作台。
- 它的 PRD 层有帮助，但还不够产品化，缺少产品策略、用户旅程、信息架构、竞品参考、埋点、权限和发布策略。
- 它的 UI spec 是设计契约，不是视觉探索或高保真设计工作台。
- 它的质量门禁更擅长工程正确性，视觉审美和产品体验仍然依赖用户判断。
- 它缺少面向非技术用户的可视化 checkpoint dashboard。

更适合的关系是：

> GSD Core 可以作为后端执行模式或重要参考；VibeSpec 应该掌握更上游的产品定义、设计决策和可视化验收闭环。

## 初始路线图

- 定义 artifact model：`PRD.md`、`DESIGN.md`、`TECH.md`、`TASKS.md`、`VERIFY.md` 和状态文件。
- 设计 CLI 命令：init、status、next、gate、run-task、verify、override。
- 实现状态机：阶段流转、门禁结果、失败次数、用户确认、回退路径。
- 建立产品、设计、技术、实现和 QA checklist。
- 跑通一个真实中等规模 app/web 项目的端到端试用。
- 再扩展常见 app/web 类型模板：SaaS、CRM、内部工具、marketplace、社区、AI app、dashboard、内容产品。
- 后续增加 dashboard：展示阶段状态、风险、未决问题、需求覆盖和用户审批。

## 状态

当前仓库是探索型 repo。第一阶段目标是把概念沉淀成具体的产品规格和 MVP 计划。

## 相关笔记

- [工作流规格](docs/workflow.md)
- [研究笔记](docs/research-notes.md)
- [中文分析笔记](docs/analysis.zh-CN.md)
