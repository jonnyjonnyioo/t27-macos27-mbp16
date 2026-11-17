# T27 — OOB AGDC — Call site Apple e ricerca del selettore 3 — Report 177

**Data:** 17 novembre 2026
**Sistema:** macOS 26.7.3 build 25G342, MacBookPro16,1
**Modalità:** sola analisi statica; nessun boot, trace, modifica, build o download.
**Vincolo spazio:** minimo 10 GiB liberi; nessun file eliminabile proposto.
**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**

---

## 1. Ambiente e SHA-256

Target:

```text
/System/Library/KernelCollections/SystemKernelExtensions.kc
SHA-256: b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7
```

Componenti analizzati:

```text
WindowServer
  SHA-256: 804cf101ec081e4f07946acaca35d694d8e9d48b25a12c5b4e1a6ce348c9000d
  /System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/Resources/WindowServer

CoreDisplay
  SHA-256: d1d038dd7f88191d47db381ce776f7837d12408439d19f279c393c847c7c64fc
  estratto: HAO-PROJECT/T27/AGENT-AMD/.tmp/a73/01_CoreDisplay

IOPresentment (ausiliario)
  SHA-256: f07a31ec7774aee56efe62edd9f96ebb07cf72926eee8e0e089b65777ae9ecce
  estratto: HAO-PROJECT/T27/AGENT-AMD/.tmp/a73/11_IOPresentment
```

Report:

```text
HAO-PROJECT/T27/AGENT-AMD/T27-OOB-AGDC-APPLE-CALLSITES-177.md
```

Comandi usati: `nm`, `otool`, `lipo`, `strings`, `llvm-objdump`/disassemblaggi già presenti, `python3`, `sha256sum`, `shasum -a 256`.

---

## 2. Metodo e limiti

La ricerca è stata fatta su tre livelli:

1. import diretti di `IOConnectCallMethod` e `IOConnectCallStructMethod`;
2. call site con il selettore immediato scritto in `esi` prima della call;
3. ricostruzione del contenitore (funzione e servizio IOKit) per separare AGDC da IOFramebuffer, IOPresentment, GPUWrangler e altri servizi.

Il selettore di `IOConnectCallMethod`/`IOConnectCallStructMethod` è il secondo argomento, cioè `esi` nella convenzione SysV x86_64.

**Limite importante:** `SkyLight` non ha un binario standalone nel framework; la directory contiene solo `Resources` e `_CodeSignature`, senza `SkyLight`. Non è quindi possibile enumerare staticamente i suoi call site. Il report distingue sempre ciò che è stato letto da ciò che resta non disponibile.

---

## 3. WindowServer

### 3.1 Import diretti

Slice x86_64 analizzata:

```text
HAO-PROJECT/T27/AGENT-AMD/.tmp/WindowServer.x86_64
SHA-256: 3a27afe3a84561dad412d917764d571f9915f85e4925e9a9a57900b6edb9e110
```

`nm -m` sul slice x86_64 mostra un solo import:

```text
(undefined) external _SLXServer (from SkyLight)
```

`otool -L` mostra solo:

```text
/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight
/usr/lib/libSystem.B.dylib
```

**PROVEN:** WindowServer non importa `IOConnectCallMethod`, `IOConnectCallStructMethod`, `IOServiceOpen` o altre funzioni IOKit.
**PROVEN:** WindowServer non contiene call site diretti a IOKit.
**PROVEN:** WindowServer non contiene i letterali `AppleGraphicsDeviceControl`, `AGDC`, `DisplayPolicy` o `gpuwrangler` nel slice x86_64.
**PROVEN:** l'unico ingresso diretto di WindowServer è `_SLXServer`, cioè il bootstrap di SkyLight.

Qualsiasi percorso verso AGDC da WindowServer deve quindi passare da SkyLight o da un'API CoreDisplay caricata indirettamente; non è un call site IOKit di WindowServer.

---

## 4. SkyLight

### 4.1 Disponibilità

```text
ls -l /System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight
No such file or directory
```

La directory `Versions/A` contiene:

```text
Resources
_CodeSignature
```

**PROVEN:** SkyLight non è presente come Mach-O standalone nel framework.
**UNPROVEN/BLOCKED:** i call site di SkyLight non sono enumerabili con `nm`/`otool` sul solo framework. Il codice è nella dyld shared cache e non è stato estratto in questa sessione.

