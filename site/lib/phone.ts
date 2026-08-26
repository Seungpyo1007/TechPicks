import { z } from "zod";

export const phoneSlugSchema = z
  .string()
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Phone slug must be lowercase kebab-case");

const brandSchema = z
  .object({
    slug: phoneSlugSchema,
    name: z.string().min(1),
  })
  .passthrough();

const socSchema = z
  .object({
    slug: phoneSlugSchema.optional(),
    name: z.string().min(1),
  })
  .passthrough();

const displaySchema = z
  .object({
    size_inch: z.number().positive().optional().nullable(),
    resolution: z.string().optional().nullable(),
    refresh_hz: z.number().positive().optional().nullable(),
    type: z.string().optional().nullable(),
    brightness_nits: z.number().positive().optional().nullable(),
    ppi: z.number().positive().optional().nullable(),
  })
  .passthrough();

const cameraSchema = z
  .object({
    type: z.string(),
    mp: z.number().nonnegative().optional().nullable(),
    aperture: z.number().positive().optional().nullable(),
    ois: z.boolean().optional().nullable(),
    optical_zoom: z.number().positive().optional().nullable(),
  })
  .passthrough();

const scoreSchema = z
  .object({
    overall: z.number().min(0).max(100),
    performance: z.number().min(0).max(100).optional().nullable(),
    camera: z.number().min(0).max(100).optional().nullable(),
    battery: z.number().min(0).max(100).optional().nullable(),
    display: z.number().min(0).max(100).optional().nullable(),
    value: z.number().min(0).max(100).optional().nullable(),
  })
  .passthrough();

export const phoneSchema = z
  .object({
    slug: phoneSlugSchema,
    name: z.string().min(1),
    brand: brandSchema,
    soc: socSchema.optional().nullable(),
    release_date: z.string().optional().nullable(),
    msrp_usd: z.number().nonnegative().optional().nullable(),
    ram_gb: z.number().positive().optional().nullable(),
    storage_options_gb: z.array(z.number().positive()).optional().default([]),
    display: displaySchema.optional().nullable(),
    cameras: z.array(cameraSchema).optional().default([]),
    battery_mah: z.number().positive().optional().nullable(),
    charging_wired_w: z.number().nonnegative().optional().nullable(),
    charging_wireless_w: z.number().nonnegative().optional().nullable(),
    weight_g: z.number().positive().optional().nullable(),
    dimensions: z
      .object({
        height_mm: z.number().positive().optional().nullable(),
        width_mm: z.number().positive().optional().nullable(),
        depth_mm: z.number().positive().optional().nullable(),
      })
      .passthrough()
      .optional()
      .nullable(),
    ip_rating: z.string().optional().nullable(),
    os: z.string().optional().nullable(),
    os_version: z.string().optional().nullable(),
    connectivity: z
      .object({
        wifi: z.string().optional().nullable(),
        bluetooth: z.string().optional().nullable(),
        nfc: z.boolean().optional().nullable(),
        usb: z.string().optional().nullable(),
      })
      .passthrough()
      .optional()
      .nullable(),
    image_url: z.url().optional().nullable(),
    score: scoreSchema.optional().nullable(),
    verified: z.boolean().optional().default(false),
    source_urls: z.array(z.url()).optional().default([]),
  })
  .passthrough();

export type Phone = z.infer<typeof phoneSchema>;

export type PhoneListItem = {
  slug: string;
  name: string;
  brandName: string;
  socName: string | null;
  priceUsd: number | null;
  imageUrl: string | null;
  overallScore: number | null;
};

export type PhoneOption = { slug: string; name: string };

export function parsePhone(value: unknown): Phone {
  return phoneSchema.parse(value);
}

export function toPhoneListItem(phone: Phone): PhoneListItem {
  return {
    slug: phone.slug,
    name: phone.name,
    brandName: phone.brand.name,
    socName: phone.soc?.name ?? null,
    priceUsd: phone.msrp_usd ?? null,
    imageUrl: phone.image_url ?? null,
    overallScore: phone.score?.overall ?? null,
  };
}

export function toPhoneOption(phone: Phone): PhoneOption {
  return { slug: phone.slug, name: phone.name };
}
