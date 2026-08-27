import { cpuClockLabel, cpuCoreLabel, type Cpu } from "@/lib/cpu";
import { formatDate, formatPrice } from "@/lib/format";
import { percent } from "@/lib/score";

const NONE = "기록 없음";

/** 정본 CPU 상세 카드. 지수 두 개는 막대로, 나머지는 스펙 타일로. */
export function CpuDetail({ cpu }: { cpu: Cpu }) {
  const single = cpu.score?.single?.index ?? null;
  const multi = cpu.score?.multi?.index ?? null;

  const specs: Array<{ key: string; value: string }> = [
    { key: "아키텍처", value: cpu.architecture ?? NONE },
    { key: "공정", value: cpu.process_node ?? NONE },
    { key: "코어 구성", value: cpuCoreLabel(cpu) },
    { key: "클럭", value: cpuClockLabel(cpu) },
    { key: "L3 캐시", value: cpu.l3_cache_mb ? `${cpu.l3_cache_mb}MB` : NONE },
    { key: "TDP", value: cpu.tdp_w ? `${cpu.tdp_w}W${cpu.max_tdp_w ? ` (최대 ${cpu.max_tdp_w}W)` : ""}` : NONE },
    { key: "내장 그래픽", value: cpu.integrated_graphics ?? "없음" },
    { key: "메모리", value: cpu.memory_support ?? NONE },
    { key: "소켓", value: cpu.socket ?? NONE },
    { key: "세그먼트", value: cpu.segment ?? NONE },
    { key: "기준가", value: formatPrice(cpu.msrp_usd) },
    { key: "출시", value: formatDate(cpu.release_date) },
  ];

  return (
    <section className="panel detail-card">
      <div className="detail-head">
        <div className="detail-headings">
          <span className="kicker">{cpu.manufacturer.name}</span>
          <h2 style={{ fontSize: 26 }}>{cpu.name}</h2>
          <div className="detail-tags">
            {cpu.process_node && <span className="tag tag-accent">{cpu.process_node}</span>}
            {cpu.socket && <span className="tag tag-neutral">{cpu.socket}</span>}
            <span className={cpu.verified ? "tag tag-accent" : "tag tag-outline"}>
              {cpu.verified ? "검증됨" : "미검증"}
            </span>
          </div>
        </div>
        <div className="detail-score">
          <span className="detail-score-value">
            {cpu.score?.overall === undefined || cpu.score?.overall === null
              ? "—"
              : Math.round(cpu.score.overall)}
          </span>
          <span className="note">TECHPICKS SCORE</span>
        </div>
      </div>

      <div className="axis-bars">
        <div className="axis-bar">
          <span>싱글</span>
          <span className="meter">
            <i style={{ width: percent(single) }} />
          </span>
          <b>{single === null ? "—" : Math.round(single)}</b>
        </div>
        <div className="axis-bar">
          <span>멀티</span>
          <span className="meter meter-deep">
            <i style={{ width: percent(multi) }} />
          </span>
          <b>{multi === null ? "—" : Math.round(multi)}</b>
        </div>
        <p className="note" style={{ margin: 0 }}>
          Cinebench R23 기록에서 산출한 0–100 정규화 지수입니다. TechAPI 는 원시 벤치 점수를 발행하지
          않습니다.
        </p>
      </div>

      <dl className="spec-grid">
        {specs.map((spec) => (
          <div className="spec-tile" key={spec.key}>
            <dt>{spec.key}</dt>
            <dd>{spec.value}</dd>
          </div>
        ))}
      </dl>
    </section>
  );
}
