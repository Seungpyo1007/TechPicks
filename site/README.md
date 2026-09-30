# TechPicks site

Public, server-rendered TechPicks pages built with Next.js App Router.

```bash
pnpm install --frozen-lockfile
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

Set `NEXT_PUBLIC_SITE_URL` to the production origin. Vercel should import the
repository with `site/` as its root directory and use project name
`techpicks-site`. Preview deployments are marked `noindex` automatically.

The list reads `../assets/catalog/v1.json` directly. Detail and comparison
pages request the TechAPI static dump on the server and fall back to that same
catalog when the upstream is unavailable. Run `pnpm sync:brand` after changing
the selected files under `assets/logo/`.

## Sign-in

`/login` and `/profile` use the app's Firebase project (`lib/firebase.ts`), so
an account made in the app works here. Email and Google work as is. Apple on
the web needs an Apple Services ID and key in Firebase; after that set
`NEXT_PUBLIC_APPLE_SIGN_IN=true`. A new domain has to be added to the Firebase
authorized domains first, or Google shows `unauthorized-domain`.