Non viene quindi affermato che SkyLight non invii il selettore 3: viene affermato che **non è verificabile staticamente con i file disponibili**.

---

## 5. CoreDisplay: inventario completo Method/Struct

CoreDisplay importa:

```text
_IOConnectCallMethod
_IOConnectCallStructMethod
_IOConnectCallScalarMethod
_IOConnectAddClient
_IOServiceOpen
```

Il seguente inventario copre **tutti** i call site `IOConnectCallMethod` e `IOConnectCallStructMethod` del binario estratto: **34** call site (30 Method, 4 Struct). Il selettore è il valore immediato in `esi`; `None` significa che lo scanner non ha encontato un immediato nel finestra precedente e richiede lettura manuale.

| # | Indirizzo | Tipo | Selector | Funzione contenitrice | Servizio |
|---:|---|---|---:|---|---|
| 1 | `0x7ff80535e786` | Method | 18 (0x12) | `_IOFBGetAttributeForFramebufferjjjPj` | IOFramebuffer |
| 2 | `0x7ff80535f0ae` | Method | 2 | `IOFBRebuild(IOFBConnect*, unsigned char)` | IOFramebuffer |
| 3 | `0x7ff80535f8cf` | Method | 2 | `IOFBRebuild(IOFBConnect*, unsigned char)` | IOFramebuffer |
| 4 | `0x7ff80535fd16` | Method | 2 | `IOFBProcessConnectChange(IOFBConnect*)` | IOFramebuffer |
| 5 | `0x7ff80535fee3` | Method | 11 (0x0B) | `_IOFBSetGamma` | IOFramebuffer |
| 6 | `0x7ff80536017a` | Method | 4 | `_IOFBSetDisplayModeAndDepth` | IOFramebuffer |
| 7 | `0x7ff80536037e` | Method | 19 (0x13) | `_IOFBSetAttributeForFramebuffer` | IOFramebuffer |
| 8 | `0x7ff80536051d` | Method | 2 | `IOFBResetTransform(IOFBConnect*)` | IOFramebuffer |
| 9 | `0x7ff80536068d` | Method | 1 | `_IOFBGetPixelInformation(...)` | IOFramebuffer |
| 10 | `0x7ff805360be2` | Method | 2 | `IOFBBuildModeList(IOFBConnect*, unsigned char)` | IOFramebuffer |
| 11 | `0x7ff805360d4f` | Method | 6 | `IOFBBuildModeList(IOFBConnect*, unsigned char)` | IOFramebuffer |
| 12 | `0x7ff80536100a` | Method | 7 | `IOFBBuildModeList(IOFBConnect*, unsigned char)` | IOFramebuffer |
| 13 | `0x7ff8053634db` | Method | 5 | `IOFBCreateDisplayModeInformation(...)` | IOFramebuffer |
| 14 | `0x7ff805364b2f` | Struct | 17 (0x11) | `_IOFBDriverPreflight` | IOFramebuffer |
| 15 | `0x7ff805364e28` | Method | 2 | `_IOFBCreateSharedCursor` | IOFramebuffer |
| 16 | `0x7ff80536521a` | Method | 2 | `_IOFBCreateSharedCursor` | IOFramebuffer |
| 17 | `0x7ff8053654fd` | Method | None/dinamico | `_IOFBCreateSharedCursor` | IOFramebuffer |
| 18 | `0x7ff805365763` | Method | 3 | `_IOFBSetStartupDisplayModeAndDepth` | IOFramebuffer |
| 19 | `0x7ff8053657ff` | Method | 8 | `_IOFBGetFramebufferOffsetForAperture` | IOFramebuffer |
| 20 | `0x7ff8053658ab` | Method | 2 | `_IOFBGetCurrentDisplayModeAndDepth` | IOFramebuffer |
| 21 | `0x7ff805365cc9` | Method | 2 | `_IOFBAcknowledgeNotification` | IOFramebuffer |
| 22 | `0x7ff805365d94` | Method | 2 | `_IOFBAcknowledgeNotification` | IOFramebuffer |
| 23 | `0x7ff805365ef7` | Method | 14 (0x0E) | `_IOFBAcknowledgeNotification` | IOFramebuffer |
| 24 | `0x7ff805365fd8` | Method | 10 (0x0A) | `_IOFBSetNewCursor` | IOFramebuffer |
| 25 | `0x7ff80536605b` | Method | 12 (0x0C) | `_IOFBSetCursorVisible` | IOFramebuffer |
| 26 | `0x7ff8053744d4` | Method | 2 | `_IODisplayCreateInfoDictionary` | IODisplay |
| 27 | `0x7ff80538a955` | Method | 1 | `CoreDisplay::Display::TransactionStateString()` | CoreDisplay/display |
| 28 | `0x7ff80538aa8e` | Method | 1 | `CoreDisplay::Display::TransactionStateString()` | CoreDisplay/display |
| 29 | `0x7ff80539e17d` | Struct | 16 (0x10) | `WSAGDCSetDisplayPolicyEnabled(bool, bool)` | **AGDC** |
| 30 | `0x7ff80539e318` | Struct | 1 | `WSAGDCSetDisplayPolicyEnabled(bool, bool)` | **AGDC** |
| 31 | `0x7ff8053be4f8` | Method | 13 (0x0D) | `_MPSetCursorPosition` | IOFramebuffer/display |
| 32 | `0x7ff8053e8b47` | Method | 9 | `_CDSetDeviceBounds` | CoreDisplay |
| 33 | `0x7ff8053ef0a5` | Method | 20 (0x14) | `displayWillSleepWithImages` block | display power |
| 34 | `0x7ff8053f6b9e` | Struct | 1 | `_CGXMappedDisplayStart` | IOPresentment/display |

