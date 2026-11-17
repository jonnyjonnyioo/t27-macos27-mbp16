# T27 — AGENT-AMD — 9A48F0 IDENTITY

**Scope:** risolvere identità e architettura del target `0x9A48F0` raggiunto dal branch stub `0x10180`, verificando mapping VM/fileoff, segmento, immagine e validità del salto x86_64.

**Modalità:** sola lettura; SystemKC/BootKC, `__BRANCH_STUBS`, `__BRANCH_GOTS`, tabella segmenti, byte machine; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che `0x9A48F0` mappa a `__REGION19` fileoff `0x9998146`, dove i byte sono **zero**. **REFUTED** che sia codice x86_64 o ARM64. **UNPROVEN** il costruttore reale della superclass. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 120 | `7cae0e6cbda192c5ca5bccbd1e14198fc66d3a3541456b6a22a7c7c194c49db8` |
| Report 119 | `6bcea47b2b63d5d275ea97e11617426cb2adcb665ef889879ef8d06fc5cf7b1e` |

**PROVEN:** gli artefatti sono quelli indicati; 120 ha il banner di rettifica.

---

## 2. Mapping `0x9A48F0`

| Segmento | vmaddr | fileoff | filesize | Offset |
|---|---:|---:|---:|---:|
| `__PRELINK_INFO` | `0x3C000` | `0x245760` | `0x1359872` | `0x9688F0` |
| `__REGION12` | `0x2AA000` | `0x2793472` | `0x4157440` | `0x6FA8F0` |
| `__REGION18` | `0x6E7000` | `0x7237632` | `0x2740224` | `0x2BD8F0` |
| `__REGION19` | `0x984000` | `0x9977856` | `0x11550720` | `0x208F0` |

**PROVEN:** `0x9A48F0` cade in `__REGION19`.
**PROVEN:** il file offset è `0x9998146`.
**PROVEN:** i segmenti non sono lineari vmaddr=fileoff.

---

## 3. Byte corretti

```text
fileoff 0x9998146:
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

| Test | Esito |
|---|---|
| Codice x86_64 | **NO** |
| Codice ARM64 | **NO** |
| Zero-fill | **SÌ** |
| Funzione | **NO** |
| Simbolo | **NO** |

**PROVEN:** i byte sono zero.
**REFUTED:** codice x86_64/ARM64.
**UNPROVEN:** il contenuto runtime.

---

## 4. Errore precedente

| Report | Affermazione | Stato |
|---|---|---|
| 120 | byte ARM64 a `0x9A48F0` | **RITIRATA** |
| 120 | target non-x86_64 | **RITIRATA** |
| 120 | GOT target `0x9A48F0` | **PROVEN** |

**PROVEN:** l’ARM64 era letto a fileoff errato.
**PROVEN:** il target GOT è corretto.
**UNPROVEN:** l’esecuzione.

---

## 5. GOT `0x24200`

| Campo | Valore |
|---|---:|
| Raw | `0x400000009A48F0` |
| `target` | `0x9A48F0` |
| `cacheLevel` | `1` |
| Base L1 | **UNPROVEN** |
| Byte al target | **zero** |

**PROVEN:** il target è zero-filled.
**UNPROVEN:** la base L1.
**UNPROVEN:** la validità del salto.

---

## 6. Branch stub

```text
0x10180: FF 25 7A 40 01 00   jmp *0x1407A(%rip)
GOT:     0x24200
```

| Elemento | Valore |
|---|---:|
| Stub | `0x10180` |
| GOT | `0x24200` |
| Target | `0x9A48F0` |
| Codice | **NO** |

**PROVEN:** lo stub salta alla GOT.
**PROVEN:** il target è zero.
**UNPROVEN:** il costruttore.

---

## 7. Architettura

| Immagine | Formato | Target |
|---|---|---|
| SystemKC | Mach-O x86_64 | `__REGION19` zero |
| BootKC | Mach-O x86_64 | `0xFFFFFF80009A48F0` codice |
| Alias x86_64 | **possibile** | **UNPROVEN** |

**PROVEN:** SystemKC è x86_64.
**PROVEN:** il target SystemKC è zero.
**UNPROVEN:** un alias BootKC.

---

## 8. Implicazioni

| Domanda | Risposta |
|---|---|
| Salto valido | **UNPROVEN** |
| Costruttore superclass | **UNPROVEN** |
| `registerService` | **NO** |
| Pubblicazione | **UNPROVEN** |
| Matching | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `0x9A48F0` in `__REGION19` | **SÌ** |
| Fileoff | `0x9998146` |
| Byte | **zero** |
| Codice | **NO** |
| Architettura | **nessuna** |
| Costruttore superclass | **UNPROVEN** |
| Pubblicazione | **UNPROVEN** |
| Matching | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `0x9A48F0` mappa a `__REGION19` fileoff `0x9998146`, dove i byte sono tutti zero: non è codice x86_64 né ARM64. L’ARM64 del report 120 era un errore di mapping; il target GOT è corretto ma non eseguibile staticamente. Il costruttore reale della superclass, la pubblicazione di Interface e il matching X6000HWLibs restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
