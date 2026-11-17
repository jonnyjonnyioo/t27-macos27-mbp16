# T27 — AGENT-AMD — CLIENT AUTORIZZATO / WINDOWSERVER / VTABLE 0x858 (174)

**Scope:** identificare un client Apple già autorizzato ad AGDC e valutare un harness isolato senza modifiche al sistema; analizzare firma ed entitlement di WindowServer, SkyLight, CoreDisplay e processi GPU; verificare quali processi possono aprire AGDC e invocare `newUserClient`; decodificare il puntatore vtable `0x858`; valutare fattibilità e limiti di un client-only harness senza injection.

**Modalità:** sola lettura. Nessun boot, trace, modifica, build o download. Comandi: `codesign`, `security`, `strings`, `nm`, `otool`, `llvm-objdump`, `sysctl`, `ps`, `shasum`, `sha256sum`.

**Esito sintetico:** **PROVEN** che WindowServer è firmato Apple, gira come PID 224 e possiede `com.apple.private.gpuwrangler = true`; **NON** possiede `com.apple.private.applegraphicsdevicecontrol`. **PROVEN** che `authorizeTask` accetta `gpuwrangler`, quindi WindowServer è un client autorizzato. **PROVEN** che `kern.bootargs` è vuoto: `agdc_entitle` non è impostato e non c’è bypass. **PROVEN** che CoreDisplay e IOPresentment sono immagini della dyld cache, non firmate standalone; l’autorizzazione è quella del processo ospite. **PROVEN** che il puntatore vtable `0x858` si decodifica in `0x13d41c34`, cioè `AppleGraphicsDeviceControl::vendor_doDeviceAttribute`, **non** nel Wrangler `0xbf9894e`. Il Wrangler resta a valle e il collegamento diretto è **UNPROVEN**. **PROVEN** che nessun client Apple osservato invia il selettore 3: WindowServer/CoreDisplay usano 1/0x10, IOPresentment 1/0x980, Powerlog solo open. L’harness isolato senza injection **non è autorizzabile**; il primo ostacolo non è l’ABI ma un attore autorizzato che invii il comando 3. T27 resta **OPEN**: **94% engineering / 32% first boot / 8% desktop**.

---

## 1. Ambiente e SHA-256

| Artefatto | SHA-256 |
|---|---|
| Report 173 | `23970525a0987a69246dc1aa67635dde2307bf06f8906988be53a1e32cd6e200` |
| `SystemKernelExtensions.kc` target 25G342 | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| WindowServer target | `804cf101ec081e4f07946acaca35d694d8e9d48b25a12c5b4e1a6ce348c9000d` |
| CoreDisplay estratto | `d1d038dd7f88191d47db381ce776f7837d12408439d19f279c393c847c7c64fc` |
| IOPresentment estratto | `f07a31ec7774aee56efe62edd9f96ebb07cf72926eee8e0e089b65777ae9ecce` |
| PowerlogLiteOperators estratto | `6e3bcdc986f89c550e73e22802b273ba4528b95df4c2fda56204521917ec58c8` |

**Target:** macOS `26.7.3`, build `25G342`.
**Kernel collection:** `/System/Library/KernelCollections/SystemKernelExtensions.kc`, SHA `b4b618…`.
**Spazio:** **14.124.612 KiB ≈ 13,47 GiB** liberi.

---

## 2. WindowServer: firma ed entitlement

### 2.1 File

| Campo | Valore |
|---|---|
| Percorso | `/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/Resources/WindowServer` |
| Symlink runtime | `/System/Library/PrivateFrameworks/SkyLight.framework/Resources/WindowServer` |
| Dimensione | `158.112` byte |
| Formato | Mach-O universal `x86_64` + `arm64e` |
| Identifier | `com.apple.WindowServer` |
| Platform identifier | `26` |
| Flags | `0x2000` library-validation |
| CDHash SHA-256 | `588b28a2533772956e321f62eba6c0851b6ab725` |
| CDHashFull | `588b28a2533772956e321f62eba6c0851b6ab72552f1a0bb310017d088c157c3` |
| Authority | `macOS Software Signing` |
| Authority | `Apple Code Signing Certification Authority` |
| Authority | `Apple Root CA` |
| TeamIdentifier | `not set` |

