import type { Metadata } from "next";
import Link from "next/link";
import { Icon } from "@/components/ui/icon";
import { getCatalogCpus, getCatalogPhones, rankCpus, rankPhones } from "@/lib/catalog";
import { formatPrice } from "@/lib/format";
import { getLaptops } from "@/lib/laptop";
import { homeTiles } from "@/lib/nav";
import { overallScore, percent, stagger } from "@/lib/score";
import { canonicalUrl } from "@/lib/seo";

export const metadata: Metadata = {
  title: "함께하는 기술",
  description: "스마트폰 · CPU · 노트북을 같은 스펙 기준으로 정렬한 TechPicks 대시보드입니다.",
  alternates: { canonical: canonicalUrl("/") },
};

export default async function HomePage() {
  const [phones, cpus, laptops] = await Promise.all([
    getCatalogPhones(),
    getCatalogCpus(),
    getLaptops(),
  ]);

  const rankedPhones = rankPhones(phones);
  const topPhones = rankedPhones.slice(0, 5);
  const topCpus = rankCpus(cpus).slice(0, 5);
  const leader = rankedPhones[0];
  const tiles = homeTiles({ phones: phones.length, cpus: cpus.length, laptops: laptops.length });

  return (
    <div className="stack">
      <section className="panel home-hero">
        <div className="home-hero-copy">
          <span className="kicker">랭킹 리스트 2026</span>
          <h2>함께하는 기술</h2>
          <p>
            스마트폰 · CPU · 노트북을 같은 스펙 기준으로 정렬했습니다. 점수는 TechAPI 원본 수치에서
            산출됩니다.
          </p>
        </div>
        {leader && (
          <div className="home-hero-side">
            <span className="kicker">이번 주 1위</span>
            <span className="home-hero-top">{leader.name}</span>
            <span style={{ fontSize: 12, opacity: 0.78 }}>
              {[leader.soc?.name, formatPrice(leader.msrp_usd), `점수 ${overallScore(leader) ?? "—"}`]
                .filter(Boolean)
                .join(" · ")}
            </span>
            <Link className="btn btn-primary" href="/phones" style={{ alignSelf: "start", marginTop: 4 }}>
              랭킹 보기
            </Link>
          </div>
        )}
      </section>

      <section style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        <div className="section-head">
          <h2>바로 가기</h2>
          <span className="note">{tiles.length} SERVICES</span>
        </div>
        <div className="tile-grid">
          {tiles.map((tile, index) => (
            <Link
              key={`${tile.href}-${tile.label}`}
              className="panel tile"
              href={tile.href}
              style={{ animationDelay: stagger(index) }}
            >
              <span className="tile-icon">
                <Icon name={tile.icon} size={22} />
              </span>
              <span className="tile-label">
                <strong>{tile.label}</strong>
                <span>{tile.sub}</span>
              </span>
            </Link>
          ))}
        </div>
      </section>

      <section className="home-split">
        <div className="panel panel-pad">
          <div className="section-head">
            <h2>스마트폰 상위 5</h2>
            <Link className="btn btn-ghost" href="/phones">
              전체 →
            </Link>
          </div>
          <div>
            {topPhones.map((phone, index) => {
              const total = overallScore(phone);
              return (
                <Link
                  key={phone.slug}
                  className="rank-row"
                  href={`/phones/${phone.slug}`}
                  style={{ animationDelay: stagger(index, 55) }}
                >
                  <span className="rank-row-num">{index + 1}</span>
                  <span className="rank-row-name">
                    <strong>{phone.name}</strong>
                    <span>{phone.soc?.name ?? phone.brand.name}</span>
                  </span>
                  <span className="rank-row-score">
                    <span className="meter meter-inline">
                      <i style={{ width: percent(total) }} />
                    </span>
                    <b>{total ?? "—"}</b>
                  </span>
                </Link>
              );
            })}
          </div>
        </div>

        <div className="panel panel-pad">
          <div className="section-head">
            <h2>CPU 멀티코어 상위 5</h2>
            <Link className="btn btn-ghost" href="/cpus">
              전체 →
            </Link>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {topCpus.map((cpu) => {
              const multi = cpu.score?.multi?.index ?? null;
              return (
                <div className="bench-row" key={cpu.slug}>
                  <div className="bench-row-head">
                    <span>{cpu.name}</span>
                    <b>{multi === null ? "—" : Math.round(multi)}</b>
                  </div>
                  <div className="meter meter-deep">
                    <i style={{ width: percent(multi) }} />
                  </div>
                </div>
              );
            })}
            <p className="note" style={{ margin: 0 }}>
              Cinebench R23 멀티코어 지수 · TechAPI 채점값 (0–100 정규화)
            </p>
          </div>
        </div>
      </section>
    </div>
  );
}
