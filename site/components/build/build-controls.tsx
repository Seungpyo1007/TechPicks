"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { BUDGET_PRESETS, MAX_BUDGET, MIN_BUDGET, type UseCaseKey } from "@/lib/build";
import { buildHref } from "@/lib/build-query";

export type PartOption = { slug: string; name: string; priceLabel: string };

/**
 * 예산과 부품 선택. 값이 바뀌면 URL 을 갈아끼운다.
 *
 * 견적 계산은 전부 서버가 한다. 이 컴포넌트는 조건만 URL 에 싣는다.
 */
export function BuildControls({
  use,
  budgetUsd,
  cpuSlug,
  gpuSlug,
  cpuOptions,
  gpuOptions,
}: {
  use: UseCaseKey;
  budgetUsd: number;
  cpuSlug: string | null;
  gpuSlug: string | null;
  cpuOptions: PartOption[];
  gpuOptions: PartOption[];
}) {
  const router = useRouter();
  const [budgetDraft, setBudgetDraft] = useState(String(budgetUsd));

  function go(next: { budgetUsd?: number; cpu?: string | null; gpu?: string | null }) {
    router.push(
      buildHref({
        use,
        budgetUsd: next.budgetUsd ?? budgetUsd,
        cpu: next.cpu === undefined ? cpuSlug : next.cpu,
        gpu: next.gpu === undefined ? gpuSlug : next.gpu,
      }),
    );
  }

  function applyBudget() {
    const parsed = Number(budgetDraft);
    if (!Number.isFinite(parsed)) return setBudgetDraft(String(budgetUsd));
    const clamped = Math.min(MAX_BUDGET, Math.max(MIN_BUDGET, Math.round(parsed)));
    setBudgetDraft(String(clamped));
    if (clamped !== budgetUsd) go({ budgetUsd: clamped });
  }

  return (
    <div className="build-controls">
      <form
        className="build-budget"
        onSubmit={(event) => {
          event.preventDefault();
          applyBudget();
        }}
      >
        <label className="login-field" htmlFor="build-budget">
          <span>예산 (CPU + 그래픽카드 합계, USD)</span>
          <input
            id="build-budget"
            className="input"
            type="number"
            inputMode="numeric"
            min={MIN_BUDGET}
            max={MAX_BUDGET}
            step={50}
            value={budgetDraft}
            onChange={(event) => setBudgetDraft(event.target.value)}
            onBlur={applyBudget}
          />
        </label>
        <div className="build-presets">
          {BUDGET_PRESETS.map((preset) => (
            <button
              key={preset}
              type="button"
              className="tag compare-tab"
              aria-current={preset === budgetUsd}
              onClick={() => {
                setBudgetDraft(String(preset));
                go({ budgetUsd: preset });
              }}
            >
              ${preset.toLocaleString("en-US")}
            </button>
          ))}
        </div>
      </form>

      <div className="build-picks">
        <label className="login-field">
          <span>CPU 직접 고르기</span>
          <select
            className="input"
            value={cpuSlug ?? ""}
            onChange={(event) => go({ cpu: event.target.value || null })}
          >
            <option value="">추천에 맡기기</option>
            {cpuOptions.map((option) => (
              <option key={option.slug} value={option.slug}>
                {option.name} · {option.priceLabel}
              </option>
            ))}
          </select>
        </label>
        <label className="login-field">
          <span>그래픽카드 직접 고르기</span>
          <select
            className="input"
            value={gpuSlug ?? ""}
            onChange={(event) => go({ gpu: event.target.value || null })}
          >
            <option value="">추천에 맡기기</option>
            {gpuOptions.map((option) => (
              <option key={option.slug} value={option.slug}>
                {option.name} · {option.priceLabel}
              </option>
            ))}
          </select>
        </label>
      </div>
    </div>
  );
}
