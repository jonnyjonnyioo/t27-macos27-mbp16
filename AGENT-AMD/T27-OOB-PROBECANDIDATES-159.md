# T27 — AGENT-AMD — IOSERVICE PROBECANDIDATES / MATCHING (159)

**Scope:** verificare staticamente il comportamento di `IOService` nella gestione di personalità concorrenti con lo stesso `IOMatchCategory`; confrontare `IOService.h`, il sorgente XNU di riferimento e i simboli BootKC per `probeCandidates`, matching, `attach`, `start`; verificare `IOProbeScore`, ordine, scarti e fallimento di `start`; determinare se le 16 personalità AMD possono interferire con X6100 su `ATY,Boa`.

**Modalità:** sola lettura. Nessun boot, trace, modifica, build o download. Ricerca web read-only su XNU; nessun sorgente copiato nel progetto.

**Esito:** **PROVEN** che la documentazione locale descrive **un solo driver avviato per categoria** e che il sorgente XNU di riferimento implementa il controllo `copyClientWithCategory` prima dell’allocazione, una `startList` ordinata per `IOProbeScore` e il passaggio al candidato successivo solo se `start` fallisce. **PROVEN** che le 16 personalità AMD condividono la categoria ma sono separate da `IOProviderClass`; sul provider X6000 solo X6100 richiede `Load6100`, il valore del target. **NON PUÒ** quindi la collisione impedire X6100 nel percorso normale. **UNPROVEN** il bytecode target 26.7.3: i simboli BootKC esistono, ma i corpi non sono disassemblabili. **UNPROVEN** l’attach runtime. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| `IOService.h` locale | `b63a858ca74fe35b6e1d6af6ff7f558da14fdb97eba7410e46db181545112ab1` |
| Report 158 | `63c151ca305c1df4ababf32bb11fd109e0ed73ec5b790d82ba9a2d6b55609f05` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| X6000HWLibs `Info.plist` | `42599c7cdb3269e7ed39614766dc1955c3eba5eba52d3d1aeab5cad75ffcbd5c` |
| X6100HWLibs `Info.plist` | `414fa880bf31cfbdd5a0007825961c6cc9e231afba5210e563507b510deb86a1` |

**Ambiente:** macOS `26.7.3`, build `25G342`.
**Spazio:** **15.421.620 KiB ≈ 14,71 GiB** > 10 GiB.

**Nota:** il sorgente XNU consultato online è una **referenza**, non il sorgente del target. La versione `main` può differire da macOS 26.7.3; ogni conclusione sul target è marcata separatamente.

---

## 2. Evidenza locale

### 2.1 Simboli BootKC

| Simbolo | Indirizzo |
|---|---:|
| `IOService::registerService` | `0xFFFFFF8000A94C60` |
| `IOService::start` | `0xFFFFFF8000A94E70` |
| `IOService::attach` | `0xFFFFFF8000A95E30` |
| `IOService::matchPropertyTable(OSDictionary*, SInt32*)` | `0xFFFFFF8000A95AB0` |
| `IOService::matchPropertyTable(OSDictionary*)` | `0xFFFFFF8000A95AD0` |
| `IOService::matchInternal` | `0xFFFFFF8000A9AE70` |
| `IOService::startMatching` | `0xFFFFFF8000A9CFD0` |
| `IOService::probeCandidates` | `0xFFFFFF8000A9D9E0` |
| `IOService::startCandidate` | `0xFFFFFF8000A9EF50` |
| `IOService::copyClientWithCategory` | `0xFFFFFF8000A94730` |

**PROVEN:** tutti i simboli sono presenti come `T` nel BootKC.
**PROVEN:** `probeCandidates` e `startCandidate` sono funzioni reali, non stringhe.

### 2.2 Corpi target

`__TEXT_EXEC` del BootKC:

| Campo | Valore |
|---|---:|
| `vmaddr` | `0xFFFFFF80002E8000` |
| `vmsize` | `0xA14000` |
| `fileoff` | `950272` |
| `filesize` | `10567680` |

`otool -tvV` non produce istruzioni per `0xFFFFFF8000A9D9E0` né `0xFFFFFF8000A9EF50`.
**PROVEN:** il fileset non espone quei corpi a `otool`.
**UNPROVEN:** il bytecode target di `probeCandidates`/`startCandidate`.
**UNPROVEN:** eventuali differenze rispetto al sorgente XNU di riferimento.

### 2.3 Header locale

`IOService.h`:

| Riga | Contenuto |
|---:|---|
| 74 | `kIODefaultProbeScore = 0` |
| 249 | lista dei driver matchati ordinata per `IOProbeScore` |
| 251 | ogni entry è processata in ordine |
| 253 | driver attaccato, `probe`, poi **detached**; si passa al successivo |
| 255 | lista divisa in categorie `IOMatchCategory` |
| 257 | per ogni categoria, il driver con score più alto viene attaccato e `start`; se `start` riesce, gli altri della stessa categoria sono **scartati**; altrimenti si prova il successivo |
| 286 | **Only one driver in a category can be started on each provider** |
| 604 | il client è già attaccato quando viene chiamato `probe` |
| 606 | lo score ordina i driver nella stessa categoria; default `kIODefaultProbeScore` |
| 614 | `start` è chiamato sul client selezionato; il client è già attaccato |
| 1041 | più `attach` dello stesso client allo stesso provider sono **no-op** e ritornano successo; un client può essere attaccato a più provider |