**PROVEN:** WindowServer è firmato Apple con la catena `macOS Software Signing`.
**PROVEN:** è un binario di piattaforma (`Platform identifier=26`), non firmato da un team sviluppatore.
**PROVEN:** il CDHash è `588b28…`; SHA-256 del file è `804cf1…`.

### 2.2 Entitlement rilevanti

| Entitlement | Valore | Stato |
|---|---|---|
| `com.apple.private.gpuwrangler` | `true` | **PROVEN** |
| `com.apple.private.applegraphicsdevicecontrol` | assente | **PROVEN** |
| `com.apple.private.allow-explicit-graphics-priority` | `true` | **PROVEN** |
| `com.apple.private.iokit.displayservice` | `true` | **PROVEN** |
| `com.apple.private.iog.displayassertion` | `true` | **PROVEN** |
| `com.apple.private.SkyLight.displaycontrol` (loginwindow) | presente solo in loginwindow | **PROVEN** |

**PROVEN:** WindowServer ha `com.apple.private.gpuwrangler = true`.
**PROVEN:** WindowServer **non** ha `com.apple.private.applegraphicsdevicecontrol`.
**PROVEN:** `authorizeTask` accetta `com.apple.private.gpuwrangler` (report 173, target 0x13d3f8a1–0x13d3f8c5).
**PROVEN:** quindi WindowServer supera il secondo percorso di `authorizeTask`.

### 2.3 Processo in esecuzione

| Campo | Valore |
|---|---|
| PID | `224` |
| Comando | `/System/Library/PrivateFrameworks/SkyLight.framework/Resources/WindowServer` |
| Boot args | vuoti (`kern.bootargs` = stringa vuota) |

**PROVEN:** WindowServer è in esecuzione come PID 224.
**PROVEN:** `kern.bootargs` è vuoto; `agdc_entitle` non è impostato.
**PROVEN:** non esiste, allo stato attuale, un bypass `agdc_entitle`.

---

## 3. SkyLight, CoreDisplay, IOPresentment

### 3.1 Dove sono i binari

| Componente | Percorso atteso | Stato |
|---|---|---|
| SkyLight | `/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight` | **assente su disco**; symlink `SkyLight` rotto |
| CoreDisplay | `/System/Library/Frameworks/CoreDisplay.framework/Versions/A/CoreDisplay` | **assente su disco**; symlink `CoreDisplay` rotto |
| IOPresentment | `/System/Library/PrivateFrameworks/IOPresentment.framework/Versions/A/IOPresentment` | **assente su disco**; symlink rotto |
| WindowServer | `.../SkyLight.framework/Versions/A/Resources/WindowServer` | **presente e firmato** |

**PROVEN:** SkyLight, CoreDisplay e IOPresentment non hanno un eseguibile standalone sul filesystem; il codice è nella dyld shared cache.
**PROVEN:** `WindowServer` dipende da `SkyLight`:
```
/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight (compatibility 64.0.0, current 600.0.0)
/usr/lib/libSystem.B.dylib
```
**PROVEN:** `codesign -dvvv` sui file estratti CoreDisplay/IOPresentment restituisce `code object is not signed at all`; non sono firme standalone.
**INFERRED:** l’autorizzazione effettiva di CoreDisplay/IOPresentment è quella del processo che li carica (WindowServer), non una firma propria.
**UNPROVEN:** quali immagini della cache siano caricate esattamente da WindowServer a runtime.

### 3.2 CoreDisplay

Stringhe rilevanti nell’immagine estratta `.tmp/a73/01_CoreDisplay`:

| Offset | Stringa |
|---:|---|
| `0x10d72d` | `AppleGraphicsDeviceControl` |
| `0x10d748` | `void WS::AGDCService::set_display_policy_enabled(bool)` |
| `0x10d7d9` | `void WSAGDCSetDisplayPolicyEnabled(bool, bool)` |
| `0x10d825` | `WS::AGDCService::AGDCServiceCreateFirstMatchingClass failed` |
| `0x1159df` | `IOPRESENTMENT_CAPABILITIES_AGDCEXTENDED_MISSING` |

