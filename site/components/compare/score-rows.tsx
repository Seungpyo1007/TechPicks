import type { CompareRow } from "@/lib/compare-spec";
import { percent, stagger } from "@/lib/score";

/**
 * 정본 비교 화면의 점수 행.
 *
 * 막대는 각 행에서 가장 큰 값을 100% 로 놓고 그린다. 단위가 제각각인 행(mAh, g, USD)을
 * 한 그림 안에서 견주려면 행 안에서 정규화하는 수밖에 없다.
 */
export function ScoreRows({
  title,
  rows,
  names,
  columns,
}: {
  title: string;
  rows: CompareRow[];
  names: string[];
  columns: string;
}) {
  return (
    <section className="panel compare-section">
      <div className="compare-grid" style={{ gridTemplateColumns: columns, paddingBottom: 14 }}>
        <span className="kicker">{title}</span>
        {names.map((name) => (
          <span className="compare-head-cell" key={name}>
            <i />
            <span>{name}</span>
          </span>
        ))}
      </div>

      {rows.map((row, index) => {
        const numbers = row.cells.map((cell) => Number.parseFloat(cell.text.replace(/[^0-9.]/g, "")));
        const max = Math.max(...numbers.filter((value) => Number.isFinite(value)), 0);

        return (
          <div
            className="compare-grid compare-score-row"
            key={row.label}
            style={{ gridTemplateColumns: columns, animationDelay: stagger(index, 40) }}
          >
            <span style={{ fontSize: 13 }}>{row.label}</span>
            {row.cells.map((cell, cellIndex) => (
              <div
                className={cell.isBest ? "compare-score-cell is-best" : "compare-score-cell"}
                key={`${row.label}-${cellIndex}`}
              >
                <span className="meter">
                  <i
                    style={{
                      width: Number.isFinite(numbers[cellIndex]) && max > 0
                        ? percent(numbers[cellIndex], max)
                        : "0%",
                      animationDelay: stagger(cellIndex, 60),
                    }}
                  />
                </span>
                <b>{cell.text}</b>
              </div>
            ))}
          </div>
        );
      })}
    </section>
  );
}
