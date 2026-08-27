import { describe, expect, it } from "vitest";
import { compareHref, parseCompareQuery } from "@/lib/compare-query";

const slugs = new Set(["galaxy-s25-ultra", "galaxy-s24-ultra", "iphone-17-pro"]);

describe("compare query", () => {
  it("starts on the phone tab with nothing selected", () => {
    expect(parseCompareQuery({}, slugs)).toEqual({ kind: "select", type: "phone", selected: [] });
  });

  it("asks for a second product when only one is chosen", () => {
    const result = parseCompareQuery({ type: "phone", ids: "galaxy-s25-ultra" }, slugs);
    expect(result).toMatchObject({ kind: "select", selected: ["galaxy-s25-ultra"] });
  });

  it("keeps the two-product contract that the app deep link uses", () => {
    expect(parseCompareQuery({ type: "phone", ids: "galaxy-s25-ultra,galaxy-s24-ultra" }, slugs)).toEqual({
      kind: "compare",
      type: "phone",
      ids: ["galaxy-s25-ultra", "galaxy-s24-ultra"],
    });
  });

  it("accepts a third product", () => {
    const result = parseCompareQuery(
      { type: "phone", ids: "galaxy-s25-ultra,galaxy-s24-ultra,iphone-17-pro" },
      slugs,
    );
    expect(result).toMatchObject({ kind: "compare", ids: expect.arrayContaining(["iphone-17-pro"]) });
  });

  it("rejects a fourth product", () => {
    const result = parseCompareQuery(
      { type: "phone", ids: "galaxy-s25-ultra,galaxy-s24-ultra,iphone-17-pro,galaxy-s25-ultra" },
      slugs,
    );
    expect(result.kind).toBe("not-found");
  });

  it("carries the cpu and laptop tabs", () => {
    expect(parseCompareQuery({ type: "cpu" }, slugs)).toMatchObject({ kind: "select", type: "cpu" });
    expect(parseCompareQuery({ type: "laptop" }, slugs)).toMatchObject({ kind: "select", type: "laptop" });
  });

  it("rejects an unknown kind and an unknown slug", () => {
    expect(parseCompareQuery({ type: "tablet", ids: "galaxy-s25-ultra" }, slugs).kind).toBe("not-found");
    expect(parseCompareQuery({ type: "phone", ids: "nope,galaxy-s24-ultra" }, slugs).kind).toBe("not-found");
  });

  it("asks again when the same product is picked twice", () => {
    const result = parseCompareQuery({ type: "phone", ids: "galaxy-s25-ultra,galaxy-s25-ultra" }, slugs);
    expect(result).toMatchObject({ kind: "select", message: "서로 다른 제품을 골라주세요." });
  });

  it("builds hrefs the picker can navigate to", () => {
    expect(compareHref("phone", ["a", "b"])).toBe("/compare?type=phone&ids=a,b");
    expect(compareHref("cpu", [])).toBe("/compare?type=cpu");
  });
});
