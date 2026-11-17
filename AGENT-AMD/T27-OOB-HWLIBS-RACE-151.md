# T27 — AGENT-AMD — DEVICE TYPE TABLE / HWLIBS RACE (151)

> **RETTIFICA (Prompt 152):** la tabella degli slot nella prima versione usava `__ZTV` (`0xc26f078`) invece del vptr oggetto `__ZTV + 0x10` (`0xc26f088`). Il vptr corretto è `0xc26f088`: slot `0x868` → `0xc26cbe0` (`getMatchProperty`), slot `0x858` → `0xc26cd30` (`getCail`), slot `0x878` vuoto. `start` chiama quindi `getMatchProperty` a `0xc26d9b3`, non `getCail`. La sezione 4.3 e le righe collegate sono state corrette; fare riferimento al report 152 per la verifica indipendente.

**Scope:** mappare i cinque (in realtà dodici) `__ZL15deviceTypeTable` ai bundle HWLibs; verificare il consumo della tabella in `AMDRadeonX6000HWLibs`; ricostruire la sequenza HWServices → HWLibs → acceleratore; individuare chi scrive `LoadHWServices` e `LoadAccelerator`; verificare se la race HWServices/HWLibs documentata da Radeonized è applicabile a T27.

**Modalità:** sola lettura; SystemKC, binari reali `AMDRadeonX6000`, `AMDRadeonX6000HWServices`, `AMDSupport`, `AMDRadeonX6000Framebuffer`; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **TABELLA UNIVERSALE, TARGET GIÀ PRESENTE**. Tutte le tabelle HWLibs esaminate sono byte-identiche, contengono i device ID Navi 14 `0x7340/0x7341/0x7343/0x7347/0x734F` con tipo `5`, e vengono lette nel costruttore `AmdTtlServices`, non in `probe`/`start`. `LoadAccelerator` è scritto da `AMDSupport`/Framebuffer nel metodo esterno `vendor_doDeviceAttribute`, non da HWServices o HWLibs. La race di Radeonized non è dimostrata applicabile a T27. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| `AMDRadeonX6000` | `2734aaf7bf338afb9dece81466651a0c9db3a99dc6c5930798dd1fb5da63a40b` |
| `AMDRadeonX6000HWServices` | `cc7aaca45446f98cc4ea03b1fdf80b402975c1b0e0d07585a304d78dcdf797f7` |
| `AMDSupport` | `c569698b689d3822ce3f18a51202b10f46f48e395e80a339dc3bae403754f2a4` |
| `AMDRadeonX6000Framebuffer` | `a2469429602210e64a74292a30b06353d9e0f75cd6b8b65f98324e64fa0b4536` |
| Report 150 | `fcfa5666aa7f86a13b72dd1804ad7e521ebc67d2fac5940a8be2518543389d01` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. `deviceTypeTable`: mappa completa

`nm -S -m` classifica ogni tabella come `(__TEXT,__const)`, non-external. La tabella X6000 si trova a `0xc77cba0`; nel fileset il file offset coincide con l'indirizzo virtuale perché `__TEXT` ha `fileoff == vmaddr` (`0xc273000`).

| Gruppo / bundle | `__ZL15deviceTypeTable` | Dimensione | SHA-256 dei primi `0x2A0` byte |
|---|---:|---:|---|
| `com.apple.kext.AMDRadeonX5000HWLibs` | `0x4afc970` | `0x2A0` | `5d1686a3fdaa45ea260e535b18e9fb3e847e122ca3787a61123d083ee8b1e3b6` |
| `com.apple.kext.AMDRadeonX5100HWLibs` | `0x6c206e0` | `0x2A0` | idem |
| `com.apple.kext.AMDRadeonX5200HWLibs` | `0x7788830` | `0x2A0` | idem |
| `com.apple.kext.AMDRadeonX5400HWLibs` | `0x8ee3780` | `0x2A0` | idem |
| `com.apple.kext.AMDRadeonX5700HWLibs` | `0xa893d50` | `0x2A0` | idem |
| `com.apple.kext.AMDRadeonX6000HWLibs` | `0xc77cba0` | `0x2A0` | idem |
| `com.apple.kext.AMDRadeonX6100HWLibs` | `0xe1180f0` | `0x2A0` | idem |
| `com.apple.kext.AMDRadeonX6200HWLibs` | `0xf08d260` | `0x2A0` | idem |
| `com.apple.kext.AMDRadeonX6300HWLibs` | `0x104721e0` | `0x2A0` | idem |
| `com.apple.kext.AMDRadeonX6700HWLibs` | `0x1129f1d0` | `0x2A0` | idem |
| `com.apple.kext.AMDRadeonX6800HWLibs` | `0x1282ac80` | `0x2A0` | idem |
| `com.apple.kext.AMDRadeonX6810HWLibs` | `0x13450c30` | `0x2A0` | idem |

