# AGENT-05 — WORKLOG

**Scope:** BCE, VHCI, USB, tastiera, trackpad, AppleUSBTopCaseDriver, AppleTopCaseHIDEventDriver, audio, componenti x86_64; input interno vs USB esterno.
**Mode:** read-only; no boot, no kextload, no USB test.
**Inputs:** T25 T2/HID, T26 system matrix, root2 inventory.
**Output:** `../T27-AGENT-05-T2-HID.md`.
**Handoff:** Agent 08 must not use external USB input or Linux T2 support as proof of internal macOS input.
