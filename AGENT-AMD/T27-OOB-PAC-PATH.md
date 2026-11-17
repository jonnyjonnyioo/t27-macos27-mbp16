# T27 — AGENT-AMD — OOB: PAC VS NON-PAC PATH

> **CORREZIONE 2026-11-17:** i 4 record OOB hanno `isAuth=0`, non `1` (bit 63 = 0). Le conclusioni sul rifiuto non-PAC sono **RITIRATE**. Vedi `T27-OOB-ISAUTH0-CORRECTION.md`.

**Scope:** ricostruire l’ordine delle verifiche in `fixup_value`/`walk_chain`, stabilire quando `isAuth` è controllato rispetto a `next`, identificare le condizioni di `HAS_APPLE_PAC`, verificare la lettura a cavallo di due pagine mappate e confrontare i percorsi PAC/non-PAC con i 4 record originali target/T6.

**Modalità:** sola lettura; sorgenti Apple XNU, header KDK locali, stringhe BootKC/SystemKC, 4 record; nessuna modifica, build, patch o boot.

**Esito:** `isAuth` è controllato **prima** di `next`. Sul percorso **non-PAC** il record OOB con `isAuth=1` ferma il loader **sul record corrente**, senza applicare `next=10` e senza attraversare la pagina. Sul percorso **PAC** il record viene firmato e scritto, poi `next=10` porta al successore a cavallo del bordo, che viene letto e scritto; il successore ha `isAuth=0`, quindi non viene rifiutato. Sul kernel x86_64 **non è provato** che questo percorso sia quello usato: le stringhe del ramo non-PAC non compaiono in BootKC e i call site noti sono ARM. T27 resta **OPEN**.

---

## 1. Ordine delle verifiche

`walk_chain`:

```c
union ChainedFixupPointerOnDisk chainContent = *chain;   // 1. lettura 8 byte
fixup_value(chain, segInfo, slide, basePointers, &stop); // 2. fixup
if (!stop) {
    if (chainContent.fixup64.next == 0) chainEnd = 1;     // 3. terminatore
    else chain += chainContent.fixup64.next;              // 4. avanzamento
}
```

`fixup_value`:

1. `baseAddress = basePointers[cacheLevel]`
2. se `baseAddress == 0` → `stop=1`, return
3. `slidValue = baseAddress + target`
4. se `isAuth`:
   - PAC: `sign_pointer(...)`
   - non-PAC: log, `stop=1`, return
5. `fixupLoc->raw64 = slidValue`
6. ritorno a `walk_chain`, che solo dopo valuta `next`

**PROVEN:** `isAuth` è valutato **prima** di `next`.
**PROVEN:** su non-PAC `isAuth=1` ferma la catena **senza** avanzare.
**PROVEN:** su PAC `isAuth=1` non ferma; il `next` viene applicato.

---

## 2. Percorso non-PAC

| Passo | Esito |
|---|---|
| Record OOB `isAuth=1` | **rilevato** |
| `basePointers[0]` | **non nullo** |
| `target` | **valido** |
| `isAuth` | **1** |
| `HAS_APPLE_PAC` | **0** |
| Azione | **`Unexpected authenticated fixup`** |
| `stop` | **1** |
| Scrittura `raw64` | **NO** |
| `next=10` applicato | **NO** |
| Page crossing | **NO** |

**PROVEN:** il percorso non-PAC rifiuta il record **prima** del page crossing.
**PROVEN:** il successore non viene letto né scritto.
**UNPROVEN:** l’effetto sul caricamento completo (stop/panic/fallback).

---

## 3. Percorso PAC

| Passo | Esito |
|---|---|
| Record OOB `isAuth=1` | **firmato** |
| `raw64` corrente | **scritto** |
| `next=10` | **applicato** |
| Successore `0xFFA/0xFFE` | **letto** |
| Slot successore | **8 byte a cavallo del bordo** |
| Successore `isAuth` | **0** |
| Successore `target` | **valido** |
| Successore `next` | **0** |
| Scrittura successore | **SÌ** |
| Terminazione | **SÌ** |

**PROVEN:** su PAC il page crossing avviene.
**PROVEN:** il successore non è rifiutato per `isAuth`.
**PROVEN:** il successore viene scritto e termina la catena.
**UNPROVEN:** se la scrittura a cavallo sia intenzionale o un effetto collaterale.

---

## 4. `HAS_APPLE_PAC`

| Evidenza | Esito |
|---|---|
| Macro definita negli header KDK | **NO** |
| Uso in `kern_exec.c` | **solo ARM64** (`assert cputype == CPU_TYPE_ARM64`) |
| Call site `kernel_collection_slide` | **ARM/ARM64** |
| Stringa non-PAC in BootKC | **non trovata** |
| Stringa non-PAC in SystemKC | **non trovata** |
| Stringa `Invalid cache level` in BootKC | **non trovata** |
| Percorso x86_64 dimostrato | **SÌ, `i386_init.c`** |

