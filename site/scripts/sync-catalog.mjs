/**
 * 앱이 번들하는 카탈로그를 사이트 안으로 복사한다.
 *
 * 앱과 웹이 같은 순위를 보여주려면 같은 파일을 읽어야 한다. 그런데 원본은 저장소 루트의
 * `assets/catalog/v1.json` 이라 `site/` 를 프로젝트 루트로 배포하면 빌드 중에 보이지 않는다.
 * 그래서 노트북·데스크톱 부품과 같은 방식으로 스냅샷을 커밋해 두고, 두 파일이 어긋나지
 * 않는지는 CI 가 확인한다(`site-ci.yml` 의 catalog snapshot 단계).
 */
import { copyFile, mkdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const siteDirectory = path.resolve(scriptDirectory, "..");
const source = path.resolve(siteDirectory, "..", "assets", "catalog", "v1.json");
const target = path.join(siteDirectory, "data", "catalog.json");

await mkdir(path.dirname(target), { recursive: true });
await copyFile(source, target);

console.log("Synced assets/catalog/v1.json to data/catalog.json.");
