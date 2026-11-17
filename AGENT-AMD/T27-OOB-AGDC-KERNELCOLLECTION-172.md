# T27 — AGENT-AMD — CALL SITE 73 IMMAGINI / TARGET KERNEL COLLECTION (172)

**Scope:** analizzare staticamente le 73 immagini della dyld shared cache x86_64h che importano `IOConnectCallMethod`; ricostruire call site, selettore, scalar input e structure input; cercare il comando 3 e il buffer di 4 byte senza dipendere solo dalle stringhe; verificare client AMD/Apple indiretti; aggiornare la fattibilità del compatibility layer; identificare il prossimo ostacolo concretamente risolvibile.

**Modalità:** sola lettura. Nessun boot, trace, modifica ai file di sistema, build o download. Solo estrazione in `HAO-PROJECT/T27/AGENT-AMD/.tmp/a73/` e analisi con `ipsw dyld extract`, `otool`, `nm`, `llvm-objdump`, `strings`, `dyld_info`, `shasum`, `sha256sum`.

**Esito sintetico:** **PROVEN** che tutte le 73 immagini sono state estratte; **22** contengono call site IOKit diretti, **51** hanno solo l’import o nessun call site diretto osservato. **PROVEN** che ci sono **7** call site `IOConnectCallMethod` con selettore immediato 3, ma nessuno ha struttura input di 4 byte: sono `IOFramebuffer`, `IOAudio`, `IOAccelerator`, `IOMobileFramebuffer` e `IOReport`. **PROVEN** che nessuna delle 73 immagini, oltre ai tre client già noti, contiene il letterale `AppleGraphicsDeviceControl`; nessun client AGDC con selettore 3 è emerso. **PROVEN** che il target 25G342 contiene il **codice definito** di `AppleGraphicsDeviceControl` e di `AMDRadeonX6000_AmdGpuWrangler` in `SystemKernelExtensions.kc`, nonostante il bundle AGDC non abbia un eseguibile standalone: il blocker “AGDC assente” va corretto in “AGDC presente nella kernel collection, disponibilità runtime UNPROVEN”. **UNPROVEN** il produttore userspace del bit `0x2` e l’avvio effettivo del servizio. T27 resta **OPEN**: **94% engineering / 32% first boot / 8% desktop**.

---

## 1. Ambiente e SHA-256

| Artefatto | SHA-256 |
|---|---|
| Report 171 | `a9d1e2972cc66d9d1e405ff6b8399e05f9ebbfca621203f27170a6cfb3540098` |
| Target `SystemKernelExtensions.kc` 25G342 | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| `PowerlogLiteOperators` target | `6e3bcdc986f89c550e73e22802b273ba4528b95df4c2fda56204521917ec58c8` |
| AGDC root2 26.7.2/25G325 | `a3effd46c2c22692019da818ecab43703b44bcb5e2357c174d1b1546fcc633a3` |
| AGDC `Info.plist` root2/target | `d521d429dbf95570ec5f6469d1286a846d30739be75e2fe1e1af6244431a5188` |
| AGDC KDK 27.2/26B116 | `ea39241b0c99dae2fb4dd81a33af0b36e1c0ffd1ad04283140ea51555486a1d7` |

**Target osservato:** macOS `26.7.3`, build `25G342`.
**Cache:** `/System<VOLUME>/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_x86_64h`.
**Kernel collection:** `/System/Library/KernelCollections/SystemKernelExtensions.kc`, Mach-O x86_64, 352 MB.
**Spazio:** **14.124.612 KiB ≈ 13,47 GiB** liberi; sopra 10 GiB.
**AGDC bundle:** `Contents/MacOS` assente; `Info.plist` 8.1.12 presente.
**SystemKC:** contiene metadati e simboli definiti AGDC; dettaglio in §5.

---

## 2. Estrazione e copertura delle 73 immagini

### 2.1 Metodo

```sh
ipsw dyld extract \
  /System<VOLUME>/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_x86_64h \
  "<path>" -o .tmp/a73 --stubs --force
```

