import { readFile } from "node:fs/promises";
import path from "node:path";
import { z } from "zod";
import { cpuSchema, type Cpu } from "@/lib/cpu";
import { slugSchema } from "@/lib/slug";

/**
 * 조립 견적이 쓰는 데스크톱 부품 스냅샷.
 *
 * 앱 카탈로그(`assets/catalog/v1.json`)의 CPU 40건은 전부 노트북용이라 조립에 쓸 수 없다.
 * `pnpm sync:parts` 가 TechAPI 에서 받아 `data/desktop-parts.json` 에 커밋해 둔다.
 */
const indexSchema = z
  .object({
    index: z.number(),
    percentile: z.number().optional().nullable(),
    tier: z.string().optional().nullable(),
    source: z.string().optional().nullable(),
  })
  .passthrough();

export const gpuSchema = z
  .object({
    slug: slugSchema,
    name: z.string().min(1),
    manufacturer: z.object({ slug: z.string().optional(), name: z.string() }).passthrough(),
    architecture: z.string().optional().nullable(),
    release_date: z.string().optional().nullable(),
    msrp_usd: z.number().nonnegative().optional().nullable(),
    memory_gb: z.number().positive().optional().nullable(),
    memory_type: z.string().optional().nullable(),
    boost_clock_mhz: z.number().positive().optional().nullable(),
    tdp_w: z.number().positive(),
    pcie_version: z.string().optional().nullable(),
    fp32_tflops: z.number().positive().optional().nullable(),
    score: z
      .object({
        overall: z.number().optional().nullable(),
        graphics: indexSchema.optional().nullable(),
      })
      .passthrough()
      .optional()
      .nullable(),
    verified: z.boolean().optional().default(false),
    source_urls: z.array(z.string()).optional().default([]),
  })
  .passthrough();

export type Gpu = z.infer<typeof gpuSchema>;

const snapshotSchema = z.object({
  version: z.number(),
  source: z.string(),
  generated: z.string(),
  cpus: z.array(cpuSchema),
  gpus: z.array(gpuSchema),
});

export type DesktopParts = { cpus: Cpu[]; gpus: Gpu[]; generated: string };

let partsPromise: Promise<DesktopParts> | undefined;

export function partsSnapshotPath(cwd = process.cwd()): string {
  return path.resolve(cwd, "data", "desktop-parts.json");
}

export async function readDesktopParts(filePath = partsSnapshotPath()): Promise<DesktopParts> {
  const raw = await readFile(filePath, "utf8");
  const parsed = snapshotSchema.parse(JSON.parse(raw));
  return { cpus: parsed.cpus, gpus: parsed.gpus, generated: parsed.generated };
}

export function getDesktopParts(): Promise<DesktopParts> {
  partsPromise ??= readDesktopParts();
  return partsPromise;
}

export function gpuMemoryLabel(gpu: Gpu): string {
  if (!gpu.memory_gb) return "기록 없음";
  return `${gpu.memory_gb}GB${gpu.memory_type ? ` ${gpu.memory_type}` : ""}`;
}