**PROVEN:** le dodici tabelle sono byte-identiche per i primi `0x2A0` byte.
**PROVEN:** la tabella è in `__TEXT,__const`, quindi in una sezione read-only del kernel collection.
**PROVEN:** non esiste una variante X4000 con questo simbolo; il simbolo compare solo nei bundle HWLibs X5000–X6810.

La tabella è un array di **84 record da 8 byte**:

```
struct DeviceType { uint32_t deviceId; uint32_t type; };
```

Il costruttore `AmdTtlServices` inizializza il tipo a `9` e poi cerca il device ID nella tabella. Per il target Navi 14:

| Indice | Device ID | Tipo |
|---:|---:|---:|
| 54 | `0x7340` | `5` |
| 55 | `0x7341` | `5` |
| 56 | `0x7343` | `5` |
| 57 | `0x7347` | `5` |
| 58 | `0x734F` | `5` |

**PROVEN:** tutti i device ID Navi 14 della personality `AMDRadeonX6000` sono già nella tabella.
**PROVEN:** il tipo associato è `5`; il default per un ID assente è `9`.
**REFUTED:** l'ipotesi che il target Navi 14 manchi dalla `deviceTypeTable` e richieda un'aggiunta per il solo fatto di essere Navi 14.

---

## 3. Consumo della tabella

### 3.1 Costruttore `AmdTtlServices`

| Indirizzo | Istruzione / significato |
|---:|---|
| `0xc3210d0` | inizio `AmdTtlServices::AmdTtlServices(IOPCIDevice*)` |
| `0xc321154` | `configRead16(0x2)` sul device PCI; valore in `0x180(%rbx)` |
| `0xc3211df` | `movl $0x9, 0x968(%rbx)`; tipo di default |
| `0xc3211e9` | `movl 0x180(%rbx), %esi`; device ID |
| `0xc3211ef` | `movl $0x3, %edx`; indice iniziale |
| `0xc3211f4` | `leaq __ZL15deviceTypeTable(%rip), %rcx` |
| `0xc321200`–`0xc32122b` | confronto di `%esi` con i device ID della tabella |
| `0xc321242`–`0xc321248` | `movl 0x4(%rcx,%rdx,8), %ecx`; `movl %ecx, 0x968(%rbx)` |
| `0xc32124e` | prosegue con la mappatura dei registri / initializzazione TTL |

**PROVEN:** la tabella viene letta nel costruttore `AmdTtlServices`.
**PROVEN:** il valore letto è il campo `type` del record, salvato in `0x968(%rbx)`.
**PROVEN:** la lettura avviene dopo `configRead16(0x2)`, cioè dopo aver ottenuto il device ID dal PCI config space.
**UNPROVEN:** il significato runtime esatto del campo `type = 5`.

### 3.2 Chi costruisce `AmdTtlServices`

| Indirizzo | Funzione / chiamata |
|---:|---|
| `0xc320f70` | `AmdTtlInterface::createTtlService(IOPCIDevice*)` |
| `0xc320f8d` | `callq AmdTtlServices::AmdTtlServices(IOPCIDevice*)` |
| `0xc274d30` | `AMDRadeonX6000_AMDRadeonHWLibsSWIP::createTtlInterface(IOPCIDevice*)` |
| `0xc274d6c` | `callq AmdTtlInterface::createTtlService(IOPCIDevice*)` |

