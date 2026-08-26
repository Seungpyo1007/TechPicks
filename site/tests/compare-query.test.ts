import { describe, expect, it } from "vitest";
import { compareHref, parseCompareQuery } from "@/lib/compare-query";

const slugs = new Set(["galaxy-s25-ultra", "iphone-16-pro"]);

describe("comparison URL contract", () => {
  it("parses a shareable two-phone comparison", () => {
    expect(parseCompareQuery({ type: "phone", ids: "galaxy-s25-ultra,iphone-16-pro" }, slugs)).toEqual({
      kind: "compare",
      ids: ["galaxy-s25-ultra", "iphone-16-pro"],
    });
    expect(compareHref("galaxy-s25-ultra", "iphone-16-pro")).toBe(
      "/compare?type=phone&ids=galaxy-s25-ultra,iphone-16-pro",
    );
  });

  it("keeps an incomplete selection in the picker", () => {
    expect(parseCompareQuery({ type: "phone", ids: "galaxy-s25-ultra" }, slugs)).toMatchObject({
      kind: "select",
      selected: ["galaxy-s25-ultra"],
    });
  });

  it("prevents duplicate comparisons", () => {
    expect(parseCompareQuery({ type: "phone", ids: "galaxy-s25-ultra,galaxy-s25-ultra" }, slugs)).toMatchObject({
      kind: "select",
      selected: ["galaxy-s25-ultra"],
    });
  });

  it("marks unsupported types and unknown slugs as not found", () => {
    expect(parseCompareQuery({ type: "laptop", ids: "galaxy-s25-ultra,iphone-16-pro" }, slugs)).toEqual({ kind: "not-found" });
    expect(parseCompareQuery({ type: "phone", ids: "unknown,iphone-16-pro" }, slugs)).toEqual({ kind: "not-found" });
  });
});
