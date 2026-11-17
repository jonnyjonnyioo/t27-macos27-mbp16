# T27 — OOB AGDC — Dispatch `CGXUpdateDesktop` e API private — Report 179

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

SkyLight, già estratto nel Report 178:

```text
HAO-PROJECT/T27/AGENT-AMD/.tmp/a178/SkyLight
SHA-256: 1e8ead0ceaf2b8a2fe2c167fa299142939ec579f9df60ab30dae8a5c513bea56
dimensione: 8.058.408 byte
architettura: Mach-O 64-bit dynamically linked shared library x86_64
```

CoreGraphics, estratto per questo report:

```sh
ipsw dyld extract \
  /System<VOLUME>/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_x86_64h \
  CoreGraphics --stubs -o .tmp/a179
```

```text
HAO-PROJECT/T27/AGENT-AMD/.tmp/a179/CoreGraphics
SHA-256: 34a2683052af18ae68ae66d6f6de08ee5b0111277627d0c9f67bd16d8174b6e0
architettura: Mach-O 64-bit dynamically linked shared library x86_64
```

CoreDisplay, già disponibile:

```text
HAO-PROJECT/T27/AGENT-AMD/.tmp/a73/01_CoreDisplay
SHA-256: d1d038dd7f88191d47db381ce776f7837d12408439d19f279c393c847c7c64fc
architettura: Mach-O 64-bit dynamically linked shared library x86_64
```

Target:

```text
/System/Library/KernelCollections/SystemKernelExtensions.kc
SHA-256: b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7
```

Report:

```text
HAO-PROJECT/T27/AGENT-AMD/T27-OOB-AGDC-DISPATCH-179.md
```

---

## 2. Obiettivo del PROMPT 179

Chiudere l'ultimo limite residuo della ricerca statica sul filone AMD/AGDC:

1. verificare se `CGXUpdateDesktop` contiene un percorso diretto o indiretto verso AGDC selector 3;
2. risolvere il virtual dispatch `*0xe8(%rcx)` osservato nel Report 178;
3. verificare se altre callback di `gWSCallbacks` vengono invocate da `CGXUpdateDesktop`;
4. verificare se `CGXUpdateDesktop` esiste anche in CoreGraphics;
5. distinguere rigorosamente **PROVEN / INFERRED / UNPROVEN**.

Non sono state ripetute le scansioni già concluse nel Report 178: import SkyLight, call site IOKit diretti e wrapper `WSAGDCSetDebugOptions`.

---

## 3. Risultato sintetico

**PROVEN:** `CGXUpdateDesktop` è una funzione locale di **SkyLight**, non di CoreGraphics.

**PROVEN:** il suo corpo non contiene:

```text
IOConnectCallMethod
IOConnectCallStructMethod
IOConnectCallScalarMethod
IOServiceOpen
AppleGraphicsDeviceControl
AGDC selector 3
gWSCallbacks
```

**PROVEN:** il solo dispatch indiretto è:

```asm
callq *0xe8(%rcx)
```

dove `rcx` è il primo qword dell'oggetto restituito da `WS::Displays::CDManager()`.

**PROVEN:** la vtable di quell'oggetto è `0x7ff840ad2ea0`; lo slot `+0xe8` contiene il puntatore a:

```text
CoreDisplayManager::create_overall_region() const
0x7ff809508686
```

**PROVEN:** `create_overall_region()` è un thunk di 10 byte che salta a:

```text
_CGXCreateDisplayRegion
0x7ff80541cf8a   (CoreDisplay)
```

**PROVEN:** `CGXCreateDisplayRegion` costruisce una regione unione dei display online; non contiene call site IOKit/AGDC.

**PROVEN:** CoreGraphics non contiene né `CGXUpdateDesktop` né stringhe/import AGDC. Il provider di `CGXCreateDisplayRegion` è CoreDisplay, non CoreGraphics.

**Conclusione statica:** il percorso `CGXUpdateDesktop -> *0xe8` è chiuso. Non esiste un percorso statico da `CGXUpdateDesktop` ad AGDC selector 3 nei binari esaminati. Resta **UNPROVEN** solo una modifica runtime della function pointer non rappresentata nella tabella statica.

