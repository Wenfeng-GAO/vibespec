# CouncilKit - 实现任务列表

## 任务概览

- 总任务数: 17
- P0 任务: 13
- P1 任务: 4
- P2 任务: 0

---

## T1: 项目脚手架初始化

- 前置依赖: 无
- 允许修改范围:
  - 项目根目录（新建 package.json、tsconfig.json、vite.config.ts、tailwind.config.ts、postcss.config.js、biome.json、index.html、lefthook.yml 等配置簇）
  - `src/styles/globals.css`（新建）
  - `src/main.tsx`（新建，应用入口）
  - `src/vite-env.d.ts`（新建）
- 预期产出:
  - `package.json`: 项目依赖与脚本（react 18.x, react-dom, react-router-dom 6.x, @tanstack/react-query 5.x, zustand 4.x, dexie 4.x, react-markdown 9.x, crypto-js 4.x 及所有 devDeps）
  - `tsconfig.json`: TypeScript strict 模式配置
  - `vite.config.ts`: Vite 5.x + React 插件配置
  - `tailwind.config.ts`: Tailwind 3.x 配置（深色主题、CSS 变量、内容路径）
  - `postcss.config.js`: PostCSS + Tailwind 插件
  - `biome.json`: Biome 格式化与 lint 配置
  - `index.html`: SPA 入口 HTML
  - `src/styles/globals.css`: Tailwind 指令 + CSS 变量（配色方案，按 DESIGN 视觉方向定义变量值）
  - `src/main.tsx`: React 根渲染入口
  - `src/vite-env.d.ts`: Vite 类型声明
  - `lefthook.yml`: Git hooks 配置
- 预期文件数 ≥ 10，理由: 项目脚手架是配置簇，天然文件数偏多，每个配置文件独立且必要
- 验证方式:
  - [ ] `pnpm install` 无错误
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
  - [ ] `pnpm dev` 启动成功（localhost:5173 可访问）
  - [ ] `pnpm build` 构建成功
- 对应需求: 基础设施

---

## T2: 共享类型定义

- 前置依赖: T1
- 允许修改范围:
  - `src/types/index.ts`（新建）
- 预期产出:
  - `src/types/index.ts`: 所有共享类型定义——Room、Agent、Message、Round、Summary、Template 实体类型，ModelType 枚举，RoomStatus / AgentStatus / RoundStatus / SenderType 枚举，ModelRequest / ModelMessage / StreamChunk API 契约类型。字段与 TECH.md 数据模型严格一致
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
- 对应需求: 基础设施

---

## T3: 数据模型与数据库初始化

- 前置依赖: T2
- 允许修改范围:
  - `src/models/room.ts`（新建）
  - `src/models/agent.ts`（新建）
  - `src/models/message.ts`（新建）
  - `src/models/round.ts`（新建）
  - `src/models/summary.ts`（新建）
  - `src/models/template.ts`（新建）
  - `src/lib/db.ts`（新建）
- 预期产出:
  - `src/models/room.ts`: Room 实体定义 + createRoom 工厂函数 + validateRoom 校验函数（topic 非空≤200, agentIds≥1）
  - `src/models/agent.ts`: Agent 实体定义 + createAgent 工厂函数（含自动分配 color 逻辑）
  - `src/models/message.ts`: Message 实体定义 + createMessage 工厂函数
  - `src/models/round.ts`: Round 实体定义 + createRound 工厂函数
  - `src/models/summary.ts`: Summary 实体定义 + createSummary 工厂函数
  - `src/models/template.ts`: Template 实体定义 + createTemplate 工厂函数
  - `src/lib/db.ts`: Dexie 数据库初始化，定义 rooms / agents / messages / rounds / summaries / templates 六张表，主键与索引与 TECH.md 一致
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
- 对应需求: R1, R5, R12

---

## T4: 模型 API 调用封装

