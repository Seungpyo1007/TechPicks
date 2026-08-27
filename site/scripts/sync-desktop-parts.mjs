/**
 * TechAPI 에서 데스크톱 CPU · GPU 스냅샷을 받아 `site/data/desktop-parts.json` 으로 저장한다.
 *
 * 조립 견적(`/build`)이 쓰는 데이터다. 앱 카탈로그(`assets/catalog/v1.json`)의 CPU 40건은
 * 전부 노트북용이라 데스크톱 조립에는 쓸 수 없어서 따로 받는다.
 *
 * TechAPI 는 컬렉션 인덱스에 슬러그와 이름만 싣기 때문에, 세그먼트나 출시일로 거르려면
 * 레코드를 받아 봐야 한다. CPU 3,977 + GPU 2,030 을 전부 받으면 6천 건이라,
 * 인덱스의 '이름'으로 최신 제품군만 1차로 줄인 뒤(약 550건) 레코드 필드로 정밀하게 거른다.
 * 1차 정규식은 요청 수를 줄이기 위한 것일 뿐이고, 실제 판정은 아래 2차 필터가 한다.
 */
import { writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE_URL = process.env.TECHAPI_BASE_URL ?? "https://gettechapi.github.io/TechAPI";

/** 1차 축소용. 현행 데스크톱 제품군 이름. 새 세대가 나오면 여기에 추가한다. */
const CPU_FAMILIES = /Ryzen [3579] \d{4}|Core i[3579]-1[2-9]\d{2}|Core Ultra \d|Threadripper/i;
const GPU_FAMILIES = /RTX (30|40|50)|RX (6|7|9)\d{3}|Arc [AB]\d/i;

/** 2차 필터 기준. 조립에 의미 있는 세대만 남긴다. */
const CPU_SINCE = "2023-01-01";
const GPU_SINCE = "2022-01-01";

/** GPU 레코드에는 세그먼트 필드가 없다. 이름으로 모바일 판을 걸러낸다. */
const MOBILE_GPU = /\b(Laptop|Mobile|Max-Q)\b|\d+M$|\bM\b$/i;

const CONCURRENCY = 8;

async function getJson(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${response.status} ${url}`);
  return response.json();
}

/** 동시성을 묶어 순차 실행한다. 실패한 슬러그는 건너뛰고 이유를 남긴다. */
async function fetchAll(collection, slugs) {
  const records = [];
  const missing = [];
  for (let start = 0; start < slugs.length; start += CONCURRENCY) {
    const batch = slugs.slice(start, start + CONCURRENCY);
    const settled = await Promise.allSettled(
      batch.map((slug) => getJson(`${BASE_URL}/v1/${collection}/${slug}/index.json`)),
    );
    settled.forEach((result, index) => {
      if (result.status === "fulfilled") records.push(result.value);
      else missing.push(batch[index]);
    });
    process.stdout.write(`\r  ${collection}: ${records.length}/${slugs.length}`);
  }
  process.stdout.write("\n");
  if (missing.length) console.warn(`  건너뜀 ${missing.length}건: ${missing.slice(0, 5).join(", ")}`);
  return records;
}

function hasBenchmark(cpu) {
  return Boolean(cpu.score?.single?.index || cpu.score?.multi?.index);
}

console.log("인덱스 조회…");
const [cpuIndex, gpuIndex] = await Promise.all([
  getJson(`${BASE_URL}/v1/cpus/index.json`),
  getJson(`${BASE_URL}/v1/gpus/index.json`),
]);

const cpuCandidates = cpuIndex.results.filter((item) => CPU_FAMILIES.test(item.name));
const gpuCandidates = gpuIndex.results.filter((item) => GPU_FAMILIES.test(item.name));
console.log(
  `1차 축소: CPU ${cpuCandidates.length}/${cpuIndex.count} · GPU ${gpuCandidates.length}/${gpuIndex.count}`,
);

const [cpuRecords, gpuRecords] = await Promise.all([
  fetchAll("cpus", cpuCandidates.map((item) => item.slug)),
  fetchAll("gpus", gpuCandidates.map((item) => item.slug)),
]);

const cpus = cpuRecords
  .filter(
    (cpu) =>
      cpu.segment === "desktop" &&
      (cpu.release_date ?? "") >= CPU_SINCE &&
      Boolean(cpu.socket) &&
      Boolean(cpu.tdp_w) &&
      hasBenchmark(cpu),
  )
  .sort((left, right) => (right.score?.multi?.index ?? 0) - (left.score?.multi?.index ?? 0));

const gpus = gpuRecords
  .filter(
    (gpu) =>
      (gpu.release_date ?? "") >= GPU_SINCE &&
      Boolean(gpu.tdp_w) &&
      Boolean(gpu.score?.graphics?.index) &&
      !MOBILE_GPU.test(gpu.name),
  )
  .sort((left, right) => (right.score?.graphics?.index ?? 0) - (left.score?.graphics?.index ?? 0));

console.log(`2차 필터: 데스크톱 CPU ${cpus.length}종 · GPU ${gpus.length}종`);

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const outputPath = path.resolve(scriptDirectory, "..", "data", "desktop-parts.json");
const generated = new Date().toISOString().slice(0, 10);

await writeFile(
  outputPath,
  `${JSON.stringify(
    { version: 1, source: "GetTechAPI/TechAPI v1/cpus, v1/gpus", generated, cpus, gpus },
    null,
    2,
  )}\n`,
  "utf8",
);

console.log(`저장 완료: data/desktop-parts.json`);
