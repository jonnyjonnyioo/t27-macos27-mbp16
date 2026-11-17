# T27 — AGENT-AMD — REGISTER DISCREPANCY

> **RETTIFICA (Prompt 110):** questo report ha decodificato la voce `0x5B0` come puntatore assoluto, ma il formato è `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` con entry da 4 byte. Con `cacheLevel 0` e base `0xFFFFFF8000100000`, il target è `0xFFFFFF8000A94C60` = **`IOService::registerService`**. Le conclusioni di questo report sono **SUPERATE**; vale il report 110.

**Scope:** verificare la discrepanza tra `IOService::registerService` (`0xA94C60`) e `_nxprov_close+0xE0` (`0x994C60`), identificare la destinazione reale del dispatch `0x5B0`, analizzare le vtable complete e stabilire quali conclusioni ritirare.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, vtable, symbol table, segmenti; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che `0x5B0` di IOService punta a `0xA94C60` (`registerService`) e che `0x5B0` di Navi/SWI/Abstract punta a `0x994C60` (`_nxprov_close+0xE0`), senza thunk. **REFUTED** la conclusione che `Abstract::start` chiami `registerService`. **UNPROVEN** la pubblicazione Navi. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 105 (rettificato) | `57fd278a4911b9b2ef4450b4b3593ffb475d7d037df1d4b475bbc03615ee478c` |
| Report 106 (rettificato) | `f594411a897e596ae3756c046bf47fdfaef3839cf9793bc50060b016fc18ed49` |
| Report 107 | `bac68d5031dc41b979599371eb7425ae9044d4af43152f2cb313defdb6d3f601` |

**PROVEN:** gli artefatti sono quelli indicati; 105/106 hanno il banner di rettifica.

---

## 2. Segmenti BootKC

| Segmento | vmaddr | fileoff |
|---|---:|---:|
| `__TEXT` | `0xFFFFFF8000200000` | `0x0` |
| `__DATA_CONST` | `0xFFFFFF8000210000` | `0x10000` |
| `__TEXT_EXEC` | `0xFFFFFF80002E8000` | `0xE8000` |
| `__DATA` | `0xFFFFFF8001150000` | `0xF50000` |
| `__LINKEDIT` | `0xFFFFFF8003404000` | `0x3304000` |

**PROVEN:** la lettura di `0x994C60` avviene in `__TEXT_EXEC`.
**PROVEN:** la lettura delle vtable avviene in `__DATA_CONST`.

---

## 3. Slot `0x5B0`, `0x5B8`, `0x5C0`

| Vtable | `0x5B0` | `0x5B8` | `0x5C0` |
|---|---|---|---|
| IOService | `0xA94C60` `registerService` | `0xA94E60` `probe` | `0xA94E70` `start` |
| Navi | `0x994C60` `_nxprov_close+0xE0` | `0x4C26D650` `Abstract::probe` | `0x4C26CFF0` `SWI::start` |
| SWI | `0x994C60` `_nxprov_close+0xE0` | `0x4C26D650` `Abstract::probe` | `0x4C26CFF0` `SWI::start` |
| Abstract | `0x994C60` `_nxprov_close+0xE0` | `0x4C26D650` `Abstract::probe` | `0x4C26D8C0` `Abstract::start` |

**PROVEN:** `probe` e `start` occupano gli stessi slot tra IOService e X6000.
**PROVEN:** il target di `0x5B0` **non** coincide.
**PROVEN:** non è uno shift uniforme.
**UNPROVEN:** la causa della differenza.

---

## 4. Byte a `0x994C60`

```text
6d 48 c7 43 28 00 00 00 00 4c 8b 7b 10 4d 85 ff 75 16 eb 4f ...
```

| Test | Esito |
|---|---|
| `jmp` a `0xA94C60` | **NO** |
| `jmp *rip` | **NO** |
| Thunk | **NO** |
| `_nxprov_close` | **SÌ** |
| `registerService` | **NO** |

**PROVEN:** non è un thunk.
**PROVEN:** non è `registerService`.
**UNPROVEN:** perché la vtable X6000 lo usi.

---

## 5. Riferimenti a `registerService`

| Riferimento | Esito |
|---|---|
| Simbolo in BootKC | `0xFFFFFF8000A94C60` |
| Voce vtable IOService | **SÌ** |
| Chiamate dirette in X6000 | **NO** |
| Import in SystemKC | **SÌ, `U`** |
| Altre voci X6000 | **NO** |

**PROVEN:** l’unico riferimento noto è la voce IOService.
**PROVEN:** X6000 non ha una chiamata diretta.

---

## 6. Vtable complete

| Vtable | Base | `start` | `probe` | `0x5B0` |
|---|---|---:|---:|---:|
| IOService | `0xFFFFFF80002AD4C0` | `0xA94E70` | `0xA94E60` | `0xA94C60` |
| Navi | `0xC26F078` | `0x4C26CFF0` | `0x4C26D650` | `0x994C60` |
| SWI | `0xC26F9F8` | `0x4C26CFF0` | `0x4C26D650` | `0x994C60` |
| Abstract | `0xC270CF0` | `0x4C26D8C0` | `0x4C26D650` | `0x994C60` |

**PROVEN:** le vtable X6000 sono coerenti su `start`/`probe`.
**PROVEN:** sono incoerenti su `0x5B0`.
**UNPROVEN:** la causa.

---

## 7. Conclusioni ritirate

| Conclusione | Stato |
|---|---|
| `0x5B0` è sempre `registerService` | **RITIRATA** |
| `Abstract::start` chiama `registerService` | **RITIRATA** |
| `registerService` è l’unico modo di pubblicare | **RITIRATA** |
| `Navi` pubblica il servizio | **UNPROVEN** |
| `Navi → X6000HWLibs` matcha | **UNPROVEN** |

**PROVEN:** le prime tre non sono sostenibili.
**PROVEN:** restano solo come ipotesi.

---

## 8. Conseguenze

| Domanda | Risposta |
|---|---|
| `Abstract::start` pubblica | **UNPROVEN** |
| `Navi` pubblica | **UNPROVEN** |
| `SWI::start` pubblica | **UNPROVEN** |
| `registerService` usato | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| Matching | **UNPROVEN** |
| Runtime | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `0x994C60` = `0xA94C60` | **NO** |
| Thunk | **NO** |
| Shift uniforme | **NO** |
| `Abstract::start` → `registerService` | **REFUTED** |
| Pubblicazione Navi | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `IOService` usa `0x5B0 → 0xA94C60` (`registerService`), ma Navi/SWI/Abstract usano `0x5B0 → 0x994C60` (`_nxprov_close+0xE0`); `0x994C60` non è un thunk e non è `registerService`. La conclusione che `Abstract::start` chiami `registerService` è **REFUTED**, e con essa cade l’ipotesi che `0x5B0` sia sempre `registerService`. La pubblicazione del servizio Navi e il matching X6000HWLibs → Navi restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
