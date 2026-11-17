# T27 — AGENT-AMD — X6100 INSTRUCTION-LEVEL VERIFICATION

**Scope:** verificare se i byte residui di `__text` rappresentano modifiche reali alle istruzioni o differenze di simbolizzazione/relocation.  
**Modalità:** sola lettura; `otool -tvV`, `nm -a -n`, `otool -rv`, `otool -l`; confronto in memoria.  
**Esito:** **281 istanze residue / 4.557 B** su 21.383 B differenti. **0 differenze strutturali** rilevate: stesso numero di istruzioni, stessi opcode e stessi registri. Tutti i 4.557 B residui sono riconducibili a **operandi simbolici/address o target di salto**; nessuna equivalenza semantica è dimostrata.

---

## 1. Correzione del conteggio precedente

Il report `X6100-RESIDUAL-DIFF.md` indicava **284 funzioni / 4.577 B**. La verifica per **istanza** ha trovato tre nomi locali duplicati:

- `_getValidClk`
- `_copyOverDriveSettingsLimitsArray`
- `_copyClockLimitsArray`

Ogni nome compare due volte in `otool -tvV`. Il conteggio per nome aveva aggregato **20 B** di istanze pulite nel residuo; la corrispondenza per nome aveva inoltre accoppiato la prima istanza systemkc con l'ultima root2. La corrispondenza corretta per **indirizzo normalizzato** dà:

| Voce | Valore corretto |
|---|---:|
| Istanze `otool` con differenze | **2.478** |
| Nomi unici con differenze | **2.476** |
| Istanze pulite | **2.197** (2.195 nomi) |
| Byte puliti | **16.758** |
| Istanze residue | **281** |
| Byte residui | **4.557** |
| Non assegnati | **68** |
| Totale | **21.383** |

**Copertura:** 16.758 + 4.557 + 68 = **21.383 B**.

---

## 2. Metodo

### 2.1 Corrispondenza delle funzioni

Le funzioni sono state accoppiate per **indirizzo normalizzato**:

```text
root2.start + 0xdd6e000 = systemkc.start
```

- 9.227 funzioni `otool` per binario;
- **9.227/9.227 accoppiate**;
- 0 non accoppiate.

La corrispondenza per nome non è stata usata per i duplicati: i tre nomi locali duplicati hanno istanze distinte e istruzioni differenti.

### 2.2 Livelli di normalizzazione

1. **Baseline ristretta:** commenti rimossi; indirizzi RIP normalizzati; target di `callq`/salti normalizzati. È il criterio che definisce il residuo.
2. **Scheletro completo:** oltre alla baseline, tutti i simboli (inclusi `$__ZN…`, `_simbolo` e simboli locali senza underscore iniziale) e tutti i valori numerici sono sostituiti da un segnaposto. Opcode, registri e struttura degli operandi restano invariati.
3. **Simboli/address:** per ogni coppia di istruzioni, se almeno un lato contiene un simbolo, entrambi i lati vengono normalizzati completamente; se nessuno contiene simboli, i numeri restano e vengono confrontati.
4. **Target di salto:** `callq`, `j*`, `loop` e `loope` sono trattati come trasferimenti di controllo; il target viene normalizzato separatamente dall'opcode.

### 2.3 Criteri

| Categoria | Criterio |
|---|---|
| **Address/symbol-resolvable** | stesso numero di istruzioni, stessi opcode/registri; differenze solo in simboli, indirizzi o target |
| **Branch-target** | stesso opcode/registri; differisce solo il target di `loop`/`loope` |
| **Structural** | differisce numero di istruzioni, opcode, registri o forma degli operandi |
| **Ambiguous** | stesso scheletro ma valore numerico diverso senza simbolo associato |

---

## 3. Risultato complessivo

| Categoria | Istanze | Byte | Quota residuo |
|---|---:|---:|---:|
| **Address/symbol-resolvable** | 277 | **4.521** | **99,21%** |
| **Branch-target (`loop`/`loope`)** | 4 | **36** | **0,79%** |
| **Structural** | **0** | **0** | **0%** |
| **Ambiguous residuo** | **0** | **0** | **0%** |
| **Totale residuo** | **281** | **4.557** | **100%** |

- **0** funzioni con numero di istruzioni diverso.
- **0** funzioni con opcode diversi.
- **0** funzioni con registri diversi.
- **0** differenze strutturali residue dopo la normalizzazione dei target.

---

## 4. Top tre funzioni residue

| Byte | Funzione | Istruzioni | Differenze | Categoria |
|---:|---|---:|---:|---|
| **244** | `_PhwComm_OD8_ApplySettings` | 3.687 | 1 | address/symbol |
| **148** | `_PhwVega10_EnableDPMTasks` | 2.333 | 2 | address/symbol |
| **80** | `__ZN14AmdTtlServices27createSaveRestorePartitionsEv` | 219 | 1 | address/symbol |

### 4.1 `_PhwComm_OD8_ApplySettings`

