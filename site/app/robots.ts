import type { MetadataRoute } from "next";
import { canonicalUrl, isPreviewDeployment } from "@/lib/seo";

/** 개인 기능과 자리표시 화면은 색인에서 뺀다. */
const PRIVATE_PATHS = ["/login", "/profile", "/scan", "/viewer"];

export default function robots(): MetadataRoute.Robots {
  return {
    rules: isPreviewDeployment()
      ? { userAgent: "*", disallow: "/" }
      : { userAgent: "*", allow: "/", disallow: PRIVATE_PATHS },
    sitemap: canonicalUrl("/sitemap.xml"),
  };
}
