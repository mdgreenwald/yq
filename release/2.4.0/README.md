# yq 2.4.0 rebuild with native Apple Silicon (darwin/arm64)

This directory rebuilds [upstream yq 2.4.0](https://github.com/mikefarah/yq/releases/tag/2.4.0)
from its unmodified source and publishes it with a `darwin/arm64` binary, which was never
released because Apple Silicon (and Go's macOS arm64 port) did not exist in May 2019.

Projects pinned to yq 2.4.0 can download `yq_darwin_arm64` from this fork's `v2.4.0` (or `2.4.0`)
release instead of relying on Rosetta. On a Mac without Rosetta, upstream's
`yq_darwin_amd64` fails with `Bad CPU type in executable`.

| File | Purpose |
|---|---|
| `mise.toml` | Pins Go 1.16.15 and GoReleaser 2.18.3 |
| `prepare.sh` | Vendors the pinned dependencies into a 2.4.0 checkout and verifies their checksums |
| `vendor-2.4.0.tar.gz` | The pinned dependency sources, so builds don't depend on third-party repositories |
| `.goreleaser.yaml` | Builds the 23 targets as raw binaries named like upstream's assets |
| `stage.sh` | Flattens GoReleaser output into release asset names and verifies `checksums.txt` |
| `smoke.sh` | Runs a binary through version, acceptance and 2.4.0 feature checks |
| `RELEASE_NOTES.md` | Release body: rebuild notice plus upstream's original notes |

Workflows:

- [`legacy-2.4.0-build.yml`](../../.github/workflows/legacy-2.4.0-build.yml) builds, runs upstream's
  unit tests, and smoke-tests the binaries natively on macOS arm64, macOS Intel, Linux amd64/arm64
  and Windows. It runs on changes to these files and on demand.
- [`legacy-2.4.0-release.yml`](../../.github/workflows/legacy-2.4.0-release.yml) (manual) runs the
  build, rebuilds and checks the result is byte-identical to what was smoke-tested, then creates
  **draft** releases `v2.4.0` and `2.4.0` with build provenance attestations.

## Source and version

| | |
|---|---|
| Upstream tag | `2.4.0` (lightweight) → commit `84de9c078dd9f52a50182c79c96e63a21ff1756e`, "Improved handling of numeric keys", 2019-05-16 |
| This fork's tags | `v2.4.0` and `2.4.0`, both → the same commit. The source is built as-is; build configuration lives here, on `master` |
| `--version` | `yq version 2.4.0`, as upstream: `-X main.GitDescribe=2.4.0` (`GitDescribe` replaces the version text, so it must not carry a `v`) |

## Targets

Upstream released 23 raw binaries built with go1.11.4 (found by running `strings` on its
`yq_linux_amd64`) using `gox`. This rebuild uses **Go 1.16.15**, the oldest Go with an official
`darwin/arm64` port, for every target:

| OS | Arches | vs upstream |
|---|---|---|
| darwin | amd64, **arm64** | **+arm64**, −386 |
| freebsd | 386, amd64, arm | same |
| linux | 386, amd64, arm, arm64, mips, mips64, mips64le, mipsle, ppc64, ppc64le, s390x | same |
| netbsd | 386, amd64, arm | same |
| openbsd | 386, amd64 | same |
| windows | 386, amd64 | same |

- `darwin/386` was removed in Go 1.15 and can't be built with Go 1.16. Use
  [upstream's binary](https://github.com/mikefarah/yq/releases/download/2.4.0/yq_darwin_386) for it.
- 32-bit ARM uses `GOARM=7`, matching upstream (read from `runtime.goarm` in upstream's
  `yq_linux_arm`, `yq_freebsd_arm` and `yq_netbsd_arm`).
- Go 1.16's linker ad-hoc signs `darwin/arm64` binaries even when cross-compiling, which Apple
  Silicon requires. The binaries are not notarised.
- `CGO_ENABLED=0`, `-trimpath` and `mod_timestamp` make the build reproducible: two builds give
  identical `checksums.txt`.

## Building a module-less 2019 project with Go 1.16

- **GOPATH mode.** 2.4.0 has no `go.mod`, so everything runs with `GO111MODULE=off`. The source
  must sit at `$GOPATH/src/github.com/mikefarah/yq` (its `vendor.json` `rootPath`). GoReleaser
  handles this and logs `not a go module`.
- **Committed dependencies.** Only `vendor/vendor.json` is committed at 2.4.0 (`vendor/*/` is
  gitignored). The dependency sources are kept here in `vendor-2.4.0.tar.gz`, and `prepare.sh`
  unpacks them into the checkout. It then builds the archived
  [govendor](https://github.com/kardianos/govendor) at a pinned commit and runs `govendor status`,
  which fails if any vendored package differs from the `checksumSHA1` in `vendor.json`. The
  release attaches the same tarball.
- **Dangling dependency commit.** `vendor.json` pins `gopkg.in/mikefarah/yaml.v2` at
  `e175af14aaa1d0eff2ee04b691e4a4827a111416`, which is no longer on any branch of
  `github.com/mikefarah/yaml`, so `govendor sync` can't check it out. GitHub still serves it when
  fetched by SHA, but may garbage-collect it at any time; that is why the sources are committed.
  `VENDOR_FROM_NETWORK=1 prepare.sh` re-fetches everything with `govendor sync` (fetching the
  dangling commit by SHA) as a cross-check.

| Dependency | Revision |
|---|---|
| github.com/inconshreveable/mousetrap | `76626ae9c91c4f2a10f34cad8ce83ea42c93bb75` |
| github.com/pkg/errors | `816c9085562cd7ee03e7f8188a1cfd942858cded` |
| github.com/spf13/pflag | `3ebe029320b2676d667ae88da602a5f854788a8a` |
| gopkg.in/imdario/mergo.v0 | `9316a62528ac99aaecb4e47eadd6dc8aa6533d58` |
| gopkg.in/mikefarah/yaml.v2 | `e175af14aaa1d0eff2ee04b691e4a4827a111416` (dangling) |
| gopkg.in/op/go-logging.v1 | `b2cb9fa56473e98db8caba80237377e83fe44db5` |
| gopkg.in/spf13/cobra.v0 | `ef82de70bb3f60c65fb8eebacbb2d122ef517385` |

## Building locally

Needs [mise](https://mise.jdx.dev), git, jq, and network access to github.com (for govendor).
On an Apple Silicon Mac every tool runs natively.

```bash
ROOT=$PWD
WORK=$ROOT/tmp/legacy-2.4.0     # tmp/ is gitignored
SRC=$WORK/gopath/src/github.com/mikefarah/yq

git fetch https://github.com/mikefarah/yq.git tag 2.4.0 --no-tags   # if the commit is missing
mkdir -p "$(dirname "$SRC")"
git worktree add --detach "$SRC" 84de9c078dd9f52a50182c79c96e63a21ff1756e

mise trust release/2.4.0/mise.toml
mise -C release/2.4.0 install
eval "$(mise -C release/2.4.0 env -s bash)"    # Go 1.16.15 + GoReleaser on PATH
export GOPATH=$WORK/gopath GO111MODULE=off   # 2.4.0 predates Go modules

bash release/2.4.0/prepare.sh "$SRC"

cd "$SRC"
bash scripts/test.sh
goreleaser release --snapshot --clean --skip=publish --config "$ROOT/release/2.4.0/.goreleaser.yaml"
bash "$ROOT/release/2.4.0/stage.sh" "$WORK/gopath/src/github.com/mikefarah/dist" "$WORK/assets"
bash "$ROOT/release/2.4.0/smoke.sh" "$WORK/assets/yq_darwin_arm64"
```

Gotchas:

- mise sets `GOBIN` to the Go install's own `bin`, so a plain `go get` installs into the toolchain.
  `prepare.sh` sets `GOBIN` explicitly.
- `govendor` must run with Go 1.16 on `PATH`. Under a modern Go it fails with `lstat ''`.
- Avoid `mise exec -C <dir>` for these steps: it also changes the working directory.
- A git `url.<ssh>.insteadOf https://github.com/` rewrite makes these clones go over SSH. If your
  SSH agent can't sign, run with `GIT_CONFIG_GLOBAL=/dev/null`.
- In zsh, quote yq 2.x paths with brackets (`'b.d[+]'`), or zsh treats them as globs.
- Upstream's `make local build` is not used: it runs `gometalinter` (archived) and installs its
  tools with `go get -u` at their latest versions, so it isn't reproducible. GoReleaser keeps
  upstream's ldflags.

## Releasing

1. Push the tags (once):
   `git tag -a v2.4.0 84de9c07 -m "yq 2.4.0 rebuild with darwin/arm64" && git tag 2.4.0 84de9c07 && git push origin v2.4.0 2.4.0`.
   The tagged commit has no `.github/workflows`, so pushing these tags triggers nothing.
2. Disable the fork's `docker-release.yml` and `snap-release.yml` (`gh workflow disable`). They
   run on any published release and publish upstream's Docker and Snap packages.
3. Run **Legacy 2.4.0 release** from the Actions tab. If either tag already has a published
   release it refuses to run; stale drafts are deleted and recreated.
4. Review the drafts and publish `v2.4.0` (as Latest), then `2.4.0`.

Verify a download:

```bash
shasum -a 256 -c checksums.txt --ignore-missing
gh attestation verify yq_darwin_arm64 --repo mdgreenwald/yq
```
