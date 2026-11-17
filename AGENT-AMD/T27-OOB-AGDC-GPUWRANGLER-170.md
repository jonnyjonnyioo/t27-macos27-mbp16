# T27 — AGENT-AMD — GPUWRANGLER / COREDISPLAY CLIENT MAP (170)

**Scope:** identificare il client userspace che apre `AppleGraphicsDeviceControl` e invia il selettore 3 con un structure input di 4 byte contenente `0x2`; disassemblare `GPUWrangler.framework`, `CoreDisplay.framework` e `IOPresentment.framework` nella dyld shared cache; separare i client AGDC reali dai client AGC/mux; verificare se `0x2` viene inizializzato in uno di questi percorsi.

**Modalità:** sola lettura. Nessun boot, trace, modifica, build o download. Comandi: `find`, `grep`, `otool`, `dyld_info`, `strings`, `shasum`, `sha256sum`, `df`, `sw_vers`.

**Esito:** **PROVEN** che il client AGDC diretto è **CoreDisplay.framework**, funzione `WSAGDCSetDisplayPolicyEnabled` a `0x7ff80539e0fa`, con `IOServiceMatching("AppleGraphicsDeviceControl")` e `IOConnectCallStructMethod` **selettore `0x10`** su una policy di 8 byte. **PROVEN** un secondo client AGDC diretto, **IOPresentment.framework**, con `IOConnectCallMethod` selettori `1` e `0x980`, sempre con output structure. **PROVEN** che `GPUWrangler.framework` non è un client AGDC: usa `AppleGPUWrangler`, comandi `2`/`0xb`, non il selettore 3. **PROVEN** che un selettore 3 esiste in CoreDisplay, ma appartiene al percorso **AGC/mux** (`AppleGraphicsControl`, `kAGCSetMuxState`), non ad AGDC. **UNPROVEN** il produttore del buffer AGDC da 4 byte con `0x2`: non compare nei tre client analizzati. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| AGDC root2 26.7.2/25G325 | `a3effd46c2c22692019da818ecab43703b44bcb5e2357c174d1b1546fcc633a3` |
| AGDC `Info.plist` root2 | `d521d429dbf95570ec5f6469d1286a846d30739be75e2fe1e1af6244431a5188` |
| AGDC KDK 27.2/26B116 | `ea39241b0c99dae2fb4dd81a33af0b36e1c0ffd1ad04283140ea51555486a1d7` |
| AGDC `Info.plist` target `/System` | `d521d429dbf95570ec5f6469d1286a846d30739be75e2fe1e1af6244431a5188` |
| `CoreDisplay` `Info.plist` | `dfabf1e338a4c7ee8e5403988b9c75b9926bc41987901437f03cb8d2f64356e5` |
| `GPUWrangler` `Info.plist` | `6d290a14ad04eaaa0d61c0eb668058471b39e2e4edfe287590c2fae8f2038c79` |
| `WindowServer` loader | `804cf101ec081e4f07946acaca35d694d8e9d48b25a12c5b4e1a6ce348c9000d` |
| `CoreDisplay.compact` (estrazione cache) | `b7abdcfe3af5c64716f64a38e4002b0ebd432fc5ed7bbf7dc09709c6768d6b75` |
| `IOPresentment.compact` (estrazione cache) | `9d6da75a461d2ea9fa521f39a0da17cb047799414f93b17cc8829dd8bd1efc5f` |
| Report 169 | `ef653e62a451ae39ceeee9a1b7546c0d3d268e340efc42bd572d6759d2579d25` |

**Target osservato:** macOS `26.7.3`, build `25G342`.
**Stato AGDC target:** plist presente e byte-identico a root2; **eseguibile AGDC assente**.
**root2:** `26.7.2`, build `25G325`, AGDC `8.1.12`.
**KDK:** `27.2`, `26B116`.
**Spazio:** **15.387.332 KiB ≈ 14,68 GiB** > 10 GiB.

### 1.1 Correzione del report 169

Il report 169 riportava **0 occorrenze** di `AppleGraphicsDeviceControl` nella cache principale. La verifica diretta con offset e mapping della cache smentisce quel dato.

| Evidenza | Valore |
|---|---|
| Offset cache principale | `0x545572d` |
| VA corrispondente | `0x7ff80545572d` |
| Immagine contenente | `/System/Library/Frameworks/CoreDisplay.framework/Versions/A/CoreDisplay` |
| Seconda occorrenza | offset `0x1599f5d2`, VA `0x7ff81599f5d2`, `IOPresentment` |
| Terza occorrenza | subcache `.02`, offset `0x7631893` |

