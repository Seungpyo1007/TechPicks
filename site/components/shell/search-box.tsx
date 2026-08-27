"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { Icon } from "@/components/ui/icon";
import { stagger } from "@/lib/score";

export type SearchEntry = { href: string; name: string; meta: string };

/** 정본 헤더의 검색 + 결과 드롭다운. 결과는 tp-res 스태거로 들어온다. */
export function SearchBox({ entries }: { entries: SearchEntry[] }) {
  const [query, setQuery] = useState("");

  const results = useMemo(() => {
    const normalized = query.trim().toLocaleLowerCase("ko-KR");
    if (normalized.length < 1) return [];
    return entries
      .filter((entry) => `${entry.name} ${entry.meta}`.toLocaleLowerCase("ko-KR").includes(normalized))
      .slice(0, 8);
  }, [entries, query]);

  return (
    <div className="search">
      <label className="sr-only" htmlFor="global-search" style={{ position: "absolute", left: -9999 }}>
        제품 · 칩셋 · 브랜드 검색
      </label>
      <span className="search-icon">
        <Icon name="search" size={17} />
      </span>
      <input
        id="global-search"
        className="input"
        type="search"
        value={query}
        onChange={(event) => setQuery(event.target.value)}
        placeholder="제품 · 칩셋 · 브랜드 검색"
        autoComplete="off"
      />
      {results.length > 0 && (
        <div className="search-results elev-lg" role="listbox" aria-label="검색 결과">
          {results.map((result, index) => (
            <Link
              key={result.href}
              className="search-result"
              href={result.href}
              style={{ animationDelay: stagger(index, 35) }}
              onClick={() => setQuery("")}
            >
              <strong>{result.name}</strong>
              <span>{result.meta}</span>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
