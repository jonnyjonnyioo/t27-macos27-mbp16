# T27 — OOB AGDC — SkyLight nella dyld shared cache — Report 178

**Data:** 17 novembre 2026
**Sistema:** macOS 26.7.3 build 25G342, MacBookPro16,1
**Modalità:** sola analisi statica; nessun boot, trace, modifica, build o download.
**Vincolo spazio:** minimo 10 GiB liberi; nessun file eliminabile proposto.
**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**

---

## 1. Oggetto e hash

Cache:

```text
/System<VOLUME>/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_x86_64h
subcache .01–.06, .map, .atlas
timestamp: 6 novembre 2026 06:12
```

SkyLight estratto con:

```sh
ipsw dyld extract \
  /System<VOLUME>/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_x86_64h \
  SkyLight --stubs -o .tmp/a178
```

File:

```text
HAO-PROJECT/T27/AGENT-AMD/.tmp/a178/SkyLight
SHA-256: 1e8ead0ceaf2b8a2fe2c167fa299142939ec579f9df60ab30dae8a5c513bea56
dimensione: 8.058.408 byte
architettura: Mach-O 64-bit dynamically linked shared library x86_64
```

Target:

```text
/System/Library/KernelCollections/SystemKernelExtensions.kc
SHA-256: b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7
```

WindowServer:

```text
/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/Resources/WindowServer
SHA-256: 804cf101ec081e4f07946acaca35d694d8e9d48b25a12c5b4e1a6ce348c9000d
```

Report:

```text
HAO-PROJECT/T27/AGENT-AMD/T27-OOB-AGDC-SKYLIGHT-178.md
```

---

## 2. Metodo

1. estrazione del solo dylib SkyLight dalla cache, senza estrarre l'intera cache;
2. verifica di architettura, hash, import e stringhe;
3. scansione di tutti i call site `IOConnectCallMethod`, `IOConnectCallStructMethod` e `IOConnectCallScalarMethod`;
4. ricostruzione della callback table che SkyLight passa a CoreDisplay;
5. risoluzione del callback usato da `WSAGDCSetDebugOptions`;
6. verifica dell'entitlement del processo che ospita SkyLight.

**Limite:** l'analisi è statica. Le chiamate indirette e le virtual dispatch non sono state eseguite. I risultati runtime restano **UNPROVEN**.

---

## 3. Import e stringhe

### 3.1 Import IOKit

`nm -m` mostra:

```text
(undefined) external _IOConnectCallScalarMethod (from IOKit)
(undefined) external _IOConnectMapMemory (from IOKit)
(undefined) external _IOConnectSetNotificationPort (from IOKit)
(undefined) external _IOMasterPort (from IOKit)
(undefined) external _IOServiceAddMatchingNotification (from IOKit)
(undefined) external _IOServiceClose (from IOKit)
(undefined) external _IOServiceGetBusyState (from IOKit)
(undefined) external _IOServiceGetMatchingService (from IOKit)
(undefined) external _IOServiceGetMatchingServices (from IOKit)
(undefined) external _IOServiceMatching (from IOKit)
(undefined) external _IOServiceOpen (from IOKit)
(undefined) external _IOServiceRequestProbe (from IOKit)
(undefined) external _IOServiceWaitQuiet (from IOKit)
```

**PROVEN:** SkyLight importa `IOConnectCallScalarMethod`, ma **non** importa `IOConnectCallMethod` né `IOConnectCallStructMethod`.

### 3.2 Stringhe dei servizi

Conteggio esatto nel binario:

```text
AppleGraphicsDeviceControl            0
AppleGraphicsControl                  1
AppleGraphicsPowerManagement          0
AGPM                                  0
AGDC                                  0
```

**PROVEN:** SkyLight non contiene il nome del servizio AGDC (`AppleGraphicsDeviceControl`) e non contiene i letterali `AGDC`/`AGPM`.
**PROVEN:** l'unica stringa grafica di servizio è `AppleGraphicsControl`, che è un servizio diverso da `AppleGraphicsDeviceControl`.

### 3.3 Import CoreDisplay AGDC

