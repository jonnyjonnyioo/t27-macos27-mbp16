# T27 — AGENT-AMD — TARGET SystemKC / ABI AGDC / AUTORIZZAZIONE (173)

**Scope:** verificare la catena AGDC realmente presente nel `SystemKernelExtensions.kc` target 25G342; analizzare `AppleGraphicsDeviceControl::start`, `newUserClient`, `UserKernelTransfer`; verificare entitlement, autorizzazioni e registrazione; ricostruire il callback `[vtable+0x858]` verso `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute`; confrontare target e root2; valutare un compatibility layer userspace minimo che usi il SystemKC senza sostituire AGDC o modificare il kernel.

**Modalità:** sola lettura. Nessun boot, trace, modifica ai file di sistema, build o download. Comandi: `nm`, `otool`, `ndisasm`, `llvm-objdump`, `strings`, `shasum`, `sha256sum`.

**Esito sintetico:** **PROVEN** che il target 25G342 contiene il codice AGDC e il Wrangler AMD in `SystemKernelExtensions.kc`. **PROVEN** che le funzioni ABI-critical del target sono **byte-identiche** a root2: `externalMethod` `0x6dc`, `authorizeTask` `0x7fe`, `initWithTask` `0x9b4`, `start` `0x1392`, `filtered` `0x17b0`, `newUserClient` `0x2cbe`, `UserKernelTransfer` `0x2e60`. Solo `publishHdaGfxProperties` differisce (18 byte). **PROVEN** che `newUserClient` chiama `initWithTask` e `authorizeTask`; **PROVEN** che `authorizeTask` richiede uno dei due entitlement privati o il boot-arg `agdc_entitle`; `WindowServer` è riconosciuto in `initWithTask`. **PROVEN** che `filtered` con selettore 3 richiede input 4 byte, chiama `[vtable+0x858]` con la stessa firma del Wrangler e che il Wrangler testa `0x2` e imposta `LoadHWServices`, `LoadController`, `LoadAccelerator`. **UNPROVEN** il puntatore esatto della vtable e l’avvio runtime del servizio. Il primo ostacolo pratico è l’**autorizzazione/entitlement del client**, non l’ABI. T27 resta **OPEN**: **94% engineering / 32% first boot / 8% desktop**.

---

## 1. Ambiente e SHA-256

| Artefatto | SHA-256 |
|---|---|
| Report 172 | `35b9c436da9b3b65c245581070dce71f5a074d75ca632fbfc1733748add32dbc` |
| `SystemKernelExtensions.kc` target 25G342 | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| AGDC root2 26.7.2/25G325 | `a3effd46c2c22692019da818ecab43703b44bcb5e2357c174d1b1546fcc633a3` |
| AGDC `Info.plist` root2/target | `d521d429dbf95570ec5f6469d1286a846d30739be75e2fe1e1af6244431a5188` |
| AGDC KDK 27.2/26B116 | `ea39241b0c99dae2fb4dd81a33af0b36e1c0ffd1ad04283140ea51555486a1d7` |

**Target:** macOS `26.7.3`, build `25G342`.
**Kernel collection:** `/System/Library/KernelCollections/SystemKernelExtensions.kc`, Mach-O x86_64, 352 MB.
**Base codice AGDC target:** `0x13d3f000` (dedotta da `externalMethod = base + 0x6dc`).
**Base Wrangler target:** `0xbf9894e` per `vendor_doDeviceAttribute`.
**Spazio:** **14.124.612 KiB ≈ 13,47 GiB** liberi; sopra 10 GiB.

---

## 2. Confronto target ↔ root2

### 2.1 Metodo

Il file root2 `.tmp/AGDC` è un kext Mach-O con il codice a offset noti (report 169): `externalMethod` `0x6dc`, `authorizeTask` `0x7fe`, `initWithTask` `0x9b4`, `start` `0x1392`, `filtered` `0x17b0`, `newUserClient` `0x2cbe`, `UserKernelTransfer` `0x2e60`.

Nel target, la base `0x13d3f000` è stata ricavata dal simbolo `externalMethod` a `0x13d3f6dc`; gli altri simboli cadono agli stessi offset.

### 2.2 Byte comparison

