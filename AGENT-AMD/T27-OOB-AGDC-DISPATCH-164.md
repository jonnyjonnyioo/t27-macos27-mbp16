# T27 — AGENT-AMD — AGDC DISPATCH (164)

**Scope:** ricostruire il percorso AGDC che invoca virtualmente `vendor_doDeviceAttribute` e determina `flags & 0x2`; individuare `AppleGraphicsDeviceControl` in SystemKC, BootKC e componenti estratti; ricostruire dispatcher, chiamate virtuali, vtable e argomenti; analizzare `AmdAgdcServices` e interfacce AGDC; cercare la costruzione di `rdx/rbx`; verificare percorsi alternativi per `LoadHWServices=true`; identificare caller e condizioni del bit `0x2`.

**Modalità:** sola lettura. Nessun boot, trace, modifica, build o download. Comandi: `nm`, `otool`, `strings`, `grep`, `find`, `plutil`, `shasum`.

**Esito:** **PROVEN** che `AppleGraphicsDeviceControl` in SystemKC compare solo come simbolo **importato/undefined**, non come implementazione; BootKC non lo contiene; il bundle `AppleGraphicsDeviceControl.kext` nel root ha solo `Info.plist`/`version.plist`, senza eseguibile. **PROVEN** che il dispatcher `AmdAgdcServices` non chiama direttamente il Wrangler e che il puntatore alla funzione è in una tabella indiretta. **UNPROVEN** il caller AGDC effettivo e la valorizzazione di `flags & 0x2`. **PROVEN** che non esistono altri setter di `LoadHWServices` oltre ai due Wrangler. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| AppleGraphicsDeviceControl `Info.plist` | `d521d429dbf95570ec5f6469d1286a846d30739be75e2fe1e1af6244431a5188` |
| X6000Framebuffer executable | `a2469429602210e64a74292a30b06353d9e0f75cd6b8b65f98324e64fa0b4536` |
| X6000Framebuffer `Info.plist` | `1b28b9aab877c4b3362edabde5a512d45d0cf97c10611b034c8ea53995a9f573` |
| AMDSupport executable | `c569698b689d3822ce3f18a51202b10f46f48e395e80a339dc3bae403754f2a4` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 163 | `dca7d39ebbc7fc169783c67ab6c8e630e8fa25f694349d1104f0f3bd222a1467` |

**Ambiente:** macOS `26.7.3`, build `25G342`.
**Spazio:** **15.409.900 KiB ≈ 14,70 GiB** > 10 GiB.

---

## 2. Presenza di AppleGraphicsDeviceControl

### 2.1 SystemKC

`nm -arch x86_64 -n SystemKC | grep AppleGraphicsDeviceControl`:

| Simbolo | Tipo |
|---|---|
| `AppleGraphicsDeviceControl::newUserClient` | **U** |
| `AppleGraphicsDeviceControl::vendor_doDeviceAttribute` | **U** |
| `AppleGraphicsDeviceControl::setDeviceAttribute` | **U** |
| `AppleGraphicsDeviceControl::start` | **U** |
| `AppleGraphicsDeviceControl::stop` | **U** |
| `AppleGraphicsDeviceControl::message` | **U** |
| `AppleGraphicsDeviceControl::gMetaClass` | **U** |
| `AppleGraphicsDeviceControl` vtable | **U** |
| `_RESERVEDAppleGraphicsDeviceControl0…7` | **U** |

**PROVEN:** i simboli sono **undefined** in SystemKC.
**PROVEN:** SystemKC contiene riferimenti/import, non il corpo delle funzioni.
**UNPROVEN:** dove risieda l’implementazione nel sistema live.

### 2.2 BootKC

| Ricerca | Esito |
|---|---|
| simboli `AppleGraphicsDeviceControl` | **0** |
| stringhe `AppleGraphicsDeviceControl` | **0** |

