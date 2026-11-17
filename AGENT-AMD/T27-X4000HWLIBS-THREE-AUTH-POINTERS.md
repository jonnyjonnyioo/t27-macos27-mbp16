# T27 — AGENT-AMD — X4000HWLIBS THREE AUTH POINTERS

**Scope:** risolvere i tre slot `cacheLevel=2` reali di X4000HWLibs (`0xA99B60`, `0xDB9980`, `0xF80198`): segmento, sezione, parola raw, campi, target, simboli, riferimenti e provenienza comune.

**Modalità:** sola lettura; parsing SystemKC 25G342, sezioni, fixup e symtab. Nessuna modifica, build o boot.

**Esito:** i tre slot sono tre `isAuth=1` isolati in **`X4000HWLibs __DATA,__data`**, con `next=0`, `key=0`, `addrDiv=0`, `cacheLevel=2`. I target sono tre offset della **stessa pagina 4 KB**, `0x18C00000`–`0x18C00FFF`: `0x18C00002`, `0x18C0074D`, `0x18C00EFC`. Quella pagina è **fuori dal SystemKC** (size 369.213.440 B) e non cade in alcun segmento dei provider. **Nessun simbolo esatto**, **nessun riferimento assoluto/RIP-relative comune**. La provenienza comune è **la stessa pagina target**, non una struttura proprietaria dimostrata. T27 resta **OPEN**.

---

## 1. Slot e sezioni

| Slot | Provider | Segmento | Sezione | Offset sezione | Raw |
|---:|---|---|---|---:|---|
| `0xA99B60` | X4000HWLibs | `__DATA` | **`__data`** | `0x109550` | `0x8000000698C0074D` |
| `0xDB9980` | X4000HWLibs | `__DATA` | **`__data`** | `0x429370` | `0x8000200698C00EFC` |
| `0xF80198` | X4000HWLibs | `__DATA` | **`__data`** | `0x5EFB88` | `0x8000200598C00002` |

**PROVEN:** tutti e tre sono in `__DATA,__data`, non in `__got`, `__const` o `__kalloc_type`.
**PROVEN:** non sono contigui e non formano una tabella.

---

## 2. Decodifica

| Campo | `0xA99B60` | `0xDB9980` | `0xF80198` |
|---|---:|---:|---:|
| `isAuth` | **1** | **1** | **1** |
| `cacheLevel` | **2** | **2** | **2** |
| `target` | `0x18C0074D` | `0x18C00EFC` | `0x18C00002` |
| `next` | **0** | **0** | **0** |
| `diversity` | **6** | **0x2006** | **0x2005** |
| `addrDiv` | **0** | **0** | **0** |
| `key` | **0** | **0** | **0** |

**PROVEN:** i tre slot sono catene singole (`next=0`).
**PROVEN:** `cacheLevel=2`, `isAuth=1`, `key=0`, `addrDiv=0`.
**PROVEN:** nessuno ha un secondo elemento di catena.

---

## 3. Target

| Target | Decimale | Dentro SystemKC? | Segmento provider | Sezione |
|---|---:|---|---|---|
| `0x18C00002` | 415.236.098 | **NO** | **nessuno** | **nessuna** |
| `0x18C0074D` | 415.237.965 | **NO** | **nessuno** | **nessuna** |
| `0x18C00EFC` | 415.239.932 | **NO** | **nessuno** | **nessuna** |

**PROVEN:** i tre target sono **oltre** la fine del SystemKC (369.213.440 B).
**PROVEN:** non cadono in `__TEXT`, `__DATA` o `__DATA_CONST` di X4000/X4000HWLibs.
**PROVEN:** non sono indirizzi assoluti risolti: sono offset con `basePointers[2]` non serializzato.
**UNPROVEN:** la base `cacheLevel=2` e l’eventuale KC ausiliaria.

---

## 4. Regione comune

| Proprietà | Valore |
|---|---|
| Pagina target | **`0x18C00000`–`0x18C00FFF`** |
| Offset relativi | **`0x2`, `0x74D`, `0xEFC`** |
| Stessa pagina | **SÌ** |
| Stessa struttura | **UNPROVEN** |
| Stesso provider sorgente | **SÌ — X4000HWLibs** |
| Stessa sezione sorgente | **SÌ — `__data`** |

**PROVEN:** i tre target condividono la stessa pagina 4 KB.
**PROVEN:** i tre slot condividono provider e sezione.
**UNPROVEN:** che la pagina appartenga a una struttura nota o che i tre riferimenti siano correlati funzionalmente.

---

## 5. Simboli e riferimenti

| Verifica | `0xA99B60` | `0xDB9980` | `0xF80198` |
|---|---:|---:|---:|
| Simbolo esatto | **0** | **0** | **0** |
| Riferimento assoluto 8 B | **0** | **0** | **0** |
| Candidato RIP-relative comune | **0** | **0** | **0** |
| Riferimento provato | **NO** | **NO** | **NO** |

**PROVEN:** nessun simbolo ha esattamente questi indirizzi.
**PROVEN:** nessuna occorrenza assoluta a 8 byte.
**PROVEN:** nessun candidato RIP-relative con gli opcode comuni `48/4C 8D/8B`.
**UNPROVEN:** riferimenti tramite pattern non comuni, registri o calcolo dinamico.

---

## 6. Provenienza

| Ipotesi | Evidenza | Stato |
|---|---|---|
| Tabella contigua | slot non contigui | **NO** |
| GOT | sezione `__data`, non `__got` | **NO** |
| Vtable | nessun simbolo, nessuna sequenza | **UNPROVEN** |
| Callback | nessun xref | **UNPROVEN** |
| Dati | sezione `__data` | **COMPATIBILE** |
| Riferimenti alla stessa pagina esterna | 3 target nella stessa pagina | **PROVEN** |
| Stessa struttura | nessuna prova | **UNPROVEN** |

**PROVEN:** sono dati isolati in `__data`, non una tabella contigua.
**PROVEN:** condividono la pagina target esterna.
**UNPROVEN:** struttura e funzione.

---

## 7. Confronto con i 12 raw

| Gruppo | Quantità | Match |
|---|---:|---:|
| 3 slot reali | 3 | — |
| 12 raw | 12 | **0** |
| Target 12 nel SystemKC | 0 | **0** |
| Target 12 nella pagina `0x18C00000` | 0 | **0** |

**PROVEN:** i 3 slot reali non coincidono con i 12 raw.
**PROVEN:** i 12 raw non sono in questa pagina.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| 3 slot in `__data`? | **SÌ** |
| `next=0`? | **SÌ** |
| `cacheLevel=2`, `isAuth=1`? | **SÌ** |
| Target nella stessa pagina? | **SÌ — `0x18C00000`** |
| Target dentro SystemKC? | **NO** |
| Simboli esatti? | **0** |
| Xref provati? | **0** |
| Struttura proprietaria? | **UNPROVEN** |
| Base `cacheLevel=2`? | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** i tre slot sono dati autenticati isolati in `X4000HWLibs __DATA,__data`, con catene singole e target nella stessa pagina esterna `0x18C00000`. Non ci sono simboli, xref o strutture dimostrabili; la provenienza comune è la pagina target, non una struttura. La base `cacheLevel=2` resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
