import type { Metadata } from "next";
import { SiteHeader } from "@/components/site-header";
import { isPreviewDeployment, siteOrigin } from "@/lib/seo";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: siteOrigin(),
  title: { default: "TechPicks — 스마트폰을 더 분명하게", template: "%s | TechPicks" },
  description: "같은 기준으로 스마트폰의 점수와 핵심 사양을 비교하세요.",
  applicationName: "TechPicks",
  robots: isPreviewDeployment() ? { index: false, follow: false } : { index: true, follow: true },
  openGraph: {
    type: "website",
    locale: "ko_KR",
    siteName: "TechPicks",
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ko">
      <body>
        <SiteHeader />
        <main>{children}</main>
        <footer className="site-footer">
          <div className="shell footer-inner">
            <span>TechPicks</span>
            <span>
              Data from{" "}
              <a href="https://github.com/GetTechAPI/TechAPI" rel="noreferrer">
                TechAPI
              </a>{" "}
              · CC-BY-SA 4.0
            </span>
          </div>
        </footer>
      </body>
    </html>
  );
}
