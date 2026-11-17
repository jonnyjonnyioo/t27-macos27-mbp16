# T27 — AGENT-AMD — X6100 CODE DIFFERENCE ATTRIBUTION

**Scope:** capire se i **21.383 byte** differenti di `__text` tra `X6100HWLibs` di `systemkc-all` (`e521d3cc…`) e root2 (`00b6214e…`) derivano da compilazione, ottimizzazione o trasformazioni del binario, **senza inferire equivalenza funzionale**.  
**Modalità:** sola lettura; `otool -tvV`, `nm -a -n`, `nm -m`, `dwarfdump`, `shasum` logico. Nessuna estrazione, copia, build o boot.  
**Esito:** **21.383 B** differenti in `__text`, distribuiti su **2.573 funzioni**; le tre funzioni più coinvolte hanno **lo stesso numero di istruzioni** e differenze normalizzate concentrate su **bersagli di call/indirizzi**. La causa resta **UNPROVEN**; non è dimostrata equivalenza funzionale.

---

## 1. Metodo

| Strumento | Esito |
|---|---|
| `otool -tvV` | disponibile; disassembla `__TEXT,__text` con etichette |
| `nm -arch x86_64 -a -n` | 9.646 simboli di testo |
| `nm -arch x86_64 -m` | 12.602 righe; 72 external defined, 348 undefined |
| `dwarfdump --debug-info` | **`.debug_info` vuoto** in entrambi |
| `llvm-objdump` | **ASSENTE** |
| `shasum` logico | calcolato su slice in memoria, senza file |

L’attribuzione ai simboli usa il **simbolo di testo precedente** all’offset; è quindi una mappa approssimata, non un debug info.

---

## 2. Distribuzione

| Misura | Valore |
|---|---:|
| `__text` size | 2.362.326 B |
| Byte differenti | **21.383** |
| Percentuale | **0,905%** |
| Funzioni con almeno una differenza | **2.573** |
| Simboli di testo | 9.646 |

### 2.1 Funzioni più coinvolte

| Byte diversi | Funzione |
|---:|---|
| **244** | `_PhwComm_OD8_ApplySettings` |
| **180** | `__ZN14AmdTtlServices16sendRequestToMESE20AMD_MES_REQUEST_TYPEPv` |
| **140** | `_PhwVega10_EnableDPMTasks` |
| 95 | `__ZN14AmdTtlServices19cosGetVbiosRomImageEPvP23cos_get_rom_image_inputP24cos_get_rom_image_output` |
| 92 | `__ZN14AmdTtlServices16gmmCbEventNotifyEPv14_TtlGmmEventId` |
| 84 | `_PhwVega12_SetupDefaultDPMTables` |
| 80 | `__ZN14AmdTtlServices27createSaveRestorePartitionsEv` |
| 76 | `__ZN14AmdTtlServices31gmmCbAllocateLocalGpuMemoryInitEPvP25_TtlGmmAllocLocalMemInputP26_TtlGmmAllocLocalMemOutput` |
| 73 | `__ZN14AmdTtlServices19reportFwVersionInfoEv` |
| 72 | `_PHM_NeedUpdateClocks` |
| 68 | `<before-first-symbol>` |
| 68 | `_PEM_InitPowerPlayFeatureInfo` |
| 68 | `_PhwCIslands_SetPowerStateTasks` |
| 68 | `_PptVega10_Initialize` |
| 68 | `__ZN14AmdTtlServices30gmmCbAllocateNonlocalGpuMemoryEPvP28_TtlGmmAllocNonlocalMemInputP29_TtlGmmAllocNonlocalMemOutput` |

Le differenze non sono concentrate in un’unica funzione o in un unico sottosistema: compaiono in **power management, MES, TTL/GMM, firmware, clock e inizializzazione**.

---

## 3. Disassemblaggio delle prime tre

### 3.1 Conteggi

| Funzione | Istruzioni systemkc | Istruzioni root2 | Differenze normalizzate |
|---|---:|---:|---:|
| `_PhwComm_OD8_ApplySettings` | 3.687 | 3.687 | **62** |
| `sendRequestToMESE` | 523 | 523 | **29** |
| `_PhwVega10_EnableDPMTasks` | 2.333 | 2.333 | **52** |

Le tre funzioni hanno **lo stesso numero di istruzioni**; le differenze normalizzate sono molto minori dei byte differenti (es. 244 B vs 62 istruzioni). Questo indica che molti byte differiscono in **operandi/immediati**, non in nuove istruzioni.

