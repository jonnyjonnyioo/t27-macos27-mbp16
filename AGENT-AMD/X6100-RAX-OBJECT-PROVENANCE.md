# T27 — AGENT-AMD — X6100 RAX OBJECT PROVENANCE

**Scope:** determinare se le **283 chiamate indirette** con pattern **vptr_load** (`movq (%reg), %rax` + `callq *0xN(%rax)`) usino davvero oggetti **X6100** o strutture di altre classi. Analisi backward del registro sorgente, della sua origine e della funzione contenente la call.

**Modalità:** sola lettura; `otool -tvV`, `nm -n`, Python. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** **0/283** call hanno **`%rdi` = argomento diretto di una funzione X6100**; **11/283** sono in funzioni X6100, ma **9** usano **locali stack** e **2** usano **sotto-oggetti** (`0xa8`, `0xb8`), non il `this` X6100. **179** sono in altre classi C++ (`AmdTtlServices` in testa) e **93** in funzioni C/locali. Le **48** call a `0x28` sono **46 altre classi + 2 sotto-oggetti X6100**. **Nessuna dispatch della main vtable X6100 è provata**. T27 resta **OPEN**.

---

## 1. Metodo

1. Parse di **603.316** istruzioni e delle **568** `callq *0xN(%rax)`.
2. Selezione delle **283** con **vptr_load**.
3. Per ciascuna:
   - registro sorgente del load (`%rdi`, `%rbx`, …);
   - funzione contenente la call da `nm -n`;
   - ultima scrittura del registro prima del load, entro il confine di funzione;
   - classificazione dell’origine.
4. Incrocio con le **6 vtable X6100** e con i target X4000.

**Limite:** l’analisi è **intra-funzione**; non risale ai chiamanti. Un `%rdi` argomento può essere X6100 solo se il chiamante lo passa, e questo non è osservabile senza interprocedurale o runtime.

---

## 2. Registro sorgente del vptr load

| Registro | Call | Quota |
|---|---:|---:|
| **%rdi** | **113** | 39,93% |
| **%rbx** | **80** | 28,27% |
| **%r15** | **32** | 11,31% |
| **%r12** | **17** | 6,01% |
| **%r14** | **16** | 5,65% |
| **%rax** | **15** | 5,30% |
| **%r13** | **8** | 2,83% |
| **%rsi** | **2** | 0,71% |
| **Totale** | **283** | 100% |

**PROVEN:** il vptr è letto da **8 registri diversi**; non c’è un unico `this`. **%rdi** copre solo il **39,93%**.

---

## 3. Origine del registro

| Origine | Call | Quota | Significato |
|---|---:|---:|---|
| **copy** | **133** | 47,00% | registro copiato da un altro registro |
| **arg_entry** | **64** | 22,61% | nessuna scrittura: argomento alla funzione |
| **field_load** | **52** | 18,37% | caricato da un campo di un altro oggetto |
| **other_write** | **27** | 9,54% | stack, pop, scritture non classificate |
| **vptr_load** | **7** | 2,47% | caricato da un altro vptr |
| **Totale** | **283** | 100% | |

Dettaglio **copy**:
- `copy:%rax` **69**
- `copy:%rdi` **61**
- `copy:%rsi` **2**
- `copy:%rdx` **1**

Dettaglio **field_load**:
- `0x8` **25**
- `0x10` **10**
- `0x170` **4**
- `0x40` **2**
- `0xa8` **1**
- `0xb8` **1**
- `0x20` **1**
- `0x4c8` **1**
- altri **7**

**PROVEN:** **185/283 (65,4%)** non sono un `this` diretto: **133 copy + 52 field**. **64** sono argomenti, ma la classe non è nota.

---

## 4. Funzione contenente la call

| Classe funzione | Call | Quota |
|---|---:|---:|
| **altre classi C++** (`__ZN…`, non X6100) | **179** | 63,25% |
| **C / locali** | **93** | 32,86% |
| **X6100** | **11** | 3,89% |
| **Totale** | **283** | 100% |

**PROVEN:** **272/283 (96,1%)** delle call con vptr_load sono **fuori** dalle funzioni X6100.

Top funzioni:
| Call | Funzione |
|---:|---|
| **26** | `AmdTtlServices::reportFwVersionInfo` |
| **11** | `AmdTtlServices::logSWIPError` |
| **10** | `AmdTtlServices::AmdTtlServices(IOPCIDevice*)` |
| **9** | `AmdTtlServices::cosWritePciConfigData` |
| **9** | `AmdTtlServices::getOSObjectData` |
| **8** | `AmdTtlServices::cosGetVbiosRomImage` |
| **6** | `_PECI_RetrieveBiosDataTable` |
| **6** | `AmdTtlServices::createPciDeviceCache` |
| **6** | `AmdTtlServices::getPciDevice` |
| **6** | `AmdTtlServices::initializeAMDLogProperties` |

**INFERRED:** il cluster dominante è **AmdTtlServices**, non X6100. Le call sono coerenti con **vtable di servizi TTL**, non con la main vtable X6100.

---

## 5. Le 11 call in funzioni X6100

