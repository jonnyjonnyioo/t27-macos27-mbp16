# T27 — macOS 27.2.1 (26B131) on MacBookPro16,1 / Navi14 / T2

Public, sanitized copy of the read-only work. No Apple binaries, IPSW contents, local paths or personal data.

Related issue: https://github.com/lythka/hao-patcher/issues/80

## Target

- MacBookPro16,1 (2019 16-inch)
- Intel Core i7-9750H
- Radeon Pro 5500M, Navi14, PCI `1002:7340`
- Apple T2
- Target OS: macOS 27.2.1 build 26B131
- Goal: boot to desktop

## Materials identified

- Kernel 26B131, x86_64, 21,128,776 bytes
  - SHA-256 `3c9317518535791503970fbec322b9bba70e91f3a233536205ccd77b047ffc83`
  - UUID `037E7B86-0AC8-3C67-AFB8-7C2C86435E9A`
- Donor 25G342 contains the six AMD X6000 kexts.
- `AMDRadeonX6000HWLibs` has no standalone executable in the donor; the binary was extracted from the 25G342 SystemKC:
  - 28,865,520 bytes
  - SHA-256 `a6a1040fef266bef6773b3c5df703a4e7bc8a84579d45104c5ab6b019224707f`
  - UUID `5CD4BC0C-C225-365F-A872-C885575B9A19`
- KDK 26B131 public mirror: https://github.com/dortania/KdkSupportPkg/releases/tag/26B131
  - `AppleGraphicsDeviceControl` is a plugin inside `AppleGraphicsControl.kext`, not a top-level kext.

## Static symbol result

Using kernel 26B131 + the five KDK providers + `AppleGraphicsDeviceControl` 26B131 + the six AMD 25G342 kexts + HWLibs 25G342:

| Component | Unresolved |
|---|---:|
| `AMDSupport` | 0 |
| `AMDFramebuffer` | 0 |
| `AMDRadeonServiceManager` | 0 |
| `AMDRadeonX6000Framebuffer` | 0 |
| `AMDRadeonX6000HWServices` | 0 |
| `AMDRadeonX6000HWLibs` | 0 |
| `AMDRadeonX6000` | **1 of 1,171** |

Missing symbol:

```text
__ZN26AMDRadeonX6000_AMDHardware25decrementInternalRefCountEj
AMDRadeonX6000_AMDHardware::decrementInternalRefCount(unsigned int)
```

No local provider defines it. The KDK 26B131 contains no AMD kexts.

## Public search

- No public report of 26B131 on MacBookPro16,1 or with Navi14 was found.
- `hao-patcher` demonstrates 26B131 on MacBookPro9,2 with Intel HD 4000; it is author-claimed, without independent replication, and other Intel Macs are untested.
- OCLP states it has no macOS 27 plans; MacBookPro16,1 is dropped, and T2 is already unstable on Tahoe.
- No public patch, stub or reimplementation of the missing symbol was found.

## Status

Read-only. No boot, build, download, installation or system modification. T27 remains OPEN.

## Request for help

If anyone has a working X6000/Navi14 path for macOS 26/27, T2 bring-up experience, or knows where `decrementInternalRefCount` is supposed to come from, please reply on issue #80 or point to a project/commit. Sanitized logs and test results are available; Apple binaries will not be shared.