---

## 4. `CGXUpdateDesktop`: corpo esatto

Simbolo:

```text
_CGXUpdateDesktop
0x7ff80930258f  (SkyLight, simbolo locale)
```

Corpo completo, 95 byte, fino al simbolo successivo `_WSDisableUpdateInternalToken` a `0x7ff8093025ee`:

```asm
_CGXUpdateDesktop:
0x7ff80930258f  pushq %rbp
0x7ff809302590  movq %rsp,%rbp
0x7ff809302593  pushq %r14
0x7ff809302595  pushq %rbx
0x7ff809302596  callq _WSDisableUpdateInternalToken
0x7ff80930259b  movq %rax,%rbx
0x7ff80930259e  movq ___sessionControlRef(%rip),%rax
0x7ff8093025a5  testq %rax,%rax
0x7ff8093025a8  je 0x7ff8093025bc
0x7ff8093025aa  movq 0x20(%rax),%rax
0x7ff8093025ae  testq %rax,%rax
0x7ff8093025b1  je 0x7ff8093025bc
0x7ff8093025b3  movq 0x138(%rax),%r14
0x7ff8093025ba  jmp 0x7ff8093025bf
0x7ff8093025bc  xorl %r14d,%r14d
0x7ff8093025bf  movq 0x8(%r14),%rdi
0x7ff8093025c3  testq %rdi,%rdi
0x7ff8093025c6  je 0x7ff8093025cd
0x7ff8093025c8  callq 0x7ff809677d70          ## _CFRelease
0x7ff8093025cd  callq __ZN2WS8Displays9CDManagerEv
0x7ff8093025d2  movq (%rax),%rcx
0x7ff8093025d5  movq %rax,%rdi
0x7ff8093025d8  callq *0xe8(%rcx)
0x7ff8093025de  movq %rax,0x8(%r14)
0x7ff8093025e2  movq %rbx,%rdi
0x7ff8093025e5  popq %rbx
0x7ff8093025e6  popq %r14
0x7ff8093025e8  popq %rbp
0x7ff8093025e9  jmp _WSReenableUpdateInternalToken
```

### 4.1 Call dirette

| Indirizzo | Target | Natura |
|---|---|---|
| `0x7ff809302596` | `_WSDisableUpdateInternalToken` | gestione token di update |
| `0x7ff8093025c8` | `_CFRelease` | rilascio CF |
| `0x7ff8093025cd` | `WS::Displays::CDManager()` | singleton del display manager |
| `0x7ff8093025d8` | `*0xe8(%rcx)` | virtual dispatch |
| `0x7ff8093025e9` | `_WSReenableUpdateInternalToken` | tail-jump, riequilibrio token |

**PROVEN:** nessuna delle call dirette è un'API IOKit.
**PROVEN:** `CGXUpdateDesktop` non referenzia `gWSCallbacks`; non invoca callback aggiuntive oltre al dispatch virtuale.

### 4.2 Perché non è un percorso AGDC

`CGXUpdateDesktop` non contiene:

```text
IOConnectCallMethod            0
IOConnectCallStructMethod      0
IOConnectCallScalarMethod      0
IOServiceOpen                  0
AppleGraphicsDeviceControl     0
WSAGDCSetDebugOptions          0
```

Il nome `CGXUpdateDesktop` descrive un aggiornamento del desktop; non un comando al controller grafico.

---

## 5. Risoluzione della vtable `CoreDisplayManager`

### 5.1 `CDManager()` restituisce un `CoreDisplayManager`

```asm
__ZN2WS8Displays9CDManagerEv:
0x7ff80950cb2a  ...
0x7ff80950cb62  movl $0x218,%edi
0x7ff80950cb67  callq __ZnwmSt19__type_descriptor_t
0x7ff80950cb72  callq __ZN2WS8Displays18CoreDisplayManagerC2Ev
0x7ff80950cb77  movq %rbx, __ZZN2WS8Displays9CDManagerEvE7manager(%rip)
```

