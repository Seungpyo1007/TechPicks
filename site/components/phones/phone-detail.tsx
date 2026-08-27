import Link from "next/link";
import { ScoreRadar } from "@/components/phones/score-radar";
import { compareHref } from "@/lib/compare-query";
import type { Phone } from "@/lib/phone";
import { phoneSpecTiles } from "@/lib/phone-spec";
import { axisValues, overallScore, percent } from "@/lib/score";
import type { Soc } from "@/lib/soc";

/** 정본 상세 패널. 제품 사진 대신 레이더 + 축 막대 + 스펙 타일을 쓴다. */
export function PhoneDetail({
  phone,
  soc,
  compareWith,
}: {
  phone: Phone;
  soc: Soc | null;
  compareWith: string | null;
}) {
  const axes = axisValues(phone);
  const total = overallScore(phone);
  const specs = phoneSpecTiles(phone, soc);
  const sourceUrl = phone.source_urls?.[0] ?? "https://github.com/GetTechAPI/TechAPI";

  return (
    <div className="detail-column">
      <article className="panel detail-card">
        <div className="detail-head">
          <div className="detail-headings">
            <span className="kicker">{phone.brand.name}</span>
            <h2>{phone.name}</h2>
            <div className="detail-tags">
              {phone.soc?.name && <span className="tag tag-accent">{phone.soc.name}</span>}
              <span className="tag tag-neutral">
                {[phone.os, phone.os_version].filter(Boolean).join(" ") || "OS 기록 없음"}
              </span>
              <span className={phone.verified ? "tag tag-accent" : "tag tag-outline"}>
                {phone.verified ? "검증됨" : "미검증"}
              </span>
            </div>
          </div>
          <div className="detail-score">
            <span className="detail-score-value">{total ?? "—"}</span>
            <span className="note">TECHPICKS SCORE</span>
            {compareWith && compareWith !== phone.slug && (
              <Link
                className="btn btn-secondary"
                href={compareHref("phone", [compareWith, phone.slug])}
                style={{ marginTop: 6 }}
              >
                비교에 추가
              </Link>
            )}
            {!compareWith && (
              <Link
                className="btn btn-secondary"
                href={compareHref("phone", [phone.slug])}
                style={{ marginTop: 6 }}
              >
                비교에 추가
              </Link>
            )}
          </div>
        </div>

        <div className="detail-body">
          <ScoreRadar axes={axes} label={`${phone.name} 점수 레이더`} />
          <div className="axis-bars">
            {axes.map((axis) => (
              <div className="axis-bar" key={axis.key}>
                <span>{axis.label}</span>
                <span className="meter">
                  <i style={{ width: percent(axis.value) }} />
                </span>
                <b>{axis.value}</b>
              </div>
            ))}
            <p className="note" style={{ marginTop: 4 }}>
              점수는 TechAPI 채점 알고리즘이 산출한 0–100 정규화 값입니다. 성능은 Geekbench,
              시스템은 AnTuTu 기록에서 나옵니다.
            </p>
          </div>
        </div>
      </article>

      <section className="panel detail-card">
        <h3 style={{ margin: 0, fontSize: 15, letterSpacing: ".04em" }}>상세 스펙</h3>
        <dl className="spec-grid">
          {specs.map((spec) => (
            <div className="spec-tile" key={spec.key}>
              <dt>{spec.key}</dt>
              <dd>{spec.value}</dd>
            </div>
          ))}
        </dl>
        <p className="note" style={{ margin: 0 }}>
          {/* 앱과 웹이 같은 리소스를 가리킨다. 매핑은 docs/HANDOFF.md 의 URL 표. */}
          <a href={`techpicks://device/${phone.slug}`}>앱에서 열기</a> · 출처:{" "}
          <a href={sourceUrl} target="_blank" rel="noreferrer">
            {new URL(sourceUrl).hostname}
          </a>
        </p>
      </section>
    </div>
  );
}
