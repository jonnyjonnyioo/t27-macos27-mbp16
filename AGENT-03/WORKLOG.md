# AGENT-03 — WORKLOG

**Scope:** ACPI, APIC, IOPCIFamily, IOACPIFamily, PCI, VT-d, storage/APFS, dipendenze di launchd, specificità MacBookPro16,1.
**Mode:** read-only; no boot, no kextload, no EFI/NVRAM changes.
**Inputs:** T26 system/boot matrices, T25 boot dependencies, T24 target inventory.
**Output:** `../T27-AGENT-03-ACPI-BOOT.md`.
**Handoff:** Agent 08 must keep VT-d/DMAR as UNPROVEN unless a local AppleVTD/DMAR inspection exists.
