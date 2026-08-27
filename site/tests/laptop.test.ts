import { describe, expect, it } from "vitest";
import { displayLabel, getLaptops, memoryLabel, tierLabel } from "@/lib/laptop";

describe("laptop snapshot", () => {
  it("parses the committed TechAPI snapshot", async () => {
    const laptops = await getLaptops();
    expect(laptops.length).toBeGreaterThan(0);
    expect(laptops.every((laptop) => laptop.slug && laptop.name && laptop.brand.name)).toBe(true);
  });

  it("labels memory and storage the way the original card does", async () => {
    const laptops = await getLaptops();
    const withStorage = laptops.find((laptop) => laptop.storage_gb === 1024);
    expect(withStorage && memoryLabel(withStorage)).toContain("1TB");
  });

  it("falls back instead of inventing a display spec", async () => {
    expect(displayLabel({ slug: "x", name: "x", brand: { name: "x" }, display: null } as never)).toBe(
      "기록 없음",
    );
  });

  it("tiers by price and says so when the price is missing", async () => {
    expect(tierLabel({ msrp_usd: 3494 } as never)).toBe("하이엔드");
    expect(tierLabel({ msrp_usd: 1500 } as never)).toBe("퍼포먼스");
    expect(tierLabel({ msrp_usd: null } as never)).toBe("가격 미기재");
  });
});