### 5.1 Selezione AGDC

**PROVEN:** solo due call site CoreDisplay sono nel percorso AGDC:

```text
0x7ff80539e17d  IOConnectCallStructMethod  selector 0x10
0x7ff80539e318  IOConnectCallStructMethod  selector 1
```

Entrambi sono dentro `WSAGDCSetDisplayPolicyEnabled`.

**PROVEN:** nessuno dei 34 call site CoreDisplay usa `IOConnectCallMethod` con selettore 3 su AGDC.
**PROVEN:** il call site CoreDisplay con selettore 3 a `0x7ff805365763` è `_IOFBSetStartupDisplayModeAndDepth`, quindi appartiene a IOFramebuffer, non ad AGDC.
**PROVEN:** il call site CoreDisplay con selettore 3 a `0x7ff8053654fd` è dinamico, ma appartiene a `_IOFBCreateSharedCursor` (IOFramebuffer), non ad AGDC.

---

## 6. CoreDisplay: percorso AGDC reale e wrapper

### 6.1 Apertura del servizio AGDC

In `WSAGDCSetDisplayPolicyEnabled`:

```asm
0x7ff80539e23e  leaq "AppleGraphicsDeviceControl", %rdi
0x7ff80539e245  call 0x7ff80543adaa          ; IOServiceMatching
0x7ff80539e24a  test rax,rax
0x7ff80539e24d  je 0x7ff80539e1ba
0x7ff80539e253  movl -0x264(%rbp),%edi       ; master port
0x7ff80539e259  leaq -0x268(%rbp),%rdx       ; iterator
0x7ff80539e260  movq %rax,%rsi
0x7ff80539e263  call 0x7ff80543ada4          ; IOServiceGetMatchingServices
0x7ff80539e270  movl -0x268(%rbp),%edi
0x7ff80539e276  call 0x7ff80543ac18          ; IOIteratorNext
0x7ff80539e27b  test eax,eax
0x7ff80539e27d  je 0x7ff80539e34c
```

Il codice costruisce un record locale con il port del servizio e la connessione, poi chiama il selettore 1 e infine il selettore `0x10`.

### 6.2 Selettore 1

```asm
0x7ff80539e2d8  movq $0x2c,-0x278(%rbp)      ; dimensione struttura output
0x7ff80539e2fb  movl -0x26c(%rbp),%edi       ; connect
0x7ff80539e301  movl $0x1,%esi              ; selector 1
0x7ff80539e306  xorl %edx,%edx
0x7ff80539e308  xorl %ecx,%ecx
0x7ff80539e30a  leaq -0x260(%rbp),%r8
0x7ff80539e311  leaq -0x278(%rbp),%r9
0x7ff80539e318  callq 0x7ff80543ab3a        ; IOConnectCallStructMethod
```

**PROVEN:** il selettore 1 è usato per la struttura di inizializzazione del servizio AGDC; non è il selettore 3.

### 6.3 Selettore 0x10

