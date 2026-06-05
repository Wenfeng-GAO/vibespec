# Phase 1 方案设计：Define Skill

日期：2026-06-05
状态：已落实到 `skills/phase1-define/SKILL.md`

## 结论

当前阶段只做 Define skill，目标是把一句话产品想法转成可确认的 `PRD.md`。

这不是轻量 MVP，也不做 CLI。Define 阶段的门禁由 skill 协议、`PRD.md` frontmatter 和用户逐段确认完成。

## 研究范围

本轮对比了 5 类与“想法到产品定义”相关的开源实现。

| 体系 | 代表工具 | Stars（2026-06-05） | 核心能力 | 对 Define 的适配 |
|------|----------|-------------------:|----------|------------------|
| Superpowers | brainstorming | 218607 | 1 问 1 答、方案对比、逐段验证、硬门禁 | 借鉴门禁和逐段确认，不能照搬架构/测试内容 |
| Compound Engineering | ce-brainstorm | 19858 | Pressure Test、需求文档、scope 分级、document-review | Define 主参考 |
| GitHub Spec Kit | specify + clarify | 108959 | taxonomy 覆盖扫描、clarify、质量 checklist | 借鉴澄清和质量门禁 |
| GSD Core | discuss-phase + phase loop | 2772 | 阶段循环、状态持久化、REQ-ID 覆盖 | 借鉴节奏和覆盖意识，不借实现决策 Discuss |
| Task Master | PRD template | 27326 | PRD 到 task 管理 | 只借产品概览和用户体验结构 |

横向对比详见 `docs/phase1-define-skill-comparison-2026-06-05.md`。

## 各工具借鉴清单

### 从 Superpowers 借鉴

- 硬门禁：用户确认前不进入实现。
- 逐段验证：一次只确认一组内容，降低整篇 PRD 一次性审查的负担。
- 方案对比：当存在多个合理产品方向时，先展示 2-3 个方向和取舍。
- 自检：写完文档后检查占位符、矛盾、范围和歧义。

不借鉴：

- 架构、组件、数据流、测试设计，这些属于 Design/Tech/Implementation 阶段。
- 写完 spec 后自动进入 planning。

### 从 CE Brainstorm 借鉴

- Product Pressure Test：
  - 谁的什么问题？
  - 现在怎么解决？
  - 如果不做会怎样？
  - 最小可证明版本是什么？
  - 什么情况下会失败？
- 一次只问一个问题。
- 不让后续阶段发明产品行为。
- 阻断性问题和延后问题分层。
- 稳定需求 ID：`R1`、`R2`、`R3`。

需要改写：

- CE 的 handoff 是 `ce-plan`，VibeSpec Define 的 handoff 只能是 Design 阶段提示。
- CE 默认产物是 requirements doc，VibeSpec 产物固定为 `PRD.md`。

### 从 Spec Kit 借鉴

- taxonomy 覆盖扫描：
  - 功能范围；
  - 用户和角色；
  - 用户旅程；
  - 交互状态；
  - 非功能质量；
  - 集成依赖；
  - 边界情况；
  - 约束权衡；
  - 术语一致性；
  - 完成信号；
  - 占位符检测。
- Priority = Impact x Uncertainty：优先问最影响后续返工的问题。
- checklist：PRD 写完后检查是否可测、可衡量、无实现细节。

需要改写：

- Spec Kit `clarify` 的 5 题上限适合后置澄清，不适合完整 Define 全流程。
- Spec Kit 的 branch、specs 目录、hook 和 plan handoff 不进入当前 skill。

### 从 GSD Core 借鉴

- 阶段节奏：一个阶段只解决一个阶段的问题。
- 状态持久化思想：下游阶段读取上游产物，而不是依赖聊天上下文。
- REQ-ID 覆盖：后续 Design/Tech/Verify 可以追踪 `R1/R2/R3`。

不借鉴：

- `.planning/STATE.md`；
- Discuss 里的实现偏好收集；
- worktree、Plan、Execute、Verify、Ship。

### 从 Task Master 借鉴

- PRD 中需要产品概览、核心功能、用户体验和风险。

不借鉴：

- Technical Architecture；
- Development Roadmap；
- Logical Dependency Chain；
- task/subtask 生成。

## VibeSpec Define Skill 组合方案

```
VibeSpec Define Skill =
    本地上下文读取
  + 外部/竞品研究（用于发现问题，不替用户拍板）
  + 多视角研究包（用户场景 / 产品边界 / 风险假设 / 对标模式）
  + CE 的 Product Pressure Test
  + 单问题产品定义对话
  + Superpowers 的 2-3 个产品方向对比
  + Spec Kit 的覆盖扫描和质量 checklist
  + BMAD/Spec Kit 风格的 Persona、旅程、P0/P1/P2
  + VibeSpec 独有的 Define-only 边界和 PRD 确认门禁
```

## PRD.md 强制模板

`PRD.md` 使用 frontmatter 表示 Define 状态：

```markdown
---
phase: define
status: draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
confirmed_at:
---
```

正文必须包含：

- 产品目标；
- 目标用户；
- 核心场景与用户旅程；
- P0/P1/P2 功能需求；
- 成功标准；
- 不做什么；
- 风险与未决问题；
- 假设；
- 术语表；
- 确认记录。

确认后将 `status` 改为 `confirmed` 并写入 `confirmed_at`。

## 反模式防御规则

Define skill 加载时注入以下约束：

1. 不写任何代码，包括示例代码、伪代码、命令行。
2. 不设计技术架构，包括 API、数据模型、目录结构、框架选择。
3. 不跳过“不做什么”的讨论。
4. 不在用户确认前推断 P0/P1 核心需求。
5. 不把功能列表当成 PRD，必须有场景和旅程。
6. PRD 未确认前，不生成任何实现 task。
7. 不主动进入 Design 阶段，只提示下一步。

## Phase 1 门禁

门禁类型：Skill 内人工确认。

门禁机制：

- `PRD.md` 初始为 `status: draft`；
- 按 5 组逐段确认：
  - 产品目标与目标用户；
  - 核心场景与用户旅程；
  - 功能需求与优先级；
  - 成功标准与不做什么；
  - 风险、假设与未决问题；
- 所有组确认后，用户进行最终确认；
- 最终确认后，`PRD.md` frontmatter 改为 `status: confirmed`。

不使用 CLI，不使用 `.vibespec/state.json`。

## 已完成实现

`skills/phase1-define/SKILL.md` 已按本方案重写，包含：

- Define-only 核心定位；
- 输入和产物定义；
- 硬约束；
- 交互规则；
- 恢复与上下文读取；
- 研究包；
- 产品压力测试；
- 产品定义对话；
- 方案对比；
- 覆盖扫描；
- `PRD.md` 模板；
- PRD 质量门禁；
- 逐段确认；
- Define 完成协议。
