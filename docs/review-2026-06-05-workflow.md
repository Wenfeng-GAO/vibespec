# Workflow.md Review Report

日期：2026-06-05
审查文档：docs/workflow.md
审查方法：document-review (multi-persona)

## 审查者

| Persona | 状态 | Findings | Auto | Present | Residual |
|---------|------|----------|------|---------|----------|
| coherence | completed | 5 | 0 | 5 | 3 |
| feasibility | completed | 5 | 2 | 3 | 4 |
| product-lens | completed | 6 | 0 | 6 | 0 |
| adversarial | completed | 5 | 0 | 5 | 5 |
| scope-guardian | failed | -- | -- | -- | -- |

## Auto-fixes Applied

- 添加状态文件错误处理契约（缺失/损坏/无效/空状态文件的行为定义）
- 添加状态-产物一致性权威规则（文件系统为权威来源，每次加载时校验产物存在性）

## P0 - Must Fix

1. **Agent 提示词生成与交接机制未定义** (feasibility, 0.90)
   CLI 负责"生成当前阶段提示词"，Agent Adapter 负责"转为 agent 可执行方式"，但从未指定具体机制——写入 stdout？写入文件？管道传入子进程？没有这个契约，核心集成环路无法构建。

2. **状态机过于线性，无法支持迭代开发** (product-lens + adversarial, 0.85)
   状态图只有一个回边（IntegrationVerify → StepImplementation）。设计中发现的 PRD 缺陷、技术约束倒逼的设计变更，都没有合法的回退路径。

## P1 - Should Fix

3. **认知负担与 solo developer 目标用户不匹配** (product-lens, 0.72)
   设计目标说"保持 CLI 足够轻"，但 v1 实际包括 5 阶段、7 个 CLI 命令、配置 schema、状态 schema 等。

4. **Agent 执行结果没有回流到状态管理的机制** (adversarial, 0.80)
   架构图只有单向流 CLI→Adapter→Agent，但状态文件需要记录执行结果、门禁结果、失败次数。

5. **门禁验证的是产物完整性和形式，而非实质性正确性** (product-lens + adversarial, 0.88)
   LLM 自检只检查"产物是否完整""命令是否执行"，无法判断产物是否正确。

6. **所有成功标准测量的是工具机制，而非输出质量是否改善** (product-lens + adversarial, 0.90)
   10 条标准全是工具操作指标，无一条衡量代码质量、返工率或用户满意度。

7. **"连续 3 次失败"计数范围和重置规则未定义** (coherence, 0.82)
   同一 task 重试 3 次？跨 task 累计？成功后是否清零？

8. **`run-task` 中的"当前 task"与 TASKS.md 多任务模型未建立映射** (coherence, 0.72)

9. **Agent Adapter 接口和契约完全被推迟** (feasibility, 0.85)
   Adapter 是核心差异化能力，但其接口完全未定义。

10. **未引用用户痛点证据来支撑构建解决方案** (product-lens, 0.75)

## P2 - Consider Fixing

11. Phase 3 门禁中"可以要求人工确认"与 LLM 自检章节描述不一致 (coherence, 0.60)
12. Agent-neutral 抽象在未理解 agent 差异前就建立 (product-lens + adversarial, 0.70)
13. Override 行为契约不完整 (feasibility, 0.68)
14. VibeSpec 自身的提示词生成策略模糊 (feasibility, 0.70)
15. "Agent workflow pack"术语仅出现一次且未定义 (coherence, 0.65)

## 核心设计债务

1. **状态机过于线性**——缺少从后期阶段回退到前期产物的路径
2. **Agent 集成是黑洞**——提示词如何发给 agent、执行结果如何回流，全部未定义
3. **门禁验证形式不验证实质**——只能验证"有没有产出物"，不能验证"产出物好不好"

## Residual Concerns

- 状态文件损坏或手动修改时的行为未定义
- Phase 4 反模式中"不一次性修改过大范围"的"过大"由谁定义
- Override 机制与人工确认的关系不明确
- 5 阶段瀑布流程可能增加开销导致用户放弃
- LLM 生成产物可能在 gate 通过但实质错误
- 配置 schema 和状态 schema 推迟到下一步形成串行依赖

## Deferred Questions

- 连续失败计数是 per-task 还是全局？成功后是否清零？
- TASKS.md 中多个 task 如何映射到 `run-task` 的"当前 task"？
- VibeSpec 是独立 CLI 还是 Claude Code skill？两个文档描述不一致
- 用户通过门禁后想回到早期阶段修改产物，是完整重置还是分支？
- VibeSpec 如何判断 agent 是否成功执行了 task？
- 5 阶段流程对 solo developer 是否过重？能否用 2-3 阶段流程实现大部分价值？
- 当用户橡皮图章式 approve 门禁时，系统如何检测并响应？
- 什么证据表明结构化流程确实改善了 vibecoding 结果？