**PROVEN:** l'oggetto restituito è allocato con `0x218` byte e costruito da `CoreDisplayManager::CoreDisplayManager()`.

### 5.2 Il costruttore installa la vtable

```asm
__ZN2WS8Displays18CoreDisplayManagerC2Ev:
0x7ff80950dd86  pushq %rbp
0x7ff80950dd87  movq %rsp,%rbp
0x7ff80950dd8a  pushq %rbx
0x7ff80950dd8b  pushq %rax
0x7ff80950dd8c  movq %rdi,%rbx
0x7ff80950dd8f  leaq 0x375cf4ba(%rip),%rax
0x7ff80950dd96  movq %rax,(%rdi)
...
0x7ff80950ddc2  cmpq $0x0,__ZN2WS8DisplaysL15base_class_vptrE(%rip)
0x7ff80950ddca  jne 0x7ff80950dea3
0x7ff80950ddd0  movq (%rbx),%rax
0x7ff80950ddd3  movq %rax,__ZN2WS8DisplaysL15base_class_vptrE(%rip)
...
0x7ff80950ddec  leaq 0x375c50ad(%rip),%rax
0x7ff80950ddf3  movq %rax,(%rbx)
```

Calcolo RIP-relativo:

```text
0x7ff80950dd96 + 0x375cf4ba = 0x7ff840add250   (base class vptr)
0x7ff80950ddf3 + 0x375c50ad = 0x7ff840ad2ea0   (vtable finale)
```

**PROVEN:** il primo qword dell'oggetto `CoreDisplayManager` è `0x7ff840ad2ea0`.
**PROVEN:** `CDManager()` restituisce quindi un oggetto la cui vtable è `0x7ff840ad2ea0`.

### 5.3 File offset e slot `+0xe8`

La vtable è nella sezione:

```text
__DATA_CONST,__const
addr:   0x7ff840abb3d0
size:   0x2cae0
offset: 5645920 (0x5627a0)
```

Calcolo:

```text
vtable 0x7ff840ad2ea0
file offset = 0x5627a0 + (0x7ff840ad2ea0 - 0x7ff840abb3d0)
            = 0x57a130
slot +0xe8  = 0x7ff840ad2f88
file offset = 0x57a218
```

Dump:

```text
0057a130: b069500900020000 ba69500900020000
0057a140: 1e6a500900020000 986d500900020000
...
0057a210: 9c1f540900020000 8686500900020000
0057a218: 8686500900020000 9086500900020000
```

Decodifica chained-fixup x86_64:

```text
target = 0x7ff800000000 | (raw & 0xffffffff)
```

Slot `+0x0`:

```text
raw:     0x00000200095069b0
target:  0x7ff8095069b0
simbolo: CoreDisplayManager::initialize_accelerated_compositing()
```

Slot `+0xe8`:

```text
raw:     0x0000020009508686
target:  0x7ff809508686
simbolo: CoreDisplayManager::create_overall_region() const
```

**PROVEN:** `callq *0xe8(%rcx)` non è un percorso AGDC: è una chiamata virtuale a `create_overall_region()`.

### 5.4 Corpo di `create_overall_region()`

```asm
__ZNK2WS8Displays18CoreDisplayManager21create_overall_regionEv:
0x7ff809508686  pushq %rbp
0x7ff809508687  movq %rsp,%rbp
0x7ff80950868a  popq %rbp
0x7ff80950868b  jmp 0x7ff809678568   ## symbol stub for: _CGXCreateDisplayRegion
```

**PROVEN:** è un thunk di 10 byte; non contiene logica IOKit/AGDC.
**PROVEN:** il target è `_CGXCreateDisplayRegion`, importato da SkyLight e definito in CoreDisplay.

---

## 6. `CGXCreateDisplayRegion` in CoreDisplay

Simbolo:

```text
_CGXCreateDisplayRegion
0x7ff80541cf8a  (CoreDisplay, simbolo esterno)
```

Corpo osservato:

