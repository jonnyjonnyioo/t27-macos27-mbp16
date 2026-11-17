# T27 — AGENT-AMD — X6100 RESIDUAL CODE-DIFFERENCE AUDIT

**Scope:** classificare tutti i **21.383 byte** differenti di `__text` tra `AMDRadeonX6100HWLibs` di `systemkc-all` (`e521d3cc…`) e root2 (`00b6214e…`), separando le differenze **address/relocation-only** da un **residuo** non spiegato dalla normalizzazione stretta.  
**Modalità:** sola lettura; `otool -tvV`, `nm -a -n`, `otool -rv`, `otool -l`; confronto in memoria, nessuna scrittura di sezioni.  
**Esito:** copertura **21.383/21.383 B**. **16.758 B** cadono in funzioni con scheletro di istruzioni identico dopo normalizzazione di call/RIP; **4.557 B** restano residui dopo quella normalizzazione; **68 B** sono prima della prima etichetta `otool`. Il residuo **non è prova** di differenza di flusso: gli esempi mostrano ancora symbolization/relocation.

> **Correzione per istanza (16 Nov 2026):** tre nomi locali (`_getValidClk`, `_copyOverDriveSettingsLimitsArray`, `_copyClockLimitsArray`) compaiono due volte nel binario. Il conteggio per nome aveva aggregato 20 B di istanze pulite nel residuo. La verifica per indirizzo/istanza dà **16.758 B puliti** e **4.557 B residui** (281 nomi/istanze); il totale resta 21.383 B. Vedi `X6100-INSTRUCTION-VERIFICATION.md`.

---

## 1. Metodo e confini

| Voce | Valore |
|---|---|
| `__text` size | 2.362.326 B |
| Byte differenti | **21.383** |
| Bucket `nm` con differenze | **2.573** |
| Etichette `otool` con differenze | **2.476** |
| Bucket senza etichetta `otool` distinta | **97** |
| Byte prima della prima etichetta | **68** |

Le due mappe non coincidono: `nm` può assegnare più bucket allo stesso intervallo di codice, mentre `otool -tvV` espone le etichette di funzione. La classificazione seguente usa **le etichette `otool`**; i conteggi per funzione possono quindi differire da quelli del report `X6100-CODE-DIFF.md` (bucket `nm`).

### 1.1 Normalizzazione applicata

Per ogni funzione con differenze:

1. si rimuovono i commenti `##`;
2. si normalizzano gli indirizzi **RIP-relative** (`0x…(%rip)` → `ADDR(%rip)`);
3. si normalizzano i **target diretti** di `callq` e salti (`callq 0x…` / `callq _simbolo` → `TARGET`);
4. si confrontano le liste di istruzioni risultanti.

Non vengono normalizzati tutti gli immediati, le displacement o i nomi simbolici generici. Questa scelta è volutamente stretta: rende il residuo un **limite superiore**, non una misura di differenze semantiche.

---

## 2. Copertura completa

| Categoria | Funzioni | Byte | Percentuale |
|---|---:|---:|---:|
| **Address/relocation-only candidate** | 2.195 nomi (2.197 istanze) | **16.758** | **78,37%** |
| **Residuo dopo normalizzazione stretta** | 281 | **4.557** | **21,31%** |
| **Non assegnato** (prima della prima etichetta) | — | **68** | **0,32%** |
| **Totale** | 2.476 | **21.383** | **100%** |

- `missing_root2_funcs = 0`: tutte le funzioni con differenze hanno un'etichetta root2 corrispondente.
- La copertura dei byte è **completa**; la copertura **causale** non lo è.

---

## 3. Funzioni address/relocation-only candidate

Queste funzioni hanno **lo stesso numero di istruzioni** e la stessa sequenza dopo la normalizzazione di call/RIP. Sono quindi candidate a differenze di **indirizzi/relocation/symbolization**, non a un cambio di istruzioni.

| Byte | Funzione |
|---:|---|
| **216** | `sendRequestToMESE` |
| 95 | `cosGetVbiosRomImage` |
| 92 | `gmmCbEventNotify` |
| 92 | `getFirmware` |
| 84 | `PhwVega12_SetupDefaultDPMTables` |
| 76 | `gmmCbAllocateLocalGpuMemoryInit` |
| 73 | `reportFwVersionInfo` |
| 72 | `PHM_NeedUpdateClocks` |
| 68 | `PEM_VariBright_StateEnablesVariBrightCallback` |
| 64 | `gmmCbAllocateLocalGpuMemoryPostInit` |

`sendRequestToMESE` è **216 B** con il confine `otool`; nel report precedente era 180 B con il bucket `nm`. Non è una contraddizione: cambia il confine della funzione, non il totale.

---

## 4. Residuo dopo normalizzazione stretta

