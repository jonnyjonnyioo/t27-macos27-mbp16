# T27 — AGENT-AMD — AUTH CHAIN PROVENANCE

**Scope:** stabilire se i 56 auth pointer provengano da catene DYLD reali o da scansioni di parole nei dati; individuare `LC_DYLD_CHAINED_FIXUPS` nei 172 provider; confrontare UUID/entry; ricostruire `page_start`, `next`, offset e `cacheLevel`; verificare i 12 livello 2; correggere `0x8B1`.

**Modalità:** sola lettura; parsing SystemKC 25G342 e dei 172 `LC_FILESET_ENTRY`; decodifica delle catene page-bounded; nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** **172/172** provider hanno `LC_DYLD_CHAINED_FIXUPS` **nel KC**; i binari standalone X4000/X4000HWLibs **non** lo hanno. Le catene embedded di X4000 e X4000HWLibs contengono **293/397 auth slot** e **43/75 cacheLevel 2**, ma **nessuno** dei 12 target `cacheLevel=2` compare tra gli auth target delle catene. I 12 valori sono quindi **occorrenze raw**, **non slot di catena**. `0x8B1` è in **X5200HWLibs**, non X4000HWLibs. Provenienza completa dei 56: **UNPROVEN**; 12 livello 2: **0/12 slot**. T27 resta **OPEN**.

---

## 1. Fixup nei provider

| Provider | `LC_DYLD_CHAINED_FIXUPS` embedded | Dataoff | Size | Header |
|---|---|---:|---:|---|
| X4000 | **SÌ** | `0x15FF820E` | 226 | `(0,28,226,226,0,1,0)` |
| X4000HWLibs | **SÌ** | `0x15FF835C` | 5742 | `(0,28,5742,5742,0,1,0)` |
| X5200HWLibs | **SÌ** | **non estratto** | — | — |
| Tutti i 172 | **SÌ** | — | — | — |

**PROVEN:** i fixup sono **embedded** nei provider del KC; i file standalone X4000/X4000HWLibs non li contengono.
**PROVEN:** la provenienza va cercata nel KC, non nei binari standalone.
**Correzione:** il report 48 aveva verificato solo gli standalone e concludeva “niente catene”; la conclusione era **limitata agli standalone** e viene superata da questa verifica embedded.

---

## 2. Segmenti e `page_start`

| Provider | Segmento | Fileoff | Size | Pagine | Pagine con start |
|---|---|---:|---:|---:|---:|
| X4000 | `__TEXT` | `0x2AA000` | `0x3F7000` | 4 | 4 |
| X4000 | `__DATA` | `0x6A1000` | `0x3A000` | 140 | 136 |
| X4000 | `__DATA_CONST` | `0x6DB000` | `0x5000` | 34 | 34 |
| X4000HWLibs | `__TEXT` | `0x6E7000` | `0x29D000` | 4 | 4 |
| X4000HWLibs | `__DATA` | `0x983000` | `0xB05000` | 5664 | 382 |
| X4000HWLibs | `__DATA_CONST` | `0x1488000` | `0x1000` | 26 | 26 |

**PROVEN:** `page_start` e `next` esistono e sono decodificabili.
**PROVEN:** le catene sono **page-bounded**; un `next` che esce dalla pagina non è valido.

---

## 3. Auth slot nelle catene

| Provider | Auth slot | `cacheLevel=2` | Target 12 trovati | Target range auth |
|---|---:|---:|---:|---|
| X4000 | **293** | **43** | **0** | `0x0`–`0x3FFFFFB8` |
| X4000HWLibs | **397** | **75** | **0** | `0x0`–`0x3FFFFFEE` |

**PROVEN:** le catene contengono centinaia di auth slot reali.
**PROVEN:** **0/12** target `cacheLevel=2` compare tra gli auth target delle catene.
**PROVEN:** i 12 valori non sono slot di queste catene.

---

## 4. I 12 valori

| Target | In catena X4000? | In catena X4000HWLibs? | Conclusione |
|---:|---|---|---|
| `0x3F8C007F` | **NO** | **NO** | raw |
| `0x3E8203F2` | **NO** | **NO** | raw |
| `0x334FE856` | **NO** | **NO** | raw |
| `0x1780000E` | **NO** | **NO** | raw |
| `0x20A` | **NO** | **NO** | raw |
| `0x4A6` | **NO** | **NO** | raw |
| `0x16400001` | **NO** | **NO** | raw |
| `0x8B1` | **NO** | **NO** | raw / X5200 |
| `0x1A000002` | **NO** | **NO** | raw |
| 3 non esterni | **NO** | **NO** | raw |

**PROVEN:** **0/12** sono auth slot nelle due catene.
**UNPROVEN:** che i 3 non esterni siano in altri provider.

---

## 5. `0x8B1`

| Verifica | Esito |
|---|---|
| X4000HWLibs | **0 occorrenze** |
| X5200HWLibs | **2 occorrenze** (`0x7EA5330`, `0xA1FE360`) |
| Attribuzione corretta | **X5200HWLibs** |
| Slot di catena | **non provato** |
| Conclusione | **fonte corretta; natura raw** |

**PROVEN:** `0x8B1` non è in X4000HWLibs.
**PROVEN:** è in X5200HWLibs.
**UNPROVEN:** che sia uno slot e non un valore dati.

---

## 6. Provenienza dei 56

| Gruppo | Auth | Verificati in catena | Esito |
|---|---:|---:|---|
| 9 esterni livello 2 | 9 | **9** | **0 slot** |
| 3 non esterni livello 2 | 3 | **0** | **UNPROVEN** |
| Altri 44 | 44 | **0** | **UNPROVEN** |
| **Totale** | **56** | **9** | **provenienza non stabilita** |

**PROVEN:** i 9 esterni livello 2 non sono slot.
**UNPROVEN:** gli altri 47; non sono stati confrontati individualmente con tutte le catene.

---

## 7. Rischio

| Condizione | Conseguenza |
|---|---|
| 12 valori non referenziati | **nessun effetto runtime** |
| 12 valori in dati | **nessun fixup** |
| Catene reali con `cacheLevel=2` | **43+75 = 118 slot** |
| Tali slot percorsi con `basePointers[2]=0` | **invalid cache level** |

**PROVEN:** le catene hanno **118** slot `cacheLevel=2`, indipendentemente dai 12 raw.
**UNPROVEN:** se quegli slot siano percorsi a runtime.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| 172 provider con fixup? | **SÌ — 172/172** |
| Standalone X4000/X4000HWLibs con fixup? | **NO** |
| 12 valori sono slot? | **NO — 0/12** |
| 9 esterni in catena? | **NO** |
| `0x8B1` corretto? | **SÌ — X5200HWLibs** |
| Provenienza 56 completa? | **UNPROVEN** |
| Reachability 12? | **UNPROVEN** |
| Rischio? | **condizionato** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** i 56 auth pointer **non sono stati ricavati da catene DYLD verificate**; per i 12 livello 2 la provenienza da catena è **esclusa** (**0/12**). Le catene reali hanno **118** slot `cacheLevel=2`, ma non coincidono con i 12 raw. `0x8B1` va attribuito a **X5200HWLibs**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
