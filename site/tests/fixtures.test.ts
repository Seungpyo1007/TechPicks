import { readFile } from "node:fs/promises";
import path from "node:path";
import { describe, expect, it } from "vitest";
import { parsePhone } from "@/lib/phone";

async function fixture(name: string): Promise<unknown> {
  const filePath = path.resolve(process.cwd(), "..", "shared", "contracts", "fixtures", name);
  return JSON.parse(await readFile(filePath, "utf8"));
}

describe("shared smartphone fixtures", () => {
  it("parses the normal consumed-field fixture", async () => {
    const phone = parsePhone(await fixture("valid-phone.json"));
    expect(phone.slug).toBe("galaxy-s25-ultra");
    expect(phone.score?.overall).toBe(78.9);
  });

  it("accepts missing optional fields with stable defaults", async () => {
    const phone = parsePhone(await fixture("missing-fields-phone.json"));
    expect(phone.storage_options_gb).toEqual([]);
    expect(phone.source_urls).toHaveLength(1);
  });

  it("rejects a malformed slug", async () => {
    const value = await fixture("invalid-slug-phone.json");
    expect(() => parsePhone(value)).toThrow(/slug/i);
  });
});