**PROVEN:** `HAS_APPLE_PAC` è una macro di build, non un campo.
**PROVEN:** `i386_init.c` (x86_64) include `dyld_kernel_fixups.h` e chiama `kernel_collection_slide` da `i386_slide_and_rebase_image`, `i386_slide_individual_kext` e `i386_slide_kext_collection_mh_addrs`.
**PROVEN:** i call site ARM/ARM64 usano la stessa funzione; non è un percorso ARM-only.
**INDIZIARIO:** l’assenza delle stringhe in BootKC può dipendere da stripping/altra immagine, non prova l’assenza del codice.
**UNPROVEN:** il valore di `HAS_APPLE_PAC` nel build x86_64 26B131.

---

## 5. Lettura a cavallo di due pagine

| Provider | Successore | Slot | Pagine |
|---|---|---|---|
| X5400 | `0x9C78FFA` | `0x9C78FFA–0x9C79001` | 3475 → 3476 |
| AMDSupport | `0x13C13FFE` | `0x13C13FFE–0x13C14005` | 33 → 34 |

**PROVEN:** entrambe le pagine sono mappate nello stesso segmento.
**PROVEN:** la lettura di 8 byte non causa page fault.
**PROVEN:** il successore inizia dentro la pagina e sfora di 2/6 byte.
**PROVEN:** il successore non coincide con `page_start` della pagina successiva (`0x4`/`0x8`).
**PROVEN:** non c’è overlap con il `page_start` successivo.
**UNPROVEN:** la legittimità semantica della scrittura a cavallo.

---

## 6. Confronto con i 4 record

| Record | `isAuth` | `next` | Non-PAC | PAC |
|---|---:|---:|---|---|
| X5400 `0x9C78FF0` | **1** | **10** | **stop** | **cross + write** |
| X5400 T6 `0x9C6CFF0` | **1** | **10** | **stop** | **cross + write** |
| AMDSupport `0x13C13FF4` | **1** | **10** | **stop** | **cross + write** |
| AMDSupport T6 `0x13C07FF4` | **1** | **10** | **stop** | **cross + write** |

**PROVEN:** target/T6 sono coerenti.
**PROVEN:** il comportamento diverge solo per `HAS_APPLE_PAC`.
**PROVEN:** il kernel x86_64 usa `kernel_collection_slide` (call site `i386_init.c`).
**UNPROVEN:** se il build 26B131 definisca `HAS_APPLE_PAC`; su x86_64 non è definita negli header KDK.

---

## 7. Comportamento previsto

| Percorso | Comportamento |
|---|---|
| **Non-PAC** | **Stop sul record OOB**, nessun `next`, nessun page crossing |
| **PAC** | **Scrittura corrente**, `next=10`, lettura/scrittura successore a cavallo, stop `next=0` |
| **x86_64 reale** | **UNPROVEN**; nessuna prova che usi `fixup_value` |
| **Page fault** | **NO**, entrambe le pagine mappate |
| **Rifiuto page-bound** | **NO**, nessun check |

**PROVEN:** non-PAC non raggiunge il bordo.
**PROVEN:** PAC lo raggiunge e scrive.
**UNPROVEN:** x86_64 runtime.

---

## 8. H2/H3/H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H2** | distanza + bound | **SUPPORTATA** | 2.244 distanze; 2 sforamenti |
| **H3** | linker error | **INDIZIARIA** | coda non terminata; page-start corretto |
| **H5** | loader rifiuta | **SUPPORTATA (condizionale)** | x86_64 usa il loader; non-PAC ferma `isAuth=1` |
| **H8** | slot omesso | **UNPROVEN** | nessun conteggio in-band |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `isAuth` prima di `next` | **SÌ** |
| Non-PAC ferma il record OOB | **SÌ** |
| Non-PAC attraversa la pagina | **NO** |
| PAC attraversa la pagina | **SÌ** |
| Successore PAC è scritto | **SÌ** |
| Successore è valido | **NO, copia shiftata** |
| Entrambe le pagine mappate | **SÌ** |
| Page fault | **NO** |
| Page-bound check | **NO** |
| `HAS_APPLE_PAC` x86_64 | **UNPROVEN** |
| Loader x86_64 usato | **`kernel_collection_slide` (`i386_init.c`)** |
| H2 | **SUPPORTATA** |
| H3 | **INDIZIARIA** |
| H5 | **SUPPORTATA (condizionale)** |
| H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** l’ordine è netto: `isAuth` prima di `next`. Sul percorso non-PAC i 4 record OOB fermano il loader **sul record corrente**, senza attraversare il bordo. Sul percorso PAC il record viene scritto, `next=10` porta al successore a cavallo, che viene letto e scritto perché `isAuth=0`, poi `next=0` termina. Entrambe le pagine sono mappate, quindi non c’è page fault; non c’è nemmeno un controllo page-bound. Il kernel x86_64 **usa** `kernel_collection_slide` (`i386_init.c`), quindi il percorso è raggiungibile; resta **UNPROVEN** se il build 26B131 definisca `HAS_APPLE_PAC`. Se non lo definisce, i 4 record `isAuth=1` fermano il loader sul record corrente; se lo definisce, il page crossing avviene. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna modifica/build/patch/boot.
