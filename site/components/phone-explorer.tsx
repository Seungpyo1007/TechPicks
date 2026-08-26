"use client";

import { useMemo, useState } from "react";
import { PhoneCard } from "@/components/phone-card";
import type { PhoneListItem } from "@/lib/phone";

export function PhoneExplorer({ phones }: { phones: PhoneListItem[] }) {
  const [query, setQuery] = useState("");
  const visiblePhones = useMemo(() => {
    const normalized = query.trim().toLocaleLowerCase("ko-KR");
    if (!normalized) return phones;
    return phones.filter((phone) =>
      `${phone.name} ${phone.brandName} ${phone.socName ?? ""}`
        .toLocaleLowerCase("ko-KR")
        .includes(normalized),
    );
  }, [phones, query]);

  return (
    <section aria-label="스마트폰 목록">
      <div className="search-wrap">
        <label htmlFor="phone-search">제품, 브랜드, 칩셋 검색</label>
        <input
          id="phone-search"
          type="search"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="예: Galaxy, Apple, Snapdragon"
        />
        <span>{visiblePhones.length}대</span>
      </div>
      {visiblePhones.length ? (
        <div className="phone-grid">
          {visiblePhones.map((phone) => (
            <PhoneCard key={phone.slug} phone={phone} rank={phones.indexOf(phone) + 1} />
          ))}
        </div>
      ) : (
        <div className="empty-state">
          <strong>검색 결과가 없습니다.</strong>
          <span>제품명이나 브랜드를 다르게 입력해 보세요.</span>
        </div>
      )}
    </section>
  );
}
