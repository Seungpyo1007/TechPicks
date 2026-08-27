"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { SearchBox, type SearchEntry } from "@/components/shell/search-box";
import { SyncButton } from "@/components/shell/sync-button";
import { screenTitle } from "@/lib/nav";

/** 정본의 스티키 헤더. 화면마다 kicker/타이틀이 바뀐다. */
export function TopBar({ entries }: { entries: SearchEntry[] }) {
  const pathname = usePathname();
  const { kicker, title } = screenTitle(pathname);

  return (
    <header className="top-bar">
      <div className="top-bar-title">
        <span className="kicker">{kicker}</span>
        <h1>{title}</h1>
      </div>

      <SearchBox entries={entries} />

      <div className="top-bar-actions">
        <Link className="btn btn-secondary" href="/compare" style={{ height: 36 }}>
          비교
        </Link>
        <SyncButton />
        <Link className="avatar" href="/profile" aria-label="프로필">
          SP
        </Link>
      </div>
    </header>
  );
}
