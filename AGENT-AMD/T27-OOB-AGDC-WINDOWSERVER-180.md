# T27 — OOB AGDC — WindowServer executable — Report 180

**Data:** 17 novembre 2026
**Sistema:** macOS 26.7.3 build 25G342, MacBookPro16,1
**Modalità:** sola analisi statica; nessun boot, trace, modifica, build o download.
**Vincolo spazio:** minimo 10 GiB liberi; nessun file eliminabile proposto.
**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**

---

## 1. Oggetto e hash

### 1.1 Binario originale

```text
/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/Resources/WindowServer
SHA-256: 804cf101ec081e4f07946acaca35d694d8e9d48b25a12c5b4e1a6ce348c9000d
formato: Mach-O universal (x86_64 arm64e)
```

### 1.2 Slice x86_64 analizzata

```text
HAO-PROJECT/T27/AGENT-AMD/.tmp/WindowServer.x86_64
SHA-256: 3a27afe3a84561dad412d917764d571f9915f85e4925e9a9a57900b6edb9e110
formato: Mach-O 64-bit executable x86_64
```

La slice x86_64 è quella effettivamente usata dall'host MacBookPro16,1 e quella già impiegata nei report precedenti. L'hash della slice è distinto da quello del file universale: entrambi sono riportati per evitare ambiguità.

### 1.3 Altri oggetti di riferimento

```text
SkyLight
SHA-256: 1e8ead0ceaf2b8a2fe2c167fa299142939ec579f9df60ab30dae8a5c513bea56

CoreGraphics
SHA-256: 34a2683052af18ae68ae66d6f6de08ee5b0111277627d0c9f67bd16d8174b6e0

CoreDisplay
SHA-256: d1d038dd7f88191d47db381ce776f7837d12408439d19f279c393c847c7c64fc

SystemKernelExtensions.kc
SHA-256: b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7
```

Report:

```text
HAO-PROJECT/T27/AGENT-AMD/T27-OOB-AGDC-WINDOWSERVER-180.md
```

---

## 2. Obiettivo del PROMPT 180

Verificare l'ultimo candidato logico del filone AMD/AGDC: **l'eseguibile WindowServer stesso**, non i framework che importa.

La domanda è:

> WindowServer contiene un call site diretto o indiretto verso AGDC selector 3, oppure tutto il percorso grafico passa esclusivamente per `_SLXServer` in SkyLight?

L'analisi è read-only. Non sono stati eseguiti il processo, il boot o trace.

---

## 3. Risultato sintetico

**PROVEN:** WindowServer x86_64 è un loader minimale.

**PROVEN:** importa **un solo** simbolo da SkyLight:

```text
_SLXServer
```

**PROVEN:** non importa alcuna API IOKit:

```text
IOConnectCallMethod            0
IOConnectCallStructMethod      0
IOConnectCallScalarMethod      0
IOServiceOpen                  0
IOServiceMatching              0
```

**PROVEN:** non contiene `dlsym`/`dlopen`.

**PROVEN:** non contiene le stringhe:

```text
AppleGraphicsDeviceControl
AppleGraphicsControl
AGDC
WSAGDC
CGXUpdateDesktop
LoadHWServices
```

**PROVEN:** l'unico call site rilevante è:

```asm
0x1000006cc  callq _SLXServer
```

**Conclusione statica:** WindowServer non può inviare direttamente AGDC selector 3. Non ha né i simboli IOKit né un resolver dinamico per ottenerli. Tutto il percorso grafico passa per `_SLXServer`, già analizzato nei Report 178 e 179.

---

## 4. Struttura del binario

### 4.1 Librerie collegate

```sh
otool -L .tmp/WindowServer.x86_64
```

```text
/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight
/usr/lib/libSystem.B.dylib
```

**PROVEN:** WindowServer non è collegato direttamente a IOKit, CoreGraphics, CoreDisplay o AGDC.
**PROVEN:** l'unica libreria grafica è SkyLight.

### 4.2 Import totali

```sh
nm -m .tmp/WindowServer.x86_64 | grep -c undefined
```

```text
23
```

Elenco completo:

```text
_SLXServer                    (SkyLight)
___assert_rtn                 (libSystem)
___bzero                      (libSystem)
___error                      (libSystem)
___stack_chk_fail             (libSystem)
___stack_chk_guard            (libSystem)
__os_log_debug_impl           (libSystem)
__os_log_default              (libSystem)
__os_log_error_impl           (libSystem)
__set_user_dir_suffix         (libSystem)
_confstr                      (libSystem)
_exit                         (libSystem)
_free                         (libSystem)
_getenv                       (libSystem)
_getpwuid                     (libSystem)
_getuid                       (libSystem)
_mkdir                        (libSystem)
_os_log_type_enabled          (libSystem)
_realpath$DARWIN_EXTSN        (libSystem)
_sandbox_init_with_parameters (libSystem)
_setegid                      (libSystem)
_seteuid                      (libSystem)
_strerror                     (libSystem)
```