| Call | Funzione | Offset | Sorgente | Origine |
|---|---|---:|---|---|
| `0xDD6F080` | `HWLibs::free` | 0x28 | %rdi | **field 0xa8** |
| `0xDD6F1A8` | `HWLibs::attach` | 0x680 | %rdi | stack `-0x10(%rbp)` |
| `0xDD6F1D2` | `HWLibs::attach` | 0x8E8 | %rdi | stack `-0x18(%rbp)` |
| `0xDD6F1EE` | `HWLibs::attach` | 0x8F0 | %rdi | stack `-0x18(%rbp)` |
| `0xDD6F20A` | `HWLibs::attach` | 0x8F8 | %rdi | stack `-0x18(%rbp)` |
| `0xDD6F44A` | `HWLibs::callPlatformFunction` | 0x1E8 | %rdi | stack `-0x18(%rbp)` |
| `0xDD6F4C6` | `HWLibs::callPlatformFunction` | 0x148 | %rdi | stack `-0x18(%rbp)` |
| `0xDD6F920` | `SWIP::free` | 0x28 | %rdi | **field 0xb8** |
| `0xDD6FABA` | `SWIP::callPlatformFunction` | 0x1E8 | %rdi | stack `-0x18(%rbp)` |
| `0xDD6FBBC` | `SWIP::createTtlInterface` | 0x850 | %rdi | stack `-0x28(%rbp)` |
| `0xDD6FBFB` | `SWIP::createTtlInterface` | 0x40 | %rdi | stack `-0x20(%rbp)` |

**PROVEN:**
- **0/11** usano `%rdi` come `this` X6100 non modificato.
- **2/11** usano un **sotto-oggetto** caricato da `0xa8(%rax)` / `0xb8(%rax)`.
- **9/11** usano un **puntatore locale** sullo stack.
- **0/11** usano la **main vtable X6100** in modo provato.

**INFERRED:** i 2 `free` chiamano una vtable del **sotto-oggetto** (hardware services), non quella X6100. I 9 stack puntano a oggetti temporanei o restituiti, di classe ignota.

---

## 6. Il caso 0x28

**48 call** totali:
- **46** in **altre classi C++**;
- **2** in **X6100** (`HWLibs::free`, `SWIP::free`), ma su **sotto-oggetti**.

Top:
| Call | Funzione |
|---:|---|
| **13** | `AmdTtlServices::reportFwVersionInfo` |
| **4** | `AmdTtlServices::logSWIPError` |
| **3** | `AmdTtlServices::createSaveRestorePartitions` |
| **3** | `AmdTtlServices::initializeAMDLogProperties` |
| **2** | `AmdTtlServices::gmmCbAllocateNonlocalGpuMemory` |
| **2** | `AmdTtlServices::cosGetVbiosRomImage` |
| **1** | `HWLibs::free` |
| **1** | `SWIP::free` |

**PROVEN:** **46/48** sono in **AmdTtlServices o altre classi**; **2/48** in X6100 ma su **sotto-oggetti**.
**UNPROVEN:** che uno qualunque dei 48 `%rdi` sia un oggetto X6100 main.

**Conseguenza:** il target `0x91DF70` (`__TEXT,__cstring` X4000) è il target **solo se** l’oggetto è X6100 main. Poiché **0/48** lo sono in modo provato, l’anomalia “call a stringa” **non è attribuita a X6100**.

---

## 7. 0x8F0 / 0x8E8 / 0x8F8

**24 call** totali (9+8+7), tutte in **`HWLibs::attach`**, tutte con **`%rdi` da `-0x18(%rbp)`**.

**PROVEN:** sono **puntatori locali** di `attach`, non il `this` X6100.
**UNPROVEN:** la classe dell’oggetto puntato.

**Conseguenza:** lo slot calcolato **fuori** da `__ZTV35` non è una prova di vtable X6100; è solo un **candidato** su un oggetto ignoto.

---

## 8. Validità dei target

| Oggetto | Target X4000 | Validità |
|---|---|---|
| **X6100 main** | dati/stringhe | **nessuna call provata** |
| **X6100 sotto-oggetto** | sconosciuto | **UNPROVEN** |
| **AmdTtlServices** | sconosciuto | **UNPROVEN** |
| **C / locali** | sconosciuto | **UNPROVEN** |
| **stack locals** | sconosciuto | **UNPROVEN** |

**PROVEN:** i target X4000 mappati nel report precedente sono **condizionali all’appartenenza a X6100**; qui **0/283** oggetti sono X6100 main in modo provato.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| 283 vptr_load? | **SÌ** |
| `%rdi` arg diretto in funzione X6100? | **0** |
| Call in funzioni X6100? | **11** (3,89%) |
| Di queste, `this` X6100? | **0** |
| Sotto-oggetti X6100? | **2** (`0xa8`, `0xb8`) |
| Stack locali X6100? | **9** |
| Altre classi C++? | **179** (63,25%) |
| C / locali? | **93** (32,86%) |
| 0x28 su X6100 main? | **0/48 provati** |
| 0x8F0/8E8/8F8 su X6100 main? | **0/24 provati** |
| Dispatch main vtable X6100? | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** le **283** call con vptr_load **non sono riconducibili alla main vtable X6100**. Il **96,1%** è fuori dalle funzioni X6100; l’**11** residuo usa **sotto-oggetti** o **locali stack**, mai il `this` X6100. Le anomalie “target dati” restano **condizionali e non attribuite**. T27 resta **OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
