# T27 — AGENT-AMD — CHILD EVIDENCE / IOMatchCategory (158)

**Scope:** verificare se esistono evidenze archiviate di child estranei già associati a `IOMatchCategory=AMDRadeonHWLibs`; inventariare tutte le personalità AMD con quella categoria; distinguere `!registered`, `!matched` e oggetti realmente associati; cercare documentazione sull’ordine di enumerazione dei child.

**Modalità:** sola lettura. Nessun nuovo `ioreg`, trace, boot, modifica, build o download. Comandi: `grep`, `find`, `plutil`, `shasum`, `nm`.

**Esito:** **nessuna evidenza archiviata di child estranei**. Non esiste un dump `ioreg` del target né un record persistito di `!registered`/`!matched`; l’unico file in `<SESSION>/evidence` è un log `kmutil`, non un registry dump. **16/16** personalità HWLibs del root hanno `IOMatchCategory=AMDRadeonHWLibs`; 7 appartengono al provider X6000, ma il target `ATY,Boa` pubblica `Load6100` e solo X6100 supera `IOPropertyMatch`. La documentazione MacKernelSDK chiarisce che, per ogni categoria, IOKit attacca/avvia **un solo** driver: il più alto di `IOProbeScore`; se `start` riesce, gli altri della stessa categoria vengono scartati. L’ordine dei child restituito da `getChildIterator` resta **UNPROVEN**. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| `IOService.h` (MacKernelSDK) | `b63a858ca74fe35b6e1d6af6ff7f558da14fdb97eba7410e46db181545112ab1` |
| `IORegistryEntry.h` (MacKernelSDK) | `b0189e02eab0c447513ede708d92f0072f65b0bb96134d9aca9c6778f6c07939` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| X6000HWServices | `cc7aaca45446f98cc4ea03b1fdf80b402975c1b0e0d07585a304d78dcdf797f7` |
| X6000HWLibs `Info.plist` | `42599c7cdb3269e7ed39614766dc1955c3eba5eba52d3d1aeab5cad75ffcbd5c` |
| X6100HWLibs `Info.plist` | `414fa880bf31cfbdd5a0007825961c6cc9e231afba5210e563507b510deb86a1` |
| Report 157 | `53369b30576d04a1854e92206e822cf8c9517e2428a6de51c443366024c32180` |
| `HARDWARE-DISCOVERY.md` | `146b3ee000e7eef722e837781589cd3131c91be2b0301278d6efb68d2fae98dd` |
| `kmutil-hao71.log` | `d1571ffaafc86d6dcf7b9bf07f60b8383022b1977bc988ff0549e86b0b6f7b34` |

**Ambiente:** macOS `26.7.3`, build `25G342`.
**Spazio:** **15.410.392 KiB ≈ 14,70 GiB** > 10 GiB.

---

## 2. Evidenze runtime archiviate

### 2.1 Nessun dump `ioreg`

`HARDWARE-DISCOVERY.md`:

| Riga | Fatto |
|---:|---|
| 5 | **nessun dump DeviceTree/ioreg/DSDT del MacBookPro16,1 è presente** |
| 13 | dump ioreg MBP16,1: **nessun dump** |
| 14 | `*ioreg*`, log `AppleGPUWrangler`: **nessun output** |
| 27 | non esiste un file `ioreg -l` o `IODeviceTree` del MBP16,1 |
| 34 | binario `ioreg` target: **non eseguito; nessun output** |
| 37 | target 26B131 non avviato; eseguire `ioreg` sull’host misurerebbe l’host, non il target |

**PROVEN:** non esiste un’evidenza `ioreg` del target.
**PROVEN:** non esiste un elenco child del provider HWServices.
**UNPROVEN:** qualunque stato di registrazione/match dei child.

### 2.2 Nessun `!registered`/`!matched` persistito

Ricerca testuale su `T27/AGENT-AMD` e `<SESSION>` per `!registered` e `!matched`: **0 file**.

**PROVEN:** non esiste un record persistito che mostri un oggetto con questi marcatori.
**UNPROVEN:** l’esistenza di un oggetto `!registered` o `!matched` nel runtime target.
**NON DIMOSTRATO:** qualunque associazione tra un oggetto X6100 e il provider HWServices.

### 2.3 Unico file in `<SESSION>/evidence`

| File | SHA-256 | Contenuto |
|---|---|---|
| `kmutil-hao71.log` | `d1571ffaafc86d6dcf7b9bf07f60b8383022b1977bc988ff0549e86b0b6f7b34` | log `kmutil`, non `ioreg` |

**PROVEN:** l’unico artefatto di evidence della sessione è un log `kmutil`.
**PROVEN:** non è un dump IORegistry.

### 2.4 Cosa significherebbero i marcatori

