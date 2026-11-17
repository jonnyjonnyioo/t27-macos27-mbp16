# T27 — AGENT-AMD — X6100 HYBRID VTABLE SEMANTICS

**Scope:** capire **perché** le **6 vtable C++ realmente istanziate** contengano **835 slot esterni** verso **dati/stringhe X4000** invece che funzioni; confrontare le vtable istanziate con le **2 non istanziate** e con le **8 senza slot esterni**; verificare costruttori, distruttori, letture degli slot, offset e corrispondenza con firmware/tabelle X4000.

**Modalità:** sola lettura; `nm -n -S`, `otool -l`, `otool -tvV`, parsing Mach-O/chained fixups. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** la meccanica è C++ (8 vptr store, vptr = `__ZTV + 0x10`), ma **835/869** slot esterni delle 6 vtable puntano a **dati, tabelle e firmware X4000**, **0 a codice**. Le 2 vtable con slot esterni ma **senza riferimenti** sono **non istanziate/proprietarie (UNPROVEN)**. Il modello più coerente è **vtable ibrida / descrittore dati**, non una vtable standard di funzioni. **Nessuna prova** che gli slot dati siano chiamati come vfunc; **2212 chiamate indirette**, **568 via `*0xN(%rax)`** e **1660 load da `0xN(%rax)`** sono generiche e non attribuibili. T27 resta **OPEN**.

---

## 1. Input e metodo

| Input | Uso |
|---|---|
| `X6100-ZTV-STRUCTURE-CLASSIFICATION.md` | 16 `__ZTV`, 8 vptr store, 13 refs |
| `X6100-VTABLE-SEMANTIC-VALIDATION.md` | 869 slot, header, offset |
| `X6100-CROSS-PROVIDER-ATTRIBUTION.md` | target X4000 |
| `systemkc-all/com.apple.kext.AMDRadeonX6100HWLibs` | `otool -tvV`, `nm`, sezioni |

Analisi:
1. **6 vtable istanziate**: X6100 main, HWLibs main, SWIP main, 3 MetaClass.
2. **835** slot esterni in queste 6; **34** nelle 2 non istanziate; **0** nelle 8 senza slot esterni.
3. Disassembly di:
   - costruttori/distruttori `C1/C2/D1/D2`;
   - **vptr store**;
   - load `movq 0xN(%rX), %rY`;
   - chiamate indirette `callq *0xN(%rX)`;
   - accessi indicizzati `(%rX,%rY,8)`.
4. Corrispondenza con simboli/firmware/tabelle X4000.

---

## 2. Where the 835 data slots are

| Vtable | Slot esterni | Target X4000 | Target codice |
|---|---:|---:|---:|
| `__ZTV35…X6100` | 255 | 255 | **0** |
| `__ZTV30…HWLibs` | 255 | 255 | **0** |
| `__ZTV34…SWIP` | 256 | 256 | **0** |
| `__ZTVN35…MetaClass` | 23 | 23 | **0** |
| `__ZTVN30…MetaClass` | 23 | 23 | **0** |
| `__ZTVN34…MetaClass` | 23 | 23 | **0** |
| **Totale 6 vtable** | **835** | **835** | **0** |
| `AtiPowerPlayInterface` | 32 | 32 | **0** |
| `AtiApplePowerTuneServices` | 2 | 2 | **0** |
| **Totale esterni** | **869** | **869** | **0** |

**PROVEN:** le 6 vtable istanziate non contengono **alcun** target in codice X4000. **Tutti** i loro 835 slot esterni sono dati/tabelle/stringhe.

---

## 3. Corrispondenza con X4000

Target aggregati delle vtable (869 slot):

| Target X4000 | Slot |
|---|---:|
| `__DATA,__data` | **674** |
| `__DATA,__const` | **135** |
| `__TEXT,__cstring` | **57** |
| `__TEXT,__const` | **3** |
| **Totale** | **869** |

Ripartizione per gruppo:

| Gruppo | Data | Const | Cstring | Text const | Totale |
|---|---:|---:|---:|---:|---:|
| 6 vtable istanziate | **640** | **135** | **57** | **3** | **835** |
| 2 vtable-like non istanziate | **34** | 0 | 0 | 0 | **34** |
| **Totale** | **674** | **135** | **57** | **3** | **869** |

