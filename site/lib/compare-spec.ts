import { formatPrice } from "@/lib/format";
import type { Phone } from "@/lib/phone";
import type { Soc } from "@/lib/soc";

/**
 * 정본 `TechPicks Web M3.dc.html` 의 `cmpRows` / 스펙 그룹 이식.
 *
 * 정본은 손으로 큐레이션한 데이터라 Geekbench 원시 점수(예: 10,558)를 갖고 있었지만
 * TechAPI v1 은 원시 벤치를 발행하지 않고 0–100 정규화 지수만 준다. 표 구조와 승자 판정은
 * 그대로 두고 라벨/단위만 지수 기준으로 바꿨다. 없는 숫자를 만들어 넣지 않는다.
 */

/** 큰 값이 이기는 항목인지, 작은 값이 이기는 항목인지. null 이면 승패를 가리지 않는다. */
type Direction = "high" | "low" | null;

export type CompareContext = { soc: Soc | null };

type RowDefinition = {
  label: string;
  /** 승자 판정에 쓰는 수치. 비교 불가면 null. */
  value: (phone: Phone, context: CompareContext) => number | null;
  direction: Direction;
  format: (phone: Phone, context: CompareContext) => string;
};

export type CompareCell = { text: string; isBest: boolean };
export type CompareRow = { label: string; cells: CompareCell[] };
export type CompareGroup = { title: string; rows: CompareRow[] };

const NONE = "기록 없음";

const REAR_TYPES = ["main", "ultrawide", "telephoto", "periscope", "macro", "depth", "multispectral"];
const SELFIE_TYPES = ["selfie", "cover-selfie", "inner-selfie", "front-depth"];
const ZOOM_TYPES = ["telephoto", "periscope"];

function megapixels(phone: Phone, types: string[]): number[] {
  return (phone.cameras ?? [])
    .filter((camera) => types.includes(camera.type))
    .map((camera) => camera.mp ?? 0)
    .filter((mp) => mp > 0);
}

function cameraLabel(phone: Phone, types: string[], emptyText = NONE): string {
  const values = megapixels(phone, types);
  return values.length ? values.map((mp) => `${mp}MP`).join(" + ") : emptyText;
}

function maxMegapixels(phone: Phone, types: string[]): number | null {
  const values = megapixels(phone, types);
  return values.length ? Math.max(...values) : null;
}

function storageLabel(phone: Phone): string {
  const options = phone.storage_options_gb ?? [];
  if (!options.length) return NONE;
  return options.map((gb) => (gb >= 1024 ? `${gb / 1024}TB` : `${gb}GB`)).join(" · ");
}

function zoomLenses(phone: Phone) {
  return (phone.cameras ?? []).filter((camera) => ZOOM_TYPES.includes(camera.type));
}

function zoomLabel(phone: Phone): string {
  const lenses = zoomLenses(phone);
  if (!lenses.length) return "없음";
  return lenses
    .map((lens) => `${lens.mp ?? "?"}MP${lens.optical_zoom ? ` ×${lens.optical_zoom}` : ""}`)
    .join(" + ");
}

function cpuIndex(context: CompareContext): number | null {
  return context.soc?.score?.cpu?.index ?? null;
}

function systemIndex(context: CompareContext): number | null {
  return context.soc?.score?.system?.index ?? null;
}

function indexLabel(value: number | null): string {
  return value === null ? NONE : `${Math.round(value)} / 100`;
}

const CHIPSET_ROW: RowDefinition = {
  label: "칩셋",
  value: () => null,
  direction: null,
  format: (phone) => phone.soc?.name ?? NONE,
};

const CPU_INDEX_ROW: RowDefinition = {
  label: "Geekbench CPU 지수",
  value: (_phone, context) => cpuIndex(context),
  direction: "high",
  format: (_phone, context) => indexLabel(cpuIndex(context)),
};

