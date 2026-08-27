import type { Metadata } from "next";
import { ProfileSettings } from "@/components/profile/profile-settings";

export const metadata: Metadata = {
  title: "프로필",
  description: "계정과 표시 설정.",
  robots: { index: false, follow: false },
};

export default function ProfilePage() {
  return (
    <div className="tool-grid">
      <section className="panel panel-pad">
        <div className="profile-id">
          <span className="profile-avatar">SP</span>
          <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
            <span style={{ fontFamily: "var(--font-heading)", fontSize: 22, lineHeight: 1 }}>Seungpyo</span>
            <span className="note">seungpyo@techpicks.app</span>
          </div>
        </div>
        <div className="detail-tags">
          <span className="tag tag-accent">스마트폰</span>
          <span className="tag tag-accent">CPU</span>
          <span className="tag tag-neutral">관심 제품군 편집</span>
        </div>
        <p className="note" style={{ margin: 0 }}>
          계정 연동은 아직 붙지 않았습니다. 아래 설정은 이 브라우저에만 저장됩니다.
        </p>
        <div style={{ display: "flex", gap: 8, marginTop: 4 }}>
          <button className="btn btn-secondary" type="button" style={{ height: 38 }} disabled>
            프로필 편집
          </button>
          <button className="btn btn-secondary" type="button" style={{ height: 38 }} disabled>
            비밀번호 변경
          </button>
        </div>
      </section>

      <ProfileSettings />
    </div>
  );
}
