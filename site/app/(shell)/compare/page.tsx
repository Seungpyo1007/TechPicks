import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { CompareSlots } from "@/components/compare/compare-picker";
import { ScoreRows } from "@/components/compare/score-rows";
import { Silhouette } from "@/components/compare/silhouette";
import { SpecBattle } from "@/components/compare/spec-battle";
import { getCatalogCpus, getCatalogPhones, getCatalogSocs, rankCpus, rankPhones } from "@/lib/catalog";
import { cpuSpecGroups, cpuSummaryRows, laptopSpecGroups, laptopSummaryRows } from "@/lib/compare-others";
import {
  COMPARE_KIND_LABELS,
  COMPARE_KINDS,
  compareHref,
  type CompareKind,
  parseCompareQuery,
} from "@/lib/compare-query";
import { type CompareGroup, type CompareRow, specGroups, summaryRows } from "@/lib/compare-spec";
import { getLaptops } from "@/lib/laptop";
import { canonicalUrl } from "@/lib/seo";

export const metadata: Metadata = {
  title: "제품 비교",
  description: "스마트폰 · CPU · 노트북을 최대 3종까지 같은 기준으로 나란히 놓고 비교합니다.",
  alternates: { canonical: canonicalUrl("/compare") },
};

type Props = { searchParams: Promise<Record<string, string | string[] | undefined>> };

function pick<T extends { slug: string }>(pool: T[], slugs: string[]): T[] {
  return slugs
    .map((slug) => pool.find((item) => item.slug === slug))
    .filter((item): item is T => item !== undefined);
}

const PHONE_NOTE =
  "굵게 표시된 값이 그 항목의 우세한 쪽입니다. 무게·두께·가격은 작을수록 우세로 봅니다. 성능 지수는 TechAPI 가 발행하는 0–100 정규화 값입니다.";
const CPU_NOTE = "지수는 Cinebench R23 기록에서 산출한 0–100 정규화 값입니다. TDP 는 낮을수록 우세로 봅니다.";
const LAPTOP_NOTE = "TechAPI 노트북 데이터에는 채점이 없어 구성과 가격만 견줍니다.";

export default async function ComparePage({ searchParams }: Props) {
  const query = await searchParams;

  // 종류를 먼저 읽어야 어느 목록에서 슬러그를 검증할지 정할 수 있다.
  const requestedType = Array.isArray(query.type) ? query.type[0] : query.type;
  if (requestedType !== undefined && !(COMPARE_KINDS as readonly string[]).includes(requestedType)) {
    notFound();
  }
  const kind = (requestedType ?? "phone") as CompareKind;

  const [phones, cpus, laptops, socs] = await Promise.all([
    getCatalogPhones().then(rankPhones),
    getCatalogCpus().then(rankCpus),
    getLaptops(),
    getCatalogSocs(),
  ]);

  const pool: Array<{ slug: string; name: string }> =
    kind === "cpu" ? cpus : kind === "laptop" ? laptops : phones;

  const parsed = parseCompareQuery(query, new Set(pool.map((item) => item.slug)));
  if (parsed.kind === "not-found") notFound();

  const selected = parsed.kind === "compare" ? parsed.ids : parsed.selected;
  const names = pick(pool, selected).map((item) => item.name);
  const columns = `170px repeat(${Math.max(names.length, 1)}, 1fr)`;

  const figures =
    kind === "phone"
      ? pick(phones, selected).map((phone, index) => (
          <Silhouette key={phone.slug} phone={phone} delay={`${index * 60}ms`} />
        ))
      : [];

  let scoreTitle = "점수 비교";
  let rows: CompareRow[] = [];
  let groups: CompareGroup[] = [];
  let note = PHONE_NOTE;

  if (parsed.kind === "compare") {
    if (kind === "phone") {
      const chosen = pick(phones, selected);
      const contexts = chosen.map((phone) => ({
        soc: socs.find((soc) => soc.slug === phone.soc?.slug) ?? null,
      }));
      scoreTitle = "TechPicks 점수";
      rows = summaryRows(chosen, contexts);
      groups = specGroups(chosen, contexts);
      note = PHONE_NOTE;
    } else if (kind === "cpu") {
      const chosen = pick(cpus, selected);
      scoreTitle = "벤치마크 지수";
      rows = cpuSummaryRows(chosen);
      groups = cpuSpecGroups(chosen);
      note = CPU_NOTE;
    } else {
      const chosen = pick(laptops, selected);
      scoreTitle = "구성 요약";
      rows = laptopSummaryRows(chosen);
      groups = laptopSpecGroups(chosen);
      note = LAPTOP_NOTE;
    }
  }

  return (
    <div className="compare">
      <section className="panel compare-picker">
        <div className="compare-tabs">
          <div className="compare-tab-group">
            {COMPARE_KINDS.map((value) => (
              <Link
                key={value}
                className="tag compare-tab"
                href={compareHref(value, [])}
                aria-current={value === kind}
              >
                {COMPARE_KIND_LABELS[value]}
              </Link>
            ))}
            <span className="kicker" style={{ marginLeft: 6 }}>
              {pool.length}종
            </span>
          </div>
        </div>

        <CompareSlots
          kind={kind}
          options={pool.map((item) => ({ slug: item.slug, name: item.name }))}
          selected={selected}
          figures={figures}
        />

        <p className="compare-figure-note">
          {kind === "phone"
            ? "도형은 TechAPI 의 실측 치수와 후면 렌즈 구성으로 그린 것입니다. 제품 사진이 아닙니다."
            : "제품 사진 대신 기록된 사양만으로 비교합니다."}
        </p>

        {parsed.kind === "select" && parsed.message && (
          <p className="note" style={{ textAlign: "center", margin: 0 }}>
            {parsed.message}
          </p>
        )}
      </section>

      {parsed.kind === "compare" && (
        <>
          <ScoreRows title={scoreTitle} rows={rows} names={names} columns={columns} />
          <SpecBattle groups={groups} names={names} columns={columns} note={note} />
        </>
      )}
    </div>
  );
}
