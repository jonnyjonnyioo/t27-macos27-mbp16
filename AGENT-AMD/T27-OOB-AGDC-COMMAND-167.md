# T27 — AGENT-AMD — AGDC COMMAND / INPUT BUFFER (167)

**Scope:** identificare quale comando AGDC fornisce il buffer `in` contenente il bitmask `0x2` a `vendor_doDeviceAttribute`; ricostruire gli ID comando; cercare caller locali; identificare struttura, dimensione e inizializzazione del buffer `unsigned long *in`; confrontare X6000Framebuffer e AMDSupport; verificare se `0x2` identifica un’operazione o una capability; indicare le evidenze locali per il target.

**Modalità:** sola lettura. Nessun boot, trace, modifica, build o download. Comandi: `grep`, `find`, `nm`, `otool`, `strings`, `plutil`, `shasum`.

**Esito:** **PROVEN** che il ramo che scrive `LoadHWServices` è il **comando 3** di `vendor_doDeviceAttribute`; il buffer `in` è letto come bitmask nella sua prima parola e il bit `0x2` attiva la scrittura. **PROVEN** che X6000Framebuffer e AMDSupport usano la stessa convenzione. **PROVEN** che il buffer è un input esterno di AGDC e che non esistono caller locali. **UNPROVEN** chi emetta il comando 3 sul MacBookPro16,1 e se il buffer contenga `0x2`. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| `AppleGraphicsDeviceControl_re.h` | `99a829f1cefc5f3d56e005d17883cf854e2c6b2e056d7c570d4034fa83e26ffa` |
| `nvrm-agdc.cpp` | `ba68e3f1abdb4f9d0e4dbb9b7ae2ac1b2f19786b38714e42177f5a49665a40a9` |
| X6000Framebuffer executable | `a2469429602210e64a74292a30b06353d9e0f75cd6b8b65f98324e64fa0b4536` |
| X6000Framebuffer `Info.plist` | `1b28b9aab877c4b3362edabde5a512d45d0cf97c10611b034c8ea53995a9f573` |
| HWServices `Info.plist` | `c6dcc67430bbbff1490e7101d395b3dbcfe248c10adc889efd59dd1689810bf0` |
| Report 166 | `14bc4fad486ebacdba49021da04b1823d72f9551cfcc89907e0e2bc0eb0ecd7f` |

**Ambiente:** macOS `26.7.3`, build `25G342`.
**Spazio:** **15.399.212 KiB ≈ 14,69 GiB** > 10 GiB.

---

## 2. Comando 3

### 2.1 X6000Framebuffer

`AmdGpuWrangler::vendor_doDeviceAttribute`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0xbf989a2` | `cmpl $0x3, %r13d` | confronto comando |
| `0xbf989a6` | `je 0xbf989d8` | salto al ramo comando 3 |
| `0xbf989d8` | test `r12` / `r15` | output/attributi |
| `0xbf989fc` | test `rbx` | input non nullo |
| `0xbf98a05` | `getProvider` | provider PCI |
| `0xbf98a1c` | `movl (%rbx), %eax` | prima parola input |
| `0xbf98a1e` | `testb $0x2, %al` | bit HWServices |
| `0xbf98a25` | `"LoadHWServices"` | chiave |
| `0xbf98a34` | `setProperty` | valore `true` |
| `0xbf98a45` | `registerService(2)` | pubblicazione |

**PROVEN:** il comando è **3**.
**PROVEN:** il bit `0x2` è nella prima parola del buffer `in`.
**PROVEN:** il ramo termina con `registerService(2)`.

### 2.2 AMDSupport

`AtiGpuWrangler::vendor_doDeviceAttribute`:

| Indirizzo | Istruzione |
|---:|---|
| `0x13b844cf` | `subl $0x1, %eax` |
| `0x13b844d6` | ricarica comando |
| `0x13b844dc` | `subl $0x3, %eax` |
| `0x13b844df` | `je 0x13b84513` |
| `0x13b84513` | ramo attributi |
| `0x13b845ff` | `andl $0x2, %eax` |
| `0x13b84611` | `"LoadHWServices"` |
| `0x13b8461d` | `setProperty` |

**PROVEN:** anche AMDSupport usa il comando **3**.
**PROVEN:** stesso bit `0x2`.
**PROVEN:** stessa chiave e stesso valore.

---

## 3. Struttura del buffer `in`

### 3.1 ABI

Dall’header locale:

```cpp
vendor_doDeviceAttribute(
    unsigned int cmd,       // esi
    unsigned long *in,      // rdx
    unsigned long inSize,   // rcx
    unsigned long *out,     // r8
    unsigned long *outSize, // r9
    IOExternalMethodArguments *args);