```text
(undefined) external _WSAGDCSetDebugOptions (from CoreDisplay)
```

**PROVEN:** questo è l'unico simbolo con nome AGDC importato da SkyLight.
**PROVEN:** `WSAGDCSetDebugOptions` non è un call site IOKit; è un wrapper CoreDisplay. Il suo comportamento è analizzato nella sezione 5.

---

## 4. Call site IOKit in SkyLight

### 4.1 Method/Struct

```text
IOConnectCallMethod:       0
IOConnectCallStructMethod: 0
```

**PROVEN:** SkyLight non ha alcun call site `IOConnectCallMethod`/`IOConnectCallStructMethod`.
**PROVEN:** non può inviare direttamente un comando AGDC attraverso queste due API.

### 4.2 Scalar

SkyLight ha esattamente **2** call site `IOConnectCallScalarMethod`.

#### Primo: `_AGPMSetBoost`

```asm
_AGPMSetBoost:
0x7ff8092020cb  pushq %rbp
...
0x7ff8092020dc  movl $0x1c90,%esi          ; selector 0x1c90
0x7ff8092020e1  movl $0x1,%ecx
0x7ff8092020e6  xorl %r8d,%r8d
0x7ff8092020e9  xorl %r9d,%r9d
0x7ff8092020ec  callq _IOConnectCallScalarMethod
```

**PROVEN:** il selettore è `0x1c90`, non 3.
**PROVEN:** il nome della funzione è `AGPMSetBoost`; il percorso è AppleGraphicsPowerManagement/boost, non AGDC.

#### Secondo: `_SLSInitialize_block_invoke`

```asm
0x7ff809595121  leaq "AppleGraphicsControl",%rdi
0x7ff809595128  callq _IOServiceMatching
...
0x7ff809595179  callq _IOServiceOpen
...
0x7ff809595182  movl -0x24(%rbp),%edi
0x7ff809595185  xorl %esi,%esi              ; selector 0
0x7ff809595187  xorl %edx,%edx
0x7ff809595189  xorl %ecx,%ecx
0x7ff80959518b  xorl %r8d,%r8d
0x7ff80959518e  xorl %r9d,%r9d
0x7ff809595191  callq _IOConnectCallScalarMethod
```

**PROVEN:** il servizio è `AppleGraphicsControl`, non `AppleGraphicsDeviceControl`.
**PROVEN:** il selettore è 0, non 3.
**PROVEN:** il secondo `IOServiceOpen` usa tipo 1, ma non invia il selettore 3.

### 4.3 Conclusione sui call site

| API | Numero | Selettori | AGDC selector 3 |
|---|---:|---|---|
| `IOConnectCallMethod` | 0 | — | **NO** |
| `IOConnectCallStructMethod` | 0 | — | **NO** |
| `IOConnectCallScalarMethod` | 2 | `0x1c90`, 0 | **NO** |
| `IOServiceOpen` | 6 | servizi vari | **NO** |
| `IOServiceMatching` | 5 | `AppleGraphicsControl` e altri | **NO** |

**PROVEN:** SkyLight non invia direttamente AGDC selector 3.
**PROVEN:** nessuno dei suoi call site IOKit diretti appartiene a `AppleGraphicsDeviceControl`.

---

## 5. Il percorso `WSAGDCSetDebugOptions`

### 5.1 Call site in SkyLight

L'unico riferimento è:

```text
0x7ff8095094b4  jmp _WSAGDCSetDebugOptions
```

È dentro:

```text
WS::Displays::CoreDisplayManager::set_debug_options(unsigned int, void*, unsigned long)
0x7ff809509396
```

La funzione riceve un codice debug in `esi`, lo salva in `ebx`, e usa una serie di branch per distribuire i vari debug option. Il ramo che raggiunge `WSAGDCSetDebugOptions` è a `0x7ff809509494`:

```asm
0x7ff809509494  movq 0x36b4a2bd(%rip),%rax
0x7ff80950949b  movq (%rax),%rax
0x7ff80950949e  cmpq -0x20(%rbp),%rax
0x7ff8095094a2  jne 0x7ff809509733
0x7ff8095094a8  movl %ebx,%edi
...
0x7ff8095094b4  jmp _WSAGDCSetDebugOptions
```

