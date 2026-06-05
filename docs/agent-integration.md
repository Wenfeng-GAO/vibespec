# Agent 集成架构

## 结论

VibeSpec 的最终架构不是 CLI-first，而是 **skill-first**：

```text
VibeSpec = Codex Skill + Claude Skill + Repo-local Protocol + TypeScript Validators
```

Codex 和 Claude Code 是两个执行入口。`.vibespec/` 是共享事实来源。TypeScript validators 负责确定性检查。Skill 负责把 VibeSpec 工作流放进 agent 的上下文里。

## 为什么不把 CLI 作为核心

独立 CLI 很容易陷入 agent 集成黑洞：

- prompt 如何发给 Codex 或 Claude Code；
- agent 执行结果如何回流；
- agent 什么时候算完成；
- agent 失败后如何重试；
- agent 能否修改状态；
- 状态机如何证明推进是合法的。

Skill-native 的方式更贴近 agent 的真实工作流。它不需要另起一个 agent runner，而是让 Codex 和 Claude Code 在各自运行时里遵守同一套协议。

## 交付物

### Codex Skill

建议结构：

```text
skills/codex/vibespec/
  SKILL.md
  references/
    workflow.md
    protocol.md
    gates.md
  templates/
    PRD.md
    DESIGN.md
    TECH.md
    TASKS.md
    VERIFY.md
  scripts/
    validate-state.ts
    validate-artifact.ts
    validate-gate.ts
```

### Claude Skill

建议结构：

```text
skills/claude/vibespec/
  SKILL.md
  references/
    workflow.md
    protocol.md
    gates.md
  templates/
    PRD.md
    DESIGN.md
    TECH.md
    TASKS.md
    VERIFY.md
  scripts/
    validate-state.ts
    validate-artifact.ts
    validate-gate.ts
```

两个 skill 可以有不同的包装方式，但必须共享同一套协议语义。

### 共享协议

项目内生成：

```text
.vibespec/
  config.json
  state.json
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

## 权威边界

### Skill 负责

- 读取当前状态；
- 判断当前阶段；
- 指导 agent 生成或更新 artifact；
- 要求 agent 输出 run report；
- 要求 agent 输出 gate report；
- 在门禁允许时更新状态；
- 在需要人工确认时停止。

### Protocol 负责

- 统一 Codex 和 Claude Code 的读写格式；
- 记录当前阶段；
- 记录 artifact 版本和依赖；
- 记录 gate 结果；
- 记录 change request；
- 记录 override；
- 记录失败次数。

### Validators 负责

- 检查 JSON schema；
- 检查 Markdown 必填章节；
- 检查阶段流转是否合法；
- 检查 gate report 是否完整；
- 检查 artifact 依赖是否 stale；
- 检查失败次数是否触发人工介入；
- 检查 override 是否有原因和风险说明。

### 用户负责

- 确认产品定义；
- 确认设计规约；
- 确认最终验收；
- 对产品方向、审美质量和关键取舍做判断。

## Agent 执行循环

每次 agent 工作都走同一套循环：

1. 读取 `AGENTS.md` 和当前 skill 指令。
2. 读取 `.vibespec/state.json`。
3. 判断当前阶段和阻塞原因。
4. 读取当前阶段所需 artifact。
5. 生成或更新目标 artifact。
6. 写入 `.vibespec/runs/<timestamp>-<agent>-<phase>.md`。
7. 运行 TypeScript validators。
8. 写入 `.vibespec/gates/<timestamp>-<phase>.json`。
9. 如果是自动门禁，基于 gate report 更新 `state.json`。
10. 如果是人工确认门禁，停止并请求用户确认。

## 状态更新规则

Agent 不能只因为自己认为完成了就推进状态。

状态推进必须满足：

- 目标 artifact 已存在；
- run report 已存在；
- gate report 已存在；
- validators 通过或明确记录失败；
- 当前阶段允许推进；
- 人工确认型门禁有用户明确确认；
- 下游 artifact 没有未处理的 stale 标记。

## 回退和失效

后期发现上游产物有问题时，不应该手工乱改状态，而是创建 change request。

建议规则：

- 修改 `PRD.md` 后，`DESIGN.md`、`TECH.md`、`TASKS.md`、`VERIFY.md` 自动标记 stale。
- 修改 `DESIGN.md` 后，`TECH.md`、`TASKS.md`、`VERIFY.md` 自动标记 stale。
- 修改 `TECH.md` 后，`TASKS.md`、`VERIFY.md` 自动标记 stale。
- 修改 `TASKS.md` 后，`VERIFY.md` 自动标记 stale。

Change request 应包含：

- 变更原因；
- 影响的 artifact；
- 需要重新确认的阶段；
- 是否阻塞当前工作；
- 用户确认记录。

## Gate Report

每个门禁都要生成 gate report，而不是只在聊天里说“通过”。

建议字段：

```json
{
  "phase": "design-spec",
  "status": "pass",
  "checkedAt": "2026-06-05T00:00:00.000Z",
  "agent": "codex",
  "artifacts": ["docs/vibespec/DESIGN.md"],
  "checks": [
    {
      "id": "routes-present",
      "status": "pass",
      "evidence": "DESIGN.md 包含路由表"
    }
  ],
  "requiresHumanApproval": true,
  "humanApproval": null,
  "risks": [],
  "nextAction": "等待用户确认 DESIGN.md"
}
```

## Run Report

每次 agent 工作都要写 run report。

建议包含：

- 本次目标；
- 输入 artifact；
- 修改的文件；
- 执行的检查；
- 失败和重试；
- 未解决问题；
- 下一步建议。

## 关键设计原则

- Skill 是执行入口，不是全部状态来源。
- `.vibespec/` 是跨 agent 的共享事实来源。
- Validators 做确定性检查，不代替产品判断。
- 人工确认型门禁必须停下来等用户。
- 任何 override 都必须留下原因、风险和补偿动作。
- Codex 和 Claude Code 可以有不同操作方式，但不能有不同 workflow 语义。

## 下一步

1. 写 `docs/protocol.md`，定义 `.vibespec/` schema。
2. 写 `docs/gates.md`，定义每个阶段的实质性 rubric。
3. 创建 `skills/codex/vibespec/SKILL.md` 草案。
4. 创建 `skills/claude/vibespec/SKILL.md` 草案。
5. 创建 TypeScript validator 脚本骨架。
