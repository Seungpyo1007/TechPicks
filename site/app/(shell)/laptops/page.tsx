import type { Metadata } from "next";
import { LaptopGrid } from "@/components/laptops/laptop-grid";
import { formatPrice } from "@/lib/format";
import { displayLabel, getLaptops, memoryLabel, tierLabel } from "@/lib/laptop";
import { canonicalUrl } from "@/lib/seo";

export const metadata: Metadata = {
  title: "노트북 구성",
  description: "TechAPI 노트북 데이터의 CPU·GPU·메모리·디스플레이 구성을 같은 카드 형식으로 봅니다.",
  alternates: { canonical: canonicalUrl("/laptops") },
};

export default async function LaptopsPage() {
  const laptops = await getLaptops();

  const items = laptops.map((laptop) => ({
    slug: laptop.slug,
    brand: laptop.brand.name,
    name: laptop.name,
    verified: laptop.verified ?? false,
    cpuName: laptop.cpu_name ?? "기록 없음",
    gpuName: laptop.gpu_name ?? "기록 없음",
    memoryLabel: memoryLabel(laptop),
    displayLabel: displayLabel(laptop),
    priceLabel: formatPrice(laptop.msrp_usd),
    tier: tierLabel(laptop),
  }));

  return <LaptopGrid laptops={items} />;
}