**PROVEN:** il chiamante passa il codice debug in `edi`; il wrapper CoreDisplay poi lo ignora e imposta `edi=1`.

### 5.2 Wrapper CoreDisplay

```asm
_WSAGDCSetDebugOptions:
0x7ff80539e038  pushq %rbp
0x7ff80539e039  movq %rsp,%rbp
0x7ff80539e03c  movl $0x1,%edi
0x7ff80539e041  popq %rbp
0x7ff80539e042  jmpq *0x3e73b5c0(%rip)
```

Il target RIP-relativo è:

```text
0x7ff843ad9608
```

**PROVEN:** il wrapper non chiama `IOConnectCallMethod`, `IOConnectCallStructMethod` o `IOConnectCallScalarMethod`.
**PROVEN:** il wrapper esegue un tail-jump a un function pointer in `gWSCallbacks+0x628`.

### 5.3 `gWSCallbacks` e la callback table di SkyLight

CoreDisplay inizializza `gWSCallbacks` in `_InitializeCoreDisplay`:

```asm
_InitializeCoreDisplay:
0x7ff8054166f3  pushq %rbp
0x7ff8054166f4  movq %rsp,%rbp
0x7ff8054166f7  leaq gWSCallbacks(%rip),%rdi
0x7ff8054166fe  leaq 0x10(%rbp),%rsi
0x7ff805416702  movl $0x6b8,%edx
0x7ff805416707  callq memcpy
...
```

`gWSCallbacks` è a:

```text
0x7ff843ad8fe0
```

SkyLight costruisce la tabella sorgente in `___WSCDInitializeVtable_block_invoke`:

```asm
0x7ff8096103d3  leaq WSCDInitializeVtable.callbacks(%rip),%rsi
0x7ff8096103da  movl $0xd7,%ecx
0x7ff8096103df  movq %rsp,%rdi
0x7ff8096103e2  rep movsq (%rsi),(%rdi)
0x7ff8096103e5  callq _InitializeCoreDisplay
```

La tabella è a:

```text
WSCDInitializeVtable.callbacks = 0x7ff840ade020
dimensione copiata = 0xd7 * 8 = 0x6b8 = 1720 byte
```

**PROVEN:** SkyLight copia la propria tabella di 1720 byte e la passa a `InitializeCoreDisplay`.
**PROVEN:** `InitializeCoreDisplay` copia la stessa dimensione in `gWSCallbacks`.

### 5.4 Valore dello slot `+0x628`

L'entry della tabella a `+0x628` è:

```text
raw:     0x000002000930258f
decoded: 0x7ff80930258f
simbolo: _CGXUpdateDesktop
```

La decodifica usa il formato chained-fixup x86_64 della cache:

```text
target = 0x7ff800000000 | (raw & 0xffffffff)
```

Quindi:

```text
gWSCallbacks + 0x628
  = 0x7ff843ad8fe0 + 0x628
  = 0x7ff843ad9608
  = &_CGXUpdateDesktop
```

**PROVEN:** `WSAGDCSetDebugOptions` non arriva a una funzione AGDC; arriva a `_CGXUpdateDesktop`.
**PROVEN:** la catena statica è:

```text
SkyLight CoreDisplayManager::set_debug_options
  -> WSAGDCSetDebugOptions (CoreDisplay)
  -> gWSCallbacks+0x628
  -> CGXUpdateDesktop (SkyLight)
```

**PROVEN:** questa catena non contiene un invio del selettore 3.

### 5.5 Corpo di `CGXUpdateDesktop`

`_CGXUpdateDesktop` a `0x7ff80930258f` esegue:

```text
call WSDisableUpdateInternalToken
CFRelease
call WS::Displays::CDManager()
call *0xe8(%rcx)              ; virtual dispatch sul CDManager
call WSReenableUpdateInternalToken
```

Non contiene:

```text
IOConnectCallMethod
IOConnectCallStructMethod
IOConnectCallScalarMethod
WSAGDCSetDebugOptions
AppleGraphicsDeviceControl
AGDC selector 3
```