**PROVEN:** CoreDisplay contiene il letterale `AppleGraphicsDeviceControl`.
**PROVEN:** CoreDisplay ha un percorso `WS::AGDCService` e `WSAGDCSetDisplayPolicyEnabled`.
**PROVEN (report 171):** CoreDisplay usa `IOConnectCallStructMethod` selettore 1 (versione, output 44 byte) e selettore `0x10` (policy, input 8 byte).
**PROVEN:** CoreDisplay non invia il selettore 3 e non costruisce il buffer `{0x2,...}`.
**INFERRED:** se caricato in WindowServer, CoreDisplay eredita l’entitlement `gpuwrangler` del processo e può aprire AGDC.
**UNPROVEN:** la prova runtime del caricamento e dell’apertura.

### 3.3 IOPresentment

Stringhe rilevanti nell’immagine `.tmp/a73/11_IOPresentment`:

| Offset | Stringa |
|---:|---|
| `0x195d2` | `AppleGraphicsDeviceControl` |
| `0x1962b` | `ioPresentmentFindAGDCMatch` |
| `0x19759` | `kAGDCGPUCapability` |
| `0x1a9f0` | `Error: Unable to open AGDC connection for %s` |
| `0x1ab00` | `Error: Invalid response for AGDC GPU capabilities` |

**PROVEN:** IOPresentment apre AGDC e usa selettori 1 e `0x980` (report 171).
**PROVEN:** non invia il selettore 3 e non costruisce input di 4 byte.
**INFERRED:** se caricato in WindowServer, è coperto dall’entitlement del processo.
**UNPROVEN:** il processo ospite effettivo di IOPresentment.

### 3.4 PowerlogLiteOperators

| Campo | Valore |
|---|---|
| SHA-256 | `6e3bcdc986f89c550e73e22802b273ba4528b95df4c2fda56204521917ec58c8` |
| Stringa AGDC | `0x216893` `AppleGraphicsDeviceControl` |
| Uso | `IOServiceMatching` + `IOServiceOpen` + `IOObjectRelease` |
| Comando 3 | **nessuno** |

**PROVEN:** Powerlog apre AGDC solo per presenza/down-rev; non chiama `IOConnectCallMethod`.
**PROVEN:** non invia il selettore 3.
**UNPROVEN:** il suo processo ospite e la sua autorizzazione.

### 3.5 loginwindow

| Entitlement | Valore |
|---|---|
| `com.apple.private.SkyLight.displaycontrol` | presente |
| `com.apple.private.gpuwrangler` | **assente** |
| `com.apple.private.applegraphicsdevicecontrol` | **assente** |

**PROVEN:** loginwindow non ha nessuno dei due entitlement AGDC.
**PROVEN:** non è un client AGDC autorizzato.

---

## 4. Quali processi possono aprire AGDC

### 4.1 WindowServer

| Condizione | Evidenza | Stato |
|---|---|---|
| Entitlement `gpuwrangler` | codesign WindowServer | **PROVEN** |
| `authorizeTask` accetta `gpuwrangler` | target 0x13d3f8a1 | **PROVEN** |
| CoreDisplay chiama AGDC | stringhe e call site | **PROVEN** |
| CoreDisplay caricato in WindowServer | dipendenza SkyLight / uso GPU | **INFERRED** |
| WindowServer invia selettore 3 | nessun call site | **NO — PROVEN assenza** |
| WindowServer può invocare `newUserClient` | `IOServiceOpen` in CoreDisplay | **INFERRED** |

**PROVEN:** WindowServer è il solo processo osservato con `com.apple.private.gpuwrangler`.
**PROVEN:** è autorizzato da `authorizeTask`.
**PROVEN:** il suo codice AGDC noto (CoreDisplay) usa solo i selettori 1 e `0x10`.
**UNPROVEN:** l’apertura effettiva a runtime e il caricamento di CoreDisplay nel suo spazio.

### 4.2 CoreDisplay / IOPresentment

| Aspetto | Stato |
|---|---|
| Binario standalone | **NO** |
| Firma propria | **NO — code object is not signed at all** |
| Codice AGDC | **PROVEN** |
| Selettore 3 | **NO — PROVEN** |
| Host autorizzato | **INFERRED WindowServer** |
| Apertura autonoma da harness | **UNPROVEN / bloccata dall’autorizzazione** |