```asm
_CGXCreateDisplayRegion:
0x7ff80541cf8a  pushq %rbp
0x7ff80541cf8b  movq %rsp,%rbp
0x7ff80541cf8e  pushq %r15
0x7ff80541cf90  pushq %r14
0x7ff80541cf92  pushq %rbx
0x7ff80541cf93  pushq %rax
0x7ff80541cf94  xorl %edi,%edi
0x7ff80541cf96  callq _CGXNextOnlineEnabledDisplayDevice
0x7ff80541cf9b  testq %rax,%rax
0x7ff80541cf9e  je 0x7ff80541d007
0x7ff80541cfa0  movq %rax,%r14
0x7ff80541cfa3  movq 0x18(%rax),%rdi
0x7ff80541cfa7  callq _CGRegionCreateCopy
0x7ff80541cfac  movq %rax,%rbx
0x7ff80541cfaf  movq (%r14),%r15
...
0x7ff80541cfc4  cmpb $0x0,0x129(%rax)
0x7ff80541cfd4  callq _CGRegionCreateUnionWithRegion
0x7ff80541cfdf  callq _CGRegionRelease
...
0x7ff80541d006  retq
0x7ff80541d007  ...
0x7ff80541d011  jmp _CGRegionCreateEmptyRegion
```

### 6.1 Call dirette

| Indirizzo | Target | Natura |
|---|---|---|
| `0x7ff80541cf96` | `_CGXNextOnlineEnabledDisplayDevice` | enumerazione display |
| `0x7ff80541cfa7` | `_CGRegionCreateCopy` | regione |
| `0x7ff80541cfd4` | `_CGRegionCreateUnionWithRegion` | regione |
| `0x7ff80541cfdf` | `_CGRegionRelease` | regione |
| `0x7ff80541d011` | `_CGRegionCreateEmptyRegion` | regione vuota |

**PROVEN:** nessuna call diretta a IOKit, AGDC, `IOConnectCall*` o `WSAGDCSetDebugOptions`.
**PROVEN:** la funzione costruisce solo una regione geometrica unione dei display online/enabled.

### 6.2 `CGXNextOnlineEnabledDisplayDevice`

```text
0x7ff80541d016  (CoreDisplay)
```

Il corpo usa `_gWSDeviceList` e due callback indirette:

```asm
0x7ff80541d01f  callq *0x3e6bc17b(%rip)
0x7ff80541d029  callq *0x3e6bbfc1(%rip)
```

Calcolo dei due puntatori dati:

```text
0x7ff80541d025 + 0x3e6bc17b = 0x7ff843ad91a0
0x7ff80541d02f + 0x3e6bbfc1 = 0x7ff843ad8ff0
```

`0x7ff843ad8fe0` è `gWSCallbacks` in `__DATA,__common` di CoreDisplay:

```text
0x7ff843ad8ff0 = gWSCallbacks + 0x10
0x7ff843ad91a0 = gWSCallbacks + 0x1c0
```

Le due entry della tabella SkyLight `WSCDInitializeVtable.callbacks` sono:

```text
+0x10:
  raw:     0x0000020009510052
  target:  0x7ff809510052
  simbolo: _WSGetCurrentSessionDisplayData_CoreDisplayOnly

+0x1c0:
  raw:     0x00000200093fd9aa
  target:  0x7ff8093fd9aa
  simbolo: _CGXGetCurrentSessionScoreboardDisplaySet
```

**PROVEN:** le due callback indirette non sono AGDC; sono letture di dati di sessione.
**PROVEN:** `WSGetCurrentSessionDisplayData_CoreDisplayOnly` legge `__sessionControlRef` e restituisce un campo; non chiama IOKit.
**PROVEN:** `CGXGetCurrentSessionScoreboardDisplaySet` legge `__sessionControlRef` e restituisce un campo booleano; non chiama IOKit.

Pertanto anche il ramo di enumerazione display non raggiunge AGDC.

---

## 7. `gWSCallbacks`: scansione della tabella

SkyLight costruisce la tabella in `___WSCDInitializeVtable_block_invoke`:

