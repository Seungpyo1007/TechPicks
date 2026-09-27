import Image from "next/image";
import Link from "next/link";

/** 약관·개인정보 처리방침의 틀. 셸 밖, 글 읽기에 맞춘 한 단. */
export function LegalPage({ children }: { children: React.ReactNode }) {
  return (
    <main className="legal">
      <Link className="sidebar-brand" href="/">
        <span className="brand-mark">
          <Image src="/brand/NBlogo.png" alt="" width={21} height={21} />
        </span>
        <span className="brand-name">TechPicks</span>
      </Link>
      {children}
      <p className="note legal-foot">
        <Link href="/terms">이용약관</Link> · <Link href="/privacy">개인정보 처리방침</Link>
      </p>
    </main>
  );
}

/** 문의 메일. 정해지면 여기 한 곳만 바꾼다. */
export const CONTACT_EMAIL = "CONTACT_EMAIL";
export const EFFECTIVE_KO = "2026년 9월 27일";
export const EFFECTIVE_EN = "September 27, 2026";