- 前置依赖: T2
- 允许修改范围:
  - `src/services/claude.ts`（新建）
  - `src/services/openai.ts`（新建）
  - `src/services/deepseek.ts`（新建）
  - `src/services/model-registry.ts`（新建）
  - `src/lib/api.ts`（新建）
  - `src/lib/stream.ts`（新建）
- 预期产出:
  - `src/services/claude.ts`: Claude API 流式调用封装（x-api-key header, messages 格式, SSE 解析, 10s AbortController 超时）
  - `src/services/openai.ts`: OpenAI API 流式调用封装（Bearer token, messages 格式, SSE 解析, 10s 超时）
  - `src/services/deepseek.ts`: DeepSeek API 流式调用封装（Bearer token, messages 格式, SSE 解析, 10s 超时）
  - `src/services/model-registry.ts`: 模型注册与路由，根据 ModelType 分发到对应 service
  - `src/lib/api.ts`: 统一 API 调用入口，封装认证、错误处理（401/429/500/timeout）与重试逻辑
  - `src/lib/stream.ts`: 流式输出处理，将 SSE StreamChunk 转为可消费的 AsyncIterable/ReadableStream
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
- 对应需求: R4, R7

---

## T5: 工具函数层

- 前置依赖: T2
- 允许修改范围:
  - `src/lib/crypto.ts`（新建）
  - `src/lib/context.ts`（新建）
  - `src/lib/summary.ts`（新建）
- 预期产出:
  - `src/lib/crypto.ts`: API Key 本地 AES-256 加解密（encryptKey / decryptKey），使用 crypto-js
  - `src/lib/context.ts`: 上下文压缩——滑动窗口 N=5 轮 + 摘要注入（compressContext 函数）
  - `src/lib/summary.ts`: 独立总结生成——调用模型 API 生成轮次总结（generateSummary 函数）
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
- 对应需求: R5, R7

---

## T6: 状态管理（Zustand Stores）

- 前置依赖: T2, T3
- 允许修改范围:
  - `src/stores/ui.ts`（新建）
  - `src/stores/discussion.ts`（新建）
- 预期产出:
  - `src/stores/ui.ts`: UI 状态——sidebarOpen, currentRoomId, viewMode(timeline/column),setCurrentRoomId, toggleSidebar, setViewMode
  - `src/stores/discussion.ts`: 讨论流状态——rounds, messages, activeRoundId, typingAgentIds, addMessage, startRound, completeRound, setTypingAgent, resetDiscussion
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
- 对应需求: R4, R6

---

## T7: React Query 配置与数据操作 Hooks

- 前置依赖: T3, T6
- 允许修改范围:
  - `src/stores/queries.ts`（新建）
- 预期产出:
  - `src/stores/queries.ts`: React Query hooks——useRooms(房间列表), useRoom(id), useCreateRoom, useCreateMessage, useCreateRound, useMessages(roundId), useSummary(roundId)。所有 hooks 与 Dexie 数据库交互，处理缓存与乐观更新
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
- 对应需求: R1, R4, R5, R6, R12

---

## T8: 基础 UI 组件

- 前置依赖: T1, T6
- 允许修改范围:
  - `src/components/ui/Button.tsx`（新建）
  - `src/components/ui/TextInput.tsx`（新建）
  - `src/components/ui/Textarea.tsx`（新建）
  - `src/components/ui/Select.tsx`（新建）
  - `src/components/ui/Modal.tsx`（新建）
  - `src/components/ui/Skeleton.tsx`（新建）
- 预期产出:
  - `Button.tsx`: 主操作按钮，支持 variant(primary/secondary/ghost)、size、loading 状态、disabled
  - `TextInput.tsx`: 单行输入框，支持 label、placeholder、validation error、value/onChange
  - `Textarea.tsx`: 多行输入框，支持自动高度、placeholder、validation
  - `Select.tsx`: 下拉选择框（用于 ModelSelect 等），支持 options、selectedValue、onChange
  - `Modal.tsx`: 模态对话框，支持标题、内容、关闭回调
  - `Skeleton.tsx`: 加载骨架占位，支持 variant(text/avatar/block)
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
- 对应需求: 基础设施