| Funzione | Offset root2 | Target | Byte identici |
|---|---:|---:|---|
| `externalMethod` | `0x6dc` | `0x13d3f6dc` | **SÌ** |
| `authorizeTask` | `0x7fe` | `0x13d3f7fe` | **SÌ** |
| `initWithTask` | `0x9b4` | `0x13d3f9b4` | **SÌ** |
| `AppleGraphicsDeviceControlClient::start` | `0xaee` | `0x13d3faee` | **SÌ** |
| `AppleGraphicsDeviceControlClient::stop` | `0xbba` | `0x13d3fbba` | **SÌ** |
| `message` client | `0xd00` | `0x13d3fd00` | **SÌ** |
| `doPlugin_Command` | `0xed2` | `0x13d3fed2` | **SÌ** |
| `publishHdaGfxProperties` | `0x150` | `0x13d3f150` | **NO — 18 byte diversi** |
| `start` AGDC | `0x1392` | `0x13d40392` | **SÌ** |
| `stop` AGDC | `0x16ac` | `0x13d406ac` | **SÌ** |
| `message` AGDC | `0x1750` | `0x13d40750` | **SÌ** |
| `getDeviceAttribute` | `0x178e` | `0x13d4078e` | **SÌ** |
| `filtered_doDeviceAttribute` | `0x17b0` | `0x13d407b0` | **SÌ** |
| `setDeviceAttribute` | `0x2bdc` | `0x13d41bdc` | **SÌ** |
| `doDeviceAttribute` | `0x2c00` | `0x13d41c00` | **SÌ** |
| `vendor_doDeviceAttribute` | `0x2c34` | `0x13d41c34` | **SÌ** |
| `newUserClient` | `0x2cbe` | `0x13d41cbe` | **SÌ** |
| `UserKernelTransfer` | `0x2e60` | `0x13d41e60` | **SÌ** |

**PROVEN:** tutte le funzioni ABI-critical del user client e del comando 3 sono byte-identiche tra root2 e target.
**PROVEN:** l’unica differenza rilevata è `publishHdaGfxProperties` (18 byte su 578), non nel percorso `UserKernelTransfer`/`filtered` del comando 3.
**PROVEN:** non c’è una differenza ABI target/root2 nei registri o negli offset di `IOExternalMethodArguments`.
**UNPROVEN:** che l’intero kext AGDC sia identico; sono state confrontate le funzioni elencate, non ogni byte del file.

### 2.3 Conseguenza

Il target può usare la stessa analisi ABI di root2:

- `IOExternalMethodArguments`:
  - `0x20` scalarInput
  - `0x28` scalarInputCount
  - `0x30` structureInput
  - `0x38` structureInputSize
  - `0x40` structureInputDescriptor
  - `0x48` scalarOutput
  - `0x50` scalarOutputCount
  - `0x58` structureOutput
  - `0x60` structureOutputSize
  - `0x68` structureOutputDescriptor

**PROVEN:** `UserKernelTransfer` target legge gli stessi offset di root2.
**PROVEN:** il buffer del comando 3 resta `structureInput` di 4 byte; AGDC non lo costruisce.

---

## 3. `AppleGraphicsDeviceControl::start`

### 3.1 Sequenza

Entry `0x13d40392`.

| Indirizzo | Istruzione / azione | Significato |
|---:|---|---|
| `0x13d403be` | `call [rax+0x5d0]` | `super::start` (INFERRED) |
| `0x13d403f4` | `mov rax,[r14]` | vtable dell’oggetto AGDC |
| `0x13d40402` | `mov esi,1` | selettore AGDC 1 |
| `0x13d4040e` | `call [rax+0x858]` | callback/vtable AGDC |
| `0x13d40414` | legge output 0x2c | versione/info |
| `0x13d40443` | `mov esi,0x980` | selettore capability |
| `0x13d4044f` | `call [rax+0x858]` | callback AGDC |
| `0x13d40464` | `lea rsi, "NeedsPolicyDriver"` | proprietà |
| `0x13d40470` | `call [rax+0x278]` | setProperty |
| `0x13d40485` | `lea rsi, "AppleGPUWrangler"` | nome servizio Wrangler |
| `0x13d4048f` | `call 0x1047a` | matching/get service (INFERRED) |
| `0x13d40611` | `lea rsi, "IOPCITunnelled"` | proprietà |
| `0x13d40620` | `call [rax+0x2d0]` | setProperty |
| `0x13d40631` | `edi=0x1000`, `esi=0`, `rdx=this` | `doPlugin_Command(0x1000,0,this)` |
| `0x13d4063b` | `call 0x13d3fed2` | comando plugin |
| `0x13d4064a` | `call [rax+0x2a8]` | getProperty (INFERRED) |
| `0x13d4065b` | `lea rsi, "IOUserClientClass"` | proprietà |
| `0x13d40665` | `lea rdx, "AppleGraphicsDeviceControlClient"` | classe client |
| `0x13d4066f` | `call [rax+0x270]` | setProperty |
| `0x13d4067d` | `call [rax+0x5b0]` | setPowerState/avvio (INFERRED) |

