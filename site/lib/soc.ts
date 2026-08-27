import { z } from "zod";
import { slugSchema } from "@/lib/slug";

const indexSchema = z
  .object({
    index: z.number(),
    percentile: z.number().optional().nullable(),
    tier: z.string().optional().nullable(),
    source: z.string().optional().nullable(),
  })
  .passthrough();

/** SoC 채점도 CPU 와 같이 0–100 정규화 지수다.
 *  `cpu.source` 는 geekbench, `system.source` 는 antutu_score 를 가리킨다. */
const socScoreSchema = z
  .object({
    overall: z.number().optional().nullable(),
    cpu: indexSchema.optional().nullable(),
    system: indexSchema.optional().nullable(),
  })
  .passthrough();

export const socSchema = z
  .object({
    slug: slugSchema,
    name: z.string().min(1),
    manufacturer: z.object({ slug: z.string().optional(), name: z.string() }).passthrough().optional().nullable(),
    release_date: z.string().optional().nullable(),
    process_nm: z.number().positive().optional().nullable(),
    gpu_name: z.string().optional().nullable(),
    gpu_cores: z.number().positive().optional().nullable(),
    npu_tops: z.number().nonnegative().optional().nullable(),
    modem: z.string().optional().nullable(),
    score: socScoreSchema.optional().nullable(),
    verified: z.boolean().optional().default(false),
  })
  .passthrough();

export type Soc = z.infer<typeof socSchema>;
