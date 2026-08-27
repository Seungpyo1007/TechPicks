"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Icon } from "@/components/ui/icon";
import { isActive, NAV_ITEMS } from "@/lib/nav";

/** 정본의 216px 사이드바. 데스크톱 폭에서만 보이고, 좁아지면 하단 탭이 대신한다. */
export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="sidebar">
      <Link className="sidebar-brand" href="/">
        <span className="brand-mark">
          <Image src="/brand/NBlogo.png" alt="" width={21} height={21} priority />
        </span>
        <span className="brand-name">TechPicks</span>
      </Link>

      <nav className="sidebar-nav" aria-label="주요 메뉴">
        {NAV_ITEMS.map((item) => (
          <Link
            key={item.href}
            className="nav-item"
            href={item.href}
            aria-current={isActive(pathname, item.href) ? "page" : undefined}
          >
            <Icon name={item.icon} />
            <span>{item.label}</span>
          </Link>
        ))}
      </nav>

      <p className="sidebar-credit">
        스펙 데이터 ·{" "}
        <a href="https://github.com/GetTechAPI/TechAPI" target="_blank" rel="noreferrer">
          TechAPI
        </a>
        <br />
        CC-BY-SA 4.0
      </p>
    </aside>
  );
}