**PROVEN:** nel corpo di `CGXUpdateDesktop` non c'è alcun call site IOKit e nessun riferimento ad AGDC.
**UNPROVEN:** il virtual dispatch `*0xe8(%rcx)` potrebbe, a runtime, raggiungere codice non visibile staticamente; non è stata trovata alcuna evidenza che lo faccia e non è un percorso AGDC documentato.

### 5.6 Perché il nome è fuorviante

`WSAGDCSetDebugOptions` è un simbolo esportato da CoreDisplay, ma nel codice disponibile non è un setter AGDC: è un tail-jump a `CGXUpdateDesktop`. Il nome suggerisce un comando AGDC, ma la sua implementazione statica non invia alcun selettore AGDC.

**PROVEN:** l'unico effetto statico osservabile è l'aggiornamento del desktop tramite `CGXUpdateDesktop`.
**UNPROVEN:** eventuali effetti collaterali runtime del virtual dispatch interno.

---

## 6. `_SLXServer` e raggiungibilità

`_SLXServer` è a:

```text
0x7ff8092e6301
```

È l'entry esportata usata da WindowServer. La funzione è grande e gestisce il bootstrap del server, il parsing di `-debug`, `console`, `-daemon`, `-exit`, `-virtual`, `-virtualonly`, safe mode e l'inizializzazione del server.

La tabella `WSCDInitializeVtable.callbacks` viene installata dal block `___WSCDInitializeVtable_block_invoke` a `0x7ff8096103c8`. Il block non ha un chiamante diretto nel testo; è un blocco di inizializzazione della tabella, richiamato dal percorso di inizializzazione SkyLight.

**PROVEN:** `_SLXServer` non contiene un call site diretto a `WSAGDCSetDebugOptions`.
**PROVEN:** `WSAGDCSetDebugOptions` è chiamato solo da `CoreDisplayManager::set_debug_options` a `0x7ff8095094b4`.
**INFERRED:** la tabella `WSCDInitializeVtable.callbacks` viene installata durante l'inizializzazione di SkyLight, quindi il percorso è raggiungibile dal processo WindowServer che ospita SkyLight.
**UNPROVEN:** la catena esatta `_SLXServer -> ... -> CoreDisplayManager::set_debug_options` non è stata dimostrata con un call graph completo; il chiamante di `set_debug_options` non è stato ricostruito e non è un ramo diretto osservato di `_SLXServer`.

Anche assumendo la raggiungibilità, il percorso termina in `CGXUpdateDesktop` e non invia il selettore 3.

---

## 7. Entitlement e processo ospite

WindowServer è firmato Apple:

```text
Identifier=com.apple.WindowServer
Authority=macOS Software Signing
Authority=Apple Code Signing Certification Authority
Authority=Apple Root CA
Signed Time=12 Oct 2026 at 12:18:02
Format=Mach-O universal (x86_64 arm64e)
```

Entitlement rilevanti:

```text
com.apple.private.gpuwrangler = true
com.apple.private.iokit.displayservice = true
com.apple.private.iokit.rootdomain-set-property = true
com.apple.private.iomfb.set-block = true
com.apple.private.iomfb.set-block-client-profile = true
```

**PROVEN:** WindowServer ha `com.apple.private.gpuwrangler`.
**PROVEN:** non è presente un entitlement chiamato `agdc_entitle`.
**PROVEN:** WindowServer non importa IOKit direttamente; usa `_SLXServer`.
**INFERRED:** SkyLight esegue nel processo WindowServer e ne eredita l'autorizzazione; non è un processo autonomo.
**PROVEN:** il dylib SkyLight estratto dalla cache non ha una firma standalone (`code object is not signed at all`); la firma è quella della cache/OS, non del singolo file estratto.

Il punto autorizzativo non è quindi “SkyLight ha l'entitlement AGDC”: **SkyLight non è un processo** e non contiene il servizio AGDC. L'autorizzazione resta in capo a WindowServer, che però non ha un call site IOKit diretto e non invia il selettore 3 nel percorso SkyLight disponibile.

---

## 8. Confronto con i report precedenti

