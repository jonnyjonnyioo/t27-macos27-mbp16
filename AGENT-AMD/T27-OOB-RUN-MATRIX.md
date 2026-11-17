# T27 — AGENT-AMD — OOB RUN MATRIX

**Scope:** confrontare tutte le 24 run ≥8 `next=10`; verificare se le 2 OOB sono eccezioni sistematiche; correlare start/end/lunghezza/next finale/residuo con page-start, offset segmento e pagina successiva; confrontare target/T6.

**Modalità:** sola lettura; scan di tutti i provider, matrice 24 run, digest target/T6; nessuna modifica, patch, build o download.

**Esito:** **24 run ≥8** identiche target/T6 (digest `74387680…`). **18 terminano `next=0`**, **2 sono OOB**, **4 chiudono con un `next` diverso da 0/10**. Le 2 OOB sono le **sole** con `next` finale **10**; non condividono una page-start o un offset di segmento unico. **H2 SUPPORTATA**; **H3 INDIZIARIA**; **H5/H8 UNPROVEN**. T27 resta **OPEN**.

---

## 1. Matrice delle 24 run

| Provider | Pag | Start | End | Len | Next | Tipo | PageStart | SegOff | Res | SuccRes | NextPage |
|---|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|
| X4000HWLibs | 1620 | `0xC6A` | `0xFF8` | 91 | 0 | next0 | `0x20` | 2740224 | 0 | — | `0x2` |
| X4000HWLibs | 1621 | `0x2` | `0x14C` | 33 | 0 | next0 | `0x2` | 2740224 | 3756 | — | `0xFFFF` |
| X4100HWLibs | 1331 | `0x35A` | `0x83C` | 125 | 988 | other | `0x30` | 1363968 | 1980 | 992 | `0xC8` |
| X4400HWLibs | 3250 | `0x3DA` | `0x8BC` | 125 | 0 | next0 | `0x30` | 3006464 | 1852 | — | `0xFFFF` |
| X4700HWLibs | 1620 | `0x7CA` | `0xCAC` | 125 | 0 | next0 | `0x1D8` | 3006464 | 844 | — | `0xFFFF` |
| X5000HWLibs | 7083 | `0x6EA` | `0xBCC` | 125 | 0 | next0 | `0x438` | 6037504 | 1068 | — | `0xFFFF` |
| X5100HWLibs | 1191 | `0x4EA` | `0x9CC` | 125 | 0 | next0 | `0x10` | 3629056 | 1580 | — | `0xFFFF` |
| X5200HWLibs | 4179 | `0xE7A` | `0xFF6` | 38 | 0 | next0 | `0x888` | 4521984 | 2 | — | `0x0` |
| X5200HWLibs | 4180 | `0x0` | `0x35C` | 86 | 0 | next0 | `0x0` | 4521984 | 3228 | — | `0xFFFF` |
| **X5400HWLibs** | **3475** | **`0xC8A`** | **`0xFF0`** | **88** | **10** | **OOB** | **`0x698`** | **4542464** | **8** | **-2** | **`0x4`** |
| X5400HWLibs | 3476 | `0x4` | `0x16C` | 36 | 0 | next0 | `0x4` | 4542464 | 3724 | — | `0xFFFF` |
| X5700HWLibs | 1751 | `0x64A` | `0xB2C` | 125 | 0 | next0 | `0x58` | 4935680 | 1228 | — | `0xFFFF` |
| X6000Framebuffer | 47 | `0x68A` | `0xB6C` | 125 | 20 | other | `0x8` | 2662400 | 1164 | 1144 | `0xCF8` |
| X6000HWLibs | 5549 | `0x3DA` | `0x8BC` | 125 | 0 | next0 | `0x130` | 5550080 | 1852 | — | `0xFFFF` |
| X6100HWLibs | 3061 | `0x50A` | `0x9EC` | 125 | 0 | next0 | `0x260` | 3858432 | 1548 | — | `0xFFFF` |
| X6200HWLibs | 3770 | `0xCEA` | `0xFF6` | 78 | 0 | next0 | `0xA40` | 3858432 | 2 | — | `0x0` |
| X6200HWLibs | 3771 | `0x0` | `0x1CC` | 46 | 28 | other | `0x0` | 3858432 | 3628 | 3600 | `0x568` |
| X6300HWLibs | 2560 | `0xD0A` | `0xFF8` | 75 | 0 | next0 | `0xA60` | 4050944 | 0 | — | `0x2` |
| X6300HWLibs | 2561 | `0x2` | `0x1EC` | 49 | 252 | other | `0x2` | 4050944 | 3596 | 3344 | `0xFFFF` |
| X6700HWLibs | 4262 | `0xACA` | `0xFAC` | 125 | 0 | next0 | `0x820` | 4321280 | 76 | — | `0xFFFF` |
| X6800HWLibs | 2028 | `0x82A` | `0xD0C` | 125 | 0 | next0 | `0x580` | 4493312 | 748 | — | `0xFFFF` |
| X6810HWLibs | 1741 | `0x6CA` | `0xBAC` | 125 | 0 | next0 | `0x420` | 4415488 | 1100 | — | `0xFFFF` |
| **AMDSupport** | **33** | **`0xD6A`** | **`0xFF4`** | **66** | **10** | **OOB** | **`0x0`** | **811008** | **4** | **-6** | **`0x8`** |
| AMDSupport | 34 | `0x8` | `0x24C` | 58 | 0 | next0 | `0x8` | 811008 | 3500 | — | `0xFFFF` |

