import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { ComparePicker } from "@/components/compare-picker";
import { ComparisonTable } from "@/components/comparison-table";
import { getCatalogPhones, rankPhones } from "@/lib/catalog";
import { compareHref, parseCompareQuery } from "@/lib/compare-query";
import { toPhoneOption } from "@/lib/phone";
import { canonicalUrl } from "@/lib/seo";
import { getPhone } from "@/lib/techapi";

type ComparePageProps = {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

export async function generateMetadata({ searchParams }: ComparePageProps): Promise<Metadata> {
  const phones = await getCatalogPhones();
  const query = parseCompareQuery(await searchParams, new Set(phones.map((phone) => phone.slug)));
  if (query.kind !== "compare") {
    return {
      title: "스마트폰 비교",
      description: "스마트폰 두 대를 골라 핵심 점수와 사양을 나란히 비교하세요.",
      alternates: { canonical: canonicalUrl("/compare") },
    };
  }
  const selected = query.ids.map((slug) => phones.find((phone) => phone.slug === slug)!);
  const title = `${selected[0].name} vs ${selected[1].name}`;
  return {
    title,
    description: `${selected[0].name}와 ${selected[1].name}의 점수와 핵심 사양 비교.`,
    alternates: { canonical: canonicalUrl(compareHref(...query.ids)) },
  };
}

export default async function ComparePage({ searchParams }: ComparePageProps) {
  const catalogPhones = rankPhones(await getCatalogPhones());
  const phoneOptions = catalogPhones.map(toPhoneOption);
  const query = parseCompareQuery(await searchParams, new Set(catalogPhones.map((phone) => phone.slug)));
  if (query.kind === "not-found") notFound();

  if (query.kind === "select") {
    return (
      <div className="shell page-stack compare-page">
        <section className="hero compare-hero">
          <p className="eyebrow">SIDE BY SIDE</p>
          <h1>두 대를 고르면<br />차이가 또렷해집니다.</h1>
          <p className="hero-copy">로그인 없이 비교하고, 완성된 주소를 그대로 공유할 수 있습니다.</p>
        </section>
        <ComparePicker phones={phoneOptions} initial={query.selected} message={query.message} />
      </div>
    );
  }

  const loaded = await Promise.all(query.ids.map((slug) => getPhone(slug)));
  if (!loaded[0] || !loaded[1]) notFound();
  const selected: [NonNullable<typeof loaded[0]>, NonNullable<typeof loaded[1]>] = [loaded[0], loaded[1]];

  return (
    <div className="shell page-stack compare-page">
      <section className="compare-title">
        <p className="eyebrow">SIDE BY SIDE</p>
        <h1>{selected[0].name}<span>vs</span>{selected[1].name}</h1>
        <p>이 주소를 다시 열면 같은 두 제품의 비교가 재현됩니다.</p>
      </section>
      <ComparisonTable phones={selected} />
      <section className="change-comparison">
        <h2>비교 제품 바꾸기</h2>
        <ComparePicker phones={phoneOptions} initial={query.ids} />
      </section>
    </div>
  );
}