**PROVEN:** l'unico import non-libSystem è `_SLXServer`.
**PROVEN:** non ci sono import IOKit, AGDC o `WSAGDCSetDebugOptions`.

### 4.3 Entry point e chiamata a SkyLight

```asm
0000000100000698  pushq %rbp
0000000100000699  movq %rsp,%rbp
000000010000069c  pushq %r14
000000010000069e  pushq %rbx
000000010000069f  movq %rsi,%rbx
00000001000006a2  movl %edi,%r14d
00000001000006a5  movl $0x58,%edi
00000001000006aa  callq _setegid
00000001000006af  testl %eax,%eax
00000001000006b1  jne 0x1000006d1
00000001000006b3  movl $0x58,%edi
00000001000006b8  callq _seteuid
00000001000006bd  testl %eax,%eax
00000001000006bf  jne 0x1000006f0
00000001000006c1  callq 0x10000070f
00000001000006c6  movl %r14d,%edi
00000001000006c9  movq %rbx,%rsi
00000001000006cc  callq _SLXServer
```

**PROVEN:** WindowServer passa `argc`/`argv` a `_SLXServer`; non prepara buffer, selettori o connessioni AGDC.
**PROVEN:** il binario non contiene un secondo percorso grafico.

---

## 5. Assenza di AGDC nel testo e nei dati

### 5.1 Stringhe

```sh
strings .tmp/WindowServer.x86_64 | grep -iE \
  'AppleGraphicsDeviceControl|AppleGraphicsControl|AGDC|WSAGDC|CGXUpdateDesktop|LoadHWServices'
```

Risultato:

```text
(nessuna occorrenza)
```

**PROVEN:** WindowServer non contiene il nome del servizio AGDC, il wrapper `WSAGDCSetDebugOptions`, il simbolo `CGXUpdateDesktop` o la stringa `LoadHWServices`.

### 5.2 Call site

```sh
otool -tV .tmp/WindowServer.x86_64 | grep -n -E \
  'IOConnectCall(Method|StructMethod|ScalarMethod)|IOServiceOpen|_SLXServer|CGXUpdateDesktop|WSAGDC'
```

Risultato:

```text
20:00000001000006cc  callq 0x100000bd4  ## symbol stub for: _SLXServer
```

**PROVEN:** l'unico call site grafico è `_SLXServer`.
**PROVEN:** non ci sono call site `IOConnectCallMethod`, `IOConnectCallStructMethod`, `IOConnectCallScalarMethod` o `IOServiceOpen`.

### 5.3 Assenza di resolver dinamico

`nm -m` e `otool -tV` non mostrano:

```text
_dlsym
_dlopen
_dlopen_preflight
```

**PROVEN:** WindowServer non può risolvere a runtime un simbolo IOKit/AGDC non presente nella tabella degli import.

---

## 6. Conseguenza: l'unico ponte è `_SLXServer`

Il percorso statico completo è:

```text
WindowServer main
  -> _SLXServer (SkyLight)
       -> inizializzazione SkyLight
       -> CoreDisplayManager::set_debug_options
       -> WSAGDCSetDebugOptions (CoreDisplay)
       -> gWSCallbacks + 0x628
       -> CGXUpdateDesktop (SkyLight)
       -> *0xe8 -> create_overall_region()
       -> CGXCreateDisplayRegion (CoreDisplay)
       -> CGRegion* / session data
```

I Report 178 e 179 hanno già dimostrato che questa catena:

- non importa `IOConnectCallMethod` o `IOConnectCallStructMethod`;
- usa solo due `IOConnectCallScalarMethod`, con selettori `0x1c90` e `0`;
- non contiene `AppleGraphicsDeviceControl`;
- non invia AGDC selector 3;
- termina in un aggiornamento geometrico del desktop.

**PROVEN:** WindowServer non aggiunge alcun percorso AGDC a monte di `_SLXServer`.
**PROVEN:** l'eseguibile non è un client AGDC diretto.

---

## 7. Entitlement

Dal Report 178, WindowServer ha:

```text
com.apple.private.gpuwrangler = true
com.apple.private.iokit.displayservice = true
com.apple.private.iokit.rootdomain-set-property = true
com.apple.private.iomfb.set-block = true
com.apple.private.iomfb.set-block-client-profile = true
```

**PROVEN:** l'entitlement `com.apple.private.gpuwrangler` è presente.
**PROVEN:** non esiste un entitlement chiamato `agdc_entitle`.

**INFERRED:** l'entitlement abilita WindowServer a usare servizi grafici tramite SkyLight, ma non crea un call site AGDC che il binario non contiene.

**UNPROVEN:** un eventuale percorso runtime attivato da una funzione di SkyLight non osservata staticamente. Non è stata trovata evidenza.

---

## 8. PROVEN / INFERRED / UNPROVEN

### PROVEN

