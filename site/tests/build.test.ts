import { describe, expect, it } from "vitest";
import {
  bottleneckMessage,
  buildCombo,
  comboScore,
  findUseCase,
  recommend,
  recommendedWatts,
  requirements,
} from "@/lib/build";
import { getDesktopParts } from "@/lib/desktop-part";
import type { Cpu } from "@/lib/cpu";
import type { Gpu } from "@/lib/desktop-part";

function cpu(overrides: Partial<Cpu> = {}): Cpu {
  return {
    slug: "test-cpu",
    name: "Test CPU",
    manufacturer: { name: "AMD" },
    socket: "AM5",
    memory_support: "DDR5-5600",
    tdp_w: 120,
    max_tdp_w: 162,
    integrated_graphics: "Radeon Graphics",
    msrp_usd: 400,
    storage_options_gb: undefined,
    score: { overall: 70, single: { index: 90 }, multi: { index: 60 } },
    ...overrides,
  } as Cpu;
}

function gpu(overrides: Partial<Gpu> = {}): Gpu {
  return {
    slug: "test-gpu",
    name: "Test GPU",
    manufacturer: { name: "NVIDIA" },
    tdp_w: 285,
    memory_gb: 16,
    pcie_version: "PCIe 5.0",
    msrp_usd: 600,
    score: { overall: 80, graphics: { index: 80 } },
    ...overrides,
  } as Gpu;
}

describe("weighting by use case", () => {
  it("leans on the GPU for gaming and on the CPU for office work", () => {
    const parts = { cpu: cpu(), gpu: gpu() };
    const gaming = comboScore(parts.cpu, parts.gpu, findUseCase("gaming"));
    const office = comboScore(parts.cpu, parts.gpu, findUseCase("office"));
    // 같은 부품인데 용도가 다르면 점수가 달라야 가중치가 실제로 걸린 것이다.
    expect(gaming).not.toBe(office);
    expect(gaming).toBeGreaterThan(office);
  });

  it("credits VRAM only for the AI use case", () => {
    const small = gpu({ memory_gb: 8 });
    const large = gpu({ slug: "big-gpu", memory_gb: 32 });
    const ai = findUseCase("ai");
    const gaming = findUseCase("gaming");
    expect(comboScore(cpu(), large, ai)).toBeGreaterThan(comboScore(cpu(), small, ai));
    expect(comboScore(cpu(), large, gaming)).toBe(comboScore(cpu(), small, gaming));
  });
});

describe("power and requirements", () => {
  it("adds the platform draw and rounds up to 50W", () => {
    // 162(CPU 최대) + 285(GPU) + 150(플랫폼) = 597 → 600
    expect(recommendedWatts(cpu(), gpu())).toBe(600);
  });

  it("falls back to tdp when the cpu has no max tdp", () => {
    expect(recommendedWatts(cpu({ max_tdp_w: null }), gpu())).toBe(600);
  });

  it("derives the parts TechAPI does not carry", () => {
    const rows = requirements(cpu(), gpu());
    const labels = rows.map((row) => row.label);
    expect(labels).toContain("메인보드 소켓");
    expect(labels).toContain("메모리 규격");
    expect(labels).toContain("권장 파워");
    expect(rows.find((row) => row.label === "메인보드 소켓")?.value).toBe("AM5");
  });

  it("says a discrete gpu is required when the cpu has no integrated graphics", () => {
    const rows = requirements(cpu({ integrated_graphics: null }), null);
    expect(rows.find((row) => row.label === "내장 그래픽")?.value).toContain("외장 GPU 필수");
  });
});

describe("bottleneck", () => {
  it("stays quiet when the two sides are close", () => {
    const combo = buildCombo(cpu(), gpu(), findUseCase("gaming"));
    expect(bottleneckMessage(combo.bottleneck)).toBeNull();
  });

  it("warns when the cpu cannot feed the gpu", () => {
    const weak = cpu({ score: { single: { index: 40 }, multi: { index: 30 } } } as Partial<Cpu>);
    const combo = buildCombo(weak, gpu({ score: { graphics: { index: 95 } } } as Partial<Gpu>), findUseCase("gaming"));
    expect(bottleneckMessage(combo.bottleneck)).toContain("CPU가 GPU를 따라가지 못합니다");
  });

  it("judges gaming on single-core, not multi-core", () => {
    // 8코어 X3D 처럼 멀티는 평범해도 게임에 강한 CPU 를 병목으로 찍으면 안 된다.
    const gamingChip = cpu({ score: { single: { index: 95 }, multi: { index: 55 } } } as Partial<Cpu>);
    const fastGpu = gpu({ score: { graphics: { index: 99 } } } as Partial<Gpu>);
    expect(bottleneckMessage(buildCombo(gamingChip, fastGpu, findUseCase("gaming")).bottleneck)).toBeNull();
    // 같은 부품이라도 렌더링에서는 멀티코어가 모자란 게 맞다.
    expect(
      bottleneckMessage(buildCombo(gamingChip, fastGpu, findUseCase("creator")).bottleneck),
    ).toContain("CPU가 GPU를 따라가지 못합니다");
  });
});

describe("recommendation against the real snapshot", () => {
  it("never exceeds the budget", async () => {
    const { cpus, gpus } = await getDesktopParts();
    const picks = recommend(cpus, gpus, findUseCase("gaming"), 900);
    expect(picks.length).toBeGreaterThan(0);
    picks.forEach((combo) => expect(combo.priceUsd).toBeLessThanOrEqual(900));
  });

  it("returns nothing when the budget cannot buy any pair", async () => {
    const { cpus, gpus } = await getDesktopParts();
    expect(recommend(cpus, gpus, findUseCase("gaming"), 200)).toEqual([]);
  });

  it("does not repeat the same part across the picks", async () => {
    const { cpus, gpus } = await getDesktopParts();
    const picks = recommend(cpus, gpus, findUseCase("creator"), 3000);
    expect(new Set(picks.map((combo) => combo.cpu.slug)).size).toBe(picks.length);
    expect(new Set(picks.map((combo) => combo.gpu.slug)).size).toBe(picks.length);
  });

  it("picks a different leader for gaming than for office work", async () => {
    const { cpus, gpus } = await getDesktopParts();
    const gaming = recommend(cpus, gpus, findUseCase("gaming"), 1200)[0];
    const office = recommend(cpus, gpus, findUseCase("office"), 1200)[0];
    expect(gaming.gpu.slug === office.gpu.slug && gaming.cpu.slug === office.cpu.slug).toBe(false);
  });
});
