import { renderToStaticMarkup } from "react-dom/server";
import { afterEach, describe, expect, it, vi } from "vitest";
import ComparePage, { generateMetadata as compareMetadata } from "@/app/compare/page";
import PhoneDetailPage, { generateMetadata as detailMetadata } from "@/app/phones/[slug]/page";
import PhonesPage from "@/app/phones/page";
import sitemap from "@/app/sitemap";

vi.mock("next/navigation", async (importOriginal) => {
  const original = await importOriginal<typeof import("next/navigation")>();
  return { ...original, useRouter: () => ({ push: vi.fn() }) };
});

afterEach(() => vi.unstubAllGlobals());

describe("public pages", () => {
  it("server-renders the ranking with searchable products", async () => {
    const html = renderToStaticMarkup(await PhonesPage());
    expect(html).toContain("스마트폰 랭킹");
    expect(html).toContain("Oppo Find X9 Ultra");
    expect(html).toContain("phone-search");
  });

  it("server-renders detail essentials and Product JSON-LD before hydration", async () => {
    vi.stubGlobal("fetch", vi.fn(async () => { throw new Error("offline"); }));
    const props = { params: Promise.resolve({ slug: "galaxy-s25-ultra" }) };
    const html = renderToStaticMarkup(await PhoneDetailPage(props));
    expect(html).toContain("Galaxy S25 Ultra");
    expect(html).toContain("Snapdragon 8 Elite");
    expect(html).toContain("application/ld+json");
    expect(html).toContain("techpicks://device/galaxy-s25-ultra");

    const metadata = await detailMetadata(props);
    expect(metadata.alternates?.canonical).toContain("/phones/galaxy-s25-ultra");
    expect(metadata.openGraph).toMatchObject({ type: "website" });
  });

  it("renders the comparison picker when the selection is incomplete", async () => {
    const html = renderToStaticMarkup(
      await ComparePage({ searchParams: Promise.resolve({ type: "phone", ids: "galaxy-s25-ultra" }) }),
    );
    expect(html).toContain("비교할 스마트폰 두 대를 골라주세요.");
    expect(html).toContain("첫 번째 스마트폰");
  });

  it("reproduces a valid comparison and canonical URL", async () => {
    vi.stubGlobal("fetch", vi.fn(async () => { throw new Error("offline"); }));
    const searchParams = Promise.resolve({
      type: "phone",
      ids: "galaxy-s25-ultra,galaxy-s24-ultra",
    });
    const html = renderToStaticMarkup(await ComparePage({ searchParams }));
    expect(html).toContain("Galaxy S25 Ultra");
    expect(html).toContain("Galaxy S24 Ultra");
    expect(html).toContain("비교 항목");

    const metadata = await compareMetadata({ searchParams: Promise.resolve({ type: "phone", ids: "galaxy-s25-ultra,galaxy-s24-ultra" }) });
    expect(metadata.alternates?.canonical).toContain(
      "/compare?type=phone&amp;ids=galaxy-s25-ultra,galaxy-s24-ultra".replace("&amp;", "&"),
    );
  });

  it("uses the 404 boundary for an invalid phone or comparison slug", async () => {
    await expect(PhoneDetailPage({ params: Promise.resolve({ slug: "unknown-phone" }) })).rejects.toMatchObject({ digest: expect.stringContaining("404") });
    await expect(ComparePage({ searchParams: Promise.resolve({ type: "phone", ids: "unknown-phone,galaxy-s25-ultra" }) })).rejects.toMatchObject({ digest: expect.stringContaining("404") });
  });

  it("includes every catalog phone in the sitemap", async () => {
    const entries = await sitemap();
    const detailEntries = entries.filter((entry) => entry.url.includes("/phones/"));
    expect(detailEntries).toHaveLength(154);
    expect(entries.some((entry) => entry.url.endsWith("/compare"))).toBe(true);
  });
});
