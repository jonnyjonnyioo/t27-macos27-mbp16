# T27 — AGENT-AMD — HWLIBS ATTACH (153)

**Scope:** verificare come `registerService(2)` di HWServices attivi il matching IOKit, seguire il percorso verso `IOCatalogue::startMatching`/`findDrivers`, verificare le condizioni per associare la personality X6000HWLibs al provider Interface e individuare i controlli che possono impedire l'attach.

**Modalità:** sola lettura; BootKC, SystemKC, HWServices, plist HWLibs/HWServices; ricerca sorgente XNU come riferimento, senza modifiche, build, boot o trace.

**Esito:** **PROVEN** che `registerService` è a `0xFFFFFF8000A94C60` e che l'argomento `2` è `kIOServiceSynchronous`; il percorso sorgente è `registerService → startMatching → doServiceMatch → IOCatalogue::findDrivers`. **PROVEN** che i simboli `IOCatalogue::startMatching`/`findDrivers` esistono nel BootKC. **PROVEN** che la personality X6000HWLibs dichiara `IOProviderClass=Interface`, `IOMatchCategory=AMDRadeonHWLibs` e `IOPropertyMatch.LoadPlugIn`; **PROVEN** che `findPlugIn` controlla solo `IOMatchCategory`. **UNPROVEN** l'esecuzione target del corpo di `registerService`/`startMatching` e l'attach runtime; il corpo non è disassemblabile dai fileset disponibili. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| X6000HWServices | `cc7aaca45446f98cc4ea03b1fdf80b402975c1b0e0d07585a304d78dcdf797f7` |
| HWServices `Info.plist` | `c6dcc67430bbbff1490e7101d395b3dbcfe248c10adc889efd59dd1689810bf0` |
| X6000HWLibs `Info.plist` | `42599c7cdb3269e7ed39614766dc1955c3eba5eba52d3d1aeab5cad75ffcbd5c` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. `IOService::registerService`

### 2.1 Simbolo target

| Elemento | Valore |
|---|---:|
| Simbolo | `__ZN9IOService15registerServiceEj` |
| Indirizzo BootKC | `0xFFFFFF8000A94C60` |
| Tipo | `T` (testo) |
| Call-site HWServices | `0xc26da0d` |
| Argomento | `esi = 2` |

**PROVEN:** il simbolo `IOService::registerService(unsigned int)` è presente nel BootKC all'indirizzo indicato.
**PROVEN:** HWServices chiama lo slot oggetto `0x5b0` con `esi = 2`; il target chained L0 è `0xFFFFFF8000A94C60`.

### 2.2 Significato dell'argomento `2`

Riferimento sorgente XNU:

| Costante | Valore | Significato |
|---|---:|---|
| `kIOServiceSynchronous` | `0x00000002` | matching e notifiche dei client già registrati prima del ritorno |
| `kIOServiceAsynchronous` | `0x00000008` | forza il matching asincrono |
| `kIOServiceExclusive` | `0x00000001` | opzione di registrazione esclusiva |

**PROVEN (sorgente XNU):** `2` è `kIOServiceSynchronous`, non un indice di plugin e non un `LoadPlugIn`.
**PROVEN (sorgente XNU):** `registerService(options)` chiama `startMatching(options)`.
**PROVEN (sorgente XNU):** con `kIOServiceSynchronous`, `startMatching` esegue il percorso sincrono `doServiceMatch` prima di tornare, salvo i casi `needConfig`/stato del provider.

### 2.3 Limite della verifica target

Il corpo di `registerService` non è disassemblabile con `otool`/`lldb` sul fileset BootKC disponibile: il KC ha segmenti fileset con offset fuori dal file e `lldb` non risolve il simbolo nel modulo `com.apple.kernel`. Il simbolo `T` e il call-site sono provati; l'istruzione interna è **UNPROVEN** a livello di byte.

**PROVEN:** simbolo e call-site.
**UNPROVEN:** disassembly del corpo target.
**PROVEN (sorgente):** semantica di `options=2`.
**UNPROVEN:** che il target 26B131 usi esattamente la stessa sorgente; la versione XNU è un riferimento, non una prova byte-per-byte.

