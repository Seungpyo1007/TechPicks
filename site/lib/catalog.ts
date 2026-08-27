import { readFile } from "node:fs/promises";
import path from "node:path";
import { z } from "zod";
import { cpuSchema, type Cpu } from "@/lib/cpu";
import { phoneSchema, type Phone } from "@/lib/phone";
import { socSchema, type Soc } from "@/lib/soc";

/** Flutter 앱이 번들하는 카탈로그. 앱과 웹이 같은 순위를 보여주려면 같은 파일을 읽어야 한다. */
const catalogSchema = z.object({
  version: z.number(),
  source: z.string(),
  smartphones: z.array(phoneSchema),
  cpus: z.array(cpuSchema).optional().default([]),
  socs: z.array(socSchema).optional().default([]),
});

type Catalog = z.infer<typeof catalogSchema>;

let catalogPromise: Promise<Catalog> | undefined;

export function catalogPath(cwd = process.cwd()): string {
  return path.resolve(cwd, "..", "assets", "catalog", "v1.json");
}

export async function readCatalog(filePath = catalogPath()): Promise<Catalog> {
  const raw = await readFile(filePath, "utf8");
  return catalogSchema.parse(JSON.parse(raw));
}

export async function readPhonesFromCatalog(filePath = catalogPath()): Promise<Phone[]> {
  return (await readCatalog(filePath)).smartphones;
}

function getCatalog(): Promise<Catalog> {
  catalogPromise ??= readCatalog();
  return catalogPromise;
}

export async function getCatalogPhones(): Promise<Phone[]> {
  return (await getCatalog()).smartphones;
}

export async function getCatalogPhone(slug: string): Promise<Phone | null> {
  const phones = await getCatalogPhones();
  return phones.find((phone) => phone.slug === slug) ?? null;
}

export async function getCatalogCpus(): Promise<Cpu[]> {
  return (await getCatalog()).cpus;
}

export async function getCatalogCpu(slug: string): Promise<Cpu | null> {
  const cpus = await getCatalogCpus();
  return cpus.find((cpu) => cpu.slug === slug) ?? null;
}

export async function getCatalogSocs(): Promise<Soc[]> {
  return (await getCatalog()).socs;
}

/** 슬러그로 SoC 를 찾는다. 스마트폰 레코드의 `soc` 는 요약본이라 지수·모뎀은 여기서 온다. */
export async function getCatalogSoc(slug: string | null | undefined): Promise<Soc | null> {
  if (!slug) return null;
  const socs = await getCatalogSocs();
  return socs.find((soc) => soc.slug === slug) ?? null;
}

export function rankPhones(phones: Phone[]): Phone[] {
  return [...phones].sort((left, right) => {
    const scoreDifference = (right.score?.overall ?? -1) - (left.score?.overall ?? -1);
    return scoreDifference || left.name.localeCompare(right.name);
  });
}

/** 멀티코어 지수 내림차순. 정본 홈 화면의 `CPU 멀티코어 상위 5` 가 쓰는 정렬이다. */
export function rankCpus(cpus: Cpu[]): Cpu[] {
  return [...cpus].sort((left, right) => {
    const multi = (right.score?.multi?.index ?? -1) - (left.score?.multi?.index ?? -1);
    return multi || (right.score?.overall ?? -1) - (left.score?.overall ?? -1) || left.name.localeCompare(right.name);
  });
}