**PROVEN:** `start` invia i comandi AGDC 1 e `0x980` tramite `[vtable+0x858]`.
**PROVEN:** `start` imposta `NeedsPolicyDriver`, `IOPCITunnelled` e `IOUserClientClass = AppleGraphicsDeviceControlClient`.
**PROVEN:** `start` cerca `AppleGPUWrangler` e invoca `doPlugin_Command(0x1000, 0, this)`.
**INFERRED:** il `call [rax+0x5d0]` iniziale è il `super::start` di `IOService`.
**UNPROVEN:** che il servizio venga registrato e che `start` ritorni successo a runtime.

### 3.2 Condizioni di registrazione

| Condizione | Evidenza | Stato |
|---|---|---|
| Codice AGDC nel target | `SystemKC` defined symbols | **PROVEN** |
| `IOUserClientClass` impostata | `start` `0x13d4066f` | **PROVEN statico** |
| `AppleGPUWrangler` cercato | string `0x13d42822` | **PROVEN statico** |
| `NeedsPolicyDriver` impostata | string `0x13d42810` | **PROVEN statico** |
| `IOPCITunnelled` impostata | string `0x13d42764` | **PROVEN statico** |
| plugin command `0x1000` | `0x13d40631` | **PROVEN statico** |
| servizio avviato a runtime | nessuna trace | **UNPROVEN** |

**PROVEN:** il codice di registrazione è presente e coerente con un kext AGDC funzionante.
**UNPROVEN:** l’esito runtime di `start` e la presenza effettiva del servizio IOService.

---

## 4. `newUserClient`, `initWithTask`, `authorizeTask`

### 4.1 `newUserClient`

Entry `0x13d41cbe`.

| Indirizzo | Istruzione / azione | Significato |
|---:|---|---|
| `0x13d41ced` | `call [rax+0x2a8]` | ottiene/crea l’oggetto client |
| `0x13d41d3f` | `call 0x107c8` | alloca/crea client (INFERRED) |
| `0x13d41d5d` | `call [rax+0x258]` | preparazione provider |
| `0x13d41d88` | `call 0x1007e` | confronto classe/metaclass |
| `0x13d41da6` | `call [r8+0x8e8]` | **`initWithTask`** (INFERRED) |
| `0x13d41db0` | `test al,al` | inizializzazione riuscita? |
| `0x13d41dc0` | `call [r8+0x960]` | **`authorizeTask`** (INFERRED) |
| `0x13d41dcc` | `test al,al` | autorizzazione riuscita? |
| `0x13d41dd4` | `call [rcx+0x670]` | attach/start client (INFERRED) |
| `0x13d41de7` | `call [rcx+0x5c0]` | registrazione finale (INFERRED) |
| `0x13d41df1` | `mov [r15],rbx` | restituisce il client |
| errori | `0xe00002bc`, `0xe00002bd`, `0xe00002c7` | codici IOKit |

**PROVEN:** `newUserClient` crea il client e chiama due gate virtuali, `[r8+0x8e8]` e `[r8+0x960]`.
**INFERRED:** i due gate sono `AppleGraphicsDeviceControlClient::initWithTask` e `authorizeTask`, in quest’ordine.
**PROVEN:** se un gate fallisce, il client viene rilasciato e `newUserClient` ritorna errore.
**UNPROVEN:** la mappatura esatta degli slot vtable `0x8e8`/`0x960` ai simboli, per la codifica chained della vtable.

### 4.2 `initWithTask`

