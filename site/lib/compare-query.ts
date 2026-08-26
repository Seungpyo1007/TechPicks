type SearchValue = string | string[] | undefined;

export type CompareQuery =
  | { kind: "select"; message?: string; selected: string[] }
  | { kind: "compare"; ids: [string, string] }
  | { kind: "not-found" };

function single(value: SearchValue): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

export function parseCompareQuery(
  query: Record<string, SearchValue>,
  validSlugs: ReadonlySet<string>,
): CompareQuery {
  const type = single(query.type);
  const idsValue = single(query.ids);

  if (type === undefined && idsValue === undefined) {
    return { kind: "select", selected: [] };
  }
  if (type !== "phone") return { kind: "not-found" };

  const ids = (idsValue ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);

  if (ids.some((slug) => !validSlugs.has(slug))) return { kind: "not-found" };
  if (ids.length < 2) {
    return { kind: "select", selected: ids, message: "비교할 스마트폰 두 대를 골라주세요." };
  }
  if (ids.length !== 2) return { kind: "not-found" };
  if (ids[0] === ids[1]) {
    return { kind: "select", selected: [ids[0]], message: "서로 다른 스마트폰을 골라주세요." };
  }

  return { kind: "compare", ids: [ids[0], ids[1]] };
}

export function compareHref(first: string, second: string): string {
  return `/compare?type=phone&ids=${encodeURIComponent(first)},${encodeURIComponent(second)}`;
}
