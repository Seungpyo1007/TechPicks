import type { MetadataRoute } from "next";
import { getCatalogCpus, getCatalogPhones } from "@/lib/catalog";
import { canonicalUrl } from "@/lib/seo";

/** 공개 화면만 싣는다. /login /profile /scan /viewer 는 색인 대상이 아니다. */
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [phones, cpus] = await Promise.all([getCatalogPhones(), getCatalogCpus()]);

  return [
    { url: canonicalUrl("/"), changeFrequency: "daily", priority: 1 },
    { url: canonicalUrl("/phones"), changeFrequency: "daily", priority: 1 },
    { url: canonicalUrl("/cpus"), changeFrequency: "weekly", priority: 0.8 },
    { url: canonicalUrl("/laptops"), changeFrequency: "weekly", priority: 0.6 },
    { url: canonicalUrl("/compare"), changeFrequency: "weekly", priority: 0.7 },
    ...phones.map((phone) => ({
      url: canonicalUrl(`/phones/${phone.slug}`),
      lastModified: phone.release_date ? new Date(`${phone.release_date}T00:00:00Z`) : undefined,
      changeFrequency: "weekly" as const,
      priority: 0.8,
    })),
    ...cpus.map((cpu) => ({
      url: canonicalUrl(`/cpus/${cpu.slug}`),
      lastModified: cpu.release_date ? new Date(`${cpu.release_date}T00:00:00Z`) : undefined,
      changeFrequency: "weekly" as const,
      priority: 0.6,
    })),
  ];
}