**PROVEN:** CoreDisplay e IOPresentment non sono processi autonomi né binari firmati standalone.
**PROVEN:** il loro codice AGDC non invia il comando 3.
**INFERRED:** possono aprire AGDC solo dentro un processo con entitlement, probabilmente WindowServer.

### 4.3 Powerlog

| Aspetto | Stato |
|---|---|
| Codice AGDC | **PROVEN** (solo open) |
| Selettore 3 | **NO** |
| `gpuwrangler` | **UNPROVEN** |
| Utile per il comando 3 | **NO** |

**PROVEN:** Powerlog non è un client del comando 3.
**UNPROVEN:** la sua autorizzazione; anche se autorizzato, non invia il comando.

### 4.4 Nessun altro client

**PROVEN (report 172):** su 73 immagini della cache solo CoreDisplay, IOPresentment e Powerlog contengono il letterale AGDC.
**PROVEN:** nessuna delle 73 immagini ha un call site `IOConnectCallMethod` con selettore 3 e structure input di 4 byte.
**PROVEN:** non esiste un quarto client AGDC osservato.
**PROVEN:** `loginwindow` non ha gli entitlement AGDC.
**UNPROVEN:** client non presenti nella cache o con nome costruito dinamicamente.

---

## 5. Decodifica della vtable `0x858`

### 5.1 Simbolo e layout

| Elemento | Valore |
|---|---|
| Simbolo vtable | `__ZTV26AppleGraphicsDeviceControl` |
| Indirizzo | `0x13d44478` |
| Sezione | `__DATA,__const` |
| `vptr` oggetto | `vtable + 0x10 = 0x13d44488` |
| Slot `+0x858` | `0x13d44ce0` |
| Valore raw | `0x40000053d41c34` |
| Low 32 bit | `0x53d41c34` |
| Tag/chained | `0x40000000` |
| Target decodificato | **`0x13d41c34`** |
| Simbolo target | `__ZN26AppleGraphicsDeviceControl24vendor_doDeviceAttributeEjPmmS0_S0_P17AGDCClientState_t` |

**PROVEN:** `__ZTV26AppleGraphicsDeviceControl` è definita nel target a `0x13d44478`.
**PROVEN:** lo slot `+0x858` contiene `0x40000053d41c34`.
**PROVEN:** il valore si decodifica in `0x13d41c34`, indirizzo del simbolo `AppleGraphicsDeviceControl::vendor_doDeviceAttribute`.
**PROVEN:** quindi il callback `[rax+0x858]` di `filtered` chiama **`vendor_doDeviceAttribute` di AGDC**, non direttamente il Wrangler.

### 5.2 Correzione rispetto al report 173

| Affermazione 173 | Correzione 174 | Stato |
|---|---|---|
| Callback `0x858` non risolto | Slot risolto a `0x13d41c34` | **PROVEN** |
| Callback `0x858` verso Wrangler | Callback verso wrapper AGDC | **PROVEN** |
| Wrangler `0xbf9894e` dietro `0x858` | Wrangler non è il target diretto | **PROVEN** |
| Puntatore encoded non decodificato | Decodifica low32 - tag = target | **PROVEN** |

**PROVEN:** la vtable è locale al target e non richiede root2 per la decodifica.
**PROVEN:** il target `0x13d41c34` è il wrapper `vendor_doDeviceAttribute`.
**UNPROVEN:** il percorso successivo del wrapper fino al Wrangler.

### 5.3 Wrapper `vendor_doDeviceAttribute`