Entry `0x13d3f9b4`.

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x13d3f9df` | `call [rax+0x8f8]` | controllo preliminare task (INFERRED) |
| `0x13d3f9f0` | `test r12,r12` | task valido? |
| `0x13d3fa69` | `lea rsi, "WindowServer"` | nome processo |
| `0x13d3fa73` | `call 0x100fc` | confronto stringa (INFERRED) |
| `0x13d3fa7a` | `setz [rbx+0x110]` | flag WindowServer |
| `0x13d3fa88` | `mov [rbx+0xf0],rbx` | self pointer |
| `0x13d3fa8f` | `mov [rbx+0xf8],r12` | task |
| `0x13d3fa96` | `mov [rbx+0x108],r15d` | tipo |
| `0x13d3faa1` | `mov [rbx+0x100],rax` | argomento |
| `0x13d3fab6` | `mov [rbx+0x130],r14b` | flag |
| `0x13d3fac4` | `mov al,1` | successo |

**PROVEN:** `initWithTask` confronta il nome del processo con `"WindowServer"` e salva il risultato a `client+0x110`.
**PROVEN:** il client memorizza task, self pointer, tipo e argomento.
**INFERRED:** il confronto è `strcmp`/`proc_selfname`; il flag `+0x110` è il riconoscimento WindowServer.
**UNPROVEN:** che il flag WindowServer da solo autorizzi il client; `authorizeTask` non lo legge direttamente.

### 4.3 `authorizeTask`

Entry `0x13d3f7fe`.

Stringhe target:

| Indirizzo | Stringa |
|---:|---|
| `0x13d42600` | `agdc_entitle` |
| `0x13d4260d` | `com.apple.private.applegraphicsdevicecontrol` |
| `0x13d4263a` | `com.apple.private.gpuwrangler` |
| `0x13d42658` | `AGDCC: Unauthorized client '%s' blocked (%s)` |
| `0x13d42687` | `WindowServer` |

Flusso:

| Indirizzo | Istruzione / azione | Significato |
|---:|---|---|
| `0x13d3f82a` | `cmp byte [agdc_entitle],0xff` | override boot-arg? |
| `0x13d3f83e` | `lea rdi, "agdc_entitle"` | nome boot-arg |
| `0x13d3f848` | `edx=1`; `call 0x1019e` | parse boot-arg (INFERRED) |
| `0x13d3f860` | `mov [agdc_entitle],cl` | salva override |
| `0x13d3f866` | `lea rsi, entitlement 1` | `com.apple.private.applegraphicsdevicecontrol` |
| `0x13d3f870` | `call 0x10234` | `copyClientEntitlement` (INFERRED) |
| `0x13d3f878` | carica globale/atteso | confronto entitlement |
| `0x13d3f898` | `cmp rbx,r12` | match? |
| `0x13d3f8a1` | `lea rsi, entitlement 2` | `com.apple.private.gpuwrangler` |
| `0x13d3f8ab` | `call 0x10234` | seconda verifica |
| `0x13d3f8c5` | `cmp rbx,r14` | match? |
| `0x13d3f8ce` | `cmp [agdc_entitle],0` | override attivo? |
| `0x13d3f8d5` | `jnz 0x13d3f98a` | autorizza se boot-arg |
| `0x13d3f98a` | ritorno | autorizzato |
| `0x13d3f972` | `lea rdi, "AGDCC: Unauthorized client..."` | log negato |

**PROVEN:** `authorizeTask` verifica i due entitlement privati.
**PROVEN:** `authorizeTask` accetta anche un override `agdc_entitle` da boot-arg.
**PROVEN:** se nessun entitlement e override assente, logga `AGDCC: Unauthorized client`.
**INFERRED:** `0x10234` è `copyClientEntitlement`; la sequenza è quella classica IOKit.
**UNPROVEN:** il valore di `agdc_entitle` sul target; nessun boot/trace.

### 4.4 WindowServer

| Elemento | Stato |
|---|---|
| `WindowServer` in `initWithTask` | **PROVEN** |
| flag `client+0x110` | **PROVEN** |
| `WindowServer` in `authorizeTask` | **NO** (la funzione usa entitlement/boot-arg) |
| WindowServer autorizzato senza entitlement | **UNPROVEN** |
| WindowServer ha entitlement firmati | **UNPROVEN** |

**PROVEN:** `WindowServer` è riconosciuto e marcato, ma il percorso `authorizeTask` non contiene un ramo `WindowServer`.
**INFERRED:** WindowServer può superare l’autorizzazione solo se ha l’entitlement firmato o se `agdc_entitle` è attivo.
**UNPROVEN:** il contenuto effettivo della firma di WindowServer/SkyLight.

---

## 5. `UserKernelTransfer` target

Entry `0x13d41e60`, byte-identico a root2 `0x2e60`.

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x13d41e7c` | `mov r14,[rdx+0x38]` | `args` |
| `0x13d41e80` | `mov r15,[r14+0x40]` | input descriptor |
| `0x13d41e84` | `mov rbx,[r14+0x68]` | output descriptor |
| `0x13d41e8d` | `mov rax,[rbx]` | vtable descriptor |
| `0x13d41e93` | `call [rax+0x1c8]` | lunghezza output descriptor |
| `0x13d41ec4` | `mov r15d,[r14+0x38]` | fallback input size |
| `0x13d41edb` | confronto `0x4000000` | limite 64 MiB |
| `0x13d41f8d` | `call [rdx+0x118]` | mapping input |
| `0x13d41fac` | `lea rax,[rbp-0x68]` | output size |
| `0x13d41fb0` | `mov rdi,[rbp-0x58]` | AGDC object |
| `0x13d41fb4` | `mov esi,3` | **api = 3** |
| `0x13d41fb9` | `mov edx,[rbp-0x2c]` | selector |
| `0x13d41fbc` | `mov r8,r15` | input size |
| `0x13d41fbf` | `push [rbp-0x60]` | struttura args |
| `0x13d41fc3` | `call 0x13d407b0` | **`filtered_doDeviceAttribute`** |