I simboli nearest principali (869 slot) sono:

| Simbolo X4000 | Slot |
|---|---:|
| `_aF32_MEC_Ucode` | 109 |
| `_CAILAsicCapsInitTable` | 63 |
| `__ZL20CAIL_ASIC_CAPS_TABLE` | 42 |
| `MCILDebugPrint.cold.1` | 18 |
| `_aRLC_Ucode` | 18 |
| `_scbu_tbl` | 11 |
| `_aSpectre_GoldenRegisterSettings` | 5 |
| `_polaris10_kicker_smc_firmware` | 3 |
| `_aBONAIRE_GoldenRegisterSettings_A1` | 2 |
| `_stSPUKernel_CI` | 2 |
| `_PwrVirusTable` | 1 |
| `__ZTV20AtiPowerPlayServices` | 1 |

**PROVEN:** la maggior parte degli slot punta a **firmware/CAIL e tabelle ASIC**, non a funzioni. Questo spiega il carattere **ibrido**: la vtable contiene **descrittori di dati** in posizioni che l’ABI Itanium riserva ai **function pointer**.

---

## 4. Accesso agli slot

| Misura | Valore |
|---|---:|
| Chiamate indirette totali (`callq *…`) | **2.212** |
| Chiamate indirette via `*0xN(%rax)` | **568** |
| Load da `0xN(%rax)` | **1.660** |
| Accessi indicizzati `(%rX,%rY,8)` | **1.895** |
| Scritture a `__DATA,__const` / `__ZTV` | **0** |
| vptr store attribuibili a `__ZTV` | **8** |

Offset più frequenti nelle chiamate `*0xN(%rax)`:

| Offset | Chiamate | Nota |
|---:|---:|---|
| `0x28` | 48 | possibile slot dopo header |
| `0x40` | 43 | slot |
| `0x38` | 40 | slot |
| `0x10` | 32 | **prima entry virtuale** |
| `0x60` | 26 | slot |
| `0xB8` | 22 | slot |
| `0x80` | 18 | slot |
| `0x08` | 15 | header/typeinfo |
| `0x1D0` | 14 | slot |
| `0xB0` | 13 | slot |
| `0x100` | 12 | slot |
| `0x128` | 11 | slot |
| `0x30` | 10 | slot |
| `0x2B8` | 10 | slot |
| `0x8F0` | 9 | oltre la main vtable |
| `0x8E8` | 8 | oltre la main vtable |
| `0x8F8` | 8 | oltre la main vtable |

**PROVEN:** esistono **568** chiamate indirette con offset compatibili con vtable/slot; **0x10** (prima entry) è usato **32** volte.

**UNPROVEN:** che `%rax` sia il **vptr** e che l’offset appartenga a **una delle 6 vtable**. Le 2.212 chiamate indirette includono callback, function pointer di struct e dispatch di altri oggetti. **Nessuna** relazione diretta è dimostrata.

**Conclusione parziale:** gli slot dati **non sono mai scritti**; la vtable è read-only. Se una `callq *0x10(%rax)` usasse davvero il vptr X6100, chiamerebbe **dati X4000**: ciò sarebbe invalido. **Nessun boot** può confermarlo.

---

## 5. Perché 835 dati?

### Ipotesi A — vtable ibrida / descrittore

La struttura ha:
- simbolo `__ZTV`;
- header Itanium a 16 byte;
- vptr = `__ZTV + 0x10`;
- costruttori C1/C2 reali;
- slot allineati nel corpo virtuale.

Ma il contenuto è **dati/firmware**. Può essere una **vtable C++ estesa** in cui le entry non sono solo funzioni, ma **descrittori di firmware/CAIL** usati dal driver.

**Stato:** **INFERRED**.

### Ipotesi B — tabella di inizializzazione travestita da vtable

I costruttori installano il vptr, ma il codice potrebbe usare la struttura come **tabella dati** (offset/descrittori) e non come dispatch virtuale. I **640** target in `__DATA,__data`, **135** in `__const`, **57** in `__cstring` e **3** in `__const` testo sono compatibili con questa lettura.

