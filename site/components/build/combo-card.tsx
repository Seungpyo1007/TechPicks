import Link from "next/link";
import { buildHref } from "@/lib/build-query";
import { type Combo, comboReason, type UseCase } from "@/lib/build";
import { cpuCoreLabel } from "@/lib/cpu";
import { gpuMemoryLabel } from "@/lib/desktop-part";
import { formatPrice } from "@/lib/format";
import { percent, stagger } from "@/lib/score";

/** 추천 조합 카드. 1순위만 강조하고 나머지는 같은 형식으로 나열한다. */
export function ComboCard({
  combo,
  useCase,
  budgetUsd,
  rank,
  isSelected,
}: {
  combo: Combo;
  useCase: UseCase;
  budgetUsd: number;
  rank: number;
  isSelected: boolean;
}) {
  return (
    <article
      className="panel combo-card"
      aria-current={isSelected ? "true" : undefined}
      style={{ animationDelay: stagger(rank, 60) }}
    >
      <div className="combo-head">
        <span className="kicker">{rank === 1 ? "1순위 추천" : `${rank}순위`}</span>
        <span className="combo-score">{combo.score}</span>
      </div>

      <dl className="laptop-rows">
        <div className="laptop-row">
          <dt>CPU</dt>
          <dd>
            {combo.cpu.name}
            <br />
            <span className="note">
              {cpuCoreLabel(combo.cpu)} · {formatPrice(combo.cpu.msrp_usd)}
            </span>
          </dd>
        </div>
        <div className="laptop-row">
          <dt>그래픽</dt>
          <dd>
            {combo.gpu.name}
            <br />
            <span className="note">
              {gpuMemoryLabel(combo.gpu)} · {formatPrice(combo.gpu.msrp_usd)}
            </span>
          </dd>
        </div>
      </dl>

      <div className="axis-bar">
        <span>적합도</span>
        <span className="meter">
          <i style={{ width: percent(combo.score) }} />
        </span>
        <b>{Math.round(combo.score)}</b>
      </div>

      <p className="note" style={{ margin: 0 }}>
        {comboReason(combo, useCase, budgetUsd)}
      </p>

      <Link
        className={rank === 1 ? "btn btn-primary" : "btn btn-secondary"}
        href={buildHref({ use: useCase.key, budgetUsd, cpu: combo.cpu.slug, gpu: combo.gpu.slug })}
        style={{ alignSelf: "start", height: 38 }}
      >
        {isSelected ? "선택됨" : "이 조합 보기"}
      </Link>
    </article>
  );
}
