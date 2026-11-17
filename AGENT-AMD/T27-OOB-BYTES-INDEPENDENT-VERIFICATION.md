# T27 — AGENT-AMD — OOB BYTES INDEPENDENT VERIFICATION

**Scope:** verificare indipendentemente se i due record OOB contengono `next=10` scritto dal produttore o se derivano da errore di estrazione/interpretazione/ricostruzione; rileggere i byte originali; ricostruire da file offset, segment offset e indirizzo virtuale; verificare endianess, bitfield, stride e page-start.

**Modalità:** sola lettura; `xxd` diretto sui file, parsing minimale indipendente, walk dalle page-start; nessuna modifica, patch, build o download.

**Esito:** `next=10` è **realmente presente** nei byte originali di entrambi i file e in T6. La decodifica little-endian, il bitfield, lo stride 1 e le page-start sono coerenti; nessuna discrepanza. **Nessun errore di estrazione/interpretazione**. T27 resta **OPEN**.

---

## 1. Byte originali

| File | Record file offset | 8 byte | LE raw | `next` LE |
|---|---:|---|---:|---:|
| SystemKC X5400 | `0x9C78FF0` | `26 64 ca 48 00 00 50 00` | `0x50000048CA6426` | **10** |
| T6 X5400 | `0x9C6CFF0` | `26 a4 c9 48 00 00 50 00` | `0x50000048C9A426` | **10** |
| SystemKC AMDSupport | `0x13C13FF4` | `e0 99 bb 53 00 00 50 00` | `0x50000053BB99E0` | **10** |
| T6 AMDSupport | `0x13C07FF4` | `e0 d9 ba 53 00 00 50 00` | `0x50000053BAD9E0` | **10** |

**PROVEN:** i byte sono letti direttamente dal file.
**PROVEN:** `next=10` è nei 4 record.
**PROVEN:** target/T6 hanno lo stesso `next`.

---

## 2. Endianess e bitfield

| File | LE raw | BE raw | `next` LE | `next` BE |
|---|---|---:|---:|---:|
| SystemKC X5400 | `0x50000048CA6426` | `0x2664CA4800005000` | **10** | 1228 |
| T6 X5400 | `0x50000048C9A426` | `0x26A4C94800005000` | **10** | 1236 |
| SystemKC AMDSupport | `0x50000053BB99E0` | `0xE099BB5300005000` | **10** | 3091 |
| T6 AMDSupport | `0x50000053BAD9E0` | `0xE0D9BA5300005000` | **10** | 3099 |

**PROVEN:** solo LE produce `next=10`.
**PROVEN:** BE produce valori diversi, incompatibili con il walk.
**PROVEN:** il file è little-endian.

### Bitfield LE

| Campo | Bit | Valore X5400 | Valore AMDSupport |
|---|---:|---:|---:|
| target | 0–29 | `0x8CA6426` | `0x13BB99E0` |
| cacheLevel | 30–31 | 1 | 1 |
| diversity | 32–47 | 0 | 0 |
| addrDiv | 48 | 0 | 0 |
| key | 49–50 | 0 | 0 |
| **next** | **51–62** | **10** | **10** |
| isAuth | 63 | 0 | 0 |

**PROVEN:** il bitfield è coerente.
**PROVEN:** `next` occupa 12 bit.
**PROVEN:** stride 1 byte.

---

## 3. Ricostruzione offset

| File | Entry | Seg fileoff | Pagina | Record off | File offset calcolato | `xxd` |
|---|---:|---:|---:|---:|---:|---|
| SystemKC X5400 | `0x8A90000` | `0x455000` | 3475 | `0xFF0` | **`0x9C78FF0`** | **match** |
| T6 X5400 | `0x8A84000` | `0x455000` | 3475 | `0xFF0` | **`0x9C6CFF0`** | **match** |
| SystemKC AMDSupport | `0x13B2C000` | `0xC6000` | 33 | `0xFF4` | **`0x13C13FF4`** | **match** |
| T6 AMDSupport | `0x13B20000` | `0xC6000` | 33 | `0xFF4` | **`0x13C07FF4`** | **match** |

**Formula:** `entry_fileoff + segment_fileoff + page*0x1000 + record_offset`.

**PROVEN:** i quattro offset coincidono con `xxd`.
**PROVEN:** non c’è errore di estrazione.

---

## 4. Indirizzo virtuale

| File | `__DATA` vmaddr | Page base | Record VA |
|---|---:|---:|---:|
| SystemKC X5400 | `0x8EE5000` | `0x9C78000` | `0x9C78FF0` |
| T6 X5400 | `0x8ED9000` | `0x9C6C000` | `0x9C6CFF0` |
| SystemKC AMDSupport | `0x13BF2000` | `0x13C13000` | `0x13C13FF4` |
| T6 AMDSupport | `0x13BE6000` | `0x13C07000` | `0x13C07FF4` |

**PROVEN:** VA e file offset coincidono per `__DATA`.
**PROVEN:** non è un indirizzo runtime assoluto.

---

## 5. Page-start e walk

| File | Page-start | Walk | Ultimo | `next` | Residuo |
|---|---:|---:|---:|---:|---:|
| SystemKC X5400 | `0x698` | **188** | `0xFF0` | **10** | **6** |
| T6 X5400 | `0x698` | **188** | `0xFF0` | **10** | **6** |
| SystemKC AMDSupport | `0x0` | **432** | `0xFF4` | **10** | **2** |
| T6 AMDSupport | `0x0` | **432** | `0xFF4` | **10** | **2** |

**PROVEN:** il walk parte dalla page-start e arriva all’ultimo slot.
**PROVEN:** il numero di slot coincide target/T6.
**PROVEN:** la page-start è corretta.

---

## 6. Discrepanze

| Test | Esito |
|---|---|
| Byte originali | **coerenti** |
| Endianess | **LE** |
| Bitfield | **coerente** |
| Stride 1 | **coerente** |
| Offset calcolato | **coincide** |
| Page-start | **coerente** |
| Walk | **188/432** |
| T6 | **coerente** |
| Discrepanze | **nessuna** |

**PROVEN:** nessuna discrepanza.
**PROVEN:** `next=10` è nel binario originale.
**PROVEN:** non è un errore di estrazione/interpretazione/ricostruzione.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| `next=10` originale? | **SÌ, 4/4 record** |
| Errore di estrazione? | **NO** |
| Errore di endianess? | **NO** |
| Errore di bitfield? | **NO** |
| Errore di offset? | **NO** |
| Page-start corretta? | **SÌ** |
| T6 coerente? | **SÌ** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** i byte originali contengono `next=10` in entrambi i record e in T6. La decodifica little-endian, il bitfield a 12 bit, lo stride 1, gli offset e le page-start sono coerenti; nessuna discrepanza. `next=10` non è un artefatto di estrazione o interpretazione. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,25 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna scrittura/patch/build/download.
