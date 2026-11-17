# T27 — AGENT-AMD — BINARY CONSISTENCY

**Scope:** verificare UUID, build, architettura e provenienza di SystemKC, BootKC e AMDSupport; ricontrollare VA/file offset/segmenti di callsite `0x27C570`, stub `0x1016E`, GOT `0x241E8`; confrontare stub vicine con target eseguibili.

**Modalità:** sola lettura; SystemKC, BootKC, AMDSupportPart; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **MAPPING COERENTE**, provenienza del codice **PROVEN**; il carve completo non è byte-identico per normalizzazione del `fileoff`. La GOT resta rebase-only e il target NX è un cluster dati, non un errore di provenienza. T27 **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf8b8340c987a98e33b039622e62b0a304fce9df799356f7f7d05ca840` |
| AMDSupportPart | `849ccf34c3976f6859eee962f2fc829c27061dff8d0b0526a1561d374f3b5cf4` |
| Report 145 | `2ae50d3e28dcb6c39973d1c840b7896a23fe7a5c485fba4223a79d3c6462c1a2` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Architettura e UUID

| Binario | Arch | UUID |
|---|---|---|
| SystemKC | x86_64 | `93336203-88E3-AA73-08FC-7C9F4D7B21E0` |
| BootKC | x86_64 | `63C931A6-A4C0-AB5D-E2FB-D1712B1143DB` |
| AMDSupportPart | x86_64 | `2723D92D-6032-3051-9874-A87DE97B25CB` |

**PROVEN:** tutti x86_64.
**PROVEN:** UUID distinti.
**UNPROVEN:** uguaglianza UUID (non attesa tra collezione e kext).

---

## 3. Build

| Binario | Build metadata |
|---|---|
| SystemKC | `LC_BUILD_VERSION platform 0, minos 0.0, sdk n/a` |
| BootKC | `LC_BUILD_VERSION platform 0, minos 0.0, sdk n/a` |
| AMDSupportPart | `LC_SOURCE_VERSION 7.1.11`; `LC_BUILD_VERSION` assente |

**PROVEN:** SystemKC/BootKC hanno metadati di collezione.
**PROVEN:** AMDSupport ha source version `7.1.11`.
**UNPROVEN:** build esatta comune.

---

## 4. Provenienza del carve

| Test | Esito |
|---|---|
| Header A vs S@`0x27B000` | **uguale** |
| Primi 64 byte | **uguali** |
| Primi 256 byte | **NO** |
| SHA completo A vs slice S | **diverso** |
| Prima differenza | `0x49` |
| Causa | normalizzazione `fileoff` |

**PROVEN:** A e S divergono a `0x49`.
**PROVEN:** `0x49` cade nel campo `fileoff` del segmento `__TEXT`.
**PROVEN:** A normalizza il segmento a file offset 0.
**REFUTED:** provenienza diversa per il codice.

---

## 5. Mapping del callsite

| Elemento | SystemKC | AMDSupportPart |
|---|---:|---:|
| Callsite | `0x27C570` | `0x1570` |
| Istruzione precedente | `0x27C545` | `0x1545` |
| Byte callsite | `ff 90 60 08 00 00` | `ff 90 60 08 00 00` |
| Byte call stub | `e8 ...` | `e8 ...` |

**PROVEN:** `A[0x1570] == S[0x27C570]`.
**PROVEN:** `A[0x1545] == S[0x27C545]`.
**PROVEN:** mapping VA→A offset = `VA - 0x27B000`.

---

## 6. Stub e GOT

| Elemento | Indirizzo | Byte/valore |
|---|---:|---|
| Stub | `0x1016E` | `ff 25 74 40 01 00` |
| GOT | `0x241E8` | `0x400000009A7640` |
| Target | `0x9A7640` | dati `__REGION19` |
| Prot | — | `0x3` RW/NX |

**PROVEN:** stub e GOT sono in SystemKC.
**PROVEN:** il callsite chiama lo stub.
**PROVEN:** il target è NX.

---

## 7. Stub vicine

| Stub | GOT | Target | Segmento | Prot |
|---:|---:|---:|---|---:|
| `0x10150` | `0x241C0` | `0x991840` | `__REGION19` | `0x3` |
| `0x10156` | `0x241C8` | `0x922470` | `__REGION18` | `0x5` |
| `0x1015C` | `0x241D0` | `0x94C650` | `__REGION18` | `0x5` |
| `0x10162` | `0x241D8` | `0x9A7630` | `__REGION19` | `0x3` |
| `0x10168` | `0x241E0` | `0x9BDE00` | `__REGION19` | `0x3` |
| `0x1016E` | `0x241E8` | `0x9A7640` | `__REGION19` | `0x3` |
| `0x10174` | `0x241F0` | `0x9BD500` | `__REGION19` | `0x3` |
| `0x1017A` | `0x241F8` | `0x9BD150` | `__REGION19` | `0x3` |
| `0x10180` | `0x24200` | `0x9A48F0` | `__REGION19` | `0x3` |
| `0x10186` | `0x24208` | `0x9A4930` | `__REGION19` | `0x3` |
| `0x1018C` | `0x24210` | `0x9A5FA0` | `__REGION19` | `0x3` |
| `0x10192` | `0x24218` | `0x252A00` | `__REGION3` | `0x5` |

**PROVEN:** `0x1016E` è in un cluster dati `0x10162`–`0x1018C`.
**PROVEN:** le stub RX più vicine sono `0x10156`, `0x1015C` prima e `0x10192` dopo.
**PROVEN:** non è un caso isolato.

---

## 8. Statistiche stub

| Categoria | Count |
|---|---:|
| Stub totali | `1669` |
| Target NX (`0x3`) | `708` |
| Target RX (`0x5`) | `956` |
| Altri | `5` |

**PROVEN:** la maggioranza ha target RX.
**PROVEN:** 708 stub hanno target NX.
**UNPROVEN:** quali siano realmente chiamate.

---

## 9. Riferimenti alternativi

| Ricerca | Esito |
|---|---|
| `0x9A7640` qword | `0` |
| `0x9A7640` dword | solo GOT `0x241E8` |
| Simbolo a `0x9A7640` | **assente** |
| Simbolo vicino | `_aRLC_Ucode` |
| Altra stub con stesso target | **nessuna** |

**PROVEN:** nessun riferimento alternativo.
**PROVEN:** nessun simbolo di funzione.

---

## 10. Verdetto

| Domanda | Risposta |
|---|---|
| Arch coerente | **SÌ** |
| UUID uguali | **NO** (atteso) |
| Build esatta | **UNPROVEN** |
| Code provenance | **PROVEN** |
| Full-file provenance | **PARTIAL** |
| Mapping callsite | **PROVEN** |
| Target NX | **PROVEN** |
| Anomalia da mismatch | **NO** |
| T27 GO? | **NO — OPEN** |

**PROVEN:** il callsite è coerente con SystemKC.
**PROVEN:** il target NX non deriva da un errore di mapping.
**UNPROVEN:** la build esatta e il runtime.

---

## 11. Conclusione

| Domanda | Risposta |
|---|---|
| SystemKC UUID | `93336203...` |
| BootKC UUID | `63C931A6...` |
| AMDSupport UUID | `2723D92D...` |
| Arch | x86_64 |
| Carve | normalizzato a `0x49` |
| Callsite | `A[0x1570] == S[0x27C570]` |
| Stub | `0x1016E` |
| Target | `0x9A7640` NX |
| Caller Wrangler | **UNPROVEN** |

**Risposta netta:** i tre binari sono x86_64 con UUID distinti; SystemKC e BootKC hanno metadati di collezione (`platform 0, minos 0.0`), AMDSupport ha `LC_SOURCE_VERSION 7.1.11` e nessun `LC_BUILD_VERSION`. Il carve AMDSupport non è byte-identico allo slice SystemKC: la prima differenza è a `0x49`, nel campo `fileoff` del segmento `__TEXT`, quindi è una normalizzazione del carve, non un cambio di codice. Il callsite `0x27C570` e la call a `0x27C545` coincidono byte per byte (`A[0x1570] == S[0x27C570]`); la provenienza del codice è **PROVEN**. Lo stub `0x1016E` sta in un cluster NX `0x10162`–`0x1018C`, con stub RX vicine `0x10156`, `0x1015C` e `0x10192`; non è un errore di mapping. Il target `0x9A7640` resta NX e la GOT è rebase-only. STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