**PROVEN:** la catena statica è `AMDRadeonHWLibsSWIP::createTtlInterface` → `AmdTtlInterface::createTtlService` → costruttore `AmdTtlServices` → lettura `deviceTypeTable`.
**PROVEN:** la lettura non è in `AMDRadeonHWLibs::probe` (`0xc274270`) né in `AMDRadeonHWLibs::start` (`0xc2744e0`).
**UNPROVEN:** il momento runtime preciso in cui `createTtlInterface` viene invocata rispetto al matching IOKit.

### 3.3 Conseguenza per un patch

La tabella è in `__TEXT,__const`; una scrittura diretta del tipo `*(uint32_t *)0xc77cba0 = ...` non è un'operazione sicura su una pagina read-only. Un progetto esterno che patcha `deviceTypeTable` deve prima rendere scrivibile la pagina o usare una mappatura dedicata. Per T27:

| Domanda | Risposta |
|---|---|
| Il target è già presente? | **SÌ**, tipo `5` |
| Serve aggiungere il device ID? | **NO**, per i cinque ID Navi 14 |
| La tabella è scrivibile con un semplice store? | **NO**, è `__TEXT,__const` |
| Radeonized deve patchare questa tabella per Navi 14? | **NO**, non per aggiungere l'ID |
| Un patch della tabella è necessario per T27? | **UNPROVEN / non dimostrato** |

**PROVEN:** la tabella è read-only e già completa per il target.
**REFUTED:** l'idea che il fallimento di T27 sia dovuto a un device ID Navi 14 assente dalla tabella.

---

## 4. Sequenza HWServices → HWLibs

### 4.1 `AMDRadeonX6000HWServices`

`Info.plist`:

| Campo | Valore |
|---|---|
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWServicesNavi` |
| `IOPCIMatch` | include `0x7310…`, `0x7340/41/43/47/4F`, `0x7360`, `0x73A2/AB/BF/A3`, `0x73E3/FF/E0` |
| `IOPropertyMatch` | `{ LoadHWServices = true }` |
| `IOProbeScore` | `65051` |
| `IOProviderClass` | `IOPCIDevice` |

**PROVEN:** la personality HWServices è quella Navi e copre i device ID target.
**PROVEN:** il match richiede il property `LoadHWServices=true`.

### 4.2 `getMatchProperty`

`AMDRadeonX6000_AMDRadeonHWServicesNavi::getMatchProperty()` è a `0xc26cbe0`.

| Indirizzo | Comportamento |
|---:|---|
| `0xc26cc02` | default `"Load6000"` in `-0x30(%rbp)` |
| `0xc26cc1d` | `PE_parse_boot_argn("-amd_simnow", …)` |
| `0xc26cc45` | se il boot-arg è presente: `"Load6000Sim"` |
| `0xc26cc50`–`0xc26cc8d` | legge `0xa0(%rax)` (project name) e confronta con `ProjectNameTable[i].first` |
| `0xc26ccb0` | se match: `ProjectNameTable[i].second` diventa il valore di ritorno |
| `0xc26ccd0`–`0xc26ccec` | ritorna la stringa selezionata |

`ProjectNameTable` è a `0xc271730`; `PROJECT_NAME_COUNT` è a `0xc26e3a0` e vale `9`.

| Indice | Project name | Load string |
|---:|---|---|
| 0 | `ATY,Henbury` | `Load6810` |
| 1 | `ATY,Belknap` | `Load6800` |
| 2 | `ATY,Carswell` | `Load6800` |
| 3 | `ATY,Sunbeam` | `Load6300` |
| 4 | `ATY,Ikaheka` | `Load6200` |
| 5 | `ATY,Keelback` | `Load6200` |
| 6 | `ATY,Python` | `Load6700` |
| 7 | `ATY,Adder` | `Load6700` |
| 8 | `ATY,Boa` | `Load6100` |

**PROVEN:** il default è `Load6000`.
**PROVEN:** `-amd_simnow` sostituisce il default con `Load6000Sim`.
**PROVEN:** la tabella progetto è di 9 elementi e contiene i mapping sopra.

### 4.3 Pubblicazione di `LoadPlugIn` e slot corretti

`AMDRadeonX6000_AMDRadeonHWServicesAbstract::start` è a `0xc26d8c0`.

Il costruttore `AMDRadeonX6000_AMDRadeonHWServicesNavi` (`0xc26c980`) imposta il puntatore vtable dell'oggetto a `__ZTV38AMDRadeonX6000_AMDRadeonHWServicesNavi + 0x10` (`0xc26c9a5`–`0xc26c9b0`), cioè `0xc26f088`. Gli slot vanno quindi letti da `0xc26f088`, non da `__ZTV` (`0xc26f078`).

| Slot oggetto | Entry | Target | Simbolo |
|---:|---:|---:|---|
| `0x858` | `0xc26f8e0` | `0xc26cd30` | `AMDRadeonX6000_AMDRadeonHWServicesAbstract::getCail()` |
| `0x868` | `0xc26f8f0` | `0xc26cbe0` | `AMDRadeonX6000_AMDRadeonHWServicesNavi::getMatchProperty()` |
| `0x878` | `0xc26f900` | `0` | slot vuoto |

`start` esegue:

| Indirizzo | Istruzione / significato |
|---:|---|
| `0xc26d961` | `populateDeviceInfo` |
| `0xc26d9a0` | `readProjectName` |
| `0xc26d9b0` | chiamata virtuale `*0x868` → `getMatchProperty` (`0xc26cbe0`) |
| `0xc26d9bd`–`0xc26d9c3` | se il ritorno è nullo, errore `"No Match PlugIn Reg Key."` |
| `0xc26d9c5`–`0xc26d9d7` | `setProperty(MATCH_PLUG_IN_REG_KEY, returnedValue)` |
| `0xc26da0d` | chiamata virtuale `*0x5b0` con `esi = 2`; target `0x994c60` → `0xFFFFFF8000A94C60` = `IOService::registerService(2)` |
| `0xc26da21` | `findPlugIn()` |
| `0xc26dc80` | scansione dei figli; confronto `IOMatchCategory` con `HWLIB_PLUG_IN_MATCH_CATEGORY` (`"AMDRadeonHWLibs"`) |

**PROVEN:** `start` chiama lo slot oggetto `0x868` → `getMatchProperty`; il call-site statico è `0xc26d9b3`.
**PROVEN:** `getCail` (`0xc26cd30`) è nello slot `0x858` e non viene chiamato da `start`.
**PROVEN:** il `setProperty` di `LoadPlugIn` è a `0xc26d9d7`.
**PROVEN:** `start` chiama `registerService(2)` a `0xc26da0d`; `findPlugIn` segue a `0xc26da21`.
**PROVEN:** `findPlugIn` cerca il figlio con `IOMatchCategory = AMDRadeonHWLibs`.
**CORRETTO:** la precedente affermazione che `start` chiamasse `getCail` era errata; derivava dall'uso di `__ZTV` invece del vptr oggetto `+0x10`.

**Conseguenza:** il percorso statico è `readProjectName` → `getMatchProperty` → `setProperty("LoadPlugIn")` → `registerService(2)` → `findPlugIn`. La selezione del plugin è quindi concatenata; non è un punto aperto. Resta **UNPROVEN** solo l'esito runtime del matching IOKit.

### 4.4 Plugin HWLibs e target Navi 14

`AMDRadeonX6000HWLibs.kext/Contents/Info.plist` dichiara:

| Campo | Valore |
|---|---|
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWLibsX6000` |
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `{ LoadPlugIn = Load6000 }` |
| `IOMatchCategory` | `AMDRadeonHWLibs` |

Gli altri plugin della stessa HWServices usano `Load6100`, `Load6200`, `Load6300`, `Load6700`, `Load6800`, `Load6810`.

`AMDRadeonX6000Framebuffer.kext/Contents/Info.plist` colloca i project name Navi 14 sotto `AMDRadeonNavi14Controller`:

| Project name | Load string (da HWServices) |
|---|---|
| `ATY,Boa` | `Load6100` |
| `ATY,Keelback` | `Load6200` |
| `ATY,Python` | `Load6700` |

