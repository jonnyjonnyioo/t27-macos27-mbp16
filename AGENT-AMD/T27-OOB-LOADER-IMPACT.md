# T27 — AGENT-AMD — OOB LOADER IMPACT

**Scope:** stabilire se i due OOB siano percorsi dal loader o siano riferimenti irraggiungibili; ricostruire le catene complete; confrontare con dyld/XNU e con KC donor.

**Modalità:** sola lettura; parsing SystemKC 25G342 e donor T6. Nessuna simulazione di boot, modifica o correzione.

**Esito:** i due OOB **non sono page-start malformati**: sono l’**ultimo slot raggiunto** di due catene complete, il cui `next=10` punta a **6 byte** dalla fine pagina, insufficienti per un puntatore da 8 byte. Quindi lo slot è raggiungibile; è il **successore** a essere OOB. Il donor T6 ha **1 OOB** negli stessi due provider, sulle **stesse pagine** ma con offset/raw diversi. Il comportamento del loader (stop, ignore, reject) resta **UNPROVEN**; nessuna implementazione dyld/XNU locale è disponibile. T27 resta **OPEN**.

---

## 1. Catene complete

| Provider | Pagina | Start | Slot | Ultimo offset | Ultimo raw | `next` | `nxt` | Page end |
|---|---:|---:|---:|---:|---|---:|---:|---:|
| X5400HWLibs | **3475** | `0x698` | **188** | `0x9C78FF0` | `0x050000048CA6426` | **10** | `0x9C78FFA` | `0x9C79000` |
| AMDSupport | **33** | `0x0` | **432** | `0x13C13FF4` | `0x050000053BB99E0` | **10** | `0x13C13FFE` | `0x13C14000` |

**PROVEN:** le catene sono complete e terminano sull’ultimo slot.
**PROVEN:** l’ultimo slot è **dentro** la pagina.
**PROVEN:** il successore calcolato è a **6 byte** dal page end.
**PROVEN:** servono **8 byte** per leggere il successore.

---

## 2. Ultimi slot

| Provider | Ultimi 5 offset | Ultimi 5 raw | `next` |
|---|---|---|---|
| X5400HWLibs | `0x9C78FC8` … `0x9C78FF0` | tutti `0x050000048CA6426` | **10** |
| AMDSupport | `0x13C13FCC` … `0x13C13FF4` | `0x050000053BB9740` ×4, poi `0x050000053BB99E0` | **10** |

**PROVEN:** l’OOB non è un page-start isolato; è la coda di una catena percorsa.
**PROVEN:** la coda ha `next=10` ripetuto.
**UNPROVEN:** se `next=10` sia un terminatore valido per quel formato.

---

## 3. Raggiungibilità

| Domanda | Risposta |
|---|---|
| L’ultimo slot è raggiunto? | **SÌ — dalla catena** |
| È un page-start? | **NO** |
| Il successore è dentro pagina? | **NO — 6 byte residui** |
| Il loader lo percorrerebbe? | **UNPROVEN** |
| Il loader lo rifiuterebbe? | **UNPROVEN** |

**PROVEN:** lo slot è raggiungibile durante la scansione.
**PROVEN:** il successore è OOB.
**UNPROVEN:** la decisione del loader.

---

## 4. dyld/XNU locale

| Fonte | Disponibilità | Esito |
|---|---|---|
| `fixup-chains.h` | **assente** | **UNPROVEN** |
| `kcformat.c` | **assente** | **UNPROVEN** |
| `kcgen` | **assente** | **UNPROVEN** |
| dyld source | **assente** | **UNPROVEN** |
| Report T27 | definizioni parziali | **non sufficienti** |

**PROVEN:** non c’è un’implementazione locale del loop.
**PROVEN:** non si può dedurre stop/ignore/reject dal solo file.
**UNPROVEN:** il comportamento runtime.

---

## 5. Donor T6

| Provider | OOB T6 | Pagina T6 | Ultimo T6 | Raw T6 | OOB 25G342 | Pagina 25G342 | Stessa pagina? |
|---|---:|---:|---|---:|---:|---|
| X5400HWLibs | **1** | **3475** | `0x9C6CFF0` | `0x050000048C9A426` | **1** | **3475** | **SÌ** |
| AMDSupport | **1** | **33** | `0x13C07FF4` | `0x050000053BAD9E0` | **1** | **33** | **SÌ** |

**PROVEN:** T6 ha lo stesso numero di OOB (1 per provider).
**PROVEN:** le pagine sono le stesse; offset e raw sono diversi.
**INFERRED:** il fenomeno è ricorrente nello stesso punto delle due catene, non identico byte-per-byte.
**UNPROVEN:** la causa comune.

---

## 6. Impatto

| Metrica | Valore |
|---|---:|
| Catene totali | **3.828** |
| OOB | **2** |
| Slot OOB raggiunti | **2** |
| Successori OOB | **2** |
| Auth/cache2 negli OOB | **0/0** |
| Impatto sui conteggi | **nessuno** |
| Impatto runtime | **UNPROVEN** |

**PROVEN:** i due OOB non cambiano i conteggi di auth/cache2.
**UNPROVEN:** se il loader interrompa, ignori o rifiuti la catena.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| OOB sono page-start? | **NO** |
| Ultimo slot raggiunto? | **SÌ** |
| Successore dentro pagina? | **NO** |
| Loader percorre il successore? | **UNPROVEN** |
| Loader stop/ignore/reject? | **UNPROVEN** |
| Donor T6 analogo? | **SÌ — 1+1, stesse pagine** |
| Correzione? | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** i due OOB sono **code di catene raggiunte**, non page-start isolati. L’ultimo slot è dentro la pagina; il suo `next=10` produce un successore a 6 byte dal bordo, insufficiente per 8 byte. Il donor T6 ripete 1 OOB per gli stessi provider sulle stesse pagine, con offset/raw diversi. Il comportamento del loader resta **UNPROVEN** perché non c’è codice dyld/XNU locale. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna simulazione/modifica/build/boot.