Tutte le 73 immagini sono state estratte in `.tmp/a73/` con nome indicizzato (`01_…`–`73_…`). Sono state analizzate con `otool -tV` e con uno scanner che registra le ultime scritture immediate nei registri SysV (`%esi`, `%ecx`, `%r9`) prima di ogni chiamata IOKit.

**PROVEN:** 73/73 immagini estratte; 155 MB totali.
**PROVEN:** 6 estrazioni hanno emesso un warning `LC_DYLD_CHAINED_FIXUPS` (`libFDR`, due driver Intel GL, `H16ISP`, `libramrod`, `libPS190Updater`); i file esistono e sono Mach-O.
**PROVEN:** la scansione diretta ha trovato **665 call site IOKit** in **22 immagini**.
**PROVEN:** 51 immagini non hanno mostrato un call site diretto con symbol stub; l’import può essere inutilizzato o risolto via GOT/indirettamente.
**UNPROVEN:** che le 51 immagini senza call site diretto non chiamino IOKit attraverso un puntatore GOT non risolto.

### 2.2 Conteggio per simbolo

| Simbolo | Call site |
|---|---:|
| `_IOConnectCallMethod` | **361** |
| `_IOConnectCallScalarMethod` | **166** |
| `_IOConnectCallStructMethod` | **117** |
| `_IOConnectCallAsyncMethod` | **13** |
| `_IOConnectCallAsyncScalarMethod` | **8** |
| **Totale** | **665** |

**PROVEN:** `IOConnectCallMethod` è il metodo più usato, ma la maggior parte dei call site non ha selettore 3.
**PROVEN:** il simbolo `_IOConnectCallMethod` è presente in 73 immagini; la presenza dell’import non implica un uso effettivo.
**UNPROVEN:** i call site raggiunti solo tramite GOT o stub non risolti.

### 2.3 Immagini con call site diretti

| Immagine | Call site |
|---|---:|
| `17_DiskManagement` | 159 |
| `06_IOMobileFramebuffer` | 77 |
| `05_IOAccelerator` | 68 |
| `21_ANEServices` | 52 |
| `04_IOSurface` | 47 |
| `02_CoreAudio` | 47 |
| `01_CoreDisplay` | 46 |
| `16_IOUSBHost` | 40 |
| `15_libEndpointSecurity.dylib` | 34 |
| `11_IOPresentment` | 31 |
| `19_libcsfde.dylib` | 16 |
| `18_CoreAUC` | 8 |
| `09_libCoreStorage.dylib` | 8 |
| `20_GameController` | 5 |
| `12_GPUWrangler` | 5 |
| `13_IOBluetooth` | 4 |
| `07_MobileKeyBag` | 4 |
| `10_CoreBrightness` | 3 |
| `08_libIOReport.dylib` | 3 |
| `14_ProtectedCloudStorage` | 3 |
| `03_libMobileGestalt.dylib` | 3 |
| `22_DeviceCheckInternal` | 2 |

**PROVEN:** 22 immagini compaiono nella tabella dei call site diretti; il file di intestazione della scansione non è un’immagine.
**PROVEN:** `PowerlogLiteOperators` non ha call site IOKit diretti nel ramo AGDC; `GPUWrangler` ne ha 5, tutti sul servizio `AppleGPUWrangler`.
**PROVEN:** nessuna delle 22 immagini è un client AGDC con selettore 3.

---

## 3. Selettore 3: tutti i call site trovati

### 3.1 `IOConnectCallMethod` con selettore 3

