# Restore and reuse

This repository is self-contained. Nothing else is needed to get back a working
copy of the T27 research, and nothing here depends on the machine it came from.

## Restore the archive

```sh
git clone https://github.com/jonnyjonnyioo/t27-macos27-mbp16
cd t27-macos27-mbp16
TOOLS/verify.sh
```

`git clone` returns the exact bytes that were published. `TOOLS/verify.sh`
re-hashes every file against `MANIFEST-PUBLIC.sha256` and exits 0 only when all
of them match. That is the check that makes it safe to delete the local copy.

## Rebuild the public tree from the private source

Only needed if the private `T27/` tree still exists and the sanitized copy has
to be derived again:

```sh
TOOLS/rebuild-public.sh /path/to/private/T27 /tmp/t27-rebuild
```

The script reads `MANIFEST-PUBLIC.sha256`, copies each path from the private
tree, applies the placeholder substitution, and compares the result with the
recorded hash. It prints `identical=` / `differing=` / `missing_source=` and
names every file that does not reproduce exactly. Against the private tree this
archive was derived from, it reports `identical=336 differing=0`, so the
substitution rules below are the complete recipe. `AGENT-AMD/qwen-loop.sh` is
taken from the repository itself because it was made path-independent by hand at
publication time; the rest is re-derived from the private copy.

Placeholder map:

| Original local path | Placeholder |
| --- | --- |
| `/Users/IMAC/Desktop/HAO-PROJECT` | `<PROJECT_ROOT>` |
| `/Users/IMAC/Desktop` | `<DESKTOP>` |
| `/Users/IMAC` | `<HOME>` |
| `/private/tmp/hao91-sys27` | `<TARGET_ROOT>` |
| `/private/tmp/hao93-kdk25` | `<DONOR_VOLUME>` |
| other `/private/tmp/*` | `<TMP>` |
| `/Volumes/msu-target-X87eLfva` | `<VOLUME>` |
| other `/Volumes/*` | `<VOLUME>` |
| `SESSION-HAO-*` | `<SESSION>` |

## What is here and what is not

Included: every T27 report, worklog, matrix, blocklist, script and manifest
(231 artifacts), plus 100 raw analysis tables — export lists, `unresolved`
lists, symbol and path tables — under `AGENT-AMD/evidence/`. Those tables are
the data behind the one-symbol claim, so anyone can re-check it without owning
the Apple binaries. `EXCLUDED-FILES.tsv` inventories the 164 files that were
withheld — path, size, SHA-256 and category — so the record of what existed
survives even if the private tree is deleted.

Not included, by design:

- Apple binaries: kexts, `dylib`, kernel collections, KDK contents, IPSW or
  installer payloads. Redistributing them is not something this archive does.
- `disasm` / `compact` listings and raw `.bin` captures cut from Apple code.
- The 112 GB of local session data, logs and the rest of the 432 MB `.tmp`
  extraction tree.

So a rebuild from the private tree restores the *published* subset only. The
disassembly and binaries exist nowhere else: if the private tree is deleted,
they are gone. That is the one irreversible loss, and it is a deliberate trade,
not an oversight.

## Before deleting the local copy

1. `git clone` the repository somewhere outside the folder you are about to
   delete.
2. Run `TOOLS/verify.sh` inside the clone; it must report `failed=0`.
3. Check `git -C <clone> log --oneline -1` matches the commit you published.
4. Only then delete `HAO-PROJECT/T27-PUBLIC`, and `HAO-PROJECT/T27` if you also
   accept losing the binaries and disassembly.

The published issue and gist are independent of the local files:

- Issue: https://github.com/lythka/hao-patcher/issues/80
- Gist: https://gist.github.com/jonnyjonnyioo/5660a323faf1e1c57c3abad7928f9b6a