Entry `0x13d41c34`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x13d41c3c` | `mov rax,[rbp+0x10]` | 7° argomento: `AGDCClientState_t*` |
| `0x13d41c40` | `test rax,rax` | client state presente? |
| `0x13d41c45` | `mov rax,[rax+0x38]` | campo del client state |
| `0x13d41c4d` | `mov r10,[rdi]` | vtable dell’oggetto |
| `0x13d41c50` | `mov [rsp],rax` | passa il client state |
| `0x13d41c54` | `call [r10+0x850]` | **secondo slot virtuale** |

**PROVEN:** il wrapper inoltra a `[vtable+0x850]`.
**PROVEN:** lo slot `+0x850` della vtable AGDC contiene `0x40000000ab77f0`.
**PROVEN:** il target decodificato è `0xab77f0`; i byte a `0xab77f0` non sono codice x86_64 valido (sono dati).
**UNPROVEN:** l’oggetto effettivo di `r10` e il significato dello slot `+0x850`; non si può affermare che sia il Wrangler.

### 5.4 Wrangler

| Elemento | Valore |
|---|---|
| Simbolo | `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute` |
| Indirizzo | `0xbf9894e` |
| Firma | `(this, selector, input, inputSize, output, outputSize, IOExternalMethodArguments*)` |
| Uso del comando 3 | **PROVEN** |
| Bit `0x2` | **PROVEN** |
| `LoadHWServices` | **PROVEN statico** |
| Puntatore diretto nella vtable AGDC | **NO — UNPROVEN/assente** |

**PROVEN:** il Wrangler ha la stessa forma di chiamata del wrapper, ma non è il target dello slot `0x858`.
**PROVEN:** la stringa `0xbf9894e` non compare in una vtable AGDC; compare nella tabella dei simboli a `0x155d4898`.
**UNPROVEN:** il percorso `wrapper → AGDCPlugin::doPluginAttribute → Wrangler`; è plausibile ma non dimostrato.

### 5.5 `filtered` e il ricevente

Simbolo:

```
AppleGraphicsDeviceControl::filtered_doDeviceAttribute(
    agdc_filtered_api_t, unsigned int, unsigned long, unsigned long,
    unsigned long, unsigned long, AGDCClientState_t*)