| Immagine | Call address | Selettore | Scalar input | Structure input | Contesto |
|---|---:|---:|---:|---:|---|
| `CoreDisplay` | `0x7ff805365763` | 3 | 2 | 0 | `IOFBSetStartupDisplayModeAndDepth`; `IOFramebuffer` |
| `CoreAudio` | `0x7ff805b60ca9` | 3 | 0 | 0x20 | `HALS_IOA2UCDevice::PerformConfigChange`; IOAudio2 |
| `CoreAudio` | `0x7ff805e2a659` | 3 | 0 | 0 | `HALS_IOA1UCEngine::StartIO`; IOAudio1 |
| `IOAccelerator` | `0x7ff80f46e442` | 3 | 2 | 0 | `IOAccelResource` |
| `IOAccelerator` | `0x7ff80f46ea9e` | 3 | 1 | 0 | `IOAccelDevice` |
| `IOMobileFramebuffer` | `0x7ff811cdc265` | 3 | 1 | 0 | `IOMobileFramebuffer` |
| `libIOReport.dylib` | `0x7ff814795cbd` | 3 | 1 | 0 | `IOReportHub` / `__updateKernelBuffer` |

**PROVEN:** sette call site `IOConnectCallMethod` con selettore 3.
**PROVEN:** nessuno ha structure input di 4 byte; gli unici structure input non nulli sono 0x20 (CoreAudio) e 0 (gli altri).
**PROVEN:** i servizi sono `IOFramebuffer`, `IOAudio1/2`, `IOAccelerator`, `IOMobileFramebuffer`, `IOReportHub`; nessuno è AGDC.
**UNPROVEN:** un eventuale selettore 3 calcolato a runtime in un registro non immediato.

### 3.2 `IOConnectCallStructMethod` con selettore 3

| Immagine | Call address | Structure size | Contesto |
|---|---:|---:|---|
| `IOAccelerator` | `0x7ff80f46ebaf` | 8 | IOAccelerator |
| `IOMobileFramebuffer` | `0x7ff811cd29fe` | non determinato | IOMobileFramebuffer |
| `libEndpointSecurity.dylib` | `0x7ff81b97ad7d` | non determinato | EndpointSecurity |
| `DiskManagement` | `0x7ff81cd5c20c` | 64 | DiskManagement |
| `ANEServices` | `0x7ff821a709b1` | 32 | ANEServices |

**PROVEN:** cinque call site `IOConnectCallStructMethod` con selettore 3; nessuno ha structure input 4 byte.
**PROVEN:** `IOConnectCallStructMethod` non fornisce lo scalar input richiesto da AGDC `externalMethod`; da solo non può essere il client AGDC del comando 3.

### 3.3 `IOConnectCallScalarMethod` con selettore 3

| Immagine | Call address | Scalar input | Contesto |
|---|---:|---:|---|
| `CoreDisplay` | `0x7ff8053577c6` | 2 | AGC/mux; `AppleGraphicsControl` |
| `CoreDisplay` | `0x7ff805357b12` | 2 | AGC/mux |
| `libMobileGestalt.dylib` | `0x7ff80915b384` | 1 | MobileGestalt |
| `IOAccelerator` | `0x7ff80f470092` | 2 | IOAccelerator |
| `IOMobileFramebuffer` | `0x7ff811cd8497` | 2 | IOMobileFramebuffer |
| `IOUSBHost` | `0x7ff81bab0cf7` | 1 | IOUSBHost |
| `ANEServices` | `0x7ff821a73112` | non determinato | ANEServices |
| `ANEServices` | `0x7ff821a7317a` | non determinato | ANEServices |

**PROVEN:** otto call site scalar con selettore 3; il primo è il noto AGC/mux di CoreDisplay.
**PROVEN:** nessuno è AGDC; nessuno ha structure input.

### 3.4 Call site con structure input 4

| Immagine | Call address | Selettore | Contesto |
|---|---:|---:|---|
| `IOAccelerator` | `0x7ff80f46fa19` | 4 | IOAccelerator |
| `IOPresentment` | `0x7ff815988033` | valore del parser non affidabile | query AGDC, non comando 3 |
| `IOPresentment` | `0x7ff815988805` | valore del parser non affidabile | query AGDC, non comando 3 |
| `GPUWrangler` | `0x7ff8159a2dab` | valore del parser non affidabile | AppleGPUWrangler |
| `libcsfde.dylib` | `0x7ff82010ae95` | 31 | CoreStorage |

