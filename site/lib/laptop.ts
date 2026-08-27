import { readFile } from "node:fs/promises";
import path from "node:path";
import { z } from "zod";
import { slugSchema } from "@/lib/slug";

const laptopSchema = z
  .object({
    slug: slugSchema,
    name: z.string().min(1),
    brand: z.object({ slug: z.string().optional(), name: z.string() }).passthrough(),
    release_date: z.string().optional().nullable(),
    msrp_usd: z.number().nonnegative().optional().nullable(),
    device_category: z.string().optional().nullable(),
    cpu_name: z.string().optional().nullable(),
    gpu_name: z.string().optional().nullable(),
    gpu_type: z.string().optional().nullable(),
    ram_gb: z.number().positive().optional().nullable(),
    storage_gb: z.number().positive().optional().nullable(),
    display: z
      .object({
        size_inch: z.number().positive().optional().nullable(),
        resolution: z.string().optional().nullable(),
        refresh_hz: z.number().positive().optional().nullable(),
        ppi: z.number().positive().optional().nullable(),
      })
      .passthrough()
      .optional()
      .nullable(),
    weight_g: z.number().positive().optional().nullable(),
    os: z.string().optional().nullable(),
    verified: z.boolean().optional().default(false),
    source_urls: z.array(z.string()).optional().default([]),
  })
  .passthrough();

/** `scripts/sync-laptops.mjs` 가 TechAPI 에서 받아 커밋해 둔 스냅샷.
 *  카탈로그(`assets/catalog/v1.json`)에는 노트북이 없고, 빌드는 오프라인에서도
 *  같은 결과를 내야 하므로 원격 조회 대신 이 파일을 읽는다. */
const snapshotSchema = z.object({
  version: z.number(),
  source: z.string(),
  generated: z.string(),
  laptops: z.array(laptopSchema),
});

export type Laptop = z.infer<typeof laptopSchema>;

let snapshotPromise: Promise<Laptop[]> | undefined;

export function laptopSnapshotPath(cwd = process.cwd()): string {
  return path.resolve(cwd, "data", "laptops.json");
}

export async function readLaptops(filePath = laptopSnapshotPath()): Promise<Laptop[]> {
  const raw = await readFile(filePath, "utf8");
  return snapshotSchema.parse(JSON.parse(raw)).laptops;
}

export function getLaptops(): Promise<Laptop[]> {
  snapshotPromise ??= readLaptops();
  return snapshotPromise;
}

export function memoryLabel(laptop: Laptop): string {
  const ram = laptop.ram_gb ? `${laptop.ram_gb}GB` : null;
  const storage = laptop.storage_gb
    ? laptop.storage_gb >= 1024
      ? `${laptop.storage_gb / 1024}TB`
      : `${laptop.storage_gb}GB`
    : null;
  return [ram, storage].filter(Boolean).join(" · ") || "기록 없음";
}

export function displayLabel(laptop: Laptop): string {
  const display = laptop.display;
  if (!display) return "기록 없음";
  const parts = [
    display.size_inch ? `${display.size_inch}″` : null,
    display.resolution ?? null,
    display.refresh_hz ? `${display.refresh_hz}Hz` : null,
  ].filter(Boolean);
  return parts.join(" · ") || "기록 없음";
}

/** 정본 노트북 카드 우하단의 등급 태그. 가격대만으로 나눈다. */
export function tierLabel(laptop: Laptop): string {
  const price = laptop.msrp_usd;
  if (!price) return "가격 미기재";
  if (price >= 2500) return "하이엔드";
  if (price >= 1200) return "퍼포먼스";
  return "메인스트림";
}
