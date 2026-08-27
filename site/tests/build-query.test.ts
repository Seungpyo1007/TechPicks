import { describe, expect, it } from "vitest";
import { buildHref, parseBuildQuery } from "@/lib/build-query";

const cpus = new Set(["ryzen-7-9800x3d", "core-i9-14900k"]);
const gpus = new Set(["geforce-rtx-5090", "geforce-rtx-4070"]);

describe("build query", () => {
  it("defaults to gaming at a mid budget", () => {
    expect(parseBuildQuery({}, cpus, gpus)).toEqual({
      kind: "build",
      use: "gaming",
      budgetUsd: 1500,
      cpu: null,
      gpu: null,
    });
  });

  it("carries a full estimate so the link can be shared", () => {
    const result = parseBuildQuery(
      { use: "creator", budget: "2200", cpu: "ryzen-7-9800x3d", gpu: "geforce-rtx-5090" },
      cpus,
      gpus,
    );
    expect(result).toMatchObject({ use: "creator", budgetUsd: 2200, cpu: "ryzen-7-9800x3d" });
  });

  it("rejects an unknown use case", () => {
    expect(parseBuildQuery({ use: "mining" }, cpus, gpus).kind).toBe("not-found");
  });

  it("rejects a budget outside the usable range or not a number", () => {
    expect(parseBuildQuery({ budget: "10" }, cpus, gpus).kind).toBe("not-found");
    expect(parseBuildQuery({ budget: "999999" }, cpus, gpus).kind).toBe("not-found");
    expect(parseBuildQuery({ budget: "abc" }, cpus, gpus).kind).toBe("not-found");
  });

  it("rejects parts that are not in the snapshot", () => {
    expect(parseBuildQuery({ cpu: "no-such-cpu" }, cpus, gpus).kind).toBe("not-found");
    expect(parseBuildQuery({ gpu: "no-such-gpu" }, cpus, gpus).kind).toBe("not-found");
  });

  it("builds hrefs the controls navigate to", () => {
    expect(buildHref({ use: "ai", budgetUsd: 3000 })).toBe("/build?use=ai&budget=3000");
    expect(buildHref({ use: "gaming", budgetUsd: 900, cpu: "a", gpu: "b" })).toBe(
      "/build?use=gaming&budget=900&cpu=a&gpu=b",
    );
  });
});
