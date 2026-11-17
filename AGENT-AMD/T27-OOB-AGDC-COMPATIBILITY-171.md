# T27 — AGENT-AMD — TERZO CLIENT AGDC / COMPATIBILITY LAYER (171)

**Scope:** estendere la ricerca a tutti i client userspace della dyld shared cache, framework, plugin e servizi AMD/Apple; cercare `IOConnectCallMethod` con selettore 3 e structure input di almeno 4 byte; ricostruire i produttori indiretti del bit `0x2`; valutare un **AGDC Compatibility Layer** minimo e isolato; distinguere codice Apple riutilizzabile, comportamento riproducibile e componenti da ricreare.

**Modalità:** sola lettura. Nessun boot, trace, modifica ai file di sistema, build o download. Comandi: `find`, `grep`, `sed`, `otool`, `ipsw dyld`, `strings`, `shasum`, `sha256sum`, `df`, `sw_vers`.

**Esito sintetico:** **PROVEN** che nella dyld shared cache x86_64h del target 25G342 il letterale `AppleGraphicsDeviceControl` compare in **esattamente tre immagini**: `CoreDisplay`, `IOPresentment`, `PowerlogLiteOperators`. **PROVEN** che Powerlog è un terzo client AGDC, ma solo di **presenza/apertura** (`IOServiceMatching` → `IOServiceGetMatchingService` → `IOServiceOpen` → `IOObjectRelease`), senza alcun `IOConnectCallMethod` nel percorso AGDC. **PROVEN** che nessuno dei tre client AGDC invia il selettore 3 con structure input di 4 byte. **PROVEN** che 73 immagini importano `IOConnectCallMethod`; la scansione completa dei loro call site non è stata possibile perché le immagini sono nella cache e non hanno file standalone. **UNPROVEN** il produttore userspace del bit `0x2`. **Valutazione compatibility layer:** un layer **client-only** è condizionato alla presenza del servizio AGDC, all’entitlement e al callback AMD; un layer che sostituisca AGDC o il Wrangler **non è realizzabile in userspace**. T27 resta **OPEN**: **94% engineering / 32% first boot / 8% desktop**.

---

## 1. Ambiente e SHA-256

| Artefatto | SHA-256 |
|---|---|
| Report 170 | `4c1a78cc6839a56bd57234a28bd1096ede6f1754b677c86d4f0a9929629d0ff4` |
| `PowerlogLiteOperators` estratto (target 25G342) | `6e3bcdc986f89c550e73e22802b273ba4528b95df4c2fda56204521917ec58c8` |
| AGDC root2 26.7.2/25G325 | `a3effd46c2c22692019da818ecab43703b44bcb5e2357c174d1b1546fcc633a3` |
| AGDC `Info.plist` root2/target | `d521d429dbf95570ec5f6469d1286a846d30739be75e2fe1e1af6244431a5188` |
| AGDC KDK 27.2/26B116 | `ea39241b0c99dae2fb4dd81a33af0b36e1c0ffd1ad04283140ea51555486a1d7` |
| `CoreDisplay.compact` | `b7abdcfe3af5c64716f64a38e4002b0ebd432fc5ed7bbf7dc09709c6768d6b75` |
| `IOPresentment.compact` | `9d6da75a461d2ea9fa521f39a0da17cb047799414f93b17cc8829dd8bd1efc5f` |
| `GPUWrangler` `Info.plist` | `6d290a14ad04eaaa0d61c0eb668058471b39e2e4edfe287590c2fae8f2038c79` |

**Target osservato:** macOS `26.7.3`, build `25G342`.
**Cache:** `/System<VOLUME>/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_x86_64h`, con subcache `.01`–`.06`.
**Powerlog:** `PowerlogLiteOperators` 3,4 MB, UUID `BDE491D7-832D-3029-9DAF-834F8F060B80`, `minos 26.7`, `SDK 26.7.2`, source `3031.160.6`.
**Spazio:** **14.124.612 KiB ≈ 13,47 GiB** liberi su `/System<VOLUME>/Data`; sopra la soglia di 10 GiB.
**Stato AGDC target:** `Info.plist` presente e byte-identico a root2; **eseguibile AGDC assente**.

