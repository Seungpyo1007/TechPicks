import { BottomNav } from "@/components/shell/bottom-nav";
import { CompareFab } from "@/components/shell/compare-fab";
import { Sidebar } from "@/components/shell/sidebar";
import { TopBar } from "@/components/shell/top-bar";
import { buildSearchIndex } from "@/lib/search-index";

/** 정본의 앱 셸. 데스크톱은 사이드바, 모바일은 하단 탭 — 분기는 CSS 가 한다. */
export default async function ShellLayout({ children }: { children: React.ReactNode }) {
  const searchEntries = await buildSearchIndex();

  return (
    <div className="shell">
      <Sidebar />
      <main className="shell-main">
        <TopBar entries={searchEntries} />
        <div className="screen">{children}</div>
      </main>
      <CompareFab />
      <BottomNav />
    </div>
  );
}