**PROVEN:** il MacBookPro16,1/Navi 14 non è legato in modo statico e univoco a `X6000HWLibs`; a seconda del project name può selezionare X6100, X6200 o X6700.
**PROVEN:** tutte le tabelle `deviceTypeTable` di X6100/X6200/X6700/X6000 sono identiche e contengono i cinque ID target con tipo `5`.
**UNPROVEN:** quale dei tre project name sia effettivamente usato dal VBIOS del MacBookPro16,1; servirebbe ioreg/VBIOS o runtime.

**Conseguenza:** l'analisi della tabella non dipende dal bundle X6000; il target è coperto allo stesso modo da tutti i bundle HWLibs Navi 14.

---

## 5. Acceleratore e `LoadAccelerator`

### 5.1 Personality `AMDRadeonX6000`

`AMDRadeonX6000.kext/Contents/Info.plist` contiene cinque personalities con:

| Campo | Valore |
|---|---|
| `IOMatchCategory` | `IOAccelerator` |
| `IOPropertyMatch` | `{ LoadAccelerator = true }` |
| `IOPCIMatch` | gruppi che includono `0x7340 0x7341 0x7343 0x7347 0x734F` |
| `IOProviderClass` | `IOPCIDevice` |

**PROVEN:** il target Navi 14 è presente nelle personality dell'acceleratore.
**PROVEN:** l'acceleratore richiede `LoadAccelerator=true` sul provider.

### 5.2 Chi scrive `LoadAccelerator`

`AMDSupport` — `AtiGpuWrangler::vendor_doDeviceAttribute` a `0x13b84370`:

| Indirizzo | Istruzione |
|---:|---|
| `0x13b845fd` | `andl $0x2, %eax`; test del bit 1 dei flag |
| `0x13b84611` | `setProperty("LoadHWServices", 1)` |
| `0x13b8462d` | `setProperty("LoadAccelerator", 1)` |
| `0x13b84648` | `andl $0x3, %eax`; eventuale `*0x5b0` |

`AMDRadeonX6000Framebuffer` — `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute` a `0xbf9894e`:

| Indirizzo | Istruzione |
|---:|---|
| `0xbf98a1c` | test del bit 1 |
| `0xbf98a25` | `setProperty("LoadHWServices", 1)` |
| `0xbf98a6b` | test del bit 1 |
| `0xbf98a72` | `setProperty("LoadAccelerator", 1)` |

**PROVEN:** `LoadHWServices` e `LoadAccelerator` sono scritti nello stesso ramo, in sequenza, dalla stessa funzione.
**PROVEN:** entrambe le funzioni sono `vendor_doDeviceAttribute`, un metodo esterno del wrangler, non `start`/`probe`.
**PROVEN:** `LoadAccelerator` non compare come stringa nei binari HWServices/HWLibs/X6000; compare in `AMDSupport`, `AMDRadeonX6000Framebuffer` e nei plist.
**REFUTED:** l'ipotesi che HWServices o HWLibs scrivano `LoadAccelerator`.

### 5.3 `createHWInterface`

`AMDRadeonX6000_AMDGraphicsAccelerator::createHWInterface(IOPCIDevice*)` è a `0xbdc6db6`.

| Indirizzo | Istruzione |
|---:|---|
| `0xbdc6dc8` | test del device |
| `0xbdc6dd4`–`0xbdc6dda` | `callq *0xb48(%rax)`; crea/ottiene l'oggetto Interface |
| `0xbdc6de0` | salva il ritorno in `0x1a38(%rbx)` |
| `0xbdc6dfe`–`0xbdc6e01` | `fillGartParameters` |
| `0xbdc6e1d`–`0xbdc6e23` | `callq *0x118(%rax)` |
| `0xbdc6e29`–`0xbdc6e34` | se il ritorno è vero, setta il bit `0x1` in `0x1e89(%rbx)` |
| `0xbdc6e36`–`0xbdc6e48` | cleanup dell'oggetto se il ritorno è falso |