### 1.1 Perché il target è la cache, non i bundle

I bundle `CoreDisplay.framework`, `IOPresentment.framework`, `PowerlogLiteOperators.framework` e `GPUWrangler.framework` esistono come directory, ma i rispettivi eseguibili **non sono file standalone**: il codice è nella dyld shared cache. La verifica `test -f` sui 73 path elencati dalla cache ha restituito **0 file presenti**: non è un errore di path, è il modello di distribuzione della cache.

**PROVEN:** non è possibile scansionare i 73 binari con `otool` direttamente dal filesystem.
**PROVEN:** le immagini analizzate sono state estratte dalla cache o ricostruite da `ipsw`.
**UNPROVEN:** che un’immagine non estratta contenga un client AGDC dinamico.

---

## 2. Copertura della ricerca

### 2.1 Ricerca del servizio

Comando:

```sh
ipsw dyld str \
  /System<VOLUME>/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_x86_64h \
  AppleGraphicsDeviceControl
```

Risultato esatto:

```text
0x7ff80545572d: "AppleGraphicsDeviceControl"  image=CoreDisplay
0x7ff81599f5d2: "AppleGraphicsDeviceControl"  image=IOPresentment
0x7ffa07631893: "AppleGraphicsDeviceControl"  image=PowerlogLiteOperators
```

**PROVEN:** il letterale del servizio compare in **tre** immagini della cache userspace.
**PROVEN:** la terza immagine è `PowerlogLiteOperators`, non un driver grafico.
**PROVEN:** la ricerca `LoadHWServices` nella stessa cache non ha restituito occorrenze userspace.
**UNPROVEN:** un nome di servizio costruito dinamicamente o una chiamata senza letterale.

### 2.2 Importatori di `IOConnectCallMethod`

| Ricerca | Esito |
|---|---|
| Immagini che importano `IOConnectCallMethod` | **73** |
| Immagini con letterale `AppleGraphicsDeviceControl` | **3** |
| Immagini con `WS::AGDCService` | **CoreDisplay** |
| Immagini con `AppleGPUWrangler` | **GPUWrangler / IOPresentment** |
| Immagini con `AppleGraphicsControl` | **CoreDisplay (AGC/mux)** |
| Immagini con `LoadHWServices` | **0 nella cache userspace** |

**PROVEN:** 73 immagini sono client IOKit generici; non sono 73 client AGDC.
**PROVEN:** la presenza del letterale restringe i client AGDC candidati a tre.
**UNPROVEN:** che le altre 70 immagini non usino un nome dinamico o un servizio diverso che raggiunga AGDC.

### 2.3 Limite metodologico importante

Una ricerca ingenua di `movl $3, %esi` non identifica un selettore IOKit:

| Immagine | Occorrenze di `movl $3,%esi` nel disassemblaggio | Selezione AGDC 3 |
|---|---:|---|
| CoreDisplay | 166 | **nessuna nel percorso AGDC** |
| IOPresentment | 65 | **nessuna** |
| Powerlog | 25 | **nessuna nel percorso AGDC** |
| GPUWrangler | non applicabile: disassemblaggio non conservato | **nessuna; usa AppleGPUWrangler** |

Il registro `%esi` viene usato anche per argomenti di logging, indici, flag e altre API. La sola immediate `3` non basta: servono il contesto della call, il servizio aperto e la forma degli argomenti.

**PROVEN:** un grep di `$3,%esi` produce falsi positivi.
**PROVEN:** il selettore 3 AGC di CoreDisplay è uno di questi falsi positivi rispetto ad AGDC.
**UNPROVEN:** che tutti i 166/65/25 siti siano estranei ad AGDC; solo i call site AGDC esaminati sono stati esclusi.

---

## 3. Terzo client AGDC: PowerlogLiteOperators

### 3.1 Immagine e simbolo

