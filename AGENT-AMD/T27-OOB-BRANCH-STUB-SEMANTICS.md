# T27 — AGENT-AMD — BRANCH STUB SEMANTICS

**Scope:** capire perché la branch stub `0x1016E` salta verso dati RW non eseguibili (`0x9A7640`); confrontare GOT adiacenti e pattern; stabilire riferimento valido, tabella o anomalia.

**Modalità:** sola lettura; SystemKC; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PATTERN PRE-FIXUP / ANOMALIA STATICA**. Le branch stub adiacenti `0x10162`–`0x1017A` puntano tutte a `__REGION19` RW/NX; la `__BRANCH_GOTS` è scrivibile (`0x3`). Il target statico non è eseguibile: non è una funzione; la semantica runtime resta **UNPROVEN**. T27 **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf8b8340c987a98e33b039622e62b0a304fce9df799356f7f7d05ca840` |
| Report 143 | `07490d4fe0d26f04c796b0a5375e9486f3e86c5af855a9a443909cd14e62249a` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Stub adiacenti

| Stub | Byte | GOT | Valore | Target | Segmento |
|---:|---|---:|---:|---:|---|
| `0x10162` | `ff 25 70 40 01 00` | `0x241D8` | `0x400000009A7630` | `0x9A7630` | `__REGION19` |
| `0x10168` | `ff 25 72 40 01 00` | `0x241E0` | `0x400000009BDE00` | `0x9BDE00` | `__REGION19` |
| `0x1016E` | `ff 25 74 40 01 00` | `0x241E8` | `0x400000009A7640` | `0x9A7640` | `__REGION19` |
| `0x10174` | `ff 25 76 40 01 00` | `0x241F0` | `0x400000009BD500` | `0x9BD500` | `__REGION19` |
| `0x1017A` | `ff 25 78 40 01 00` | `0x241F8` | `0x400000009BD150` | `0x9BD150` | `__REGION19` |

**PROVEN:** cinque stub consecutivi puntano a `__REGION19`.
**PROVEN:** tutti i target grezzi sono RW (`0x3`), NX.
**UNPROVEN:** il valore dopo fixup.

---

## 3. Statistiche GOT

| Voce | Valore |
|---|---:|
| Entry totali | `12288` |
| Zero | `10619` |
| Non-zero | `1669` |
| Target `__REGION12` | `434` |
| Target `__REGION18` | `400` |
| Target `__REGION25` | `353` |
| Target `__REGION19` | `266` |
| Target `__TEXT` | `5` |

**PROVEN:** la GOT non è tutta dati: 434 entry puntano a `__REGION12`, 400 a `__REGION18`, ecc.
**PROVEN:** il gruppo `0x10162`–`0x1017A` è un cluster omogeneo su `__REGION19`.
**UNPROVEN:** la semantica dei singoli target.

---

## 4. Protezioni

| Segmento | Maxprot | Initprot | Significato |
|---|---:|---:|---|
| `__BRANCH_STUBS` | `0x5` | `0x5` | RX |
| `__BRANCH_GOTS` | `0x3` | `0x3` | RW |
| `__REGION19` | `0x3` | `0x3` | RW, NX |

**PROVEN:** la GOT è scrivibile.
**PROVEN:** il target statico è NX.
**PROVEN:** le stub sono RX.

---

## 5. Interpretazione

| Ipotesi | Esito |
|---|---|
| Funzione valida | **REFUTED** statico |
| Tabella dati | **PROBABILE** |
| Riferimento pre-fixup | **PROBABILE** |
| Anomalia isolata | **NO** |
| Semantica runtime | **UNPROVEN** |

**PROVEN:** il target grezzo non è codice.
**PROVEN:** il pattern è condiviso da cinque stub.
**UNPROVEN:** se la GOT venga riscritta a runtime.

---

## 6. Perché salta su dati

| Causa | Evidenza |
|---|---|
| Valore non rilocato | GOT RW, target NX |
| Tabella/blob | `_aRLC_Ucode` vicino |
| Fixup runtime | GOT scrivibile |
| Funzione | **NO** statico |

**PROVEN:** la combinazione GOT RW + target NX è incompatibile con una chiamata diretta statica.
**UNPROVEN:** il fixup effettivo.

---

## 7. STOP

| Criterio | Esito |
|---|---|
| Pattern identificato | **SÌ** |
| Funzione | **NO** |
| Semantica runtime | **UNPROVEN** |
| Oggetto `start` | **UNPROVEN** |
| Spazio >10 GiB | **SÌ** |
| Modifiche | **NO** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente con certezza.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| `0x1016E` | branch stub RX |
| GOT | `0x241E8` RW |
| Target grezzo | `0x9A7640` |
| Target | dati `__REGION19`, NX |
| Adiacenti | stesse caratteristiche |
| Funzione | **UNPROVEN** |
| Anomalia isolata | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la branch stub `0x1016E` salta a `0x9A7640`, che è in `__REGION19` RW/NX; non è una funzione. Le cinque stub adiacenti (`0x10162`–`0x1017A`) puntano tutte a `__REGION19`, quindi non è un caso isolato: è un cluster pre-fixup o un riferimento a dati/tabella. La `__BRANCH_GOTS` è scrivibile (`0x3`), mentre le stub sono RX (`0x5`); la combinazione è incompatibile con una chiamata diretta statica e compatibile con una GOT rilocata a runtime. La semantica finale e l’oggetto di `AMDFramebuffer::start` restano **UNPROVEN**. STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
