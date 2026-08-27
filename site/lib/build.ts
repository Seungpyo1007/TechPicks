import type { Cpu } from "@/lib/cpu";
import type { Gpu } from "@/lib/desktop-part";

/**
 * 조립 견적의 추천 엔진.
 *
 * TechAPI 에는 메인보드·메모리·저장장치·파워·케이스가 없다. 그래서 실제 제품을 고르는 것은
 * CPU 와 GPU 뿐이고, 나머지는 두 부품에서 **도출되는 요구사양**으로만 제시한다.
 * 없는 제품을 지어내지 않는다.
 *
 * 점수는 전부 TechAPI 가 발행하는 0–100 정규화 지수다. 원시 벤치마크 점수가 아니다.
 */

export type UseCaseKey = "gaming" | "creator" | "office" | "ai";

type Weights = { gpu: number; cpuSingle: number; cpuMulti: number; vram: number };

export type UseCase = {
  key: UseCaseKey;
  label: string;
  summary: string;
  weights: Weights;
  /** 내장 그래픽만으로도 성립하는 용도인지. 사무·개발만 해당한다. */
  allowsIntegratedGpu: boolean;
};

export const USE_CASES: UseCase[] = [
  {
    key: "gaming",
    label: "게이밍",
    summary: "프레임은 대부분 GPU가 좌우합니다. CPU는 싱글코어가 더 중요합니다.",
    weights: { gpu: 0.7, cpuSingle: 0.25, cpuMulti: 0.05, vram: 0 },
    allowsIntegratedGpu: false,
  },
  {
    key: "creator",
    label: "영상 · 렌더링",
    summary: "GPU 가속과 CPU 멀티코어를 함께 씁니다. 어느 한쪽만 높으면 손해입니다.",
    weights: { gpu: 0.45, cpuSingle: 0.15, cpuMulti: 0.4, vram: 0 },
    allowsIntegratedGpu: false,
  },
  {
    key: "office",
    label: "사무 · 개발",
    summary: "빌드와 반응 속도가 CPU에 달려 있습니다. 외장 GPU는 선택입니다.",
    weights: { gpu: 0.1, cpuSingle: 0.45, cpuMulti: 0.45, vram: 0 },
    allowsIntegratedGpu: true,
  },
  {
    key: "ai",
    label: "AI · 연구",
    summary: "모델이 올라가려면 VRAM 용량이 먼저입니다. 그다음이 연산 성능입니다.",
    weights: { gpu: 0.5, cpuSingle: 0.15, cpuMulti: 0.25, vram: 0.1 },
    allowsIntegratedGpu: false,
  },
];

export function findUseCase(key: UseCaseKey): UseCase {
  const found = USE_CASES.find((useCase) => useCase.key === key);
  if (!found) throw new Error(`unknown use case: ${key}`);
  return found;
}

/** 조립에서 흔히 쓰는 예산 구간(두 부품 MSRP 합계 기준, USD). */
export const BUDGET_PRESETS = [600, 1000, 1500, 2500] as const;
export const MIN_BUDGET = 200;
export const MAX_BUDGET = 6000;

/** 보드·메모리·저장장치·팬이 쓰는 몫. 파워 용량 계산에만 쓰는 가정값이고 화면에 밝힌다. */
const PLATFORM_WATTS = 150;
/** 병목으로 볼 지수 차이. */
const BOTTLENECK_GAP = 20;

function cpuSingle(cpu: Cpu): number {
  return cpu.score?.single?.index ?? 0;
}

function cpuMulti(cpu: Cpu): number {
  return cpu.score?.multi?.index ?? 0;
}

function gpuGraphics(gpu: Gpu): number {
  return gpu.score?.graphics?.index ?? 0;
}

/** VRAM 을 0–100 으로. 32GB 를 만점으로 본다 — 현행 소비자용 최대 용량이다. */
function vramIndex(gpu: Gpu): number {
  return Math.min(100, ((gpu.memory_gb ?? 0) / 32) * 100);
}

export type Combo = {
  cpu: Cpu;
  gpu: Gpu;
  /** 용도 가중치를 적용한 0–100 점수. */
  score: number;
  priceUsd: number;
  /** 권장 파워 용량(W). 50W 단위로 올림. */
  psuWatts: number;
  bottleneck: Bottleneck;
};

export type Bottleneck =
  | { kind: "balanced" }
  | { kind: "cpu-bound"; gap: number }
  | { kind: "gpu-bound"; gap: number };

/**
 * 병목을 볼 때 쓰는 CPU 축. 용도가 실제로 기대는 쪽으로 골라야 한다.
 *
 * 게이밍을 멀티코어와 견주면 8코어 X3D 처럼 게임에 강한 CPU 가 병목으로 잘못 찍힌다.
 */
function cpuAxisFor(cpu: Cpu, useCase: UseCase): number {
  if (useCase.key === "gaming") return cpuSingle(cpu);
  if (useCase.key === "office") return (cpuSingle(cpu) + cpuMulti(cpu)) / 2;
  return cpuMulti(cpu);
}

function bottleneckOf(cpu: Cpu, gpu: Gpu, useCase: UseCase): Bottleneck {
  const gap = Math.round(gpuGraphics(gpu) - cpuAxisFor(cpu, useCase));
  if (Math.abs(gap) < BOTTLENECK_GAP) return { kind: "balanced" };
  // GPU 지수가 훨씬 높으면 CPU 가 그래픽을 못 먹인다.
  return gap > 0 ? { kind: "cpu-bound", gap } : { kind: "gpu-bound", gap: -gap };
}

