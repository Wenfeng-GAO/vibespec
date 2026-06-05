# 研究笔记

这份文档记录 VibeSpec 的第一轮产品探索。

## 核心洞察

中等规模 app 和 web 项目不只需要一个快速 coding agent。它们还需要一个工作流，强制产品定义清晰、阶段性 review 明确、验证证据具体，避免实现过程漂移太远。

VibeSpec 的机会不是替代 Lovable、Bolt、Replit Agent、v0、Cursor、Claude Code、Codex 或 Gemini CLI，而是编排这些工具周围的产品定义、设计决策、实现节奏和验收流程。

## 用户痛点

1. **产品定义不清**
   - 用户经常从一个模糊想法开始，而不是从 PRD 开始。
   - 功能行为、页面结构、用户旅程和验收标准都是隐式的。
   - Agent 会自由补全空白，所以结果即使“能用”，也可能不是用户真正想要的。

2. **验证标准太弱**
   - Agent 可能把 task completion 当成 product quality。
   - 视觉质量、UX 状态、边界情况、可访问性、性能和可维护性经常没有被充分定义。
   - 如果没有 rubric，agent 降低质量标准时用户也未必知道。

3. **反馈太晚**
   - 很多 vibe-coding session 像一次长时间盲跑。
   - 用户太晚才看到真实产品形态。
   - 基础决策已经写进代码后，返工会变得很贵。

## 产品假设

VibeSpec 应该是一个面向 vibe coding 的 **workflow layer**：

- 位于实现之前；
- 不绑定某一个 coding agent；
- artifact-driven；
- checkpoint-driven；
- verification-driven。

它应该让 agent 问更好的问题、产出更好的计划、在有价值的位置停下来 review，并用具体证据证明质量。

## 参考工具

### GitHub Spec Kit

参考链接：<https://github.com/github/spec-kit>

适合借鉴：

- Spec-driven development flow；
- 用 constitution 固化长期项目原则；
- plan 前先 clarify；
- implementation 前先 checklist；
- specify、plan、tasks、implement、clarify、analyze、checklist 等命令。

对 VibeSpec 的不足：

- Spec Kit 强在工程流程，但对视觉探索、用户侧产品 review 和非专家 checkpoint UX 支持较弱。

### Kiro Specs

参考链接：<https://kiro.dev/docs/specs/>

适合借鉴：

- requirements、design、tasks 三段式；
- task status 和 guided execution UI；
- 明确区分快速 vibe work 和 spec work；
- 更适合长周期 feature continuity。

对 VibeSpec 的不足：

- 体验仍然偏 IDE agent。VibeSpec 可以更工具中立，也更 product/design-first。

### BMad Method

参考链接：<https://github.com/bmad-code-org/BMAD-METHOD>

适合借鉴：

- analyst、PM、architect、UX、developer、QA 等多 agent 角色；
- implementation 前先沉淀 planning artifacts；
- agentic agile 的组织方式；
- build 前的 brainstorming 和 research 阶段。

对 VibeSpec 的不足：

- 能力很强，但方法感偏重。VibeSpec 应该为个人创作者和小团队压缩流程复杂度。

### GSD Core

参考链接：<https://github.com/open-gsd/gsd-core>

适合借鉴：

- phase loop：discuss、plan、execute、verify、ship；
- project、requirements、roadmap、context、validation、plan、summary、verification、UAT 等 planning artifacts；
- UI spec contract；
- plan checker 和 verification workflow；
- conversational UAT。

它不能完全解决：

- 产品发现和产品策略；
- 面向用户旅程、页面清单、埋点、权限、发布决策的深层 PRD；
- 视觉探索和高保真设计 review；
- 非技术用户可用的 dashboard 体验；
- 常见 app/web 类型模板。

### OpenSpec、SpecDD 和 Colign

参考链接：

- <https://github.com/Fission-AI/OpenSpec>
- <https://specdd.ai/>
- <https://www.colign.co/>

适合借鉴：

- repo-local specs；
- AI-readable product context；
- vendor-neutral assistant support；
- 可以随代码库一起移动的轻量 spec 文件。

