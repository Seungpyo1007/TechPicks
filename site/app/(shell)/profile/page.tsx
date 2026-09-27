import type { Metadata } from "next";
import { AccountPanel } from "@/components/profile/account-panel";
import { ProfileSettings } from "@/components/profile/profile-settings";

export const metadata: Metadata = {
  title: "프로필",
  description: "계정과 표시 설정.",
  robots: { index: false, follow: false },
};

export default function ProfilePage() {
  return (
    <div className="tool-grid">
      <AccountPanel />
      <ProfileSettings />
    </div>
  );
}
