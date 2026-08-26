import Image from "next/image";
import Link from "next/link";

export function SiteHeader() {
  return (
    <header className="site-header">
      <div className="shell header-inner">
        <Link className="brand" href="/phones" aria-label="TechPicks 스마트폰 랭킹">
          <span className="brand-mark">
            <Image src="/brand/NBlogo_black.png" alt="" width={34} height={34} priority />
          </span>
          <span>TechPicks</span>
        </Link>
        <nav aria-label="주요 메뉴">
          <Link href="/phones">스마트폰</Link>
          <Link href="/compare">비교</Link>
        </nav>
      </div>
    </header>
  );
}
