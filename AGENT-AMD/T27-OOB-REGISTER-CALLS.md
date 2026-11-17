# T27 — AGENT-AMD — REGISTER CALLS

> **RETTIFICA (Prompt 110):** questo report ha decodificato la voce `0x5B0` come puntatore assoluto, ma il formato è `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` con entry da 4 byte. Con `cacheLevel 0` e base `0xFFFFFF8000100000`, il target è `0xFFFFFF8000A94C60` = **`IOService::registerService`**. Le conclusioni di questo report sono **SUPERATE**; vale il report 110.

**Scope:** verificare tutte le chiamate e i riferimenti a `IOService::registerService` in X6000HWServices; stabilire se Navi ha un percorso alternativo di pubblicazione o se la mancata chiamata ad `Abstract::start` impedisce la registrazione.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, vtable, symbol table, disassemblaggio; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che l’unico call site del dispatch `0x5B0` è `0xC26DA0D`. **PROVEN** che le vtable Navi/SWI/Abstract a `0x5B0` puntano a `0x994C60`, il cui simbolo più vicino è `_nxprov_close+0xE0`, **non** `IOService::registerService` (`0xA94C60`). **REFUTED** la conclusione precedente che `Abstract::start` chiami `registerService`. **UNPROVEN** la pubblicazione Navi. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 105 (pre-rettifica) | `c0185b2a997b57a999e0e19c17cb5bef65e555abde189238e3745fe28b5a6039` |
| Report 106 (pre-rettifica) | `72088185e8b97f7200f929716f792ee3b37fb88d738efcd17b6f8acd1d662cbd` |

**PROVEN:** gli artefatti sono quelli indicati; le copie 105/106 sono rettificate dal banner.

---

## 2. Call site `0x5B0`

| Evidenza | Valore |
|---|---|
| Unico call site | `0xC26DA0D` |
| Istruzione | `callq *0x5B0(%rax)` |
| Funzione | `Abstract::start` |
| Altri call site | **nessuno** |

**PROVEN:** c’è un solo uso del dispatch.
**PROVEN:** è in `Abstract::start`.

---

## 3. Vtable `0x5B0`

| Vtable | Slot | Raw | Target | Simbolo più vicino |
|---|---:|---:|---:|---|
| IOService | `0x2ADA80` | `0xFFFFFF8000A94C60` | `0xA94C60` | `IOService::registerService` |
| Navi | `0xC26F638` | `0x40000000994C60` | `0x994C60` | `_nxprov_close+0xE0` |
| SWI | `0xC26FFB8` | `0x40000000994C60` | `0x994C60` | `_nxprov_close+0xE0` |
| Abstract | `0xC2712B0` | `0x40000000994C60` | `0x994C60` | `_nxprov_close+0xE0` |

**PROVEN:** le tre vtable X6000 puntano a `0x994C60`.
**PROVEN:** `0x994C60` non è `0xA94C60`.
**REFUTED:** che Navi/SWI/Abstract usino `registerService` in `0x5B0`.

---

## 4. Byte a `0x994C60`

```text
6d 48 c7 43 28 00 00 00 00 4c 8b 7b 10 4d 85 ff 75 16 eb 4f ...
```

| Elemento | Esito |
|---|---|
| `jmp` a `0xA94C60` | **NO** |
| Thunk | **NO** |
| Codice `_nxprov_close` | **SÌ** |
| `registerService` | **NO** |

**PROVEN:** non è un thunk.
**PROVEN:** non è `registerService`.
**UNPROVEN:** il significato della voce.

---

## 5. Altre registrazioni

| Percorso | Esito |
|---|---|
| `registerService` diretto | **NO** |
| `registerService` via `0x5B0` | **NO, target diverso** |
| Callback/metaclass | **nessuna osservata** |
| Workloop | **nessuna osservata** |
| Provider | **nessuna registrazione osservata** |
| `newUserClient` | **non osservato** |

**PROVEN:** non ci sono altre chiamate.
**UNPROVEN:** registrazioni runtime fuori dal binario.

---

## 6. Personalità X6000HWLibs

| Requisito | Valore |
|---|---|
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `LoadPlugIn=Load6000` |
| Provider Navi | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| Matching | **UNPROVEN** |

**PROVEN:** i requisiti della personalità.
**UNPROVEN:** la loro soddisfazione.

---

## 7. Impatto su T27

| Domanda | Risposta |
|---|---|
| `Abstract::start` chiama `registerService` | **REFUTED** |
| `Navi` chiama `registerService` | **UNPROVEN** |
| `Navi` pubblica il servizio | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| `X6000HWLibs` matcha Navi | **UNPROVEN** |
| Runtime | **UNPROVEN** |

---

## 8. Classificazione

| Affermazione | Esito |
|---|---|
| Unico call site `0x5B0` | **PROVEN** |
| Target `0x5B0` X6000 | **`0x994C60`** |
| Target = `registerService` | **REFUTED** |
| Thunk | **REFUTED** |
| Chiamata Navi a `registerService` | **UNPROVEN** |
| Servizio Navi pubblicato | **UNPROVEN** |
| Matching HWLibs | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Call site `0x5B0` | **1, `0xC26DA0D`** |
| Target Navi/SWI/Abstract | **`0x994C60`** |
| Target IOService | **`0xA94C60`** |
| Coincidono | **NO** |
| `registerService` chiamato | **UNPROVEN** |
| Servizio Navi pubblicato | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** l’unico uso del dispatch `0x5B0` è `0xC26DA0D` in `Abstract::start`. Le vtable Navi/SWI/Abstract a `0x5B0` puntano a `0x994C60`, il cui simbolo più vicino è `_nxprov_close+0xE0`, **non** a `IOService::registerService` (`0xA94C60`); i byte a `0x994C60` non sono un thunk. La conclusione che `Abstract::start` chiami `registerService` è **REFUTED**; la chiamata di Navi a `registerService` e la pubblicazione del servizio restano **UNPROVEN**, così come il matching X6000HWLibs → Navi. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
