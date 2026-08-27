"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { compareHref, type CompareKind, MAX_COMPARE_ITEMS } from "@/lib/compare-query";

export type CompareOption = { slug: string; name: string };

/**
 * 정본 비교 화면의 셀렉트 슬롯들.
 *
 * 선택 상태는 URL 에 둔다. 그래야 비교 결과 링크를 그대로 공유할 수 있고,
 * 서버가 표를 렌더할 수 있다. 세 번째 슬롯만 화면 상태로 열고 닫는다.
 */
export function CompareSlots({
  kind,
  options,
  selected,
  figures,
}: {
  kind: CompareKind;
  options: CompareOption[];
  selected: string[];
  figures: React.ReactNode[];
}) {
  const router = useRouter();
  const [showThird, setShowThird] = useState(selected.length >= MAX_COMPARE_ITEMS);

  const slotCount = Math.max(2, showThird ? MAX_COMPARE_ITEMS : Math.min(selected.length || 2, 2));
  const slots = Array.from({ length: slotCount }, (_, index) => index);

  function change(slotIndex: number, next: string) {
    const ids = [...selected];
    if (next) ids[slotIndex] = next;
    else ids.splice(slotIndex, 1);
    router.push(compareHref(kind, ids.filter(Boolean).slice(0, MAX_COMPARE_ITEMS)));
  }

  // VS 는 두 개를 비교할 때만. 세 개면 열 사이에 끼울 자리가 없다.
  const showVersus = slotCount === 2;
  const columns = showVersus ? "1fr 54px 1fr" : `repeat(${slotCount}, 1fr)`;

  return (
    <>
      {!showThird && (
        <button className="btn btn-ghost" type="button" onClick={() => setShowThird(true)}>
          세 번째 추가
        </button>
      )}
      <div className="compare-panels" style={{ gridTemplateColumns: columns }}>
        {slots.map((slotIndex) => (
          <div
            className="compare-panel"
            key={slotIndex}
            style={{
              gridColumn: showVersus ? (slotIndex === 0 ? 1 : 3) : slotIndex + 1,
              gridRow: 1,
              animationDelay: `${slotIndex * 60}ms`,
            }}
          >
            <label style={{ width: "100%" }}>
              <span style={{ position: "absolute", left: -9999 }}>{slotIndex + 1}번째 비교 대상</span>
              <select
                className="input"
                value={selected[slotIndex] ?? ""}
                onChange={(event) => change(slotIndex, event.target.value)}
              >
                <option value="">제품 선택</option>
                {options.map((option) => (
                  <option key={option.slug} value={option.slug}>
                    {option.name}
                  </option>
                ))}
              </select>
            </label>
            {figures[slotIndex]}
          </div>
        ))}
        {showVersus && (
          <div className="compare-vs" style={{ gridColumn: 2, gridRow: 1 }}>
            VS
          </div>
        )}
      </div>
    </>
  );
}
