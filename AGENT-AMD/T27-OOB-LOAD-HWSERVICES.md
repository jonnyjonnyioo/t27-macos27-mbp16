# T27 — AGENT-AMD — LOAD HWSERVICES

**Scope:** verificare il percorso dichiarato da `LoadHWServices=true`, confrontarlo con `LoadPlugIn=Load6000`, cercare il caricatore e separare metadati, codice e runtime.

**Modalità:** sola lettura; SystemKC, BootKC, X6000HWServices, X5000HWServices; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che `LoadHWServices` compare in 3 personality e in 2 stringhe __REGION19 vicine a `LoadController`/`LoadAccelerator` e ai log del GPU Wrangler. **UNPROVEN** il caricatore. **REFUTED** un caricatore statico identificabile in HWServices. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| X6000HWServices | `2aa47ceee99969d3eba360fe558a3fbcd7e69c4bea2cd76704350a9bdfafe453` |
| X5000HWServices | `8a88fe7276968d3b124c9ff7ccf26d18b5e918fc339ab3681dfcb5a2cbd3cfbf` |
| Report 132 | `682cec0254a8debcba76784ba4d167e1b2263241548f015f729cf7c0be64487e` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Occorrenze

| Immagine | `LoadHWServices` | `LoadPlugIn` | `Load6000` | `Load5000` |
|---|---:|---:|---:|---:|
| SystemKC | **5** | **19** | **3** | **2** |
| BootKC | **0** | **0** | **0** | **0** |
| X6000HWServices | **0** | **1** | **2** | **0** |
| X5000HWServices | **0** | **1** | **0** | **1** |

**PROVEN:** `LoadHWServices` è assente da HWServices.
**PROVEN:** `LoadHWServices` è assente da BootKC.
**UNPROVEN:** il consumo runtime.

---

## 3. Le 5 occorrenze SystemKC

| Offset | Tipo |
|---:|---|
| `0x491CC` | XML X4000 HWServices |
| `0x5022F` | XML X5000 HWServices |
| `0x5F99C` | XML X6000 HWServices |
| `0xC14F4A3` | stringa `__REGION19` |
| `0x13BE4880` | stringa `__REGION19` |

### 0xC14F4A3

```text
LoadHWServices\0LoadController\0LoadAccelerator\0
[%s][WRANGLER] %s::%s !!! Mismatch Argument Length. Ty...
```

### 0x13BE4880

```text
LoadHWServices\0LoadAccelerator\0
Accelerator successfully registered with GPU Wrangler.\n
ERROR: Invali...
```

**PROVEN:** le due stringhe sono vicine a `LoadController`/`LoadAccelerator`.
**PROVEN:** il contesto è GPU Wrangler.
**UNPROVEN:** il kext e la funzione.

---

## 4. Personality HWServices

| Bundle | IOClass | Provider | Load | Score | Required |
|---|---|---|---|---:|---|
| X4000 | `...HWServicesPolaris` | `IOPCIDevice` | `LoadHWServices=true` | `65051` | **assente** |
| X5000 | `...HWServicesVega` | `IOPCIDevice` | `LoadHWServices=true` | `65051` | **assente** |
| X6000 | `...HWServicesNavi` | `IOPCIDevice` | `LoadHWServices=true` | `65051` | **assente** |

**PROVEN:** tutte dichiarano `LoadHWServices`.
**PROVEN:** tutte usano `IOPCIDevice`.
**PROVEN:** score identico.
**UNPROVEN:** chi imposta la proprietà.

---

## 5. LoadPlugIn

| Campo | Valore |
|---|---|
| `LoadPlugIn` | `Load6000` |
| `Load6000` funzione | **NO** |
| `Load6000` proprietà | **SÌ** |
| `getMatchProperty` | `0xC26CBE0` |
| Caller statico | **NO** |

**PROVEN:** `LoadPlugIn` è una proprietà.
**PROVEN:** `Load6000` non è una funzione.
**UNPROVEN:** il caricatore.

---

## 6. Finder e Wrangler

| Elemento | Funzione |
|---|---|
| Finder `0xC26DC80` | cerca HWLibs |
| `getMatchProperty` `0xC26CBE0` | restituisce `Load6000` |
| GPU Wrangler | contesto delle stringhe |
| Loader | **UNPROVEN** |

**PROVEN:** Finder e `getMatchProperty` non caricano HWServices.
**PROVEN:** il contesto Wrangler è presente.
**UNPROVEN:** il caricatore effettivo.

---

## 7. Evidenze statiche

| Test | Esito |
|---|---|
| Caricatore in HWServices | **NO** |
| Caricatore in BootKC | **NO** |
| `LoadHWServices` in codice HWServices | **NO** |
| `LoadHWServices` in stringhe Wrangler | **SÌ** |
| Funzione Wrangler | **UNPROVEN** |
| Attivazione runtime | **UNPROVEN** |

**PROVEN:** nessun caricatore in HWServices.
**PROVEN:** due stringhe Wrangler.
**UNPROVEN:** la funzione.

---

## 8. X4000 / X5000 / X6000

| Campo | X4000 | X5000 | X6000 |
|---|---|---|---|
| `LoadHWServices` | **SÌ** | **SÌ** | **SÌ** |
| Provider | `IOPCIDevice` | `IOPCIDevice` | `IOPCIDevice` |
| Score | `65051` | `65051` | `65051` |
| `OSBundleRequired` | **assente** | **assente** | **assente** |
| `LoadPlugIn` | `Load4000` | `Load5000` | `Load6000` |

**PROVEN:** schema comune.
**PROVEN:** differenze solo prefisso e Load.
**UNPROVEN:** runtime.

---

## 9. STOP

| Criterio | Esito |
|---|---|
| Caricatore identificato | **NO** |
| Mapping stringhe | **ambiguo** |
| Funzione Wrangler | **UNPROVEN** |
| Spazio >10 GiB | **SÌ** |
| Modifiche | **NO** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| `LoadHWServices` | 5 occorrenze |
| XML | 3 |
| Wrangler | 2 |
| Caricatore | **UNPROVEN** |
| `LoadPlugIn` | proprietà |
| `Load6000` funzione | **NO** |
| Finder carica | **NO** |
| Attivazione | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `LoadHWServices=true` è dichiarato nelle personality X4000/X5000/X6000 e compare in due stringhe __REGION19 vicine a `LoadController`/`LoadAccelerator` e ai log del GPU Wrangler. Non esiste un caricatore statico identificabile in HWServices: la stringa non compare nei binari HWServices, non compare in BootKC e le due occorrenze __REGION19 hanno mapping ambiguo (simboli vicini di firmware). `LoadPlugIn=Load6000` è una proprietà di matching, non una funzione; Finder e `getMatchProperty` non caricano HWServices. Il caricatore e l’attivazione restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,2 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