**PROVEN:** BootKC non contiene la classe.

### 2.3 Bundle estratto

`/System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDeviceControl.kext`:

| File | Stato |
|---|---|
| `Contents/Info.plist` | presente |
| `Contents/version.plist` | presente |
| `Contents/_CodeSignature/CodeResources` | presente |
| `Contents/MacOS/AppleGraphicsDeviceControl` | **assente** |
| `Contents/MacOS/` | **assente** |

**PROVEN:** il bundle non contiene l’eseguibile dichiarato da `CFBundleExecutable`.
**PROVEN:** `Info.plist` ha `IOKitPersonalities` vuoto e `OSBundleRequired=Safe Boot`.
**INFERRED:** il codice è in una kernel collection o in un componente non estratto.
**UNPROVEN:** l’implementazione live.

---

## 3. Dispatcher AGDC

### 3.1 `AmdAgdcServices::vendor_doDeviceAttribute`

`AMDRadeonX6000_AmdAgdcServices::vendor_doDeviceAttribute` a `0xbf73668`:

| Elemento | Evidenza |
|---|---|
| input comando | `validateCommand` `0xbf74378`, `allowHwCommand` `0xbf743ba` |
| input esterni | `IOExternalMethodArguments` |
| tabella comandi | range `0x700`–`0x974` |
| call dirette a Wrangler | **0** |
| call indirette | slot virtuali; non risolte |

**PROVEN:** è un dispatcher di comandi AGDC.
**PROVEN:** non chiama direttamente `AmdGpuWrangler::vendor_doDeviceAttribute`.
**UNPROVEN:** il comando che porta il bit `0x2`.

### 3.2 Tabella del Wrangler

Il puntatore a `AmdGpuWrangler::vendor_doDeviceAttribute` `0xbf9894e` compare a:

| Elemento | Valore |
|---|---:|
| file offset | `3221960` |
| VA `__DATA_CONST` | `0xc26e9c8` |
| tipo | puntatore in tabella |
| call dirette nel binario | **0** |

**PROVEN:** la funzione è esposta per dispatch indiretto.
**PROVEN:** non esiste una `callq 0xbf9894e` nel binario.
**UNPROVEN:** il proprietario della tabella e il chiamante.

---

## 4. Costruzione di `rdx/rbx`

