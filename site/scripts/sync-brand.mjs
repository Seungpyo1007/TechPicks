import { access, copyFile, mkdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const siteDirectory = path.resolve(scriptDirectory, "..");
const repositoryRoot = path.resolve(siteDirectory, "..");
const outputDirectory = path.join(siteDirectory, "public", "brand");
// 사이드바·로그인 락업은 액센트 배경 위 흰 로고를 쓴다(정본 디자인).
const files = ["NBlogo.png", "NBlogo_black.png"];

// 배포 빌드는 site/ 만 받으므로 저장소 루트의 원본이 없다. 그때는 public/brand 에
// 커밋해 둔 사본이 이미 정답이라 복사를 건너뛴다.
const sourceDirectory = path.join(repositoryRoot, "assets", "logo");
try {
  await access(sourceDirectory);
} catch {
  console.log("Brand source not available; using the copies committed under public/brand.");
  process.exit(0);
}

await mkdir(outputDirectory, { recursive: true });
await Promise.all(
  files.map((file) => copyFile(path.join(sourceDirectory, file), path.join(outputDirectory, file))),
);

console.log(`Synced ${files.length} brand asset(s).`);