| Elemento | Valore |
|---|---|
| Immagine | `PowerlogLiteOperators` |
| SHA-256 | `6e3bcdc986f89c550e73e22802b273ba4528b95df4c2fda56204521917ec58c8` |
| UUID | `BDE491D7-832D-3029-9DAF-834F8F060B80` |
| Funzione | `-[PLMacCPUGPUAgent isDownRevNeeded]` |
| Entry funzione | `0x7ffa075f8758` |
| Blocco `isDownRevNeeded_block_invoke` | `0x7ffa075f87ba` |
| Stringa AGDC | `0x7ffa07631893` |
| Riferimento alla stringa | `0x7ffa075f897e` |

**PROVEN:** la funzione e la stringa sono nella stessa immagine.
**PROVEN:** la stringa è usata in un percorso di confronto con `IOFramebuffer`.
**INFERRED:** il nome del metodo è `isDownRevNeeded`; il simbolo è presente nel literal pool e nel nome del blocco.

### 3.2 Percorso AGDC

| Indirizzo | Istruzione / azione | Significato |
|---:|---|---|
| `0x7ffa075f897e` | `leaq 0x38f0e(%rip), %rdi` | puntatore a `"AppleGraphicsDeviceControl"` |
| `0x7ffa075f8985` | `callq 0x7ffa075fbbaa` | `IOServiceMatching` (INFERRED) |
| `0x7ffa075f898a` | `testq %rax, %rax` | matching riuscito? |
| `0x7ffa075f898d` | `jne 0x7ffa075f89a4` | sì: usa il matching |
| `0x7ffa075f898f` | `leaq 0x38f18(%rip), %rdi` | fallback `"IOFramebuffer"` |
| `0x7ffa075f8996` | `callq 0x7ffa075fbbaa` | secondo `IOServiceMatching` (INFERRED) |
| `0x7ffa075f89a4` | prepara `service`/`iterator` | — |
| `0x7ffa075f89ae` | `callq 0x7ffa075fbba4` | `IOServiceGetMatchingService` (INFERRED) |
| `0x7ffa075f89b3` | `testl %eax, %eax` | servizio trovato? |
| `0x7ffa075f8b38` | `movl -0x4c(%rbp), %edi` | service port |
| `0x7ffa075f8b3b` | `callq 0x7ffa075fb9f4` | `IOServiceOpen` (INFERRED) |
| `0x7ffa075f8b40` | `testl %eax, %eax` | apertura riuscita? |
| `0x7ffa075f8b46` | `callq 0x7ffa075fba0c` | `IOObjectRelease` (INFERRED) |
| `0x7ffa075f8b4b` | `movb $0x1, isDownRevNeeded._downRevNeeded(%rip)` | apertura fallita: flag down-rev |
| `0x7ffa075f8b55` | `callq 0x7ffa075fba0c` | release del servizio |

**PROVEN:** il percorso apre il servizio AGDC o, in fallback, `IOFramebuffer`.
**PROVEN:** dopo l’apertura esegue solo il release; **non chiama `IOConnectCallMethod` né `IOConnectCallStructMethod`**.
**PROVEN:** se `IOServiceOpen` fallisce, imposta `_downRevNeeded = true` e rilascia l’oggetto.
**INFERRED:** `0x7ffa075fbbaa` = `IOServiceMatching`, `0x7ffa075fbba4` = `IOServiceGetMatchingService`, `0x7ffa075fb9f4` = `IOServiceOpen`, `0x7ffa075fba0c` = `IOObjectRelease`. La tabella degli stub è corrotta (`___swift_instantiateConcreteTypeFromMangledNameV2`), quindi la mappatura esatta è inferita da import, sequenza e argomenti.
**UNPROVEN:** il valore effettivo di `_downRevNeeded` sul target; dipende dal runtime.

### 3.3 Perché Powerlog non è il produttore di `0x2`

| Elemento | Stato |
|---|---|
| Contiene `AppleGraphicsDeviceControl` | **PROVEN** |
| Apre AGDC | **PROVEN** |
| Apre `IOFramebuffer` in fallback | **PROVEN** |
| Usa `IOConnectCallMethod` nel percorso AGDC | **NO — PROVEN** |
| Invia selettore 3 | **NO — nessuna evidenza** |
| Costruisce structure input di 4 byte | **NO** |
| Scrive `0x2` | **NO** |

