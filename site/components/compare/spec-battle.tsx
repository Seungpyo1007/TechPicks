"use client";

import { useMemo, useState } from "react";
import { type CompareGroup, onlyDifferences } from "@/lib/compare-spec";
import { stagger } from "@/lib/score";

/** 정본의 `스펙 대결` 표. `차이만 보기` 는 값이 같은 행을 걸러낸다. */
export function SpecBattle({
  groups,
  names,
  columns,
  note,
}: {
  groups: CompareGroup[];
  names: string[];
  columns: string;
  note: string;
}) {
  const [diffOnly, setDiffOnly] = useState(false);
  const visible = useMemo(() => (diffOnly ? onlyDifferences(groups) : groups), [diffOnly, groups]);

  let rowIndex = 0;

  return (
    <section className="panel compare-section">
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: 12,
          flexWrap: "wrap",
          paddingBottom: 12,
        }}
      >
        <span className="kicker">스펙 대결</span>
        <button
          className="btn btn-ghost"
          type="button"
          aria-pressed={diffOnly}
          onClick={() => setDiffOnly((value) => !value)}
        >
          {diffOnly ? "전체 보기" : "차이만 보기"}
        </button>
      </div>

      <div className="compare-grid compare-spec-head" style={{ gridTemplateColumns: columns }}>
        <span className="kicker">항목</span>
        {names.map((name) => (
          <span className="compare-head-cell" key={name}>
            <i />
            <span>{name}</span>
          </span>
        ))}
      </div>

      {visible.length === 0 ? (
        <p className="note" style={{ paddingTop: 18 }}>
          두 제품의 기록된 스펙이 모두 같습니다.
        </p>
      ) : (
        visible.map((group) => (
          <div key={group.title}>
            <div className="compare-group-title">{group.title}</div>
            {group.rows.map((row) => {
              rowIndex += 1;
              return (
                <div
                  className="compare-grid compare-spec-row"
                  key={`${group.title}-${row.label}`}
                  style={{ gridTemplateColumns: columns, animationDelay: stagger(rowIndex, 18) }}
                >
                  <span>{row.label}</span>
                  {row.cells.map((cell, index) => (
                    <span
                      className={cell.isBest ? "compare-spec-cell is-best" : "compare-spec-cell"}
                      key={`${row.label}-${index}`}
                    >
                      {cell.text}
                    </span>
                  ))}
                </div>
              );
            })}
          </div>
        ))
      )}

      <p className="note" style={{ marginTop: 18 }}>
        {note}
      </p>
    </section>
  );
}
