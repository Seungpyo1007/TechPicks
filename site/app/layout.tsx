import type { Metadata } from "next";
import { Noto_Sans_KR, Outfit } from "next/font/google";
import { THEME_BOOTSTRAP_SCRIPT } from "@/components/shell/theme";
import { isPreviewDeployment, siteOrigin } from "@/lib/seo";
import "./globals.css";

/** 정본이 지정한 두 서체. 제목은 Outfit, 본문은 Noto Sans KR. */
const outfit = Outfit({ subsets: ["latin"], weight: ["400", "500", "600", "700"], variable: "--font-outfit" });
const notoSansKr = Noto_Sans_KR({
  subsets: ["latin"],
  weight: ["400", "500", "700"],
  variable: "--font-noto-sans-kr",
});

export const metadata: Metadata = {
  metadataBase: siteOrigin(),
  title: { default: "TechPicks — 스펙으로 고르는 전자기기", template: "%s | TechPicks" },
  description: "스마트폰 · CPU · 노트북을 같은 스펙 기준으로 정렬한 랭킹과 비교. 데이터는 TechAPI.",
  applicationName: "TechPicks",
  robots: isPreviewDeployment() ? { index: false, follow: false } : { index: true, follow: true },
  openGraph: { type: "website", locale: "ko_KR", siteName: "TechPicks" },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ko" className={`${outfit.variable} ${notoSansKr.variable}`} suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_BOOTSTRAP_SCRIPT }} />
      </head>
      <body>{children}</body>
    </html>
  );
}