Le due istruzioni `movl $0x2, %esi` nel blocco (`0x7ffa075f894a`, `0x7ffa075f8b04`) precedono chiamate a stub di logging e sono circondate da `movl $0x8400102` (tipo di log Apple). Non sono selettori IOKit.

**PROVEN:** Powerlog è un **terzo client AGDC di sola presenza/apertura**, non un client del comando 3.
**INFERRED:** il suo scopo è rilevare un AGDC down-rev, non inviare una policy o un attributo.
**UNPROVEN:** eventuali percorsi Powerlog verso AGDC fuori da `isDownRevNeeded`.

---

## 4. Audit del selettore 3

### 4.1 Matrice dei client AGDC reali

| Immagine | Letterale AGDC | Apre AGDC | Selettori AGDC osservati | Selettore 3 AGDC | Structure input 4 byte |
|---|---|---|---|---|---|
| `CoreDisplay` | **SÌ** `0x7ff80545572d` | **SÌ** | `1`, `0x10` | **NO** | **NO** |
| `IOPresentment` | **SÌ** `0x7ff81599f5d2` | **SÌ** | `1`, `0x980` | **NO** | **NO** |
| `PowerlogLiteOperators` | **SÌ** `0x7ffa07631893` | **SÌ** | **nessuno**; solo open/release | **NO** | **NO** |
| `GPUWrangler` | **NO** | **NO**; usa `AppleGPUWrangler` | `2`, `0xb` | **NO** | **NO** |
| AGC/mux in `CoreDisplay` | **NO** | **NO**; usa `AppleGraphicsControl` | `2`, `3` scalar | **NO** | **NO** |

**PROVEN:** i client AGDC userspace con letterale del servizio sono esattamente tre.
**PROVEN:** nessuno dei tre invia il selettore 3 AGDC.
**PROVEN:** il selettore 3 presente in CoreDisplay è AGC/mux, non AGDC.