| Byte | Funzione |
|---:|---|
| **244** | `_PhwComm_OD8_ApplySettings` |
| **148** | `_PhwVega10_EnableDPMTasks` |
| 80 | `__ZN14AmdTtlServices27createSaveRestorePartitionsEv` |
| 68 | `_PhwCIslands_SetPowerStateTasks` |
| 68 | `_PptVega10_Initialize` |
| 68 | `__ZN14AmdTtlServices30gmmCbAllocateNonlocalGpuMemoryEPvP28_TtlGmmAllocNonlocalMemInputP29_TtlGmmAllocNonlocalMemOutput` |
| 60 | `_PhwTonga_Initialize` |
| 56 | `_PhwIceland_Initialize` |
| 56 | `_PptTonga_Initialize` |
| 56 | `_PhwVega20_OD8_ApplySettings` |
| 52 | `_PP_Tables_Initialize` |
| 52 | `_PhwTonga_InitSMCTable` |
| 52 | `_PhwPolaris10_SetPowerStateTasks` |
| 52 | `_PhwPolaris10_Initialize` |
| 52 | `_PhwPolaris22_EnableDPMTasks` |
| 52 | `_PhwVega20_EnableDPMTasks` |

### 4.1 Esempi di residuo

`_PhwComm_OD8_ApplySettings`:

```text
A 000000000df372ef movl $0xbc0, %esi
B 00000000001c92ef movl $__ZN35AMDRadeonX6100_AMDRadeonHWLibsX6100C1Ev, %esi
```

`_PhwVega10_EnableDPMTasks`:

```text
A 000000000dec2f8e movl $0x2, 0xa60(%r14)
B 0000000000154f8e movl $0x2, __ZN35AMDRadeonX6100_AMDRadeonHWLibsX6100D1Ev(%r14)

A 000000000dec30c5 movw %si, 0xb90(%r14,%rdx)
B 00000000001550c5 movw %si, __ZN35AMDRadeonX6100_AMDRadeonHWLibsX6100nwEm(%r14,%rdx)
```

`createSaveRestorePartitions`:

```text
A 000000000df6a0ae movl $0x1000, %edx
B 00000000001fc0ae movl $__ZN30AMDRadeonX6100_AMDRadeonHWLibsC2Ev, %edx
```

Questi esempi hanno **stesso opcode e stessi registri**, ma operandi resi diversamente: root2 visualizza simboli/displacement, systemkc numeri. Non dimostrano un cambio di flusso; mostrano che una parte dei 4.557 B residui è ancora **symbolization/relocation**, non codice diverso.

---

## 5. Interpretazione

### 5.1 PROVEN

- Tutti i **21.383 B** sono allocati: 16.758 + 4.557 + 68.
- **2.195** etichette `otool` hanno scheletro identico dopo normalizzazione; **281** no.
- Il residuo include esempi con opcode/registri identici ma operandi simbolici/numerici diversi.
- Root2 ha **6.243 external relocation entries**; `systemkc-all` ne ha **0** (da `X6100-RELOCATION-ANALYSIS.md`).
- I 72 export e i 348 undefined hanno gli stessi nomi.

### 5.2 INFERRED

- La quota **16.758 B** è compatibile con differenze di indirizzi/relocation/symbolization.
- La quota **4.557 B** è un **limite superiore** del residuo non spiegato: una parte è ancora symbolization, non necessariamente istruzioni diverse.
- Le funzioni PM/MES/TTL coinvolte sono implementative, non interfacce esportate.

### 5.3 UNPROVEN

- Che i 16.758 B siano **tutti** relocation: la normalizzazione non prova la causa.
- Che i 4.557 B siano tutti differenze reali di istruzioni.
- L’equivalenza semantica, l’ABI e la compatibilità 26B131.
- La causa delle differenze residue.

---

## 6. Conclusione

| Domanda | Risposta |
|---|---|
| Byte classificati? | **21.383/21.383** |
| Address/relocation-only candidate | **16.758 B** (78,37%) |
| Residuo dopo normalizzazione stretta | **4.557 B** (21,31%) |
| Non assegnati | **68 B** (0,32%) |
| Funzioni con scheletro identico | **2.195** |
| Funzioni con residuo | **281** |
| Residuo = prova di codice diverso? | **NO** |
| Equivalenza semantica? | **UNPROVEN** |
| ABI 26B131? | **UNPROVEN** |

La classificazione è **completa per copertura** ma **non causale**: 16.758 B sono coerenti con relocation/address e 4.557 B restano non spiegati dalla normalizzazione stretta. Gli esempi residui mostrano ancora symbolization di operandi, quindi il residuo è un **limite superiore**, non una prova di modifica del flusso. Nessuna dichiarazione di compatibilità 26B131.

**STOP rispettato:** sola lettura; nessuna scrittura di sezioni, estrazione, copia, build, firma o boot. Spazio libero 12.932.528 KiB (12,33 GiB) > 10 GiB.
