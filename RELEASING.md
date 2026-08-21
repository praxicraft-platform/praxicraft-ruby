# Releasing

Maintainer notes for publishing the `praxicraft` gem to RubyGems.

## How publish works

[`.github/workflows/publish.yml`](.github/workflows/publish.yml) runs on pushes to **`main`** when:

- `lib/**`
- `praxicraft.gemspec`
- `CHANGELOG.md`
- `.github/workflows/publish.yml`

Flow:

1. Run tests on Ruby 3.1 / 3.2 / 3.3.
2. Read `Praxicraft::VERSION` from `lib/praxicraft/version.rb`.
3. If git tag `v{version}` already exists → skip.
4. Otherwise create + push `v{version}`, `gem build`, `gem push`.

## Cut a release

1. Bump `VERSION` in `lib/praxicraft/version.rb`.
2. Update `CHANGELOG.md`.
3. Merge to `main`.

## One-time RubyGems setup

1. Create the gem name [`praxicraft`](https://rubygems.org) (or ensure you can push it).
2. Create GitHub Environment **`rubygems`** on `praxicraft-platform/praxicraft-ruby`.
3. Set repository secret `RUBYGEMS_API_KEY` (RubyGems API key with push access).
4. Merge a version bump to `main` for the first release.

## GitHub Release

The Publish workflow also creates a **GitHub Release** for tag `v{version}` (with generated notes and package assets where applicable).

You can run **Actions → Publish → Run workflow** manually (`workflow_dispatch`) after bumping the version on `main`.
