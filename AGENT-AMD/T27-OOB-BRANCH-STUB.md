# T27 — AGENT-AMD — BRANCH STUB

> **RETTIFICA (Prompt 121):** `0x9A48F0` mappa a `__REGION19` fileoff `0x9998146`, dove i byte sono **zero**; l’ARM64 letto prima era un errore di mapping. Il target resta non-code e il costruttore superclass **UNPROVEN**. Vale il report 121.

**Scope:** identificare il target effettivo dello stub `0x10180`, ricostruire il meccanismo di chiamata e il codice condiviso della superclass, distinguendo costruzione, inizializzazione e pubblicazione.

**Modalità:** sola lettura; SystemKC/BootKC, `__BRANCH_STUBS`, `__BRANCH_GOTS`, disassemblaggio, byte machine; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che `0x10180` è uno stub in `__BRANCH_STUBS` con `jmp *0x1407A(%rip)` verso la GOT `0x24200`. **PROVEN** che la GOT contiene `0x9A48F0`, che non è codice x86_64. **UNPROVEN** il costruttore reale della superclass. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 119 | `2c62d1d2830207d125e6e09d5b31256d964966e38ac3051035f3d067783f5fc1` |
| Report 118 | `036b5b38783b6baa74b6988a57be9c2e15da789a2ba5566294916d5d339e51b9` |

**PROVEN:** gli artefatti sono quelli indicati; 118/119 hanno il banner di rettifica.

---

## 2. Mapping di `0x10180`

| Segmento | vmaddr | fileoff | filesize |
|---|---:|---:|---:|
| `__TEXT` | `0x0` | `0x0` | `0x10000` |
| `__BRANCH_STUBS` | `0x10000` | `0x10000` | `0x14000` |
| `__BRANCH_GOTS` | `0x24000` | `0x24000` | `0x18000` |

**PROVEN:** `0x10180` è in `__BRANCH_STUBS`.
**PROVEN:** non è in `__TEXT`.
**PROVEN:** è uno stub.

---

## 3. Byte dello stub

```text
0x10180: FF 25 7A 40 01 00   jmp *0x1407A(%rip)
0x10186: next
GOT:     0x10186 + 0x1407A = 0x24200
```

| Elemento | Valore |
|---|---:|
| Istruzione | `jmp *0x1407A(%rip)` |
| GOT | `0x24200` |
| Sezione GOT | `__BRANCH_GOTS` |
| Target | **UNPROVEN** |

**PROVEN:** è un branch stub.
**PROVEN:** la GOT è `0x24200`.
**PROVEN:** il target non è diretto.

---

## 4. GOT `0x24200`

| Offset | Raw | Target | `cacheLevel` |
|---:|---:|---:|---:|
| `0x24200` | `0x400000009A48F0` | `0x9A48F0` | `1` |

**PROVEN:** la GOT contiene `0x9A48F0`.
**PROVEN:** è un target L1.
**UNPROVEN:** il simbolo.

---

## 5. Byte a `0x9A48F0`

```text
05 00 40 96 1C 00 20 C4 03 00 00 96 30 00 00 CC ...
```

| Test | Esito |
|---|---|
| Codice x86_64 | **NO** |
| Codice ARM64 | **SÌ** |
| Funzione x86_64 | **NO** |
| Simbolo x86_64 | **NO** |
| Blob firmware | **SÌ** |

**PROVEN:** non è codice x86_64.
**PROVEN:** è codice ARM64.
**REFUTED:** il target x86_64.
**UNPROVEN:** lo stub corretto.

---

## 6. Call rel32

| Chiamante | Istruzione | Target |
|---|---|---:|
| X5000 `0x457C32C` | `callq 0x10180` | `0x10180` |
| X6000 `0xC26D27C` | `callq 0x10180` | `0x10180` |

**PROVEN:** entrambi chiamano lo stesso stub.
**PROVEN:** il target è lo stub, non il costruttore.
**UNPROVEN:** il costruttore.

---

## 7. Inizializzazione e pubblicazione

| Fase | Esito |
|---|---|
| Stub chiamato | **SÌ** |
| Vptr impostato | **SÌ** |
| Costruttore superclass | **UNPROVEN** |
| `registerService` | **NO** |
| Pubblicazione | **NO** |
| Pubblicazione differita | **UNPROVEN** |

**PROVEN:** costruzione e pubblicazione sono distinte.
**PROVEN:** il costruttore non pubblica.
**UNPROVEN:** lo stub/GOT.

---

## 8. X6000HWLibs

| Requisito | Valore |
|---|---|
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `LoadPlugIn=Load6000` |
| Interface completa | **SÌ** |
| Interface pubblicata | **UNPROVEN** |
| Matching | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `0x10180` | **branch stub** |
| GOT | `0x24200` |
| GOT target | `0x9A48F0` |
| Target x86_64 | **NO** |
| Costruttore superclass | **UNPROVEN** |
| Pubblicazione | **NO nel ctor** |
| Interface provider | **UNPROVEN** |
| Matching | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `0x10180` non è una funzione ma uno stub in `__BRANCH_STUBS`: `jmp *0x1407A(%rip)` verso la GOT `0x24200`, che contiene `0x9A48F0`. Quest’ultimo non è codice x86_64 (i byte sono ARM64) e non ha simbolo x86_64, quindi il costruttore reale della superclass resta **UNPROVEN**. I costruttori X5000/X6000 passano per lo stesso stub e impostano il vptr, ma non chiamano `registerService`; la pubblicazione e il matching X6000HWLibs restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
