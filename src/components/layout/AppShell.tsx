import { Outlet } from "react-router-dom";

/**
 * 应用外壳：侧边栏 + 主内容区两栏布局。
 * 完整实现由 T9 完成，当前为最小桩。
 */
export default function AppShell() {
  return (
    <div className="flex h-screen bg-background text-foreground">
      {/* Sidebar 占位 — T9 实现 */}
      <aside className="hidden w-sidebar shrink-0 border-r border-background-surface bg-background-panel lg:block" />

      {/* 主内容区 */}
      <main className="flex-1 overflow-y-auto">
        <Outlet />
      </main>
    </div>
  );
}
