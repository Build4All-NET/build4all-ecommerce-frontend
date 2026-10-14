# build4all-ecommerce-frontend

Build pipeline for the Build4All ecommerce apps. The app source is **not** here —
it lives in the private repository `Build4All-NET/build4all-ecommerce-core`, and
CI checks it out at build time.

## Why the split

GitHub Actions minutes and GitHub Pages are free only on a public repository, and
the owner storefronts are published from this one. Keeping the workflows here and
the source private keeps both: free builds, unpublished code.

## What runs here

| Workflow | Triggered by | Produces |
|---|---|---|
| `owner_app_build.yml` | `repository_dispatch` | APK + AAB, uploaded to Cloudflare R2 |
| `owner_app_build_ios.yml` | `repository_dispatch` | IPA, uploaded to TestFlight |
| `owner_web_build.yml` | `repository_dispatch`, manual | Storefront site (Cloudflare Pages or GitHub Pages) |
| `add_tester_to_app.yml` | `repository_dispatch`, manual | Adds a TestFlight internal tester |
| `cf_pages_diagnose.yml` | manual | Cloudflare Pages diagnostics |

The backend dispatches a build; the workflow reports back to it over the CI
callback endpoints. Nothing here is driven by a push.

## How the source is pulled in

Each build workflow names the source repository once, in `APP_SOURCE_REPO`, and
checks it out with `CORE_REPO_TOKEN` — a fine-grained token scoped to that one
repository, Contents: read-only.

iOS needs both trees: the app source at the workspace root, and the App Store
Connect helpers under `.github/scripts`, which ship with the workflows rather
than with the app. It checks the scripts out separately and sparsely, into the
directory named by `CI_SCRIPTS_DIR`.

`add_tester_to_app.yml` never reads the app source, so it still checks out this
repository alone.

## Working on the app itself

Clone `Build4All-NET/build4all-ecommerce-core`. Changes to screens, assets and
`pubspec.yaml` belong there. This repository changes only when the pipeline does.