const BATTERY_ROW: RowDefinition = {
  label: "배터리",
  value: (phone) => phone.battery_mah ?? null,
  direction: "high",
  format: (phone) => (phone.battery_mah ? `${phone.battery_mah.toLocaleString("en-US")}mAh` : NONE),
};

const WEIGHT_ROW: RowDefinition = {
  label: "무게",
  value: (phone) => phone.weight_g ?? null,
  direction: "low",
  format: (phone) => (phone.weight_g ? `${phone.weight_g}g` : NONE),
};

const RAM_ROW: RowDefinition = {
  label: "메모리",
  value: (phone) => phone.ram_gb ?? null,
  direction: "high",
  format: (phone) => (phone.ram_gb ? `${phone.ram_gb}GB` : NONE),
};

const PRICE_ROW: RowDefinition = {
  label: "가격",
  value: (phone) => phone.msrp_usd ?? null,
  direction: "low",
  format: (phone) => formatPrice(phone.msrp_usd),
};

/** 비교 상단의 요약 행. 정본 `cmpRows` 와 같은 항목 순서. */
const SUMMARY_ROWS: RowDefinition[] = [
  {
    label: "종합 점수",
    value: (phone) => phone.score?.overall ?? null,
    direction: "high",
    format: (phone) => (phone.score?.overall ? String(Math.round(phone.score.overall)) : NONE),
  },
  CHIPSET_ROW,
  CPU_INDEX_ROW,
  {
    label: "화면",
    value: (phone) => phone.display?.size_inch ?? null,
    direction: "high",
    format: (phone) =>
      phone.display?.size_inch ? `${phone.display.size_inch}″ ${phone.display.refresh_hz ?? 60}Hz` : NONE,
  },
  {
    label: "후면 카메라",
    value: (phone) => maxMegapixels(phone, REAR_TYPES),
    direction: "high",
    format: (phone) => cameraLabel(phone, REAR_TYPES),
  },
  BATTERY_ROW,
  WEIGHT_ROW,
  RAM_ROW,
  PRICE_ROW,
];

