# T27 — AGENT-AMD — AGDC USER CLIENT / INPUT PRODUCER (169)

**Scope:** identificare il client AGDC che invia `doDeviceAttribute` con comando 3 e produce il buffer contenente `0x2`; cercare `IOConnectCallMethod`/`IOConnectCallStructMethod`; ricostruire i call site che raggiungono `filtered(api=2)` e `doDeviceAttribute`; identificare chi costruisce il buffer; esaminare AMD, AppleGraphicsControl e GPU plugin; confrontare 25G325, 25G342 e KDK 26B116.

**Modalità:** sola lettura. Nessun boot, trace, modifica, build o download. Comandi: `find`, `grep`, `nm`, `otool`, `strings`, `plutil`, `shasum`, `df`, `sw_vers`.

**Esito:** **PROVEN** che esiste un percorso user client completo: `AppleGraphicsDeviceControlClient::externalMethod` → `UserKernelTransfer(selector, state)` → `filtered_doDeviceAttribute(api=3, selector, ...)`. Il buffer non viene costruito dal kext: arriva da `IOExternalMethodArguments::structureInput`/`structureInputDescriptor` e viene inoltrato al comando 3; con `inSize=4` e primo byte `0x2` raggiunge il Wrangler AMD. **PROVEN** che questo percorso usa `api=3`, non `doDeviceAttribute(api=2)`. **INFERRED** che il produttore sia un client userspace privilegiato (WindowServer o GPUWrangler/AGDC client) che chiama `IOConnectCallMethod` con selettore 3 e structure input di 4 byte. **UNPROVEN** il processo esatto, il call site userspace e il valore runtime. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| AGDC root2 26.7.2/25G325 | `a3effd46c2c22692019da818ecab43703b44bcb5e2357c174d1b1546fcc633a3` |
| AGDC `Info.plist` root2 | `d521d429dbf95570ec5f6469d1286a846d30739be75e2fe1e1af6244431a5188` |
| AGDC KDK 27.2/26B116 | `ea39241b0c99dae2fb4dd81a33af0b36e1c0ffd1ad04283140ea51555486a1d7` |
| AGDC `Info.plist` target `/System` | `d521d429dbf95570ec5f6469d1286a846d30739be75e2fe1e1af6244431a5188` |
| `WindowServer` loader | `804cf101ec081e4f07946acaca35d694d8e9d48b25a12c5b4e1a6ce348c9000d` |
| `GPUWrangler.framework` `Info.plist` | `6d290a14ad04eaaa0d61c0eb668058471b39e2e4edfe287590c2fae8f2038c79` |
| X6000Framebuffer executable | `a2469429602210e64a74292a30b06353d9e0f75cd6b8b65f98324e64fa0b4536` |
| Report 168 | `62ff0faa201e4260f1ca663f7ae0535ed88693db5abe69092635aa83658a38eb` |

**Target osservato:** macOS `26.7.3`, build `25G342`.
**Stato AGDC target:** plist presente e byte-identico a root2; **eseguibile AGDC assente** (`0` file in `Contents/MacOS`).
**root2:** `26.7.2`, build `25G325`, AGDC `8.1.12`.
**KDK:** `27.2`, `26B116`.
**Spazio:** **15.410.328 KiB ≈ 14,70 GiB** > 10 GiB.

### 1.1 Ponte tra target e root2

| Evidenza | Stato |
|---|---|
| Plist AGDC target = root2 | **PROVEN byte-identico** (`d521…`) |
| Eseguibile AGDC target | **ASSENTE** |
| Eseguibile root2 | **PROVEN** (`a3eff…`) |
| `UserKernelTransfer` root2 0x2e60 | **PROVEN** |
| `UserKernelTransfer` KDK 0x2ec4 | **PROVEN, stessa struttura** |
| Equivalenza binaria target ↔ root2 | **UNPROVEN** |

**PROVEN:** il contratto AGDC del target è compatibile con root2 a livello di plist; non è prova dell'eseguibile.
**PROVEN:** root2 è l'unico binario AGDC 26.x disponibile.
**UNPROVEN:** che il codice 25G342 sia byte-identico a 25G325.

---

## 2. User client: `externalMethod`

### 2.1 Entry e stato