**PROVEN:** `UserKernelTransfer` passa a `filtered` **api=3** e il selettore originale.
**PROVEN:** il buffer input è `structureInput`/descriptor; AGDC non lo costruisce.
**PROVEN:** il limite è 64 MiB; il comando 3 richiede 4 byte nel ramo successivo.
**UNPROVEN:** la forma puntatore vs descrittore usata dal client reale.

---

## 6. `filtered` comando 3 e callback

### 6.1 Ramo selettore 3

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x13d40cba` | `cmp r13d,3` | selettore 3 |
| `0x13d40cbe` | `jz 0x13d412f0` | ramo comando 3 |
| `0x13d412f0` | `test r8,r8` | input presente? |
| `0x13d412f5` | `cmp r8,4` | input size 4 |
| `0x13d41310` | `test r11,r11` | output size pointer? |
| `0x13d41318` | `cmp [r11],4` | output size 4 |
| `0x13d41343` | `test byte [rdi+0xb5],1` | flag policy/HDA |
| `0x13d41350` | `test byte [r10],4` | bit HDA |
| `0x13d4136e` | `call 0x13d40150` | `publishHdaGfxProperties` |
| `0x13d41787` | `xor ebx,ebx` | esito |
| `0x13d41789` | `mov rax,[rdi]` | vtable |
| `0x13d41790` | `mov esi,r13d` | selector 3 |
| `0x13d41793` | `mov rdx,r10` | input |
| `0x13d41796` | `mov rcx,r8` | input size |
| `0x13d41799` | `mov r8,r15` | output |
| `0x13d4179c` | `mov r9,r11` | output size pointer |
| `0x13d4179f` | `call [rax+0x858]` | **callback AGDC** |

**PROVEN:** il comando 3 richiede input di 4 byte e output di 4 byte.
**PROVEN:** il bit `0x4` dell’input è il flag HDA; `0x2` non viene scritto da AGDC.
**PROVEN:** il callback è una chiamata virtuale `[vtable+0x858]`.
**UNPROVEN:** il simbolo esatto dello slot `0x858` (vtable con chained fixup non decodificata).

### 6.2 Firma del callback

Al call site `0x13d4179f`:

| Registro | Valore |
|---|---|
| `rdi` | oggetto AGDC (`this`) |
| `rsi` | selettore 3 (`r13d`) |
| `rdx` | input (`r10`) |
| `rcx` | input size 4 (`r8`) |
| `r8` | output (`r15`) |
| `r9` | output size pointer (`r11`) |

**PROVEN:** la firma è `(this, selector, input, inputSize, output, outputSize)`.
**PROVEN:** il selettore passato è 3 e la size input è 4.

### 6.3 Wrangler AMD

Entry `0xbf9894e`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0xbf98968` | `test r9,r9` | output size pointer |
| `0xbf9896d` | `mov r12,[r9]` | output size |
| `0xbf98975` | `test r15,r15` | output |
| `0xbf9897b` | `test rbx,rbx` | input |
| `0xbf989a2` | `cmp r13d,3` | comando 3 |
| `0xbf989a6` | `jz 0xbf989d8` | ramo comando 3 |
| `0xbf989d8` | `test r12,r12` | output size noto? |
| `0xbf989e6` | `mov dword [r15],3` | output = 3 |
| `0xbf989fc` | `test rbx,rbx` | input |
| `0xbf98a05` | `call [rax+0x680]` | oggetto Wrangler |
| `0xbf98a17` | `call 0xbf8ec04` | lock/prepare (INFERRED) |
| `0xbf98a1e` | `test al,0x2` | **bit 0x2** |
| `0xbf98a25` | `lea rsi, "LoadHWServices"` | proprietà |
| `0xbf98a34` | `call [rax+0x278]` | setProperty `LoadHWServices` |
| `0xbf98a40` | `mov esi,2` | setPowerState 2 |
| `0xbf98a45` | `call [rax+0x5b0]` | power state |
| `0xbf98a54` | `lea rsi, "LoadController"` | proprietà |
| `0xbf98a63` | `call [rax+0x278]` | setProperty `LoadController` |
| `0xbf98a72` | `lea rsi, "LoadAccelerator"` | proprietà |
| `0xbf98a81` | `call [rax+0x278]` | setProperty `LoadAccelerator` |
| `0xbf98a89` | `test al,0x3` | bit 0/1 |
| `0xbf98a9e` | `call 0xbf8ec04` | unlock (INFERRED) |

