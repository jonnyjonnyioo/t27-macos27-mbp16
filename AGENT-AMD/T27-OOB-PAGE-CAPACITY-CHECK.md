# T27 — AGENT-AMD — OOB PAGE CAPACITY CHECK

**Scope:** verificare se il vincolo minimo di 8 byte per slot spiega causalmente le due OOB; distinguere un difetto del linker da una terminazione specifica AMD; ricostruire la capacità residua di ogni pagina; controllare `offset + 8 <= page_end`; cercare controlli di page-bound nel BootKC.

**Modalità:** sola lettura; capacity table di tutte le pagine X5400/AMDSupport, walk dei 124 `next=10` per provider, ricerca simboli/stringhe BootKC; nessuna modifica, patch, build o download.

**Esito:** il vincolo 8 byte spiega **geometricamente** le due OOB: lo slot corrente entra sempre, il successore `next=10` non entra in **2/124** casi. Non è dimostrato che il loader applichi il page-bound; non c’è evidenza di una terminazione speciale AMD né di un difetto linker dimostrato. **H2 SUPPORTATA**; **H3 INDIZIARIA**; **H5/H8 UNPROVEN**. T27 resta **OPEN**.

---

## 1. Capacità per pagina

| Provider | Pagine | NONE | Catene | Residuo corrente min/max | Violazioni slot corrente |
|---|---:|---:|---:|---:|---:|
| X5400HWLibs | **5.371** | **5.125** | **246** | **0 / 4.088** | **0** |
| AMDSupport | **39** | **2** | **37** | **0 / 4.088** | **0** |

**PROVEN:** ogni ultimo slot corrente entra negli 8 byte.
**PROVEN:** il residuo minimo dopo l’ultimo slot è **0**.
**PROVEN:** nessuna pagina ha uno slot corrente troncato.
**PROVEN:** la tabella completa è in `T27-PAGE-CAPACITY.tsv` (5.410 righe, SHA-256 `88fb4c9dd95ae2b10555b8631b7fbdc7122c594a0e6cf2ba91e43aa33a5c6778`).

---

## 2. I 124 `next=10`

| Provider | `next=10` | `off+8<=end` | `off+10+8<=end` | Violazioni successore | Residuo successore min |
|---|---:|---:|---:|---:|---:|
| X5400HWLibs | **124** | **124** | **123** | **1** | **-2** |
| AMDSupport | **124** | **124** | **123** | **1** | **-6** |

**PROVEN:** lo slot corrente soddisfa sempre il vincolo 8 byte.
**PROVEN:** il successore soddisfa il vincolo in **123/124** casi.
**PROVEN:** c’è **1** violazione per provider.
**PROVEN:** le violazioni sono X5400 `0xFF0` (`-2`) e AMDSupport `0xFF4` (`-6`).

---

## 3. Terminale vs interno

| Classe | Quantità | `off+8` | `off+18` | Residuo successore |
|---|---:|---|---|---:|
| Interni | **123** | **SÌ** | **SÌ** | **≥4** |
| Terminali | **2** | **SÌ** | **NO** | **-2 / -6** |

**PROVEN:** i terminali non violano il vincolo del proprio slot.
**PROVEN:** violano solo il vincolo del successore.
**PROVEN:** gli interni hanno residuo successore sufficiente.

---

## 4. Capacità residua delle pagine anomale

| Provider | Pagina | Ultimo offset | Residuo dopo slot | Residuo dopo successore | Esito |
|---|---:|---:|---:|---:|---|
| X5400HWLibs | 3475 | `0xFF0` | **8** | **-2** | OOB |
| AMDSupport | 33 | `0xFF4` | **4** | **-6** | OOB |

**PROVEN:** X5400 ha 8 byte dopo lo slot corrente, ma solo 6 prima del page-end per il successore.
**PROVEN:** AMDSupport ha 4 byte dopo lo slot corrente, ma solo 2 prima del page-end per il successore.
**PROVEN:** il successore richiede 8 byte.

---

## 5. BootKC: page-bound

| Ricerca | Esito |
|---|---|
| Simbolo `fixup_value` | **assente** |
| Simbolo `chained` | **assente** |
| Simbolo page-bound chained | **assente** |
| Stringa `chained fixup` | **assente** |
| Stringa `fixup_value` | **assente** |
| Disassembly `readPrelinkedExtensions` | **nessun page-bound** |
| Controllo equivalente | **non trovato** |

**PROVEN:** BootKC non espone un loader chained né un controllo page-bound.
**PROVEN:** i simboli `fixup` presenti sono estranei (AHCIPort, NVMe, VFS).
**UNPROVEN:** il loader kernel.

---

## 6. Terminazione speciale AMD

| Test | Esito |
|---|---|
| `next=10` normali | **2.244** |
| Terminali `10` | **2** |
| Altri `10` con residuo <8 | **0** |
| Documentazione AMD | **assente** |
| Regola di terminazione `10` | **nessuna evidenza** |

**PROVEN:** solo 2 `next=10` violano il page-bound.
**PROVEN:** non c’è una regola documentata.
**UNPROVEN:** una terminazione speciale AMD.

---

## 7. Record incompleto

| Evidenza | Esito |
|---|---|
| Successore reale | **NO** |
| Successore page-start | **NO** |
| Successore dentro pagina | **NO** |
| Successore dentro segmento | **SÌ** |
| Successore con `next=0` | **SÌ, ma copia shiftata** |
| Coda incompleta | **INDIZIARIA** |

**PROVEN:** il successore non è uno slot dichiarato.
**PROVEN:** è una copia shiftata di byte vicini.
**UNPROVEN:** l’omissione di un record.

---

## 8. Causa dimostrata vs ipotesi

### Dimostrato

| Fatto | Evidenza |
|---|---|
| Slot corrente sempre dentro pagina | **124/124** |
| Successore fuori pagina | **2/124** |
| Residuo successore negativo | **-2 / -6** |
| Page-start corrette | digest target/T6 identici |
| Nessun page-bound nel BootKC | simboli/stringhe assenti |

### Ipotesi

| Ipotesi | Stato |
|---|---|
| H2: loader applica page-bound | **UNPROVEN** |
| H3: linker ha lasciato coda incompleta | **INDIZIARIA** |
| H5: loader rifiuta la catena | **UNPROVEN** |
| H8: record terminale omesso | **UNPROVEN** |
| Terminazione speciale AMD | **UNPROVEN** |

**PROVEN:** il vincolo 8 byte spiega la geometria.
**PROVEN:** non dimostra il comportamento runtime.
**PROVEN:** non dimostra un difetto linker.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Slot corrente troncato? | **NO** |
| Successore troncato? | **SÌ, 2/124** |
| Residuo successore | **-2 / -6** |
| Page-start corrette? | **SÌ** |
| Page-bound BootKC? | **NO** |
| Terminazione AMD speciale? | **NO EVIDENZA** |
| H2 | **SUPPORTATA** |
| H3 | **INDIZIARIA** |
| H5/H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il vincolo minimo di 8 byte spiega **geometricamente** le due OOB: lo slot corrente entra sempre, mentre il successore `next=10` non entra in **2/124** casi, con residuo **-2/-6**. Non è dimostrato che il loader applichi il page-bound; non esiste una terminazione speciale AMD documentata né un difetto linker dimostrato. H2 resta la spiegazione più semplice; H3 è indiziaria; H5/H8 restano UNPROVEN. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,25 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna scrittura/patch/build/download.