**PROVEN:** la stringa del servizio è presente nella cache principale, dentro CoreDisplay, a `0x7ff80545572d`.
**PROVEN:** la precedente ricerca 169 non aveva coperto correttamente l'immagine/offset.
**INFERRED:** la stringa è il nome usato da `IOServiceMatching`/`IOServiceGetMatchingService` nel percorso AGDC.

---

## 2. CoreDisplay: client AGDC diretto

### 2.1 Immagine e mapping

| Segmento | VA | Dimensione |
|---|---:|---:|
| `__TEXT` | `0x7ff805348000` | `0x128e3f` |
| `__DATA_CONST` | `0x7ff840522540` | `0xfaf0` |
| `__DATA` | `0x7ff843ad3620` | `0x6078` |
| `__DATA_DIRTY` | `0x7ff8437e07a0` | `0x770` |

**PROVEN:** l'immagine è quella che contiene sia `AppleGraphicsDeviceControl` sia `WS::AGDCService`.
**PROVEN:** `CoreDisplay` non ha un eseguibile standalone nel bundle; il codice è nella shared cache.
**PROVEN:** `CoreDisplay` importa da IOKit `IOConnectCallMethod`, `IOConnectCallStructMethod`, `IOServiceMatching`, `IOServiceGetMatchingService`, `IOServiceOpen`.

### 2.2 Simboli e stringhe

