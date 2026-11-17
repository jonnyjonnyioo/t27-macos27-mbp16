# T27 — AGENT-AMD — X6100 RELOCATION / EXTERNAL CALL ANALYSIS

**Scope:** verificare se le differenze nelle call di `AMDRadeonX6100HWLibs` sono dovute a **relocation, risoluzione di simboli o modifiche effettive del flusso di controllo**.  
**Modalità:** sola lettura; `otool -rv`, `otool -l`, `nm -a -n`, `otool -tvV`. Nessuna scrittura, estrazione, copia, build o boot.  
**Esito:** `systemkc-all` **non ha relocation entries**; root2 ne ha **6.243 esterne**. Le tre funzioni campione hanno **lo stesso numero e ordine di call**; i target numerici di systemkc corrispondono, per conteggio e posizione, ai simboli esterni di root2. **Nessuna modifica di flusso è dimostrata**; l’equivalenza finale resta **UNPROVEN**.

---

## 1. Relocation table

| Binario | `otool -rv` | Interpretazione |
|---|---:|---|
| `systemkc-all` `e521d3cc…` | **1 riga** (solo header) | **0 relocation entries** |
| root2 `00b6214e…` | **13.906 righe** | **6.243 external relocation entries** |

Root2 conserva una tabella di relocation esterna; `systemkc-all` no. Questo è il fatto centrale: le due copie non sono nello stesso stato di linking.

### 1.1 Esempi di entry root2

```text
address  pcrel length extern type    scattered symbolnum/value
003ae068 False ?( 3)  True   UNSIGND False     __ZN11IOPCIDevice9metaClassE
003aea40 False ?( 3)  True   UNSIGND False     __ZN11OSMetaClass21_RESERVEDOSMetaClass0Ev
003af3a0 False ?( 3)  True   UNSIGND False     __ZN11OSMetaClass21_RESERVEDOSMetaClass0Ev
```

Le entry sono indirizzi di dati (`0x3ae...`) e simboli esterni, non solo call. La tabella dimostra che root2 **richiede ancora risoluzione**.

### 1.2 Conteggi per simbolo esterno

| Simbolo | Entry root2 |
|---|---:|
| `_PE_enter_debugger` | **3.849** |
| `_kprintf` | **580** |
| `___bzero` | **380** |
| `_memcpy` | **58** |

Questi quattro simboli hanno 4.867 entry; le restanti 1.376 completano le 6.243.

---

## 2. Symbol table / dysymtab

| Campo | systemkc | root2 |
|---|---:|---:|
| `LC_SYMTAB.symoff` | 16.404.480 | 16.465.744 |
| `LC_SYMTAB.nsyms` | 12.602 | 12.917 |
| `LC_DYSYMTAB.nlocalsym` | 12.182 | 12.497 |
| `LC_DYSYMTAB.nextdefsym` | **72** | **72** |
| `LC_DYSYMTAB.nundefsym` | **348** | **348** |
| `LC_DYSYMTAB.tocoff` | 0 | 0 |
| `LC_DYSYMTAB.modtaboff` | 0 | 0 |
| `LC_DYSYMTAB.extrefsymoff` | 0 | 0 |

I 72 external defined e i 348 undefined sono invariati; root2 ha 315 local symbols in più. La differenza è nel **linking/relocation**, non nell’elenco degli export/import.

`otool -Iv` non mostra entry indirette in nessuno dei due; `otool -L` non mostra dylib.

---

## 3. Call-site nelle tre funzioni

### 3.1 Conteggi

| Funzione | Call systemkc | Call root2 | Unique target systemkc/root2 |
|---|---:|---:|---:|
| `_PhwComm_OD8_ApplySettings` | **282** | **282** | 28 / 28 |
| `sendRequestToMESE` | **37** | **37** | 6 / 6 |
| `_PhwVega10_EnableDPMTasks` | **148** | **148** | 45 / 45 |

Nessuna call aggiunta o rimossa nei tre campioni; la sequenza delle posizioni è la stessa (a meno del base shift).