| Elemento | Report 177 | Report 178 |
|---|---|---|
| SkyLight disponibile | no, BLOCKED | **sì, estratto e analizzato** |
| SkyLight hash | assente | **1e8ead0c…** |
| SkyLight `IOConnectCallMethod` | non verificabile | **0** |
| SkyLight `IOConnectCallStructMethod` | non verificabile | **0** |
| SkyLight `IOConnectCallScalarMethod` | non verificabile | **2: 0x1c90, 0** |
| SkyLight stringa AGDC | non verificabile | **0 occorrenze** |
| SkyLight `WSAGDCSetDebugOptions` | non verificabile | **importato; termina in CGXUpdateDesktop** |
| WindowServer IOKit diretto | 0 | **0** |
| CoreDisplay AGDC selector 0x10 | PROVEN | invariato |
| IOPresentment selector 3 | NO, PROVEN | invariato |
| Percorso AGDC selector 3 | non trovato | **non trovato; il solo wrapper AGDC è un update desktop** |

---

## 9. Verdetto

| Domanda | Esito |
|---|---|
| SkyLight è estraibile dalla cache 25G342 | **SÌ, PROVEN** |
| SkyLight ha `IOConnectCallMethod` | **NO, PROVEN** |
| SkyLight ha `IOConnectCallStructMethod` | **NO, PROVEN** |
| SkyLight ha `IOConnectCallScalarMethod` | **SÌ, 2 call site** |
| I due selettori Scalar sono 3 | **NO, PROVEN: 0x1c90 e 0** |
| SkyLight usa `AppleGraphicsDeviceControl` | **NO, PROVEN** |
| SkyLight usa `AppleGraphicsControl` | **SÌ, servizio diverso** |
| SkyLight chiama `WSAGDCSetDebugOptions` | **SÌ, una volta** |
| Quel wrapper invia AGDC selector 3 | **NO, PROVEN** |
| Dove termina quel wrapper | **`CGXUpdateDesktop`** |
| `CGXUpdateDesktop` contiene IOKit/AGDC | **NO, PROVEN** |
| Esiste un percorso Apple disponibile al selettore 3 | **NO, non trovato** |
| Resta un percorso virtuale non verificabile | **UNPROVEN** |
| T27 | **OPEN — 94% engineering / 32% first boot / 8% desktop** |

**Risposta netta:** l'analisi di SkyLight elimina il principale punto cieco del report 177. SkyLight non importa `IOConnectCallMethod`/`IOConnectCallStructMethod`, non contiene `AppleGraphicsDeviceControl`, e i suoi due soli call site Scalar usano i selettori `0x1c90` e `0` su servizi non AGDC. L'unico simbolo AGDC importato, `WSAGDCSetDebugOptions`, è un wrapper CoreDisplay che passa per `gWSCallbacks+0x628`; la tabella installata da SkyLight mappa quello slot a `CGXUpdateDesktop`, che non invia IOKit. Non esiste quindi un percorso statico SkyLight -> AGDC selector 3.

**Primo ostacolo residuo:** non è più l'assenza di SkyLight. È che nessun attore Apple disponibile invia il selettore 3: WindowServer è autorizzato ma non ha IOKit diretto; SkyLight usa solo `AppleGraphicsControl`/AGPM e un wrapper AGDC che termina in `CGXUpdateDesktop`; CoreDisplay usa AGDC `1`/`0x10`; IOPresentment usa `0x711`/`0x713`/`0x921`/`0x925`/`0x988`/`0x980`.

**Limite residuo del compatibility layer isolato:** un layer client-only può essere autorizzato da WindowServer solo se esiste un attore che invii il selettore 3. La static analysis non lo trova. Restano non verificabili solo effetti runtime di virtual dispatch (`CGXUpdateDesktop` -> `*0xe8(%rcx)`) e API private non osservate; non sono state trovate evidenze che raggiungano AGDC.

**Spazio:** **14.383.128 KiB ≈ 13,72 GiB** liberi (verificato dopo l'estrazione e l'analisi). Nessuna cancellazione; nessun file eliminabile proposto.
**STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
