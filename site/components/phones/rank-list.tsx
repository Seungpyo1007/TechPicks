"use client";

import Link from "next/link";
import { useState } from "react";
import type { RankListItem } from "@/lib/phone";
import { stagger } from "@/lib/score";

/** 정본의 `전체 보기` 토글이 접었을 때 보이는 개수. */
export const COLLAPSED_COUNT = 12;

/**
 * 정본 스마트폰 화면 왼쪽의 순위 리스트.
 *
 * 항목은 버튼이 아니라 링크다. 정본은 클라이언트 상태로 선택을 바꿨지만 웹에서는 제품마다
 * 실제 URL 이 있어야 검색에 잡힌다. 접힘/펼침은 CSS 로만 처리해서 링크는 항상 HTML 에 남는다.
 */
export function PhoneRankList({
  items,
  activeSlug,
}: {
  items: RankListItem[];
  activeSlug: string;
}) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="panel master">
      <div className="master-head">
        <span className="kicker">순위</span>
        <button className="btn btn-ghost" type="button" onClick={() => setExpanded((value) => !value)}>
          {expanded ? `상위 ${COLLAPSED_COUNT}개만` : `전체 ${items.length}개`}
        </button>
      </div>
      <div className="master-list" data-expanded={expanded}>
        {items.map((item, index) => (
          <Link
            key={item.slug}
            className="master-item"
            href={`/phones/${item.slug}`}
            aria-current={item.slug === activeSlug ? "page" : undefined}
            style={{ animationDelay: stagger(Math.min(index, 10)) }}
          >
            <span className="master-item-num">{index + 1}</span>
            <span className="master-item-body">
              <strong>{item.name}</strong>
              <span>{item.priceLabel}</span>
            </span>
            <span className="master-item-total">{item.total ?? "—"}</span>
          </Link>
        ))}
      </div>
    </div>
  );
}
