# T27 — AGENT-AMD — L3 BASE SEARCH

**Scope:** ricostruire la mappatura L3 di `0x12AA488` senza assumere indirizzi VM top-level, esaminare le regioni sovrapposte, confrontare le occorrenze del raw e cercare una base L3 indipendente.

**Modalità:** sola lettura; SystemKC/BootKC, segmenti, occorrenze, metadati; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che `0xC00000012AA488` compare **155** volte in SystemKC e **186** in BootKC, sempre identico, e che non esiste una base L3 nei metadati dyld. **UNPROVEN** la base e l’identità del target. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 123 | `fa1836f7633328d758643f9394ec368a669a5cf1f09cb9a5ac770449e120ea28` |
| Report 122 | `addfb50e9d1e628c0ccf922babfde2ad7b3f3a12bab3b4c979dcdcba0db9dbae` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Occorrenze

| Immagine | Occorrenze |
|---|---:|
| SystemKC | **155** |
| BootKC | **186** |

Primi offset SystemKC:

```text
0x29FCE0 0x2A70A8 0x2A7A38 0x2A8398
0x6E39E8 0x9840B8 0x15D6058 0x23700B8
0x34B60B8 0x457F368
```

**PROVEN:** il valore è ripetuto.
**PROVEN:** non è specifico di Interface.
**PROVEN:** è un `superClass` condiviso.

---

## 3. Contesti

| Offset | Segmento | Byte |
|---:|---|---|
| `0x29FCE0` | `__PRELINK_INFO` | `88 A4 2A 01 00 00 C0 00` |
| `0x2A70A8` | `__PRELINK_INFO` | `88 A4 2A 01 00 00 C0 00` |
| `0x6E39E8` | `__PRELINK_INFO` | `88 A4 2A 01 00 00 C0 00` |
| `0x9840B8` | `__PRELINK_INFO` | `88 A4 2A 01 00 00 C0 00` |
| `0x34B60B8` | `__REGION12` | `88 A4 2A 01 00 00 C0 00` |
| `0x457F368` | `__REGION12` | `88 A4 2A 01 00 00 C0 00` |
| `0xA896408` | `__REGION19` | `88 A4 2A 01 00 00 C0 00` |
| `0xC270370` | `__REGION19` | `88 A4 2A 01 00 00 C0 00` |

**PROVEN:** il raw è sempre lo stesso.
**PROVEN:** i segmenti sono diversi.
**UNPROVEN:** il mapping corretto.

---

## 4. Basi candidate

| Base | Target risultante | Esito |
|---:|---:|---|
| `0x0` | `0x12AA488` | ambiguo |
| `0x3C000` | `0x12E6488` | dentro `__PRELINK_INFO` |
| `0x2AA000` | `0x1554488` | dentro `__REGION12` |
| `0x6E7000` | `0x1991488` | dentro `__REGION18` |
| `0x984000` | `0x1C2E488` | fuori `__REGION19` |
| `0xFFFFFF8000100000` | `0xFFFFFF80012AA488` | kernel space |
| `0xFFFFFF8000200000` | `0xFFFFFF80014AA488` | kernel space |

**PROVEN:** nessuna base è indicata dai metadati.
**PROVEN:** i risultati sono incompatibili.
**UNPROVEN:** la base corretta.

---

## 5. Metadati

| Fonte | Base L3 |
|---|---|
| `LC_DYLD_CHAINED_FIXUPS` | **NO** |
| `starts_offset` | **NO** |
| `imports_count=0` | **NO** |
| `__PRELINK_INFO` | **NO** |
| `__BRANCH_GOTS` | **NO** |

**PROVEN:** il formato non memorizza la base.
**PROVEN:** non esiste una tabella di traduzione.
**UNPROVEN:** la base runtime.

---

## 6. Trasformazioni comuni

| Test | Esito |
|---|---|
| `target & 0x3FFFFFFF` | **0x12AA488** |
| `cacheLevel` | **3** |
| `isAuth` | **0** |
| `next` | **0** |
| Base nota | **NO** |
| Offset negativo | **NO** |

**PROVEN:** il campo è un target L3 puro.
**PROVEN:** non è un indirizzo VM.
**UNPROVEN:** la trasformazione completa.

---

## 7. Interpretazioni

| Ipotesi | Stato |
|---|---|
| Class descriptor | **UNPROVEN** |
| Codice | **REFUTED** |
| Dato firmware | **REFUTED** |
| Metadato prelink | **UNPROVEN** |
| Puntatore condiviso | **PROVEN** |
| Base L3 ricostruibile | **NO** |

---

## 8. Stop

| Criterio | Esito |
|---|---|
| Base L3 dimostrata | **NO** |
| Mapping univoco | **NO** |
| Riferimenti indipendenti | **NO** |
| Spazio >10 GiB | **SÌ** |
| Modifiche | **NO** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Occorrenze SystemKC | **155** |
| Occorrenze BootKC | **186** |
| Base L3 | **UNPROVEN** |
| Target | `0x12AA488` |
| `cacheLevel` | `3` |
| Class descriptor | **UNPROVEN** |
| Superclass | **UNPROVEN** |
| Pubblicazione | **UNPROVEN** |
| Matching | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `0xC00000012AA488` è un `superClass` condiviso, ripetuto 155 volte in SystemKC e 186 in BootKC; è un target L3 puro (`target=0x12AA488`, `cacheLevel=3`, `isAuth=0`, `next=0`). I metadati dyld non memorizzano la base L3, le regioni top-level sono sovrapposte e le basi candidate producono indirizzi incompatibili. Non esiste un riferimento indipendente per ricostruire la base: il criterio di stop è raggiunto e l’identità della superclass resta **UNPROVEN**, così come pubblicazione e matching X6000HWLibs. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,2 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