**PROVEN:** il Wrangler gestisce il comando 3.
**PROVEN:** se l’input contiene `0x2`, imposta `LoadHWServices=true`, `LoadController=true`, `LoadAccelerator=true` e richiede il power state 2.
**PROVEN:** il bit `0x1` controlla `LoadController`; il bit `0x2` controlla `LoadHWServices`/`LoadAccelerator` nel ramo osservato.
**INFERRED:** il ramo `0xbf989d8` è il percorso output-only; il ramo `0xbf989fc` è il percorso input.
**UNPROVEN:** che lo slot `[vtable+0x858]` punti esattamente a `0xbf9894e`; la firma e il comportamento coincidono, ma la vtable encoded non è stata risolta.

### 6.4 Perché il callback non è ancora “chiuso”

| Prova | Stato |
|---|---|
| Call site `filtered+0x858` con selettore 3 | **PROVEN** |
| Firma compatibile con Wrangler | **PROVEN** |
| Wrangler gestisce `0x2` e `LoadHWServices` | **PROVEN** |
| Puntatore vtable `0x858` → `0xbf9894e` | **UNPROVEN** |
| Catena runtime AGDC → Wrangler | **UNPROVEN** |

**PROVEN:** la forma della chiamata è quella del Wrangler.
**UNPROVEN:** l’identità del puntatore nello slot; il valore encoded `0x400000009bfea0` non è stato decodificato con certezza.

---

## 7. Compatibility layer userspace

### 7.1 Cosa può fare

Un harness userspace può:

1. cercare `AppleGraphicsDeviceControl`;
2. aprire la connessione;
3. inviare `IOConnectCallMethod` con:
   - `selector = 3`
   - `scalarInput = {3}`, `scalarInputCount = 1`
   - `structureInput = {0x2,...}`, `structureInputSize = 4`
   - `scalarOutput = 1`, `scalarOutputCount = 1`
4. ricevere l’esito del callback Wrangler.

**PROVEN:** l’ABI è quella target/root2 identica.
**PROVEN:** il comando 3 e il buffer 4 byte sono coerenti con `filtered`.
**UNPROVEN:** che il servizio sia attivo e che il client sia autorizzato.

### 7.2 Prerequisiti

| # | Prerequisito | Stato |
|---:|---|---|
| 1 | Codice AGDC nel SystemKC | **PROVEN** |
| 2 | `start` registra `IOUserClientClass` | **PROVEN statico** |
| 3 | Servizio IOService attivo | **UNPROVEN** |
| 4 | `initWithTask` | **PROVEN statico** |
| 5 | `authorizeTask` con entitlement | **PROVEN statico** |
| 6 | Entitlement disponibile per l’harness | **UNPROVEN / BLOCKED** |
| 7 | Callback `0x858` → Wrangler | **UNPROVEN** (firma PROVEN) |
| 8 | `LoadHWServices` runtime | **UNPROVEN** |

