import { z } from "zod";
import { slugSchema } from "@/lib/slug";

const makerSchema = z
  .object({ slug: z.string().optional(), name: z.string().min(1) })
  .passthrough();

/** TechAPI 채점은 원시 벤치 점수가 아니라 0–100 정규화 지수를 발행한다. */
const indexSchema = z
  .object({
    index: z.number(),
    percentile: z.number().optional().nullable(),
    tier: z.string().optional().nullable(),
    source: z.string().optional().nullable(),
  })
  .passthrough();

const cpuScoreSchema = z
  .object({
    overall: z.number().optional().nullable(),
    single: indexSchema.optional().nullable(),
    multi: indexSchema.optional().nullable(),
  })
  .passthrough();

export const cpuSchema = z
  .object({
    slug: slugSchema,
    name: z.string().min(1),
    manufacturer: makerSchema,
    release_date: z.string().optional().nullable(),
    segment: z.string().optional().nullable(),
    architecture: z.string().optional().nullable(),
    socket: z.string().optional().nullable(),
    process_node: z.string().optional().nullable(),
    cores: z.number().int().positive().optional().nullable(),
    threads: z.number().int().positive().optional().nullable(),
    p_cores: z.number().int().nonnegative().optional().nullable(),
    e_cores: z.number().int().nonnegative().optional().nullable(),
    base_clock_ghz: z.number().positive().optional().nullable(),
    boost_clock_ghz: z.number().positive().optional().nullable(),
    l3_cache_mb: z.number().nonnegative().optional().nullable(),
    tdp_w: z.number().nonnegative().optional().nullable(),
    max_tdp_w: z.number().nonnegative().optional().nullable(),
    integrated_graphics: z.string().optional().nullable(),
    memory_support: z.string().optional().nullable(),
    msrp_usd: z.number().nonnegative().optional().nullable(),
    score: cpuScoreSchema.optional().nullable(),
    verified: z.boolean().optional().default(false),
    source_urls: z.array(z.string()).optional().default([]),
  })
  .passthrough();

export type Cpu = z.infer<typeof cpuSchema>;

export function cpuCoreLabel(cpu: Cpu): string {
  if (!cpu.cores) return "기록 없음";
  const threads = cpu.threads ? ` · ${cpu.threads}스레드` : "";
  const split = cpu.p_cores && cpu.e_cores ? ` (P ${cpu.p_cores} + E ${cpu.e_cores})` : "";
  return `${cpu.cores}코어${split}${threads}`;
}

export function cpuClockLabel(cpu: Cpu): string {
  const base = cpu.base_clock_ghz ? `${cpu.base_clock_ghz}GHz` : null;
  const boost = cpu.boost_clock_ghz ? `최대 ${cpu.boost_clock_ghz}GHz` : null;
  return [base, boost].filter(Boolean).join(" · ") || "기록 없음";
}
