export function ScoreRing({ score, label = "종합 점수" }: { score?: number | null; label?: string }) {
  const normalized = Math.max(0, Math.min(100, score ?? 0));
  return (
    <div className="score-ring">
      <svg viewBox="0 0 120 120" aria-hidden="true">
        <circle className="score-ring-track" cx="60" cy="60" r="52" />
        <circle
          className="score-ring-value"
          cx="60"
          cy="60"
          r="52"
          pathLength="100"
          strokeDasharray={`${normalized} 100`}
        />
      </svg>
      <div>
        <strong>{score?.toFixed(1) ?? "—"}</strong>
        <span>{label}</span>
      </div>
    </div>
  );
}