### 7.3 Autorizzazione: primo ostacolo

`authorizeTask` accetta:

- `com.apple.private.applegraphicsdevicecontrol`, oppure
- `com.apple.private.gpuwrangler`, oppure
- boot-arg `agdc_entitle` diverso da 0.

**PROVEN:** un client ordinario senza uno di questi non supera `authorizeTask`.
**PROVEN:** WindowServer è riconosciuto in `initWithTask`, ma `authorizeTask` non ha un ramo WindowServer.
**INFERRED:** WindowServer deve possedere l’entitlement firmato o il boot-arg.
**UNPROVEN:** il contenuto della firma di WindowServer/SkyLight.

Un harness locale **non può auto-assegnarsi** un entitlement privato Apple: la firma/AMFI lo impedisce. Root non basta. L’alternativa “eseguire dentro WindowServer” non è isolata e richiede interposizione/firma.

**PROVEN:** l’autorizzazione è il primo ostacolo pratico del layer client-only.
**UNPROVEN:** un percorso autorizzato alternativo che non modifichi kernel o processi Apple.

### 7.4 Cosa non serve

| Componente | Conclusione |
|---|---|
| Ricreare AGDC | **NON necessario**; codice target presente |
| Ricreare il Wrangler | **NON necessario**; codice target presente |
| Sostituire il kernel | **NON necessario e bloccato** |
| Modificare SystemKC | **vietato e non necessario** |
| Usare CoreDisplay per il comando 3 | **non applicabile**; non lo invia |
| Usare IOPresentment per il comando 3 | **non applicabile**; solo query |

**PROVEN:** il layer non deve sostituire AGDC; deve solo essere un client autorizzato.
**PROVEN:** la parte mancante non è il codice Apple, ma l’autorizzazione e il client userspace.

### 7.5 Fattibilità

| Scenario | Fattibilità |
|---|---|
| Harness con entitlement privato | **condizionata**; ABI pronta, autorizzazione da ottenere |
| Harness senza entitlement | **non fattibile** su stock; `authorizeTask` nega |
| Harness dentro WindowServer | **non isolato**; SIP/firma |
| Sostituzione AGDC/Wrangler | **bloccata/non necessaria** |
| Solo analisi statica | **completa** per ABI e autorizzazione |

**Risposta netta:** il compatibility layer userspace minimo è **tecnicamente corretto** e non richiede modifiche al kernel, ma è **praticamente bloccato dall’autorizzazione** di `AppleGraphicsDeviceControl`. Il target contiene già AGDC e Wrangler; l’ABI è identica a root2; il primo ostacolo irrisolto è ottenere un client autorizzato (entitlement firmato o esecuzione in WindowServer), non ricreare componenti Apple.

---

## 8. Primo ostacolo irrisolto e prossimo passo

### 8.1 Ostacolo

| Priorità | Ostacolo | Stato |
|---:|---|---|
| 1 | Autorizzazione `authorizeTask` per un harness locale | **BLOCKED** senza entitlement |
| 2 | Servizio AGDC attivo a runtime | **UNPROVEN** |
| 3 | Puntatore vtable `0x858` → Wrangler | **UNPROVEN** |
| 4 | Effetto `LoadHWServices` | **UNPROVEN** |
| 5 | Produttore userspace `0x2` | **UNPROVEN** |

**PROVEN:** l’ostacolo 1 è il primo blocco concreto; gli altri presuppongono un client autorizzato.
**PROVEN:** l’ABI e il codice non sono il problema.

### 8.2 Passo successivo concretamente risolvibile

1. Verificare staticamente la firma/entitlement di `WindowServer` e `SkyLight` nel target.
2. Verificare se esiste un processo Apple già autorizzato che apre AGDC (oltre ai tre client noti).
3. Se non esiste, il layer client-only non è ottenibile senza entitlement; l’alternativa è solo analisi, non esecuzione.
4. Non serve modificare SystemKC o costruire un kext.

**PROVEN:** il prossimo passo è statico e verificabile con `codesign`, `nm`, `strings`, `otool`.
**UNPROVEN:** l’esito (WindowServer potrebbe avere l’entitlement, ma non è stato verificato).

---

## 9. Stato delle prove