---

## T9: 布局与导航组件

- 前置依赖: T1, T6, T7, T8
- 允许修改范围:
  - `src/components/layout/AppShell.tsx`（新建）
  - `src/components/layout/Sidebar.tsx`（新建）
  - `src/components/shared/EmptyState.tsx`（新建）
  - `src/components/shared/ErrorBanner.tsx`（新建）
- 预期产出:
  - `AppShell.tsx`: 两栏布局外壳（侧边栏 + 主内容区 + React Router Outlet），深色主题
  - `Sidebar.tsx`: 侧边栏——新建房间按钮、useRooms 房间列表（RoomListItem 待 T10）、Agent 模板入口(P1 标注)、收起/展开
  - `EmptyState.tsx`: 通用空状态组件（图标 + 说明文字 + 操作按钮），支持 variant(no-room/no-template/no-discussion)
  - `ErrorBanner.tsx`: 错误提示条（错误信息 + 重试按钮），可关闭
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
  - [ ] `pnpm dev` 侧边栏与主内容区渲染正常
- 对应需求: R1

---

## T10: 房间相关组件

- 前置依赖: T6, T7, T8, T9
- 允许修改范围:
  - `src/components/room/RoomListItem.tsx`（新建）
  - `src/components/room/RoomHeader.tsx`（新建）
  - `src/components/room/ViewToggle.tsx`（新建）
- 预期产出:
  - `RoomListItem.tsx`: 房间列表项——显示话题、最近活跃时间、活跃状态指示灯，点击导航到 /rooms/:roomId
  - `RoomHeader.tsx`: 房间讨论页头部——显示话题、ViewToggle、agent 管理入口(P1 标注)
  - `ViewToggle.tsx`: 时间线/分栏切换按钮组，读取/写入 Zustand ui.viewMode
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
- 对应需求: R4, R6, R10

---

## T11: Agent 与消息组件

- 前置依赖: T6, T8
- 允许修改范围:
  - `src/components/agent/AgentConfigCard.tsx`（新建）
  - `src/components/agent/AgentConfigList.tsx`（新建）
  - `src/components/agent/TypingIndicator.tsx`（新建）
  - `src/components/message/MessageBubble.tsx`（新建）
- 预期产出:
  - `AgentConfigCard.tsx`: Agent 配置卡片——模型选择(Select)、角色输入(TextInput)、颜色标识、删除按钮；支持可编辑/只读变体
  - `AgentConfigList.tsx`: Agent 配置列表——包含 AgentConfigCard 列表 + 添加按钮，管理 agent 列表增删
  - `TypingIndicator.tsx`: 打字指示器——动画点 + "X 正在思考…"文案
  - `MessageBubble.tsx`: 发言气泡——区分 agent/用户发言（颜色标识、头像首字母、名称标签），内容支持 Markdown 渲染（react-markdown），离线标注变体
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
- 对应需求: R2, R3, R4, R8

---

## T12: 讨论流组件

- 前置依赖: T6, T10, T11
- 允许修改范围:
  - `src/components/room/DiscussionStream.tsx`（新建）
  - `src/components/room/TimelineView.tsx`（新建）
  - `src/components/room/RoundDivider.tsx`（新建）
  - `src/components/room/SummaryBlock.tsx`（新建）
  - `src/components/room/UserInputBar.tsx`（新建）
- 预期产出:
  - `DiscussionStream.tsx`: 讨论流容器——根据 viewMode 条件渲染 TimelineView / ColumnCompareView(T12 仅实现 TimelineView)，加载/空/错误状态
  - `TimelineView.tsx`: 时间线视图——按时间线展示 RoundDivider → MessageBubble → SummaryBlock，流式输出时最新气泡逐字更新
  - `RoundDivider.tsx`: 轮次分隔线——"第 N 轮" + 进度指示
  - `SummaryBlock.tsx`: 总结折叠块——展开/折叠切换，Markdown 渲染总结内容
  - `UserInputBar.tsx`: 用户输入框——Textarea + 发送按钮，输入追问/观点触发新一轮
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
- 对应需求: R4, R5, R6, R8

