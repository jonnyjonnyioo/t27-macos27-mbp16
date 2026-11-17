# T27 — AGENT-AMD — L2/L3 BASES

**Scope:** risolvere le basi L2/L3 del formato `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`, cercare altri puntatori L2/L3 nelle immagini AMD, confrontare X5000/X6000 Interface e verificare l’identità di `0x12AA488`.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset X5000/X6000, chained pointers, symbol table; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che il formato non memorizza le basi L2/L3 e che L0/L1 sono verificabili sui simboli; **PROVEN** che X5000 e X6000 Interface condividono il puntatore L3 `0xC00000012AA488` e vtable IOService identiche. **UNPROVEN** la base L3 e l’eredità. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 115 | `df262d77cb3932f66f69347f269c7e03288d58bbdeb2380169ebe8c3749ee118` |
| Report 114 | `e60ceb180d7028ecbff2df76d1f25f8ca8ffd1fdafe740798f403017888698db` |

**PROVEN:** gli artefatti sono quelli indicati; 115 ha il banner di rettifica.

---

## 2. Metadati disponibili

| Campo | Valore |
|---|---:|
| `fixups_version` | `0` |
| `starts_offset` | `28` |
| `imports_count` | `0` |
| `pointer_format` | `11` |
| entry | `4` byte |
| `target` | `0..29` |
| `cacheLevel` | `30..31` |

**PROVEN:** il formato non contiene basi.
**PROVEN:** le basi sono fornite dal layout runtime.
**UNPROVEN:** L2/L3 statiche.

---

## 3. Basi verificate

| Livello | Base | Evidenza |
|---:|---:|---|
| `0` | `0xFFFFFF8000100000` | `0x994C60 + base = registerService` |
| `1` | `0` (target assoluto) | `0xC26CFF0` = `SWI::start` |
| `2` | **UNPROVEN** | nessun campione |
| `3` | **UNPROVEN** | nessun campione |

**PROVEN:** L0/L1 coerenti.
**UNPROVEN:** L2/L3.

---

## 4. Puntatori L3 nelle immagini

| Immagine | Offset | Raw | `superClass` |
|---|---:|---:|---:|
| X6000HWServices | `0xC270370` | `0xC00000012AA488` | `0x12AA488` |
| X5000HWServices | `0x457F368` | `0xC00000012AA488` | `0x12AA488` |

**PROVEN:** il puntatore è identico.
**PROVEN:** entrambi sono L3.
**UNPROVEN:** la base.

---

## 5. X5000/X6000 Interface

| Classe | MetaClass | Vtable | `superClass` |
|---|---:|---:|---:|
| X5000 Interface | `0x457C2C0` | `0x457F370` | `0x12AA488` L3 |
| X6000 Interface | `0xC26D210` | `0xC270378` | `0x12AA488` L3 |

| Slot | X5000 | X6000 |
|---|---|---|
| `0x5B0` | `registerService` | `registerService` |
| `0x5B8` | `probe` | `probe` |
| `0x5C0` | `start` | `start` |
| `0x5C8` | `stop` | `stop` |

**PROVEN:** vtable identiche IOService.
**PROVEN:** superclasse condivisa.
**PROVEN:** sono sorelle.
**UNPROVEN:** la classe base reale.

---

## 6. `0x12AA488`

| Test | Esito |
|---|---|
| Simbolo esatto | **nessuno** |
| Target L3 | **SÌ** |
| Indirizzo VM | **NO** |
| Base L3 | **UNPROVEN** |
| Simbolo firmware | solo nearest |
| Appartenenza firmware | **REFUTED** |

**PROVEN:** è un target a 30 bit.
**PROVEN:** non è un indirizzo VM.
**REFUTED:** l’appartenenza al blob firmware.
**UNPROVEN:** il proprietario.

---

## 7. Altre entry L2/L3

| Immagine | Conteggio grezzo | Uso |
|---|---:|---|
| X6000HWServices | `671` | rumore dati/testo |
| X5000HWServices | `692` | rumore dati/testo |

**PROVEN:** la scansione grezza non discrimina.
**PROVEN:** non è una prova di puntatori.
**UNPROVEN:** un elenco affidabile.

---

## 8. Eredità e dipendenze

| Domanda | Risposta |
|---|---|
| X5000/X6000 sorelle | **SÌ** |
| Base comune `0x12AA488` | **UNPROVEN** |
| X4000 Interface correlata | **UNPROVEN** |
| X6000HWLibs dipende da Interface | **SÌ, requisito** |
| Interface pubblicata | **UNPROVEN** |
| Matching | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Base L2 | **UNPROVEN** |
| Base L3 | **UNPROVEN** |
| `0x12AA488` VM | **NO** |
| `0x12AA488` firmware | **REFUTED** |
| X5000/X6000 sorelle | **SÌ** |
| Eredità | **UNPROVEN** |
| Pubblicazione | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il formato `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` non memorizza le basi L2/L3; L0 (`0xFFFFFF8000100000`) e L1 (target assoluto) sono verificabili, L2/L3 no. X5000 e X6000 Interface condividono il puntatore L3 `0xC00000012AA488` e vtable IOService identiche, quindi sono sorelle; `0x12AA488` è un target a 30 bit, non un indirizzo VM, e l’appartenenza al blob firmware è **REFUTED**. L’eredità reale, la pubblicazione di Interface e il matching X6000HWLibs restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