| Prova | Stato |
|---|---|
| Target/root2 `externalMethod` identici | **PROVEN** |
| Target/root2 `UserKernelTransfer` identici | **PROVEN** |
| Target/root2 `filtered` identici | **PROVEN** |
| Target/root2 `newUserClient` identici | **PROVEN** |
| Target/root2 `start` identici | **PROVEN** |
| `publishHda` differente | **PROVEN (18 byte)** |
| `start` imposta `IOUserClientClass` | **PROVEN statico** |
| `start` cerca `AppleGPUWrangler` | **PROVEN statico** |
| `newUserClient` chiama init/auth | **PROVEN; nomi INFERRED** |
| `authorizeTask` entitlement 1/2 | **PROVEN** |
| `agdc_entitle` boot-arg | **PROVEN statico** |
| WindowServer flag | **PROVEN statico** |
| WindowServer bypass autorizzazione | **UNPROVEN** |
| `filtered` selector 3 input 4 byte | **PROVEN** |
| `filtered` callback `[+0x858]` | **PROVEN** |
| Firma callback = Wrangler | **PROVEN** |
| Puntatore vtable → Wrangler | **UNPROVEN** |
| Wrangler test `0x2` | **PROVEN** |
| `LoadHWServices`/`LoadController`/`LoadAccelerator` | **PROVEN statico** |
| Runtime `LoadHWServices` | **UNPROVEN** |
| Servizio runtime | **UNPROVEN** |
| Produttore userspace `0x2` | **UNPROVEN** |

---

## 10. Diagnosi

| Priorità | Elemento | Stato |
|---:|---|---|
| 1 | AGDC nel target SystemKC | **PROVEN** |
| 2 | ABI target = root2 | **PROVEN per le funzioni critiche** |
| 3 | Comando 3 input 4 byte | **PROVEN** |
| 4 | Callback `0x858` con firma Wrangler | **PROVEN** |
| 5 | Wrangler imposta LoadHWServices | **PROVEN statico** |
| 6 | Autorizzazione harness | **BLOCKED** |
| 7 | Runtime servizio | **UNPROVEN** |
| 8 | Produttore `0x2` | **UNPROVEN** |

**Diagnosi:** il target ha la catena AGDC completa e la stessa ABI di root2. `newUserClient` crea il client solo dopo `initWithTask` e `authorizeTask`; `authorizeTask` richiede un entitlement privato o `agdc_entitle`. `filtered` comando 3 inoltra il buffer di 4 byte a `[vtable+0x858]`, la cui firma coincide con il Wrangler AMD, che interpreta `0x2` e imposta `LoadHWServices`. Il compatibility layer userspace non deve ricreare AGDC; deve superare l’autorizzazione. Questo è il primo ostacolo irrisolto.

---

## 11. Verdetto

| Domanda | Risposta |
|---|---|
| AGDC target presente | **SÌ — SystemKC, PROVEN** |
| Wrangler AMD target presente | **SÌ — SystemKC, PROVEN** |
| ABI target = root2 | **SÌ per le funzioni critiche — PROVEN** |
| `UserKernelTransfer` target | **0x13d41e60 — PROVEN** |
| `filtered` target | **0x13d407b0 — PROVEN** |
| `newUserClient` target | **0x13d41cbe — PROVEN** |
| `authorizeTask` entitlement | **PROVEN** |
| WindowServer bypass | **UNPROVEN** |
| Callback `0x858` | **PROVEN call site; target slot UNPROVEN** |
| Wrangler `0x2` → LoadHWServices | **PROVEN statico** |
| Harness senza entitlement | **non fattibile** |
| Harness con entitlement | **condizionato** |
| Sostituzione kernel | **non necessaria/bloccata** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il target 25G342 contiene AGDC e il Wrangler, e le funzioni ABI-critical sono byte-identiche a root2. `filtered` comando 3 richiede 4 byte, chiama `[vtable+0x858]` con la firma del Wrangler, e il Wrangler imposta `LoadHWServices`/`LoadController`/`LoadAccelerator` quando vede `0x2`. Il compatibility layer userspace minimo non richiede modifiche al kernel, ma è bloccato dall’autorizzazione: `authorizeTask` accetta solo i due entitlement privati o `agdc_entitle`; un harness locale non può auto-assegnarli. **Primo ostacolo irrisolto: autorizzazione/entitlement del client**, non l’ABI. T27 resta **OPEN**: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **14.124.612 KiB ≈ 13,47 GiB** liberi. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
