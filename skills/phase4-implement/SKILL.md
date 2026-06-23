---
name: vibespec-phase4-implement
description: VibeSpec Phase 4 - 分步实现阶段。基于 TASKS.md 逐个执行实现 task，每次调用执行一个 task。读 state.json 确定当前 task、实现代码、自检、记录结果。连续 3 次失败触发人工介入。用于把技术方案转化为可工作代码。
argument-hint: "[task-id / continue / retry / status]"
---

# VibeSpec Phase 4: 分步实现

## 核心定位

你是 VibeSpec 的分步实现 agent，角色是执行工程师。你的任务是基于已确认的 PRD、DESIGN、TECH 和已拆分的 TASKS.md，逐个执行实现 task。每次调用只执行一个 task。

本 skill 与 Phase 1-3 根本不同:

- **Phase 1-3**: 单 session，线性工作流（Step 0-N），产出单个文档，不写代码
- **Phase 4**: 多 session，每次调用执行一个 task，产出代码文件，每个 task 在 fresh context 中运行

Phase 4 不需要人工确认来退出——所有 task 完成后自动标记阶段完成。

Phase 4 完成的唯一标准是:

1. `TASKS.md` 已生成（task 拆分完成）；
2. 所有 task 在 state.json 中标记为 `completed`；
3. 没有 task 处于连续 3 次失败待人工介入状态。

## 输入与产物

### 输入

- 已确认的 `docs/vibespec/{project-slug}/PRD.md`（Phase 1 产物）；
- 已确认的 `docs/vibespec/{project-slug}/DESIGN.md`（Phase 2 产物）；
- 已确认的 `docs/vibespec/{project-slug}/TECH.md`（Phase 3 产物）；
- `.vibespec/state.json` 中 `phases.tech.status === "confirmed"`；
- 当前代码仓库（实际实现目标）；
- `docs/vibespec/{project-slug}/TASKS.md`（如不存在则在 Step 0a 生成）。

### 产物

- `docs/vibespec/{project-slug}/TASKS.md` — task 拆分文档（首次调用时生成）；
- 代码文件 — 每个 task 在仓库中创建或修改实际实现代码；
- `.vibespec/state.json` — 每个 task 执行后更新状态、失败计数、完成摘要。

`{project-slug}` 从 `.vibespec/state.json` 的 `phases.tech.artifact` 路径中提取。

## 执行模式

本 skill 的每次调用遵循"执行循环"而非"线性工作流"：

```
每次调用:
  Step 0: 验证上游 + 加载状态
  Step 0a: Task 拆分（仅 TASKS.md 缺失时）
  Step 1: 读取当前 task
  Step 2: 实现
  Step 3: 自检
  Step 4: 记录结果 + 确定下一步
```

调用参数:

- 无 task-id: 读取 state.json，找下一个 pending task，宣布并等待用户确认执行
- `T{N}` 明确: 执行指定 task
- `continue`: 执行下一个 pending task
- `retry`: 重新执行上次失败的 task
- `status`: 报告当前 task 进度、完成/失败/待执行统计

## 硬约束

以下规则不可跳过:

1. 不一次改动过大范围。每个 task 只修改一个逻辑层或功能区域，最多 3-5 个文件。
2. 不在完成代码中留 TODO、FIXME、HACK、XXX 等占位符注释。未完成的部分不属于当前 task 范围。
3. 不跨 task 随意跳转。完成当前 task 后再考虑下一个。
4. 不忽略验证命令。必须执行验证命令并记录输出，不能"假设通过"。
5. 连续失败超过 2 次不自动重试。第 3 次连续失败时，标记 human-intervention-needed 并停止。
6. 不修改 task 允许修改范围外的文件。特别是 PRD.md、DESIGN.md、TECH.md（上游产物不可修改）。
7. 不写与 task 无关的代码。"顺带改一下"不属于当前 task 的范围。
8. 不跳过自检。必须在 state.json 中记录 pass/fail 结果和自检证据。

如果你发现自己违反任一规则，立即停止当前输出，说明偏离点，在 state.json 中记录失败原因。

## 交互规则

- 每次调用只执行一个 task。
- 执行前宣布 task 目标和允许修改范围。
- Task 失败时不做诊断对话——记录失败原因在 state.json，更新失败计数，停止。
- 连续 3 次失败时明确告知用户:"连续 3 个 task 失败，需要人工介入。最后失败的 task: T{N}。请检查 TASKS.md 和 state.json，定位问题后重新调用。"
- `status` 模式只输出当前进度概览，不执行任何 task。

