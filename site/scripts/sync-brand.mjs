import { copyFile, mkdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const siteDirectory = path.resolve(scriptDirectory, "..");
const repositoryRoot = path.resolve(siteDirectory, "..");
const outputDirectory = path.join(siteDirectory, "public", "brand");
const files = ["NBlogo_black.png"];

await mkdir(outputDirectory, { recursive: true });
await Promise.all(
  files.map((file) =>
    copyFile(
      path.join(repositoryRoot, "assets", "logo", file),
      path.join(outputDirectory, file),
    ),
  ),
);

console.log(`Synced ${files.length} brand asset(s).`);