### 4.2 Il selettore 3 AGC

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x7ff8053577b1` | `movl $0x2, %ebx` | costante mux |
| `0x7ff8053577b6` | `movl $0x3, %esi` | selettore 3 |
| `0x7ff8053577bb` | `movl $0x2, %ecx` | 2 scalar input |
| `0x7ff8053577c0` | `movq %r14, %r8` | output scalar |
| `0x7ff8053577c3` | `movq %r15, %r9` | output count |
| `0x7ff8053577c6` | `callq 0x7ff80543ab34` | `IOConnectCallScalarMethod` (INFERRED) |

Contesto: `AppleGraphicsControl`, `kAGCSetMuxState`, `AGCEVENT_WS_POLICY`, `CGXMux...`.

**PROVEN:** è una chiamata scalar, non `IOConnectCallMethod` con structure input.
**PROVEN:** il servizio è AGC, non AGDC.
**INFERRED:** il selettore 3 AGC è il comando di policy/boot del mux.
**UNPROVEN:** il suo significato funzionale esatto.

### 4.3 Forma richiesta per il selettore 3 AGDC

Dal contratto `AppleGraphicsDeviceControlClient::externalMethod` (root2):

| Requisito | Valore |
|---|---|
| `scalarInputCount` | **1** |
| `scalarInput[0]` | **3** (deve coincidere col selettore) |
| `scalarOutputCount` | **1** |
| `structureInput` | **4 byte** per il comando 3 |
| `structureInput[0]` | deve contenere il bit `0x2` per il percorso AMD |
| Metodo userspace | `IOConnectCallMethod` (1 scalare + structure input) |
| `IOConnectCallStructMethod` da solo | **non basta**: manca lo scalare |

**PROVEN:** il contratto richiede almeno uno scalare in input e uno in output.
**PROVEN:** il buffer del comando 3 è un structure input del client; AGDC non lo costruisce.
**UNPROVEN:** il call site userspace che soddisfa questa forma.

### 4.4 Candidati non AGDC

| Immagine / famiglia | Evidenza | Stato |
|---|---|---|
| `IOAccelerator` | importa IOKit; possibile client grafico | **non contiene il letterale AGDC**; call site non disassemblato |
| `IOGPU` | framework grafico | **non contiene il letterale AGDC**; call site non disassemblato |
| `IOMobileFramebuffer` | framebuffer | **non contiene il letterale AGDC**; call site non disassemblato |
| `SkyLight` | logica WindowServer | **non contiene il letterale AGDC**; usa IOKit scalar in altri percorsi |
| Driver AMD/Intel | molti import IOKit | **nessun letterale AGDC**; non sono client AGDC |
| `GPUWrangler` | client `AppleGPUWrangler` | **PROVEN non AGDC** |

**PROVEN:** questi candidati non hanno il letterale del servizio AGDC nella cache.
**UNPROVEN:** una chiamata AGDC con nome dinamico o un path indiretto attraverso un servizio intermedio.

### 4.5 Conclusione sull’audit

| Domanda | Risposta |
|---|---|
| Client AGDC con letterale | **3: CoreDisplay, IOPresentment, Powerlog** |
| Client AGDC che invia il selettore 3 | **nessuno trovato** |
| Selettore 3 AGDC con structure input 4 byte | **nessuno trovato** |
| Selettore 3 AGC in CoreDisplay | **PROVEN; non AGDC** |
| Importatori `IOConnectCallMethod` | **73** |
| Tutti i 73 disassemblati | **NO**; immagini cache-only, solo 4 estratte |
| Nome servizio dinamico | **UNPROVEN** |

**PROVEN:** l’assenza è dimostrata per i tre client AGDC e per il percorso AGC.
**UNPROVEN:** l’assenza globale in tutte le 73 immagini.

---

## 5. Produttore indiretto del bit `0x2`

### 5.1 Cosa è stato cercato

| Candidato | Scrittura di `0x2` | Esito |
|---|---|---|
| CoreDisplay AGDC policy | 8 byte `enabled` | **NO** |
| CoreDisplay AGC mux | 2 scalar | **NO** |
| IOPresentment AGDC | output-only | **NO** |
| Powerlog AGDC | open/release | **NO** |
| GPUWrangler | comandi `2`/`0xb` | **NO** |
| AGDC root2 | trasporta il buffer | **NO — PROVEN** |
| `AmdGpuWrangler` | legge `0x2` | **consumatore, non produttore** |
| `LoadHWServices` userspace | 0 occorrenze | **NO** |
| Plugin/driver di terze parti | non nel target | **escluso dal target** |

**PROVEN:** il bit `0x2` non viene creato dal kext AGDC: `UserKernelTransfer` inoltra il buffer del client.
**PROVEN:** il Wrangler AMD lo consuma (`test` sul primo byte), non lo genera.
**PROVEN:** nessuno dei tre client AGDC lo scrive.
**PROVEN:** `LoadHWServices` non compare nella cache userspace.
**UNPROVEN:** l’istruzione userspace, il processo e il valore runtime che impostano `0x2`.

### 5.2 Catena del produttore

```text
[? processo userspace ?]
  ├─ costruisce structureInput[4] = { 0x2, ... }
  └─ IOConnectCallMethod(conn, selector=3,
        scalarInput={3}, scalarInputCount=1,
        structureInput=in, structureInputSize=4,
        scalarOutput=&ret, scalarOutputCount=1)
       └─ AppleGraphicsDeviceControlClient::externalMethod
            └─ UserKernelTransfer(api=3)
                 └─ filtered_doDeviceAttribute(api=3, cmd=3, in, 4)
                      └─ callback 0x858
                           └─ AmdGpuWrangler::vendor_doDeviceAttribute
                                └─ test bit 0x2