## 执行循环

### Step 0: 验证上游与加载状态

先验证 Phase 3 完成状态:

1. 读取 `.vibespec/state.json`
2. 确认 `phases.tech.status === "confirmed"`
3. 从 `phases.tech.artifact` 路径提取 `{project-slug}`

如果 state.json 不存在或 tech 阶段未 confirmed:

> Phase 3 (Tech Plan) 尚未完成。请先完成 Tech Plan 阶段并确认 TECH.md，才能进入实现阶段。

验证通过后，读取上下文:

- `AGENTS.md`
- 已确认的 `docs/vibespec/{project-slug}/PRD.md`
- 已确认的 `docs/vibespec/{project-slug}/DESIGN.md`
- 已确认的 `docs/vibespec/{project-slug}/TECH.md`
- `.vibespec/state.json`（中 `phases.implement` 段，如有）

如果 `phases.implement` 不存在（首次调用）：

- 检查 `docs/vibespec/{project-slug}/TASKS.md` 是否存在
- 如不存在 → 进入 Step 0a
- 如存在 → 读取 TASKS.md，初始化 `state.json` 的 `phases.implement` 段

如果 `phases.implement.status === "human-intervention-needed"`：

- 检查上次失败 task 和失败原因
- 报告状态，询问用户下一步（手动指定 task-id / retry / 修改 TASKS.md）

如果 `phases.implement.status === "completed"`：

> Phase 4 已全部完成。所有 task 均已通过。进入 Phase 5 (集成验证)。

如果 `phases.implement.status === "in-progress"`：

- 读取 `phases.implement.tasks` 中各 task 状态
- 找到下一个 `pending` 的 task

#### Step 0 完成标准

- state.json 已验证，Phase 3 为 confirmed
- project-slug 已确定
- PRD/DESIGN/TECH 已读取
- TASKS.md 存在（或已触发 Step 0a）

### Step 0a: Task 拆分（仅 TASKS.md 缺失或首次初始化时）

分析 TECH.md（目录结构、数据模型、组件树、API 契约）和 PRD.md P0 需求，拆分 TASKS.md。

拆分规则:

1. **依赖排序**: 基础设施先于业务逻辑。顺序: 项目脚手架 → 基础 UI 组件 → 类型/数据模型 → 数据层 → 服务/API 层 → 工具/工具函数 → 状态管理 → 布局组件 → 页面组件 → 页面路由集成 → 质量收尾（响应式/深色/a11y）

2. **逻辑单元**: 每个 task 对应 TECH.md 中的一个逻辑单元（一组组件、一个数据模型、一个 service、一个 store、一个 lib 模块）。一个 task 至多修改 3-5 个文件。

3. **P0 覆盖**: 所有 PRD P0 需求必须在 task 覆盖范围中。

4. **P1/P2 标注**: P1 和 P2 需求对应的 task 标注 `[P1]` 或 `[P2]`，排在 P0 task 之后。

5. **稳定 ID**: 每个 task 使用稳定 ID（T1, T2, T3...），后续 task 可按 ID 引用前置 task。

`TASKS.md` 模板:

```markdown
# {产品名} - 实现任务列表

## 任务概览

- 总任务数: N
- P0 任务: N
- P1 任务: N
- P2 任务: N

---

## T1: {task 目标}

- 前置依赖: 无（或 T{N}）
- 允许修改范围:
  - `src/{目录}`（新建/修改）
- 预期产出:
  - {文件 1}: {说明}
  - {文件 2}: {说明}
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
  - [ ] {额外验证命令或手动检查项}
- 对应需求: {R1, R2...}

---

## T2: {task 目标}
...

---

## T{N}: {task 目标}
...
```

如果 `TASKS.md` 已存在（写入后发现有遗漏），在拆分完成后由用户决定是否修订。

写入 TASKS.md 后，初始化 `state.json` 的 `phases.implement` 段:

```json
{
  "phases": {
    "...已有记录原样保留...": {},
    "implement": {
      "status": "in-progress",
      "artifact": "docs/vibespec/{project-slug}/TASKS.md",
      "tasks": {
        "T1": {"status": "pending"},
        "T2": {"status": "pending"}
      },
      "consecutiveFailures": 0,
      "startedAt": "YYYY-MM-DDTHH:mm:ssZ"
    }
  }
}
```

#### Step 0a 完成标准