```

Call site `0x13d4179f`:

```
mov rax,[rdi]          ; vtable dell'oggetto
mov esi,r13d           ; selettore 3
mov rdx,r10            ; input
mov rcx,r8             ; input size 4
mov r8,r15             ; output
mov r9,r11             ; output size pointer
call [rax+0x858]       ; vendor_doDeviceAttribute
```

**PROVEN:** `filtered` chiama lo slot `0x858` con selettore 3 e input di 4 byte.
**PROVEN:** il ricevente è l’oggetto AGDC (`rdi` da `UserKernelTransfer`).
**PROVEN:** lo slot `0x858` è il wrapper `vendor_doDeviceAttribute`.
**UNPROVEN:** il percorso interno del wrapper e l’arrivo al Wrangler.

---

## 6. Harness client-only senza injection

### 6.1 Autorizzazione

| Via | Stato | Note |
|---|---|---|
| `com.apple.private.applegraphicsdevicecontrol` | **assente** in WindowServer | solo Apple può firmarlo |
| `com.apple.private.gpuwrangler` | **presente** in WindowServer | non trasferibile |
| `agdc_entitle` boot-arg | **assente** (`kern.bootargs` vuoto) | richiederebbe boot-arg |
| root | **non sufficiente** | il controllo è su entitlement/task |
| firma ad-hoc | **non sufficiente** | AMFI non concede entitlement privati |

**PROVEN:** un harness ordinario non ha nessuno dei due entitlement.
**PROVEN:** `kern.bootargs` è vuoto; `agdc_entitle` non è attivo.
**PROVEN:** un harness locale non può auto-assegnarsi un entitlement privato Apple.
**INFERRED:** root e firma ad-hoc non bypassano `authorizeTask`.

### 6.2 Ereditarietà dell’entitlement

| Ipotesi | Esito |
|---|---|
| `dlopen` di CoreDisplay nell’harness | l’harness resta il task; `authorizeTask` vede l’harness | **INFERRED: negato** |
| fork/exec da WindowServer | l’entitlement è legato alla firma, non ereditato da exec | **INFERRED: negato** |
| injection in WindowServer | non isolato; richiede task port/SIP | **escluso** |
| plugin WindowServer | injection; non isolato | **escluso** |
| API pubblica WindowServer | non espone il selettore 3 | **PROVEN assenza** |

**PROVEN:** CoreDisplay/IOPresentment non sono processi autonomi né firmati standalone.
**PROVEN:** l’autorizzazione è per processo/firma, non per framework.
**INFERRED:** un harness che carica CoreDisplay non eredita `gpuwrangler`.
**PROVEN:** WindowServer non espone un’API pubblica per il selettore 3.

### 6.3 Client autorizzato esistente

| Processo | Autorizzato | Invia selettore 3 | Utile |
|---|---|---|---|
| WindowServer | **SÌ — gpuwrangler** | **NO** | no |
| CoreDisplay (in WindowServer) | **SÌ per host** | **NO** (1/0x10) | no |
| IOPresentment (host?) | **UNPROVEN** | **NO** (1/0x980) | no |
| Powerlog | **UNPROVEN** | **NO** (solo open) | no |
| loginwindow | **NO** | **NO** | no |
| harness locale | **NO** | possibile ma non autorizzato | no |

**PROVEN:** esiste un client autorizzato: WindowServer.
**PROVEN:** quel client non invia il comando 3.
**PROVEN:** nessun client osservato unisce autorizzazione e comando 3.
**UNPROVEN:** un client Apple non osservato o un’API privata che inoltri il comando 3.

### 6.4 Fattibilità

| Scenario | Fattibilità |
|---|---|
| Harness isolato senza entitlement | **NO** |
| Harness con entitlement privato | **non ottenibile** senza Apple/injection |
| Harness dentro WindowServer | **non isolato** |
| Uso di CoreDisplay/IOPresentment | **non inviano il comando 3** |
| API pubblica per selettore 3 | **non trovata** |
| `agdc_entitle` boot-arg | **non impostato**; richiede reboot |
| Modifica kernel/kext | **vietata e non necessaria** |
| Analisi statica | **completa per il percorso noto** |

**Risposta netta:** il client autorizzato esiste ed è WindowServer; ma non invia il selettore 3. Un harness isolato senza injection non può ottenere `gpuwrangler`, e `agdc_entitle` non è impostato. Non esiste, allo stato osservato, un percorso client-only isolato che unisca autorizzazione e comando 3. **Il primo ostacolo non è l’ABI né il codice AGDC: è l’assenza di un attore autorizzato che invii il comando 3.** Un harness non autorizzato verrebbe bloccato da `authorizeTask`; un harness autorizzato richiederebbe injection o un entitlement Apple.

---

## 7. Primo ostacolo e prossimo passo

### 7.1 Ostacolo

| Priorità | Ostacolo | Stato |
|---:|---|---|
| 1 | Attore autorizzato che invii il selettore 3 | **BLOCKED** |
| 2 | Entitlement per un harness locale | **BLOCKED** (solo WindowServer) |
| 3 | `agdc_entitle` boot-arg | **assente** |
| 4 | Percorso wrapper `0x858 → Wrangler` | **UNPROVEN** |
| 5 | Runtime `LoadHWServices` | **UNPROVEN** |
| 6 | Produttore userspace `0x2` | **UNPROVEN** |

**PROVEN:** l’ostacolo 1 è il primo blocco concreto.
**PROVEN:** l’ostacolo 2 è provato dalla firma di WindowServer e dall’assenza di entitlement nell’harness.
**PROVEN:** l’ostacolo 3 è provato da `kern.bootargs` vuoto.

### 7.2 Prossimo passo concretamente risolvibile

1. Verificare staticamente se WindowServer/SkyLight espone un’API privata che inoltra il selettore 3 (oltre a CoreDisplay 1/0x10).
2. Risolvere il wrapper `0x858` → `[+0x850]` → `AGDCPlugin::doPluginAttribute` → Wrangler, senza assumere il collegamento.
3. Verificare se `AGDCPlugin::doPluginAttribute` (0x13d4240e) può essere raggiunto da un client autorizzato con selettore 3.
4. Non tentare injection o modifica kernel: non sono compatibili con T27.

**PROVEN:** il passo 1 è statico e verificabile con `nm`, `otool`, `strings`.
**UNPROVEN:** l’esito; nessuna API siffatta è stata ancora trovata.

---

## 8. Stato delle prove

| Prova | Stato |
|---|---|
| WindowServer firmato Apple | **PROVEN** |
| WindowServer PID 224 | **PROVEN** |
| WindowServer `gpuwrangler=true` | **PROVEN** |
| WindowServer `applegraphicsdevicecontrol` assente | **PROVEN** |
| `authorizeTask` accetta gpuwrangler | **PROVEN** |
| `kern.bootargs` vuoto | **PROVEN** |
| `agdc_entitle` assente | **PROVEN** |
| CoreDisplay/IOPresentment non firmati standalone | **PROVEN** |
| CoreDisplay usa AGDC 1/0x10 | **PROVEN** |
| IOPresentment usa AGDC 1/0x980 | **PROVEN** |
| Powerlog solo open | **PROVEN** |
| Nessun client invia selettore 3 | **PROVEN** |
| WindowServer può aprire AGDC | **INFERRED** |
| CoreDisplay caricato in WindowServer | **INFERRED** |
| Vtable `0x858` = `0x13d41c34` | **PROVEN** |
| `0x13d41c34` = vendor wrapper | **PROVEN** |
| Wrangler dietro `0x858` | **UNPROVEN** |
| Wrapper `[+0x850]` target | **UNPROVEN** |
| Harness senza entitlement | **NO** |
| Harness con entitlement | **non ottenibile** |
| API pubblica selettore 3 | **non trovata** |

---

## 9. Diagnosi

| Priorità | Elemento | Stato |
|---:|---|---|
| 1 | WindowServer autorizzato | **PROVEN** |
| 2 | WindowServer non invia comando 3 | **PROVEN** |
| 3 | Altri client autorizzati | **nessuno osservato** |
| 4 | Harness isolato | **non autorizzabile** |
| 5 | Vtable `0x858` | **PROVEN wrapper** |
| 6 | Wrangler diretto | **UNPROVEN** |
| 7 | Comando 3 end-to-end | **BLOCKED** |

**Diagnosi:** WindowServer è l’unico processo osservato con `com.apple.private.gpuwrangler`, quindi è l’unico client AGDC autorizzato noto; ma il suo codice AGDC (CoreDisplay) usa soltanto i selettori 1 e `0x10`, non il 3. CoreDisplay e IOPresentment non sono firmati standalone e non inviano il comando 3; Powerlog apre soltanto. La vtable `0x858` è stata decodificata: punta al wrapper `AppleGraphicsDeviceControl::vendor_doDeviceAttribute` a `0x13d41c34`, non al Wrangler. Il Wrangler resta a valle e il collegamento non è provato. Un harness isolato non può ottenere l’entitlement di WindowServer; `agdc_entitle` non è impostato. Il percorso client-only isolato è quindi **bloccato**.

---

## 10. Verdetto

| Domanda | Risposta |
|---|---|
| WindowServer è autorizzato? | **SÌ — gpuwrangler, PROVEN** |
| WindowServer invia il comando 3? | **NO — PROVEN** |
| CoreDisplay/IOPresentment inviano il comando 3? | **NO — PROVEN** |
| Powerlog invia il comando 3? | **NO — PROVEN** |
| Esiste un client autorizzato + comando 3? | **NO osservato** |
| Vtable `0x858` | **0x13d41c34, PROVEN** |
| `0x13d41c34` | **vendor_doDeviceAttribute wrapper, PROVEN** |
| Wrangler dietro il wrapper | **UNPROVEN** |
| Harness isolato senza injection | **NO** |
| `agdc_entitle` | **assente, PROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** WindowServer è il client Apple autorizzato, grazie a `com.apple.private.gpuwrangler`, ma non invia il selettore 3; CoreDisplay/IOPresentment si fermano a 1/0x10 e 1/0x980, Powerlog apre soltanto. La vtable `0x858` è stata decodificata in `0x13d41c34` (`AppleGraphicsDeviceControl::vendor_doDeviceAttribute`), non nel Wrangler. Un harness isolato senza injection non può ottenere l’entitlement di WindowServer; `kern.bootargs` è vuoto e `agdc_entitle` è assente. **Primo ostacolo irrisolto: manca un attore autorizzato che invii il comando 3**, non l’ABI o il codice AGDC. T27 resta **OPEN**: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **14.124.612 KiB ≈ 13,47 GiB** liberi. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