```

**PROVEN:** la catena dal client a `filtered(api=3)` esiste ed è completa fino al callback.
**PROVEN:** il buffer non viene creato da AGDC.
**UNPROVEN:** il primo nodo (processo/istruzione) e il callback runtime del target.

### 5.3 Perché non si può dichiarare “assente”

| Motivo | Conseguenza |
|---|---|
| Le 73 immagini non sono tutte disassemblate | un call site può essere in una delle 70 non estratte |
| Il nome del servizio può essere costruito | il letterale non è necessario |
| Un plugin può essere caricato a runtime | la cache statica non copre il runtime |
| Il target AGDC è assente | non si può verificare il codice 25G342 |
| Il test runtime è vietato | non si può osservare il valore reale |

**PROVEN:** la ricerca statica non ha trovato il produttore.
**UNPROVEN:** la sua esistenza o assenza globale. La formulazione corretta è **“non trovato”**, non **“inesistente”**.

---

## 6. AGDC Compatibility Layer: fattibilità

### 6.1 Obiettivo minimo

Un layer isolato dovrebbe:

1. trovare e aprire `AppleGraphicsDeviceControl`;
2. inviare il comando 3 con `scalarInput={3}`, `structureInput={0x2,...}` di 4 byte e `scalarOutput`;
3. verificare l’effetto sul Wrangler AMD (`LoadHWServices`, HWServices/X6100);
4. **non** sostituire il servizio kernel, il Wrangler o i driver.

### 6.2 Architettura

```text
harness / compatibility client (userspace)
  └─ IOKit
       └─ AppleGraphicsDeviceControl (kernel service)
            └─ externalMethod → UserKernelTransfer(api=3)
                 └─ filtered → callback 0x858
                      └─ AmdGpuWrangler / AMDSupport
                           └─ LoadHWServices → HWServices / X6100
