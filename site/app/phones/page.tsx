import type { Metadata } from "next";
import Link from "next/link";
import { PhoneExplorer } from "@/components/phone-explorer";
import { getCatalogPhones, rankPhones } from "@/lib/catalog";
import { toPhoneListItem } from "@/lib/phone";
import { canonicalUrl } from "@/lib/seo";

export const metadata: Metadata = {
  title: "스마트폰 랭킹",
  description: "TechAPI 데이터를 같은 기준으로 계산한 스마트폰 랭킹과 검색 목록입니다.",
  alternates: { canonical: canonicalUrl("/phones") },
};

export default async function PhonesPage() {
  const phones = rankPhones(await getCatalogPhones());
  const listItems = phones.map(toPhoneListItem);

  return (
    <div className="shell page-stack">
      <section className="hero ranking-hero">
        <div>
          <p className="eyebrow">스마트폰 랭킹 · SMARTPHONE INDEX</p>
          <h1>숫자는 간결하게,<br />선택은 분명하게.</h1>
          <p className="hero-copy">
            {phones.length}대의 성능, 카메라, 배터리, 디스플레이와 가격을 같은 기준으로 정렬했습니다.
          </p>
        </div>
        <Link className="hero-action" href="/compare">
          <span>두 제품을 나란히</span>
          <strong>스마트폰 비교하기 →</strong>
        </Link>
      </section>
      <PhoneExplorer phones={listItems} />
    </div>
  );
}
