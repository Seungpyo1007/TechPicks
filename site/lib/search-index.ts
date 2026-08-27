import type { SearchEntry } from "@/components/shell/search-box";
import { getCatalogCpus, getCatalogPhones, rankPhones } from "@/lib/catalog";
import { getLaptops } from "@/lib/laptop";

/** 헤더 검색이 훑는 목록. 정본과 같이 제품·칩셋·브랜드를 한 상자에서 찾는다. */
export async function buildSearchIndex(): Promise<SearchEntry[]> {
  const [phones, cpus, laptops] = await Promise.all([
    getCatalogPhones(),
    getCatalogCpus(),
    getLaptops(),
  ]);

  const phoneEntries = rankPhones(phones).map((phone) => ({
    href: `/phones/${phone.slug}`,
    name: phone.name,
    meta: [phone.brand.name, phone.soc?.name].filter(Boolean).join(" · "),
  }));

  const cpuEntries = cpus.map((cpu) => ({
    href: `/cpus/${cpu.slug}`,
    name: cpu.name,
    meta: [cpu.manufacturer.name, cpu.architecture].filter(Boolean).join(" · "),
  }));

  const laptopEntries = laptops.map((laptop) => ({
    href: "/laptops",
    name: laptop.name,
    meta: [laptop.brand.name, laptop.cpu_name].filter(Boolean).join(" · "),
  }));

  return [...phoneEntries, ...cpuEntries, ...laptopEntries];
}
