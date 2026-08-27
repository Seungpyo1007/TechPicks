"use client";

import Link from "next/link";
import { Switch, useNotifications, useTheme } from "@/components/shell/theme";

/** 정본 프로필 화면의 설정 행. 값은 이 브라우저에만 남는다(계정 저장은 아직 없다). */
export function ProfileSettings() {
  const [theme, setTheme] = useTheme();
  const [notifications, setNotifications] = useNotifications();

  return (
    <div className="panel" style={{ padding: 16, display: "flex", flexDirection: "column" }}>
      <div className="setting-row">
        <span>다크 모드</span>
        <Switch
          checked={theme === "dark"}
          onChange={(next) => setTheme(next ? "dark" : "light")}
          label="다크 모드"
        />
      </div>
      <div className="setting-row">
        <span>알림</span>
        <Switch checked={notifications} onChange={setNotifications} label="알림" />
      </div>
      <div className="setting-row">
        <span>언어</span>
        <span className="tag tag-neutral">한국어</span>
      </div>
      <div className="setting-row">
        <span>데이터 출처</span>
        <a
          href="https://github.com/GetTechAPI/TechAPI"
          target="_blank"
          rel="noreferrer"
          style={{ fontSize: 13 }}
        >
          TechAPI · CC-BY-SA 4.0
        </a>
      </div>
      <Link
        className="btn btn-secondary btn-block"
        href="/login"
        style={{ height: 42, margin: "12px 0 16px" }}
      >
        로그아웃
      </Link>
    </div>
  );
}
