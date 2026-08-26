import { describe, expect, it, vi } from "vitest";
import { parsePhone } from "@/lib/phone";
import { getPhone } from "@/lib/techapi";
import validPhone from "../../shared/contracts/fixtures/valid-phone.json";

const fallbackPhone = parsePhone(validPhone);
const fallback = vi.fn(async (slug: string) => (slug === fallbackPhone.slug ? fallbackPhone : null));

describe("TechAPI detail loading", () => {
  it("returns a parsed upstream record", async () => {
    const remote = { ...validPhone, name: "Remote Galaxy S25 Ultra" };
    const fetcher = vi.fn(async () => new Response(JSON.stringify(remote), { status: 200 }));
    const phone = await getPhone(fallbackPhone.slug, { fetcher: fetcher as typeof fetch, fallback });
    expect(phone?.name).toBe("Remote Galaxy S25 Ultra");
  });

  it("falls back to the catalog on network and parsing failures", async () => {
    const networkFailure = vi.fn(async () => { throw new Error("offline"); });
    await expect(getPhone(fallbackPhone.slug, { fetcher: networkFailure as unknown as typeof fetch, fallback })).resolves.toEqual(fallbackPhone);

    const invalidPayload = vi.fn(async () => new Response("{}", { status: 200 }));
    await expect(getPhone(fallbackPhone.slug, { fetcher: invalidPayload as typeof fetch, fallback })).resolves.toEqual(fallbackPhone);
  });

  it("does not fetch a slug outside the shared catalog", async () => {
    const fetcher = vi.fn();
    await expect(getPhone("unknown-phone", { fetcher: fetcher as unknown as typeof fetch, fallback })).resolves.toBeNull();
    expect(fetcher).not.toHaveBeenCalled();
  });
});