### 3.2 Corrispondenze numerico → simbolo

| Target systemkc | Target root2 | Occorrenze in `PhwComm` | Occorrenze in `sendRequest` | Occorrenze in `PhwVega10` |
|---|---|---:|---:|---:|
| `0x10378` | `_PE_enter_debugger` | 55 | 0 | 35 |
| `0x10114` | `_kprintf` | 0 | 26 | 0 |
| `0x100b4` | `___bzero` | 0 | 3 | 2 |
| `0x100de` | `_memcpy` | 0 | 0 | 2 |

`_PE_enter_debugger`, `_kprintf`, `___bzero` e `_memcpy` sono **undefined external** in entrambi. Il mapping numerico è **INFERRED** da conteggio, posizione e ricorrenza; non esiste un simbolo `0x10378` in `nm` root2.

### 3.3 Esempi di call-site

`_PhwComm_OD8_ApplySettings`:

```text
A 000000000df36014 callq 0x10378
B 00000000001c8014 callq _PE_enter_debugger
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

Le istruzioni di call hanno **stessa posizione relativa** e **stesso numero di occorrenze**; cambia la rappresentazione del target.

---

## 4. Interpretazione

### 4.1 PROVEN

- `systemkc-all` ha **0 relocation entries**; root2 ha **6.243 external relocation entries**.
- I 72 export e i 348 undefined hanno gli stessi nomi.
- Le tre funzioni campione hanno lo stesso numero di call (282/37/148) e gli stessi target per nome, salvo la resa numerica di systemkc.
- Root2 contiene relocation per `_PE_enter_debugger` (3.849), `_kprintf` (580), `___bzero` (380), `_memcpy` (58).
- `otool -Iv` non mostra entry indirette; `otool -L` non mostra dylib.
- `LC_DYSYMTAB` conserva 72 extdef e 348 undef in entrambi.

### 4.2 INFERRED

- Le differenze numerico/simbolico nelle call sono **coerenti con relocation e symbol resolution**, non con un cambio di destinazione o di flusso.
- `0x10378`, `0x10114`, `0x100b4`, `0x100de` corrispondono ai quattro esterni per conteggio/posizione.
- Root2 è in uno stato **pre-relocation**; `systemkc-all` è **post-relocation/senza tabella**.
- La differenza di `__text` include quindi una componente di **operandi di call/relocation**; non è solo codice logico.

### 4.3 UNPROVEN

- Che **tutte** le 21.383 differenze di `__text` siano relocation: alcune possono essere codice/compilazione.
- Che i target finali dopo applicazione delle 6.243 relocation coincidano semanticamente.
- L’equivalenza funzionale e l’ABI.
- La compatibilità con 26B131 e il caricamento.
- La causa delle differenze non-call.

---

## 5. Conclusione

| Domanda | Risposta |
|---|---|
| systemkc ha relocation? | **NO**: 0 entry |
| root2 ha relocation? | **SÌ**: 6.243 esterne |
| Call aggiunte/rimosse nei tre campioni? | **NO** |
| Target numerici ↔ simboli? | **INFERRED**, coerente |
| Cambio di flusso dimostrato? | **NO** |
| Tutte le differenze sono relocation? | **NO dimostrato** |
| External/undefined invariati? | **SÌ**: 72/348 |
| Equivalenza semantica? | **UNPROVEN** |
| ABI 26B131? | **UNPROVEN** |

Le differenze nelle call sono **coerenti con relocation e symbol resolution**: root2 conserva 6.243 relocation esterne, `systemkc-all` nessuna; le tre funzioni hanno le stesse call e gli stessi target per nome. Questo **non** dimostra che l’intero `__text` sia equivalente: restano 21.383 B differenti, 2.573 funzioni e nessuna prova di ABI o compatibilità 26B131.

**STOP rispettato:** sola lettura; nessuna scrittura, estrazione, copia, build, firma o boot. Spazio libero 12.923.368 KiB (12,32 GiB) > 10 GiB.
