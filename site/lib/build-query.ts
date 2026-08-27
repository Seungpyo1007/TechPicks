import { MAX_BUDGET, MIN_BUDGET, type UseCaseKey, USE_CASES } from "@/lib/build";
import { isValidSlug } from "@/lib/slug";

/**
 * `/build?use=gaming&budget=1500&cpu={slug}&gpu={slug}`
 *
 * 견적을 URL 에 담아야 그대로 공유되고 서버가 렌더할 수 있다. `/compare` 와 같은 규칙이다.
 */
type SearchValue = string | string[] | undefined;

export type BuildQuery =
  | { kind: "build"; use: UseCaseKey; budgetUsd: number; cpu: string | null; gpu: string | null }
  | { kind: "not-found" };

const DEFAULT_USE: UseCaseKey = "gaming";
const DEFAULT_BUDGET = 1500;

function single(value: SearchValue): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

function isUseCaseKey(value: string | undefined): value is UseCaseKey {
  return value !== undefined && USE_CASES.some((useCase) => useCase.key === value);
}

export function parseBuildQuery(
  query: Record<string, SearchValue>,
  validCpuSlugs: ReadonlySet<string>,
  validGpuSlugs: ReadonlySet<string>,
): BuildQuery {
  const useValue = single(query.use);
  if (useValue !== undefined && !isUseCaseKey(useValue)) return { kind: "not-found" };

  const budgetValue = single(query.budget);
  let budgetUsd = DEFAULT_BUDGET;
  if (budgetValue !== undefined) {
    const parsed = Number(budgetValue);
    if (!Number.isFinite(parsed) || !Number.isInteger(parsed)) return { kind: "not-found" };
    if (parsed < MIN_BUDGET || parsed > MAX_BUDGET) return { kind: "not-found" };
    budgetUsd = parsed;
  }

  const cpuValue = single(query.cpu);
  if (cpuValue !== undefined && (!isValidSlug(cpuValue) || !validCpuSlugs.has(cpuValue))) {
    return { kind: "not-found" };
  }

  const gpuValue = single(query.gpu);
  if (gpuValue !== undefined && (!isValidSlug(gpuValue) || !validGpuSlugs.has(gpuValue))) {
    return { kind: "not-found" };
  }

  return {
    kind: "build",
    use: isUseCaseKey(useValue) ? useValue : DEFAULT_USE,
    budgetUsd,
    cpu: cpuValue ?? null,
    gpu: gpuValue ?? null,
  };
}

export function buildHref(options: {
  use: UseCaseKey;
  budgetUsd: number;
  cpu?: string | null;
  gpu?: string | null;
}): string {
  const params = new URLSearchParams({
    use: options.use,
    budget: String(options.budgetUsd),
  });
  if (options.cpu) params.set("cpu", options.cpu);
  if (options.gpu) params.set("gpu", options.gpu);
  return `/build?${params.toString()}`;
}