---

## T13: 页面与路由集成

- 前置依赖: T9, T10, T11, T12
- 允许修改范围:
  - `src/app/layout.tsx`（新建）
  - `src/app/page.tsx`（新建）
  - `src/app/rooms/new/page.tsx`（新建）
  - `src/app/rooms/[roomId]/page.tsx`（新建）
- 预期产出:
  - `layout.tsx`: AppShell 根布局，包裹 React Router Outlet
  - `page.tsx`: 主页 / ——有房间时重定向到最近活跃房间，无房间时展示 EmptyState
  - `rooms/new/page.tsx`: 新建房间页——TopicInput + AgentConfigList + RoundCountSelect(默认2轮) + 发起讨论按钮，表单验证（话题非空+至少1个agent）
  - `rooms/[roomId]/page.tsx`: 房间讨论页——RoomHeader + DiscussionStream + UserInputBar，加载房间数据与讨论历史，发起/继续讨论逻辑
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
  - [ ] `pnpm dev` 四条路由均可导航访问
  - [ ] `pnpm build` 构建成功
- 对应需求: R1, R2, R3, R4, R5, R6, R7, R8

---

## T14: API Key 管理界面 [P1]

- 前置依赖: T5, T8, T9
- 允许修改范围:
  - `src/components/settings/ApiKeyManager.tsx`（新建）
- 预期产出:
  - `ApiKeyManager.tsx`: API Key 管理面板——为三个模型分别输入/更新 API Key，AES 加密存储到 localStorage，输入时密码遮罩，验证 key 有效性（可选）
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
- 对应需求: 基础设施（P1，支撑模型 API 调用）

---

## T15: Agent 模板管理页面 [P1]

- 前置依赖: T3, T8, T9, T11
- 允许修改范围:
  - `src/app/templates/page.tsx`（新建）
  - `src/components/template/TemplateCard.tsx`（新建）
  - `src/components/template/TemplatePicker.tsx`（新建）
  - `src/components/agent/AgentManagePanel.tsx`（新建）
- 预期产出:
  - `templates/page.tsx`: 模板管理页——模板列表 + 新建模板
  - `TemplateCard.tsx`: 模板卡片——显示模板名 + agent 配置组合，支持删除
  - `TemplatePicker.tsx`: 模板引用器——在选择 agent 配置时可选择已有模板填充
  - `AgentManagePanel.tsx`: Agent 管理面板——讨论中途加入/移除 agent
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
- 对应需求: R9, R11

---

## T16: 分栏对比视图 [P1]

- 前置依赖: T11, T12
- 允许修改范围:
  - `src/components/room/ColumnCompareView.tsx`（新建）
- 预期产出:
  - `ColumnCompareView.tsx`: 分栏对比视图——每个 agent 一列并排展示，按 round 分组，支持独立回答模式对比
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
- 对应需求: R10

---

## T17: 质量收尾（响应式 + 可访问性 + 导出） [P1]

- 前置依赖: T13
- 允许修改范围:
  - `src/styles/globals.css`（修改：增加响应式断点样式）
  - `src/components/layout/AppShell.tsx`（修改：增加响应式布局 + 抽屉模式）
  - `src/components/layout/Sidebar.tsx`（修改：增加移动端抽屉模式）
  - 其他组件（修改：增加 a11y 属性——aria-live、aria-label、键盘导航 focus 管理）
- 预期产出:
  - 响应式: 桌面(≥1024)侧边栏常驻、平板(640-1023)侧边栏抽屉化、移动端(<640)顶部抽屉
  - 可访问性: aria-live 提示流式输出与 typing 状态、键盘 Tab 导航、WCAG AA 对比度验证
- 验证方式:
  - [ ] `pnpm typecheck` 通过
  - [ ] `pnpm lint` 通过
  - [ ] `pnpm build` 构建成功
- 对应需求: A11y-1~4, 响应式断点

---