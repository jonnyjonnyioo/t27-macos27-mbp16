# T27 — AGENT-AMD — WRANGLER FLAGS / CALLER (163)

**Scope:** identificare chi imposta `flags & 0x2` prima di `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute` (`0xbf9894e`); ricostruire caller diretti e indiretti, vtable comprese; individuare origine, inizializzazione e propagazione del campo; analizzare costruttori, superclassi, `probe`, `start` e registrazione; confrontare `AtiGpuWrangler` in AMDSupport (`0x13b84370`); determinare se il target soddisfa il bit `0x2`; indicare la prova statica decisiva mancante.

**Modalità:** sola lettura. Nessun boot, trace, modifica, build o download. Comandi: `nm`, `otool`, `strings`, `grep`, `find`, `plutil`, `shasum`.

**Esito:** **PROVEN** che `vendor_doDeviceAttribute` non ha call dirette nei due kext: è raggiunto solo per dispatch indiretto/vtable. **PROVEN** che il bit `0x2` è letto da un puntatore argomento (`rdx`) e non viene inizializzato da costruttore, `probe`, `attach` o `start`. **PROVEN** che i due percorsi (X6000 e AMDSupport) hanno la stessa condizione. **UNPROVEN** chi passi il bit `0x2` sul target. La prova decisiva è il caller AGDC/AppleGraphicsDeviceControl, assente nel root estratto, oppure un `ioreg` archiviato. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| X6000Framebuffer executable | `a2469429602210e64a74292a30b06353d9e0f75cd6b8b65f98324e64fa0b4536` |
| X6000Framebuffer `Info.plist` | `1b28b9aab877c4b3362edabde5a512d45d0cf97c10611b034c8ea53995a9f573` |
| AMDSupport executable | `c569698b689d3822ce3f18a51202b10f46f48e395e80a339dc3bae403754f2a4` |
| AMDSupport `Info.plist` | `e9fa60b1333f055a4308dcdaa45d6aef078f3e7ea7eee547a1f4a2b9f1e9ba72` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| Report 162 | `fa3cf33da5d2566a36479c10460b89ce12561ac503e43bde5935d634f3d92174` |

**Ambiente:** macOS `26.7.3`, build `25G342`.
**Spazio:** **15.413.964 KiB ≈ 14,70 GiB** > 10 GiB.

---

## 2. Caller diretti

| Binario | Funzione | Call dirette trovate |
|---|---|---:|
| X6000Framebuffer | `AmdGpuWrangler::vendor_doDeviceAttribute` `0xbf9894e` | **0** |
| AMDSupport | `AtiGpuWrangler::vendor_doDeviceAttribute` `0x13b84370` | **0** |

**PROVEN:** nei due binari non esiste una `callq` diretta alle funzioni.
**PROVEN:** la funzione è referenziata da una tabella di puntatori in `__DATA_CONST`.
**INFERRED:** il percorso è virtuale/AGDC, non una chiamata C++ diretta.

### 2.1 Entry nella tabella

Nel binario X6000Framebuffer, il puntatore a `0xbf9894e` compare a file offset **3221960**, corrispondente a `0xc26e9c8` nella regione `__DATA_CONST`.

| Voce | Valore |
|---|---:|
| File offset | `3221960` |
| VA tabella | `0xc26e9c8` |
| Puntatore | `0xbf9894e` |
| Simbolo funzione | `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute` |

**PROVEN:** il puntatore è in una tabella di dispatch.
**PROVEN:** non è una chiamata diretta.
**UNPROVEN:** quale classe/vtable possieda quella tabella e quale caller la usi.

---

## 3. Origine del bit `0x2`

### 3.1 X6000Framebuffer

`0xbf9894e`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0xbf9895f` | `movq %rdx, %rbx` | salva l’argomento `rdx` |
| `0xbf98a1c` | `movl (%rbx), %eax` | legge il bitmask dal puntatore |
| `0xbf98a1e` | `testb $0x2, %al` | verifica bit `0x2` |
| `0xbf98a20` | `je 0xbf98a4d` | salta la scrittura se assente |
| `0xbf98a25` | `leaq "LoadHWServices"` | chiave |
| `0xbf98a34` | `callq *0x278(%rax)` | `setProperty` |

**PROVEN:** il bitmask è letto da `(%rbx)`.
**PROVEN:** `rbx` è l’argomento `rdx` ricevuto dal caller.
**PROVEN:** la funzione non assegna `(%rbx)` prima del test.
**PROVEN:** senza bit `0x2` non viene scritto `LoadHWServices`.

### 3.2 AMDSupport

`0x13b84370`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x13b8457a` | `callq *0x680(%rax)` | provider |
| `0x13b845ff` | `andl $0x2, %eax` | verifica bit `0x2` |
| `0x13b84611` | `leaq "LoadHWServices"` | chiave |
| `0x13b8461d` | `callq *0x278(%rax)` | `setProperty` |