| Indirizzo | Contenuto |
|---:|---|
| `0x7ff80539e038` | `WSAGDCSetDebugOptions` (export `0x56038`) |
| `0x7ff80539e0fa` | `WSAGDCSetDisplayPolicyEnabled` (funzione locale) |
| `0x7ff80539e23e` | blocco `AGDCServiceCreateFirstMatchingClass` |
| `0x7ff80545572d` | `"AppleGraphicsDeviceControl"` |
| `0x7ff80545574d` | `"WS::AGDCService"` |
| `0x7ff80545577f` | `"IOConnectCallStructMethod(dataport, 0x10, &policy, policySize, NULL, NULL); failed (%#x)\n"` |
| `0x7ff8054557de` | `"WSAGDCSetDisplayPolicyEnabled"` |
| `0x7ff805455836` | `"AGDCServiceCreateFirstMatchingClass"` |
| `0x7ff843ad6c38` | globale `gAGDCService` (puntatore all'oggetto) |

**PROVEN:** le stringhe e la funzione sono nella stessa immagine.
**PROVEN:** `gAGDCService` è caricato e memorizzato da `0x...e14f`, `0x...e1df` e `0x...e35a` sullo stesso indirizzo `0x7ff843ad6c38`.

### 2.3 `WSAGDCSetDisplayPolicyEnabled`

Entry `0x7ff80539e0fa`. Argomenti: `edi = enabled`, `esi = flag secondario` (salvato in `ebx`).

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x7ff80539e0fa` | entry | salva `enabled` in `r14d`, flag in `ebx` |
| `0x7ff80539e14f` | `movq 0x3e738ae2(%rip), %r15` | carica `gAGDCService` |
| `0x7ff80539e156` | `testq %r15, %r15` | oggetto già creato? |
| `0x7ff80539e159` | `je 0x...e1a4` | no: crea il servizio |
| `0x7ff80539e15b` | `movl 0x4(%r15), %edi` | **connect port** dell'oggetto |
| `0x7ff80539e15f` | `movzbl %r14b, %eax` | `enabled` come byte |
| `0x7ff80539e163` | `leaq -0x230(%rbp), %rdx` | buffer policy |
| `0x7ff80539e16a` | `movq %rax, (%rdx)` | **policy[0] = enabled (8 byte)** |
| `0x7ff80539e16d` | `movl $0x8, %ecx` | `inputStructCnt = 8` |
| `0x7ff80539e172` | `movl $0x10, %esi` | **selector = 0x10** |
| `0x7ff80539e177` | `xorl %r8d, %r8d` | output struct = NULL |
| `0x7ff80539e17a` | `xorl %r9d, %r9d` | output count = NULL |
| `0x7ff80539e17d` | `callq 0x7ff80543ab3a` | **IOConnectCallStructMethod** |
| `0x7ff80539e186` | log di errore | stringa con `0x10` e `policySize` |

**PROVEN:** la chiamata usa `selector = 0x10`, `inputStruct = &policy`, `inputStructCnt = 8`, nessun output.
**PROVEN:** `policy[0]` è il valore booleano `enabled`; non c'è alcun `0x2`.
**PROVEN:** la stringa di errore adiacente nomina esplicitamente `IOConnectCallStructMethod`.
**INFERRED:** `0x7ff80543ab3a` è lo stub IOKit di `IOConnectCallStructMethod` (la mappatura esatta dello stub non è risolta dal symbol table).
**UNPROVEN:** il significato del secondo argomento `esi`/`ebx`, che controlla solo la distruzione dell'oggetto a fine funzione.

### 2.4 Creazione dell'oggetto AGDC

Percorso eseguito quando `gAGDCService == NULL` (`0x...e1a4` → `0x...e23e`):

| Indirizzo | Istruzione / stringa | Significato |
|---:|---|---|
| `0x7ff80539e1a4` | `leaq -0x264(%rbp), %rsi`; `xorl %edi, %edi`; `callq 0x...ac2a` | **IOMainPort** (INFERRED) |
| `0x7ff80539e23e` | `leaq "AppleGraphicsDeviceControl", %rdi` | nome servizio |
| `0x7ff80539e245` | `callq 0x...adaa` | **IOServiceMatching** (INFERRED) |
| `0x7ff80539e253` | `movl -0x264(%rbp), %edi`; `leaq -0x268(%rbp), %rdx`; `movq %rax, %rsi`; `callq 0x...ada4` | **IOServiceGetMatchingService** (INFERRED) |
| `0x7ff80539e270` | `movl -0x268(%rbp), %edi`; `callq 0x...ac18` | **IOServiceOpen** (INFERRED) |
| `0x7ff80539e2d8` | `movq $0x2c, -0x278(%rbp)` | output size = 44 byte |
| `0x7ff80539e2e3`–`0x7ff80539e2f4` | azzera 44 byte | buffer versione |
| `0x7ff80539e2fb` | `movl -0x26c(%rbp), %edi` | connect port |
| `0x7ff80539e301` | `movl $0x1, %esi` | **selector = 1** |
| `0x7ff80539e306` | `xorl %edx, %edx` | scalar input = NULL |
| `0x7ff80539e308` | `xorl %ecx, %ecx` | scalar input count = 0 |
| `0x7ff80539e30a` | `leaq -0x260(%rbp), %r8` | structure output |
| `0x7ff80539e311` | `leaq -0x278(%rbp), %r9` | output size |
| `0x7ff80539e318` | `callq 0x7ff80543ab3a` | **IOConnectCallStructMethod, selector 1** |
| `0x7ff80539e36f` | `movl $0x20, %edi`; `callq 0x...b0e6` | alloca oggetto 0x20 byte |
| `0x7ff80539e38c` | `movl %r12d, (%r15)` | salva service/type |
| `0x7ff80539e38f` | `movl %eax, 0x4(%r15)` | **salva connect port a +4** |
| `0x7ff80539e35a` | `movq %r15, 0x3e7388d7(%rip)` | pubblica `gAGDCService` |

**PROVEN:** CoreDisplay apre il servizio `AppleGraphicsDeviceControl`.
**PROVEN:** il primo comando dopo l'apertura è il selettore **1**, con output di 44 byte (versione/info), non il selettore 3.
**INFERRED:** la sequenza `IOServiceMatching` → `IOServiceGetMatchingService` → `IOServiceOpen` è quella standard IOKit; le mappature esatte degli stub sono dedotte da stringhe, argomenti e import.
**PROVEN:** la connect port viene salvata a `oggetto+4` ed è quella usata dal selettore `0x10`.

### 2.5 `WSAGDCSetDebugOptions`

Entry `0x7ff80539e038`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x7ff80539e038` | `pushq %rbp` | entry |
| `0x7ff80539e03c` | `movl $0x1, %edi` | argomento = 1 |
| `0x7ff80539e041` | `popq %rbp` | |
| `0x7ff80539e042` | `jmpq *0x3e73b5c0(%rip)` | tail call a funzione puntata |

**PROVEN:** `WSAGDCSetDebugOptions` non costruisce buffer AGDC, non usa `IOConnectCallStructMethod` e non contiene `0x2`.
**UNPROVEN:** il target del tail call (puntatore in `__DATA`); non è stato risolto.
**INFERRED:** è un thunk di abilitazione, non il percorso comando 3.

---

## 3. IOPresentment: secondo client AGDC diretto

### 3.1 Immagine e stringhe

| Elemento | Valore |
|---|---|
| `__TEXT` | `0x7ff815986000` → `0x7ff8159a1cd8` |
| `AppleGraphicsDeviceControl` | `0x7ff81599f5d2` |
| `IOPresentmentClient` | `0x7ff81599f539` |
| `AGDC` / `AGDC map invalid` | stringhe nella `__cstring` |
| `kAGDCVendorInfo` | `0x7ff81599f646` |
| `kAGDCGPUCapability` | `0x7ff81599f759` |

**PROVEN:** IOPresentment contiene il nome del servizio AGDC e codice che lo apre.
**PROVEN:** importa `IOConnectCallMethod`, `IOConnectCallStructMethod`, `IOServiceMatching`, `IOServiceGetMatchingService`, `IOServiceOpen`.
**PROVEN:** `kAGDCVendorInfo` e `kAGDCGPUCapability` sono usati nella stampa/parsing dei risultati, non come nomi di un buffer di input.

### 3.2 `ioPresentmentFindAGDCMatch`

Entry del blocco a `0x7ff815988c18`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x7ff815988c18` | `leaq 0x169b3(%rip), %rdi` | `"AppleGraphicsDeviceControl"` |
| `0x7ff815988c1f` | `callq 0x7ff81599e2b8` | `IOServiceMatching` (INFERRED) |
| `0x7ff815988c29` | `movl -0x70(%rbp), %edi`; `leaq -0x80(%rbp), %rdx`; `movq %rax, %rsi` | service matching |
| `0x7ff815988c33` | `callq 0x7ff81599e2b2` | `IOServiceGetMatchingService` (INFERRED) |
| `0x7ff815988cf7` | `callq 0x7ff81599e2be` | `IOServiceOpen` (INFERRED), type `2` |
| `0x7ff815988d42` | `movl %r13d, %edi`; `leaq -0x2510(%rbp), %rsi`; `callq 0x...e27c` | `IORegistryEntryGetName` (INFERRED) |
| `0x7ff815988e05` | `movl -0x90(%rbp), %edi` | **connect port** |
| `0x7ff815988e2a` | `movl $0x1, %esi` | **selector = 1** |
| `0x7ff815988e2f`–`0x7ff815988e36` | azzera input/struct input | nessun input |
| `0x7ff815988e39` | `callq 0x7ff81599e21c` | **IOConnectCallMethod** (INFERRED) |
| output | `-0x120(%rbp)`, `-0x2568(%rbp)` | structure output e size |

**PROVEN:** la chiamata AGDC di `ioPresentmentFindAGDCMatch` usa **selettore 1**, senza scalar input e senza structure input.
**PROVEN:** il risultato è una struttura di output, non un comando con buffer da 4 byte.
**INFERRED:** `0x7ff81599e21c` è lo stub `IOConnectCallMethod` (forma a 10 argomenti; import presente).

### 3.3 `ioPresentmentPopulateIOFramebufferEntries`

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x7ff8159897b0` | `movl -0x255c(%rbp), %edi` | connect port |
| `0x7ff8159897bd` | `leaq -0x2568(%rbp), %rax`; `movq %rax, 0x18(%rsp)` | output size |
| `0x7ff8159897c9` | `movq %rax, 0x10(%rsp)` | output struct |
| `0x7ff8159897d1` | `movups %xmm0, (%rsp)` | scalar output azzerati |
| `0x7ff8159897d5` | `movl $0x980, %esi` | **selector = 0x980** |
| `0x7ff8159897da`–`0x7ff8159897e1` | azzera input/struct input | nessun input |
| `0x7ff8159897e4` | `callq 0x7ff81599e21c` | **IOConnectCallMethod** |

**PROVEN:** il secondo comando AGDC usa **selettore `0x980`**, senza input, con output struct.
**PROVEN:** non esiste qui un selettore 3 né un buffer di input da 4 byte.
**INFERRED:** `0x980` è il comando vendor/capability di AGDC usato da IOPresentment; il nome esatto non è nel simbolo.

### 3.4 Perché IOPresentment non è il produttore di `0x2`

| Elemento | Stato |
|---|---|
| Apre AGDC | **PROVEN** |
| Usa `IOConnectCallMethod` | **PROVEN** (forma/import) |
| Selettore 1 | **PROVEN** |
| Selettore `0x980` | **PROVEN** |
| Selettore 3 | **ASSENTE nei call site AGDC esaminati** |
| Structure input 4 byte | **ASSENTE** |
| Scrittura `0x2` | **ASSENTE** |

**PROVEN:** IOPresentment è un client AGDC di **interrogazione** (vendor info/capability), non un client che invia il comando 3.
**UNPROVEN:** eventuali percorsi AGDC in altre immagini o generati dinamicamente.

---

## 4. GPUWrangler: client di AppleGPUWrangler, non di AGDC

### 4.1 Immagine

| Elemento | Valore |
|---|---|
| `__TEXT` VA | `0x7ff8159a2000` |
| `__TEXT` size | `0x6530` |
| `GPUWranglerOpen` | `0x7ff8159a28df` (export offset `0x8df`) |
| `GPUWranglerGPULoadDrivers` | `0x7ff8159a6100` (export offset `0x4100`) |
| `GPUWranglerGPUSetAttribute` | `0x7ff8159a6291` (export offset `0x4291`) |
| `AppleGPUWrangler` | stringa a `0x7ff8159a5be7` |
| `AppleGraphicsDeviceControl` | **assente** |

**PROVEN:** GPUWrangler contiene la stringa `AppleGPUWrangler`, non contiene `AppleGraphicsDeviceControl`.
**PROVEN:** GPUWrangler importa `IOServiceOpen`, `IOServiceMatching`, `IOServiceGetMatchingService`, `IOConnectCallMethod`; è un client IOKit, ma di un altro servizio.

### 4.2 `GPUWranglerGPULoadDrivers`

Entry `0x7ff8159a6100`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x7ff8159a6156` | `movzwl 0x18(%rbx), %eax` | GPU id |
| `0x7ff8159a615a` | `leaq -0x3e(%rbp), %rsi` | buffer stack |
| `0x7ff8159a615e` | `movw %ax, (%rsi)` | gpu id a offset 0 |
| `0x7ff8159a6161` | `movl $0x2, 0x2(%rsi)` | **comando 2 a offset 2** |
| `0x7ff8159a6168` | `movq %r14, 0x6(%rsi)` | argomento |
| `0x7ff8159a616c`–`0x7ff8159a6173` | azzera 16+8 byte | buffer di 38 byte |
| `0x7ff8159a617e` | `callq 0x7ff8159a5c3e` | invio al client GPUWrangler |

**PROVEN:** la struttura inviata è più grande di 4 byte e contiene il comando `2` a offset 2.
**PROVEN:** non è il buffer AGDC da 4 byte e non imposta `0x2` nel primo byte.
**INFERRED:** il comando viene inviato al servizio `AppleGPUWrangler`, non ad AGDC.

### 4.3 `GPUWranglerGPUSetAttribute`

Entry `0x7ff8159a6291`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x7ff8159a62f1` | `cmpl $0x756e7375, %r15d` | attributo speciale |
| `0x7ff8159a62fc` | `cmpq $0x1, %r14` | valore == 1 |
| `0x7ff8159a6310` | `movzwl 0x18(%rbx), %eax` | GPU id |
| `0x7ff8159a631b` | `movl $0xb, 0x2(%rsi)` | **comando 0xb a offset 2** |
| `0x7ff8159a632d` | `callq 0x7ff8159a5c3e` | invio |

**PROVEN:** il comando è `0xb`, non il selettore 3; non viene creato alcun `0x2`.
**PROVEN:** GPUWrangler non è il client AGDC del comando 3.
**UNPROVEN:** eventuali percorsi indiretti GPUWrangler → AGDC; la stringa del servizio AGDC non è presente nell'immagine.

### 4.4 Conclusione su GPUWrangler

| Domanda | Risposta |
|---|---|
| Contiene `AppleGraphicsDeviceControl`? | **NO — PROVEN** |
| Apre `AppleGPUWrangler`? | **SÌ — PROVEN dalla stringa e dagli import** |
| Invia comando 2? | **SÌ — PROVEN a `0x...6161`** |
| Invia comando 0xb? | **SÌ — PROVEN a `0x...631b`** |
| Invia il selettore 3 AGDC? | **NO — nessuna evidenza** |
| Costruisce `0x2` per AGDC? | **NO — PROVEN nel codice esaminato** |

---

## 5. Falso positivo: il selettore 3 in CoreDisplay è AGC/mux

### 5.1 `CGXMuxSetPolicyEnabled`

Entry `0x7ff80535782d`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x7ff80535782d` | entry | `bool enabled` |
| `0x7ff805357881` | `leaq -0x30(%rbp), %rdx` | struttura mux |
| `0x7ff805357885` | `movq $0x0, (%rdx)` | campo 0 |
| `0x7ff80535788c` | `movq $0x80, 0x8(%rdx)` | campo 8 |
| `0x7ff805357894` | `movzbl %bl, %eax` | enabled |
| `0x7ff805357897` | `movq %rax, 0x10(%rdx)` | campo 16 |
| `0x7ff80535789b` | `movl 0x3e77cf87(%rip), %edi` | connessione AGC |
| `0x7ff8053578a1` | `movl $0x2, %esi` | **selector = 2** |
| `0x7ff8053578a6` | `movl $0x3, %ecx` | 3 scalar input |
| `0x7ff8053578b1` | `callq 0x7ff80543ab34` | **IOConnectCallScalarMethod** (INFERRED) |
| `0x7ff8053578d5` | log | `kAGCSetMuxState (kMuxPostEvent, AGCEVENT_WS_POLICY, ...)` |

**PROVEN:** questa è una chiamata **AGC mux**, selettore **2**, con 3 scalar input; non è AGDC.
**PROVEN:** la stringa `AppleGraphicsControl` è in CoreDisplay a `0x7ff80544e126`.
**PROVEN:** `mux_initialize` usa `kAGCOpen` e `kAGCGetMuxState` (stringhe a `0x...44e550` e `0x...44e56b`).

### 5.2 Il selettore 3 AGC

Nel blocco AGC/mux precedente (`0x7ff805357729`):

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x7ff8053577b1` | `movl $0x2, %ebx` | costante mux |
| `0x7ff8053577b6` | `movl $0x3, %esi` | **selector = 3** |
| `0x7ff8053577bb` | `movl $0x2, %ecx` | 2 scalar input |
| `0x7ff8053577c0` | `movq %r14, %r8` | output |
| `0x7ff8053577c3` | `movq %r15, %r9` | output count |
| `0x7ff8053577c6` | `callq 0x7ff80543ab34` | **IOConnectCallScalarMethod** (INFERRED) |

**PROVEN:** esiste un selettore 3 in CoreDisplay, ma usa `IOConnectCallScalarMethod` con scalar input, non `IOConnectCallMethod` con structure input.
**PROVEN:** il contesto è AGC/mux: `AppleGraphicsControl`, `kAGC...`, `AGCEVENT_WS_POLICY`.
**PROVEN:** non è il percorso `AppleGraphicsDeviceControl`/`externalMethod`/`UserKernelTransfer`.
**INFERRED:** è il comando di boot/policy del mux AGC; la funzione esterna è `CGXMux...`, non `WSAGDC...`.

### 5.3 Perché è un falso positivo

Una ricerca ingenua di `movl $0x3, %esi` seguita da una chiamata IOKit trova questo punto e può indurre a concludere che CoreDisplay invii il comando 3 ad AGDC. Non è così:

| Caratteristica | AGC mux (`0x...3577c6`) | AGDC comando 3 atteso |
|---|---|---|
| Servizio | `AppleGraphicsControl` | `AppleGraphicsDeviceControl` |
| Metodo | `IOConnectCallScalarMethod` (INFERRED) | `IOConnectCallMethod`/`externalMethod` |
| Input | 2 scalar | structureInput 4 byte |
| Bit `0x2` nel primo byte | **non dimostrato** | richiesto |
| Funzione | `CGXMux...` | `WSAGDC...` |

**PROVEN:** il selettore 3 di CoreDisplay non è il comando 3 AGDC.
**UNPROVEN:** il vero client AGDC del selettore 3.

---

## 6. Matrice dei client

| Immagine | Stringa AGDC | Client AGDC diretto | Selettori AGDC osservati | Input 4 byte / `0x2` |
|---|---|---|---|---|
| `CoreDisplay` | **SÌ** `0x7ff80545572d` | **SÌ** `WSAGDCSetDisplayPolicyEnabled` | `1`, `0x10` | **NO** |
| `IOPresentment` | **SÌ** `0x7ff81599f5d2` | **SÌ** `ioPresentmentFindAGDCMatch` | `1`, `0x980` | **NO** |
| `GPUWrangler` | **NO** | **NO**; usa `AppleGPUWrangler` | `2`, `0xb` | **NO** |
| `AGC mux` (in CoreDisplay) | **NO** | **NO**; usa `AppleGraphicsControl` | `2`, `3` scalar | **NO** |
| `WindowServer` loader | **NO** | **NO**; solo loader `SLXServer` | — | **NO** |

**PROVEN:** i due soli client AGDC trovati nella cache sono CoreDisplay e IOPresentment.
**PROVEN:** nessuno dei due invia il selettore 3 con structure input di 4 byte.
**PROVEN:** GPUWrangler e AGC/mux sono client di servizi diversi.
**UNPROVEN:** un client AGDC in un'altra immagine, un percorso dinamico o un chiamante kernel.

### 6.1 Copertura della ricerca

| Ricerca | Esito |
|---|---|
| `AppleGraphicsDeviceControl` nella cache principale | **2 occorrenze**: CoreDisplay, IOPresentment |
| `AppleGraphicsDeviceControl` nella subcache `.02` | **1 occorrenza** |
| `WS::AGDCService` | **CoreDisplay** |
| `AppleGPUWrangler` | **GPUWrangler / IOPresentment** |
| `AppleGraphicsControl` | **CoreDisplay AGC/mux** |
| `IOConnectCallMethod` in CoreDisplay | **importato**; usato in altri percorsi IOKit |
| `IOConnectCallStructMethod` in CoreDisplay | **importato**; usato dal selettore AGDC `0x10` e dal selettore `1` |
| selettore 3 AGDC con structure input | **non trovato** |
| bit `0x2` nel buffer AGDC | **non trovato** |

**PROVEN:** all'interno delle immagini estratte, non esiste un call site AGDC con selettore 3 e structure input di 4 byte.
**UNPROVEN:** l'assenza in altre immagini non analizzate o in codice generato a runtime.

---

## 7. Catena ricostruita

### 7.1 CoreDisplay — policy AGDC

```text
WSAGDCSetDisplayPolicyEnabled(enabled, flag)
  ├─ gAGDCService == NULL?
  │    └─ AGDCServiceCreateFirstMatchingClass
  │         ├─ IOServiceMatching("AppleGraphicsDeviceControl")
  │         ├─ IOServiceGetMatchingService
  │         ├─ IOServiceOpen
  │         └─ IOConnectCallStructMethod(connect, selector=1,
  │              input=NULL, inputSize=0,
  │              output=&version, outputSize=0x2c)
  └─ IOConnectCallStructMethod(connect, selector=0x10,
       input=&policy, inputSize=8,
       output=NULL, outputCount=NULL)
       policy[0] = (uint64_t)enabled
```

**PROVEN:** la catena è completa e usa il servizio AGDC.
**PROVEN:** il selettore è `0x10`, non `3`; l'input è 8 byte, non 4.
**PROVEN:** il bit `0x2` non viene scritto.

### 7.2 IOPresentment — interrogazione AGDC

```text
ioPresentmentFindAGDCMatch
  ├─ IOServiceMatching("AppleGraphicsDeviceControl")
  ├─ IOServiceGetMatchingService
  ├─ IOServiceOpen
  └─ IOConnectCallMethod(connect, selector=1,
       input=NULL, inputSize=0,
       output=&info, outputSize=&size)

ioPresentmentPopulateIOFramebufferEntries
  └─ IOConnectCallMethod(connect, selector=0x980,
       input=NULL, inputSize=0,
       output=&capabilities, outputSize=&size)
```

**PROVEN:** entrambi i comandi sono di sola lettura/interrogazione.
**PROVEN:** nessun selettore 3, nessun buffer di input da 4 byte, nessun `0x2`.

### 7.3 GPUWrangler / AGC

```text
GPUWranglerGPULoadDrivers
  └─ buffer 38 byte: [gpuID:2][cmd=2:4][...] → AppleGPUWrangler

GPUWranglerGPUSetAttribute
  └─ buffer: [gpuID:2][cmd=0xb:4][...] → AppleGPUWrangler

CGXMuxSetPolicyEnabled / CGXMux...
  └─ IOConnectCallScalarMethod(connect, selector=2/3,
       scalarInput=..., scalarCount=2/3) → AppleGraphicsControl
```

**PROVEN:** sono percorsi separati da AGDC.
**PROVEN:** nessuno costruisce il buffer AGDC da 4 byte con `0x2`.

---

## 8. Stato delle prove

| Prova | Stato |
|---|---|
| CoreDisplay apre `AppleGraphicsDeviceControl` | **PROVEN** |
| CoreDisplay usa `IOConnectCallStructMethod` selettore `0x10` | **PROVEN** |
| Policy CoreDisplay = 8 byte, `enabled` | **PROVEN** |
| CoreDisplay crea l'oggetto con selettore 1 e output 44 byte | **PROVEN** |
| IOPresentment apre AGDC | **PROVEN** |
| IOPresentment usa selettori 1 / `0x980` | **PROVEN** |
| GPUWrangler usa `AppleGPUWrangler` | **PROVEN** |
| GPUWrangler usa comandi 2 / `0xb` | **PROVEN** |
| Selettore 3 CoreDisplay è AGC/mux | **PROVEN** |
| Selettore 3 AGDC con input 4 byte | **UNPROVEN / non trovato** |
| Istruzione userspace che scrive `0x2` | **UNPROVEN** |
| Processo concreto che invia il comando 3 | **UNPROVEN** |
| Runtime target 25G342 | **UNPROVEN** |

---

## 9. Diagnosi

| Priorità | Elemento | Stato |
|---:|---|---|
| 1 | CoreDisplay è client AGDC | **PROVEN** |
| 2 | Selettore AGDC CoreDisplay | **`0x10` — PROVEN** |
| 3 | IOPresentment è client AGDC | **PROVEN** |
| 4 | Selettori IOPresentment | **`1`, `0x980` — PROVEN** |
| 5 | GPUWrangler è client AGDC | **NO — PROVEN** |
| 6 | Selettore 3 CoreDisplay è AGDC | **NO — è AGC/mux** |
| 7 | Buffer AGDC 4 byte con `0x2` | **UNPROVEN** |
| 8 | Call site userspace del selettore 3 | **UNPROVEN** |

**Diagnosi:** il percorso AGDC userspace è stato identificato, ma non è quello del comando 3. CoreDisplay usa AGDC per la **display policy** (`0x10`) e per la **versione** (`1`); IOPresentment usa AGDC per **vendor info/capability** (`1`, `0x980`). Il selettore 3 presente in CoreDisplay appartiene al mux **AGC**, non ad AGDC. Di conseguenza il buffer AGDC da 4 byte con `0x2` non è prodotto da questi client: il produttore resta fuori dalle immagini analizzate.

---

## 10. Verdetto

| Domanda | Risposta |
|---|---|
| Client AGDC diretto identificato? | **SÌ: CoreDisplay** |
| Secondo client AGDC? | **SÌ: IOPresentment** |
| CoreDisplay invia il selettore 3 AGDC? | **NO — usa `0x10` policy e `1` versione** |
| IOPresentment invia il selettore 3 AGDC? | **NO — usa `1` e `0x980`** |
| GPUWrangler è il client AGDC? | **NO — usa `AppleGPUWrangler`** |
| Il selettore 3 in CoreDisplay è AGDC? | **NO — è AGC/mux** |
| Buffer AGDC 4 byte con `0x2` | **NON TROVATO** |
| Processo che invia il comando 3 | **UNPROVEN** |
| Target 25G342 runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** CoreDisplay è il client AGDC userspace reale, ma il suo percorso AGDC è **`WSAGDCSetDisplayPolicyEnabled` → `IOConnectCallStructMethod(selector=0x10, policy[8])`**, preceduto dal selettore `1` di versione. IOPresentment è un secondo client AGDC, limitato a interrogazioni (`1`, `0x980`). GPUWrangler non è un client AGDC: parla con `AppleGPUWrangler` e usa i comandi `2`/`0xb`. Il selettore 3 che compare in CoreDisplay è **AGC/mux** e usa scalar input, non il buffer AGDC da 4 byte. Il produttore del buffer AGDC con `0x2` resta **UNPROVEN**; non è stato trovato in CoreDisplay, IOPresentment o GPUWrangler. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **15.387.332 KiB ≈ 14,68 GiB** > 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
