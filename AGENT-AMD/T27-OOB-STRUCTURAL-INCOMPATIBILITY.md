# T27 — AGENT-AMD — OOB STRUCTURAL INCOMPATIBILITY

**Scope:** verificare se la geometria degli slot da 8 byte dimostra un’incompatibilità strutturale tra le chained-fixup AMD e le due pagine terminali; ricostruire le ultime transizioni; confrontare `next=10` con la capacità; testare interpretazioni alternative del campo `next`; cercare implementazioni locali del formato AMD.

**Modalità:** sola lettura; tail delle due catene, capacity table, test di scala 1/2/4/8 su tutte le 3.828 catene, ricerca implementazioni; nessuna modifica, patch, build o download.

**Esito:** le due code terminano con **8 `next=10` consecutivi**; l’ottavo richiede 8 byte oltre il page-end (residuo **6/2**). La sola interpretazione compatibile con tutti i **2.244** `next=10` è **distanza in byte (scala 1)**. L’incompatibilità è **geometrica e condizionata al page-bound**; il comportamento runtime resta **UNPROVEN**. **H2 SUPPORTATA**; **H3 INDIZIARIA**; **H5/H8 UNPROVEN**. T27 resta **OPEN**.

---

## 1. Ultime transizioni X5400HWLibs

| Offset | Raw | `next` | Residuo |
|---:|---|---:|---:|
| `0xFAA` | `0x50000048CA67BA` | 10 | 76 |
| `0xFB4` | `0x50000048CA685E` | 10 | 66 |
| `0xFBE` | `0x50000048CA6965` | 10 | 56 |
| `0xFC8` | `0x50000048CA6426` | 10 | 46 |
| `0xFD2` | `0x50000048CA6426` | 10 | 36 |
| `0xFDC` | `0x50000048CA6426` | 10 | 26 |
| `0xFE6` | `0x50000048CA6426` | 10 | 16 |
| **`0xFF0`** | **`0x50000048CA6426`** | **10** | **6** |

**PROVEN:** la coda è una sequenza regolare di 8 `next=10`.
**PROVEN:** l’ultimo passo richiede 8 byte e ne trova 6.
**PROVEN:** il target resta stabile negli ultimi 5 slot.

---

## 2. Ultime transizioni AMDSupport

| Offset | Raw | `next` | Residuo |
|---:|---|---:|---:|
| `0xFAE` | `0x50000053BB9990` | 10 | 72 |
| `0xFB8` | `0x50000053BB9740` | 10 | 62 |
| `0xFC2` | `0x50000053BB9740` | 10 | 52 |
| `0xFCC` | `0x50000053BB9740` | 10 | 42 |
| `0xFD6` | `0x50000053BB9740` | 10 | 32 |
| `0xFE0` | `0x50000053BB9740` | 10 | 22 |
| `0xFEA` | `0x50000053BB9740` | 10 | 12 |
| **`0xFF4`** | **`0x50000053BB99E0`** | **10** | **2** |

**PROVEN:** la coda è una sequenza regolare di 8 `next=10`.
**PROVEN:** l’ultimo passo richiede 8 byte e ne trova 2.
**PROVEN:** il target resta stabile nei 6 slot precedenti.

---

## 3. Capacità e page-bound

| Provider | Ultimo slot | `off+8` | `off+18` | Esito |
|---|---:|---|---|---|
| X5400HWLibs | `0xFF0` | **dentro** | **fuori (-2)** | OOB |
| AMDSupport | `0xFF4` | **dentro** | **fuori (-6)** | OOB |

**PROVEN:** lo slot corrente è sempre dentro.
**PROVEN:** solo il successore è fuori.
**PROVEN:** il vincolo 8 byte è soddisfatto dallo slot corrente e violato dal successore.

---

## 4. Interpretazioni alternative di `next`

| Scala | Catene | Slot | Terminazioni `0` | OOB | Cicli |
|---:|---:|---:|---:|---:|---:|
| **1** | **3.828** | **501.435** | **3.826** | **2** | **0** |
| 2 | 3.828 | 64.620 | 3.457 | **371** | 0 |
| 4 | 3.828 | 51.287 | 3.293 | **535** | 0 |
| 8 | 3.828 | 35.382 | 2.679 | **1.149** | 0 |

