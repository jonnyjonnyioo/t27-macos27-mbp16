# T27 — AGENT-AMD — CHAINED VTABLE FORMAT

> **RETTIFICA (Prompt 126):** `0x5B0 = registerService` vale per la vtable **Interface** (`0xC270388`), non per Navi. Nella vtable Navi (`0xC26F078`) `0x5B0` è `IOService::_RESERVEDIOService47` e `registerService` è `0x5C0`. Gli offset degli slot sono specifici della classe.

**Scope:** determinare il formato effettivo delle vtable X6000, decodificare correttamente `0x5B0` senza assumere puntatori assoluti, confrontare Navi/SWI/Abstract con IOService e identificare il target reale.

**Modalità:** sola lettura; SystemKC/BootKC, `LC_DYLD_CHAINED_FIXUPS`, parsers, symbol table; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che il formato è `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` (11), con entry da **4 byte** e `cacheLevel`. **PROVEN** che `0x5B0` ha `cacheLevel 0` e target `0x994C60`; con base livello 0 `0xFFFFFF8000100000` il target reale è **`0xFFFFFF8000A94C60` = `IOService::registerService`**. **REFUTED** la decodifica assoluta dei report 107–109. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 107 | `bac68d5031dc41b979599371eb7425ae9044d4af43152f2cb313defdb6d3f601` |
| Report 108 | `60ceab2365146e5c2667dbb6e08b231d424ccfe5fbf4c850f757493df1d9aab8` |
| Report 109 | `0ecb6e7b3674d6d68fdddfa723683b880ed70bfc74c75308aae949f56bb1f7f6` |

**PROVEN:** gli artefatti sono quelli indicati; 107–109 hanno il banner di rettifica.

---

## 2. `LC_DYLD_CHAINED_FIXUPS`

| Campo | Valore |
|---|---:|
| `dataoff` | `369144570` |
| `datasize` | `108` |
| `fixups_version` | `0` |
| `starts_offset` | `28` |
| `imports_offset` | `108` |
| `symbols_offset` | `108` |
| `imports_count` | `0` |
| `imports_format` | `1` |
| `symbols_format` | `0` |

**PROVEN:** il fileset ha chained fixups.
**PROVEN:** non ci sono import.
**PROVEN:** il formato è solo rebase.

---

## 3. Segmenti e formato

| Segmento | `pointer_format` | `segment_offset` | Pagine | `page_start` |
|---|---:|---:|---:|---|
| `__DATA` | `11` | `0x3000` | `3` | `0`, `0`, `0` |
| `__DATA_CONST` | `11` | `0x6000` | `1` | `0x10` |

**PROVEN:** `pointer_format=11` = `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`.
**PROVEN:** entry da **4 byte**.
**PROVEN:** il lettore da 8 byte univa due entry.

---

## 4. Formato entry

```text
bit  0..29   target
bit 30..31   cacheLevel
```

| Campo | Bits |
|---|---:|
| `target` | `0..29` |
| `cacheLevel` | `30..31` |
| dimensione | `4` byte |

**PROVEN:** la voce non è un puntatore assoluto a 64 bit.
**PROVEN:** `cacheLevel` distingue i livelli di cache.

---

## 5. Basi di decodifica

| `cacheLevel` | Base | Fonte |
|---:|---:|---|
| `0` | `0xFFFFFF8000100000` | `__HIB` BootKC |
| `1` | indirizzo VM nella collezione | fileset |

**PROVEN:** `0xFFFFFF8000100000 + 0x994C60 = 0xFFFFFF8000A94C60`.
**PROVEN:** `0xFFFFFF8000A94C60` è `IOService::registerService`.
**PROVEN:** `cacheLevel 1` restituisce direttamente l’indirizzo del metodo.

---

## 6. Voci decodificate

| Vtable | Slot | Raw 4 byte | Target | `cacheLevel` | Indirizzo reale | Simbolo |
|---|---:|---:|---:|---:|---:|---|
| Navi | `0x5B0` | `0x994C60` | `0x994C60` | `0` | `0xFFFFFF8000A94C60` | `registerService` |
| SWI | `0x5B0` | `0x994C60` | `0x994C60` | `0` | `0xFFFFFF8000A94C60` | `registerService` |
| Abstract | `0x5B0` | `0x994C60` | `0x994C60` | `0` | `0xFFFFFF8000A94C60` | `registerService` |
| Navi | `0x5B8` | `0x4C26D650` | `0xC26D650` | `1` | `0xC26D650` | `Abstract::probe` |
| Navi | `0x5C0` | `0x4C26CFF0` | `0xC26CFF0` | `1` | `0xC26CFF0` | `SWI::start` |
| Abstract | `0x5C0` | `0x4C26D8C0` | `0xC26D8C0` | `1` | `0xC26D8C0` | `Abstract::start` |

**PROVEN:** `0x5B0` è `registerService`.
**PROVEN:** `start`/`probe` sono corretti.
**PROVEN:** la decodifica assoluta era invalida.

---

## 7. Perché `0x994C60` sembrava mid-instruction

| Test | Esito |
|---|---|
| `0x994C60` in BootKC | secondo byte di `jne` a `0x994C5F` |
| `0x994C60` come target vtable | **offset livello 0** |
| `0x994C60 + 0xFFFFFF8000100000` | `0xA94C60` |
| Byte a `0xA94C60` | `registerService` |
| Byte a `0x994C60` | non-entry |

**PROVEN:** l’offset non è un indirizzo.
**PROVEN:** l’indirizzo reale è `0xA94C60`.
**REFUTED:** l’ipotesi “non è una funzione”.

---

## 8. Conseguenze

| Domanda | Risposta |
|---|---|
| `Abstract::start` chiama `registerService` | **SÌ, PROVEN** |
| `Navi` usa `Abstract::start` | **NO** |
| `Navi` chiama `registerService` | **UNPROVEN** |
| `Navi` pubblica il servizio | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| Runtime | **UNPROVEN** |

---

## 9. Conclusioni rettificate

| Conclusione | Stato |
|---|---|
| `0x5B0` non è `registerService` | **RITIRATA** |
| `Abstract::start` non chiama `registerService` | **RITIRATA** |
| `0x994C60` non è una funzione | **RITIRATA** |
| `0x5B0` è `registerService` | **PROVEN** |
| `Abstract::start` chiama `registerService` | **PROVEN** |

**PROVEN:** le rettifiche 107–109 sono superate.
**PROVEN:** la conclusione 105/106 era corretta nel merito.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| Formato | **`DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`** |
| Entry | **4 byte** |
| `0x5B0` | **`registerService`** |
| `Abstract::start` | **chiama `registerService`** |
| `Navi` | **usa `SWI::start`** |
| Pubblicazione Navi | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** le vtable X6000 usano `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`, entry da 4 byte con `target` e `cacheLevel`. `0x5B0` ha `cacheLevel 0` e target `0x994C60`; con base `0xFFFFFF8000100000` il target reale è `0xFFFFFF8000A94C60`, cioè **`IOService::registerService`**. `Abstract::start` chiama quindi `registerService`; Navi usa `SWI::start` e non `Abstract::start`, perciò la pubblicazione del servizio Navi e il matching X6000HWLibs → Navi restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