- TASKS.md 已写入磁盘
- state.json implement 段已初始化
- 所有 task 状态为 pending
- 继续执行 Step 1（首次 task）

### Step 1: 读取当前 task

1. 从 `state.json` 的 `phases.implement.tasks` 中找到下一个 `pending` 的 task
2. 从 TASKS.md 中读取该 task 的完整定义
3. 更新 state.json: `currentTask: "T{N}"`
4. 宣布:

> 执行 T{N}: {task 目标}
> 
> 允许修改范围: {文件/目录列表}
> 预期产出: {文件列表}
> 
> 开始实现。

#### Step 1 完成标准

- 当前 task 已确定并宣布
- state.json currentTask 已更新

### Step 2: 实现

1. 读取允许修改范围内已存在的代码文件
2. 按预期产出实现代码
3. 遵循 TECH.md 中的技术约束:
   - TypeScript strict 模式
   - 目录结构与 TECH.md 一致
   - 使用 TECH.md 指定的技术栈和依赖
   - 数据模型字段与 TECH.md 实体定义一致
   - API 调用遵循 TECH.md 契约
4. 写入所有新建/修改的文件

### Step 3: 自检

实现完成后，执行以下自检:

代码质量:

- 运行 `pnpm typecheck`（如 TypeScript 项目已配置）
- 运行 `pnpm lint`（如 lint 已配置）
- 检查无 TODO/FIXME/HACK/XXX 占位符注释
- 检查所有文件在 task 允许修改范围内

预期产出检查:

- 验证所有"预期产出"中列出的文件已创建或修改
- 检查代码遵循 TECH.md 的目录结构和命名约定

#### Step 3.1: MUST-HAVE 逐项验证（EXISTS / SUBSTANTIVE / WIRED）

> 引入自管的逐项验证，补"typecheck 能过但近 stub / 写了却没接线"的盲点。本检查由实现者自管，不新增 agent，全程在 task 允许的文件范围内进行。

对 TASKS.md 该 task「预期产出」中列出的每个文件，按三级判定并记录结果:

1. **EXISTS** — 文件已创建/修改且非空。
2. **SUBSTANTIVE** — 非占位实现: 文件中有真实逻辑/接线，不是空壳导出、空函数体、`throw new Error('not implemented')`、纯注释占位，且无 TODO/FIXME/HACK/XXX。
3. **WIRED** — 已被接线使用: 文件中导出的核心符号至少被本 task 范围或已 completed 的前置 task 范围内某处 import/引用；对应 TECH.md 契约（数据模型字段、API 调用签名、组件 props）与定义一致。

判定与赋值:

- 三级全部满足 → `passed`
- EXISTS 满足但 SUBSTANTIVE 或 WIRED 不满足 → 逐项记 `failed`，并在 evidence 里写明缺哪一级与具体文件/符号
- 仅在「该文件按设计本就不应被当前范围接线」（如纯类型导出仅供后续 task 引用，且已在 TASKS.md 标注为前置产出）时，WIRED 可记 `n/a` 并注明理由；其余情况 WIRED 必须判定，不允许跳过

机械化优先: 判定基于「文件存在 + 无 placeholder + 不引用未实现模块（除已标前置 task）+ 符号被 import + 字段/签名匹配 TECH.md」，不做主观行为级判断，避免自评变软。

在 state.json 中记录（见 `state.json 完整格式` 一节的 `selfCheck.evidence`）:

```json
"selfCheck": {
  "result": "passed | failed",
  "evidence": [
    { "file": "src/services/auth.ts", "exists": true, "substantive": true, "wired": true },
    { "file": "src/lib/token.ts", "exists": true, "substantive": true, "wired": "n/a", "wiredReason": "纯类型导出，供 T5 引用，已在 TASKS.md 标注前置" }
  ]
}
```

任一文件 `failed`（非 `n/a`）→ 本 task 自检未通过，进入 Step 4「自检未通过」分支，`consecutiveFailures` +1。

#### Step 3 其余手动检查（如 project 尚未初始化 typecheck/lint）:

- TypeScript: 无显式类型错误（用 IDE 或人工 review 判断）
- 导入路径: 所有 import 路径存在且正确
- 未引用尚未实现的模块（除已标注的前置 task）

#### Step 3 完成标准

- 所有自检项有明确 pass/fail 结果
- MUST-HAVE 逐项 evidence 已记录（EXISTS/SUBSTANTIVE/WIRED，每文件一档）
- Fail 项有具体说明（含失败文件与缺失等级）

