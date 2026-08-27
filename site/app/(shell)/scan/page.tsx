import type { Metadata } from "next";
import { ScanPanel } from "@/components/shell/scan-panel";
import { getCatalogPhones, rankPhones } from "@/lib/catalog";
import { formatPrice } from "@/lib/format";

export const metadata: Metadata = {
  title: "OCR 스캔",
  description: "모델명으로 카탈로그에서 제품을 찾습니다.",
  // 검색 결과에 노출할 페이지가 아니다. 공개 가치가 있는 건 제품 상세 쪽이다.
  robots: { index: false, follow: true },
};

export default async function ScanPage() {
  const phones = rankPhones(await getCatalogPhones());
  const candidates = phones.map((phone) => ({
    slug: phone.slug,
    name: phone.name,
    meta: [phone.brand.name, phone.soc?.name, formatPrice(phone.msrp_usd)].filter(Boolean).join(" · "),
  }));

  return <ScanPanel candidates={candidates} />;
}