**Stato:** **INFERRED**.

### Ipotesi C — vtable parzialmente invalida

Le entry dati sarebbero **function pointer non validi**; il driver non potrebbe dispatcharle. Sarebbe un **difetto/ibrido non callable**.

**Stato:** **UNPROVEN**; richiederebbe boot o emulazione.

**Nessuna** delle tre è PROVEN. La sola cosa PROVEN è la **convivenza** di meccanica C++ e target dati.

---

## 6. Istanziate vs non istanziate

| Gruppo | Strutture | Slot esterni | vptr store | Riferimenti | Interpretazione |
|---|---:|---:|---:|---:|---|
| 6 vtable C++ | 6 | **835** | **8** | **13** | **ibride, istanziate** |
| 2 vtable-like | 2 | **34** | **0** | **0** | **non istanziate / proprietarie UNPROVEN** |
| 8 senza slot esterni | 8 | **0** | **0** | **0** | **fuori dall’analisi** |

**PROVEN:** le 2 vtable con slot esterni ma **senza vptr store** non sono installate da alcun costruttore; le 6 istanziate sì.

**INFERRED:** le 2 potrebbero essere **vtable di interfacce** usate solo come **tabelle di servizio** (PowerPlay/PowerTune), non come oggetti C++ completi.

---

## 7. Differenze rilevanti

| Aspetto | 6 istanziate | 2 non istanziate |
|---|---|---|
| vptr store | **8** | **0** |
| Riferimenti `__ZTV` | **13** | **0** |
| Slot esterni | **835** | **34** |
| Target codice | **0** | **0** |
| Header | 16 byte zero | 16 byte zero |
| vptr | `__ZTV+0x10` | **assente** |
| Uso dimostrato | costruzione oggetto | **nessuno** |

**PROVEN:** la differenza è **l’istanziazione**, non la forma. Entrambe hanno header e slot; solo le 6 ricevono un vptr.

---

## 8. Interpretazione finale

### PROVEN

- **6 vtable** C++ istanziate; **8 vptr store**; **vptr = `__ZTV+0x10`**.
- **835** slot esterni di queste 6: **640 data, 135 const, 57 cstring, 3 text const**; **0 codice**.
- **2 vtable-like** con **34** slot esterni: **0 riferimenti**, **0 vptr store**.
- **8** `__ZTV` senza slot esterni.
- **0 scritture** a `__DATA,__const`/`__ZTV`.
- **568** chiamate indirette via `*0xN(%rax)`, **32** a `0x10`; **1.660** load; **1.895** accessi indicizzati.

### INFERRED

- Le 6 vtable sono **ibride**: meccanica C++ + descrittori dati.
- I 835 target sono **firmware/CAIL/tabelle ASIC**, non funzioni.
- Le 2 non istanziate sono **interfacce/tabelle di servizio**.

### UNPROVEN

- Che gli slot dati siano **callable** o usati come vfunc.
- Che le 568 chiamate indirette usino queste vtable.
- Che la struttura sia **lecita** a runtime.
- Risoluzione assoluta, `basePointers`, dipendenza AMD, boot/ABI.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Perché 835 dati? | **Le vtable contengono descrittori/firmware X4000, non funzioni** |
| Le 6 sono C++? | **SÌ, meccanica e vptr reali; contenuto ibrido** |
| Sono standard? | **NO: 835/869 target dati, 0 codice** |
| Le 2 non istanziate? | **SÌ: 34 slot, 0 refs, 0 vptr** |
| Gli slot dati sono chiamati? | **UNPROVEN; 568 chiamate indirette non attribuibili** |
| T27 è GO? | **NO — OPEN** |

**Sintesi:** le 6 vtable sono **C++ per costruzione** ma **ibride per contenuto**: **835** slot verso **firmware, CAIL e tabelle X4000**, **0** verso codice. Le **2** vtable-like con slot esterni non sono mai istanziate; le **8** restanti sono fuori. La spiegazione più solida è **vtable/descrittore ibrido**, non vtable standard né tabella proprietaria pura. T27 resta **OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto in questa fase. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