**PROVEN:** nessun call site con selettore 3 e structure input 4.
**INFERRED:** i valori “non affidabili” di IOPresentment/GPUWrangler sono falsi positivi dello scanner: la finestra di 45 istruzioni ha catturato registri di chiamate precedenti; i call site AGDC noti usano selettori 1/0x980 e non hanno input.
**UNPROVEN:** una forma indiretta con selettore calcolato e structure input 4 in una delle 51 immagini senza call site diretto.

---

## 4. Ricerca del servizio e dei client indiretti

### 4.1 Letterali nelle 73 immagini

| Stringa esatta | Immagini |
|---|---|
| `AppleGraphicsDeviceControl` | **CoreDisplay**, **IOPresentment**, **PowerlogLiteOperators** |
| `AppleGraphicsControl` | **CoreDisplay**, **PowerlogLiteOperators** |
| `AppleGPUWrangler` | **IOPresentment**, **GPUWrangler** |
| `AGDC` | **CoreDisplay**, **IOPresentment**, **PowerlogLiteOperators** |

**PROVEN:** nessun quarto client con il letterale AGDC.
**PROVEN:** i driver AMD/Intel, `IOAccelerator`, `IOGPU`, `IOMobileFramebuffer`, `SkyLight` e `Virtualization` non contengono il letterale AGDC.
**UNPROVEN:** un nome costruito dinamicamente o una chiamata indiretta a un servizio intermedio.

### 4.2 Client AMD/Apple indiretti

| Candidato | Import `IOConnectCallMethod` | Call site AGDC | Esito |
|---|---|---|---|
| `AMDRadeonX6000MTLDriver` | **SÌ** | **NO** | nessun letterale AGDC; nessun call site diretto osservato |
| `AMDMTLBronzeDriver` | **SÌ** | **NO** | idem |
| `AMDRadeonX5000MTLDriver` | **SÌ** | **NO** | idem |
| `AMDRadeonVADriver` / `2` | **SÌ** | **NO** | idem |
| `AppleIntelKBL/ICL MTL/GL` | **SÌ** | **NO** | idem; 2 estrazioni con warning fixup |
| `IOAccelerator` | **SÌ** | **NO** | selettore 3 per IOAccelerator, non AGDC |
| `IOMobileFramebuffer` | **SÌ** | **NO** | selettore 3 per IOMobileFramebuffer |
| `IOGPU` | **SÌ** | **NO** | nessun letterale AGDC, call site non osservato |
| `Virtualization` | **SÌ** | **NO** | “GraphicsDevices” è un falso positivo testuale |
| `GPUWrangler` | **SÌ** | **NO** | `AppleGPUWrangler`, comandi 2/0xb |

**PROVEN:** i driver AMD/Intel non contengono il servizio AGDC e non hanno un call site AGDC.
**INFERRED:** gli import `IOConnectCallMethod` nei driver sono per i rispettivi servizi acceleratore/framebuffer, non per AGDC.
**UNPROVEN:** un percorso GOT non risolto o un nome dinamico.

### 4.3 Perché non è un client AGDC

| Requisito AGDC | CoreDisplay | IOPresentment | Powerlog | IOAccelerator | IOMobileFB | IOReport |
|---|---|---|---|---|---|---|
| Letterale AGDC | **SÌ** | **SÌ** | **SÌ** | NO | NO | NO |
| Apre AGDC | **SÌ** | **SÌ** | **SÌ** | NO | NO | NO |
| `IOConnectCallMethod` | **SÌ** | **SÌ** | **NO** | **SÌ** | **SÌ** | **SÌ** |
| Selettore 3 AGDC | **NO** | **NO** | **NO** | **NO** | **NO** | **NO** |
| Structure input 4 | **NO** | **NO** | **NO** | **NO** | **NO** | **NO** |
| Bit `0x2` | **NO** | **NO** | **NO** | **NO** | **NO** | **NO** |

**PROVEN:** nessuna riga soddisfa la firma AGDC del comando 3.
**PROVEN:** i call site con selettore 3 sono di altri servizi.
**UNPROVEN:** il client AGDC che invia il comando 3.

