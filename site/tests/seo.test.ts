import { afterEach, describe, expect, it, vi } from "vitest";
import validPhone from "../../shared/contracts/fixtures/valid-phone.json";
import { parsePhone } from "@/lib/phone";
import { canonicalUrl, isPreviewDeployment, phoneMetadata, productJsonLd } from "@/lib/seo";

const phone = parsePhone(validPhone);

afterEach(() => vi.unstubAllEnvs());

describe("SEO output", () => {
  it("builds production canonicals from NEXT_PUBLIC_SITE_URL", () => {
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", "https://www.techpicks.example/base/");
    expect(canonicalUrl(`/phones/${phone.slug}`)).toBe(
      "https://www.techpicks.example/base/phones/galaxy-s25-ultra",
    );
  });

  it("marks preview metadata noindex", () => {
    vi.stubEnv("VERCEL_ENV", "preview");
    expect(isPreviewDeployment()).toBe(true);
    expect(phoneMetadata(phone).robots).toMatchObject({ index: false, follow: false });
  });

  it("emits Product JSON-LD without inventing availability", () => {
    const jsonLd = productJsonLd(phone);
    expect(jsonLd).toMatchObject({ "@type": "Product", name: "Galaxy S25 Ultra" });
    expect(jsonLd.offers).not.toHaveProperty("availability");
  });
});
