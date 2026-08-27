# TechPicks consumer contract

The complete schema and data authority is
[GetTechAPI/TechAPI](https://github.com/GetTechAPI/TechAPI). This directory is
not a copy of that schema. It records only the fields currently consumed by the
Flutter app and Next.js site and supplies narrow cross-application fixtures.

## Smartphone fields in use

- Identity: `slug`, `name`, `brand.slug`, `brand.name`
- Ranking: `score.overall`, `score.performance`, `score.camera`,
  `score.battery`, `score.display`, `score.value`
- Summary: `release_date`, `msrp_usd`, `image_url`, `verified`
- Specifications: `soc.name`, `ram_gb`, `storage_options_gb`, `display`,
  `battery_mah`, charging wattage, cameras, dimensions, weight, ingress rating,
  OS, and connectivity
- Attribution: `source_urls`

Unknown fields are ignored. Optional fields may be absent or `null`. Slugs must
be lowercase kebab-case and are the stable identifier shared by app deep links
and web URLs.

## Fixtures

- `valid-phone.json`: a normal record using the consumed subset
- `missing-fields-phone.json`: a valid record with optional fields omitted
- `invalid-slug-phone.json`: a deliberately invalid slug for parser tests

Data fixtures are reduced test records derived from TechAPI and retain its
CC-BY-SA 4.0 attribution.