**PROVEN (documentazione):** un solo driver per categoria può essere avviato su un provider.
**PROVEN (documentazione):** l’ordine di start è per `IOProbeScore`.
**PROVEN (documentazione):** `attach` non è il punto in cui viene imposta la categoria.

---

## 3. Sorgente XNU di riferimento

Fonte consultata:

- `https://github.com/apple-oss-distributions/xnu/blob/main/iokit/Kernel/IOService.cpp`
- `https://github.com/apple-oss-distributions/xnu/blob/main/iokit/IOKit/IOService.h`

### 3.1 `probeCandidates`

Il sorgente mostra questa sequenza:

```text
per ogni match:
    category = match->IOMatchCategory, oppure default
    client = copyClientWithCategory(category)
    if client != NULL:
        categoryConsumed = true
        se non è replacement -> break
    ...
    inst = allocClassWithName(...)
    inst->init(props)
    category = props->IOMatchCategory, oppure default
    inst->setProperty(IOMatchCategory, category)
    if !inst->attach(this): continue
    newInst = inst->probe(this, &score)
    inst->detach(this)
    se probe fallisce: continue
    newInst->setProperty(IOProbeScore, score)
    startList = startDict[category]
    startList = OSOrderedSet con IOServiceOrdering su IOProbeScore
    startList->setObject(newInst)
```

Poi:

```text
per ogni categoria:
    started = false
    while !started && startList non vuota:
        inst = startList->getFirstObject()
        started = startCandidate(inst)
        se !started: prova il successivo
```

**PROVEN (sorgente di riferimento):** una categoria già consumata da un client viene controllata **prima** dell’allocazione.
**PROVEN (sorgente di riferimento):** la `startList` è per categoria ed è ordinata con `IOServiceOrdering` su `IOProbeScore`.
**PROVEN (sorgente di riferimento):** `start` riuscito ferma il ciclo della categoria; `start` fallito passa al candidato successivo.

### 3.2 `startCandidate`

Il sorgente mostra:

```text
ok = service->attach(this)
if (!ok) return false
ok = service->start(this)
return ok
```

**PROVEN (sorgente di riferimento):** `startCandidate` riattacca il servizio (no-op se già attaccato) e poi chiama `start`.
**PROVEN (documentazione locale):** `attach` ripetuto sullo stesso provider è no-op.

### 3.3 `copyClientWithCategory`

Il sorgente mostra:

```text
iter = getClientIterator()
while (service = iter->getNextObject()):
    if categoria del service == categoria cercata:
        service->retain()
        break
return service
```

**PROVEN (sorgente di riferimento):** il controllo di categoria usa il client iterator, non un indice o un ordinamento.
**UNPROVEN:** l’ordine del client iterator.
**UNPROVEN:** che il comportamento del target 26.7.3 coincida con questo sorgente.

---

## 4. `IOProbeScore` nel gruppo X6000

Tutti e 7 gli HWLibs X6000:

| Personalità | `IOProbeScore` |
|---|---|
| X6000HWLibs | **assente** |
| X6100HWLibs | **assente** |
| X6200HWLibs | **assente** |
| X6300HWLibs | **assente** |
| X6700HWLibs | **assente** |
| X6800HWLibs | **assente** |
| X6810HWLibs | **assente** |

**PROVEN:** nessuna delle 7 dichiara `IOProbeScore`.
**PROVEN:** il default è `kIODefaultProbeScore = 0`.
**INFERRED:** se due personalità X6000 matchano lo stesso provider, partono con score uguale.
**UNPROVEN:** il tie-break effettivo tra score uguali; dipende dall’ordine della lista e da `IOServiceOrdering`.

Sul target questo non si verifica: solo X6100 ha `Load6100`; le altre 6 richiedono valori diversi.

---

## 5. Le 16 personalità possono interferire con X6100?

### 5.1 Separazione per provider

| Famiglia | Personalità | Provider class | Può competere con X6000? |
|---|---:|---|---|
| X4000 | 4 | `AMDRadeonX4000_AMDRadeonHWServicesInterface` | **NO** |
| X5000 | 5 | `AMDRadeonX5000_AMDRadeonHWServicesInterface` | **NO** |
| X6000 | 7 | `AMDRadeonX6000_AMDRadeonHWServicesInterface` | **SÌ, stesso provider** |

**PROVEN:** la categoria è comune a tutte e 16.
**PROVEN:** `IOProviderClass` separa X4000 e X5000 dal provider X6000.
**PROVEN:** nel gruppo X6000 solo X6100 richiede `Load6100`.

### 5.2 Flusso target