---

## 5. Correzione importante: AGDC è nel target SystemKC

### 5.1 Simboli definiti

`nm -m /System/Library/KernelCollections/SystemKernelExtensions.kc` elenca, sotto `Symbols for com.apple.AppleGraphicsDeviceControl`, simboli **definiti** in `__TEXT,__text`:

| Simbolo target | Indirizzo |
|---|---:|
| `AppleGraphicsDeviceControl::newUserClient(task*, void*, unsigned int, OSDictionary*, IOUserClient**)` | `0x13d41cbe` |
| `AppleGraphicsDeviceControl::UserKernelTransfer(unsigned int, AGDCClientState_t*)` | **`0x13d41e60`** |
| `AppleGraphicsDeviceControl::filtered_doDeviceAttribute(agdc_filtered_api_t, unsigned int, unsigned long, unsigned long, ...)` | **`0x13d407b0`** |
| `AppleGraphicsDeviceControl::vendor_doDeviceAttribute(unsigned int, unsigned long, unsigned long, ...)` | `0x13d41c34` |
| `AppleGraphicsDeviceControl::setDeviceAttribute(unsigned int, unsigned long, unsigned long)` | `0x13d41bdc` |
| `AppleGraphicsDeviceControl::getDeviceAttribute(unsigned int, unsigned long*, unsigned long*)` | `0x13d4078e` |
| `AppleGraphicsDeviceControl::publishHdaGfxProperties()` | `0x13d40150` |

**PROVEN:** il target 25G342 contiene il codice AGDC nella kernel collection, non solo il plist.
**PROVEN:** `UserKernelTransfer` e `filtered_doDeviceAttribute` sono presenti come funzioni definite.
**PROVEN:** il bundle `AppleGraphicsDeviceControl.kext` non ha un eseguibile standalone; il codice è nella kernel collection.
**UNPROVEN:** che il servizio venga registrato e avviato a runtime; la sola presenza statica non lo dimostra.

### 5.2 Wrangler AMD definito

`nm -m` elenca anche:

| Simbolo target | Indirizzo |
|---|---:|
| `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute(unsigned int, unsigned long, unsigned long, ..., IOExternalMethodArguments*)` | **`0xbf9894e`** |
| `AMDRadeonX6000_AmdGpuWrangler::start(IOService*)` | `0xbf987c2` |
| `AMDRadeonX6000_AmdGpuWrangler::probe(IOService*, int*)` | `0xbf985ae` |

**PROVEN:** il Wrangler AMD è definito nella stessa kernel collection.
**PROVEN:** l’indirizzo `0xbf9894e` coincide con quello già osservato in root2; è lo stesso punto di ingresso `vendor_doDeviceAttribute`.
**INFERRED:** il codice target è lo stesso o strettamente imparentato con root2; la coincidenza di indirizzo è forte, ma non è un confronto byte-per-byte.
**UNPROVEN:** che il callback `0x858` di AGDC punti a questo Wrangler sul target.

### 5.3 Metadati `LoadHWServices`

`strings -a -t x` su `SystemKernelExtensions.kc` trova:

```text
<key>com.apple.AppleGraphicsDeviceControl</key>
<key>LoadHWServices</key>
<string>AMDRadeonX6000_AmdGpuWrangler</string>
```

**PROVEN:** la kernel collection contiene i metadati del kext AGDC, la chiave `LoadHWServices` e il nome del Wrangler AMD.
**PROVEN:** `BootKernelExtensions.kc` non contiene queste stringhe.
**UNPROVEN:** il valore runtime di `LoadHWServices` e l’ordine di caricamento.

### 5.4 Correzione al report 170

Il report 170 concludeva “eseguibile AGDC assente”; il dato resta vero per il **bundle**, ma è incompleto per il **target**:

| Affermazione | Stato corretto |
|---|---|
| AGDC bundle senza eseguibile | **PROVEN** |
| AGDC assente dal target | **FALSO / corretto** |
| AGDC definito in `SystemKernelExtensions.kc` | **PROVEN** |
| AGDC avviato a runtime | **UNPROVEN** |
| Wrangler AMD definito in SystemKC | **PROVEN** |
| Callback AGDC → Wrangler | **UNPROVEN** |