```asm
0x7ff8096103d3  leaq WSCDInitializeVtable.callbacks(%rip),%rsi
0x7ff8096103da  movl $0xd7,%ecx
0x7ff8096103df  movq %rsp,%rdi
0x7ff8096103e2  rep movsq (%rsi),(%rdi)
0x7ff8096103e5  callq _InitializeCoreDisplay
```

```text
WSCDInitializeVtable.callbacks = 0x7ff840ade020
numero entry = 0xd7 = 215
dimensione = 0x6b8 = 1720 byte
file offset = 0x5852b0
```

### 7.1 Entry rilevanti

| Offset | Raw | Target | Simbolo |
|---|---|---|---|
| `+0x10` | `0x0000020009510052` | `0x7ff809510052` | `WSGetCurrentSessionDisplayData_CoreDisplayOnly` |
| `+0x1c0` | `0x00000200093fd9aa` | `0x7ff8093fd9aa` | `CGXGetCurrentSessionScoreboardDisplaySet` |
| `+0x628` | `0x000002000930258f` | `0x7ff80930258f` | `CGXUpdateDesktop` |
| `+0x630` | `0x00000200093025ee` | `0x7ff8093025ee` | `WSDisableUpdateInternalToken` |
| `+0x6b0` | `0x00000600095108fc` | `0x7ff8095108fc` | `device_generate_lock_screen_screenshot_coredisplay_only` |

### 7.2 Scansione AGDC

Tutte le 215 entry sono state decodificate. Risultato:

```text
target nel range AGDC CoreDisplay 0x7ff80539e000–0x7ff80539f000: 0
target nei simboli AGDC SkyLight 0x7ff809202000–0x7ff809203000: 0
target nei simboli AGDC SkyLight 0x7ff809509300–0x7ff809509800: 0
```

**PROVEN:** la tabella statica `WSCDInitializeVtable.callbacks` non contiene alcun target AGDC.
**PROVEN:** l'unica entry del percorso esaminato è `+0x628 -> CGXUpdateDesktop`; `CGXUpdateDesktop` a sua volta non referenzia `gWSCallbacks`.

**INFERRED:** poiché `CGXUpdateDesktop` non legge `gWSCallbacks`, le altre 214 entry non vengono invocate da questa funzione.

**UNPROVEN:** una modifica runtime di `gWSCallbacks` o di una function pointer dopo l'inizializzazione non è osservabile staticamente. Non è stata trovata alcuna evidenza di tale modifica.

---

## 8. CoreGraphics

CoreGraphics è stato estratto dalla stessa cache 25G342:

```text
SHA-256: 34a2683052af18ae68ae66d6f6de08ee5b0111277627d0c9f67bd16d8174b6e0
```

### 8.1 `CGXUpdateDesktop`

```sh
nm -n .tmp/a179/CoreGraphics | grep CGXUpdateDesktop
```

Risultato:

```text
CGXUpdateDesktop: absent
```

**PROVEN:** `CGXUpdateDesktop` non è definito in CoreGraphics.
**PROVEN:** il simbolo è locale a SkyLight e il suo unico corpo analizzato è quello di `.tmp/a178/SkyLight`.

### 8.2 Stringhe e import AGDC

```sh
strings .tmp/a179/CoreGraphics | grep -c -iE 'AppleGraphicsDeviceControl|WSAGDCSetDebugOptions|AGDC'
```

Risultato:

```text
0
```

`nm -m` non mostra import `IOConnectCallMethod`, `IOConnectCallStructMethod`, `IOConnectCallScalarMethod`, `IOServiceOpen`, `WSAGDCSetDebugOptions` o `AppleGraphicsDeviceControl`.

**PROVEN:** CoreGraphics non contiene il nome del servizio AGDC, il wrapper `WSAGDCSetDebugOptions` o le API IOKit di connessione.
**PROVEN:** CoreGraphics non è il provider di `CGXCreateDisplayRegion`; il provider è CoreDisplay.

### 8.3 WindowServer

Il Report 178 ha già stabilito:

```text
WindowServer importa solo _SLXServer
WindowServer non ha un call site IOKit diretto
WindowServer ha com.apple.private.gpuwrangler=true
```