export function recommendedWatts(cpu: Cpu, gpu: Gpu): number {
  const cpuDraw = cpu.max_tdp_w ?? cpu.tdp_w ?? 0;
  return Math.ceil((cpuDraw + gpu.tdp_w + PLATFORM_WATTS) / 50) * 50;
}

export function comboScore(cpu: Cpu, gpu: Gpu, useCase: UseCase): number {
  const { weights } = useCase;
  const raw =
    weights.gpu * gpuGraphics(gpu) +
    weights.cpuSingle * cpuSingle(cpu) +
    weights.cpuMulti * cpuMulti(cpu) +
    weights.vram * vramIndex(gpu);
  return Math.round(raw * 10) / 10;
}

export function buildCombo(cpu: Cpu, gpu: Gpu, useCase: UseCase): Combo {
  return {
    cpu,
    gpu,
    score: comboScore(cpu, gpu, useCase),
    priceUsd: (cpu.msrp_usd ?? 0) + (gpu.msrp_usd ?? 0),
    psuWatts: recommendedWatts(cpu, gpu),
    bottleneck: bottleneckOf(cpu, gpu, useCase),
  };
}

/**
 * 예산 안에서 점수가 가장 높은 조합을 고른다.
 *
 * 가격이 기록되지 않은 부품은 예산 판단이 불가능해 자동 추천에서 뺀다.
 * (수동 선택에서는 고를 수 있다 — 그때는 예산을 따지지 않는다.)
 */
export function recommend(
  cpus: Cpu[],
  gpus: Gpu[],
  useCase: UseCase,
  budgetUsd: number,
  limit = 3,
): Combo[] {
  const pricedCpus = cpus.filter((cpu) => (cpu.msrp_usd ?? 0) > 0);
  const pricedGpus = gpus.filter((gpu) => (gpu.msrp_usd ?? 0) > 0);

  const combos: Combo[] = [];
  for (const cpu of pricedCpus) {
    for (const gpu of pricedGpus) {
      const price = (cpu.msrp_usd ?? 0) + (gpu.msrp_usd ?? 0);
      if (price > budgetUsd) continue;
      combos.push(buildCombo(cpu, gpu, useCase));
    }
  }

  combos.sort((left, right) => right.score - left.score || left.priceUsd - right.priceUsd);

  // 같은 CPU 나 같은 GPU 로 상위가 도배되면 고를 이유가 없다. 한 번씩만 남긴다.
  const seenCpu = new Set<string>();
  const seenGpu = new Set<string>();
  const picked: Combo[] = [];
  for (const combo of combos) {
    if (seenCpu.has(combo.cpu.slug) || seenGpu.has(combo.gpu.slug)) continue;
    seenCpu.add(combo.cpu.slug);
    seenGpu.add(combo.gpu.slug);
    picked.push(combo);
    if (picked.length >= limit) break;
  }
  return picked;
}

/** 조합을 고른 이유 한 줄. 점수·가격·전력만 근거로 쓴다. */
export function comboReason(combo: Combo, useCase: UseCase, budgetUsd: number): string {
  const headroom = budgetUsd - combo.priceUsd;
  const lead =
    useCase.key === "office"
      ? `CPU 멀티 ${Math.round(cpuMulti(combo.cpu))}`
      : `GPU ${Math.round(gpuGraphics(combo.gpu))}`;
  const rest = headroom > 100 ? `예산 $${headroom} 여유` : "예산에 거의 맞춤";
  return `${lead} · 합계 $${combo.priceUsd.toLocaleString("en-US")} · ${rest} · 권장 ${combo.psuWatts}W`;
}

export type Requirement = { label: string; value: string };

/** CPU·GPU 레코드에서 도출되는 나머지 부품 요구사양. */
export function requirements(cpu: Cpu, gpu: Gpu | null): Requirement[] {
  const rows: Requirement[] = [
    { label: "메인보드 소켓", value: cpu.socket ?? "기록 없음" },
    { label: "메모리 규격", value: cpu.memory_support ?? "기록 없음" },
  ];

  if (gpu) {
    rows.push(
      { label: "권장 파워", value: `${recommendedWatts(cpu, gpu)}W 이상` },
      { label: "그래픽 슬롯", value: gpu.pcie_version ?? "PCIe x16" },
      { label: "그래픽 소비전력", value: `${gpu.tdp_w}W` },
    );
  } else {
    rows.push({
      label: "권장 파워",
      value: `${Math.ceil(((cpu.max_tdp_w ?? cpu.tdp_w ?? 0) + PLATFORM_WATTS) / 50) * 50}W 이상`,
    });
  }

  rows.push({
    label: "내장 그래픽",
    value: cpu.integrated_graphics ?? "없음 — 외장 GPU 필수",
  });
  return rows;
}

export const PSU_ASSUMPTION = `권장 파워는 CPU 최대 소비전력과 GPU 소비전력에 보드·메모리·저장장치·팬 몫 ${PLATFORM_WATTS}W 를 더해 50W 단위로 올린 값입니다.`;

export function bottleneckMessage(bottleneck: Bottleneck): string | null {
  if (bottleneck.kind === "balanced") return null;
  return bottleneck.kind === "cpu-bound"
    ? `CPU가 GPU를 따라가지 못합니다 (지수 차 ${bottleneck.gap}). CPU를 올리거나 GPU를 한 단계 낮추세요.`
    : `GPU가 CPU에 비해 약합니다 (지수 차 ${bottleneck.gap}). 그래픽 작업이 많다면 GPU를 올리세요.`;
}