```text
HWServices::start
  -> setProperty("LoadPlugIn", "Load6100")
  -> registerService(2)
     -> probeCandidates
        -> X6100: provider + category + Load6100 OK
        -> X6000/X6200/X6300/X6700/X6800/X6810: Load diverso, non match
        -> X6100 attach + probe + start
  -> findPlugIn
     -> child X6100, categoria AMDRadeonHWLibs
```

**PROVEN statico:** X6100 è l’unica personalità X6000 con `Load6100`.
**PROVEN statico:** le altre 6 non superano `IOPropertyMatch` sul target.
**PROVEN (documentazione + sorgente):** una sola personalità per categoria viene avviata; le altre vengono scartate se `start` riesce.
**INFERRED:** `findPlugIn` trova X6100 se il matching sincrono ha completato l’attach.

### 5.3 Interferenza

| Scenario | Esito |
|---|---|
| X6100 unico match | `probeCandidates` avvia X6100 |
| X6000 presente ma `Load6000` | non è nella lista dei match |
| X6100 `start` riesce | altre personality della categoria non vengono avviate |
| X6100 `start` fallisce | si prova il successivo **solo se è nella startList**; le altre X6000 non hanno `Load6100` |
| Child estraneo con categoria già presente | `copyClientWithCategory` può far scartare X6100; **UNPROVEN** |
| Due personalità con score uguale e stesso match | tie-break **UNPROVEN**; non è il caso target |

**Verdetto target: NON PUÒ** — nel percorso normale le 16 personalità non interferiscono con X6100: solo X6100 matcha e la categoria ammette un solo driver avviato.

---

## 6. Differenze documentazione / implementazione

| Aspetto | Documentazione locale | Sorgente XNU di riferimento | Target 26.7.3 |
|---|---|---|---|
| Una sola personalità per categoria | **SÌ** (riga 286) | **SÌ**, `copyClientWithCategory` | **UNPROVEN bytecode** |
| Ordine per `IOProbeScore` | **SÌ** (righe 249–257) | **SÌ**, `IOServiceOrdering` | **UNPROVEN bytecode** |
| Scarto dopo `start` riuscito | **SÌ** | **SÌ**, loop `started` | **UNPROVEN bytecode** |
| Prossimo candidato dopo `start` fallito | **SÌ** | **SÌ**, `while` sulla startList | **UNPROVEN bytecode** |
| `attach` ripetuto no-op | **SÌ** (riga 1041) | **SÌ**, `startCandidate` riattacca | **UNPROVEN bytecode** |
| Ordine di `getChildIterator` | **NO garanzia** | non usato da `probeCandidates` | **UNPROVEN** |
| `findPlugIn` distingue `LoadPlugIn` | **NO** | codice HWServices, non XNU | **PROVEN** |

**PROVEN:** documentazione locale e sorgente di riferimento concordano sui punti sostanziali.
**PROVEN:** nessuna differenza sostanziale osservata tra docs e sorgente main.
**UNPROVEN:** la corrispondenza byte-per-byte con il target 26.7.3.
**UNPROVEN:** eventuali differenze introdotte da Apple tra `main` e 26.7.3.

---

## 7. Verdetto

| Domanda | Risposta | Stato |
|---|---|---|
| `probeCandidates` esiste in BootKC | `0xFFFFFF8000A9D9E0` | **PROVEN** |
| `startCandidate` esiste in BootKC | `0xFFFFFF8000A9EF50` | **PROVEN** |
| Corpi target disassemblati | **NO** | **UNPROVEN** |
| Sorgente XNU disponibile | **SÌ, main** | **REFERENZA** |
| Un solo driver per categoria | **SÌ** | **PROVEN docs/source** |
| `IOProbeScore` decide l’ordine | **SÌ** | **PROVEN docs/source** |
| Start fallito passa al successivo | **SÌ** | **PROVEN docs/source** |
| 16 personalità competono sul provider X6000 | **NO, solo 7** | **PROVEN** |
| Solo X6100 matcha `ATY,Boa` | **SÌ** | **PROVEN statico** |
| Collisione impedisce X6100 sul target | **NON PUÒ** | **PROVEN statico + docs/source** |
| Bytecode target coincide con main | **NO dimostrato** | **UNPROVEN** |
| Attach runtime X6100 | **NO osservato** | **UNPROVEN** |
| T27 GO? | **NO** | **OPEN** |

**Risposta netta:** `IOService::probeCandidates`/`startCandidate` esistono nel BootKC, ma i corpi target non sono disassemblabili. La documentazione locale e il sorgente XNU main concordano: `probeCandidates` controlla la categoria già consumata, ordina i candidati per `IOProbeScore`, attacca/proba, crea una `startList` per categoria e avvia il migliore; se `start` riesce scarta gli altri, se fallisce prova il successivo. Delle 16 personalità AMD, solo 7 condividono il provider X6000 e solo X6100 richiede `Load6100`; quindi la collisione di categoria **NON PUÒ** impedire X6100 nel percorso target normale. Restano **UNPROVEN** la corrispondenza byte-per-byte del target 26.7.3 e l’attach runtime; un child estraneo già presente resta un rischio condizionale non dimostrato. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **15.421.620 KiB ≈ 14,71 GiB** > 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