```asm
0x7ff80539e14f  movq agdc_service,%r15
0x7ff80539e156  test %r15,%r15
0x7ff80539e159  je 0x7ff80539e1a4
0x7ff80539e15b  movl 0x4(%r15),%edi          ; connect
0x7ff80539e163  leaq -0x230(%rbp),%rdx      ; policy
0x7ff80539e16a  movq %rax,(%rdx)
0x7ff80539e16d  movl $0x8,%ecx
0x7ff80539e172  movl $0x10,%esi             ; selector 0x10
0x7ff80539e177  xorl %r8d,%r8d
0x7ff80539e17a  xorl %r9d,%r9d
0x7ff80539e17d  callq 0x7ff80543ab3a         ; IOConnectCallStructMethod(dataport, 0x10, ...)
```

Il messaggio di errore conferma il selettore:

```text
IOConnectCallStructMethod(dataport, 0x10, &policy, policySize, NULL, NULL); failed (%#x)
```

**PROVEN:** l'API AGDC usata da CoreDisplay per il display policy è il selettore `0x10`.
**PROVEN:** CoreDisplay non espone alcuna chiamata AGDC con selettore 3 in questo percorso.

### 6.4 Wrapper `CGXSetDisplayPolicyEnabled`

`CGXSetDisplayPolicyEnabled` a `0x7ff8053e6b54` non chiama IOKit direttamente: costruisce una struttura di richiesta e invoca il block/dispatch a `0x7ff8053e6acf`, che a sua volta chiama `WSAGDCSetDisplayPolicyEnabled` (`0x7ff80539e0fa`).

Catena:

```text
CGXSetDisplayPolicyEnabled
  -> block CGXSetDisplayPolicyEnabled_block_invoke
  -> WSAGDCSetDisplayPolicyEnabled
  -> IOConnectCallStructMethod selector 0x10
```

**PROVEN:** il wrapper indiretto di CoreDisplay termina al selettore `0x10`, non al 3.
**PROVEN:** non c'è una tabella di dispatch che trasformi un input in selettore 3 in questa catena.

### 6.5 `WSAGDCSetDebugOptions`

`WSAGDCSetDebugOptions` a `0x7ff80539e038` fa:

```asm
0x7ff80539e03c  movl $0x1,%edi
0x7ff80539e042  jmpq *0x3e73b5c0(%rip)
```

**PROVEN:** è un salto indiretto a un handler/debug hook, non un call site `IOConnectCallMethod`/`IOConnectCallStructMethod` nel binario.
**UNPROVEN:** il target del puntatore non è un'API AGDC con selettore 3; non ci sono evidenze statiche che lo colleghino al 3.

---

## 7. IOPresentment: controllo ausiliario

IOPresentment ha **31** call site Method/Struct: **14** `IOConnectCallMethod` e **17** `IOConnectCallStructMethod`.

### 7.1 Inventario aggregato

| Funzione | Tipo | Selector | N. | Servizio |
|---|---|---:|---:|---|
| `IOPresentmentCreateGPUWranglerEventHandler` | Method | `0xA0000001`, `0xA0000002` | 2 | GPUWrangler |
| `dequeueGPUWranglerEvents` | Method | `0xA0000003`, `0xA0000002` | 2 | GPUWrangler |
| `ioPresentmentCreateAssociationMap` | Method | `0xA0000001`, `0xA0000002`, `1`, `0x980` | 5 | GPUWrangler / AGDC |
| `IOPresentmentCreateForRegistryID` | Method | 1 | 2 | IOPresentment |
| `__GatherAGDCLogicalDeviceCapabilities` | Method | `0x921` | 1 | **AGDC** |
| `__GatherAGDCDisplayPipelineCapabilities` | Struct | `0x711` | 16 | **AGDC** |
| `__GatherAGDCLinkCapabilities` | Method | `0x925`, `0x988` | 2 | **AGDC** |
| `IOPresentmentSetSDP` | Struct | `0x713` | 1 | **AGDC** |

**PROVEN:** nessuno dei 31 call site IOPresentment usa il selettore 3.
**PROVEN:** i selettori AGDC osservati sono `0x711`, `0x713`, `0x921`, `0x925`, `0x988` e `0x980`; il 3 non compare.
**PROVEN:** i selettori `0xA0000001`–`0xA0000003` appartengono al percorso GPUWrangler, non ad AGDC.
**PROVEN:** IOPresentment non fornisce un percorso diretto al selettore 3.