```text
A 000000000df372ef movl $0xbc0, %esi
B 00000000001c92ef movl $__ZN35AMDRadeonX6100_AMDRadeonHWLibsX6100C1Ev, %esi
```

Stesso `movl`, stesso `%esi`; cambia la resa dell'operando: systemkc numerico, root2 simbolico.

### 4.2 `_PhwVega10_EnableDPMTasks`

```text
A 000000000dec34db movl $0xd30, %esi
B 00000000001554db movl $__ZN11OSMetaClassdlEPvm, %esi

A 000000000dec36db movl $0xd60, %esi
B 00000000001556db movl $__GLOBAL__D_a, %esi
```

Stesso opcode e registro; due operandi simbolici in root2, numerici in systemkc.

### 4.3 `createSaveRestorePartitions`

```text
A 000000000df6a0ae movl $0x1000, %edx
B 00000000001fc0ae movl $__ZN30AMDRadeonX6100_AMDRadeonHWLibsC2Ev, %edx
```

Stesso `movl`, stesso `%edx`; operando simbolico/numerico.

---

## 5. Quattro casi `loop`/`loope`

Questi quattro casi erano ambigui con la sola normalizzazione call/RIP; normalizzando il **target di salto** diventano address-resolvable:

| Byte | Funzione | Istruzione systemkc | Istruzione root2 |
|---:|---|---|---|
| 12 | `_PhwVega10_GetSOC15RegisterOffset` | `loop 0xdeb4e80` | `loop 0x146e80` |
| 8 | `_PhwVega12_OD8_UpdateSMCTableSetting` | `loop 0xdedf58c` | `loop 0x17158c` |
| 12 | `_PhwRenoir_SetPowerStateTasks` | `loope 0xdf20250` | `loope 0x1b2250` |
| 4 | `_queue_decode_2_0_build_command` | `loope 0xdf948dd` | `loope 0x2268dd` |

Il mnemonico e i registri sono identici; cambia solo l'indirizzo assoluto del target, coerente con lo shift di base/relocation. **Non sono differenze strutturali.**

---

## 6. Interpretazione

### 6.1 PROVEN

- 21.383 B differenti: **16.758 B puliti + 4.557 B residui + 68 B non assegnati**.
- 2.478 istanze `otool` con differenze; 2.476 nomi unici.
- 281 istanze residue; tutte hanno **stesso numero di istruzioni** delle corrispondenti root2.
- 281/281 hanno **stessi opcode e registri** dopo la normalizzazione.
- 277/281 (4.521 B) hanno differenze di simboli/address.
- 4/281 (36 B) hanno differenze di target `loop`/`loope`.
- **0** differenze strutturali; **0** ambigui residui.
- Root2 ha 6.243 external relocation entries; systemkc-all ne ha 0.

### 6.2 INFERRED

- Le differenze residue sono compatibili con **symbolization/relocation** e con il diverso modo di rendere i simboli locali (systemkc usa nomi senza underscore iniziale in alcuni operandi; root2 li rende con `_`).
- I 4.557 B non sono una prova di modifica del flusso: sono differenze di **operandi/target** a parità di scheletro.

### 6.3 UNPROVEN

- Che tutti i 4.557 B siano **solo** relocation: la normalizzazione non dimostra la causa.
- Che i valori numerici nascosti in istruzioni contenenti simboli siano invariati.
- L'equivalenza semantica, l'ABI e la compatibilità con 26B131.
- La causa delle differenze residue.

---

## 7. Limiti

1. `otool` non è un decompilatore: la normalizzazione confronta testo, non semantica.
2. La normalizzazione completa nasconde i valori numerici nelle istruzioni che contengono simboli; non prova che le costanti siano identiche.
3. La corrispondenza per offset assume lo stesso layout di `__text`; 9.227/9.227 funzioni accoppiate, ma non è una prova di provenienza.
4. `loop`/`loope` sono stati trattati come trasferimenti di controllo; se il target non fosse un indirizzo, la classificazione sarebbe diversa.
5. Nessuna esecuzione, nessun test funzionale, nessun boot.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Residuo corretto | **281 istanze / 4.557 B** |
| Differenze strutturali | **0** |
| Differenze di soli operandi/address | **281 / 4.557 B** |
| Differenze realmente dimostrate di istruzioni | **0** |
| Ambigui residui | **0** |
| Equivalenza semantica | **UNPROVEN** |
| ABI 26B131 | **UNPROVEN** |

La verifica instruction-level **non trova differenze di opcode, registri o numero di istruzioni**: i 4.557 B residui sono differenze di simboli, indirizzi o target di salto. Questo **non** dimostra che il kext sia equivalente o compatibile con 26B131; la copertura è strutturale, non semantica.

**STOP rispettato:** sola lettura; nessuna scrittura di sezioni, estrazione, copia, build, firma o boot. Spazio libero 12.932.260 KiB (12,33 GiB) > 10 GiB.