**PROVEN:** stessa condizione, stesso bit, stesso valore `true`.
**PROVEN:** anche qui il bitmask arriva dall’esterno.

---

## 4. Costruttori e metodi IOService

### 4.1 Costruttori

`AmdGpuWrangler::C1` a `0xbf9854e` e `C2` a `0xbf9857e`:

| Indirizzo | Azione |
|---:|---|
| `0xbf98558` | carica `gMetaClass` |
| `0xbf98562` | chiama il costruttore base |
| `0xbf98567` | carica la vtable |
| `0xbf9856e` | salva il vptr |

**PROVEN:** i costruttori non inizializzano bitmask, provider o `LoadHWServices`.
**PROVEN:** non chiamano `vendor_doDeviceAttribute`.

### 4.2 `probe`

`0xbf985ae`:

| Controllo | Esito |
|---|---|
| provider non nullo | sì |
| score non nullo | sì |
| provider è `IOPCIDevice` | controllato a `0xbf98696` |
| flags `0x2` inizializzato | **NO** |
| `vendor_doDeviceAttribute` chiamato | **NO** |

**PROVEN:** `probe` non introduce il bit `0x2`.

### 4.3 `attach`

`0xbf986d2`:

| Indirizzo | Azione |
|---:|---|
| `0xbf9870e` | lookup proprietà display |
| `0xbf9872e` | legge `getDisplayId` (slot `0x8e8`) |
| `0xbf98745` | legge `getDisplayId` (slot `0x8f0`) |
| `0xbf9875c` | legge `getDisplayId` (slot `0x8f8`) |
| `0xbf987bc` | tail-call a `IOService::attach` slot `0x680` |

**PROVEN:** `attach` legge identità display e chiama la superclasse.
**PROVEN:** non inizializza flags e non chiama `vendor_doDeviceAttribute`.

### 4.4 `start`

`0xbf987c2`:

| Indirizzo | Azione |
|---:|---|
| `0xbf987d6` | chiama `IOService::start` (slot `0x5d0`) |
| `0xbf9881d` | `registerService(0)` |
| `0xbf98838` | lookup `AMDRadeonLoadSvcMgr` |
| `0xbf98857` | `setProperty("AMDRadeonLoadSvcMgr", true)` |
| `0xbf98865` | `registerService(0)` sul servizio |

**PROVEN:** `start` non contiene `LoadHWServices`.
**PROVEN:** `start` non chiama `vendor_doDeviceAttribute`.
**PROVEN:** il bit `0x2` non nasce nel ciclo di vita IOService del Wrangler.

---

## 5. Superclassi e AGDC

### 5.1 `AmdAgdcServices`

`AMDRadeonX6000_AmdAgdcServices::vendor_doDeviceAttribute` a `0xbf73668`:

| Elemento | Evidenza |
|---|---|
| input comando | `validateCommand`, `allowHwCommand` |
| input esterni | `IOExternalMethodArguments` |
| dispatch | tabella comandi `0x700`–`0x974` |
| call diretta a Wrangler | **assente** |

**PROVEN:** `AmdAgdcServices` è un dispatcher di comandi AGDC.
**PROVEN:** non chiama direttamente `AmdGpuWrangler::vendor_doDeviceAttribute`.
**UNPROVEN:** il comando/attributo che porta il bit `0x2`.

### 5.2 AppleGraphicsDeviceControl

| Elemento | Stato |
|---|---|
| bundle `AppleGraphicsDeviceControl.kext` | presente |
| `Contents/MacOS/AppleGraphicsDeviceControl` | **assente nel root estratto** |
| codice del caller AGDC | **non disponibile** |
| `AGDCDiagnose` | presente come tool, non come caller del kext |

**PROVEN:** il binario del kext AGDC non è nel root estratto.
**UNPROVEN:** il caller AGDC e il valore del bitmask.

---

## 6. Confronto con AtiGpuWrangler