### 7.2 Perché è rilevante

IOPresentment è il client AGDC più ricco tra i componenti estratti: apre una connessione AGDC, legge vendor info, capability e pipeline, e usa selettori diversi dal 3. La sua presenza conferma che il protocollo AGDC osservabile non include il 3 nelle API usate da questi componenti.

---

## 8. Wrapper indiretti, dispatch table e API private

### 8.1 CoreDisplay

- `WSAGDCSetDisplayPolicyEnabled` è una funzione esportata, non un call site nascosto.
- `CGXSetDisplayPolicyEnabled` è un wrapper che termina su `WSAGDCSetDisplayPolicyEnabled`.
- `WSAGDCSetDebugOptions` è un salto indiretto a un hook, ma non è un `IOConnectCall*`.
- `WSAGDCSetDisplayPolicyEnabled` usa una struttura di policy con selettore `0x10`.
- Il selettore 1 è usato per l'inizializzazione della connessione AGDC.

**PROVEN:** nel codice CoreDisplay disponibile non esiste una dispatch table che selezioni il comando 3.
**PROVEN:** l'unico selettore AGDC “di comando” esposto è `0x10`; il selettore 1 è di inizializzazione.

### 8.2 WindowServer

- Non importa IOKit.
- Non importa CoreDisplay direttamente.
- Importa solo `_SLXServer`.
- Non contiene i letterali AGDC.

**PROVEN:** WindowServer non ha un call site diretto a `IOConnectCallMethod`/`IOConnectCallStructMethod`.
**UNPROVEN:** un eventuale wrapper dentro SkyLight che porti al selettore 3.

### 8.3 SkyLight

**BLOCKED:** binario assente; nessuna scansione possibile.
Non si può escludere staticamente un percorso SkyLight -> AGDC selector 3; non lo si può nemmeno affermare.

### 8.4 Altri componenti

I 73 estratti della dyld cache contengono molti call site con selettore 3 (IOFramebuffer, IOSurface, IOAccelerator, CoreAudio, DiskManagement, ecc.), ma appartengono a servizi diversi da AGDC. Il selettore 3 non è un identificatore globale di AGDC: è significativo solo insieme alla connessione IOKit e alla classe del servizio.

---

## 9. Verdetto

| Domanda | Esito |
|---|---|
| WindowServer importa IOKit direttamente | **NO, PROVEN** |
| WindowServer ha call site Method/Struct | **NO, PROVEN** |
| SkyLight è disponibile come binario standalone | **NO, PROVEN** |
| SkyLight è stato analizzato | **NO, BLOCKED** |
| CoreDisplay ha 34 call site Method/Struct | **PROVEN** |
| CoreDisplay usa AGDC con selettore 0x10 | **PROVEN** |
| CoreDisplay usa AGDC con selettore 1 | **PROVEN** |
| CoreDisplay usa AGDC con selettore 3 | **NO, PROVEN** |
| IOPresentment usa AGDC con selettore 3 | **NO, PROVEN** |
| Esiste un percorso Apple disponibile che invii il 3 | **NO, non trovato** |
| Esiste un percorso SkyLight non verificabile | **UNPROVEN/BLOCKED** |
| T27 | **OPEN — 94% engineering / 32% first boot / 8% desktop** |

**Risposta netta:** nei componenti disponibili non esiste un percorso Apple autorizzato che invochi AGDC con selettore 3 senza injection. WindowServer non ha nemmeno accesso diretto a IOKit; CoreDisplay usa AGDC solo con i selettori 1 e 0x10; IOPresentment usa 0x711, 0x713, 0x921, 0x925, 0x988 e 0x980, mai 3. L'unico punto non verificabile è SkyLight, il cui binario non è presente nel framework e non è stato estratto.

**Primo ostacolo ancora irrisolto:** l'assenza del binario SkyLight rende impossibile dimostrare staticamente che non esista un wrapper privato SkyLight -> AGDC selector 3. A valle resta il limite già noto: manca un attore Apple autorizzato che invii effettivamente il 3; WindowServer è autorizzato ma non lo invia.

**Spazio:** **13.962.964 KiB ≈ 13,31 GiB** liberi (verificato dopo la stesura). Nessuna cancellazione; nessun file eliminabile proposto.
**STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