`AppleGraphicsDeviceControlClient::externalMethod` — root2 `0x6dc`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x6dc` | entry | `(selector, args, dispatch, target, ref)` |
| `0x6ed` | `movq %rdx, %r15` | salva `args` |
| `0x6f0` | `movl %esi, %r14d` | salva `selector` |
| `0x6f3` | `movq %rdi, %r13` | salva client |
| `0x6f6`–`0x73f` | copia campi client | prepara stato locale |
| `0x743` | `movq %rdx, -0x30(%rbp)` | **`args` dentro lo stato** |
| `0x796` | `movq 0xd8(%r13), %rdi` | controller AGDC |
| `0x79d` | `leaq -0x68(%rbp), %rdx` | stato locale |
| `0x7a1` | `movl %r14d, %esi` | selettore |
| `0x7a4` | `call UserKernelTransfer` | trasferimento |

**PROVEN:** lo stato locale parte da `-0x68`; `args` è memorizzato a `-0x30`, cioè **`state+0x38`**.
**PROVEN:** `externalMethod` non chiama `doDeviceAttribute` e non costruisce alcun buffer.
**PROVEN:** il selettore userspace viene passato invariato a `UserKernelTransfer`.

### 2.2 Controllo degli argomenti

Dopo il trasferimento, `externalMethod` valida gli output in `args`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x7cb` | `movq 0x20(%r15), %rax` | `scalarInput` |
| `0x7d4` | `cmpl $0x1, 0x28(%r15)` | `scalarInputCount == 1` |
| `0x7db` | `movq 0x48(%r15), %rcx` | `scalarOutput` |
| `0x7e4` | `cmpl $0x1, 0x50(%r15)` | `scalarOutputCount == 1` |
| `0x7eb` | `movl %r14d, %edx` | selettore |
| `0x7ee` | `cmpq %rdx, (%rax)` | primo scalare == selettore |
| `0x7f3` | `movl %r12d, (%rcx)` | risultato |

**PROVEN:** `externalMethod` richiede **1 scalare in input** e **1 scalare in output**.
**PROVEN:** il primo scalare deve essere uguale al selettore.
**PROVEN:** `IOConnectCallStructMethod` da solo (0 scalari) non supera `0x7d4`; il percorso richiede `IOConnectCallMethod`/analogo con 1 scalare e structure input.
**INFERRED:** il client usa una chiamata IOKit con `scalarInput={selector}`, `scalarOutput=1` e un structure input di 4 byte.

### 2.3 Layout `IOExternalMethodArguments`

Dal SDK kernel (15.4/26.5, layout identico):

| Offset | Campo |
|---:|---|
| `0x20` | `scalarInput` |
| `0x28` | `scalarInputCount` |
| `0x30` | `structureInput` |
| `0x38` | `structureInputSize` |
| `0x40` | `structureInputDescriptor` |
| `0x48` | `scalarOutput` |
| `0x50` | `scalarOutputCount` |
| `0x58` | `structureOutput` |
| `0x60` | `structureOutputSize` |
| `0x68` | `structureOutputDescriptor` |

**PROVEN:** gli offset usati da `UserKernelTransfer` coincidono con questa struttura.
**PROVEN:** il buffer può essere passato sia come puntatore (`structureInput`, `0x30`) sia come descrittore (`structureInputDescriptor`, `0x40`).
**UNPROVEN:** quale delle due forme usi il client reale.

---

## 3. `UserKernelTransfer`: api 3

### 3.1 Recupero di `args` e dei buffer

