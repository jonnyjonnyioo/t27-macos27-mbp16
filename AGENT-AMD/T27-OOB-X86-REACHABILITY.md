# T27 — AGENT-AMD — FORMAT 11 X86_64 REACHABILITY

> **CORREZIONE 2026-11-17:** i 4 record OOB hanno `isAuth=0`, non `1` (bit 63 = 0). Le conclusioni sul rifiuto non-PAC sono **RITIRATE**. Vedi `T27-OOB-ISAUTH0-CORRECTION.md`.

**Scope:** ricostruire il call graph di `walk_chain`/`fixup_value`, verificare i call site x86_64, le condizioni `CPU_TYPE_X86_64`/`ARM64`/`HAS_APPLE_PAC`, l’esistenza di implementazioni Intel alternative del formato 11 e la gestione di `isAuth=1`; stabilire quando il successore `next=10` è raggiungibile.

**Modalità:** sola lettura; sorgenti Apple XNU, KDK locale, 4 record; nessuna modifica, build, patch o boot.

**Esito:** il percorso **è raggiungibile su x86_64**: `osfmk/i386/i386_init.c` include `mach/dyld_kernel_fixups.h` e chiama `kernel_collection_slide` da tre funzioni. Non esiste un’implementazione Intel alternativa del formato 11. `isAuth=1` non ha una gestione x86_64 separata: sul percorso non-PAC ferma il loader **prima** di `next`. I 4 record OOB sono `isAuth=1`; quindi il successore `next=10` è raggiungibile **solo** se `HAS_APPLE_PAC` è attivo (percorso PAC) oppure se `isAuth` fosse 0. Il valore di `HAS_APPLE_PAC` nel build 26B131 resta **UNPROVEN**. **H5 SUPPORTATA (condizionale)**; **H8 UNPROVEN**. T27 resta **OPEN**.

---

## 1. Call graph verificato

```text
osfmk/i386/i386_init.c
  i386_slide_and_rebase_image()
  i386_slide_individual_kext()
  i386_slide_kext_collection_mh_addrs()
        |
        v
kernel_collection_slide()
        |
        v
walk_chain()
        |
        v
fixup_value()
```

```text
osfmk/arm/arm_init.c
osfmk/arm64/sptm/arm_init_sptm.c
        |
        v
kernel_collection_slide() -> walk_chain() -> fixup_value()
```

**PROVEN:** `i386_init.c` include `mach/dyld_kernel_fixups.h`.
**PROVEN:** `i386_init.c` chiama `kernel_collection_slide` in **tre** funzioni.
**PROVEN:** il percorso x86_64 non è ARM-only.
**PROVEN:** ARM/ARM64 usano la stessa catena.

---

## 2. Call site x86_64

| Funzione | Chiama `kernel_collection_slide` | Uso |
|---|---|---|
| `i386_slide_and_rebase_image` | **SÌ** | KC primaria all’avvio |
| `i386_slide_individual_kext` | **SÌ** | kext/collection pageable |
| `i386_slide_kext_collection_mh_addrs` | **SÌ** | collection con adjust |
| `arm_slide_rebase_and_sign_image` | **SÌ** | ARM |
| `arm_init_sptm` | **SÌ** | ARM64/SPTM |

**PROVEN:** il loader è invocato su x86_64.
**PROVEN:** non serve dedurre la raggiungibilità: il call site è verificato.
**UNPROVEN:** quale delle tre funzioni elabori i 4 record nel boot reale.

---

## 3. Condizioni di compilazione

| Condizione | Evidenza |
|---|---|
| `CPU_TYPE_X86_64` | `i386_init.c` è il file x86_64; nessun `#if` attorno alle chiamate |
| `ARM64` | `arm_init.c` / `arm_init_sptm.c` |
| `HAS_APPLE_PAC` | macro di build, non campo; non definita negli header KDK |
| `kern_exec.c` con PAC | `assert(cputype == CPU_TYPE_ARM64)` |
| `HAS_APPLE_PAC` nel build 26B131 | **UNPROVEN** |

**PROVEN:** il codice x86_64 compila il call site.
**PROVEN:** `HAS_APPLE_PAC` è una scelta di build, non un bit del record.
**UNPROVEN:** se il build 26B131 la definisca per x86_64.

---

## 4. Implementazioni Intel alternative

