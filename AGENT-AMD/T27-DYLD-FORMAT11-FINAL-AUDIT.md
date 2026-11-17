# T27 — AGENT-AMD — DYLD FORMAT 11 FINAL AUDIT

**Scope:** ricalcolare tutti i fixup con `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` formato 11 e stride 1; verificare X6100, X4000, X4000HWLibs e i 172 provider; controllare limiti, cicli, sovrapposizioni, terminazioni; escludere i tre slot ritirati; registrare le correzioni ai report 49–55.

**Modalità:** sola lettura; parsing SystemKC 25G342. Nessuna modifica, build o boot.

**Esito:** il decoder formato 11/stride 1 è **confermato**: X6100 dà esattamente **154 catene / 8.544 puntatori / 0 auth**, identical al report di validazione. X4000: **59 / 26.377 / 0 / 0**. X4000HWLibs: **163 / 9.954 / 0 / 0**. Totale: **3.828 catene / 501.435 puntatori unici / 0 sovrapposizioni / 0 cicli / 2 terminazioni OOB / 0 auth / 0 cacheLevel 2**. I tre slot sono esclusi. La validazione non è “pulita al 100%” per i **2 OOB**; T27 resta **OPEN**.

---

## 1. Decoder

| Parametro | Valore |
|---|---|
| Formato | **11** (`X86_64_KERNEL_CACHE`) |
| `target` | 30 bit unsigned |
| `cacheLevel` | 2 bit |
| `diversity` | 16 bit |
| `addrDiv` | 1 bit |
| `key` | 2 bit |
| `next` | **12 bit** |
| `isAuth` | bit 63 |
| Stride | **1 byte** |
| Page size | **0x1000** |

**PROVEN:** il decoder è quello sopra.
**PROVEN:** stride 1 è corretto.
**PROVEN:** stride 4 era incompatibile.

---

## 2. Controlli indipendenti

| Provider | Catene | Puntatori | Auth | CacheLevel 2 | Atteso | Esito |
|---|---:|---:|---:|---:|---|---|
| X6100HWLibs | **154** | **8.544** | **0** | **0** | 154/8.544/0 | **ESATTO** |
| X4000 | **59** | **26.377** | **0** | **0** | coerente | **OK** |
| X4000HWLibs | **163** | **9.954** | **0** | **0** | coerente | **OK** |

**PROVEN:** X6100 coincide byte-per-byte con il report 51/55.
**PROVEN:** X4000 e X4000HWLibs non hanno auth.
**PROVEN:** i tre slot ritirati non compaiono.

---

## 3. Audit globale

| Metrica | Valore |
|---|---:|
| Provider | **172** |
| Catene | **3.828** |
| Puntatori totali | **501.435** |
| Puntatori unici | **501.435** |
| Sovrapposizioni | **0** |
| Cicli | **0** |
| Terminazioni OOB | **2** |
| Catena massima | **510** |
| `isAuth=1` | **0** |
| `cacheLevel=2` | **0** |
| Provider con auth2 | **0** |

**PROVEN:** nessuna sovrapposizione e nessun ciclo.
**PROVEN:** **0 auth** e **0 cacheLevel 2** in tutti i 172 provider.
**PROVEN:** **2** catene terminano oltre il limite di pagina; sono anomalie residue.
**UNPROVEN:** la causa dei 2 OOB.

---

## 4. I 3 slot esclusi

| Slot | `page_start` | Offset | In catena? |
|---:|---:|---:|---|
| `0xA99B60` | **0xB20** | **0xB60** | **NO** |
| `0xDB9980` | **0x940** | **0x980** | **NO** |
| `0xF80198` | **0x18** | **0x198** | **NO** |

**PROVEN:** i tre offset non sono start né raggiunti da stride 1.
**PROVEN:** sono parole dati.
**PROVEN:** i 3 slot sono esclusi.

---

## 5. Correzioni ai report 49–55

| Report | Dato precedente | Correzione |
|---|---|---|
| 49 | 293/397 auth; 43/75 cache2; 118 | **ERRATO — ritirato** |
| 50 | 118 slot | **ERRATO — ritirato** |
| 51 | 59/1.993; 163/1.161; 18 auth; 3 cache2 | **ERRATO — stride 4** |
| 52 | 3 slot reali | **RITIRATI** |
| 53 | pagina esterna | **confermato non attribuito** |
| 54 | collection esterna | **UNPROVEN** |
| 55 | stride 1 | **CONFERMATO** |

**PROVEN:** i conteggi validi sono quelli di questo report.
**PROVEN:** 118 e 3 slot non sono più usati.
**PROVEN:** la pagina esterna resta non attribuita.

---

## 6. Terminazioni OOB

| Proprietà | Valore |
|---|---|
| Catene totali | **3.828** |
| OOB | **2** |
| Percentuale | **0,052%** |
| Auth nelle OOB | **0** |
| Impatto sui conteggi | **nessuno** |

**PROVEN:** 2 catene su 3.828 hanno una terminazione oltre pagina.
**PROVEN:** non contengono auth.
**UNPROVEN:** se siano malformazioni del file o un limite del parser.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| Formato 11/stride 1 confermato? | **SÌ** |
| X6100 esatto? | **SÌ — 154/8.544/0** |
| X4000 | **59/26.377/0/0** |
| X4000HWLibs | **163/9.954/0/0** |
| Totale | **3.828/501.435/0/0** |
| Sovrapposizioni/cicli | **0/0** |
| OOB | **2** |
| 3 slot esclusi? | **SÌ** |
| 118 valido? | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il decoder formato 11/stride 1 è **confermato** da X6100 (**154/8.544/0**) e dall’intero SystemKC (**3.828 catene / 501.435 puntatori / 0 auth / 0 cacheLevel 2**). I **118** e i **3 slot** sono **ritirati**. Restano **2 terminazioni OOB** su 3.828, che impediscono una validazione completamente pulita. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna modifica/build/boot.
