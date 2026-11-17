# T27 — AGENT-AMD — SUPERCLASS 12AA488

**Scope:** identificare la superclasse `0x12AA488`, verificare se X6000 Interface ha un’implementazione esterna a X6000HWServices, confrontare X4000/X6000 Interface e Abstract e stabilire se Interface è un provider disponibile.

**Modalità:** sola lettura; SystemKC/BootKC, fileset, symbol table, vtable, chained pointers; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che X6000 Interface è completa, con vtable `0xC270378`, costruttore `0xC26D260`, `metaClass` verso `0xC271828` e `superClass` verso `0x12AA488` con `cacheLevel 3`. **REFUTED** che Interface sia incompleta o esterna a HWServices. **UNPROVEN** l’identità della superclasse e la pubblicazione. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 113 | `d28c1aae0cbed71585626a29fed3a18e7a541e84478d9d7a021e2587edd4bc73` |
| Report 112 | `12a7ded25a94a2b6549b5a2937e791f71c55e82871188d0aba9b7f70e66bc09b` |

**PROVEN:** gli artefatti sono quelli indicati; 113 ha il banner di rettifica.

---

## 2. X6000 Interface completa

| Elemento | Indirizzo |
|---|---:|
| `MetaClassC1` | `0xC26D210` |
| `MetaClassC2` | `0xC26D300` |
| Costruttore `C2` | `0xC26D260` |
| `getMetaClass` | `0xC26D2E0` |
| `metaClass` | `0xC270368` |
| `superClass` | `0xC270370` |
| vtable | `0xC270378` |
| `gMetaClass` | `0xC271828` |

**PROVEN:** la classe è completa.
**PROVEN:** la vtable esiste.
**PROVEN:** il costruttore esiste.
**REFUTED:** “vtable assente”.

---

## 3. Puntatori di classe

| Campo | Raw | Target | `cacheLevel` |
|---|---:|---:|---:|
| `metaClass` | `0x4000004C271828` | `0xC271828` | `1` |
| `superClass` | `0xC00000012AA488` | `0x12AA488` | `3` |

**PROVEN:** `metaClass` punta a `gMetaClass`.
**PROVEN:** `superClass` usa `cacheLevel 3`.
**UNPROVEN:** la base del livello 3.
**UNPROVEN:** il significato di `0x12AA488`.

---

## 4. Vtable Interface

| Slot | Raw | Target | `cacheLevel` | Reale | Simbolo |
|---|---:|---:|---:|---:|---|
| `0x5B0` | `0x994C60` | `0x994C60` | `0` | `0xFFFFFF8000A94C60` | `registerService` |
| `0x5B8` | `0x994E60` | `0x994E60` | `0` | `0xFFFFFF8000A94E60` | `probe` |
| `0x5C0` | `0x994E70` | `0x994E70` | `0` | `0xFFFFFF8000A94E70` | `start` |
| `0x5C8` | `0x994E80` | `0x994E80` | `0` | `0xFFFFFF8000A94E80` | `stop` |
| `0x5D0` | `0x994EB0` | `0x994EB0` | `0` | `0xFFFFFF8000A94EB0` | `open` |

**PROVEN:** la vtable è tutta IOService.
**PROVEN:** non ci sono override.
**PROVEN:** Interface è strutturalmente istanziabile.

---

## 5. Simboli X4000

| Elemento | Indirizzo |
|---|---:|
| Interface `MetaClassC1` | `0x6E0DA0` |
| Interface `C2` | `0x6E0DF0` |
| Interface `getMetaClass` | `0x6E0E70` |
| Interface `gMetaClass` | `0x6E5838` |
| Abstract `MetaClassC1` | `0x6E0F80` |
| Abstract `gMetaClass` | `0x6E5860` |
| Abstract `getTtl` | `0x6E0D10` |

**PROVEN:** X4000 ha Interface e Abstract completi.
**PROVEN:** X6000 Interface è una classe separata.
**UNPROVEN:** la relazione X4000 → X6000.

---

## 6. Superclasse 0x12AA488

| Ricerca | Esito |
|---|---|
| Simbolo esatto | **nessuno** |
| Simbolo più vicino | `_polaris10_kicker_smc_firmware+0x100D8` |
| Puntatore in X5000 | **SÌ** |
| Puntatore in X6000 | **SÌ** |
| `cacheLevel` | `3` |
| Base livello 3 | **UNPROVEN** |

**PROVEN:** il valore è condiviso da X5000 e X6000.
**PROVEN:** non è una semplice VM address.
**UNPROVEN:** la classe proprietaria.

---

## 7. Implementazioni esterne

| Ricerca | Esito |
|---|---|
| X6000 Interface in HWServices | **SÌ** |
| X6000 Interface in altre kext | **NO** |
| Simboli esterni | **nessuno** |
| Vtable esterna | **nessuna** |
| Provider alternativo | **NO** |

**PROVEN:** l’unica implementazione è in HWServices.
**PROVEN:** non è esterna.
**UNPROVEN:** duplicati in immagini non estratte.

---

## 8. Provider X6000HWLibs

| Requisito | Esito |
|---|---|
| Interface istanziabile | **SÌ, strutturale** |
| Interface pubblicata | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| Matching | **UNPROVEN** |

**PROVEN:** la classe è completa.
**UNPROVEN:** la pubblicazione.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Interface completa | **SÌ** |
| Vtable | `0xC270378` |
| Costruttore | `0xC26D260` |
| `superClass` | `0x12AA488`, L3 |
| Identità superclasse | **UNPROVEN** |
| Implementazione esterna | **NO** |
| Interface provider | **UNPROVEN** |
| Matching HWLibs | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** X6000 Interface non è incompleta: ha vtable `0xC270378`, costruttore `0xC26D260`, `metaClass` verso `0xC271828` e `superClass` verso `0x12AA488` con `cacheLevel 3`. La vtable è interamente IOService (`registerService`, `probe`, `start`, `stop`, `open`), quindi la classe è strutturalmente istanziabile, ma non c’è alcuna pubblicazione. `0x12AA488` non ha simbolo e non è una semplice VM address; la sua identità resta **UNPROVEN**, così come la disponibilità di Interface come provider e il matching X6000HWLibs → Navi. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