**PROVEN:** la mancanza del file `Contents/MacOS/AppleGraphicsDeviceControl` non implica l’assenza del servizio.
**PROVEN:** il target contiene le funzioni AGDC e AMD necessarie.
**UNPROVEN:** la disponibilità runtime e l’autorizzazione del client.

---

## 6. Produttore del bit `0x2`: stato dopo le 73 immagini

| Candidato | Scrittura `0x2` | Evidenza |
|---|---|---|
| CoreDisplay | **NO** | policy 8 byte; AGC scalar |
| IOPresentment | **NO** | query 1/0x980 |
| Powerlog | **NO** | solo open/release |
| GPUWrangler | **NO** | comandi 2/0xb |
| IOAccelerator | **NO** | selettore 3 scalar, non AGDC |
| IOMobileFramebuffer | **NO** | selettore 3 scalar, non AGDC |
| IOReport | **NO** | selettore 3 scalar, non AGDC |
| CoreAudio | **NO** | selettore 3 IOAudio |
| Driver AMD/Intel | **NO** | nessun letterale AGDC |
| AGDC kernel | **trasporta** | non crea il bit |
| AmdGpuWrangler | **consuma** | test `0x2` |
| `LoadHWServices` userspace | **0 occorrenze** | non nella cache |

**PROVEN:** nessuno dei call site userspace esaminati scrive `0x2` in un buffer AGDC.
**PROVEN:** AGDC trasporta il buffer; il Wrangler lo consuma.
**UNPROVEN:** il processo, l’istruzione e il valore runtime che impostano `0x2`.

### 6.1 Cosa manca ancora

| Prova | Stato |
|---|---|
| Call site AGDC con selettore 3 | **nessuno nelle 73 immagini** |
| Buffer AGDC 4 byte con `0x2` | **non trovato** |
| Client AMD/Apple indiretto | **nessuno con letterale AGDC** |
| Nome AGDC dinamico | **UNPROVEN** |
| 51 immagini senza call site diretto | **UNPROVEN per GOT/indiretto** |
| AGDC code nel target SystemKC | **PROVEN** |
| AGDC runtime | **UNPROVEN** |

---

## 7. Compatibility layer: aggiornamento

### 7.1 Cosa cambia con SystemKC

| Componente | Prima (report 171) | Ora (report 172) |
|---|---|---|
| Codice AGDC target | **assente dal bundle** | **PROVEN in SystemKC** |
| Wrangler AMD target | **presunto da root2** | **PROVEN in SystemKC** |
| Servizio AGDC runtime | **UNPROVEN** | **UNPROVEN** |
| Callback AGDC → Wrangler | **UNPROVEN** | **UNPROVEN** |
| Client userspace comando 3 | **UNPROVEN** | **UNPROVEN; nessuno nelle 73** |
| Entitlement | **stringa root2** | **da verificare nel target** |

**PROVEN:** il compatibility layer non deve ricreare il codice AGDC: il target lo contiene già.
**PROVEN:** non serve un kext AGDC sostitutivo per il solo codice; servono servizio attivo, autorizzazione e client.
**UNPROVEN:** che il servizio sia attivo e che il client possa ottenere l’entitlement.

### 7.2 Opzioni aggiornate

#### A — Client-only harness

| Requisito | Stato |
|---|---|
| AGDC code presente | **PROVEN in SystemKC** |
| AGDC service registrato/avviato | **UNPROVEN** |
| Entitlement AGDC/GPU | **UNPROVEN runtime** |
| Callback Wrangler | **UNPROVEN** |
| Buffer 4 byte `{0x2}` | **UNPROVEN** |
| Effetto `LoadHWServices` | **UNPROVEN** |

**Fattibilità:** **condizionata**, ma non più bloccata dall’assenza del codice AGDC. Il passo successivo è verificare l’avvio del servizio e l’autorizzazione, non riscrivere AGDC.