对 VibeSpec 的不足：

- 它们更像基础设施或协议层。VibeSpec 可以在其上提供产品工作流和用户体验。

### Task Master AI

参考链接：<https://docs.task-master.dev/getting-started/quick-start/prd-quick>

适合借鉴：

- PRD 到 tasks 和 subtasks；
- dependency-aware task graph；
- 面向执行的 task breakdown。

对 VibeSpec 的不足：

- 更偏任务管理，产品/设计验证能力不足。

### AI App Builders

参考链接：

- Lovable：<https://docs.lovable.dev/>
- Bolt：<https://bolt.new/>
- Replit Agent：<https://docs.replit.com/references/agent/overview>
- v0：<https://v0.app/docs>
- Firebase Studio：<https://firebase.google.com/docs/studio/get-started-ai>
- Figma Make：<https://developers.figma.com/docs/code/intro-to-figma-make/>

适合借鉴：

- 快速生成循环；
- live preview；
- point-and-edit feedback；
- 一键部署或分享；
- design-system-aware generation；
- visual-first prototyping。

对 VibeSpec 的不足：

- 这些工具生成很快，但中等规模产品仍然需要更强的 PRD 纪律、阶段审批、需求覆盖检查和质量门禁。

### Agent Skills

参考链接：

- <https://agentskills.io/>
- <https://code.claude.com/docs/en/skills>

适合借鉴：

- Skills 作为可复用 workflow package；
- 用文件封装 instructions、scripts、references 和 assets；
- marketplace 或 shareable packs。

对 VibeSpec 的不足：

- Skills 提供能力，但用户仍然需要一个有主张的 workflow，决定何时运行哪个 skill。

## 本地 skill 参考

探索中发现的有价值本地 skills：

- `product-design:get-context`、`product-design:ideate`、`product-design:image-to-code`、`product-design:audit`、`product-design:design-qa`
- `ce:brainstorm`、`ce:plan`、`ce:work`、`ce:review`
- `document-review`、`product-lens-reviewer`、`design-lens-reviewer`、`scope-guardian-reviewer`、`security-lens-reviewer`、`feasibility-reviewer`
- `frontend-design`、`design-shotgun`、`plan-design-review`、`design-review`、`design-iterator`
- `qa`、`qa-only`、`test-browser`、`verification-before-completion`
- `agent-native-architecture`、`agent-native-reviewer`

这些 skill 说明：VibeSpec 可以先从 curated workflow 和 skill pack 形态开始，再逐步演进为完整产品 UI。

## 推荐 MVP 形态

### 1. Spec Builder

把 idea 转成：

- product brief；
- PRD；
- 用户画像；
- 用户旅程；
- 页面清单；
- feature specs；
- acceptance criteria；
- non-goals；
- risks；
- open decisions。

### 2. Checkpoint Workspace

创建明确停顿点：

- product brief approval；
- PRD review；
- design direction review；
- implementation plan review；
- phase implementation review；
- browser QA review；
- UAT approval。

### 3. Quality Gates

每个阶段都需要 pass/fail evidence：

- requirement coverage；
- UX flow coverage；
- visual quality；
- responsive behavior；
- accessibility；
- browser interaction；
- engineering tests；
- deployment readiness。

## 产品差异化

VibeSpec 应该结合：

- Spec Kit 和 Kiro 的 spec discipline；
- BMad 的 role-based product thinking；
- GSD Core 的 phase loop 和 verification；
- Lovable、v0、Figma Make 的 visual feedback loop；
- Agent Skills 的 reusable capability packaging。

切入口是：

> 帮助个人创作者和小团队在 vibe coding 中等规模产品时，不丢失产品意图、设计质量和交付信心。

## 后续可以沉淀的产物

- `docs/product-brief.md`
- `docs/prd.md`
- `docs/mvp-plan.md`
- `docs/workflow.md`
- `docs/artifact-model.md`
- `docs/quality-gates.md`
- `docs/competitive-map.md`
- `skills/`
- `templates/`
