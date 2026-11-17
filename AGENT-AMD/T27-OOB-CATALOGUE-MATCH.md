# T27 — AGENT-AMD — CATALOGUE MATCH

**Scope:** verificare se il matching IOKit usa indirettamente `Navi::getMatchProperty`, analizzare `IOCatalogue`, `IOService::newUserClient`, le personality e il legame `IOPropertyMatch`/`Load6000`; confrontare X5000 solo dove il mapping è disponibile.

**Nota:** il prompt 131 è arrivato troncato alla frase “Confronta X5000 soltanto dove il mapping…”. È stata eseguita la parte completabile; il resto è **UNPROVEN**.

**Modalità:** sola lettura; BootKC, SystemKC, X6000HWServices, X5000HWServices; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che `IOCatalogue::findDrivers`, `IOCatalogue::startMatching` e `IOService::newUserClient` non usano lo slot `0x878`. **PROVEN** che `LoadPlugIn` è una chiave XML, non codice. **UNPROVEN** il chiamante di `getMatchProperty`. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| X6000HWServices | `2aa47ceee99969d3eba360fe558a3fbcd7e69c4bea2cd76704350a9bdfafe453` |
| X5000HWServices | `8a88fe7276968d3b124c9ff7ccf26d18b5e918fc339ab3681dfcb5a2cbd3cfbf` |
| Report 130 | `e988ab53479d52a64ce40636705e32516e4b4689c39cb3a3f1a138d32aa7a848` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. IOCatalogue

| Funzione | Indirizzo | Slot usati | `0x878` |
|---|---:|---|---|
| `findDrivers(IOService*, int*)` | `0xAC2CC0` | `0x88`, `0x1A0`, `0x38`, `0x1F8`, `0x1E8`, `0x1A8`, `0x28` | **NO** |
| `findDrivers(OSDictionary*, int*)` | `0xAC2E10` | `0x88`, `0x1A0`, `0x150`, `0x128`, `0x1F8`, `0x1E8`, `0x210`, `0x1A8`, `0x28` | **NO** |
| `startMatching(OSSymbol*)` | `0xAC3B00` | `0x88`, `0x1A0`, `0x148`, `0x2B8`, `0x20`, `0x28` | **NO** |
| `startMatching(OSDictionary*)` | `0xAC4E30` | `0x88`, `0x1A0`, `0x20`, `0x130`, `0x28` | **NO** |

**PROVEN:** nessuna di queste funzioni usa `0x878`.
**UNPROVEN:** il percorso completo.

---

## 3. newUserClient

| Funzione | Indirizzo |
|---|---:|
| `newUserClient(task*, void*, uint, OSDictionary*, IOUserClient**)` | `0xA97210` |
| `newUserClient(task*, void*, uint, IOUserClient**)` | `0xA97420` |
| `newUserClient(task*, void*, uint, OSDictionary&, OSSharedPtr<IOUserClient>&)` | `0xAAAA70` |
| `newUserClient(task*, void*, uint, OSSharedPtr<IOUserClient>&)` | `0xAAAAC0` |

**PROVEN:** `newUserClient` è separato dal matching.
**PROVEN:** non è stato trovato un uso di `0x878`.
**UNPROVEN:** il percorso user-client.

---

## 4. Stringhe

| Stringa | BootKC | SystemKC |
|---|---:|---:|
| `IOPropertyMatch` | **69** | **76** |
| `LoadPlugIn` | **0** | **19** |
| `getMatchProperty` | **0** | **5** |

**PROVEN:** `LoadPlugIn` è assente da BootKC.
**PROVEN:** le 19 occorrenze SystemKC sono XML/plist.
**PROVEN:** `getMatchProperty` compare solo come simbolo.
**UNPROVEN:** il consumo runtime.

---

## 5. IOPropertyMatch / Load6000

| Test | Esito |
|---|---|
| `IOPropertyMatch` nel plist | **SÌ** |
| `LoadPlugIn=Load6000` | **SÌ** |
| `Load6000` in codice | **NO** |
| Xref `LoadPlugIn`→`Load6000` | **NO** |
| Legame statico | **solo dati** |
| Legame runtime | **UNPROVEN** |

**PROVEN:** il legame è dichiarativo.
**PROVEN:** non esiste una chiamata `Load6000`.
**UNPROVEN:** l’applicazione runtime.

---

## 6. X5000

| Elemento | X5000 |
|---|---|
| `Load5000` | `0x457D1AA` |
| `Abstract::start` | `0x457C970` |
| `findPlugIn` | `0x457CD30` |
| `IOMatchCategory` | `0x457D3B7` |
| `AMDRadeonHWLibs` | `0x457D3E0` |
| slot `0x878` | **UNPROVEN** |

**PROVEN:** lo schema statico è equivalente.
**UNPROVEN:** il mapping completo X5000.
**UNPROVEN:** il runtime.

---

## 7. STOP

| Criterio | Esito |
|---|---|
| Chiamante `getMatchProperty` | **NO** |
| `IOCatalogue` usa `0x878` | **NO** |
| `newUserClient` usa `0x878` | **NO** |
| Prompt completo | **NO** |
| Spazio >10 GiB | **SÌ** |
| Modifiche | **NO** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| `IOCatalogue` usa `0x878` | **NO** |
| `newUserClient` usa `0x878` | **NO** |
| `LoadPlugIn` in codice | **NO** |
| `Load6000` funzione | **NO** |
| Legame statico | **solo XML** |
| Caller `getMatchProperty` | **UNPROVEN** |
| Runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il matching IOKit esaminato non usa indirettamente `Navi::getMatchProperty`: `IOCatalogue::findDrivers`, `IOCatalogue::startMatching` e `IOService::newUserClient` non chiamano lo slot `0x878`. `LoadPlugIn` è una chiave XML (0 occorrenze in BootKC, 19 in SystemKC), `Load6000` non è una funzione e non esiste un xref statico tra `IOPropertyMatch` e `Load6000`: il legame è dichiarativo nella personality. Il chiamante runtime di `getMatchProperty` resta **UNPROVEN**; il prompt 131 era troncato, quindi il confronto X5000 è limitato a `Load5000` e al finder. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,2 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
