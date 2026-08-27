"use client";

import Link from "next/link";
import { useMemo, useState } from "react";

export type ScanCandidate = { slug: string; name: string; meta: string };

/**
 * 정본 OCR 스캔 화면.
 *
 * 프레임과 스캔 라인은 정본 그대로이고, 실제 동작은 앱과 같은 **수동 모델명 검색**이다.
 * 카메라 OCR 은 앱에서도 아직 켜져 있지 않아 정본도 `지원 예정` 으로 표시한다.
 */
export function ScanPanel({ candidates }: { candidates: ScanCandidate[] }) {
  const [query, setQuery] = useState("");
  const [submitted, setSubmitted] = useState("");

  const match = useMemo(() => {
    const normalized = submitted.trim().toLocaleLowerCase("ko-KR");
    if (!normalized) return null;
    return (
      candidates.find((candidate) => candidate.name.toLocaleLowerCase("ko-KR") === normalized) ??
      candidates.find((candidate) =>
        `${candidate.name} ${candidate.meta}`.toLocaleLowerCase("ko-KR").includes(normalized),
      ) ??
      null
    );
  }, [candidates, submitted]);

  return (
    <div className="tool-grid">
      <div className="panel panel-pad">
        <div className="scan-frame">
          <div className="scan-frame-inner" />
          <div className="scan-line" />
          <p className="scan-hint">모델명을 프레임 안에 맞추세요</p>
        </div>

        <form
          style={{ display: "flex", flexDirection: "column", gap: 10 }}
          onSubmit={(event) => {
            event.preventDefault();
            setSubmitted(query);
          }}
        >
          <label className="login-field">
            <span>모델명 직접 입력</span>
            <input
              className="input"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="예: Galaxy S25 Ultra"
              autoComplete="off"
            />
          </label>
          <div style={{ display: "flex", gap: 8 }}>
            <button className="btn btn-primary" type="submit" style={{ flex: 1, height: 42 }}>
              인식하기
            </button>
            <button
              className="btn btn-secondary"
              type="button"
              style={{ height: 42 }}
              onClick={() => {
                setQuery("");
                setSubmitted("");
              }}
            >
              초기화
            </button>
          </div>
        </form>
      </div>

      <div className="panel panel-pad">
        <div className="section-head">
          <h2>인식 결과</h2>
          <span className="tag tag-outline">카메라 OCR 지원 예정</span>
        </div>
        <p style={{ margin: 0, fontSize: 13, lineHeight: 1.6 }}>
          {submitted
            ? match
              ? "카탈로그에서 일치하는 제품을 찾았습니다."
              : "일치하는 제품을 찾지 못했습니다. 모델명을 다르게 입력해 보세요."
            : "지금은 카메라 대신 모델명을 직접 입력해 카탈로그에서 찾습니다. 앱도 같은 방식으로 동작합니다."}
        </p>

        {match && (
          <div className="scan-result">
            <strong>{match.name}</strong>
            <span className="note">{match.meta}</span>
            <Link className="btn btn-primary" href={`/phones/${match.slug}`} style={{ alignSelf: "start" }}>
              상세 보기
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}