| Elemento | X6000 `AmdGpuWrangler` | AMDSupport `AtiGpuWrangler` |
|---|---|---|
| funzione | `0xbf9894e` | `0x13b84370` |
| provider | `getProvider` slot `0x680` | `getProvider` slot `0x680` |
| test bit | `testb $0x2` | `andl $0x2` |
| chiave | `LoadHWServices` | `LoadHWServices` |
| valore | `true` | `true` |
| call dirette | **0** | **0** |
| inizializzazione flags | **assente** | **assente** |

**PROVEN:** i due percorsi sono strutturalmente equivalenti.
**PROVEN:** nessuno dei due inizializza il bit.
**INFERRED:** il bit è fornito dallo stesso livello AGDC/attributi.
**UNPROVEN:** quale dei due venga eseguito sul target.

---

## 7. Il target soddisfa il bit `0x2`?

| Evidenza | Esito |
|---|---|
| personality `AMDGPUWrangler` copre `0x73401002` | **PROVEN** |
| classe `AmdGpuWrangler` in SystemKC | **PROVEN** |
| `start`, `probe`, `attach` inizializzano flags | **NO — REFUTED** |
| caller AGDC disponibile | **NO — UNPROVEN** |
| `LoadHWServices` osservato su ioreg target | **NO — UNPROVEN** |
| target soddisfa bit `0x2` | **UNPROVEN** |

**PROVEN:** il target ha il potenziale per eseguire il percorso: device ID e classe sono presenti.
**UNPROVEN:** che il caller passi il bit `0x2`.
**NON DIMOSTRATO:** che l’assenza di `LoadHWServices` sia la causa del mancato caricamento HWServices.

---

## 8. Prova statica decisiva

| Prova | Dove cercarla | Stato |
|---|---|---|
| caller di `vendor_doDeviceAttribute` | AppleGraphicsDeviceControl / AGDC | **assente nel root** |
| valore del bitmask `0x2` | caller o `IOExternalMethodArguments` | **UNPROVEN** |
| scrittura `LoadHWServices` sul provider | trace xref dinamico o ioreg | **UNPROVEN** |
| presenza proprietà sul PCI target | dump `ioreg` archiviato | **assente** |

**PROVEN:** nessuna delle quattro prove è disponibile nei file attuali.
**PROVEN:** il codice del produttore è presente; manca l’input che lo attiva.
**UNPROVEN:** la decisione target.

---

## 9. Diagnosi

| Priorità | Elemento | Stato |
|---:|---|---|
| 1 | bit `0x2` nel caller AGDC | **UNPROVEN** |
| 2 | scrittura `LoadHWServices` sul provider | **PROVEN codice; runtime UNPROVEN** |
| 3 | match HWServices | **PROVEN metadati; runtime UNPROVEN** |
| 4 | `Load6100` e X6100 | **PROVEN statico** |
| 5 | X6100 operativo | **UNPROVEN runtime** |

**Diagnosi:** il produttore è noto, ma il suo ramo è condizionale. Il bit `0x2` non è inizializzato dal Wrangler: arriva dall’esterno. Non ci sono call dirette nei due kext; l’unico caller plausibile è AGDC/AppleGraphicsDeviceControl, il cui eseguibile non è nel root estratto. Quindi **non è possibile stabilire staticamente che MacBookPro16,1 soddisfi il bit `0x2`**. La prova decisiva è un xref AGDC con bit `0x2` o un `ioreg` che mostri `LoadHWServices=true` sul `IOPCIDevice`.

---

## 10. Verdetto

| Domanda | Risposta |
|---|---|
| Caller diretti di `vendor_doDeviceAttribute` | **0** |
| Caller indiretti | **vtable/AGDC, non risolto** |
| Bit `0x2` inizializzato da costruttore/probe/start | **NO** |
| Bit `0x2` fornito dall’esterno | **PROVEN** |
| Target soddisfa bit `0x2` | **UNPROVEN** |
| Prova decisiva disponibile | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute` è raggiunto solo indirettamente; non esistono call dirette nei due kext e il bit `0x2` è un argomento del caller, non un campo inizializzato dal Wrangler. Costruttori, `probe`, `attach` e `start` non lo impostano. `AmdAgdcServices` è un dispatcher, ma non chiama direttamente il metodo; `AppleGraphicsDeviceControl` non ha eseguibile nel root estratto. Pertanto non è dimostrato che il target passi `flags & 0x2`, e non è dimostrato che `LoadHWServices` venga scritto. La prova decisiva mancante è il caller AGDC con il bit `0x2` o un `ioreg` archiviato. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **15.413.964 KiB ≈ 14,70 GiB** > 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
