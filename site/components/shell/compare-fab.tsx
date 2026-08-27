"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Icon } from "@/components/ui/icon";

/** 정본의 `showFab` 규칙: 비교 화면과 프로필 화면에서는 감춘다. */
const HIDDEN_ON = ["/compare", "/profile"];

export function CompareFab() {
  const pathname = usePathname();
  if (HIDDEN_ON.some((path) => pathname === path || pathname.startsWith(`${path}/`))) return null;

  return (
    <Link className="compare-fab elev-lg" href="/compare">
      <Icon name="compare" size={20} />
      <span>비교하기</span>
    </Link>
  );
}