```

**PROVEN:** il punto di ingresso userspace è IOKit; il servizio è kernel.
**PROVEN:** il layer client non può eseguire il codice del kext al posto suo.
**UNPROVEN:** che il servizio AGDC e il callback AMD siano presenti e attivi sul target.

### 6.3 Codice Apple riutilizzabile, comportamento riproducibile, parti da ricreare

| Componente | Codice Apple riutilizzabile? | Comportamento riproducibile? | Da ricreare? | Stato |
|---|---|---|---|---|
| IOKit `IOServiceMatching` / `IOServiceOpen` / `IOConnectCallMethod` | **SÌ**, API pubblica | **SÌ** | **NO** | **PROVEN** |
| CoreDisplay `WSAGDCSetDisplayPolicyEnabled` | **NO sorgente**; binario Apple | policy 8 byte osservabile | **NO** per il layer; non serve al comando 3 | **PROVEN** |
| IOPresentment query AGDC | **NO sorgente** | selettori `1`/`0x980` osservabili | **NO** per il comando 3 | **PROVEN** |
| Powerlog open AGDC | **NO sorgente** | solo presenza | **NO** | **PROVEN** |
| Protocollo `externalMethod` / `UserKernelTransfer` / `filtered` | **NO sorgente**; contratto reverse-engineered | **SÌ** lato client | **SÌ** solo il client harness | **PROVEN/inferito** |
| Servizio kernel `AppleGraphicsDeviceControl` | **NO**; binario assente nel target | **NO** in userspace | **NO**; richiede kernel | **BLOCKED** |
| `AmdGpuWrangler` / `AMDSupport` | **NO**; codice kernel AMD/Apple | **NO** in userspace | **NO**; richiede kernel | **BLOCKED** |
| `LoadHWServices` setter | **NO**; nessun producer userspace | **NO** senza AGDC | **NO**; effetto kernel | **UNPROVEN** |
| Entitlement `com.apple.private.applegraphicsdevicecontrol` | **NO**; autorizzazione Apple | **NO** senza firma | **NO**; non aggirabile | **PROVEN stringa / runtime UNPROVEN** |
| Firma / SIP / AMFI | **NO** | **NO** | **NO** | **BLOCKED** |
| X6100 HWServices / driver AMD | **NO**; kext | **NO** in userspace | **NO** | **BLOCKED** |

**PROVEN:** il layer può riutilizzare solo l’interfaccia IOKit pubblica e il contratto reverse-engineered; non può riutilizzare il servizio kernel AGDC, il Wrangler o i driver.
**PROVEN:** la parte client è riproducibile; la parte kernel non lo è in userspace.
**UNPROVEN:** il comportamento esatto del callback `0x858` sul target.

### 6.4 Opzioni di compatibility layer

#### Opzione A — client-only harness (minima)

Un piccolo eseguibile che apre AGDC e invia il comando 3.

| Requisito | Stato |
|---|---|
| AGDC presente e apribile | **UNPROVEN** sul target |
| Entitlement AGDC/GPU | **PROVEN** come stringa; runtime **UNPROVEN** |
| Callback AMD attivo | **UNPROVEN** |
| Buffer 4 byte con `0x2` | **UNPROVEN** |
| Effetto verificabile | **UNPROVEN**; richiede runtime |

**Fattibilità:** **condizionata**. Non è una sostituzione di AGDC: è solo un client di test. Non è stato implementato in T27 perché la modalità è sola lettura e il runtime è vietato.

#### Opzione B — interposizione/iniezione in WindowServer o client Apple

| Requisito | Stato |
|---|---|
| Modifica di processi Apple | **vietata** dalla modalità |
| Code signing / SIP | **BLOCKED** |
| API privata per il comando 3 | **assente** |
| Rischio di regressione | **alto** |

**Fattibilità:** **bassa/non raccomandata**. Non è un layer isolato: richiede di alterare processi di sistema.

#### Opzione C — sostituzione kernel di AGDC/Wrangler

| Requisito | Stato |
|---|---|
| Nuovo kext / kernel collection | **fuori scope** |
| Firma kernel / SIP | **BLOCKED** |
| Reimplementazione AGDC/AMD | **non disponibile** |
| Target executable AGDC | **assente** |

**Fattibilità:** **bloccata**. Non è un compatibility layer userspace; è un sostituto kernel non autorizzato e non verificabile in T27.

#### Opzione D — riuso di CoreDisplay/IOPresentment

| Requisito | Stato |
|---|---|
| CoreDisplay invia il comando 3 | **NO — PROVEN** |
| IOPresentment invia il comando 3 | **NO — PROVEN** |
| API pubblica per il comando 3 | **assente** |
| Effetto `0x2` | **NO** |

**Fattibilità:** **non applicabile**. I due client Apple non espongono il comando 3.

### 6.5 Dipendenze minime del layer client-only

1. **Servizio:** `AppleGraphicsDeviceControl` deve esistere e accettare la connessione.
2. **Autorizzazione:** entitlement `com.apple.private.applegraphicsdevicecontrol` o `com.apple.private.gpuwrangler`; WindowServer è riconosciuto esplicitamente.
3. **ABI:** `scalarInputCount=1`, `scalarOutputCount=1`, `structureInput` 4 byte, selettore 3.
4. **Wrangler:** callback `0x858` collegato a `AmdGpuWrangler`/`AMDSupport`; altrimenti il comando non raggiunge AMD.
5. **Effetto:** `LoadHWServices` impostato a `true`, con successivo caricamento HWServices/X6100.
6. **Verifica:** lettura runtime della proprietà e dei servizi; non disponibile in sola analisi statica.

**PROVEN:** 1–4 sono il contratto osservato; 5–6 sono l’effetto atteso ma non verificato.
**UNPROVEN:** che il target 25G342 soddisfi 1, 4 e 5.

### 6.6 Valutazione finale della fattibilità

| Layer | Fattibilità | Motivo |
|---|---|---|
| Client-only probe | **condizionata** | dipende da servizio, entitlement, callback; non dimostrato |
| Interposizione client Apple | **bassa** | SIP/firma, processi di sistema, nessuna API |
| Sostituzione kernel AGDC | **bloccata** | richiede kext/kernel collection e firma |
| Sostituzione Wrangler AMD | **bloccata** | codice kernel AMD/Apple, non userspace |
| Riuso CoreDisplay/IOPresentment | **non applicabile** | non inviano il comando 3 |

**Risposta netta:** un compatibility layer **userspace** può solo essere un **client harness** del servizio AGDC esistente. Non può sostituire AGDC, il Wrangler o i driver; non può aggirare entitlement/SIP; non può dimostrare il bit `0x2` senza runtime. La fattibilità è **condizionata e non provata**; la sostituzione kernel è **bloccata**.

---

## 7. Stato delle prove

| Prova | Stato |
|---|---|
| Terzo client AGDC: Powerlog | **PROVEN** |
| Powerlog apre AGDC | **PROVEN** |
| Powerlog invia selettore 3 | **NO — nessuna evidenza** |
| Powerlog usa `IOConnectCallMethod` nel ramo AGDC | **NO — PROVEN** |
| Client AGDC con letterale | **3 — PROVEN** |
| Selettore 3 AGDC con input 4 byte | **non trovato — UNPROVEN** |
| 73 importatori `IOConnectCallMethod` | **PROVEN** |
| Tutti i 73 disassemblati | **NO — limite** |
| `LoadHWServices` in userspace | **0 occorrenze — PROVEN nella cache** |
| Produttore userspace di `0x2` | **UNPROVEN** |
| AGDC root2 non crea `0x2` | **PROVEN** (report 164/169) |
| Compatibilità client-only | **condizionata — UNPROVEN** |
| Compatibilità kernel | **bloccata** |
| Runtime target 25G342 | **UNPROVEN** |

---

## 8. Diagnosi

| Priorità | Elemento | Stato |
|---:|---|---|
| 1 | Terzo client AGDC | **PowerlogLiteOperators — PROVEN** |
| 2 | Funzione Powerlog | `-[PLMacCPUGPUAgent isDownRevNeeded]` — **PROVEN/INFERRED** |
| 3 | Powerlog invia comando 3 | **NO** |
| 4 | CoreDisplay/IOPresentment inviano comando 3 | **NO — PROVEN** |
| 5 | AGC selector 3 | **PROVEN falso positivo** |
| 6 | 73 importatori IOKit | **PROVEN; non tutti disassemblati** |
| 7 | Produttore `0x2` | **UNPROVEN** |
| 8 | Compatibility layer client-only | **condizionato** |
| 9 | Compatibility layer kernel | **bloccato** |

**Diagnosi:** l’audit estende il numero di client AGDC a tre, ma non cambia il quadro del comando 3. Powerlog è un client di presenza: apre AGDC per verificare una condizione down-rev e lo rilascia; non invia attribute. CoreDisplay usa AGDC per policy/versione; IOPresentment per vendor info/capability. Il selettore 3 di CoreDisplay è AGC/mux. Di conseguenza il buffer `{0x2, ...}` non è prodotto da nessuno dei tre client AGDC. Un compatibility layer userspace può solo inviare il comando 3 se il servizio AGDC, l’entitlement e il Wrangler esistono già; non può crearli o sostituirli.

---

## 9. Verdetto

| Domanda | Risposta |
|---|---|
| Terzo client AGDC? | **SÌ: PowerlogLiteOperators** |
| Powerlog invia il comando 3? | **NO** |
| Client AGDC che invia il selettore 3? | **nessuno trovato** |
| Selettore 3 con structure input 4 byte? | **non trovato** |
| 73 importatori IOKit? | **SÌ; scansione completa non eseguita** |
| Produttore del bit `0x2`? | **UNPROVEN** |
| Compatibility layer client-only? | **condizionato; non provato** |
| Compatibility layer kernel? | **bloccato** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il terzo client AGDC è **PowerlogLiteOperators**, ma è solo un client di **presenza/apertura** del servizio: nessun `IOConnectCallMethod`, nessun selettore 3, nessun buffer `0x2`. I tre client AGDC con letterale sono CoreDisplay, IOPresentment e Powerlog; nessuno invia il comando 3. La ricerca sui 73 importatori IOKit non è completa perché le immagini sono nella shared cache e non hanno file standalone; il produttore del bit `0x2` resta **UNPROVEN**. Un compatibility layer **userspace** è solo un client harness condizionato da servizio, entitlement e callback AMD; un layer che sostituisca AGDC/Wrangler è **bloccato**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **14.124.612 KiB ≈ 13,47 GiB** liberi su `/System<VOLUME>/Data`; sopra 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
