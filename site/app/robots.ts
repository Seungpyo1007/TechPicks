import type { MetadataRoute } from "next";
import { canonicalUrl, isPreviewDeployment } from "@/lib/seo";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: isPreviewDeployment()
      ? { userAgent: "*", disallow: "/" }
      : { userAgent: "*", allow: "/" },
    sitemap: canonicalUrl("/sitemap.xml"),
  };
}
