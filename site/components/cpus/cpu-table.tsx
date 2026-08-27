import Link from "next/link";
import { cpuClockLabel, cpuCoreLabel, type Cpu } from "@/lib/cpu";
import { formatPrice } from "@/lib/format";
import { percent } from "@/lib/score";

/** 정본 CPU 화면의 표. 원시 벤치 대신 TechAPI 정규화 지수를 싣는다. */
export function CpuTable({ cpus, activeSlug }: { cpus: Cpu[]; activeSlug?: string }) {
  return (
    <div className="panel" style={{ padding: 18, overflowX: "auto" }}>
      <table className="table" style={{ minWidth: 720 }}>
        <thead>
          <tr>
            <th>#</th>
            <th>프로세서</th>
            <th>코어 / 스레드</th>
            <th>부스트</th>
            <th>싱글 지수</th>
            <th>멀티 지수</th>
            <th>TDP</th>
            <th>가격</th>
          </tr>
        </thead>
        <tbody>
          {cpus.map((cpu, index) => {
            const single = cpu.score?.single?.index ?? null;
            const multi = cpu.score?.multi?.index ?? null;
            return (
              <tr key={cpu.slug} aria-current={cpu.slug === activeSlug ? "true" : undefined}>
                <td>{index + 1}</td>
                <td>
                  <Link href={`/cpus/${cpu.slug}`} style={{ display: "grid", gap: 2 }}>
                    <span style={{ fontWeight: 500 }}>{cpu.name}</span>
                    <span className="note">{cpu.architecture ?? cpu.manufacturer.name}</span>
                  </Link>
                </td>
                <td>{cpuCoreLabel(cpu)}</td>
                <td>{cpuClockLabel(cpu)}</td>
                <td>{single === null ? "—" : Math.round(single)}</td>
                <td>
                  <span style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <span className="meter meter-inline meter-deep">
                      <i style={{ width: percent(multi) }} />
                    </span>
                    <span>{multi === null ? "—" : Math.round(multi)}</span>
                  </span>
                </td>
                <td>{cpu.tdp_w ? `${cpu.tdp_w}W` : "—"}</td>
                <td>{formatPrice(cpu.msrp_usd)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