| Marcatore | Significato operativo | Uso nel report |
|---|---|---|
| `!registered` | oggetto presente ma non registrato come servizio | **non è** un child associato/registrato |
| `!matched` | oggetto non matchato con un provider | **non è** un child attaccato/avviato |
| `registered` + `matched` | oggetto pubblicato e matchato | potrebbe essere un child; richiede dump |
| child list del provider | relazione padre-figlio effettiva | unica prova diretta dell’associazione |

**PROVEN:** `!registered`/`!matched` non provano un’associazione.
**PROVEN:** senza dump non si può classificare alcun oggetto.
**UNPROVEN:** l’esistenza di un child X6100 registrato/matchato.

---

## 3. Inventario personalità `AMDRadeonHWLibs`

Ricerca: tutti i `*HWLibs.kext/Contents/Info.plist` sotto il root estratto; lettura con `plutil -p`; filtro esatto `IOMatchCategory => AMDRadeonHWLibs`.

**PROVEN:** 16 personalità su 16 hanno la categoria esatta.

| Famiglia | Personalità | `LoadPlugIn` | Provider class |
|---|---|---|---|
| X4000 | X4000, X4100, X4400, X4700 | Load4000/4100/4400/4700 | `AMDRadeonX4000_AMDRadeonHWServicesInterface` |
| X5000 | X5000, X5100, X5200, X5400, X5700 | Load5000/5100/5200/5400/5700 | `AMDRadeonX5000_AMDRadeonHWServicesInterface` |
| X6000 | X6000, X6100, X6200, X6300, X6700, X6800, X6810 | Load6000/6100/6200/6300/6700/6800/6810 | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |

Dettaglio X6000 (7 personalità):

| Personalità | `IOMatchCategory` | `LoadPlugIn` | Match su `ATY,Boa` |
|---|---|---|---|
| X6000HWLibs | `AMDRadeonHWLibs` | `Load6000` | **NO** |
| X6100HWLibs | `AMDRadeonHWLibs` | `Load6100` | **SÌ** |
| X6200HWLibs | `AMDRadeonHWLibs` | `Load6200` | **NO** |
| X6300HWLibs | `AMDRadeonHWLibs` | `Load6300` | **NO** |
| X6700HWLibs | `AMDRadeonHWLibs` | `Load6700` | **NO** |
| X6800HWLibs | `AMDRadeonHWLibs` | `Load6800` | **NO** |
| X6810HWLibs | `AMDRadeonHWLibs` | `Load6810` | **NO** |

**PROVEN:** la collisione di categoria è ampia (16 personalità), non solo X6000/X6100.
**PROVEN:** la collisione è limitata dal provider class: X4000 e X5000 non competono con il provider X6000.
**PROVEN:** nel gruppo X6000 solo X6100 ha `Load6100`, il valore pubblicato dal target.
**INFERRED:** gli altri 6 non superano `IOPropertyMatch` sul target.

---

## 4. Documentazione MacKernelSDK

### 4.1 `IOMatchCategory`

`IOService.h`, righe 249–259:

| Riga | Contenuto |
|---:|---|
| 249 | la lista dei driver che matchano è ordinata per `IOProbeScore` |
| 251 | ogni entry viene processata in ordine |
| 253 | il driver viene istanziato, attaccato, `probe`, poi **detached**; si passa al successivo |
| 255 | dopo il probe, la lista è divisa in categorie `IOMatchCategory`; le categorie permettono più client del provider |
| 257 | **per ogni categoria**, il driver con score più alto viene attaccato e `start`; se `start` riesce, gli altri della stessa categoria vengono **scartati**; altrimenti si prova il successivo |
| 259 | il driver è “in azione” solo dopo `start`; consuma la categoria |

**PROVEN (documentazione):** in una categoria normalmente resta **un solo** driver attaccato/avviato.
**PROVEN (documentazione):** la selezione è per `IOProbeScore`, non per ordine di `getChildIterator`.
**PROVEN (documentazione):** più client possono coesistere solo in **categorie diverse**, non come più winner della stessa categoria.

### 4.2 `attach`

`IOService.h`, riga 1041:

- `attach` inserisce il client come child del provider nel service plane;
- il provider deve essere attivo;
- **multiple attach calls to the same provider are no-ops and return success**;
- un client può essere attaccato a più provider.

**PROVEN (documentazione):** `attach` non menziona `IOMatchCategory` e non è il punto in cui viene imposta l’unicità di categoria.
**PROVEN (documentazione):** un secondo `attach` dello **stesso** client allo stesso provider è un no-op.
**UNPROVEN:** che un secondo client estraneo, con la stessa categoria, non possa essere attaccato da un percorso manuale o residuo.

### 4.3 `getChildIterator`

`IORegistryEntry.h`, righe 518–524:

- restituisce un iteratore su **each** child nel piano;
- non specifica alcun ordinamento;
- l’iteratore deve essere rilasciato;
- gli oggetti restituiti sono retained mentre l’iteratore è valido.

**PROVEN (documentazione):** nessuna garanzia di ordine.
**PROVEN:** `findPlugIn` non ordina; quindi l’ordine effettivo dei child resta **UNPROVEN**.
**UNPROVEN:** che l’ordine sia quello di attach, di registrazione o interno alla collezione.

---

## 5. Sintesi: collisione, child e ordine

| Domanda | Risposta | Stato |
|---|---|---|
| Esiste un dump `ioreg` del target? | **NO** | **PROVEN assente** |
| Esiste un record `!registered`/`!matched`? | **NO** | **PROVEN assente** |
| Esiste una prova di child X6100 associato? | **NO** | **UNPROVEN** |
| Esiste una prova di child estraneo con categoria? | **NO** | **UNPROVEN** |
| Quante personalità condividono la categoria? | **16** | **PROVEN** |
| Quante competono sul provider X6000? | **7** | **PROVEN** |
| Quali matchano `ATY,Boa`? | **solo X6100** | **PROVEN statico** |
| IOKit attacca più winner della stessa categoria? | **NO, uno per categoria** | **PROVEN documentazione** |
| `findPlugIn` distingue `LoadPlugIn`/`IOClass`? | **NO** | **PROVEN** |
| Ordine di `getChildIterator` deterministico? | **NO dimostrato** | **UNPROVEN** |
| Child estraneo può essere scelto se presente? | **SÌ, first-match** | **PROVEN condizionale** |
| Child estraneo è presente nel target? | **NO evidenza** | **UNPROVEN** |

### 5.1 Meccanismo preciso

```text
IOCatalogue:
  drivers che matchano il provider
  -> ordina per IOProbeScore
  -> per ogni categoria:
       attacca/probe/start il migliore
       se start OK: scarta gli altri della categoria
       se start KO: prova il successivo

findPlugIn:
  getChildIterator(provider)
  -> primo child con IOMatchCategory == AMDRadeonHWLibs
  -> non controlla LoadPlugIn/IOClass
```

**PROVEN:** `findPlugIn` è first-match e non verifica la personality.
**PROVEN (documentazione):** il percorso di matching normalmente lascia un solo child per categoria.
**UNPROVEN:** un child estraneo già attaccato da un percorso diverso.

### 5.2 Perché il target resta `NON PUÒ`

Sul target `ATY,Boa`:

1. il provider pubblica `Load6100`;
2. X6100 è l’unica personalità X6000 con `Load6100`;
3. X6000 richiede `Load6000` e non matcha;
4. non esiste alcuna prova archiviata di un child X6000 o di un altro child con categoria;
5. IOKit, per documentazione, attacca un solo winner per categoria.

**Verdetto target: NON PUÒ** — la collisione di categoria non crea un secondo child e X6000 non è un candidato sul target.

### 5.3 Rischio condizionale

Se un child con `IOMatchCategory=AMDRadeonHWLibs` fosse già presente per un percorso manuale/residuo, `findPlugIn` lo restituirebbe se compare prima di X6100, senza controllare `LoadPlugIn`/`IOClass`.

**PUÒ** in questo scenario.
**UNPROVEN:** che lo scenario esista nel target.
**UNPROVEN:** l’ordine dell’iteratore.
**NON DIMOSTRATO:** che la sola condivisione della categoria produca il child estraneo.

---

## 6. Verdetto

| Domanda | Risposta |
|---|---|
| Evidenze di child estranei già associati | **NESSUNA** |
| Evidenze `!registered`/`!matched` | **NESSUNA** |
| Inventario personalità categoria | **16/16** |
| Solo X6100 matcha `ATY,Boa` | **SÌ** |
| Collisione impedisce X6100 sul target | **NON PUÒ** |
| Collisione può scegliere child sbagliato se child estraneo presente | **PUÒ condizionale / UNPROVEN** |
| Ordine child documentato | **NO** |
| Attach runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** non esistono evidenze archiviate di child estranei già associati a `AMDRadeonHWLibs`: manca qualsiasi dump `ioreg` e non c’è alcun record `!registered`/`!matched`. Tutte le 16 personalità HWLibs condividono la categoria, ma solo 7 competono sul provider X6000 e solo X6100 richiede `Load6100`, il valore del target `ATY,Boa`. La documentazione `IOService.h` conferma che per ogni categoria viene attaccato/avviato un solo driver, il più alto di score; `attach` non impone la categoria, ma il percorso di matching sì. `findPlugIn` resta un first-match per sola categoria e l’ordine di `getChildIterator` non è documentato. Il target resta **NON PUÒ**; il child estraneo resta **UNPROVEN**; l’attach runtime resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **15.410.392 KiB ≈ 14,70 GiB** > 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
