import { formatPrice } from "@/lib/format";
import type { Phone } from "@/lib/phone";
import type { Soc } from "@/lib/soc";

/** 정본 상세 화면의 `상세 스펙` 타일. 항목과 순서는 정본 `phoneSpecs` 그대로. */
export type SpecTile = { key: string; value: string };

const NONE = "기록 없음";

export function phoneSpecTiles(phone: Phone, soc: Soc | null): SpecTile[] {
  const display = phone.display;
  const rear = (phone.cameras ?? []).filter((camera) => !camera.type.includes("selfie"));
  const rearLabel = rear.length ? rear.map((camera) => `${camera.mp ?? "?"}MP`).join(" + ") : "정보 없음";
  const storage = phone.storage_options_gb ?? [];

  const cpuIndex = soc?.score?.cpu?.index;
  const systemIndex = soc?.score?.system?.index;

  return [
    { key: "화면", value: `${display?.size_inch ?? "?"}″ ${display?.type ?? ""}`.trim() },
    {
      key: "해상도",
      value: `${display?.resolution ?? "—"}${display?.refresh_hz ? ` · ${display.refresh_hz}Hz` : ""}`,
    },
    { key: "밝기", value: display?.brightness_nits ? `${display.brightness_nits} nits` : NONE },
    { key: "칩셋", value: phone.soc?.name ?? NONE },
    {
      // TechAPI 는 원시 Geekbench 점수를 발행하지 않는다. 정규화 지수를 그대로 보여준다.
      key: "성능 지수",
      value:
        cpuIndex || systemIndex
          ? `CPU ${cpuIndex ? Math.round(cpuIndex) : "—"} · 시스템 ${systemIndex ? Math.round(systemIndex) : "—"}`
          : NONE,
    },
    { key: "메모리", value: phone.ram_gb ? `${phone.ram_gb}GB` : NONE },
    {
      key: "저장",
      value: storage.length
        ? storage.map((gb) => (gb >= 1024 ? `${gb / 1024}TB` : `${gb}GB`)).join(" · ")
        : "—",
    },
    { key: "후면 카메라", value: rearLabel },
    {
      key: "배터리",
      value: phone.battery_mah
        ? `${phone.battery_mah.toLocaleString("en-US")}mAh${phone.charging_wired_w ? ` · 유선 ${phone.charging_wired_w}W` : ""}`
        : NONE,
    },
    { key: "무선 충전", value: phone.charging_wireless_w ? `${phone.charging_wireless_w}W` : "미지원" },
    { key: "무게", value: phone.weight_g ? `${phone.weight_g}g` : NONE },
    { key: "방수", value: phone.ip_rating ?? NONE },
    {
      key: "연결",
      value: [phone.connectivity?.wifi, phone.connectivity?.usb].filter(Boolean).join(" · ") || "—",
    },
    { key: "가격", value: formatPrice(phone.msrp_usd) },
    { key: "출시", value: phone.release_date ?? NONE },
  ];
}

/** 정본 상세 헤더의 치수·무게 라벨. 3D 뷰어 화면도 같은 값을 쓴다. */
export function dimensionLabel(phone: Phone): string {
  const dimensions = phone.dimensions;
  if (!dimensions) return NONE;
  const parts = [dimensions.height_mm, dimensions.width_mm, dimensions.depth_mm].filter(
    (value): value is number => typeof value === "number",
  );
  return parts.length === 3 ? `${parts.join(" × ")} mm` : NONE;
}