### 3.2 Esempi misurati

`_PhwComm_OD8_ApplySettings`:

```text
A 000000000df36014 callq 0x10378
B 00000000001c8014 callq _PE_enter_debugger

A 000000000df3607a callq 0x100b4
B 00000000001c807a callq ___bzero
```

`sendRequestToMESE`:

```text
A 000000000df72254 callq 0x10114
B 0000000000204254 callq _kprintf
```

`_PhwVega10_EnableDPMTasks`:

```text
A 000000000dec2e29 callq 0x10378
B 0000000000154e29 callq _PE_enter_debugger
```

In `systemkc` `otool` mostra **numeri** per i bersagli delle call; in root2 mostra i **nomi** (`_PE_enter_debugger`, `___bzero`, `_kprintf`). `nm` classifica quei simboli come **undefined external** in entrambi. La differenza di resa è quindi anche di **symbolization/relazione**, non solo di istruzioni.

---

## 4. Sezioni e stringhe

| Intervallo | SHA systemkc | SHA root2 | Byte diversi |
|---|---|---|---:|
| `__text` | `19dcb85d…` | `c65134cb…` | **21.383** |
| `__cstring` | `9851055a…` | `9851055a…` | **0** |
| `__const` | `fd5b170c…` | `fd5b170c…` | **0** |

`strings -a -n 6`: **30.945** righe, **15.402** uniche, diff vuoto; **265** riferimenti KPI/API identici. Le differenze di codice non introducono nuove stringhe o costanti.

---

## 5. Limiti

- `dwarfdump --debug-info` è **vuoto**: nessuna informazione di linea/DWARF per attribuire i byte.
- `llvm-objdump` **non installato**.
- La mappa per simbolo precedente è approssimata; `<before-first-symbol>` (68 B) non è attribuito.
- `otool -tvV` non risolve i call esterni di `systemkc` allo stesso modo di root2; i nomi/indirizzi non sono confrontabili senza normalizzazione.
- Non è stata eseguita alcuna analisi dinamica né test funzionale.

---

## 6. Classificazione

### 6.1 PROVEN

- `__text` differisce per **21.383 B** su 2.362.326 (0,905%).
- Le differenze toccano **2.573 funzioni**; le prime tre hanno 244/180/140 B.
- Le tre funzioni campione hanno **lo stesso numero di istruzioni** (3.687/523/2.333).
- `__cstring`/`__const` sono identici; stringhe significative identiche.
- `dwarfdump --debug-info` è vuoto; `llvm-objdump` assente.
- I call esterni sono **undefined external** in entrambi; `systemkc` li rende numericamente, root2 per nome.

### 6.2 INFERRED

- Molte differenze sono in **operandi di call/indirizzi e simboli locali**, compatibili con link/relocazione e symbolization diversa.
- Le funzioni campione conservano la stessa struttura di istruzioni; questo **non** dimostra equivalenza semantica.
- Le differenze in funzioni PM/MES/TTL sono **implementative**, non un cambio degli export/import.

### 6.3 UNPROVEN

- La causa esatta (compilatore, flag, ottimizzazione, link, trasformazione).
- Che le differenze siano innocue o senza effetto funzionale.
- L’equivalenza semantica e l’ABI.
- La compatibilità con 26B131 e il caricamento.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| Byte `__text` differenti? | **21.383** |
| Funzioni coinvolte? | **2.573** |
| Prime tre funzioni | `PhwComm_OD8_ApplySettings`, `sendRequestToMES`, `PhwVega10_EnableDPMTasks` |
| Stesso numero di istruzioni nelle tre? | **SÌ** |
| Solo padding? | **NO**: 21.383 B e 2.573 funzioni |
| Solo linking? | **NO**: il testo è diverso |
| Causa dimostrata? | **NO** |
| Equivalenza funzionale? | **NO dimostrata** |
| ABI 26B131? | **UNPROVEN** |

La differenza è **reale e diffusa**, ma le tre funzioni campione mostrano la stessa struttura e differenze concentrate su call/indirizzi. Non è possibile attribuirla con certezza a compilazione, ottimizzazione o trasformazione del binario; l’assenza di DWARF e di `llvm-objdump` limita la prova. **Nessuna equivalenza funzionale o compatibilità 26B131 è dichiarata.**

**STOP rispettato:** sola lettura; nessuna estrazione, copia, build, firma o boot. Spazio libero 12.924.756 KiB (12,32 GiB) > 10 GiB.
