import type { Phone } from "@/lib/phone";

/**
 * 정본 `TechPicks Web M3.dc.html` 의 레이더/막대 계산을 그대로 옮긴 것.
 *
 * 축 이름만 한 곳이 다르다. 정본의 다섯 번째 축은 `기능`(방수·무선충전에서 파생)이었지만
 * TechAPI 채점(`assets/catalog/v1.json`)에는 대응 필드가 없다. 없는 점수를 새로 만들지 않고
 * 카탈로그가 실제로 채점하는 `value` 축을 `가치` 라는 이름으로 쓴다.
 */
export const AXES = [
  { key: "performance", label: "성능" },
  { key: "camera", label: "카메라" },
  { key: "display", label: "화면" },
  { key: "battery", label: "배터리" },
  { key: "value", label: "가치" },
] as const;

export type AxisKey = (typeof AXES)[number]["key"];

/** 정오각형 꼭짓점의 단위 벡터. 12시 방향부터 시계방향. */
const UNIT: ReadonlyArray<readonly [number, number]> = [
  [0, -1],
  [0.951, -0.309],
  [0.588, 0.809],
  [-0.588, 0.809],
  [-0.951, -0.309],
];

const RADAR_CENTER = { x: 160, y: 150 } as const;
const RADAR_RADIUS = 110;
/** 정본과 같은 하한. 0점 축이 중심으로 붕괴해 도형이 안 보이는 걸 막는다. */
const RADAR_FLOOR = 20;

export type Axis = { key: AxisKey; label: string; value: number };

export function axisValues(phone: Phone): Axis[] {
  const score = phone.score;
  return AXES.map((axis) => ({
    key: axis.key,
    label: axis.label,
    value: Math.round(Number(score?.[axis.key] ?? 0)),
  }));
}

/** SVG `points` 속성 문자열. viewBox 는 `0 0 320 300`. */
export function radarPoints(axes: Axis[]): string {
  return axes
    .map((axis, index) => {
      const radius = RADAR_RADIUS * (Math.max(RADAR_FLOOR, axis.value) / 100);
      const x = RADAR_CENTER.x + radius * UNIT[index][0];
      const y = RADAR_CENTER.y + radius * UNIT[index][1];
      return `${x.toFixed(1)},${y.toFixed(1)}`;
    })
    .join(" ");
}

/** 배경 격자 오각형 5겹. 정본은 좌표를 손으로 박아 뒀지만 같은 식으로 생성된다. */
export function radarRings(): string[] {
  return [1, 0.8, 0.6, 0.4, 0.2].map((scale) =>
    UNIT.map(([ux, uy]) => {
      const radius = RADAR_RADIUS * scale;
      return `${(RADAR_CENTER.x + radius * ux).toFixed(1)},${(RADAR_CENTER.y + radius * uy).toFixed(1)}`;
    }).join(" "),
  );
}

export function radarSpokes(): string {
  return UNIT.map(([ux, uy]) => {
    const x = RADAR_CENTER.x + RADAR_RADIUS * ux;
    const y = RADAR_CENTER.y + RADAR_RADIUS * uy;
    return `M${RADAR_CENTER.x},${RADAR_CENTER.y} L${x.toFixed(1)},${y.toFixed(1)}`;
  }).join(" ");
}

/** 축 라벨을 그릴 위치. 도형보다 조금 바깥. */
export function radarLabelPoints(): Array<{ x: number; y: number }> {
  return UNIT.map(([ux, uy]) => ({
    x: Math.round(RADAR_CENTER.x + (RADAR_RADIUS + 26) * ux),
    y: Math.round(RADAR_CENTER.y + (RADAR_RADIUS + 26) * uy) + 5,
  }));
}

export function overallScore(phone: Phone): number | null {
  const overall = phone.score?.overall;
  return overall === undefined || overall === null ? null : Math.round(overall);
}

/** 0–100 지수를 CSS `width` 로. 값이 없으면 막대를 그리지 않는다. */
export function percent(value: number | null | undefined, max = 100): string {
  if (value === null || value === undefined || max <= 0) return "0%";
  return `${Math.max(0, Math.min(100, Math.round((value / max) * 100)))}%`;
}

/** 정본의 스태거. 리스트 인덱스에 상수를 곱한 지연을 돌려준다. */
export function stagger(index: number, step = 45): string {
  return `${index * step}ms`;
}
