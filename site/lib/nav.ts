import type { IconName } from "@/components/ui/icon";

/** 정본 `navDefs` / `titles` / `tiles` / `bottomNav` 를 한 곳에 모은 것. */
export type NavItem = { href: string; label: string; icon: IconName };

export const NAV_ITEMS: NavItem[] = [
  { href: "/", label: "홈", icon: "home" },
  { href: "/phones", label: "휴대폰", icon: "phone" },
  { href: "/cpus", label: "CPU", icon: "cpu" },
  { href: "/laptops", label: "노트북", icon: "laptop" },
  { href: "/build", label: "조립", icon: "build" },
  { href: "/compare", label: "비교", icon: "compare" },
  { href: "/scan", label: "OCR 스캔", icon: "scan" },
  { href: "/viewer", label: "3D 뷰어", icon: "box" },
  { href: "/profile", label: "프로필", icon: "user" },
];

export const BOTTOM_NAV_ITEMS: NavItem[] = [
  { href: "/", label: "홈", icon: "home" },
  { href: "/phones", label: "휴대폰", icon: "phone" },
  { href: "/cpus", label: "CPU", icon: "cpu" },
  { href: "/laptops", label: "노트북", icon: "laptop" },
  { href: "/profile", label: "프로필", icon: "user" },
];

export type ScreenTitle = { kicker: string; title: string };

const TITLES: Record<string, ScreenTitle> = {
  "/": { kicker: "대시보드", title: "함께하는 기술" },
  "/phones": { kicker: "랭킹", title: "스마트폰" },
  "/cpus": { kicker: "랭킹", title: "CPU" },
  "/laptops": { kicker: "랭킹", title: "노트북" },
  "/build": { kicker: "도구", title: "조립 견적" },
  "/compare": { kicker: "도구", title: "제품 비교" },
  "/scan": { kicker: "도구", title: "OCR 스캔" },
  "/viewer": { kicker: "도구", title: "3D 뷰어" },
  "/profile": { kicker: "계정", title: "프로필" },
};

export function screenTitle(pathname: string): ScreenTitle {
  if (pathname !== "/" && pathname.startsWith("/phones")) return TITLES["/phones"];
  if (pathname.startsWith("/cpus")) return TITLES["/cpus"];
  return TITLES[pathname] ?? TITLES["/"];
}

/** 사이드바·하단탭의 활성 표시. 상세 경로는 목록 항목을 활성으로 본다. */
export function isActive(pathname: string, href: string): boolean {
  return href === "/" ? pathname === "/" : pathname === href || pathname.startsWith(`${href}/`);
}

export type Tile = { href: string; label: string; sub: string; icon: IconName };

export function homeTiles(counts: { phones: number; cpus: number; laptops: number }): Tile[] {
  return [
    { href: "/cpus", label: "CPU", sub: `${counts.cpus}종 벤치마크`, icon: "cpu" },
    { href: "/phones", label: "휴대폰", sub: `${counts.phones}종 랭킹`, icon: "phone" },
    { href: "/laptops", label: "노트북", sub: `${counts.laptops}종 구성`, icon: "laptop" },
    { href: "/compare", label: "비교", sub: "최대 3종", icon: "compare" },
    { href: "/scan", label: "OCR 스캔", sub: "모델명 인식", icon: "scan" },
    { href: "/viewer", label: "3D 뷰어", sub: "지원 예정", icon: "box" },
    { href: "/profile", label: "프로필", sub: "계정 · 설정", icon: "user" },
    { href: "/build", label: "조립", sub: "부품 추천", icon: "build" },
  ];
}