Nessun nuovo dato di questo report modifica quel risultato.

---

## 9. Catena completa verificata

```text
WS::Displays::CoreDisplayManager::set_debug_options
  -> WSAGDCSetDebugOptions (CoreDisplay)
  -> gWSCallbacks + 0x628
  -> CGXUpdateDesktop (SkyLight)
       -> WSDisableUpdateInternalToken
       -> CFRelease (condizionale)
       -> WS::Displays::CDManager()
       -> *0xe8(vtable CoreDisplayManager)
            -> CoreDisplayManager::create_overall_region()
            -> CGXCreateDisplayRegion (CoreDisplay)
                 -> CGXNextOnlineEnabledDisplayDevice
                      -> gWSCallbacks + 0x1c0
                           -> CGXGetCurrentSessionScoreboardDisplaySet
                      -> gWSCallbacks + 0x10
                           -> WSGetCurrentSessionDisplayData_CoreDisplayOnly
                 -> CGRegionCreateCopy
                 -> CGRegionCreateUnionWithRegion
                 -> CGRegionRelease
                 -> CGRegionCreateEmptyRegion
       -> WSReenableUpdateInternalToken
```

**PROVEN:** l'intera catena statica non contiene `IOConnectCallMethod`, `IOConnectCallStructMethod`, `IOConnectCallScalarMethod`, `IOServiceOpen`, `AppleGraphicsDeviceControl` o AGDC selector 3.

---

## 10. PROVEN / INFERRED / UNPROVEN

### PROVEN

1. `CGXUpdateDesktop` è a `0x7ff80930258f` in SkyLight ed è lungo 95 byte.
2. Il corpo non contiene call IOKit, stringhe AGDC o riferimenti a `gWSCallbacks`.
3. L'unico dispatch indiretto è `*0xe8(%rcx)`.
4. `CDManager()` restituisce un `CoreDisplayManager` allocato di `0x218` byte.
5. Il costruttore installa la vtable `0x7ff840ad2ea0`.
6. Lo slot `+0xe8` della vtable contiene `0x7ff809508686`, `CoreDisplayManager::create_overall_region() const`.
7. `create_overall_region()` è un thunk a `CGXCreateDisplayRegion`.
8. `CGXCreateDisplayRegion` è definita in CoreDisplay a `0x7ff80541cf8a`.
9. `CGXCreateDisplayRegion` usa solo API di regione e enumerazione display; nessun IOKit/AGDC.
10. Le due callback indirette di `CGXNextOnlineEnabledDisplayDevice` sono `CGXGetCurrentSessionScoreboardDisplaySet` e `WSGetCurrentSessionDisplayData_CoreDisplayOnly`.
11. La tabella statica `WSCDInitializeVtable.callbacks` ha 215 entry e nessun target AGDC.
12. CoreGraphics non contiene `CGXUpdateDesktop`, stringhe AGDC o import IOKit di connessione.
13. `CGXUpdateDesktop` non invoca altre callback di `gWSCallbacks`.

### INFERRED

1. Il percorso `CGXUpdateDesktop -> create_overall_region -> CGXCreateDisplayRegion` è un aggiornamento geometrico del desktop, non un comando al controller AGDC.
2. Poiché `CGXUpdateDesktop` non legge `gWSCallbacks`, le altre entry della tabella non sono invocate da questa funzione.

### UNPROVEN

1. Una modifica runtime di `gWSCallbacks` o di una function pointer dopo l'inizializzazione non è osservabile staticamente.
2. Non è stata eseguita alcuna verifica runtime del percorso; non è stato fatto boot, trace o injection.
3. Restano possibili API private non osservate in binari non estratti; questo report chiude il dispatch di `CGXUpdateDesktop`, non l'intero universo delle API private di macOS.

---

## 11. Verdetto