### Step 4: 记录结果与确定下一步

#### 自检通过

更新 state.json:

```json
{
  "phases": {
    "implement": {
      "tasks": {
        "T{N}": {
          "status": "completed",
          "completedAt": "ISO8601",
          "selfCheck": {
            "result": "passed",
            "evidence": [
              { "file": "{file}", "exists": true, "substantive": true, "wired": true }
            ]
          }
        }
      },
      "consecutiveFailures": 0
    }
  }
}
```

在 TASKS.md 末尾追加或更新 task 的完成总结:

```markdown
### T{N} 完成总结

- 完成时间: {ISO8601}
- 创建/修改的文件: {文件列表}
- 自检结果: typecheck ✓ / lint ✓ / 预期产出 ✓
```

#### 自检未通过

更新 state.json:

```json
{
  "phases": {
    "implement": {
      "tasks": {
        "T{N}": {
          "status": "failed",
          "failedAt": "ISO8601",
          "reason": "{具体失败原因}",
          "attempt": N,
          "selfCheck": {
            "result": "failed",
            "evidence": [
              { "file": "{file}", "exists": true, "substantive": false, "wired": "failed", "wiredReason": "{缺哪一级/具体符号}" }
            ]
          }
        }
      },
      "consecutiveFailures": N
    }
  }
}
```

> T{N} 自检未通过。失败原因: {原因}。连续失败: {N}。

如果 `consecutiveFailures >= 3`:

更新 state.json:

```json
{
  "phases": {
    "implement": {
      "status": "human-intervention-needed"
    }
  }
}
```

> ⚠️ 连续 3 个 task 失败。需要人工介入。
> 
> 最后失败的 task: T{N}
> 失败原因: {原因}
> 
> 建议: 检查 TASKS.md 的 task 拆分是否合理、前置依赖是否满足、允许修改范围是否足够。纠正后重新调用，指定 task-id 继续。

停止，不再自动继续。

#### 全部完成

如果所有 task 状态均为 `completed`:

更新 state.json:

```json
{
  "phases": {
    "implement": {
      "status": "completed",
      "completedAt": "ISO8601"
    }
  }
}
```

> Phase 4 全部完成。所有 N 个 task 均已通过。
> 
> 下一步: 进入 Phase 5 (集成验证)，检查实现结果是否满足 PRD、DESIGN 和 TECH。

停止，不自动进入 Phase 5。

#### 还有待执行 task

> T{N} 完成。下一个 task: T{N+1}: {目标}。再次调用继续。

停止，等待下一次调用。

## state.json 完整格式

Phase 4 阶段 state.json 格式:

```json
{
  "phases": {
    "define": {
      "status": "confirmed",
      "artifact": "docs/vibespec/{project-slug}/PRD.md",
      "confirmedAt": "<原值保留>"
    },
    "design": {
      "status": "confirmed",
      "artifact": "docs/vibespec/{project-slug}/DESIGN.md",
      "confirmedAt": "<原值保留>"
    },
    "tech": {
      "status": "confirmed",
      "artifact": "docs/vibespec/{project-slug}/TECH.md",
      "confirmedAt": "<原值保留>"
    },
    "implement": {
      "status": "in-progress | completed | human-intervention-needed",
      "artifact": "docs/vibespec/{project-slug}/TASKS.md",
      "tasks": {
        "T1": {
          "status": "completed",
          "completedAt": "ISO8601",
          "selfCheck": {
            "result": "passed",
            "evidence": [
              { "file": "src/{path}", "exists": true, "substantive": true, "wired": true }
            ]
          }
        },
        "T2": {
          "status": "failed",
          "failedAt": "ISO8601",
          "reason": "...",
          "attempt": 1,
          "selfCheck": {
            "result": "failed",
            "evidence": [
              { "file": "src/{path}", "exists": true, "substantive": false, "wired": true }
            ]
          }
        },
        "T3": {"status": "pending"}
      },
      "consecutiveFailures": 1,
      "currentTask": "T2",
      "startedAt": "ISO8601",
      "completedAt": "ISO8601"
    }
  }
}
```

status 枚举:
- `pending`: 尚未执行
- `in-progress`: 正在执行（Step 2 开始时更新）
- `completed`: 已通过自检
- `failed`: 自检未通过

attempt: 失败重试次数（从 1 开始），用于区分"第一次失败"和"重试后仍然失败"