---

## 3. Percorso `startMatching` / `findDrivers`

### 3.1 Simboli IOCatalogue

| Simbolo | Indirizzo BootKC | Tipo |
|---|---:|---|
| `IOCatalogue::findDrivers(IOService*, int*)` | `0xFFFFFF8000AC2CC0` | `T` |
| `IOCatalogue::findDrivers(OSDictionary*, int*)` | `0xFFFFFF8000AC2E10` | `T` |
| `IOCatalogue::startMatching(OSSymbol const*)` | `0xFFFFFF8000AC3B00` | `T` |
| `IOCatalogue::startMatching(OSDictionary*)` | `0xFFFFFF8000AC4E30` | `T` |

**PROVEN:** i quattro simboli sono presenti nel BootKC.
**PROVEN:** `findDrivers` e `startMatching` sono funzioni reali, non stringhe o plist.
**UNPROVEN:** il corpo disassemblato e la sequenza esatta delle chiamate nel target.

### 3.2 Percorso sorgente

```text
IOService::registerService(options)
  -> IOService::startMatching(options)
     -> IOService::doServiceMatch(options)
        -> IOCatalogue::findDrivers(service, &generation)
           -> confronto delle personality
           -> IOService::matchInternal / matchPropertyTable
           -> IOService::startCandidate
```

**PROVEN (sorgente XNU):** `registerService` chiama `startMatching`.
**PROVEN (sorgente XNU):** `doServiceMatch` usa `gIOCatalogue->findDrivers(this, &catalogGeneration)`.
**PROVEN (sorgente XNU):** `findDrivers` restituisce la lista delle personality compatibili; il match usa le chiavi della personality.
**UNPROVEN:** la corrispondenza byte-per-byte con il BootKC 26B131.

### 3.3 Slot `0x878`

Il percorso `findDrivers`/`startMatching` non usa lo slot oggetto `0x878`:

| Funzione | Slot `0x878` |
|---|---|
| `IOCatalogue::findDrivers(IOService*, int*)` | **NO** |
| `IOCatalogue::findDrivers(OSDictionary*, int*)` | **NO** |
| `IOCatalogue::startMatching(OSSymbol const*)` | **NO** |
| `IOCatalogue::startMatching(OSDictionary*)` | **NO** |
| `IOService::probe` / `start` / `matchPropertyTable` / `propertyMatching` | **NO** |

**PROVEN (report 130/131, controlli indipendenti):** queste funzioni non usano `0x878`.
**PROVEN:** `getMatchProperty` non è il matcher IOKit; è una funzione HWServices che produce il valore della proprietà `LoadPlugIn`.
**PROVEN:** il matcher usa le chiavi della personality e `matchPropertyTable`, non lo slot `0x878` di HWServices.

---

## 4. Condizioni per l'attach HWLibs

### 4.1 Personality HWLibs

| Campo | Valore | Ruolo |
|---|---|---|
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWLibsX6000` | classe da istanziare |
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` | provider richiesto |
| `IOMatchCategory` | `AMDRadeonHWLibs` | categoria del plug-in |
| `IOPropertyMatch.LoadPlugIn` | `Load6000` | proprietà richiesta sul provider |
| `IOProbeScore` | assente | nessun punteggio esplicito; default |
| `IOResourceMatch` | assente | nessun requisito di risorsa |
| `OSBundleRequired` | assente | nessun requisito di boot |
| `OSBundleLibraries` | IOPCIFamily, bsd, iokit, libkern, mach | **nessuna** dipendenza HWServices |

**PROVEN:** la personality è completa e il legame con HWServices è dichiarativo, non di linkage.
**PROVEN:** il match richiede `LoadPlugIn=Load6000` sul provider.
**PROVEN:** `IOMatchCategory` è `AMDRadeonHWLibs`.
**UNPROVEN:** che la classe `AMDRadeonX6000_AMDRadeonHWLibsX6000` sia registrata e disponibile nel momento del match; è nel SystemKC, ma l'ordine di caricamento non è osservato.

### 4.2 Provider HWServices

