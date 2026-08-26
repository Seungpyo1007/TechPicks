# TechPicks architecture

TechPicks keeps the native Flutter application and the public web experience in
one repository while treating them as separate applications.

```text
TechPicks/
├─ lib/ android/ ios/ assets/  # Flutter application
├─ site/                       # Next.js public website
└─ shared/                     # Narrow contracts and web-facing design tokens
```

## Boundaries

- Flutter owns the mobile UI, Firebase authentication, device integrations, and
  the `techpicks://` deep-link scheme.
- Next.js owns crawlable public pages, metadata, sitemaps, and browser sharing.
- UI implementations are not shared. Both applications share stable slugs,
  fixtures, a small token projection, and the TechAPI data source.
- `GetTechAPI/TechAPI` remains the complete schema and data authority. This
  repository documents only the fields that TechPicks consumes.

## Resource addresses

| Resource | Flutter | Web |
| --- | --- | --- |
| Phone detail | `techpicks://device/{slug}` / `/device/:slug` | `/phones/{slug}` |
| Phone comparison | `techpicks://compare/{a}/{b}` | `/compare?type=phone&ids=a,b` |

The path shapes intentionally differ. The stable contract is that the same slug
identifies the same TechAPI record on both platforms.

## Change policy

- App-only and site-only changes should remain separate commits and pull requests.
- Changes under `shared/` must be verified by both applications.
- A site-only change must not trigger Android or iOS builds.
- Generated Flutter plugin files and local Xcode user state are never committed.
