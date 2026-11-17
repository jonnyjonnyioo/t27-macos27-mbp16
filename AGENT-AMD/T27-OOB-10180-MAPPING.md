# T27 — AGENT-AMD — 10180 MAPPING

> **RETTIFICA (Prompt 120):** `0x10180` è uno stub in `__BRANCH_STUBS` (`jmp *0x1407A(%rip)`) verso la GOT `0x24200`, non una funzione. La GOT porta a `0x9A48F0`, che non è codice x86_64. Vale il report 120.

**Scope:** identificare il codice condiviso raggiunto tramite lo stub `0x10180`, ricostruire il mapping nella Kernel Collection, cercare riferimenti a `0x12AA488` e distinguere costruzione, inizializzazione e pubblicazione.

**Modalità:** sola lettura; fileset X5000/X6000, SystemKC/BootKC, chained fixups, disassemblaggio; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che `0x10180` è fuori dai segmenti estratti e non è risolvibile con i metadati disponibili; **PROVEN** che i costruttori chiamano lo stub e impostano il vptr senza `registerService`. **UNPROVEN** il codice raggiunto e la superclass. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 118 | `036b5b38783b6baa74b6988a57be9c2e15da789a2ba5566294916d5d339e51b9` |
| Report 117 | `04d67a09aad5a019651bebe6d0ad61350460c60f80eabb239d6baf3fa099919a` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Mapping `0x10180`

| Test | Esito |
|---|---|
| Range X5000 (`0x457B000`–`0x4582000`) | **NO** |
| Range X6000 (`0xC26C000`–`0xC273000`) | **NO** |
| Simbolo | **nessuno** |
| Sezione | **UNPROVEN** |
| Chained fixup | **NO** |
| Call rel32 | **SÌ, due** |

**PROVEN:** è fuori dai segmenti.
**PROVEN:** non è un chained pointer.
**UNPROVEN:** il codice raggiunto.

---

## 3. Chiamata nei costruttori

```text
X5000 0x457C32C: callq 0x10180
X6000 0xC26D27C: callq 0x10180
```

| Contesto | X5000 | X6000 |
|---|---|---|
| Precedente | carica `this`, `metaClass` | carica `this`, `metaClass` |
| Chiamata | `0x10180` | `0x10180` |
| Successiva | vptr `0x457F380` | vptr `0xC270388` |
| `registerService` | **NO** | **NO** |

**PROVEN:** la sequenza è identica.
**PROVEN:** lo stub è chiamato prima del vptr.
**UNPROVEN:** cosa fa lo stub.

---

## 4. Riferimenti a `0x12AA488`

| Posizione | Tipo | Valore |
|---|---|---:|
| X5000 `0x457F368` | `superClass` | `0xC00000012AA488` |
| X6000 `0xC270370` | `superClass` | `0xC00000012AA488` |
| X5000 offset `0x3018` | dato | `0x12AA488` |
| X6000 offset `0x3018` | dato | `0x12AA488` |
| Code xref | **NO** | — |

**PROVEN:** solo campi dati.
**PROVEN:** nessuna xref di codice.
**UNPROVEN:** il significato di `0x3018`.

---

## 5. Registrazione

| Percorso | Esito |
|---|---|
| `registerService` nei ctor | **NO** |
| `registerService` nello stub | **UNPROVEN** |
| Callback nel ctor | **NO** |
| Pubblicazione nel ctor | **NO** |
| Pubblicazione differita | **UNPROVEN** |

**PROVEN:** il costruttore non pubblica.
**UNPROVEN:** lo stub.

---

## 6. Separazione

| Fase | Evidenza |
|---|---|
| Costruzione superclass | **chiamata stub** |
| Inizializzazione vptr | **PROVEN** |
| Registrazione IOKit | **NO** |
| Pubblicazione servizio | **UNPROVEN** |
| Matching | **UNPROVEN** |

**PROVEN:** costruzione e pubblicazione sono distinte.
**PROVEN:** la prima non implica la seconda.

---

## 7. X6000HWLibs

| Requisito | Valore |
|---|---|
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `LoadPlugIn=Load6000` |
| Interface completa | **SÌ** |
| Interface pubblicata | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| Matching | **UNPROVEN** |

---

## 8. Classificazione

| Affermazione | Esito |
|---|---|
| `0x10180` mappato | **NO** |
| Stub condiviso | **SÌ** |
| Superclass costruita | **PROVEN strutturale** |
| Superclass identificata | **UNPROVEN** |
| Registrazione nel ctor | **NO** |
| Pubblicazione | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `0x10180` risolto | **NO** |
| Fuori segmenti | **SÌ** |
| Chained fixup | **NO** |
| Xref `0x12AA488` di codice | **NO** |
| Costruzione superclass | **SÌ** |
| Pubblicazione | **NO** |
| Interface provider | **UNPROVEN** |
| Matching | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `0x10180` è fuori dai segmenti X5000/X6000, non ha simbolo e non è un chained pointer; i costruttori lo chiamano prima di impostare il vptr, quindi la superclass è costruita ma il codice raggiunto resta **UNPROVEN**. `0x12AA488` compare solo nei campi `superClass` e in un dato a offset `0x3018`, senza xref di codice. I costruttori non chiamano `registerService`; la pubblicazione resta **UNPROVEN**, così come il matching X6000HWLibs. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
