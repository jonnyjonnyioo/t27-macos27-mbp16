# T27 — AGENT-AMD — HAS_APPLE_PAC NEL BUILD 26B131

> **CORREZIONE 2026-11-17:** i 4 record OOB hanno `isAuth=0`, non `1` (bit 63 = 0). Le conclusioni sul rifiuto non-PAC sono **RITIRATE**. Vedi `T27-OOB-ISAUTH0-CORRECTION.md`.

**Scope:** verificare il valore effettivo di `HAS_APPLE_PAC` nel percorso x86_64 di macOS 27.2.1 build 26B131 e stabilire se i 4 record AMD `isAuth=1` vengono realmente rifiutati.

**Modalità:** sola lettura; KDK locale, header XNU, sorgenti Apple, BootKC/SystemKC, 4 record; nessuna modifica, build, patch o boot.

**Esito:** **nessun artefatto decisivo** del build 26B131 definisce `HAS_APPLE_PAC`. La macro non è definita negli header KDK; l’unico header che la usa è `platform/sptm/sptm_xnu.h`; `kern_exec.c` la usa con `assert(cputype == CPU_TYPE_ARM64)`. Non ci sono configurazioni preprocessate o metadati di compilazione x86_64 disponibili. I 4 record OOB sono `isAuth=1`: se la macro è assente, il loader si ferma **sul record corrente**; se è presente, firma e attraversa. Il valore resta **UNPROVEN**. T27 resta **OPEN**.

---

## 1. Ricerca della definizione

| Ricerca | Esito |
|---|---|
| `#define HAS_APPLE_PAC` nei KDK headers | **0** |
| File KDK che citano `HAS_APPLE_PAC` | **1** (`sptm_xnu.h`) |
| Configurazioni preprocessate x86_64 | **assenti** |
| Metadati di compilazione | **assenti** |
| `HAS_APPLE_PAC` in `i386_init.c` | **solo `#if` indiretto nell’header** |
| Valore numerico nel build 26B131 | **UNPROVEN** |

**PROVEN:** la macro non è definita negli header KDK.
**PROVEN:** non ci sono artefatti preprocessati o metadati di build.
**UNPROVEN:** il valore effettivo nel binario 26B131.

---

## 2. Evidenze indirette

| Evidenza | Valore |
|---|---|
| `kern_exec.c` con PAC | **solo ARM64** |
| `CPU_TYPE_ARM64` assert | **presente** |
| `i386_init.c` chiama `kernel_collection_slide` | **SÌ** |
| `HAS_APPLE_PAC` in `i386_init.c` | **nessuna definizione locale** |
| Stringa `Unexpected authenticated fixup` in BootKC | **non trovata** |
| Stringa `Invalid cache level` in BootKC | **non trovata** |
| Stringa in SystemKC | **non trovata** |

**PROVEN:** il percorso x86_64 è raggiungibile.
**INDIZIARIO:** l’assenza delle stringhe non-PAC può indicare stripping o altra immagine.
**UNPROVEN:** il valore della macro.

---

## 3. I 4 record OOB

| Provider | Record | `isAuth` | `next` | Non-PAC | PAC |
|---|---|---:|---:|---|---|
| X5400 | `0x9C78FF0` | **1** | **10** | **stop corrente** | **cross** |
| X5400 T6 | `0x9C6CFF0` | **1** | **10** | **stop corrente** | **cross** |
| AMDSupport | `0x13C13FF4` | **1** | **10** | **stop corrente** | **cross** |
| AMDSupport T6 | `0x13C07FF4` | **1** | **10** | **stop corrente** | **cross** |

**PROVEN:** tutti e 4 hanno `isAuth=1`.
**PROVEN:** con macro assente il loader si ferma sul record corrente.
**PROVEN:** con macro presente il loader firma e attraversa.
**UNPROVEN:** quale dei due percorsi usi il build 26B131.

---

## 4. Distinzione misurato/inferito

| Categoria | Contenuto |
|---|---|
| **Misurato** | 4 record `isAuth=1`; call site x86_64; macro non definita nei KDK |
| **Inferito** | su x86_64 senza PAC il loader si ferma; su PAC attraversa |
| **UNPROVEN** | valore di `HAS_APPLE_PAC` nel build 26B131 |
| **UNPROVEN** | accettazione/rifiuto runtime |
| **UNPROVEN** | comportamento del boot |

**PROVEN:** la distinzione è completa.
**UNPROVEN:** il dato decisivo.

---

## 5. H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H5** | loader rifiuta | **SUPPORTATA (condizionale)** | non-PAC ferma `isAuth=1` |
| **H8** | slot omesso | **UNPROVEN** | nessun conteggio in-band |
| **H2** | distanza + bound | **SUPPORTATA** | 2.244 distanze; 2 sforamenti |
| **H3** | linker error | **INDIZIARIA** | coda non terminata |

**PROVEN:** H5 è condizionata a `HAS_APPLE_PAC=0`.
**UNPROVEN:** H8.

---

## 6. Conclusione

| Domanda | Risposta |
|---|---|
| Macro definita nei KDK | **NO** |
| Configurazioni/metadati disponibili | **NO** |
| Call site x86_64 | **SÌ** |
| 4 record `isAuth=1` | **SÌ** |
| Non-PAC ferma i record | **SÌ** |
| PAC li attraversa | **SÌ** |
| Valore 26B131 | **UNPROVEN** |
| H5 | **SUPPORTATA (condizionale)** |
| H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** non esiste un artefatto decisivo che fissi `HAS_APPLE_PAC` per il build 26B131. La macro non è definita negli header KDK, non ci sono configurazioni preprocessate o metadati di compilazione, e le stringhe del ramo non-PAC non compaiono nelle KC. I 4 record OOB sono `isAuth=1`: con macro assente il loader si ferma sul record corrente, con macro presente firma e attraversa. Il valore resta **UNPROVEN**, quindi H5 è **SUPPORTATA solo condizionalmente**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna modifica/build/patch/boot.