| Campo | Valore |
|---|---|
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWServicesNavi` |
| `IOProviderClass` | `IOPCIDevice` |
| `IOMatchCategory` | `AMDRadeonX6000HWServices` |
| `IOPropertyMatch.LoadHWServices` | `true` |
| `IOProbeScore` | `65051` |

**PROVEN:** HWServices è pubblicato come servizio su `IOPCIDevice`.
**PROVEN:** HWServices è una sottoclasse della Interface (`AMDRadeonX6000_AMDRadeonHWServicesInterface`), quindi può soddisfare `IOProviderClass=Interface` per HWLibs.
**UNPROVEN:** l'identità runtime della superclasse e la pubblicazione effettiva dell'oggetto Interface.

### 4.3 Proprietà `LoadPlugIn`

`AMDRadeonX6000_AMDRadeonHWServicesAbstract::start`:

| Indirizzo | Azione |
|---:|---|
| `0xc26d9b3` | `getMatchProperty()` |
| `0xc26d9d7` | `setProperty("LoadPlugIn", value)` |
| `0xc26da0d` | `registerService(2)` |

**PROVEN:** la proprietà è impostata **prima** di `registerService(2)`.
**PROVEN:** `getMatchProperty` restituisce `Load6000` di default, oppure `Load6100/6200/6300/6700/6800/6810` in base al project name.
**PROVEN:** per Navi 14 i project name `ATY,Boa`/`ATR,Keelback`/`ATY,Python` mappano a `Load6100`/`Load6200`/`Load6700`; il plugin atteso può quindi essere X6100/X6200/X6700, non necessariamente X6000.

### 4.4 Ordine sincrono

`kIOServiceSynchronous = 2` significa che il matching dei client già registrati viene eseguito prima del ritorno di `registerService`, salvo i percorsi di configurazione/attesa.

**PROVEN (sorgente):** l'argomento `2` è l'opzione sincrona.
**PROVEN:** HWServices passa `2`.
**INFERRED:** `findPlugIn` dovrebbe vedere il child già attaccato al ritorno di `registerService`, se il match ha successo.
**UNPROVEN:** che il target esegua il percorso sincrono senza deferred match o senza `needConfig`.

---

## 5. Controlli che possono impedire l'attach

| Controllo | Dove | Esito |
|---|---|---|
| Provider non registrato | `registerService` | **PUÒ IMPEDIRE**: se HWServices non è nel registry/root, `registerService` ritorna senza matching |
| Provider non attaccato | `IOService::attach` | **PUÒ IMPEDIRE**: senza provider non c'è pubblicazione |
| `LoadHWServices=true` assente | plist HWServices | **IMPORTA**: HWServices non viene istanziato |
| `LoadPlugIn` assente o errato | `start` / plist HWLibs | **IMPEDISCE** il match della personality |
| `IOProviderClass` non soddisfatto | plist HWLibs | **IMPEDISCE** il match |
| `IOMatchCategory` diverso | plist HWLibs | **IMPEDISCE** il match |
| Classe HWLibs non registrata | IOCatalogue/OSKext | **PUÒ IMPEDIRE**: nessuna istanza |
| `IOProbeScore` assente | plist HWLibs | **NON IMPEDISCE**: default 0 |
| `IOResourceMatch` assente | plist HWLibs | **NON IMPEDISCE** |
| `OSBundleRequired` assente | plist HWLibs | **NON IMPEDISCE** |
| `findPlugIn` cerca solo `IOMatchCategory` | `0xc26dc80` | **NON VERIFICA** `IOClass`/`LoadPlugIn`; può selezionare il primo HWLibs della categoria |

**PROVEN:** `findPlugIn` non controlla `IOClass` né il valore di `LoadPlugIn`; controlla solo `IOMatchCategory`.
**UNPROVEN:** se il child corretto è l'unico presente o se `findPlugIn` può scegliere un plugin sbagliato.
**PROVEN:** `findPlugIn` non avvia il child; il child deve essere già stato avviato da IOKit.

---

## 6. Classificazione

| Passaggio | Evidenza | Stato |
|---|---|---|
| `registerService` simbolo `0xA94C60` | BootKC `nm` `T` | **PROVEN** |
| HWServices chiama `registerService(2)` | `0xc26da0d` | **PROVEN** |
| `2` = `kIOServiceSynchronous` | XNU source | **PROVEN sorgente** |
| `registerService` → `startMatching` | XNU source | **PROVEN sorgente** |
| `IOCatalogue::startMatching` simboli | BootKC `nm` | **PROVEN** |
| `IOCatalogue::findDrivers` simboli | BootKC `nm` | **PROVEN** |
| `findDrivers` usa slot `0x878` | report 130/131 | **REFUTED** |
| `getMatchProperty` produce `LoadPlugIn` | HWServices `0xc26cbe0` | **PROVEN** |
| `LoadPlugIn` scritto prima di `registerService` | `0xc26d9d7` / `0xc26da0d` | **PROVEN** |
| Personality HWLibs compatibile | plist | **PROVEN metadati** |
| Classe HWLibs registrata a runtime | — | **UNPROVEN** |
| Attach HWLibs effettivo | — | **UNPROVEN** |
| Ordine sincrono target | sorgente + `2` | **INFERRED** |
| Corpo target `registerService` | fileset non disassemblabile | **UNPROVEN** |

---

## 7. Punto mancante

Il punto mancante non è il caller di `getMatchProperty` (già provato nel report 152) e non è la presenza della tabella (già provata nel report 151). È la **pubblicazione/attach runtime**:

1. HWServices deve essere attaccato al provider PCI e pubblicato.
2. `registerService(2)` deve eseguire il matching sincrono.
3. `IOCatalogue::findDrivers` deve selezionare la personality HWLibs con `IOProviderClass=Interface`, `IOMatchCategory=AMDRadeonHWLibs` e `IOPropertyMatch.LoadPlugIn`.
4. La classe `AMDRadeonX6000_AMDRadeonHWLibsX6000` deve essere registrata.
5. `findPlugIn` deve trovare il child già avviato; se manca, `start` fallisce.

**PROVEN:** i punti 1–4 hanno tutti i prerequisiti statici nei plist e nei simboli.
**UNPROVEN:** l'esecuzione runtime e l'ordine effettivo.
**STOP:** il corpo di `registerService`/`startMatching` non è disassemblabile dai fileset; senza trace/IORegistry non si può andare oltre.

---

## 8. Verdetto

| Domanda | Risposta |
|---|---|
| `registerService` target | **`0xFFFFFF8000A94C60`** |
| Argomento `2` | **`kIOServiceSynchronous`** |
| `registerService` chiama `startMatching`? | **SÌ, sorgente XNU** |
| `startMatching`/`findDrivers` esistono? | **SÌ, simboli BootKC** |
| `findDrivers` usa `0x878`? | **NO** |
| `LoadPlugIn` è impostato prima? | **SÌ** |
| Match HWLibs statico | **PROVEN metadati** |
| Attach runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `HWServices::start` imposta `LoadPlugIn` e chiama `registerService(2)`. `2` è `kIOServiceSynchronous`; il percorso sorgente XNU è `registerService → startMatching → doServiceMatch → IOCatalogue::findDrivers`, e i simboli `IOService::registerService`, `IOCatalogue::startMatching` e `IOCatalogue::findDrivers` sono presenti nel BootKC. Il matching usa le chiavi della personality, non lo slot `0x878`. La personality X6000HWLibs ha tutti i prerequisiti statici (`IOProviderClass=Interface`, `IOMatchCategory=AMDRadeonHWLibs`, `IOPropertyMatch.LoadPlugIn`); `findPlugIn` però controlla solo `IOMatchCategory` e non avvia il plugin. Restano **UNPROVEN** il corpo target di `registerService`/`startMatching` e l'attach runtime. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Fonti sorgente:** `https://github.com/apple-oss-distributions/xnu/blob/main/iokit/Kernel/IOService.cpp` e `https://github.com/apple-oss-distributions/xnu/blob/main/iokit/IOKit/IOService.h`.

**Spazio:** **12.324.392 KiB ≈ 11,75 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