/** 정본의 여섯 개 스펙 그룹. */
const SPEC_GROUPS: Array<{ title: string; rows: RowDefinition[] }> = [
  {
    title: "성능",
    rows: [
      CHIPSET_ROW,
      CPU_INDEX_ROW,
      {
        label: "AnTuTu 시스템 지수",
        value: (_phone, context) => systemIndex(context),
        direction: "high",
        format: (_phone, context) => indexLabel(systemIndex(context)),
      },
      RAM_ROW,
      {
        label: "저장",
        value: (phone) => phone.storage_options_gb?.at(-1) ?? null,
        direction: "high",
        format: storageLabel,
      },
    ],
  },
  {
    title: "화면",
    rows: [
      {
        label: "크기",
        value: (phone) => phone.display?.size_inch ?? null,
        direction: "high",
        format: (phone) => (phone.display?.size_inch ? `${phone.display.size_inch}″` : NONE),
      },
      {
        label: "주사율",
        value: (phone) => phone.display?.refresh_hz ?? null,
        direction: "high",
        format: (phone) => (phone.display?.refresh_hz ? `${phone.display.refresh_hz}Hz` : NONE),
      },
      {
        label: "해상도",
        value: (phone) => phone.display?.ppi ?? null,
        direction: "high",
        format: (phone) =>
          `${phone.display?.resolution ?? NONE}${phone.display?.ppi ? ` · ${phone.display.ppi}ppi` : ""}`,
      },
      {
        label: "최대 밝기",
        value: (phone) => phone.display?.brightness_nits ?? null,
        direction: "high",
        format: (phone) => (phone.display?.brightness_nits ? `${phone.display.brightness_nits} nits` : NONE),
      },
      {
        label: "패널",
        value: () => null,
        direction: null,
        format: (phone) => phone.display?.type ?? NONE,
      },
    ],
  },
  {
    title: "카메라",
    rows: [
      {
        label: "메인",
        value: (phone) => maxMegapixels(phone, ["main"]),
        direction: "high",
        format: (phone) => cameraLabel(phone, ["main"]),
      },
      {
        label: "초광각",
        value: (phone) => maxMegapixels(phone, ["ultrawide"]),
        direction: "high",
        format: (phone) => cameraLabel(phone, ["ultrawide"], "없음"),
      },
      {
        label: "망원 · 광학 줌",
        value: (phone) => {
          const zooms = zoomLenses(phone).map((lens) => lens.optical_zoom ?? 0);
          return zooms.length ? Math.max(...zooms) : null;
        },
        direction: "high",
        format: zoomLabel,
      },
      {
        label: "셀피",
        value: (phone) => maxMegapixels(phone, SELFIE_TYPES),
        direction: "high",
        format: (phone) => cameraLabel(phone, SELFIE_TYPES),
      },
    ],
  },
  {
    title: "배터리 · 충전",
    rows: [
      { ...BATTERY_ROW, label: "용량" },
      {
        label: "유선",
        value: (phone) => phone.charging_wired_w ?? null,
        direction: "high",
        format: (phone) => (phone.charging_wired_w ? `${phone.charging_wired_w}W` : NONE),
      },
      {
        label: "무선",
        value: (phone) => phone.charging_wireless_w ?? null,
        direction: "high",
        format: (phone) => (phone.charging_wireless_w ? `${phone.charging_wireless_w}W` : "미지원"),
      },
    ],
  },
  {
    title: "본체 · 소프트웨어",
    rows: [
      WEIGHT_ROW,
      {
        label: "두께",
        value: (phone) => phone.dimensions?.depth_mm ?? null,
        direction: "low",
        format: (phone) => (phone.dimensions?.depth_mm ? `${phone.dimensions.depth_mm}mm` : NONE),
      },
      {
        label: "방수",
        value: () => null,
        direction: null,
        format: (phone) => phone.ip_rating ?? NONE,
      },
      {
        label: "OS",
        value: () => null,
        direction: null,
        format: (phone) => [phone.os, phone.os_version].filter(Boolean).join(" ") || NONE,
      },
    ],
  },
  {
    title: "가격 · 출시",
    rows: [
      { ...PRICE_ROW, label: "기준가" },
      {
        label: "출시",
        value: () => null,
        direction: null,
        format: (phone) => phone.release_date ?? NONE,
      },
    ],
  },
];

function buildRow(definition: RowDefinition, phones: Phone[], contexts: CompareContext[]): CompareRow {
  const values = phones.map((phone, index) => definition.value(phone, contexts[index]));
  const comparable = values.filter((value): value is number => value !== null);

  let best: number | null = null;
  if (definition.direction && comparable.length > 1) {
    best = definition.direction === "high" ? Math.max(...comparable) : Math.min(...comparable);
    // 모든 값이 같으면 승자가 없다.
    if (comparable.every((value) => value === best)) best = null;
  }

  return {
    label: definition.label,
    cells: phones.map((phone, index) => ({
      text: definition.format(phone, contexts[index]),
      isBest: best !== null && values[index] === best,
    })),
  };
}

export function summaryRows(phones: Phone[], contexts: CompareContext[]): CompareRow[] {
  return SUMMARY_ROWS.map((definition) => buildRow(definition, phones, contexts));
}

export function specGroups(phones: Phone[], contexts: CompareContext[]): CompareGroup[] {
  return SPEC_GROUPS.map((group) => ({
    title: group.title,
    rows: group.rows.map((definition) => buildRow(definition, phones, contexts)),
  }));
}

/** `차이만 보기` 토글. 모든 칸이 같은 값인 행을 걸러낸다. */
export function onlyDifferences(groups: CompareGroup[]): CompareGroup[] {
  return groups
    .map((group) => ({
      title: group.title,
      rows: group.rows.filter((row) => new Set(row.cells.map((cell) => cell.text)).size > 1),
    }))
    .filter((group) => group.rows.length > 0);
}