**PROVEN:** `createHWInterface` non legge `deviceTypeTable`.
**PROVEN:** `createHWInterface` non legge `LoadAccelerator`.
**PROVEN:** non c'è un gate HWServices/HWLibs dentro `createHWInterface`; la funzione opera sull'oggetto Interface già creato.

---

## 6. Sequenza statica risultante

| Fase | Evidenza | Stato |
|---|---|---|
| 1. `AMDSupport`/wrangler imposta `LoadHWServices` | `0x13b84611`, `0xbf98a25` | **PROVEN** |
| 2. Lo stesso ramo imposta `LoadAccelerator` | `0x13b8462d`, `0xbf98a72` | **PROVEN** |
| 3. HWServices matcha `LoadHWServices=true` | plist HWServices | **PROVEN** |
| 4. HWServices `start`: `*0x868` → `getMatchProperty`, poi `setProperty` `LoadPlugIn` e `registerService(2)` | `0xc26d9b0`–`0xc26da0d` | **PROVEN** |
| 5. HWLibs matcha `LoadPlugIn` e la Interface | plist HWLibs | **PROVEN** |
| 6. HWLibs start/attach; TTL service creation | `0xc274d30` → `0xc274d6c` → `0xc320f8d` | **PROVEN** statico |
| 7. `AmdTtlServices` legge `deviceTypeTable` | `0xc3211f4` | **PROVEN** |
| 8. Acceleratore matcha `LoadAccelerator=true` | plist X6000 | **PROVEN** |
| 9. `createHWInterface` crea l'Interfaccia | `0xbdc6db6` | **PROVEN** statico |

**PROVEN:** la sequenza statica non contiene un'attesa di HWLibs prima di scrivere `LoadAccelerator`.
**PROVEN:** la tabella viene consumata nella creazione del servizio TTL, non nel `probe` HWLibs.
**UNPROVEN:** l'ordine temporale effettivo dei match IOKit e l'esecuzione delle stub NX.

---

## 7. Confronto con Radeonized

Radeonized è un progetto per **Rembrandt APU** (680M), non per Navi 14 dGPU. Il suo schema documentato:

| Elemento Radeonized | T27 / Navi 14 | Esito |
|---|---|---|
| `LoadHWServices` + gate HWLibs | HWServices pubblica `LoadPlugIn`; nessun gate HWLibs analogo | **NON EQUIVALENTE** |
| `LoadAccelerator` come gate | `LoadAccelerator` è scritto dal wrangler, non da HWLibs | **NON DIMOSTRATO** |
| `patchDeviceTypeTable` per aggiungere device ID | tutti i cinque ID target sono già presenti, tipo `5` | **NON NECESSARIO** |
| tabella in `__TEXT,__const` | richiede scrittura read-only; nessun store semplice | **RISCHIO STATICO** |
| race HWServices/HWLibs 2,5–3,6 ms | nessuna prova statica di un ritardo equivalente | **UNPROVEN** |
| patch in ritardo di 67,8 ms | nessun timing T27 misurato | **UNPROVEN** |

**PROVEN:** Radeonized non è una soluzione Navi dGPU.
**PROVEN:** il razionale "device ID mancante" non si applica a Navi 14.
**PROVEN:** la tabella è read-only e già completa.
**REFUTED:** l'applicazione diretta del patch `deviceTypeTable` di Radeonized come spiegazione sufficiente per T27.
**UNPROVEN:** l'esistenza di una race HWServices/HWLibs su Navi 14; sarebbe necessaria una misura runtime.

---

## 8. Statico vs runtime

| Elemento | Statico | Runtime |
|---|---|---|
| Tabella universale e SHA | **PROVEN** | **UNPROVEN** |
| ID Navi 14 presenti, tipo `5` | **PROVEN** | **UNPROVEN** |
| Lettura in `AmdTtlServices` | **PROVEN** | **UNPROVEN** |
| `setProperty` `LoadPlugIn` in HWServices | **PROVEN** | **UNPROVEN** |
| Caller di `getMatchProperty` | **SÌ: `start` a `0xc26d9b3`** | **UNPROVEN** |
| `LoadAccelerator` scritto dal wrangler | **PROVEN** | **UNPROVEN** |
| `createHWInterface` senza tabella/gate | **PROVEN** | **UNPROVEN** |
| Race HWServices/HWLibs | **NON DIMOSTRATA** | **UNPROVEN** |
| Patch read-only | **RISCHIO STATICO** | **UNPROVEN** |