#### B — Riuso di CoreDisplay/IOPresentment

| Requisito | Stato |
|---|---|
| Inviano il comando 3 | **NO — PROVEN** |
| API per il comando 3 | **assente** |
| Effetto `0x2` | **NO** |

**Fattibilità:** **non applicabile**.

#### C — Sostituzione kernel AGDC/Wrangler

| Requisito | Stato |
|---|---|
| Codice già nel target | **PROVEN** |
| Firma/SIP | **BLOCKED** |
| Reimplementazione | **non necessaria** |
| Rischio | **alto** |

**Fattibilità:** **bloccata e non necessaria**. Il codice esiste; il problema è l’attivazione e l’interfaccia, non la sostituzione.

#### D — Uso del SystemKC target

**PROVEN:** è la fonte corretta per l’ABI AGDC target.
**PROVEN:** contiene `UserKernelTransfer`, `filtered`, `vendor_doDeviceAttribute` e il Wrangler.
**UNPROVEN:** l’equivalenza byte-per-byte con root2 e il comportamento runtime.

### 7.3 Dipendenze minime aggiornate

1. **Servizio:** verificare che `AppleGraphicsDeviceControl` sia registrato e avviato dal SystemKC.
2. **Autorizzazione:** verificare `com.apple.private.applegraphicsdevicecontrol` / `com.apple.private.gpuwrangler` nel target e `newUserClient`.
3. **ABI:** confrontare `UserKernelTransfer` target `0x13d41e60` con root2; verificare `scalarInputCount=1`, `scalarOutputCount=1`, `structureInput` 4 byte.
4. **Wrangler:** verificare che il callback `0x858` punti a `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute` target `0xbf9894e`.
5. **Effetto:** `LoadHWServices=true`; HWServices/X6100; solo runtime.
6. **Verifica:** ioreg/servizi; non disponibile in sola analisi statica.

**PROVEN:** 1–4 sono ora verificabili staticamente nel target, non più solo in root2.
**UNPROVEN:** 5–6 senza runtime.

### 7.4 Fattibilità finale

| Layer | Fattibilità | Motivo |
|---|---|---|
| Client-only harness | **condizionata** | codice AGDC target presente; servizio/entitlement/runtime non provati |
| Riuso CoreDisplay/IOPresentment | **non applicabile** | non inviano il comando 3 |
| Sostituzione kernel | **bloccata/non necessaria** | codice già presente; firma/SIP |
| SystemKC come base ABI | **raccomandata per analisi statica** | simboli definiti e indirizzi target |

**Risposta netta:** il target non è privo di AGDC: il codice è in `SystemKernelExtensions.kc`. Un compatibility layer **userspace** può quindi essere un client harness del servizio esistente, non un sostituto. Restano da provare registrazione/avvio, entitlement e callback; il produttore userspace del bit `0x2` non è stato trovato.

---

## 8. Prossimo ostacolo concretamente risolvibile

| Priorità | Ostacolo | Come risolverlo staticamente |
|---:|---|---|
| 1 | AGDC è avviato/registrato? | esaminare `start`/`newUserClient` e i metadati del kext in SystemKC |
| 2 | ABI target = root2? | confrontare `UserKernelTransfer` target `0x13d41e60` con root2; stessi offset `0x30/0x38/0x40/0x68` |
| 3 | Callback `0x858` → Wrangler? | risolvere il puntatore nel codice AGDC target e confrontarlo con `0xbf9894e` |
| 4 | Entitlement target | cercare le stringhe `com.apple.private...` nel SystemKC e in `newUserClient` |
| 5 | Client userspace | nessun call site AGDC 3 nelle 73; cercare solo dopo 1–4 |

**PROVEN:** il prossimo passo non è cercare un altro client nella cache: è verificare l’**attivazione del servizio AGDC target** e l’**ABI** nel SystemKC.
**PROVEN:** questo è un problema statico, risolvibile con `nm`, `otool` e confronto degli offset.
**UNPROVEN:** il risultato runtime.

