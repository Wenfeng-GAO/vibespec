# VibeSpec

VibeSpec 是一个面向 AI coding agent 的工作流层，目标是帮助用户更稳定地 vibe coding 出正常的中等规模 app 和 web。

它不想做成又一个 AI app builder。它要解决的是：把一个模糊想法变成清晰的产品规格、分阶段实现任务、可见 checkpoint 和明确质量门禁，让 vibe coding 不再只靠 LLM 自由发挥。

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

## 核心工作流

1. **Define**：把想法转成 product brief、PRD、目标用户、用户旅程、功能列表、非目标和 MVP 范围。
2. **Design**：产出信息架构、页面清单、核心流程、交互状态、视觉方向和 design contract。
3. **Plan**：把规格拆成实现阶段、任务、依赖、风险和验证命令。
4. **Build**：让 coding agent 分阶段工作，每个阶段都停下来 review，而不是一口气盲跑到底。
5. **Verify**：检查需求覆盖、浏览器交互、视觉质量、可访问性和用户验收结果。

## MVP

第一版应该优先做三件高杠杆的事：

- **Spec Builder**：把 idea 转成 PRD、功能规格、页面清单、用户流程和验收标准。
- **Checkpoint Workspace**：围绕 PRD、设计、计划、实现和验证建立阶段性 review。
- **Quality Gates**：提供产品、设计、工程、浏览器 QA 和最终用户验收的质量门禁。

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

- 定义 VibeSpec 的 artifact model：brief、PRD、feature spec、design contract、implementation plan、verification report、UAT report。
- 构建常见 app/web 类型模板：SaaS、CRM、内部工具、marketplace、社区、AI app、dashboard、内容产品。
- 建立产品、设计、工程 review rubrics。
- 创建可以驱动现有 coding agent 的 staged workflow。
- 增加基于浏览器的验证：截图、路由检查、交互检查、视觉审查。
- 增加 dashboard：展示阶段状态、风险、未决问题、需求覆盖和用户审批。

## 状态

当前仓库是探索型 repo。第一阶段目标是把概念沉淀成具体的产品规格和 MVP 计划。

## 相关笔记

- [研究笔记](docs/research-notes.md)
- [中文分析笔记](docs/analysis.zh-CN.md)
