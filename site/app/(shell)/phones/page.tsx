import type { Metadata } from "next";
import { PhoneDetail } from "@/components/phones/phone-detail";
import { PhoneRankList } from "@/components/phones/rank-list";
import { getCatalogPhones, getCatalogSoc, rankPhones } from "@/lib/catalog";
import { toRankListItem } from "@/lib/phone";
import { canonicalUrl } from "@/lib/seo";

export const metadata: Metadata = {
  title: "스마트폰 랭킹",
  description: "TechAPI 데이터를 같은 기준으로 채점한 스마트폰 랭킹입니다. 성능·카메라·화면·배터리·가치 다섯 축으로 비교하세요.",
  alternates: { canonical: canonicalUrl("/phones") },
};

/** 정본 스마트폰 화면. 목록만 있는 상태가 없으므로 1위 제품을 함께 펼친다. */
export default async function PhonesPage() {
  const phones = rankPhones(await getCatalogPhones());
  const leader = phones[0];
  const soc = await getCatalogSoc(leader?.soc?.slug);

  return (
    <div className="master-detail">
      <PhoneRankList items={phones.map(toRankListItem)} activeSlug={leader?.slug ?? ""} />
      {leader ? (
        <PhoneDetail phone={leader} soc={soc} compareWith={null} />
      ) : (
        <div className="empty">
          <strong>카탈로그가 비어 있습니다.</strong>
        </div>
      )}
    </div>
  );
}