`AppleGraphicsDeviceControl::UserKernelTransfer` — root2 `0x2e60`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x2e60` | entry | `(selector, state)` |
| `0x2e7c` | `movq 0x38(%rdx), %r14` | `state+0x38` = **`args`** |
| `0x2e80` | `movq 0x40(%r14), %r15` | `structureInputDescriptor` |
| `0x2e84` | `movq 0x68(%r14), %rbx` | `structureOutputDescriptor` |
| `0x2e93` | `call *0x1c8` | lunghezza descrittore input |
| `0x2e9e` | `movl 0x60(%r14), %r12d` | fallback `structureOutputSize` |
| `0x2eb9` | `call *0x1c8` | lunghezza descrittore output |
| `0x2ec4` | `movl 0x38(%r14), %r15d` | fallback `structureInputSize` |
| `0x2f32`–`0x2f96` | mapping output | descrittore o `structureOutput` |
| `0x2fa0` | `movq 0x30(%r14), %rcx` | fallback `structureInput` |
| `0x2fac` | `leaq -0x68(%rbp), %rax` | output size locale |
| `0x2fb4` | `movl $0x3, %esi` | **`api = 3`** |
| `0x2fb9` | `movl -0x2c(%rbp), %edx` | selettore |
| `0x2fbc` | `movq %r15, %r8` | input size |
| `0x2fc3` | `call filtered_doDeviceAttribute` | dispatch |

**PROVEN:** `UserKernelTransfer` legge `args->structureInput`/`structureInputDescriptor` e la dimensione relativa.
**PROVEN:** chiama `filtered_doDeviceAttribute` con **`api=3`**, non con `api=2`.
**PROVEN:** il buffer del client non viene creato né modificato qui.
**PROVEN:** la dimensione massima accettata è `0x4000000` (64 MiB).
**UNPROVEN:** la forma esatta (puntatore o descrittore) usata dal client.

### 3.2 Correzione importante: `api=3`, non `doDeviceAttribute`

| Percorso | API | Metodo |
|---|---:|---|
| `setDeviceAttribute` / `getDeviceAttribute` | 1 | wrapper |
| `doDeviceAttribute` | **2** | metodo pubblico |
| `UserKernelTransfer` | **3** | user client |
| `filtered` | 1/2/3 | dispatcher |

**PROVEN:** il percorso user client **non passa da `doDeviceAttribute`**.
**PROVEN:** esso raggiunge direttamente `filtered` con `api=3`.
**PROVEN:** il comando 3 e il bit `0x2` possono quindi arrivare da un client userspace senza alcuna chiamata a `doDeviceAttribute`.
**UNPROVEN:** il caller del percorso `api=2` (plugin/kernel), che resta separato.

---

## 4. Comando 3 nel percorso api=3

Il ramo comando 3 di `filtered` è invariato:

| Indirizzo root2 | Istruzione | Significato |
|---:|---|---|
| `0x1cba` | `cmpl $0x3, %r13d` | selettore 3 |
| `0x1cbe` | `je 0x22f0` | ramo comando 3 |
| `0x22f0`–`0x230a` | validazione input | `inSize` 0/4, input non nullo |
| `0x2310`–`0x2332` | validazione output | `outSize` 0/4, output non nullo |
| `0x2350` | `testb $0x4, (%r10)` | bit HDA Apple |
| `0x236e` | `call publishHdaGfxProperties` | effetto HDA |
| `0x279f` | `call *0x858` | inoltro invariato al vendor |

**PROVEN:** il selettore 3 del client arriva allo stesso ramo del comando 3.
**PROVEN:** il buffer deve essere di 4 byte per superare la validazione.
**PROVEN:** il bit `0x2` non viene toccato; il bit `0x4` è solo l'effetto HDA.
**PROVEN:** il comando 3 viene inoltrato al callback `0x858`.
**INFERRED:** il Wrangler AMD riceve il buffer e legge `0x2`.
**UNPROVEN:** che il callback `0x858` del target punti al Wrangler.

---

## 5. Produttore del buffer

### 5.1 Cosa è provato

| Elemento | Stato |
|---|---|
| AGDC costruisce `0x2` | **NO — PROVEN** |
| AGDC modifica il buffer | **NO — PROVEN** |
| Buffer dal client userspace | **PROVEN via structureInput** |
| Forma del buffer | **4 byte** per comando 3 |
| Bit `0x2` nel primo byte | **PROVEN lato AMD; runtime UNPROVEN** |
| Processo che lo imposta | **UNPROVEN** |

**PROVEN:** il produttore è **fuori dal kext AGDC**, nel client che prepara `structureInput` prima della chiamata IOKit.
**PROVEN:** il kext si limita a trasportarlo.
**UNPROVEN:** l'istruzione userspace che scrive `0x2`.

### 5.2 Autorizzazione del client

`AppleGraphicsDeviceControlClient::initWithTask` — root2 `0x9b4`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0xa49` | `call _proc_selfpid` | PID |
| `0xa60` | `call _proc_selfname` | nome processo |
| `0xa69` | `leaq "WindowServer"` | confronto |
| `0xa73` | `call _strcmp` | nome == WindowServer |
| `0xa7a` | `sete 0x110(%rbx)` | flag WindowServer |

