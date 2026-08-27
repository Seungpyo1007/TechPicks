import { renderToStaticMarkup } from "react-dom/server";
import { afterEach, describe, expect, it, vi } from "vitest";
import ComparePage from "@/app/(shell)/compare/page";
import CpuPage from "@/app/(shell)/cpus/[slug]/page";
import CpusPage from "@/app/(shell)/cpus/page";
import HomePage from "@/app/(shell)/page";
import LaptopsPage from "@/app/(shell)/laptops/page";
import PhoneDetailPage, { generateMetadata as detailMetadata } from "@/app/(shell)/phones/[slug]/page";
import PhonesPage from "@/app/(shell)/phones/page";
import sitemap from "@/app/sitemap";

vi.mock("next/navigation", async (importOriginal) => {
  const original = await importOriginal<typeof import("next/navigation")>();
  return { ...original, useRouter: () => ({ push: vi.fn() }), usePathname: () => "/" };
});

/** TechAPI 원격 조회는 테스트에서 끊는다. 카탈로그 폴백만으로 렌더돼야 한다. */
function offline() {
  vi.stubGlobal(
    "fetch",
    vi.fn(async () => {
      throw new Error("offline");
    }),
  );
}

afterEach(() => vi.unstubAllGlobals());

describe("home", () => {
  it("renders the original dashboard sections", async () => {
    const html = renderToStaticMarkup(await HomePage());
    expect(html).toContain("함께하는 기술");
    expect(html).toContain("바로 가기");
    expect(html).toContain("스마트폰 상위 5");
    expect(html).toContain("CPU 멀티코어 상위 5");
    expect(html).toContain("Oppo Find X9 Ultra");
  });
});

describe("phones", () => {
  it("server-renders the ranking beside the leading product", async () => {
    const html = renderToStaticMarkup(await PhonesPage());
    expect(html).toContain("Oppo Find X9 Ultra");
    expect(html).toContain("TECHPICKS SCORE");
    expect(html).toContain("상세 스펙");
  });

  it("server-renders detail essentials and Product JSON-LD before hydration", async () => {
    offline();
    const props = { params: Promise.resolve({ slug: "galaxy-s25-ultra" }) };
    const html = renderToStaticMarkup(await PhoneDetailPage(props));

    expect(html).toContain("Galaxy S25 Ultra");
    expect(html).toContain("application/ld+json");
    expect(html).toContain("techpicks://device/galaxy-s25-ultra");
    // 레이더는 점수를 그림으로만 보여준다. 축 값은 글자로도 남아야 검색에 잡힌다.
    expect(html).toContain("성능");
    expect(html).toContain("배터리");

    const metadata = await detailMetadata(props);
    expect(metadata.alternates?.canonical).toContain("/phones/galaxy-s25-ultra");
  });

  it("uses the 404 boundary for an unknown slug", async () => {
    offline();
    await expect(
      PhoneDetailPage({ params: Promise.resolve({ slug: "unknown-phone" }) }),
    ).rejects.toMatchObject({ digest: expect.stringContaining("404") });
  });
});

describe("cpus", () => {
  it("lists processors with normalised indices, not raw benchmark scores", async () => {
    const html = renderToStaticMarkup(await CpusPage());
    expect(html).toContain("AMD Ryzen 9 9955HX3D");
    expect(html).toContain("멀티 지수");
    expect(html).toContain("Cinebench R23");
  });

  it("renders a processor detail page", async () => {
    const html = renderToStaticMarkup(
      await CpuPage({ params: Promise.resolve({ slug: "ryzen-9-9955hx3d" }) }),
    );
    expect(html).toContain("AMD Ryzen 9 9955HX3D");
    expect(html).toContain("TECHPICKS SCORE");
  });

  it("404s on an unknown processor", async () => {
    await expect(CpuPage({ params: Promise.resolve({ slug: "no-such-cpu" }) })).rejects.toMatchObject({
      digest: expect.stringContaining("404"),
    });
  });
});

describe("laptops", () => {
  it("renders the configuration cards", async () => {
    const html = renderToStaticMarkup(await LaptopsPage());
    expect(html).toContain("메모리 · 저장");
    expect(html).toContain("미검증 숨기기");
  });
});

describe("compare", () => {
  it("asks for a second product when the selection is incomplete", async () => {
    const html = renderToStaticMarkup(
      await ComparePage({ searchParams: Promise.resolve({ type: "phone", ids: "galaxy-s25-ultra" }) }),
    );
    expect(html).toContain("비교할 스마트폰 두 대를 골라주세요.");
  });

  it("renders both products, the score rows and the spec battle", async () => {
    const html = renderToStaticMarkup(
      await ComparePage({
        searchParams: Promise.resolve({ type: "phone", ids: "galaxy-s25-ultra,oppo-find-x9-ultra" }),
      }),
    );
    expect(html).toContain("Galaxy S25 Ultra");
    expect(html).toContain("Oppo Find X9 Ultra");
    expect(html).toContain("TechPicks 점수");
    expect(html).toContain("스펙 대결");
    expect(html).toContain("차이만 보기");
  });

  it("404s on an unknown kind or slug", async () => {
    await expect(
      ComparePage({ searchParams: Promise.resolve({ type: "tablet", ids: "galaxy-s25-ultra" }) }),
    ).rejects.toMatchObject({ digest: expect.stringContaining("404") });
    await expect(
      ComparePage({ searchParams: Promise.resolve({ type: "phone", ids: "nope,galaxy-s25-ultra" }) }),
    ).rejects.toMatchObject({ digest: expect.stringContaining("404") });
  });
});

describe("sitemap", () => {
  it("lists every catalog phone and processor, and no private screen", async () => {
    const entries = await sitemap();
    expect(entries.filter((entry) => entry.url.includes("/phones/"))).toHaveLength(154);
    expect(entries.filter((entry) => entry.url.includes("/cpus/"))).toHaveLength(40);
    expect(entries.some((entry) => entry.url.endsWith("/compare"))).toBe(true);
    expect(entries.some((entry) => /\/(login|profile|scan|viewer)$/.test(entry.url))).toBe(false);
  });
});
