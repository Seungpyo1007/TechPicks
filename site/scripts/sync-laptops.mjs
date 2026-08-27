/**
 * TechAPI 에서 노트북 스냅샷을 받아 `site/data/laptops.json` 으로 저장한다.
 *
 * 앱 카탈로그(`assets/catalog/v1.json`)에는 노트북이 없고, 빌드는 네트워크 없이도
 * 같은 결과를 내야 하므로 목록을 커밋해 둔다. 갱신이 필요할 때만 이 스크립트를 돌린다.
 */
import { writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE_URL = process.env.TECHAPI_BASE_URL ?? "https://gettechapi.github.io/TechAPI";

/** 정본 디자인이 쓰던 9종. 브랜드와 가격대가 고르게 퍼져 있다. */
const SLUGS = [
  "apple-macbook-air-2025-m4-abhinavflac-637",
  "apple-macbook-pro-14-m4-abhinavflac-777",
  "apple-macbook-pro-16-m4-abhinavflac-769",
  "asus-rog-strix-scar-18-abhinavflac-506",
  "asus-rog-zephyrus-g16-gu605cw-qr133ws-abhinavflac-505",
  "dell-xps-13-9350-abhinavflac-734",
  "hp-omen-16-max-16-ah0076tx-abhinavflac-565",
  "lenovo-legion-pro-7-2025-abhinavflac-326",
  "lenovo-yoga-slim-9-abhinavflac-288",
];

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const outputPath = path.resolve(scriptDirectory, "..", "data", "laptops.json");

const laptops = [];
for (const slug of SLUGS) {
  const response = await fetch(`${BASE_URL}/v1/laptops/${slug}/index.json`);
  if (!response.ok) {
    throw new Error(`TechAPI 응답 실패: ${slug} (${response.status})`);
  }
  laptops.push(await response.json());
}

const generated = new Date().toISOString().slice(0, 10);
await writeFile(
  outputPath,
  `${JSON.stringify({ version: 1, source: "GetTechAPI/TechAPI v1/laptops", generated, laptops }, null, 2)}\n`,
  "utf8",
);

console.log(`Synced ${laptops.length} laptop(s) to data/laptops.json.`);
