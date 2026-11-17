# T27 — AGENT-AMD — FORMAT 11 SPEC VS OOB

> **CORREZIONE 2026-11-17:** la frase “i 4 record OOB hanno `isAuth=1`” è errata: hanno `isAuth=0` (bit 63 = 0). Vedi `T27-OOB-ISAUTH0-CORRECTION.md`.

**Scope:** verificare la definizione autorevole di `pointer_format=11` (`DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`), la semantica di `next`, lo stride, il terminatore e la possibilità di attraversare il page boundary; confrontare la specifica con i 4 record originali target/T6; classificare validità strutturale e runtime.

**Modalità:** sola lettura; header Apple XNU/dyld, codice `walk_chain`/`fixup_value`, report locali, 4 record originali; nessun download, modifica, build o patch.

**Esito:** Apple **non vieta** a `next` di attraversare il page boundary. Il formato 11 è **stride 1 byte**, `next` è un offset in byte e `walk_chain` **non esegue alcun controllo `page_end`**: avanza con `chain + next`. I 2 OOB **non sono quindi una violazione del contratto enforced dal loader**. Restano anomalie semantiche: il successore **inizia dentro la pagina ma il suo slot di 8 byte sfora nel pagina successivo**, e il suo contenuto è una copia shiftata, non uno slot dichiarato. Il runtime resta **UNPROVEN**; la particolarità intenzionale Apple resta **UNPROVEN**. T27 resta **OPEN**.

---

## 1. Definizione autorevole

Fonte Apple: `EXTERNAL_HEADERS/mach-o/fixup-chains.h`.

```c
enum {
    DYLD_CHAINED_PTR_64_KERNEL_CACHE     =  8,
    DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE = 11,  // stride 1, x86_64 kernel caches
};

struct dyld_chained_ptr_64_kernel_cache_rebase {
    uint64_t target     : 30,   // basePointers[cacheLevel] + target
             cacheLevel :  2,
             diversity  : 16,
             addrDiv    :  1,
             key        :  2,
             next       : 12,    // 1 or 4-byte stide
             isAuth     :  1;
};
```

**PROVEN:** il formato 11 è `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`, **stride 1**.
**PROVEN:** `next` è **12 bit**, descritto come offset a stride 1 o 4 byte.
**PROVEN:** il terminatore è `next == 0` nel codice XNU, non un valore speciale del campo.

---

## 2. Semantica di `next` in XNU

Fonte Apple: `osfmk/mach/dyld_kernel_fixups.h`, `walk_chain`.

```c
case DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE:
    if (chainContent.fixup64.next == 0) {
        chainEnd = 1;
    } else {
        chain = (union ChainedFixupPointerOnDisk*)
            ((uintptr_t)chain + chainContent.fixup64.next);
    }
    break;
```

**PROVEN:** `next` è aggiunto **in byte**.
**PROVEN:** `next == 0` termina la catena.
**PROVEN:** non esiste alcun `page_end`, `page_size` o confronto con il bordo pagina in `walk_chain`.
**PROVEN:** `page_start` è solo l’offset iniziale della catena nella pagina.

---

## 3. Page boundary

| Controllo | Presenza |
|---|---|
| `next` vietato oltre pagina | **NO** |
| `page_end` in `walk_chain` | **NO** |
| `page_size` usato per bound | **NO** |
| Slot obbligato a stare in pagina | **NO** |
| `page_start` entro pagina | **SÌ, per definizione** |

**PROVEN:** il formato e `walk_chain` **non impongono** che lo slot successore resti nella pagina.
**PROVEN:** `next` può portare il cursore oltre il bordo; il loader legge la pagina successiva.
**PROVEN:** non c’è un rifiuto esplicito per page crossing.

**Correzione:** i 2 successori **non iniziano fuori pagina**: iniziano a `0xFFA` e `0xFFE`, dentro la pagina, ma il loro slot di **8 byte** termina a `0x1002` e `0x1006`, sforando nel pagina successivo. La formulazione precedente “successore fuori pagina” era imprecisa.

---

## 4. I 4 record originali

| Provider | Record | `next` | Successore | Slot successore | Pagina successiva |
|---|---|---:|---|---|---|
| X5400 | `0x9C78FF0` | **10** | `0x9C78FFA` | `0x9C78FFA–0x9C79001` | start `0x4` |
| X5400 T6 | `0x9C6CFF0` | **10** | `0x9C6CFFA` | `0x9C6CFFA–0x9C6D001` | start `0x4` |
| AMDSupport | `0x13C13FF4` | **10** | `0x13C13FFE` | `0x13C13FFE–0x13C14005` | start `0x8` |
| AMDSupport T6 | `0x13C07FF4` | **10** | `0x13C07FFE` | `0x13C07FFE–0x13C08005` | start `0x8` |

**PROVEN:** il successore inizia dentro la pagina.
**PROVEN:** lo slot di 8 byte attraversa il bordo di **2 byte** (X5400) e **6 byte** (AMDSupport).
**PROVEN:** il successore non coincide con il `page_start` della pagina successiva.
**PROVEN:** il contenuto del successore è una copia shiftata, non un record dichiarato.
**PROVEN:** target/T6 sono coerenti.