**PROVEN:** la struttura statica è chiara.
**UNPROVEN:** l'ordine temporale e la validità runtime.

---

## 9. Verdetto

| Domanda | Risposta |
|---|---|
| `deviceTypeTable` mappata | **SÌ**, 12 bundle HWLibs |
| Tabelle identiche | **SÌ**, SHA `5d1686…` |
| Target Navi 14 presente | **SÌ**, `0x7340/41/43/47/4F`, tipo `5` |
| Tabella letta in `probe`/`start` HWLibs | **NO** |
| Tabella letta in `AmdTtlServices` | **SÌ**, `0xc3211f4` |
| `LoadAccelerator` scritto da HWServices/HWLibs | **NO** |
| `LoadAccelerator` scritto da AMDSupport/Framebuffer | **SÌ**, `vendor_doDeviceAttribute` |
| `createHWInterface` usa la tabella | **NO** |
| `createHWInterface` usa `LoadAccelerator` | **NO** |
| Race Radeonized applicabile | **UNPROVEN / non dimostrata** |
| Patch tabella necessario per Navi 14 | **NO** |
| Runtime osservato | **NO** |
| T27 GO? | **NO — OPEN** |

**PROVEN:** la tabella è già corretta per il target e non è il punto di pubblicazione dell'Interface.
**REFUTED:** la necessità di aggiungere un device ID Navi 14 alla `deviceTypeTable`.
**UNPROVEN:** la race HWServices/HWLibs e l'ordine di caricamento reale.

---

## 10. Conclusione

| Voce | Valore |
|---|---|
| Tabella X6000 | `0xc77cba0`, `__TEXT,__const`, `0x2A0` byte |
| Record | 84 × `{ uint32 deviceId; uint32 type; }` |
| SHA tabella | `5d1686a3fdaa45ea260e535b18e9fb3e847e122ca3787a61123d083ee8b1e3b6` |
| Target | `0x7340`, `0x7341`, `0x7343`, `0x7347`, `0x734F` |
| Tipo target | `5` |
| Lettura | `AmdTtlServices` ctor, `0xc3211f4` |
| Catena | `createTtlInterface` → `createTtlService` → ctor |
| HWServices | `getMatchProperty` `0xc26cbe0` (slot `0x868`), `LoadPlugIn`, `registerService(2)`; caller `start` `0xc26d9b3` |
| HWLibs | `Load6000`/`Load6100`/`Load6200`/`Load6700`/… |
| Acceleratore | `LoadAccelerator` `0x13b8462d`, `0xbf98a72` |
| `createHWInterface` | `0xbdc6db6`, nessuna tabella/gate |
| Race Radeonized | **UNPROVEN** |
| T27 | **OPEN** |

**Risposta netta:** la `deviceTypeTable` non è il punto mancante di T27. Tutte le HWLibs X5000–X6810 condividono la stessa tabella di 84 record, e i cinque device ID Navi 14 sono già presenti con tipo `5`; il target non richiede l'aggiunta di un ID. La tabella è in `__TEXT,__const` e viene letta nel costruttore `AmdTtlServices`, raggiunto da `createTtlInterface`/`createTtlService`, non da `probe` o `start` di HWLibs. `LoadAccelerator` non è scritto da HWServices o HWLibs: è scritto da `AMDSupport` e dal Framebuffer nel metodo esterno `vendor_doDeviceAttribute`, nello stesso ramo che pubblica `LoadHWServices`. `createHWInterface` non legge né la tabella né `LoadAccelerator`. La race HWServices/HWLibs di Radeonized, documentata su Rembrandt APU, non è dimostrata applicabile a Navi 14 dGPU: il razionale della patch del device type non regge per il target, e non c'è una misura runtime del timing. Resta **UNPROVEN** l'ordine effettivo dei match IOKit e delle stub NX. STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **12.324.392 KiB ≈ 11,75 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