```

| Campo | Tipo | Uso AMD |
|---|---|---|
| `in` | `unsigned long *` | primo word = bitmask |
| `inSize` | `unsigned long` | controllo dimensione |
| `out` | `unsigned long *` | output |
| `outSize` | `unsigned long *` | dimensione output |

**PROVEN (header locale):** `in` è un puntatore a buffer.
**PROVEN (codice AMD):** la prima parola è letta con `movl`.
**PROVEN:** il bit `0x2` è il secondo bit del primo word.
**UNPROVEN:** la dimensione minima contrattuale e la struttura completa.

### 3.2 Dimensioni

| Elemento | Valore |
|---|---|
| parola letta | 32 bit (`movl`) |
| bit usato | `0x2` |
| buffer minimo per il test | **4 byte** |
| dimensione dichiarata | **UNPROVEN** |
| campi successivi | **UNPROVEN** |

**PROVEN:** il test richiede almeno 4 byte.
**PROVEN:** il codice non documenta gli altri campi.
**UNPROVEN:** se il buffer sia un array di `unsigned long` o una struttura.

---

## 4. Caller e inizializzazione

| Ricerca | Esito |
|---|---|
| call dirette a `0xbf9894e` | **0** |
| call dirette a `0x13b84370` | **0** |
| riferimenti testuali alla tabella | **0** |
| caller AGDC locale | **assente** |
| buffer `in` osservato | **assente** |

**PROVEN:** il buffer è costruito fuori dai due kext.
**PROVEN:** non esiste un’inizializzazione locale del bit `0x2`.
**UNPROVEN:** il caller che invia il comando 3.

### 4.1 Chi può inviarlo

| Candidato | Evidenza |
|---|---|
| `AppleGraphicsDeviceControl` | classe astratta; implementazione assente |
| `AmdAgdcServices` | dispatcher AGDC; non chiama direttamente il Wrangler |
| `callPlatformFunction` | dispatch generico; nessun legame diretto |
| userspace AGDC | possibile; nessuna prova locale |

**INFERRED:** il comando 3 arriva dal livello AGDC/AppleGraphicsDeviceControl.
**UNPROVEN:** il chiamante effettivo.

---

## 5. Significato del bit `0x2`

| Bit | Effetto osservato |
|---|---|
| `0x1` | `LoadController` (AMDSupport) |
| `0x2` | `LoadHWServices` + `LoadAccelerator` (X6000) |
| `0x3` | entrambi + `registerService` |

**PROVEN:** `0x2` attiva `LoadHWServices` e, in X6000, anche `LoadAccelerator`.
**PROVEN:** non è una capability GPU generica: è un bit di azione di caricamento.
**UNPROVEN:** la semantica ufficiale AGDC.
**UNPROVEN:** se `0x2` venga usato solo per HWServices o per un gruppo di load.

---

## 6. Confronto X6000 / AMDSupport

| Elemento | X6000 | AMDSupport |
|---|---|---|
| comando | **3** | **3** |
| input | `in` | `in` |
| bit | `0x2` | `0x2` |
| provider | `getProvider` | `getProvider` |
| chiave | `LoadHWServices` | `LoadHWServices` |
| valore | `true` | `true` |
| call dirette | **0** | **0** |

**PROVEN:** la convenzione è identica.
**INFERRED:** è un contratto AMD interno stabile.
**UNPROVEN:** quale implementazione sia attiva sul target.

---

## 7. Evidenze locali per MacBookPro16,1

| Evidenza | Stato |
|---|---|
| `IOPCIMatch 0x73401002` | **PROVEN** |
| classe `AmdGpuWrangler` in SystemKC | **PROVEN** |
| comando 3 nel codice | **PROVEN** |
| emissione del comando 3 | **UNPROVEN** |
| buffer con `0x2` | **UNPROVEN** |
| `LoadHWServices=true` su ioreg | **UNPROVEN** |

**PROVEN:** il target ha il percorso potenziale.
**UNPROVEN:** l’input effettivo.

---

## 8. Prova minima necessaria

| Prova | Cosa dimostra |
|---|---|
| buffer `in` del comando 3 | presenza del bit `0x2` |
| caller AGDC | chi invia il comando |
| `ioreg` con `LoadHWServices` | effetto sul PCI |
| log AGDC del comando 3 | conferma runtime |

**PROVEN:** nessuna prova è disponibile nei file attuali.
**UNPROVEN:** il valore target.

---

## 9. Diagnosi

| Priorità | Elemento | Stato |
|---:|---|---|
| 1 | emissione comando 3 | **UNPROVEN** |
| 2 | buffer `in` con `0x2` | **UNPROVEN** |
| 3 | `setProperty("LoadHWServices")` | **PROVEN codice; runtime UNPROVEN** |
| 4 | HWServices e X6100 | **PROVEN statico** |
| 5 | X6100 operativo | **UNPROVEN runtime** |

**Diagnosi:** il comando è identificato: **3**, con buffer `in` la cui prima parola contiene il bit `0x2`. Il bit non è una capability GPU né una proprietà PCI letta direttamente; è un’azione di load. X6000 e AMDSupport condividono la stessa convenzione. Manca l’emissione del comando sul target e il contenuto del buffer; senza questi, `LoadHWServices` resta **UNPROVEN**.

---

## 10. Verdetto

| Domanda | Risposta |
|---|---|
| Comando che porta il bit `0x2` | **3** |
| Bit nel buffer `in` | **PROVEN** |
| Dimensione minima | **4 byte** |
| Struttura completa | **UNPROVEN** |
| Caller locale | **NO** |
| X6000 e AMDSupport coerenti | **SÌ** |
| Target emette comando 3 con `0x2` | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il comando AGDC è **3**; il buffer `in` è un input esterno e la sua prima parola contiene il bitmask. Il bit `0x2` attiva `LoadHWServices` e, in X6000, anche `LoadAccelerator`; la stessa convenzione è in AMDSupport. Non ci sono caller locali né un buffer osservato; il comando 3 e il bit `0x2` sul MacBookPro16,1 restano **UNPROVEN**. La prova minima è il buffer `in` del comando 3 o un `ioreg` con `LoadHWServices=true`. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **15.399.212 KiB ≈ 14,69 GiB** > 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
