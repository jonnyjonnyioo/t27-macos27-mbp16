# T27 — macOS 27.2.1 (26B131) on MacBookPro16,1

**Status: OPEN / research archive. No working installer, no successful boot, no desktop.**

This repository is a sanitized public copy of the T27 engineering research for running macOS 27.2.1 build **26B131** on a **MacBookPro16,1** (2019 16-inch Intel, i7-9750H, Radeon Pro 5500M Navi14, Apple T2).

The work was **read-only**: no boot, trace, build, download, installation, NVRAM/T2 change or system modification was performed.

## Why this is public

The immediate blocker is narrow and testable: the AMD X6000 stack resolves statically except for one symbol. The purpose of publishing the archive is to let people with direct Navi14/T2 or kernel-collection experience inspect the evidence, reproduce the checks and point to a fix or a better donor.

- Related issue: https://github.com/lythka/hao-patcher/issues/80
- Short public dossier: https://gist.github.com/jonnyjonnyioo/5660a323faf1e1c57c3abad7928f9b6a

## What is included

This archive contains **231 T27 text artifacts**: reports, worklogs, dependency matrices, blocklists, symbol tables, hashes and helper scripts. `AGENT-AMD/evidence/` adds **100 raw analysis tables** — export lists, `unresolved` lists, symbol and path tables — so the one-symbol result can be re-checked without owning the Apple binaries. With this README, `RESTORE.md`, two helper scripts, `.gitignore` and the public checksum manifest, the repository has 337 files.

Start with:

- `T27-REPORT.md` — executive result and blockers
- `T27-INSTALLATION-ROADMAP.md` — the gated 10-phase procedure that was **not executed**
- `AGENT-AMD/T27-PUBLIC-DOSSIER.md` — short public summary
- `AGENT-AMD/T27-PROVIDERS-26B131.md` — provider/symbol coverage
- `AGENT-AMD/T27-DONOR-COMPAT.md` — 25G342 donor compatibility
- `AGENT-AMD/T27-REDEFINITION.md` — why the read-only phase was closed
- `AGENT-AMD/evidence/` — raw export/unresolved/symbol tables behind the result
- `RESTORE.md` — how to restore this archive and what a rebuild can and cannot recover

## Result in one screen

- Kernel 26B131: x86_64, 21,128,776 bytes, SHA-256 `3c9317518535791503970fbec322b9bba70e91f3a233536205ccd77b047ffc83`, UUID `037E7B86-0AC8-3C67-AFB8-7C2C86435E9A`.
- Donor 25G342: six AMD X6000 kexts. `AMDRadeonX6000HWLibs` has no standalone executable in the donor; its binary was extracted from the 25G342 SystemKC (28,865,520 bytes, SHA-256 `a6a1040fef266bef6773b3c5df703a4e7bc8a84579d45104c5ab6b019224707f`).
- Static symbol check: `AMDSupport`, `AMDFramebuffer`, `AMDRadeonServiceManager`, `AMDRadeonX6000Framebuffer`, `AMDRadeonX6000HWServices` and `AMDRadeonX6000HWLibs` resolve with **0 unresolved symbols** when checked against the local 26B131 providers. `AMDRadeonX6000` has **1 unresolved out of 1,171**:

```text
__ZN26AMDRadeonX6000_AMDHardware25decrementInternalRefCountEj
AMDRadeonX6000_AMDHardware::decrementInternalRefCount(unsigned int)
```

- No public report, patch or reimplementation of that symbol was found. No local provider defines it.
- Remaining blockers also include missing complete 26B131 BootKC/SystemKC, missing 26B131 AMD kexts, T2 VHCI/BCE, boot.efi and a hardware test.

## What is deliberately not included

- Apple binaries, kernel caches, KDK contents, IPSW/installer payloads, `.dmg`/`.zip` files.
- Disassembly and `.compact` listings, raw `.bin` captures cut from Apple code, and the 112 GB of local session data.
- The rest of the 432 MB `.tmp` tree: its analysis tables are published, its binaries are not.
- Local paths, machine names, session identifiers, account emails and other personal data.

Local paths in the published reports were replaced with placeholders such as `<PROJECT_ROOT>`, `<TARGET_ROOT>`, `<DONOR_VOLUME>`, `<SESSION>` and `<VOLUME>`. The `*.sha256` files that shipped with individual reports refer to the **pre-sanitization** local versions; `MANIFEST-PUBLIC.sha256` is the checksum manifest for this public copy.

## Restore and reuse

`git clone` returns the published bytes exactly; `TOOLS/verify.sh` re-hashes all of them against `MANIFEST-PUBLIC.sha256` and exits 0 only when nothing is missing or changed. `TOOLS/rebuild-public.sh` re-derives the sanitized tree from a private T27 copy and reports any file that does not reproduce exactly. See `RESTORE.md` for the placeholder map, what a rebuild can recover and what is lost for good once the private tree is deleted.

## Important limitation

This repository is evidence and a research log, not a supported installer or a promise that macOS 27 can run on this machine. macOS 27 has no Intel support from Apple. Attempting a bring-up on a production machine can cause data loss or an unbootable system; use an isolated volume and a verified rollback.

## License / use

No license is granted for Apple's binaries or other third-party material, because none are included. The original T27 text is published for inspection and collaboration.
