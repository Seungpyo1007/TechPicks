import { getCatalogPhone } from "@/lib/catalog";
import { parsePhone, phoneSlugSchema, type Phone } from "@/lib/phone";

export const TECHAPI_BASE_URL =
  process.env.TECHAPI_BASE_URL ?? "https://gettechapi.github.io/TechAPI";

type PhoneLoaderOptions = {
  fetcher?: typeof fetch;
  fallback?: (slug: string) => Promise<Phone | null>;
};

export async function getPhone(
  slug: string,
  options: PhoneLoaderOptions = {},
): Promise<Phone | null> {
  const parsedSlug = phoneSlugSchema.safeParse(slug);
  if (!parsedSlug.success) return null;

  const fallback = options.fallback ?? getCatalogPhone;
  const catalogPhone = await fallback(parsedSlug.data);
  if (!catalogPhone) return null;

  try {
    const fetcher = options.fetcher ?? fetch;
    const response = await fetcher(
      `${TECHAPI_BASE_URL}/v1/smartphones/${parsedSlug.data}/index.json`,
      { next: { revalidate: 86400 } },
    );
    if (!response.ok) return catalogPhone;

    const remotePhone = parsePhone(await response.json());
    return remotePhone.slug === parsedSlug.data ? remotePhone : catalogPhone;
  } catch {
    return catalogPhone;
  }
}