`authorizeTask` — root2 `0x7fe`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x866` | `leaq "com.apple.private.applegraphicsdevicecontrol"` | entitlement 1 |
| `0x870` | `call copyClientEntitlement` | verifica |
| `0x8a1` | `leaq "com.apple.private.gpuwrangler"` | entitlement 2 |
| `0x8ab` | `call copyClientEntitlement` | verifica |
| `0x8ce` | `cmpb $0, agdc_entitle` | override boot-arg |

**PROVEN:** WindowServer è riconosciuto esplicitamente.
**PROVEN:** sono accettati i due entitlement AGDC/GPU.
**PROVEN:** un client senza entitlement può essere bloccato con `AGDCC: Unauthorized client`.
**INFERRED:** il client reale è WindowServer o un processo con uno dei due entitlement.
**UNPROVEN:** quale processo invii il selettore 3 con `0x2`.

### 5.3 Candidati nel sistema 26.7.3

| Candidato | Evidenza | Stato |
|---|---|---|
| `WindowServer` | loader `SLXServer`, 154 KiB, nessuna stringa AGDC | **possibile, non provato** |
| `SkyLight` | codice effettivo in dyld cache | **non ispezionato** |
| `GPUWrangler.framework` | plist `8.1.12`, `BuildAliasOf=AppleGraphicsControl`; binario in dyld cache | **candidato forte** |
| `AppleGraphicsControl.kext` | codice kernel, non client | **escluso come produttore** |
| `AMDRadeonX6000Framebuffer` | consumatore, non produttore | **escluso** |

**PROVEN:** `WindowServer` è solo un loader; la logica è in `SkyLight` (`SLXServer`).
**PROVEN:** `GPUWrangler.framework` non contiene un binario standalone nel bundle; l'immagine è nella shared cache.
**PROVEN:** la mappa della cache elenca `GPUWrangler` e `SkyLight`.
**UNPROVEN:** un riferimento diretto a `AppleGraphicsDeviceControl` o al selettore 3 in queste immagini.

### 5.4 Ricerca nella shared cache

| Ricerca | Esito |
|---|---|
| `GPUWrangler` nella mappa cache | **PROVEN presente** |
| `AppleGraphicsDeviceControl` nella cache principale | **0 occorrenze** |
| `AGDC` nella cache principale | **0 occorrenze** |
| `IOConnectCallStructMethod` nella cache principale | **0 occorrenze** |
| Subcache complete | **non completate per timeout** |

**PROVEN:** la stringa del servizio non compare nella cache principale.
**UNPROVEN:** un riferimento nelle subcache o in un'immagine non estratta.
**NOTA:** l'assenza di stringa non dimostra assenza di chiamata: il nome può essere costruito o risolto via `IOServiceOpen` con un simbolo diverso.

---

## 6. Confronto versioni

| Build | AGDC SHA | `DTSDKBuild` | `externalMethod` | `UserKernelTransfer` |
|---|---|---|---:|---:|
| target 26.7.3 | **assente** | 25G325 (plist) | **UNPROVEN** | **UNPROVEN** |
| root2 26.7.2 | `a3eff…` | 25G325 | `0x6dc` | `0x2e60` |
| KDK 27.2 | `ea392…` | 26B116 | `0x6dc` | `0x2ec4` |

**PROVEN:** root2 e KDK hanno la stessa struttura di `UserKernelTransfer` e gli stessi offset `0x38/0x40/0x60/0x68`.
**PROVEN:** il plist target è identico a root2.
**UNPROVEN:** l'eseguibile target 25G342.

---

## 7. Catena userspace ricostruita

```text
client userspace (WindowServer / GPUWrangler / AGDC client)
  ├─ costruisce structureInput[4] = { bitmask }
  │    └─ imposta 0x2 nella prima parola
  └─ IOConnectCallMethod(connection, selector=3,
        scalarInput={3}, scalarInputCount=1,
        structureInput=in, structureInputSize=4,
        scalarOutput=&ret, scalarOutputCount=1)
       └─ AppleGraphicsDeviceControlClient::externalMethod(selector=3, args)
            └─ UserKernelTransfer(3, state)
                 └─ filtered_doDeviceAttribute(api=3, cmd=3,
                      in, 4, out, outSize, state)
                      ├─ validazione 4 byte
                      ├─ se in[0] & 0x4: publishHdaGfxProperties
                      └─ call *0x858(cmd=3, in, 4, ...)
                           └─ AmdGpuWrangler::vendor_doDeviceAttribute
                                └─ se in[0] & 0x2:
                                     setProperty("LoadHWServices", true)
