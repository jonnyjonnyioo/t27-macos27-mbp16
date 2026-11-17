# T27 — AGENT-AMD — CACHE LEVELS

> **RETTIFICA (Prompt 116):** `0x12AA488` è un target L3 a 30 bit, non un indirizzo VM; il simbolo firmware più vicino non prova alcuna appartenenza. La frase “cade nel blob firmware” va letta solo come offset, non come proprietario. Vale il report 116.

**Scope:** ricostruire le basi di indirizzamento L0–L3 del Kernel Collection, decodificare `0xC00000012AA488`, identificare segmento/immagine/proprietario e verificare l’ereditarietà di X6000 Interface.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, chained pointers, symbol table; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che L0 usa base `0xFFFFFF8000100000` (verificata su `registerService`) e L1 usa target assoluto nella collezione (verificata su `SWI::start`/`Abstract::probe`). **UNPROVEN** la base L2/L3. `0x12AA488` cade nel blob firmware `_polaris10_kicker_smc_firmware`, non in una classe; l’ereditarietà di Interface resta **UNPROVEN**. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 114 | `e60ceb180d7028ecbff2df76d1f25f8ca8ffd1fdafe740798f403017888698db` |
| Report 110 | `3354665f31801a66135b2b22aa9f0176443a2b36b68b8a41ec186b8898145255` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Basi L0/L1

| Livello | Base | Evidenza |
|---:|---:|---|
| `0` | `0xFFFFFF8000100000` | `0x994C60 + base = registerService` |
| `1` | `0` (target assoluto) | `0xC26CFF0` = `SWI::start` |
| `2` | **UNPROVEN** | nessun campione |
| `3` | **UNPROVEN** | nessun campione |

**PROVEN:** L0 e L1 sono coerenti con i simboli.
**PROVEN:** L0 non è un indirizzo assoluto.
**UNPROVEN:** L2/L3.

---

## 3. Puntatore `0xC00000012AA488`

```text
raw         0xC00000012AA488
target      0x12AA488
cacheLevel  3
```

| Campo | Valore |
|---|---:|
| `target` | `0x12AA488` |
| `cacheLevel` | `3` |
| base L3 | **UNPROVEN** |
| indirizzo reale | **UNPROVEN** |

**PROVEN:** il puntatore è L3.
**PROVEN:** non è un indirizzo assoluto.
**UNPROVEN:** la base L3.

---

## 4. Collocazione di `0x12AA488`

| Ricerca | Esito |
|---|---|
| Simbolo esatto | **nessuno** |
| Simbolo precedente | `_polaris10_kicker_smc_firmware` (`0x129A3B0`) |
| Offset | `+0x100D8` |
| Simbolo successivo | `_polaris10_kicker_smcFirmware` (`0x12BA178`) |
| Segmento | **dati firmware** |
| Classe C++ | **NO** |

**PROVEN:** cade nel blob firmware.
**PROVEN:** non è una classe.
**UNPROVEN:** il significato del target L3.

---

## 5. X5000/X6000 Interface

| Classe | `superClass` | Raw | Livello |
|---|---:|---:|---:|
| X5000 Interface | `0x12AA488` | `0xC00000012AA488` | `3` |
| X6000 Interface | `0x12AA488` | `0xC00000012AA488` | `3` |

**PROVEN:** condividono lo stesso puntatore.
**PROVEN:** sono sorelle.
**UNPROVEN:** la classe base reale.

---

## 6. X6000 Interface

| Elemento | Valore |
|---|---:|
| Vtable | `0xC270378` |
| Costruttore | `0xC26D260` |
| `metaClass` | `0xC271828` |
| `superClass` | `0x12AA488` L3 |
| Eredità reale | **UNPROVEN** |
| Pubblicazione | **UNPROVEN** |

**PROVEN:** la classe è completa.
**PROVEN:** il puntatore superclasse è condiviso.
**UNPROVEN:** l’eredità effettiva.

---

## 7. Implicazioni

| Domanda | Risposta |
|---|---|
| Interface istanziabile | **SÌ, strutturale** |
| Interface pubblicata | **UNPROVEN** |
| Navi pubblica Interface | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| Runtime | **UNPROVEN** |

**PROVEN:** la struttura non basta a pubblicare.
**UNPROVEN:** la disponibilità runtime.

---

## 8. Classificazione

| Affermazione | Esito |
|---|---|
| L0 base `0xFFFFFF8000100000` | **PROVEN** |
| L1 target assoluto | **PROVEN** |
| L2/L3 base | **UNPROVEN** |
| `0x12AA488` è una classe | **REFUTED** |
| Interface eredita da `0x12AA488` | **UNPROVEN** |
| Interface è provider | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Base L0 | `0xFFFFFF8000100000` |
| Base L1 | `0` |
| Base L2/L3 | **UNPROVEN** |
| `0x12AA488` | **dato firmware** |
| Superclasse Interface | **UNPROVEN** |
| Eredità | **UNPROVEN** |
| Pubblicazione | **UNPROVEN** |
| Matching | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** L0 usa base `0xFFFFFF8000100000` e L1 il target assoluto nella collezione; entrambe sono verificate sui simboli. L2/L3 non hanno campioni sufficienti. `0x12AA488` non è una classe: cade nel blob firmware `_polaris10_kicker_smc_firmware+0x100D8`, quindi il puntatore `superClass` L3 non è interpretabile come indirizzo di classe con i dati disponibili. X5000 e X6000 Interface condividono lo stesso puntatore e sono sorelle, ma l’eredità reale, la pubblicazione di Interface e il matching X6000HWLibs restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
