import type { CompareGroup, CompareRow } from "@/lib/compare-spec";
import { cpuClockLabel, cpuCoreLabel, type Cpu } from "@/lib/cpu";
import { formatDate, formatPrice } from "@/lib/format";
import { displayLabel, type Laptop, memoryLabel } from "@/lib/laptop";

/** 정본 비교 화면의 CPU·노트북 탭. 스마트폰과 같은 행/승자 구조를 쓴다. */
type Direction = "high" | "low" | null;

type Definition<T> = {
  label: string;
  value: (item: T) => number | null;
  direction: Direction;
  format: (item: T) => string;
};

const NONE = "기록 없음";

function buildRows<T>(definitions: Definition<T>[], items: T[]): CompareRow[] {
  return definitions.map((definition) => {
    const values = items.map(definition.value);
    const comparable = values.filter((value): value is number => value !== null);

    let best: number | null = null;
    if (definition.direction && comparable.length > 1) {
      best = definition.direction === "high" ? Math.max(...comparable) : Math.min(...comparable);
      if (comparable.every((value) => value === best)) best = null;
    }

    return {
      label: definition.label,
      cells: items.map((item, index) => ({
        text: definition.format(item),
        isBest: best !== null && values[index] === best,
      })),
    };
  });
}

const CPU_SUMMARY: Definition<Cpu>[] = [
  {
    label: "종합 점수",
    value: (cpu) => cpu.score?.overall ?? null,
    direction: "high",
    format: (cpu) => (cpu.score?.overall ? String(Math.round(cpu.score.overall)) : NONE),
  },
  {
    label: "싱글 지수",
    value: (cpu) => cpu.score?.single?.index ?? null,
    direction: "high",
    format: (cpu) => (cpu.score?.single?.index ? `${Math.round(cpu.score.single.index)} / 100` : NONE),
  },
  {
    label: "멀티 지수",
    value: (cpu) => cpu.score?.multi?.index ?? null,
    direction: "high",
    format: (cpu) => (cpu.score?.multi?.index ? `${Math.round(cpu.score.multi.index)} / 100` : NONE),
  },
];

const CPU_SPECS: Definition<Cpu>[] = [
  { label: "아키텍처", value: () => null, direction: null, format: (cpu) => cpu.architecture ?? NONE },
  { label: "공정", value: () => null, direction: null, format: (cpu) => cpu.process_node ?? NONE },
  {
    label: "코어",
    value: (cpu) => cpu.cores ?? null,
    direction: "high",
    format: (cpu) => cpuCoreLabel(cpu),
  },
  {
    label: "부스트 클럭",
    value: (cpu) => cpu.boost_clock_ghz ?? null,
    direction: "high",
    format: (cpu) => cpuClockLabel(cpu),
  },
  {
    label: "L3 캐시",
    value: (cpu) => cpu.l3_cache_mb ?? null,
    direction: "high",
    format: (cpu) => (cpu.l3_cache_mb ? `${cpu.l3_cache_mb}MB` : NONE),
  },
  {
    label: "TDP",
    value: (cpu) => cpu.tdp_w ?? null,
    direction: "low",
    format: (cpu) => (cpu.tdp_w ? `${cpu.tdp_w}W` : NONE),
  },
  {
    label: "내장 그래픽",
    value: () => null,
    direction: null,
    format: (cpu) => cpu.integrated_graphics ?? "없음",
  },
  { label: "메모리 지원", value: () => null, direction: null, format: (cpu) => cpu.memory_support ?? NONE },
  {
    label: "기준가",
    value: (cpu) => cpu.msrp_usd ?? null,
    direction: "low",
    format: (cpu) => formatPrice(cpu.msrp_usd),
  },
  { label: "출시", value: () => null, direction: null, format: (cpu) => formatDate(cpu.release_date) },
];

const LAPTOP_SUMMARY: Definition<Laptop>[] = [
  {
    label: "기준가",
    value: (laptop) => laptop.msrp_usd ?? null,
    direction: "low",
    format: (laptop) => formatPrice(laptop.msrp_usd),
  },
  {
    label: "메모리",
    value: (laptop) => laptop.ram_gb ?? null,
    direction: "high",
    format: (laptop) => (laptop.ram_gb ? `${laptop.ram_gb}GB` : NONE),
  },
  {
    label: "저장",
    value: (laptop) => laptop.storage_gb ?? null,
    direction: "high",
    format: (laptop) => memoryLabel(laptop),
  },
];

const LAPTOP_SPECS: Definition<Laptop>[] = [
  { label: "CPU", value: () => null, direction: null, format: (laptop) => laptop.cpu_name ?? NONE },
  { label: "GPU", value: () => null, direction: null, format: (laptop) => laptop.gpu_name ?? NONE },
  {
    label: "화면 크기",
    value: (laptop) => laptop.display?.size_inch ?? null,
    direction: "high",
    format: (laptop) => displayLabel(laptop),
  },
  {
    label: "무게",
    value: (laptop) => laptop.weight_g ?? null,
    direction: "low",
    format: (laptop) => (laptop.weight_g ? `${laptop.weight_g}g` : NONE),
  },
  { label: "OS", value: () => null, direction: null, format: (laptop) => laptop.os ?? NONE },
  {
    label: "검증",
    value: () => null,
    direction: null,
    format: (laptop) => (laptop.verified ? "검증됨" : "미검증"),
  },
  { label: "출시", value: () => null, direction: null, format: (laptop) => formatDate(laptop.release_date) },
];

export function cpuSummaryRows(cpus: Cpu[]): CompareRow[] {
  return buildRows(CPU_SUMMARY, cpus);
}

export function cpuSpecGroups(cpus: Cpu[]): CompareGroup[] {
  return [{ title: "구성", rows: buildRows(CPU_SPECS, cpus) }];
}

export function laptopSummaryRows(laptops: Laptop[]): CompareRow[] {
  return buildRows(LAPTOP_SUMMARY, laptops);
}

export function laptopSpecGroups(laptops: Laptop[]): CompareGroup[] {
  return [{ title: "구성", rows: buildRows(LAPTOP_SPECS, laptops) }];
}
