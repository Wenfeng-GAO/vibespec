import AppShell from "@/components/layout/AppShell";
import { Navigate, Route, Routes } from "react-router-dom";

export default function App() {
  return (
    <Routes>
      <Route element={<AppShell />}>
        <Route index element={<HomePage />} />
        <Route path="rooms/new" element={<div>新建房间（待实现）</div>} />
        <Route path="rooms/:roomId" element={<div>房间讨论（待实现）</div>} />
        <Route path="templates" element={<div>模板管理（P1）</div>} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}

function HomePage() {
  return <div>主页（待实现）</div>;
}