```

**PROVEN:** il percorso dal client a `filtered(api=3)` esiste.
**PROVEN:** il buffer non viene creato dal kext.
**INFERRED:** il client usa `IOConnectCallMethod`, non `IOConnectCallStructMethod` da solo.
**UNPROVEN:** il client concreto e il valore `0x2`.

---

## 8. Perché `IOConnectCallStructMethod` da solo non basta

| Metodo userspace | Scalar input | Structure input | Supera `externalMethod`? |
|---|---:|---:|---|
| `IOConnectCallMethod` con 1 scalare | **1** | sì | **sì, previsto** |
| `IOConnectCallStructMethod` | **0** | sì | **no: `0x7d4` richiede 1** |
| `IOConnectCallScalarMethod` | 1 | no | **no: manca il buffer** |

**PROVEN:** `externalMethod` richiede almeno uno scalare in input.
**PROVEN:** il selettore deve essere il primo scalare.
**INFERRED:** la forma corretta è `IOConnectCallMethod` con scalare 3 + structure input di 4 byte.
**UNPROVEN:** la funzione userspace esatta.

---

## 9. Prova minima necessaria

| Prova | Cosa dimostra | Stato |
|---|---|---|
| call site userspace del selettore 3 | chi invia il comando | **ASSENTE** |
| inizializzazione del buffer con `0x2` | produttore effettivo | **ASSENTE** |
| `ioreg` con `LoadHWServices=true` | effetto runtime | **ASSENTE** |
| binario AGDC 25G342 | equivalenza target | **ASSENTE** |
| trace AGDC | sequenza reale | **VIETATO** |

**PROVEN:** la prova mancante non è più nel kernel AGDC: è nel client userspace.
**UNPROVEN:** l'identità del client.

---

## 10. Diagnosi

| Priorità | Elemento | Stato |
|---:|---|---|
| 1 | user client `externalMethod` | **PROVEN** |
| 2 | `UserKernelTransfer` api=3 | **PROVEN** |
| 3 | structure input 4 byte | **PROVEN** |
| 4 | comando 3 e inoltro | **PROVEN** |
| 5 | bit `0x2` non creato da AGDC | **PROVEN** |
| 6 | client userspace | **INFERRED** |
| 7 | processo e call site | **UNPROVEN** |
| 8 | runtime target | **UNPROVEN** |

**Diagnosi:** il comando 3 non richiede `doDeviceAttribute`: il client userspace passa da `externalMethod` e `UserKernelTransfer(api=3)`. Il buffer a 4 byte è un structure input del client; AGDC lo valida e lo inoltra. La catena è quindi chiusa fino al confine userspace, ma non è identificato il processo che imposta `0x2`.

---

## 11. Verdetto

| Domanda | Risposta |
|---|---|
| Esiste un percorso user client? | **SÌ — PROVEN** |
| Metodo | `externalMethod` → `UserKernelTransfer` |
| API | **3** |
| Metodo pubblico `doDeviceAttribute` | **non usato da questo percorso** |
| Buffer costruito da AGDC? | **NO** |
| Buffer dal client? | **SÌ — structureInput** |
| Dimensione comando 3 | **4 byte** |
| Bit `0x2` trasportato | **SÌ** |
| Client concreto | **UNPROVEN** |
| Target 25G342 runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il client AGDC esiste ed è un **user client**: `externalMethod` inoltra il selettore a `UserKernelTransfer`, che chiama `filtered(api=3)` con il buffer proveniente da `structureInput`/`structureInputDescriptor`. Il comando 3 richiede 4 byte e il bit `0x2` attraversa AGDC invariato. Il kext non è il produttore: il bit deve essere scritto dal client userspace prima di `IOConnectCallMethod`. Restano **UNPROVEN** il processo concreto (WindowServer, GPUWrangler o altro client entitlement), il call site e il valore runtime sul target 25G342. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **15.410.328 KiB ≈ 14,70 GiB** > 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