---

## 5. `next=10` e terminatore

| Test | Esito |
|---|---|
| `next=10` è distanza valida | **SÌ** |
| `next=10` è sentinel | **NO** |
| `next=0` termina | **SÌ** |
| 2.244 `next=10` globali | **SÌ** |
| 2 ultimi `next=10` | **SÌ** |
| 18 run lunghe terminano 0 | **SÌ** |

**PROVEN:** `next=10` è una distanza normale.
**PROVEN:** non è un terminatore.
**PROVEN:** le 2 OOB sono le uniche con `next=10` come ultimo.

---

## 6. `fixup_value` e `isAuth`

`fixup_value` per il formato 11:

```c
const void* baseAddress = basePointers[fixupLoc->fixup64.cacheLevel];
if (baseAddress == 0) { *stop = 1; return; }
uintptr_t slidValue = (uintptr_t)baseAddress + fixupLoc->fixup64.target;
#if HAS_APPLE_PAC
if (fixupLoc->fixup64.isAuth) { slidValue = sign_pointer(...); }
#else
if (fixupLoc->fixup64.isAuth) {
    dyldLogFunc("Unexpected authenticated fixup\n");
    *stop = 1;
    return;
}
#endif
```

**PROVEN:** `cacheLevel` nullo ferma il loader.
**PROVEN:** su un percorso senza PAC, `isAuth=1` ferma il loader con “Unexpected authenticated fixup”.
**PROVEN:** i 4 record OOB hanno `isAuth=1`.
**CONDIZIONALE:** su x86_64 senza PAC il loader si fermerebbe **sul record OOB**, prima di applicare `next=10`; il page crossing non verrebbe raggiunto.
**UNPROVEN:** il valore effettivo di `HAS_APPLE_PAC` nel kernel 26B131 e il percorso runtime.

---

## 7. Validità strutturale vs runtime

| Livello | Esito |
|---|---|
| Header Apple vieta page crossing | **NO** |
| `walk_chain` controlla page_end | **NO** |
| Slot successore interamente in pagina | **NO, sfora di 2/6 byte** |
| Successore è un record dichiarato | **NO** |
| Successore è una copia shiftata | **SÌ** |
| Loader lo rifiuta per page crossing | **NO, nessun check** |
| Loader lo accetta | **UNPROVEN** |
| `isAuth` può fermarlo prima | **SÌ, condizionale** |
| Particolarità intenzionale Apple | **UNPROVEN** |
| Runtime | **UNPROVEN** |

**PROVEN:** non c’è una regola di page-bound enforced.
**PROVEN:** lo slot sfora la pagina.
**PROVEN:** il successore non è dichiarato.
**UNPROVEN:** accettazione o rifiuto runtime.

---

## 8. H2/H3/H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H2** | distanza + bound | **SUPPORTATA** | 2.244 distanze; 2 sforamenti |
| **H3** | linker error | **INDIZIARIA** | coda non terminata; page-start corretto |
| **H5** | loader rifiuta | **UNPROVEN** | nessun page check; `isAuth` condizionale |
| **H8** | slot omesso | **UNPROVEN** | nessun conteggio in-band |

---

## 9. Fonti e limiti

| Fonte | Uso |
|---|---|
| Apple `fixup-chains.h` | enum, struct, stride |
| Apple `dyld_kernel_fixups.h` | `walk_chain`, `fixup_value` |
| Report locali | 4 record, offset, page-start |
| macOS SDK locale | **non disponibile nel progetto** |
| Sorgenti XNU locale | **non disponibili nel progetto** |
| Runtime/trace | **assente** |

**PROVEN:** le fonti Apple open source definiscono il formato e il walk.
**PROVEN:** nel progetto non ci sono SDK/XNU locali.
**UNPROVEN:** una validazione runtime sul kernel 26B131.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| Formato 11 è x86_64 kernel cache | **SÌ** |
| Stride | **1 byte** |
| `next` è offset byte | **SÌ** |
| `next` può attraversare pagina | **SÌ, non vietato** |
| `walk_chain` controlla page_end | **NO** |
| Successore OOB inizia fuori pagina | **NO, inizia dentro** |
| Slot successore sfora pagina | **SÌ, 2/6 byte** |
| Successore è record valido | **NO, copia shiftata** |
| Page crossing viola il contratto | **NO** |
| Loader accetta/rifiuta | **UNPROVEN** |
| Particolarità Apple | **UNPROVEN** |
| H2 | **SUPPORTATA** |
| H3 | **INDIZIARIA** |
| H5/H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la definizione Apple è chiara: formato 11, stride 1, `next` in byte, terminatore 0; `walk_chain` non controlla il page boundary. Quindi `next=10` **può** portare oltre il bordo e i 2 OOB **non violano un controllo enforced**. La anomalia resta reale: il successore inizia dentro la pagina ma il suo slot di 8 byte sfora nel pagina successivo, e il contenuto è una copia shiftata, non un record dichiarato. Se `isAuth=1` incontra un percorso senza PAC, il loader si ferma **prima** del page crossing. L’accettazione runtime e una particolarità intenzionale Apple restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,22 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun download/modifica/build/patch.
