export function formatPrice(value: number | null | undefined): string {
  return value === null || value === undefined
    ? "가격 정보 없음"
    : new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(value);
}

export function formatDate(value: string | null | undefined): string {
  if (!value) return "출시일 정보 없음";
  return new Intl.DateTimeFormat("ko-KR", { dateStyle: "medium", timeZone: "UTC" }).format(
    new Date(`${value}T00:00:00Z`),
  );
}

export function formatOptional(value: unknown, suffix = ""): string {
  return value === null || value === undefined || value === "" ? "—" : `${String(value)}${suffix}`;
}
