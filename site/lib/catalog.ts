import { readFile } from "node:fs/promises";
import path from "node:path";
import { z } from "zod";
import { phoneSchema, type Phone } from "@/lib/phone";

const catalogSchema = z.object({
  version: z.number(),
  source: z.string(),
  smartphones: z.array(phoneSchema),
});

let catalogPromise: Promise<Phone[]> | undefined;

export function catalogPath(cwd = process.cwd()): string {
  return path.resolve(cwd, "..", "assets", "catalog", "v1.json");
}

export async function readPhonesFromCatalog(filePath = catalogPath()): Promise<Phone[]> {
  const raw = await readFile(filePath, "utf8");
  return catalogSchema.parse(JSON.parse(raw)).smartphones;
}

export function getCatalogPhones(): Promise<Phone[]> {
  catalogPromise ??= readPhonesFromCatalog();
  return catalogPromise;
}

export async function getCatalogPhone(slug: string): Promise<Phone | null> {
  const phones = await getCatalogPhones();
  return phones.find((phone) => phone.slug === slug) ?? null;
}

export function rankPhones(phones: Phone[]): Phone[] {
  return [...phones].sort((left, right) => {
    const scoreDifference = (right.score?.overall ?? -1) - (left.score?.overall ?? -1);
    return scoreDifference || left.name.localeCompare(right.name);
  });
}