| Domanda | Esito |
|---|---|
| `CGXUpdateDesktop` è in SkyLight | **SÌ, PROVEN — 0x7ff80930258f** |
| `CGXUpdateDesktop` è in CoreGraphics | **NO, PROVEN — assente** |
| Il corpo contiene IOKit diretto | **NO, PROVEN** |
| Il corpo contiene AGDC selector 3 | **NO, PROVEN** |
| Il corpo referenzia `gWSCallbacks` | **NO, PROVEN** |
| Il dispatch `*0xe8` è risolto | **SÌ, PROVEN — create_overall_region()** |
| `create_overall_region` porta a IOKit | **NO, PROVEN — thunk a CGXCreateDisplayRegion** |
| `CGXCreateDisplayRegion` porta ad AGDC | **NO, PROVEN** |
| La tabella `gWSCallbacks` contiene target AGDC | **NO, PROVEN nella tabella statica** |
| CoreGraphics contiene AGDC/`CGXUpdateDesktop` | **NO, PROVEN** |
| Esiste un percorso statico `CGXUpdateDesktop -> AGDC selector 3` | **NO, non trovato** |
| Resta un percorso runtime non osservato | **SÌ, UNPROVEN — nessuna evidenza** |
| T27 | **OPEN — 94% engineering / 32% first boot / 8% desktop** |

**Risposta netta:** il limite residuo del Report 178 è chiuso. Il virtual dispatch `*0xe8(%rcx)` non è un punto cieco AGDC: è `CoreDisplayManager::create_overall_region()`, che porta a `CGXCreateDisplayRegion` in CoreDisplay e costruisce una regione geometrica dei display. Non esiste un percorso statico da `CGXUpdateDesktop` ad AGDC selector 3. CoreGraphics non contiene né il simbolo né il servizio AGDC. L'unica incertezza residua è una modifica runtime non rappresentata nella tabella statica, per la quale non è stata trovata evidenza.

**Impatto sul compatibility layer:** il layer client-only non può usare `CGXUpdateDesktop` come ponte verso AGDC selector 3. Il percorso Apple disponibile resta un aggiornamento desktop e non un invio del comando `LoadHWServices` con bit `0x2`. La conclusione del Report 178 è quindi rafforzata, non indebolita.

---

## 12. Comandi eseguiti

```sh
# Estrazione CoreGraphics
ipsw dyld extract \
  /System<VOLUME>/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_x86_64h \
  CoreGraphics --stubs -o .tmp/a179

# Hash
shasum -a 256 .tmp/a178/SkyLight
shasum -a 256 .tmp/a179/CoreGraphics
shasum -a 256 .tmp/a73/01_CoreDisplay

# Simboli
nm -n .tmp/a178/SkyLight | grep -E 'CGXUpdateDesktop|CoreDisplayManager|WSGetCurrentSessionDisplayData|CGXGetCurrentSessionScoreboardDisplaySet'
nm -n .tmp/a179/CoreGraphics | grep CGXUpdateDesktop
nm -n .tmp/a73/01_CoreDisplay | grep CGXCreateDisplayRegion

# Disassembly
sed -n '285215,285330p' .tmp/SkyLight.disasm
otool -tV .tmp/a73/01_CoreDisplay | grep -n -A 120 -B 4 '00007ff80541cf8a'
otool -tV .tmp/a73/01_CoreDisplay | grep -n -A 80 -B 4 '<_CGXCreateDisplayRegion>:'

# Vtable e tabella
xxd -g8 -s 0x57a130 -l 288 .tmp/a178/SkyLight
xxd -g8 -s 0x57a218 -l 32 .tmp/a178/SkyLight
# decodifica chained fixup: target = 0x7ff800000000 | (raw & 0xffffffff)
```

Tutti i comandi sono read-only rispetto al sistema. Le uniche scritture sono state:

```text
.tmp/a179/CoreGraphics
.tmp/a179_extract.log
T27-OOB-AGDC-DISPATCH-179.md
```

---

## 13. Spazio e STOP

```text
df -h /
/dev/disk1s1s1   466Gi   12Gi   14Gi   47%   /
```

Spazio libero: **circa 14 GiB** (≥ 10 GiB richiesti).

**STOP rispettato:** nessun boot, trace, modifica ai file di sistema, build o download. Nessuna cancellazione. Nessun file eliminabile proposto.

**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**
