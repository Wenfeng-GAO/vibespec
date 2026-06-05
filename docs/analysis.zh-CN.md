# VibeSpec 中文分析笔记

## 结论

VibeSpec 不应该做成又一个 Lovable、Bolt 或 v0，而应该做成一个面向中等规模 app/web 的 **vibecoding workflow layer**。

它的核心价值是：在 AI coding agent 开始大量写代码之前，帮助用户把产品想法变成清晰的 PRD、功能设计、页面/流程设计、实现计划和验收标准；在实现过程中提供阶段性 checkpoint；在完成前用可验证证据判断质量是否达标。

架构更新：VibeSpec 的最终交付物明确为 **Codex Skill + Claude Skill + 共享 repo-local protocol + TypeScript validators**。它不是独立 CLI，也不是单纯 prompt pack。

## 当前问题

1. **需求不清楚**
   - 用户通常只有模糊想法，没有完整 PRD。
   - 功能边界、页面结构、用户流程和验收标准没有提前定义。
   - LLM 会自由补全空白，最后做出来的东西看似完成，但不是用户真正想要的。

2. **验证标准不明确**
   - LLM 容易把任务完成等同于产品完成。
   - 审美、交互状态、异常分支、响应式、可访问性、性能和工程质量都容易被弱化。
   - 没有明确 rubric 时，LLM 降低质量标准也不会显式告知用户。

3. **反馈太晚**
   - 很多 vibecoding 过程是一口气跑到底。
   - 用户只有最后才看到完整结果。
   - 一旦方向错了，返工成本很高。

## 产品定位

推荐定位：

> VibeSpec 是一个 spec-first、checkpoint-driven 的 vibecoding 产品工作台，帮助个人创作者和小团队用 AI coding agent 稳定构建中等规模 app/web。

它不是：

- prompt pack；
- 简单任务管理器；
- 单纯 QA checklist；
- 某个 coding agent 的 wrapper；
- one-shot app generator。

它应该是：

- 产品定义工具；
- 设计决策工具；
- 开发流程编排工具；
- 阶段性反馈工作台；
- 质量门禁系统；
- 可复用 skill/workflow pack。

## 推荐工作流

1. **Define**
   - idea -> product brief；
   - product brief -> PRD；
   - 明确目标用户、核心场景、MVP、非目标、成功标准。

2. **Design**
   - PRD -> 信息架构；
   - 页面清单、核心流程、交互状态、视觉方向；
   - 形成 design contract。

3. **Plan**
   - 设计与需求 -> 阶段计划；
   - 拆分任务、依赖、风险、验证命令和验收标准。

4. **Build**
   - coding agent 分阶段实现；
   - 每个阶段结束后必须停下来 review。

5. **Verify**
   - 需求覆盖；
   - 浏览器 QA；
   - 视觉审查；
   - 可访问性和响应式；
   - 用户验收。

## 近期建设重点

当前优先做四件事：

1. **Spec Builder**
   - 把想法生成 product brief、PRD、功能设计、页面清单、用户流程和验收标准。

2. **Checkpoint Workspace**
   - 给 PRD、设计、计划、实现、QA、UAT 设置明确 review 节点。

3. **Skill-native Workflow**
   - 用 Codex skill 和 Claude skill 直接驱动 agent 工作，并共享 `.vibespec/` 协议。

4. **Quality Gates**
   - 对产品、设计、工程、浏览器交互和最终验收提供 pass/fail 标准。

这些建设重点正好对应最初的三个痛点：需求不清、质量不稳、反馈太晚。

## GSD Core 是否符合

GSD Core 部分符合，适合作为底座或强参考，但不建议直接等同于 VibeSpec。

它已经做得比较好的部分：

- phase loop：discuss -> plan -> execute -> verify -> ship；
- repo-local planning artifacts；
- UI spec；
- plan checker；
- verification workflow；
- conversational UAT；
- 支持多个 coding agent。

它做不到或做得不够的部分：

- 不是产品定义工作台；
- PRD 不够产品化，缺用户画像、核心旅程、页面清单、数据权限、埋点、发布策略等；
- UI spec 偏设计约束，不是视觉探索或高保真设计工具；
- 审美和体验质量仍主要依赖用户判断；
- CLI/repo-local 形态对非技术用户门槛高；
- 缺可视化 checkpoint dashboard；
- 缺按 app/web 类型沉淀的模板体系。

推荐关系：

> GSD Core 可以作为工程执行流的参考或底层模式；VibeSpec 应该掌握更上游的产品定义、设计决策和可视化验收闭环。

## 可借鉴工具

### GitHub Spec Kit

适合借鉴：

- spec-driven development；
- constitution；
- clarify；
- checklist；
- specify -> plan -> tasks -> implement。

### Kiro Specs

适合借鉴：

- requirements / design / tasks 三段式；
- spec task UI；
- 阶段状态追踪；
- spec mode 和 vibe mode 的分流。

### BMad Method

适合借鉴：

- PM、Architect、UX、Developer、QA 等多角色；
- brainstorming、market research、architecture、design、development、deployment 全流程；
- agentic agile 的组织方式。

### OpenSpec / SpecDD / Colign

适合借鉴：

- repo-local spec；
- AI-readable spec；
- vendor-neutral；
- MCP-readable context。

### Task Master AI

适合借鉴：

- PRD -> tasks/subtasks/dependencies；
- 任务图；
- agent 执行中间层。

### Lovable / Bolt / Replit Agent / v0 / Firebase Studio / Figma Make

适合借鉴：

- 快速生成；
- live preview；
- 点选修改；
- 一键部署/分享；
- design-system-aware generation；
- 可视化原型反馈。

它们的不足也正是 VibeSpec 的机会：

- 生成快，但需求漂移仍然明显；
- 中等规模项目缺少强 PRD；
- 审美和体验门禁不稳定；
- 阶段验收不够系统。

### Agent Skills

适合借鉴：

- `SKILL.md + scripts + references + assets` 的能力封装；
- 可复用 workflow pack；
- marketplace 化。

## 本地已有 skill 参考

可以直接借鉴或包装：

- `product-design:get-context`
- `product-design:ideate`
- `product-design:image-to-code`
- `product-design:audit`
- `product-design:design-qa`
- `ce:brainstorm`
- `ce:plan`
- `ce:work`
- `ce:review`
- `document-review`
- `product-lens-reviewer`
- `design-lens-reviewer`
- `scope-guardian-reviewer`
- `security-lens-reviewer`
- `feasibility-reviewer`
- `frontend-design`
- `design-shotgun`
- `plan-design-review`
- `design-review`
- `design-iterator`
- `qa`
- `qa-only`
- `test-browser`
- `verification-before-completion`
- `agent-native-architecture`
- `agent-native-reviewer`

一个可行路径是：先做 VibeSpec skill/workflow pack，再逐步产品化成带 dashboard 的 web app。

## 下一步建议

1. 写 `docs/product-brief.md`。
2. 写 `docs/prd.md`。
3. 定义 artifact model。
4. 定义 checkpoint 和 quality gate。
5. 做第一个 workflow pack。
6. 用一个真实中等规模 app/web 项目试跑。