1. WindowServer x86_64 ha SHA-256 `3a27afe3a84561dad412d917764d571f9915f85e4925e9a9a57900b6edb9e110`.
2. È un Mach-O executable x86_64.
3. È collegato solo a SkyLight e libSystem.
4. Ha 23 import totali.
5. L'unico import non-libSystem è `_SLXServer`.
6. Non importa `IOConnectCallMethod`, `IOConnectCallStructMethod`, `IOConnectCallScalarMethod` o `IOServiceOpen`.
7. Non importa `dlsym`, `dlopen` o `dlopen_preflight`.
8. Non contiene stringhe `AppleGraphicsDeviceControl`, `AppleGraphicsControl`, `AGDC`, `WSAGDC`, `CGXUpdateDesktop` o `LoadHWServices`.
9. L'unico call site grafico è `0x1000006cc -> _SLXServer`.
10. `main` passa `argc`/`argv` a `_SLXServer`; non prepara comandi AGDC.
11. WindowServer non può inviare direttamente AGDC selector 3.
12. L'unico percorso grafico è `_SLXServer`, già chiuso dai Report 178 e 179.

### INFERRED

1. WindowServer è un loader/sandbox bootstrap che delega tutta la logica del server a SkyLight.
2. L'entitlement `gpuwrangler` autorizza il processo, ma non introduce da solo un invio AGDC.

### UNPROVEN

1. Una modifica runtime di SkyLight o di una function pointer dopo l'inizializzazione non è osservabile staticamente.
2. Non è stata eseguita alcuna verifica runtime; nessun boot, trace o injection.
3. Restano possibili API private in binari non estratti; questo report chiude l'eseguibile WindowServer, non l'intero universo delle API private di macOS.

---

## 9. Verdetto

| Domanda | Esito |
|---|---|
| WindowServer è un client AGDC diretto | **NO, PROVEN** |
| WindowServer importa IOKit | **NO, PROVEN** |
| WindowServer importa `IOConnectCall*` | **NO, PROVEN** |
| WindowServer usa `dlsym`/`dlopen` | **NO, PROVEN** |
| WindowServer contiene stringhe AGDC | **NO, PROVEN** |
| WindowServer ha un call site AGDC selector 3 | **NO, PROVEN** |
| WindowServer ha un solo ponte grafico | **SÌ, PROVEN — `_SLXServer`** |
| Quel ponte raggiunge AGDC selector 3 | **NO, PROVEN dai Report 178–179** |
| Resta un percorso runtime non osservato | **SÌ, UNPROVEN — nessuna evidenza** |
| T27 | **OPEN — 94% engineering / 32% first boot / 8% desktop** |

**Risposta netta:** l'eseguibile WindowServer non è un client AGDC. È un loader minimale che importa solo `_SLXServer` da SkyLight e 22 simboli libSystem. Non ha import IOKit, non ha resolver dinamico e non contiene stringhe o call site AGDC. L'unico percorso grafico è SkyLight, già chiuso staticamente: `WSAGDCSetDebugOptions -> CGXUpdateDesktop -> create_overall_region -> CGXCreateDisplayRegion`, senza AGDC selector 3.

**Impatto sul filone AMD/AGDC:** con WindowServer escluso come client diretto, non resta alcun attore Apple noto, nei componenti esaminati, che invii AGDC selector 3. Il compatibility layer client-only non può usare WindowServer come ponte AGDC. La conclusione statica del Report 179 è definitiva per l'eseguibile; resta solo l'incertezza runtime non osservata.

---

## 10. Comandi eseguiti

```sh
file .tmp/WindowServer.x86_64
shasum -a 256 .tmp/WindowServer.x86_64
otool -L .tmp/WindowServer.x86_64
nm -m .tmp/WindowServer.x86_64 | grep -E \
  'IOConnectCall|IOService|AGDC|SLXServer|CGXUpdateDesktop|WSAGDC|dlsym|dlopen'
nm -m .tmp/WindowServer.x86_64 | grep -c undefined
nm -m .tmp/WindowServer.x86_64 | grep undefined
nm -u .tmp/WindowServer.x86_64
strings .tmp/WindowServer.x86_64 | grep -iE \
  'AppleGraphicsDeviceControl|AppleGraphicsControl|AGDC|WSAGDC|CGXUpdateDesktop|LoadHWServices'
otool -tV .tmp/WindowServer.x86_64 | grep -n -E \
  'IOConnectCall(Method|StructMethod|ScalarMethod)|IOServiceOpen|_SLXServer|CGXUpdateDesktop|WSAGDC'
otool -tV .tmp/WindowServer.x86_64 | sed -n '1,35p'
```

Tutti i comandi sono read-only rispetto al sistema. Le uniche scritture sono state:

```text
.tmp/a179/CoreGraphics
.tmp/a179_extract.log
T27-OOB-AGDC-DISPATCH-179.md
T27-OOB-AGDC-WINDOWSERVER-180.md
```

---

## 11. Spazio e STOP

```text
df -h /
/dev/disk1s1s1   466Gi   12Gi   14Gi   47%   /
```

Spazio libero: **circa 14 GiB** (≥ 10 GiB richiesti).

**STOP rispettato:** nessun boot, trace, modifica ai file di sistema, build o download. Nessuna cancellazione. Nessun file eliminabile proposto.

**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**
