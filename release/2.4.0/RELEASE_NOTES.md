> **This is a rebuild of [yq 2.4.0](https://github.com/mikefarah/yq/releases/tag/2.4.0) that adds a
> native Apple Silicon (`darwin/arm64`) binary.** It is not an official upstream release.
>
> - Built from the unmodified upstream commit
>   [`84de9c07`](https://github.com/mikefarah/yq/commit/84de9c078dd9f52a50182c79c96e63a21ff1756e),
>   the same commit as upstream's `2.4.0` tag, with the dependency revisions pinned in its
>   `vendor/vendor.json` (checksums verified).
> - **New:** `yq_darwin_arm64` runs natively on Apple Silicon Macs, with no Rosetta needed.
> - **Not included:** `yq_darwin_386`. Go 1.15 removed 32-bit macOS support; use
>   [upstream's binary](https://github.com/mikefarah/yq/releases/download/2.4.0/yq_darwin_386) if you need it.
> - Built with Go 1.16.15 (upstream used go1.11.4), `CGO_ENABLED=0`, reproducible
>   (`-trimpath`, fixed timestamps). `yq --version` prints `yq version 2.4.0`, as upstream.
> - `checksums.txt` lists SHA-256 sums for every asset. Each binary has a GitHub build provenance
>   attestation: `gh attestation verify yq_darwin_arm64 --repo mdgreenwald/yq`
> - `vendor-2.4.0.tar.gz` contains the exact vendored dependency sources, kept so that this
>   release can be rebuilt even if an upstream dependency revision disappears.
> - `yq_darwin_arm64` is ad-hoc signed (as Apple Silicon requires) but not notarised. If a
>   browser download is blocked by Gatekeeper, download with `curl -L` or run
>   `xattr -d com.apple.quarantine yq_darwin_arm64`.
>
> How this was built: [`release/2.4.0/`](https://github.com/mdgreenwald/yq/tree/master/release/2.4.0)

---

## Upstream release notes: Splat and numeric keys!

### Prefix Splat!
Fixes https://github.com/mikefarah/yq/issues/218

### Delete Splat!
Fixes https://github.com/mikefarah/yq/issues/175

### Support numeric keys
Fixes: https://github.com/mikefarah/yq/issues/219 and https://github.com/mikefarah/yq/issues/215

Note there is a (slight) backwards incompatible change.

When there is no match at a given path, numeric keys are assumed to be strings.
To create an array '+' must be used.

e.g:
```
yq n thing[+].cat fred
```
will create an array under thing, whereas
```
yq n thing[0].cat fred
```
will create a map under thing, with a key '0'

### Extra help description
From https://github.com/mikefarah/yq/pull/242
Thanks @georgicodes
