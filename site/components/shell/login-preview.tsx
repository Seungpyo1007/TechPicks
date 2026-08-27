"use client";

import { useEffect, useState } from "react";
import { stagger } from "@/lib/score";

export type PreviewRow = { rank: string; name: string; percent: string; value: string };
export type PreviewCategory = { label: string; rows: PreviewRow[] };

/** 정본 로그인 화면 왼쪽. 3.6초마다 스마트폰 → CPU → 노트북 순으로 돈다. */
const ROTATE_MS = 3600;

export function LoginPreview({ categories }: { categories: PreviewCategory[] }) {
  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (categories.length < 2) return;
    const timer = setInterval(() => setIndex((value) => (value + 1) % categories.length), ROTATE_MS);
    return () => clearInterval(timer);
  }, [categories.length]);

  const active = categories[index];
  if (!active) return null;

  return (
    <div className="login-preview">
      <span className="kicker">{active.label}</span>
      {active.rows.map((row, rowIndex) => (
        <div
          className="login-row"
          key={`${active.label}-${row.name}`}
          style={{ animationDelay: stagger(rowIndex, 70) }}
        >
          <span className="login-row-rank" style={{ animationDelay: stagger(rowIndex, 70) }}>
            {row.rank}
          </span>
          <span className="login-row-body">
            <span>{row.name}</span>
            <span className="meter">
              <i style={{ width: row.percent, animationDelay: stagger(rowIndex, 70) }} />
            </span>
          </span>
          <span className="login-row-value">{row.value}</span>
        </div>
      ))}

      <div className="login-dots">
        {categories.map((category, dotIndex) => (
          <i key={category.label} data-active={dotIndex === index} />
        ))}
      </div>
    </div>
  );
}
