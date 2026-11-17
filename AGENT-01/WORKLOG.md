# AGENT-01 — WORKLOG

**Scope:** BootKC/SystemKC, KPI, UUID, simboli, ABI, architetture, dipendenze, procedura teorica.
**Mode:** read-only; no `kmutil create`, no boot, no `kextload`.
**Inputs:** T26 report, `T26-BOOTKC-DEPENDENCIES.csv`, `T26-SYSTEMKC-DEPENDENCIES.csv`, `T26-ABI-COMPATIBILITY.csv`, T23 kmutil requirements.
**Output:** `../T27-AGENT-01-KC.md`.
**Handoff:** Agent 08 must cross-check the 26B131-only requirement and the Boot→System dependency; no acceptance of 25G342 as target.
