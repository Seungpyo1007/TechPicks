import { type Axis, radarLabelPoints, radarPoints, radarRings, radarSpokes } from "@/lib/score";

/** 정본 상세 화면의 오각형 레이더. viewBox 와 좌표계는 정본과 동일하다. */
export function ScoreRadar({ axes, label }: { axes: Axis[]; label: string }) {
  const rings = radarRings();
  const labelPoints = radarLabelPoints();

  return (
    <svg className="radar" viewBox="0 0 320 300" role="img" aria-label={label}>
      {rings.map((points, index) => (
        <polygon
          key={points}
          points={points}
          fill="none"
          stroke={index === 0 ? "var(--color-neutral-400)" : "var(--color-neutral-300)"}
          strokeWidth={1}
        />
      ))}
      <path d={radarSpokes()} stroke="var(--color-neutral-400)" strokeWidth={1} fill="none" />
      <g className="radar-shape">
        <polygon
          points={radarPoints(axes)}
          fill="color-mix(in srgb, var(--color-accent) 22%, transparent)"
          stroke="var(--color-accent-700)"
          strokeWidth={2.5}
        />
      </g>
      {axes.map((axis, index) => (
        <text
          key={axis.key}
          x={labelPoints[index].x}
          y={labelPoints[index].y}
          textAnchor="middle"
          fontSize={14}
          fill="currentColor"
          fontFamily="var(--font-heading)"
        >
          {axis.label}
        </text>
      ))}
    </svg>
  );
}
