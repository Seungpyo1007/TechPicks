import { describe, expect, it } from "vitest";
import { onlyDifferences, specGroups, summaryRows } from "@/lib/compare-spec";
import { getCatalogPhones, getCatalogSocs } from "@/lib/catalog";
import type { Phone } from "@/lib/phone";

async function pair(): Promise<{ phones: Phone[]; contexts: Array<{ soc: null }> }> {
  const phones = await getCatalogPhones();
  const chosen = [phones[0], phones[1]];
  return { phones: chosen, contexts: chosen.map(() => ({ soc: null })) };
}

function findRow(rows: Awaited<ReturnType<typeof summaryRows>>, label: string) {
  const row = rows.find((candidate) => candidate.label === label);
  if (!row) throw new Error(`row not found: ${label}`);
  return row;
}

describe("comparison rows", () => {
  it("marks exactly one winner for a higher-is-better row", async () => {
    const { phones, contexts } = await pair();
    const row = findRow(summaryRows(phones, contexts), "종합 점수");
    expect(row.cells).toHaveLength(2);
    expect(row.cells.filter((cell) => cell.isBest)).toHaveLength(1);
  });

  it("treats weight as lower-is-better", async () => {
    const phones = await getCatalogPhones();
    const light = phones.find((phone) => phone.weight_g === 162);
    const heavy = phones.find((phone) => (phone.weight_g ?? 0) > 220);
    if (!light || !heavy) return; // 카탈로그에 해당 무게가 없으면 검증할 게 없다.

    const row = findRow(summaryRows([light, heavy], [{ soc: null }, { soc: null }]), "무게");
    expect(row.cells[0].isBest).toBe(true);
    expect(row.cells[1].isBest).toBe(false);
  });

  it("declares no winner when both values are identical", async () => {
    const phones = await getCatalogPhones();
    const twin = phones[0];
    const row = findRow(summaryRows([twin, twin], [{ soc: null }, { soc: null }]), "배터리");
    expect(row.cells.some((cell) => cell.isBest)).toBe(false);
  });

  it("keeps the six spec groups the original design shows", async () => {
    const { phones, contexts } = await pair();
    expect(specGroups(phones, contexts).map((group) => group.title)).toEqual([
      "성능",
      "화면",
      "카메라",
      "배터리 · 충전",
      "본체 · 소프트웨어",
      "가격 · 출시",
    ]);
  });

  it("drops identical rows when only differences are requested", async () => {
    const phones = await getCatalogPhones();
    const twin = phones[0];
    const groups = specGroups([twin, twin], [{ soc: null }, { soc: null }]);
    expect(onlyDifferences(groups)).toEqual([]);
  });

  it("reads the normalised soc index instead of a raw benchmark score", async () => {
    const [phones, socs] = await Promise.all([getCatalogPhones(), getCatalogSocs()]);
    const phone = phones.find((candidate) => socs.some((soc) => soc.slug === candidate.soc?.slug));
    if (!phone) return;
    const soc = socs.find((candidate) => candidate.slug === phone.soc?.slug) ?? null;

    const row = findRow(summaryRows([phone, phone], [{ soc }, { soc }]), "Geekbench CPU 지수");
    expect(row.cells[0].text).toMatch(/^(\d+ \/ 100|기록 없음)$/);
  });
});
