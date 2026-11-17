# AGENT-06 — WORKLOG

**Scope:** OpenCore, boot.efi, SMBIOS nativo, T2 Secure Boot, NVRAM, catena di boot.
**Mode:** read-only; no EFI/NVRAM/T2/SIP/AMFI changes, no boot.
**Inputs:** T26 boot assets, T25 desktop/boot references, HAO/OCLP pins.
**Output:** `../T27-AGENT-06-EFI.md`.
**Handoff:** Agent 08 must keep OpenCore/SMBIOS/T2 Secure Boot/NVRAM as UNPROVEN and avoid any EFI write.
