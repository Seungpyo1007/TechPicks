import type { Metadata } from "next";
import type { Phone } from "@/lib/phone";

export function siteOrigin(): URL {
  const configured = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";
  return new URL(configured.endsWith("/") ? configured : `${configured}/`);
}

export function canonicalUrl(pathname: string): string {
  return new URL(pathname.replace(/^\//, ""), siteOrigin()).toString();
}

export function isPreviewDeployment(): boolean {
  return process.env.VERCEL_ENV === "preview";
}

export function phoneDescription(phone: Phone): string {
  const score = phone.score?.overall;
  const keyFacts = [
    score === undefined ? null : `TechPicks 점수 ${score.toFixed(1)}`,
    phone.soc?.name ?? null,
    phone.battery_mah ? `${phone.battery_mah.toLocaleString("ko-KR")}mAh` : null,
  ].filter(Boolean);
  return `${phone.name}의 핵심 사양과 점수를 확인하세요${keyFacts.length ? ` — ${keyFacts.join(", ")}` : ""}.`;
}

export function phoneMetadata(phone: Phone): Metadata {
  const title = `${phone.name} 사양·점수`;
  const description = phoneDescription(phone);
  const canonical = canonicalUrl(`/phones/${phone.slug}`);
  const images = phone.image_url ? [{ url: phone.image_url, alt: phone.name }] : undefined;

  return {
    title,
    description,
    alternates: { canonical },
    robots: isPreviewDeployment() ? { index: false, follow: false } : undefined,
    openGraph: {
      type: "website",
      title,
      description,
      url: canonical,
      images,
    },
  };
}

export function productJsonLd(phone: Phone): Record<string, unknown> {
  return {
    "@context": "https://schema.org",
    "@type": "Product",
    name: phone.name,
    image: phone.image_url ?? undefined,
    brand: { "@type": "Brand", name: phone.brand.name },
    description: phoneDescription(phone),
    sku: phone.slug,
    offers:
      phone.msrp_usd === null || phone.msrp_usd === undefined
        ? undefined
        : {
            "@type": "Offer",
            priceCurrency: "USD",
            price: phone.msrp_usd,
            url: canonicalUrl(`/phones/${phone.slug}`),
          },
  };
}