---

## 9. Stato delle prove

| Prova | Stato |
|---|---|
| 73 immagini estratte | **PROVEN** |
| 22 immagini con call site IOKit | **PROVEN** |
| 665 call site IOKit | **PROVEN** |
| 7 call site Method con selettore 3 | **PROVEN** |
| Nessun Method 3 con structure 4 | **PROVEN nei call site osservati** |
| Nessun client AGDC 3 nelle 73 | **PROVEN per i call site diretti** |
| Quarto client con letterale AGDC | **NO — PROVEN** |
| AGDC definito in target SystemKC | **PROVEN** |
| Wrangler AMD definito in target SystemKC | **PROVEN** |
| AGDC bundle senza eseguibile | **PROVEN** |
| AGDC runtime | **UNPROVEN** |
| Callback AGDC → Wrangler | **UNPROVEN** |
| Produttore userspace `0x2` | **UNPROVEN** |
| 51 immagini senza call site diretto | **UNPROVEN per GOT/indirezione** |

---

## 10. Diagnosi

| Priorità | Elemento | Stato |
|---:|---|---|
| 1 | Audit delle 73 immagini | **completato; 22 con call site** |
| 2 | Selettore 3 con structure 4 | **nessuno** |
| 3 | Client AGDC userspace del comando 3 | **nessuno trovato** |
| 4 | AGDC nel target | **PROVEN in SystemKC** |
| 5 | Wrangler AMD nel target | **PROVEN in SystemKC** |
| 6 | Servizio AGDC runtime | **UNPROVEN** |
| 7 | Entitlement/ABI target | **da verificare staticamente** |
| 8 | Produttore `0x2` | **UNPROVEN** |

**Diagnosi:** l’audit delle 73 immagini non aggiunge un client AGDC con selettore 3. I sette call site con selettore 3 appartengono a IOFramebuffer, IOAudio, IOAccelerator, IOMobileFramebuffer e IOReport; nessuno ha structure input 4 byte. Il dato nuovo e più importante è nel kernel: il target 25G342 contiene il codice AGDC e il Wrangler AMD in `SystemKernelExtensions.kc`; il bundle senza eseguibile non significa servizio assente. Il compatibility layer deve quindi provare l’attivazione del servizio e l’ABI, non ricreare AGDC.

---

## 11. Verdetto

| Domanda | Risposta |
|---|---|
| 73 immagini analizzate | **SÌ — estratte tutte** |
| Immagini con call site IOKit diretti | **22** |
| Call site IOKit totali | **665** |
| Method selector 3 | **7** |
| Method selector 3 + structure 4 | **0** |
| Client AGDC selector 3 | **nessuno trovato** |
| AGDC nel target | **SÌ — SystemKC, PROVEN** |
| Wrangler AMD nel target | **SÌ — SystemKC, PROVEN** |
| AGDC bundle eseguibile | **NO — PROVEN** |
| AGDC runtime | **UNPROVEN** |
| Produttore `0x2` | **UNPROVEN** |
| Compatibility layer client-only | **condizionato, non bloccato dal codice AGDC** |
| Sostituzione kernel | **bloccata/non necessaria** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** tutte le 73 immagini sono state estratte; 22 hanno call site IOKit diretti e 665 chiamate. I sette `IOConnectCallMethod` con selettore 3 sono per `IOFramebuffer`, `IOAudio`, `IOAccelerator`, `IOMobileFramebuffer` e `IOReport`; nessuno ha structure input di 4 byte e nessuno è AGDC. Non è emerso un quarto client AGDC. Il target 25G342 però **contiene già** `AppleGraphicsDeviceControl` e `AMDRadeonX6000_AmdGpuWrangler` in `SystemKernelExtensions.kc`: il blocker è l’attivazione/ABI/entitlement, non l’assenza del codice. Il produttore userspace del bit `0x2` resta **UNPROVEN**. T27 resta **OPEN**: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **14.124.612 KiB ≈ 13,47 GiB** liberi. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
