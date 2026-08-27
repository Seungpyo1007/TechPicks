import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { PhoneDetail } from "@/components/phones/phone-detail";
import { PhoneRankList } from "@/components/phones/rank-list";
import { getCatalogPhones, getCatalogSoc, rankPhones } from "@/lib/catalog";
import { toRankListItem } from "@/lib/phone";
import { phoneMetadata, productJsonLd } from "@/lib/seo";
import { getPhone } from "@/lib/techapi";

type Params = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  const phones = await getCatalogPhones();
  return phones.map((phone) => ({ slug: phone.slug }));
}

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { slug } = await params;
  const phone = await getPhone(slug);
  if (!phone) return { title: "찾을 수 없는 제품" };
  return phoneMetadata(phone);
}

/**
 * 정본과 같은 마스터-디테일이되, 선택된 제품이 URL 을 갖는다.
 * 이름·점수·스펙이 하이드레이션 전에 HTML 에 들어 있어야 검색에 잡힌다.
 */
export default async function PhonePage({ params }: Params) {
  const { slug } = await params;
  const phone = await getPhone(slug);
  if (!phone) notFound();

  const [phones, soc] = await Promise.all([getCatalogPhones(), getCatalogSoc(phone.soc?.slug)]);
  const ranked = rankPhones(phones);

  return (
    <div className="master-detail">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(productJsonLd(phone)) }}
      />
      <PhoneRankList items={ranked.map(toRankListItem)} activeSlug={phone.slug} />
      <PhoneDetail phone={phone} soc={soc} compareWith={null} />
    </div>
  );
}
