import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { BuildControls } from "@/components/build/build-controls";
import { ComboCard } from "@/components/build/combo-card";
import {
  bottleneckMessage,
  buildCombo,
  findUseCase,
  PSU_ASSUMPTION,
  recommend,
  requirements,
  USE_CASES,
} from "@/lib/build";
import { buildHref, parseBuildQuery } from "@/lib/build-query";
import { cpuClockLabel, cpuCoreLabel } from "@/lib/cpu";
import { getDesktopParts, gpuMemoryLabel } from "@/lib/desktop-part";
import { formatPrice } from "@/lib/format";
import { canonicalUrl } from "@/lib/seo";

export const metadata: Metadata = {
  title: "조립 견적",
  description:
    "예산과 용도를 고르면 TechAPI 채점값으로 CPU와 그래픽카드 조합을 추천하고, 필요한 소켓·메모리 규격·파워 용량을 계산합니다.",
  alternates: { canonical: canonicalUrl("/build") },
};

type Props = { searchParams: Promise<Record<string, string | string[] | undefined>> };

export default async function BuildPage({ searchParams }: Props) {
  const query = await searchParams;
  const { cpus, gpus, generated } = await getDesktopParts();

  const parsed = parseBuildQuery(
    query,
    new Set(cpus.map((cpu) => cpu.slug)),
    new Set(gpus.map((gpu) => gpu.slug)),
  );
  if (parsed.kind === "not-found") notFound();

  const useCase = findUseCase(parsed.use);
  const picks = recommend(cpus, gpus, useCase, parsed.budgetUsd);

  // 직접 고른 부품이 있으면 그쪽이 우선이고, 빈 자리는 1순위 추천으로 채운다.
  const leader = picks[0];
  const selectedCpu =
    cpus.find((cpu) => cpu.slug === parsed.cpu) ?? leader?.cpu ?? null;
  const selectedGpu =
    gpus.find((gpu) => gpu.slug === parsed.gpu) ?? leader?.gpu ?? null;
  const selected =
    selectedCpu && selectedGpu ? buildCombo(selectedCpu, selectedGpu, useCase) : null;

  const warning = selected ? bottleneckMessage(selected.bottleneck) : null;
  const rows = selectedCpu ? requirements(selectedCpu, selectedGpu) : [];

  const partOption = (part: { slug: string; name: string; msrp_usd?: number | null }) => ({
    slug: part.slug,
    name: part.name,
    priceLabel: formatPrice(part.msrp_usd),
  });

  return (
    <div className="compare">
      <section className="panel compare-picker">
        <div className="compare-tabs">
          <div className="compare-tab-group">
            {USE_CASES.map((option) => (
              <Link
                key={option.key}
                className="tag compare-tab"
                href={buildHref({ use: option.key, budgetUsd: parsed.budgetUsd })}
                aria-current={option.key === useCase.key}
              >
                {option.label}
              </Link>
            ))}
            <span className="kicker" style={{ marginLeft: 6 }}>
              CPU {cpus.length} · GPU {gpus.length}
            </span>
          </div>
        </div>

        <p className="note" style={{ margin: 0 }}>
          {useCase.summary}
        </p>

        <BuildControls
          use={useCase.key}
          budgetUsd={parsed.budgetUsd}
          cpuSlug={parsed.cpu}
          gpuSlug={parsed.gpu}
          cpuOptions={cpus.map(partOption)}
          gpuOptions={gpus.map(partOption)}
        />

        <p className="compare-figure-note">
          TechAPI 에는 메인보드 · 메모리 · 저장장치 · 파워 · 케이스 데이터가 없습니다. 그래서 실제 제품을
          고르는 것은 CPU 와 그래픽카드까지이고, 나머지는 아래에 <b>요구사양</b>으로만 계산해 드립니다.
          예산은 이 두 부품의 기준가 합계이지 완제품 가격이 아닙니다.
        </p>
      </section>

      {picks.length > 0 ? (
        <section className="build-results">
          {picks.map((combo, index) => (
            <ComboCard
              key={`${combo.cpu.slug}-${combo.gpu.slug}`}
              combo={combo}
              useCase={useCase}
              budgetUsd={parsed.budgetUsd}
              rank={index + 1}
              isSelected={
                selected?.cpu.slug === combo.cpu.slug && selected?.gpu.slug === combo.gpu.slug
              }
            />
          ))}
        </section>
      ) : (
        <div className="empty">
          <strong>이 예산으로 만들 수 있는 조합이 없습니다.</strong>
          <span className="note">
            기록된 가장 싼 CPU와 그래픽카드를 합쳐도 예산을 넘습니다. 예산을 올려 보세요.
          </span>
        </div>
      )}

      {selected && selectedCpu && selectedGpu && (
        <section className="panel compare-section">
          <div className="compare-tabs" style={{ paddingBottom: 14 }}>
            <span className="kicker">선택한 구성</span>
            <span className="combo-score">{formatPrice(selected.priceUsd)}</span>
          </div>

          <div className="build-selected">
            <div className="build-part">
              <span className="kicker">{selectedCpu.manufacturer.name}</span>
              <h2>{selectedCpu.name}</h2>
              <p className="note" style={{ margin: 0 }}>
                {cpuCoreLabel(selectedCpu)} · {cpuClockLabel(selectedCpu)}
              </p>
              <Link className="btn btn-ghost" href={`/cpus/${selectedCpu.slug}`}>
                상세 보기 →
              </Link>
            </div>
            <div className="build-plus" aria-hidden="true">
              +
            </div>
            <div className="build-part">
              <span className="kicker">{selectedGpu.manufacturer.name}</span>
              <h2>{selectedGpu.name}</h2>
              <p className="note" style={{ margin: 0 }}>
                {gpuMemoryLabel(selectedGpu)} · {selectedGpu.tdp_w}W
                {selectedGpu.fp32_tflops ? ` · ${selectedGpu.fp32_tflops} TFLOPS` : ""}
              </p>
            </div>
          </div>

          {warning && (
            <p className="tag tag-outline build-warning" role="status">
              {warning}
            </p>
          )}

          <h3 className="build-subhead">나머지 부품 요구사양</h3>
          <dl className="laptop-rows">
            {rows.map((row) => (
              <div className="laptop-row" key={row.label}>
                <dt>{row.label}</dt>
                <dd>{row.value}</dd>
              </div>
            ))}
          </dl>

          <p className="note" style={{ marginTop: 14 }}>
            {PSU_ASSUMPTION} 점수는 TechAPI 가 발행하는 0–100 정규화 지수이며 원시 벤치마크 점수가
            아닙니다. 부품 데이터 기준일 {generated}.
          </p>
        </section>
      )}
    </div>
  );
}