`AmdGpuWrangler::vendor_doDeviceAttribute`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0xbf9895f` | `movq %rdx, %rbx` | salva argomento `rdx` |
| `0xbf98a1c` | `movl (%rbx), %eax` | legge bitmask |
| `0xbf98a1e` | `testb $0x2, %al` | test bit `0x2` |
| `0xbf98a20` | `je 0xbf98a4d` | salta la scrittura |
| `0xbf98a25` | `leaq "LoadHWServices"` | chiave |
| `0xbf98a34` | `callq *0x278(%rax)` | `setProperty` |

**PROVEN:** il bitmask è letto dal puntatore `rdx`.
**PROVEN:** la funzione non lo inizializza.
**PROVEN:** il bit `0x2` è un input del caller.

### 4.1 Metodi IOService

| Metodo | Inizializza flags? | Chiama vendor? |
|---|---|---|
| costruttore C1/C2 `0xbf9854e/0xbf9857e` | **NO** | **NO** |
| `probe 0xbf985ae` | **NO** | **NO** |
| `attach 0xbf986d2` | **NO** | **NO** |
| `start 0xbf987c2` | **NO** | **NO** |

**PROVEN:** il bit `0x2` non nasce nel ciclo di vita IOService.
**PROVEN:** `start` pubblica solo `AMDRadeonLoadSvcMgr` e chiama `registerService(0)`.

---

## 5. Percorsi alternativi per LoadHWServices

| Immagine | Xref `setProperty("LoadHWServices")` | Stato |
|---|---|---|
| X6000Framebuffer | `0xbf98a25` | **PROVEN** |
| AMDSupport | `0x13b84611` | **PROVEN** |
| HWServices | **0** | **REFUTED** |
| BootKC | **0** | **REFUTED** |
| SystemKC XML | 3 personality | solo dichiarazioni |
| AppleGraphicsDeviceControl | **non disponibile** | **UNPROVEN** |

**PROVEN:** non ci sono altri setter noti.
**PROVEN:** i due Wrangler usano lo stesso bit `0x2`.
**UNPROVEN:** un setter AGDC alternativo.

---

## 6. Target MacBookPro16,1

| Condizione | Evidenza | Esito |
|---|---|---|
| GPU Navi 14 `0x73401002` | `IOPCIMatch` | **PROVEN metadati** |
| classe `AmdGpuWrangler` | SystemKC | **PROVEN** |
| `flags & 0x2` dal caller | nessun caller disponibile | **UNPROVEN** |
| `LoadHWServices=true` sul PCI | nessun ioreg | **UNPROVEN** |
| HWServices caricato | runtime | **UNPROVEN** |

**PROVEN:** il target ha il potenziale per il percorso.
**UNPROVEN:** che il caller passi il bit `0x2`.
**UNPROVEN:** che `LoadHWServices` venga scritto.

---

## 7. Prova decisiva mancante

| Prova | Disponibilità |
|---|---|
| corpo di `AppleGraphicsDeviceControl::vendor_doDeviceAttribute` | **assente** |
| tabella/vtable AGDC con argomenti | **non risolta** |
| caller che valorizza `rdx` con bit `0x2` | **assente** |
| `ioreg` con `LoadHWServices=true` | **assente** |

**PROVEN:** nessuna prova decisiva è nei file attuali.
**PROVEN:** il limite è l’assenza dell’implementazione AGDC, non il Wrangler.
**UNPROVEN:** la condizione target.

---

## 8. Diagnosi

| Priorità | Elemento | Stato |
|---:|---|---|
| 1 | Caller AGDC e bit `0x2` | **UNPROVEN** |
| 2 | `setProperty("LoadHWServices")` effettivo | **PROVEN codice; runtime UNPROVEN** |
| 3 | HWServices match | **PROVEN metadati; runtime UNPROVEN** |
| 4 | `Load6100` e X6100 | **PROVEN statico** |
| 5 | X6100 operativo | **UNPROVEN runtime** |

**Diagnosi:** il dispatcher AGDC è presente come interfaccia, ma il suo corpo e il caller non sono nel root estratto; `AppleGraphicsDeviceControl` è solo un import in SystemKC e un bundle senza eseguibile. Non è possibile stabilire staticamente se il target passi `flags & 0x2`. L’unica prova decisiva è il codice AGDC mancante o un `ioreg`/trace archiviato.

---

## 9. Verdetto

| Domanda | Risposta |
|---|---|
| AppleGraphicsDeviceControl in SystemKC | **solo U/import** |
| In BootKC | **NO** |
| Eseguibile nel bundle | **NO** |
| Caller diretto del Wrangler | **NO** |
| Bit `0x2` inizializzato dal Wrangler | **NO** |
| Setter alternativi | **NO noti** |
| Target soddisfa bit `0x2` | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il percorso AGDC non è ricostruibile staticamente con i file disponibili. `AppleGraphicsDeviceControl` compare in SystemKC solo come simbolo importato, non è in BootKC e il bundle non contiene l’eseguibile. `AmdAgdcServices` è un dispatcher ma non chiama direttamente il Wrangler; il puntatore alla funzione è in una tabella indiretta e il bit `0x2` è un argomento `rdx` non inizializzato dal Wrangler. Non esistono altri setter di `LoadHWServices`. La condizione del target resta **UNPROVEN**; la prova decisiva è l’implementazione AGDC o un `ioreg` archiviato. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **15.409.900 KiB ≈ 14,70 GiB** > 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
