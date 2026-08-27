"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Icon } from "@/components/ui/icon";
import { BOTTOM_NAV_ITEMS, isActive } from "@/lib/nav";

/** 정본의 모바일 하단 5탭. 좁은 폭에서만 보인다(CSS 미디어쿼리). */
export function BottomNav() {
  const pathname = usePathname();

  return (
    <nav className="bottom-nav" aria-label="모바일 메뉴">
      {BOTTOM_NAV_ITEMS.map((item) => (
        <Link
          key={item.href}
          href={item.href}
          aria-current={isActive(pathname, item.href) ? "page" : undefined}
        >
          <span className="bottom-nav-pill">
            <Icon name={item.icon} size={20} />
          </span>
          <span>{item.label}</span>
        </Link>
      ))}
    </nav>
  );
}