**PROVEN:** solo la scala 1 produce 3.826 terminazioni e 2 OOB.
**PROVEN:** scale 2/4/8 producono centinaia di OOB.
**PROVEN:** `next` è una distanza in byte.
**PROVEN:** non è una distanza in unità 2/4/8.

---

## 5. Interpretazioni non compatibili

| Interpretazione | Esito |
|---|---|
| Distanza byte (scala 1) | **2.244/2.244 come distanza; 2 oltre pagina** |
| Distanza scala 2 | **371 OOB globali** |
| Distanza scala 4 | **535 OOB globali** |
| Distanza scala 8 | **1.149 OOB globali** |
| `next=10` sentinel | **contradetto: 2.244 usi** |
| `next=10` terminatore | **contradetto: 123 interni per provider** |

**PROVEN:** non esiste un’altra interpretazione compatibile con tutti i casi.
**PROVEN:** `next=10` è distanza byte.

---

## 6. Implementazioni locali

| Implementazione | Formati | Formato 11 | AMD |
|---|---|---|---|
| `hao-runtime/src/macho.c` | ARM64E, 64, 64_OFFSET | **NO** | **NO** |
| Stela `chained_fixups.rs` | 1, 2, 6, 9, 12 | **NO** | **NO** |
| `fixup-chains.h` | assente | **NO** | **NO** |
| QEMU/XNU/ld64 | assente | **NO** | **NO** |

**PROVEN:** nessuna implementazione locale valida il formato 11.
**PROVEN:** nessun riferimento AMD locale.

---

## 7. Incompatibilità dimostrata?

| Livello | Esito | Evidenza |
|---|---|---|
| Geometria pagina | **SÌ, condizionata** | 2/2 code oltre il page-end |
| Page-bound obbligatorio | **UNPROVEN** | nessun loader |
| Linker | **INDIZIARIO** | coda regolare di 8 `next=10` |
| Runtime | **UNPROVEN** | nessun boot/trace |

**PROVEN:** la geometria è incompatibile **se** ogni slot deve stare nella pagina.
**PROVEN:** non è dimostrato che il loader imponga tale regola.
**PROVEN:** non è dimostrato un difetto linker.

---

## 8. Comportamento del linker

| Fatto | Evidenza |
|---|---|
| Coda X5400 | **8 `next=10`** |
| Coda AMDSupport | **8 `next=10`** |
| Ultimo passo oltre pagina | **2/2** |
| Terminazione speciale | **nessuna** |
| Next azzerato prima del bordo | **NO** |

**PROVEN:** il linker ha prodotto una coda regolare e non ha azzerato l’ultimo `next`.
**PROVEN:** non c’è una firma di terminazione speciale.
**INDIZIARIO:** coda incompleta o mancato page-bound.

---

## 9. H2/H3/H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H2** | distanza + bound | **SUPPORTATA** | scala 1 unica compatibile; 2 OOB |
| **H3** | linker/incompletezza | **INDIZIARIA** | coda 8×10; ultimo non azzerato |
| **H5** | loader rifiuta | **UNPROVEN** | nessun loader/trace |
| **H8** | slot omesso | **UNPROVEN** | nessun conteggio in-band |

**PROVEN:** H2 è l’unica interpretazione compatibile.
**PROVEN:** H3 resta indiziaria.
**UNPROVEN:** H5/H8.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| Coda X5400/AMDSupport | **8 `next=10`** |
| Ultimo passo | **oltre pagina** |
| Residuo | **6 / 2** |
| Scala compatibile | **1 (byte)** |
| Altre scale | **371/535/1.149 OOB** |
| Incompatibilità geometrica | **SÌ, condizionata** |
| Page-bound runtime | **UNPROVEN** |
| Linker difettoso | **INDIZIARIO** |
| H2 | **SUPPORTATA** |
| H3 | **INDIZIARIA** |
| H5/H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** le due catene terminano con 8 `next=10` consecutivi; l’ottavo richiede 8 byte e ne trova 6/2. La scala 1 è l’unica compatibile con tutti i 2.244 `next=10`; scale 2/4/8 producono 371/535/1.149 OOB. L’incompatibilità è **geometrica** e vale **se** il loader impone il page-bound; il comportamento runtime e un difetto linker restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,25 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna scrittura/patch/build/download.
