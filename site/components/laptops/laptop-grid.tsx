"use client";

import { useMemo, useState } from "react";
import { stagger } from "@/lib/score";

export type LaptopCardItem = {
  slug: string;
  brand: string;
  name: string;
  verified: boolean;
  cpuName: string;
  gpuName: string;
  memoryLabel: string;
  displayLabel: string;
  priceLabel: string;
  tier: string;
};

/**
 * 정본 노트북 화면의 3열 카드와 `미검증 숨기기` 토글.
 *
 * TechAPI 노트북 레코드는 대부분 `verified: false` 라 이 토글이 실제로 의미를 갖는다.
 */
export function LaptopGrid({ laptops }: { laptops: LaptopCardItem[] }) {
  const [hideUnverified, setHideUnverified] = useState(false);

  const visible = useMemo(
    () => (hideUnverified ? laptops.filter((laptop) => laptop.verified) : laptops),
    [hideUnverified, laptops],
  );

  const verifiedCount = laptops.filter((laptop) => laptop.verified).length;

  return (
    <div className="stack">
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 10 }}>
        <p className="note" style={{ margin: 0 }}>
          TechAPI 노트북 {laptops.length}종 · 검증 완료 {verifiedCount}종
        </p>
        <button
          className="btn btn-secondary"
          type="button"
          aria-pressed={hideUnverified}
          onClick={() => setHideUnverified((value) => !value)}
        >
          {hideUnverified ? "미검증 포함" : "미검증 숨기기"}
        </button>
      </div>

      {visible.length ? (
        <div className="card-grid">
          {visible.map((laptop, index) => (
            <article
              className="panel laptop-card"
              key={laptop.slug}
              style={{ animationDelay: stagger(index, 50) }}
            >
              <div className="laptop-card-head">
                <span className="kicker">{laptop.brand}</span>
                <span className={laptop.verified ? "tag tag-accent" : "tag tag-outline"}>
                  {laptop.verified ? "검증됨" : "미검증"}
                </span>
              </div>
              <h2>{laptop.name}</h2>
              <dl className="laptop-rows">
                <div className="laptop-row">
                  <dt>CPU</dt>
                  <dd>{laptop.cpuName}</dd>
                </div>
                <div className="laptop-row">
                  <dt>GPU</dt>
                  <dd>{laptop.gpuName}</dd>
                </div>
                <div className="laptop-row">
                  <dt>메모리 · 저장</dt>
                  <dd>{laptop.memoryLabel}</dd>
                </div>
                <div className="laptop-row">
                  <dt>디스플레이</dt>
                  <dd>{laptop.displayLabel}</dd>
                </div>
              </dl>
              <div className="laptop-foot">
                <span>{laptop.priceLabel}</span>
                <span className="tag tag-neutral">{laptop.tier}</span>
              </div>
            </article>
          ))}
        </div>
      ) : (
        <div className="empty">
          <strong>검증된 노트북이 아직 없습니다.</strong>
          <span className="note">TechAPI 검증 계층이 채워지면 이 목록에 올라옵니다.</span>
        </div>
      )}
    </div>
  );
}
