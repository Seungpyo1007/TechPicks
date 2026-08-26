import type { MetadataRoute } from "next";
import { getCatalogPhones } from "@/lib/catalog";
import { canonicalUrl } from "@/lib/seo";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const phones = await getCatalogPhones();
  return [
    { url: canonicalUrl("/phones"), changeFrequency: "daily", priority: 1 },
    { url: canonicalUrl("/compare"), changeFrequency: "weekly", priority: 0.7 },
    ...phones.map((phone) => ({
      url: canonicalUrl(`/phones/${phone.slug}`),
      lastModified: phone.release_date ? new Date(`${phone.release_date}T00:00:00Z`) : undefined,
      changeFrequency: "weekly" as const,
      priority: 0.8,
    })),
  ];
}
