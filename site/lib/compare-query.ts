import { isValidSlug } from "@/lib/slug";

/**
 * `/compare?type=phone|cpu|laptop&ids=a,b[,c]`
 *
 * 정본은 종류 탭과 최대 3종 비교를 갖고 있다. 기존 계약(`/compare?type=phone&ids=a,b`)은
 * 그대로 유효하고, 종류와 세 번째 슬롯이 더해졌다.
 */
type SearchValue = string | string[] | undefined;

export const COMPARE_KINDS = ["phone", "cpu", "laptop"] as const;
export type CompareKind = (typeof COMPARE_KINDS)[number];

export const COMPARE_KIND_LABELS: Record<CompareKind, string> = {
  phone: "스마트폰",
  cpu: "CPU",
  laptop: "노트북",
};

export const MAX_COMPARE_ITEMS = 3;

export type CompareQuery =
  | { kind: "select"; type: CompareKind; selected: string[]; message?: string }
  | { kind: "compare"; type: CompareKind; ids: string[] }
  | { kind: "not-found" };

function single(value: SearchValue): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

function isCompareKind(value: string | undefined): value is CompareKind {
  return value !== undefined && (COMPARE_KINDS as readonly string[]).includes(value);
}

export function parseCompareQuery(
  query: Record<string, SearchValue>,
  validSlugs: ReadonlySet<string>,
): CompareQuery {
  const typeValue = single(query.type);
  const idsValue = single(query.ids);

  if (typeValue === undefined && idsValue === undefined) {
    return { kind: "select", type: "phone", selected: [] };
  }
  if (typeValue !== undefined && !isCompareKind(typeValue)) return { kind: "not-found" };

  const type: CompareKind = isCompareKind(typeValue) ? typeValue : "phone";
  const ids = (idsValue ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);

  if (ids.some((slug) => !isValidSlug(slug) || !validSlugs.has(slug))) return { kind: "not-found" };
  if (ids.length > MAX_COMPARE_ITEMS) return { kind: "not-found" };

  if (new Set(ids).size !== ids.length) {
    return {
      kind: "select",
      type,
      selected: [...new Set(ids)],
      message: "서로 다른 제품을 골라주세요.",
    };
  }
  if (ids.length < 2) {
    return {
      kind: "select",
      type,
      selected: ids,
      message: `비교할 ${COMPARE_KIND_LABELS[type]} 두 대를 골라주세요.`,
    };
  }

  return { kind: "compare", type, ids };
}

export function compareHref(type: CompareKind, ids: string[]): string {
  const value = ids.filter(Boolean).map(encodeURIComponent).join(",");
  return value ? `/compare?type=${type}&ids=${value}` : `/compare?type=${type}`;
}
