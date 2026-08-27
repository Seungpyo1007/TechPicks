import { z } from "zod";

/** TechAPI 슬러그 규칙. 잘못된 형태는 라우트 단계에서 404 로 떨어뜨린다. */
export const slugSchema = z
  .string()
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Slug must be lowercase kebab-case");

export function isValidSlug(value: string): boolean {
  return slugSchema.safeParse(value).success;
}