**PROVEN:** 18 run terminano `next=0`.
**PROVEN:** 2 run sono OOB.
**PROVEN:** 4 run chiudono con `next` diverso da 0/10.
**PROVEN:** il digest della matrice è identico target/T6: `743876806fa7429446cdaffe2137cfb495933fdff872071d6a9dbbd0e496bb75`.

---

## 2. OOB vs normali

| Elemento | 2 OOB | 18 normali |
|---|---|---|
| Next finale | **10** | **0** |
| Residuo dopo slot | **8 / 4** | **0 / 2 / 76 / …** |
| Successore | **fuori pagina** | **nessuno** |
| Page-start | `0x698` / `0x0` | varie |
| Segment offset | 4542464 / 811008 | vari |
| Pagina successiva | `0x4` / `0x8` | varie |
| Target/T6 | **identici** | **identici** |

**PROVEN:** le OOB non hanno una page-start unica.
**PROVEN:** non hanno un segment offset unico.
**PROVEN:** non sono le uniche vicine al page-end.
**PROVEN:** l’unica differenza è il `next` finale **10** invece di **0**.

---

## 3. Run vicine al page-end

| Provider | Pag | End | Next | Residuo | Esito |
|---|---:|---:|---:|---:|---|
| X4000HWLibs | 1620 | `0xFF8` | 0 | **0** | **next0** |
| X5200HWLibs | 4179 | `0xFF6` | 0 | **2** | **next0** |
| X6200HWLibs | 3770 | `0xFF6` | 0 | **2** | **next0** |
| X6300HWLibs | 2560 | `0xFF8` | 0 | **0** | **next0** |
| **X5400HWLibs** | **3475** | **`0xFF0`** | **10** | **8** | **OOB** |
| **AMDSupport** | **33** | **`0xFF4`** | **10** | **4** | **OOB** |

**PROVEN:** altre run arrivano a 0/2 byte dal page-end e terminano `next=0`.
**PROVEN:** le OOB hanno **più** residuo (8/4) ma un `next=10`.
**PROVEN:** non è la vicinanza al page-end a creare l’OOB, ma il valore finale.

---

## 4. Le 4 run con `next` diverso

| Provider | Pag | Run | Next finale | Residuo | Next page |
|---|---:|---:|---:|---:|---:|
| X4100HWLibs | 1331 | 125 | **988** | 1980 | `0xC8` |
| X6000Framebuffer | 47 | 125 | **20** | 1164 | `0xCF8` |
| X6200HWLibs | 3771 | 46 | **28** | 3628 | `0x568` |
| X6300HWLibs | 2561 | 49 | **252** | 3596 | `0xFFFF` |

**PROVEN:** quattro run chiudono con un `next` diverso da 0/10.
**PROVEN:** tutte restano dentro la pagina.
**PROVEN:** il campo `next` ammette valori intermedi.

---

## 5. Correlazioni

| Variabile | Correlazione con OOB |
|---|---|
| Page-start | **nessuna unica** |
| Segment offset | **nessuna unica** |
| Lunghezza run | **88/66**, non unica (125×12) |
| Posizione pagina | **3475/33**, non unica |
| Pagina successiva | **0x4/0x8**, non unica |
| Next finale | **10, unica** |
| Residuo | **8/4, non unica** |
| Target/T6 | **identici** |

**PROVEN:** nessuna correlazione strutturale esclusiva oltre al `next=10`.
**PROVEN:** target/T6 identici.

---

## 6. Eccezioni sistematiche?

| Test | Esito |
|---|---|
| 2/24 con next finale 10 | **SÌ** |
| Stessa struttura | **SÌ** |
| Page-start comune | **NO** |
| Segment offset comune | **NO** |
| Run length comune | **NO** |
| Causa dimostrata | **NO** |

**PROVEN:** le 2 OOB sono un’eccezione **sistematica nel valore finale**, non nella geometria.
**PROVEN:** non è dimostrata la causa.

---

## 7. H2/H3/H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H2** | distanza + bound | **SUPPORTATA** | 18 run normali; 2 OOB al page-end |
| **H3** | linker error | **INDIZIARIA** | run normali terminano 0 a 0/2 byte dal bordo |
| **H5** | loader rifiuta | **UNPROVEN** | nessun loader/trace |
| **H8** | slot omesso | **UNPROVEN** | nessun conteggio in-band |

**PROVEN:** H2 resta la spiegazione più semplice.
**PROVEN:** H3 è più forte di prima ma non dimostrata.
**UNPROVEN:** H5/H8.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Run ≥8 | **24** |
| Normali `next=0` | **18** |
| OOB | **2** |
| Altri `next` | **4** |
| Page-start comune OOB | **NO** |
| Segment offset comune | **NO** |
| Unica differenza OOB | **next finale 10** |
| T6 | **identico** |
| H2 | **SUPPORTATA** |
| H3 | **INDIZIARIA** |
| H5/H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** le 24 run sono identiche target/T6. Diciotto terminano `next=0`, anche a 0/2 byte dal page-end; le 2 OOB sono le sole con `next` finale **10** e non condividono page-start, segment offset o lunghezza. L’eccezione è **sistematica nel valore finale**, non nella geometria; H2 resta la spiegazione più semplice, H3 è indiziaria, H5/H8 restano UNPROVEN. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,25 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna scrittura/patch/build/download.
