// ============================================================
// CouncilKit — 共享类型定义
// 字段严格对应 TECH.md 数据模型与 API 契约
// ============================================================

// ---- 枚举 ----

/** 底层模型类型 */
export type ModelType = "claude" | "openai" | "deepseek";

/** 房间状态 */
export type RoomStatus = "idle" | "discussing" | "paused";

/** Agent 状态 */
export type AgentStatus = "online" | "offline" | "typing";

/** 轮次状态 */
export type RoundStatus = "pending" | "active" | "completed";

/** 发送者类型 */
export type SenderType = "agent" | "user";

/** StreamChunk 事件类型 */
export type StreamChunkType = "content_block_delta" | "message_stop" | "error";

// ---- 数据实体 ----

/** 房间 */
export interface Room {
  /** 房间唯一标识，UUID */
  id: string;
  /** 讨论话题，非空，长度 ≤ 200 */
  topic: string;
  /** 创建时间戳，Unix ms */
  createdAt: number;
  /** 最近活跃时间戳，Unix ms */
  lastActiveAt: number;
  /** 关联 agent ID 列表，至少 1 个 */
  agentIds: string[];
  /** 轮次 ID 列表，初始为空数组 */
  roundIds: string[];
  /** 房间状态 */
  status: RoomStatus;
}

/** Agent */
export interface Agent {
  /** Agent 唯一标识，UUID */
  id: string;
  /** 底层模型 */
  model: ModelType;
  /** 角色/立场，非空，长度 ≤ 100 */
  role: string;
  /** 标识色，hex 色值 */
  color: string;
  /** 所属房间 ID（非模板时） */
  roomId?: string;
  /** 所属模板 ID（P1） */
  templateId?: string;
  /** Agent 状态 */
  status: AgentStatus;
}

/** 消息 */
export interface Message {
  /** 消息唯一标识，UUID */
  id: string;
  /** 发送者 ID（agentId 或 "user"） */
  senderId: string;
  /** 发送者类型 */
  senderType: SenderType;
  /** 消息内容（Markdown），非空 */
  content: string;
  /** 所属轮次 ID */
  roundId: string;
  /** 发送时间戳，Unix ms */
  timestamp: number;
}

/** 轮次 */
export interface Round {
  /** 轮次唯一标识，UUID */
  id: string;
  /** 轮次序号，从 1 自增 */
  roundNumber: number;
  /** 所属房间 ID */
  roomId: string;
  /** 本轮消息 ID 列表，按发言顺序排列 */
  messageIds: string[];
  /** 本轮总结 ID，轮次完成前为空 */
  summaryId?: string;
  /** 轮次状态 */
  status: RoundStatus;
}

/** 总结 */
export interface Summary {
  /** 总结唯一标识，UUID */
  id: string;
  /** 关联轮次 ID */
  roundId: string;
  /** 总结内容（Markdown），非空 */
  content: string;
  /** 生成时间戳，Unix ms */
  generatedAt: number;
  /** 生成总结使用的模型 */
  model: ModelType;
}

/** Agent 模板配置项（Template 内嵌） */
export interface AgentConfig {
  model: ModelType;
  role: string;
  color: string;
}

/** Agent 模板（P1） */
export interface Template {
  /** 模板唯一标识，UUID */
  id: string;
  /** 模板名称，非空 */
  name: string;
  /** agent 配置数组 */
  agentConfigs: AgentConfig[];
  /** 创建时间戳，Unix ms */
  createdAt: number;
}

// ---- API 契约类型 ----

/** 模型 API 请求体 */
export interface ModelRequest {
  /** 模型名 */
  model: string;
  /** 对话上下文 */
  messages: ModelMessage[];
  /** 流式输出 */
  stream: true;
}

/** 模型 API 消息 */
export interface ModelMessage {
  role: "user" | "assistant" | "system";
  content: string;
}

/** 流式响应 chunk */
export interface StreamChunk {
  type: StreamChunkType;
  delta?: { text: string };
  error?: { message: string; code: string };
}

// ---- 辅助类型 ----

/** Agent 预设颜色列表 */
export const AGENT_COLORS = [
  "#a78bfa", // 紫色
  "#60a5fa", // 蓝色
  "#34d399", // 绿色
  "#fbbf24", // 琥珀色
  "#f87171", // 红色
  "#fb923c", // 橙色
  "#e879f9", // 粉紫
  "#2dd4bf", // 青色
] as const;

/** 用户发送者 ID 固定值 */
export const USER_SENDER_ID = "user" as const;