| Ricerca | Esito |
|---|---|
| Secondo `kernel_collection_slide` x86_64 | **NO** |
| Loader Intel separato per formato 11 | **NO** |
| `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` in dyld utente | **NO** |
| Implementazione in Stela locale | **solo formato 8** |
| Implementazione in BootKC/SystemKC | **nessun simbolo** |
| Fonti Apple | **unica: `dyld_kernel_fixups.h`** |

**PROVEN:** non è emersa un’implementazione Intel alternativa.
**PROVEN:** il formato 11 è gestito dallo stesso `kernel_collection_slide`.
**UNPROVEN:** una variante non simbolizzata nel binario.

---

## 5. `isAuth=1` su x86_64

`fixup_value`:

```c
#if HAS_APPLE_PAC
if (fixupLoc->fixup64.isAuth) {
    slidValue = sign_pointer(...);
}
#else
if (fixupLoc->fixup64.isAuth) {
    dyldLogFunc("Unexpected authenticated fixup\n");
    *stop = 1;
    return;
}
#endif
fixupLoc->raw64 = slidValue;
```

**PROVEN:** non esiste un ramo `CPU_TYPE_X86_64` separato.
**PROVEN:** l’unica differenza è `HAS_APPLE_PAC`.
**PROVEN:** con macro assente, `isAuth=1` ferma **prima** della scrittura e di `next`.
**PROVEN:** con macro presente, `isAuth=1` viene firmato e `next` viene applicato.
**UNPROVEN:** il valore della macro nel kernel 26B131.

---

## 6. Condizioni per raggiungere `next=10`

| Condizione | Successore raggiunto |
|---|---|
| `isAuth=0` | **SÌ** |
| `isAuth=1` + PAC | **SÌ** |
| `isAuth=1` + non-PAC | **NO** |
| `isAuth=1` + cacheLevel nullo | **NO** |
| `isAuth=1` + formato non 11 | **NO** |
| I 4 OOB | **isAuth=1** |

**PROVEN:** i 4 OOB hanno `isAuth=1`.
**PROVEN:** su non-PAC il successore non è raggiunto.
**PROVEN:** su PAC il successore è raggiunto.
**UNPROVEN:** se il kernel 26B131 usi PAC su x86_64.

---

## 7. H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H5** | loader rifiuta | **SUPPORTATA (condizionale)** | x86_64 chiama il loader; non-PAC ferma `isAuth=1` |
| **H8** | slot omesso | **UNPROVEN** | nessun conteggio in-band |
| **H2** | distanza + bound | **SUPPORTATA** | 2.244 distanze; 2 sforamenti |
| **H3** | linker error | **INDIZIARIA** | coda non terminata; page-start corretto |

**PROVEN:** H5 è supportata sul percorso non-PAC.
**PROVEN:** H5 non è supportata sul percorso PAC.
**UNPROVEN:** H8.

---

## 8. Correzione del report precedente

Il report `T27-OOB-PAC-PATH.md` diceva che i call site noti erano **solo ARM**. È **errato**: `i386_init.c` è un call site x86_64 verificato. Il report è stato corretto; questa sezione lo supersede sul punto della raggiungibilità.

**PROVEN:** il call site x86_64 esiste.
**PROVEN:** la precedente affermazione ARM-only è ritirata.
**UNPROVEN:** il valore di `HAS_APPLE_PAC`, non la raggiungibilità.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `i386_init.c` chiama `kernel_collection_slide` | **SÌ** |
| Formato 11 raggiungibile su x86_64 | **SÌ** |
| Implementazione Intel alternativa | **NO** |
| `isAuth=1` gestito diversamente su x86_64 | **NO** |
| Non-PAC ferma `isAuth=1` | **SÌ** |
| PAC raggiunge `next=10` | **SÌ** |
| I 4 OOB hanno `isAuth=1` | **SÌ** |
| Successore raggiunto su non-PAC | **NO** |
| `HAS_APPLE_PAC` 26B131 | **UNPROVEN** |
| H5 | **SUPPORTATA (condizionale)** |
| H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il percorso formato 11 è **realmente raggiungibile su x86_64**: `i386_init.c` chiama `kernel_collection_slide`, che chiama `walk_chain` e `fixup_value`. Non c’è un’implementazione Intel separata. `isAuth=1` non ha un trattamento x86_64 dedicato: senza PAC ferma il loader **prima** di `next`; con PAC firma e attraversa. I 4 record OOB sono `isAuth=1`, quindi il successore `next=10` è raggiungibile solo sul percorso PAC (o se `isAuth` fosse 0). La raggiungibilità è provata; il valore di `HAS_APPLE_PAC` nel build 26B131 resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,20 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna modifica/build/patch/boot.
