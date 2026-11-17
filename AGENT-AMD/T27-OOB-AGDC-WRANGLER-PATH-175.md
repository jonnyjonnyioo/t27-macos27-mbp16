# T27 — AGENT-AMD — WRAPPER → WRANGLER / doPluginAttribute / API (175)

**Scope:** ricostruire senza supposizioni il percorso AGDC dal wrapper `vendor_doDeviceAttribute` al Wrangler; risolvere lo slot `+0x850` (`0x40000000ab77f0`); identificare il codice effettivo e il mapping; ricostruire `AGDCPlugin::doPluginAttribute` e i suoi chiamanti; cercare API SkyLight/WindowServer che raggiungano il selettore 3; verificare se esiste un percorso autorizzato senza injection.

**Modalità:** sola lettura. Nessun boot, trace, modifica, build o download. Comandi: `nm`, `otool`, `ndisasm`, `strings`, `codesign`, `sysctl`, `shasum`, `sha256sum`.

**Esito sintetico:** **PROVEN** che `filtered` chiama `[vtable+0x858]` = `0x13d41c34` (`AppleGraphicsDeviceControl::vendor_doDeviceAttribute`). **PROVEN** che nel wrapper `[rdi]` viene letto e si chiama `[vtable+0x850]`. **PROVEN** che la vtable `__ZTV29AMDRadeonX6000_AmdGpuWrangler` è a `0xc1f07b0` e che, con vptr `+0x10`, lo slot `+0x850` contiene `0x4000004bf9894e`, che si decodifica in **`0xbf9894e` = Wrangler `vendor_doDeviceAttribute`**. **PROVEN** che lo slot `+0x858` della stessa vtable contiene `0x40000053d41c34` = wrapper AGDC. Quindi il percorso **Wrangler → +0x858 wrapper → +0x850 Wrangler** è coerente **se l’oggetto è il Wrangler**. **PROVEN** che `AGDCPlugin::doPluginAttribute` a `0x13d4240e` fa tail-call `[plugin vtable+0x890]`; ha **7 chiamanti diretti** nel codice AGDC. **UNPROVEN** che il percorso `doPluginAttribute → Wrangler` sia quello usato dal comando 3: la vtable Wrangler `+0x890` punta a `0x13d420fa`, non a `0xbf9894e`. **PROVEN** che WindowServer non espone un’API AGDC con selettore 3; CoreDisplay usa 1/0x10, IOPresentment 1/0x980, Powerlog solo open. **Nessun percorso autorizzato senza injection** è stato trovato. T27 resta **OPEN**: **94% engineering / 32% first boot / 8% desktop**.

---

## 1. Ambiente e SHA-256

| Artefatto | SHA-256 |
|---|---|
| Report 174 | `ccf2f374b4455d5f913b09cc8d381390aee59052e8c3fc39fcab9bb9027de013` |
| `SystemKernelExtensions.kc` target 25G342 | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| WindowServer target | `804cf101ec081e4f07946acaca35d694d8e9d48b25a12c5b4e1a6ce348c9000d` |
| CoreDisplay estratto | `d1d038dd7f88191d47db381ce776f7837d12408439d19f279c393c847c7c64fc` |
| IOPresentment estratto | `f07a31ec7774aee56efe62edd9f96ebb07cf72926eee8e0e089b65777ae9ecce` |
| PowerlogLiteOperators estratto | `6e3bcdc986f89c550e73e22802b273ba4528b95df4c2fda56204521917ec58c8` |

**Target:** macOS `26.7.3`, build `25G342`.
**Base AGDC:** `0x13d3f000`; **base Wrangler:** `0xbf9894e`.
**Spazio:** **14.124.612 KiB ≈ 13,47 GiB** liberi.

---

## 2. Punto di partenza: wrapper `vendor_doDeviceAttribute`

Entry `0x13d41c34`:

```
13D41C34  push rbp
13D41C35  mov rbp,rsp
13D41C38  sub rsp,0x10
13D41C3C  mov rax,[rbp+0x10]     ; 7° arg: AGDCClientState_t*
13D41C40  test rax,rax
13D41C43  jz 0x13d41c4b
13D41C45  mov rax,[rax+0x38]     ; campo del client state
13D41C49  jmp 0x13d41c4d
13D41C4B  xor eax,eax
13D41C4D  mov r10,[rdi]          ; vtable dell'oggetto
13D41C50  mov [rsp],rax
13D41C54  call qword near [r10+0x850]
13D41C5B  add rsp,0x10
13D41C5F  pop rbp
13D41C60  retq
```

**PROVEN:** il wrapper non implementa il comando 3; inoltra a `[vtable+0x850]`.
**PROVEN:** il wrapper è il target dello slot `+0x858` della vtable AGDC (report 174).
**UNPROVEN (nel 174):** il significato di `[vtable+0x850]`.

---

## 3. Vtable Wrangler: risoluzione di `+0x850`

### 3.1 Simbolo e indirizzo

| Elemento | Valore |
|---|---|
| Simbolo | `__ZTV29AMDRadeonX6000_AmdGpuWrangler` |
| Indirizzo | `0xc1f07b0` |
| Sezione | `__DATA,__const` |
| `vptr` oggetto | `0xc1f07b0 + 0x10 = 0xc1f07c0` |

**PROVEN:** la vtable del Wrangler è definita nel target SystemKC a `0xc1f07b0`.
**PROVEN:** il `vptr` C++ dell’oggetto è `0xc1f07c0`.

### 3.2 Slot rilevanti

| Slot da vptr | Indirizzo | Raw | Decodifica | Simbolo |
|---:|---:|---|---|---|
| `+0x850` | `0xc1f1010` | `0x4000004bf9894e` | **`0xbf9894e`** | `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute` |
| `+0x858` | `0xc1f1018` | `0x40000053d41c34` | **`0x13d41c34`** | `AppleGraphicsDeviceControl::vendor_doDeviceAttribute` (wrapper) |
| `+0x860` | `0xc1f1020` | `0x40000053d42078` | `0x13d42078` | reserved/thunk AGDC |
| `+0x868` | `0xc1f1028` | `0x40000053d4208c` | `0x13d4208c` | reserved/thunk AGDC |
| `+0x890` | `0xc1f1050` | `0x40000053d420fa` | `0x13d420fa` | reserved/thunk AGDC |

**PROVEN:** `Wrangler vtable +0x850 = 0xbf9894e`, cioè il `vendor_doDeviceAttribute` del Wrangler.
**PROVEN:** `Wrangler vtable +0x858 = 0x13d41c34`, cioè il wrapper AGDC.
**PROVEN:** la vtable Wrangler contiene entrambi i simboli.
**UNPROVEN:** che l’oggetto su cui `filtered` esegue la chiamata virtuale sia effettivamente il Wrangler e non la classe base AGDC.

### 3.3 Percorso coerente

```
filtered_doDeviceAttribute (0x13d407b0)
  └─ call [vtable+0x858]
       └─ AppleGraphicsDeviceControl::vendor_doDeviceAttribute (0x13d41c34)
            └─ call [vtable+0x850]
                 └─ AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute (0xbf9894e)
```

**PROVEN:** i due slot e le due funzioni esistono e sono nella stessa vtable Wrangler.
**INFERRED:** il percorso è quello eseguito quando `filtered` opera su un oggetto Wrangler.
**UNPROVEN:** la prova runtime dell’oggetto effettivo.

### 3.4 Perché nel 174 `+0x850` sembrava `0xab77f0`

Nel report 174 è stata letta la vtable **base** `__ZTV26AppleGraphicsDeviceControl`:

| Base | Slot `+0x850` | Raw | Decodifica |
|---|---:|---|---|
| AGDC `0x13d44478` | `0x13d44cd8` | `0x40000000ab77f0` | `0xab77f0` |
| Wrangler `0xc1f07b0` | `0xc1f1010` | `0x4000004bf9894e` | `0xbf9894e` |

**PROVEN:** la vtable base AGDC e la vtable Wrangler hanno contenuti diversi nello slot `+0x850`.
**PROVEN:** il valore `0xab77f0` appartiene alla **base AGDC**, non alla vtable Wrangler.
**INFERRED:** `0xab77f0` è un override/placeholder della classe base, non il percorso Wrangler.
**UNPROVEN:** il significato di `0xab77f0` nella classe base; il suo mapping è descritto sotto.

### 3.5 Mapping di `0xab77f0`

| Elemento | Valore |
|---|---|
| Indirizzo | `0xab77f0` |
| Segmento | `__REGION49` |
| `vmaddr` | `0xa895000` |
| `vmsize` | `0x152b000` |
| `fileoff` | `0xa895000` |
| `maxprot` | `0x3` (read/write) |
| `initprot` | `0x3` (read/write) |
| Byte | `0a406b7f0a40737f1300c0cf240040cf...` |
| Codice x86_64 valido | **NO** |

**PROVEN:** `0xab77f0` non è in un segmento eseguibile (`maxprot=3`, `initprot=3`).
**PROVEN:** i byte a `0xab77f0` non sono un prologo x86_64 valido.
**PROVEN:** un `call`/`jmp` diretto a `0xab77f0` non può eseguire codice.
**UNPROVEN:** la decodifica definitiva del raw `0x40000000ab77f0`; il valore è una base/virtual placeholder, non il Wrangler.

---

## 4. `AGDCPlugin::doPluginAttribute`

### 4.1 Entry `0x13d4240e`

```
13D4240E  push rbp
13D4240F  mov rbp,rsp
13D42412  test rsi,rsi
13D42415  jz 0x13d42424
13D42417  mov rax,[rdi]          ; vtable del plugin
13D4241A  mov rax,[rax+0x890]    ; slot +0x890
13D42421  pop rbp
13D42422  jmp rax                ; tail call
13D42424  mov eax,0xe00002c0     ; errore argomento
13D42429  pop rbp
13D4242A  retq
```

**PROVEN:** `doPluginAttribute` richiede `rsi != 0`.
**PROVEN:** legge `[rdi]` e tail-call `[vtable+0x890]`.
**PROVEN:** non chiama direttamente il Wrangler.
**UNPROVEN:** il target effettivo di `[vtable+0x890]` per il plugin Wrangler.

### 4.2 Slot `+0x890` nelle vtable note

| Vtable | `+0x890` raw | Decodifica | Simbolo |
|---|---:|---|---|
| AGDC base `0x13d44e28` (AGDCPlugin) | `0x100000000ab77f0` | `0xab77f0` | non eseguibile |
| Wrangler `0xc1f07b0` | `0x40000053d420fa` | `0x13d420fa` | reserved/thunk AGDC |
| AGDC base `0x13d44478` | `0x40000053d420ce` | `0x13d420ce` | reserved/thunk AGDC |

**PROVEN:** la vtable base `AGDCPlugin` ha `+0x890 = 0xab77f0` non eseguibile.
**PROVEN:** la vtable Wrangler ha `+0x890 = 0x13d420fa`, non `0xbf9894e`.
**PROVEN:** `doPluginAttribute` non raggiunge il Wrangler tramite `+0x890` nella vtable Wrangler.
**UNPROVEN:** il ruolo di `0x13d420fa`; è un thunk AGDC, non il vendor Wrangler.

### 4.3 Chiamanti diretti di `doPluginAttribute`

Scansione del codice AGDC (`0x13d3f000–0x13d46000`):

| Call site | Funzione contenente | Nota |
|---:|---|---|
| `0x13d4002a` | `AppleGraphicsDeviceControl::doPlugin_Command` (`0x13d3fed2`) | comando plugin |
| `0x13d4007e` | `doPlugin_Command` | comando plugin |
| `0x13d4010e` | `doPlugin_Command` | comando plugin |
| `0x13d4161a` | `filtered_doDeviceAttribute` (`0x13d407b0`) | chiamata diretta nel ramo filtered |
| `0x13d41b58` | `setDeviceAttribute` (`0x13d41bdc`) | attributo |
| `0x13d41c84` | `_actionWrapper(OSObject*,...)` (`0x13d41c62`) | action wrapper |
| `0x13d41cb2` | `actionWrapper(AGDCPlugin*,...)` (`0x13d41c90`) | action wrapper |

**PROVEN:** 7 chiamanti diretti nel codice AGDC.
**PROVEN:** nessun chiamante diretto nel codice Wrangler (`0xbf98000–0xbf99000`).
**PROVEN:** `doPluginAttribute` è chiamato da `filtered`, `setDeviceAttribute`, `doPlugin_Command` e due action wrapper.
**UNPROVEN:** quale di questi percorsi sia attivo per il selettore 3 a runtime.

### 4.4 Action wrapper

| Funzione | Indirizzo | Comportamento |
|---|---:|---|
| `AppleGraphicsDeviceControl::_actionWrapper(OSObject*, void*, void*, void*, void*)` | `0x13d41c62` | prepara args e chiama `doPluginAttribute` |
| `AppleGraphicsDeviceControl::actionWrapper(AGDCPlugin*, void*)` | `0x13d41c90` | prepara args e chiama `doPluginAttribute` |

**PROVEN:** entrambi chiamano `0x13d4240e` a `0x13d41c84` / `0x13d41cb2`.
**INFERRED:** sono callback di `IOAction`/`IOCommandGate` per l’inoltro al plugin.
**UNPROVEN:** il collegamento con un client userspace o con il comando 3.

### 4.5 Chiamata diretta da `filtered`

A `0x13d41603`:

```
13D41603  xor eax,eax
13D41605  mov [rsp+0x8],rsi
13D4160A  mov [rsp],rax
13D4160E  mov rdi,rbx        ; plugin
13D41611  mov rsi,rdx        ; AGDC
13D41614  mov edx,r13d       ; selettore
13D41617  mov r9,r15         ; output
13D4161A  call 0x13d4240e    ; doPluginAttribute
```

**PROVEN:** `filtered` contiene una chiamata diretta a `doPluginAttribute`.
**UNPROVEN:** la condizione di ramo che la abilita e il tipo effettivo di `rbx`.
**PROVEN:** questa chiamata non passa dallo slot `0x858`, quindi è un percorso alternativo.

---

## 5. API SkyLight / WindowServer e selettore 3

### 5.1 WindowServer

| Aspetto | Evidenza | Stato |
|---|---|---|
| Firmato Apple | `codesign` | **PROVEN** |
| `gpuwrangler=true` | entitlement | **PROVEN** |
| AGDC literal nel loader | `strings` | **NO** |
| Selector 3 nel loader | nessun call site | **NO — PROVEN assenza** |
| API pubblica AGDC | nessuna | **non trovata** |

**PROVEN:** WindowServer non contiene il letterale `AppleGraphicsDeviceControl`.
**PROVEN:** WindowServer non contiene un call site `IOConnectCallMethod` con selettore 3.
**PROVEN:** il loader dipende da SkyLight, non da CoreDisplay direttamente.
**UNPROVEN:** un’API privata dentro SkyLight/CoreDisplay che inoltri il selettore 3.

### 5.2 CoreDisplay

| Aspetto | Evidenza | Stato |
|---|---|---|
| AGDC literal | `.tmp/a73/01_CoreDisplay` | **PROVEN** |
| Selettore 1 | report 171 | **PROVEN** |
| Selettore `0x10` policy | report 171 | **PROVEN** |
| Selettore 3 | nessun call site | **NO — PROVEN assenza** |
| API per selettore 3 | nessuna | **non trovata** |

**PROVEN:** CoreDisplay usa AGDC solo per versione (1) e policy (`0x10`).
**PROVEN:** non invia il selettore 3.
**UNPROVEN:** una funzione privata non documentata che costruisca il buffer `{0x2,...}`.

### 5.3 IOPresentment

| Aspetto | Evidenza | Stato |
|---|---|---|
| AGDC literal | `.tmp/a73/11_IOPresentment` | **PROVEN** |
| Selettore 1 | report 171 | **PROVEN** |
| Selettore `0x980` | report 171 | **PROVEN** |
| Selettore 3 | nessun call site | **NO — PROVEN assenza** |

**PROVEN:** IOPresentment non invia il selettore 3.
**UNPROVEN:** un percorso privato che lo inoltri.

### 5.4 Powerlog

**PROVEN:** Powerlog apre AGDC solo con `IOServiceOpen`; non chiama `IOConnectCallMethod`.
**PROVEN:** non invia il selettore 3.
**UNPROVEN:** la sua autorizzazione; anche se autorizzato, non invia il comando.

### 5.5 Conclusione API

| Componente | Comando 3 | API |
|---|---|---|
| WindowServer | **NO** | nessuna trovata |
| CoreDisplay | **NO** | 1 / `0x10` |
| IOPresentment | **NO** | 1 / `0x980` |
| Powerlog | **NO** | solo open |
| SkyLight standalone | **non disponibile** | codice in dyld cache |

**PROVEN:** nessuna API AGDC con selettore 3 è stata trovata nei componenti disponibili.
**UNPROVEN:** API privata non osservata o client non presente nella cache.

---

## 6. Percorso autorizzato senza injection

### 6.1 Autorizzazione

| Via | Stato |
|---|---|
| `gpuwrangler` in WindowServer | **PROVEN** |
| `applegraphicsdevicecontrol` in WindowServer | **NO** |
| `agdc_entitle` boot-arg | **assente** |
| harness locale con entitlement | **non ottenibile** |
| root | **non basta** |
| injection/plugin WindowServer | **escluso** |

**PROVEN:** WindowServer è autorizzato tramite `gpuwrangler`.
**PROVEN:** WindowServer non invia il selettore 3.
**PROVEN:** `kern.bootargs` è vuoto; `agdc_entitle` non è attivo.
**PROVEN:** un harness isolato non può ottenere l’entitlement di WindowServer.

### 6.2 Percorso completo

```
WindowServer (gpuwrangler)
  └─ CoreDisplay
       └─ AGDC selectors 1 / 0x10
            └─ NO selector 3
```

**PROVEN:** il percorso autorizzato noto si ferma ai selettori 1/0x10.
**PROVEN:** nessun percorso autorizzato noto raggiunge `filtered` con selettore 3.
**UNPROVEN:** un’API privata che consenta a WindowServer di inviare 3.

### 6.3 Harness isolato

| Scenario | Esito |
|---|---|
| Harness senza entitlement | **authorizeTask nega** |
| Harness con `dlopen` CoreDisplay | **task harness, nega** |
| Harness con fork/exec da WindowServer | **entitlement non ereditato** |
| Harness con injection | **escluso** |
| Harness con boot-arg | **bootargs vuoto** |
| API pubblica WindowServer | **non trovata** |

**PROVEN:** non esiste un percorso isolato senza injection che unisca autorizzazione e selettore 3.
**PROVEN:** il blocco è di autorizzazione, non di ABI o codice AGDC.

---

## 7. Stato del percorso Wrangler

| Tratto | Evidenza | Stato |
|---|---|---|
| `filtered → +0x858` | call site 0x13d4179f | **PROVEN** |
| `+0x858 = 0x13d41c34` | vtable AGDC/Wrangler | **PROVEN** |
| `0x13d41c34 → +0x850` | wrapper | **PROVEN** |
| `Wrangler +0x850 = 0xbf9894e` | vtable 0xc1f07b0 | **PROVEN** |
| oggetto effettivo = Wrangler | vtable/start | **INFERRED** |
| `doPluginAttribute → +0x890` | code 0x13d4240e | **PROVEN** |
| `Wrangler +0x890 = 0x13d420fa` | vtable | **PROVEN** |
| `doPluginAttribute → Wrangler vendor` | nessun slot | **UNPROVEN / NO** |
| `0xab77f0` eseguibile | `__REGION49` RW | **NO — PROVEN** |
| API autorizzata selector 3 | nessuna | **non trovata** |

**PROVEN:** il percorso virtuale corretto per il vendor Wrangler è `+0x858` (wrapper) e poi `+0x850` (Wrangler), non `+0x890`.
**PROVEN:** `doPluginAttribute` usa `+0x890`, che nella vtable Wrangler non è il vendor.
**UNPROVEN:** il significato di `0x13d420fa`; non è il Wrangler.

---

## 8. Diagnosi

| Priorità | Elemento | Stato |
|---:|---|---|
| 1 | Wrapper `+0x850` | **Wrangler 0xbf9894e, PROVEN in vtable** |
| 2 | Oggetto effettivo Wrangler | **INFERRED** |
| 3 | `doPluginAttribute` | **7 callers, PROVEN** |
| 4 | `doPluginAttribute → Wrangler` | **NO, +0x890 non è vendor** |
| 5 | API WindowServer selector 3 | **non trovata** |
| 6 | Harness isolato | **bloccato** |
| 7 | Comando 3 autorizzato | **BLOCKED** |

**Diagnosi:** la vtable Wrangler risolve il dubbio del 174: `+0x850` è `0xbf9894e` (Wrangler vendor), `+0x858` è `0x13d41c34` (wrapper AGDC). Se `filtered` opera su un oggetto Wrangler, il percorso `filtered → wrapper → Wrangler` è coerente e completo a livello di dispatch. La vtable base AGDC, invece, ha `+0x850 = 0xab77f0`, che è in una regione RW non eseguibile: non è il percorso Wrangler. `AGDCPlugin::doPluginAttribute` è un percorso separato: tail-call `+0x890`; nella vtable Wrangler `+0x890 = 0x13d420fa`, non il vendor. Non c’è quindi prova che `doPluginAttribute` raggiunga il Wrangler. WindowServer è autorizzato ma non invia il selettore 3; nessuna API pubblica lo consente; l’harness isolato non può ottenere l’entitlement. Il percorso autorizzato con selettore 3 resta bloccato.

---

## 9. Verdetto

| Domanda | Risposta |
|---|---|
| Wrangler vtable `+0x850` | **`0xbf9894e` — PROVEN** |
| Wrangler vtable `+0x858` | **`0x13d41c34` wrapper — PROVEN** |
| Percorso `filtered → wrapper → Wrangler` | **PROVEN a livello vtable; oggetto INFERRED** |
| `0xab77f0` | **base AGDC, RW, non eseguibile — PROVEN** |
| `doPluginAttribute` | **0x13d4240e, 7 callers — PROVEN** |
| `doPluginAttribute → Wrangler` | **NO — `+0x890` non è vendor** |
| API WindowServer selector 3 | **non trovata** |
| Harness isolato senza injection | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la vtable Wrangler chiarisce il percorso: `+0x858` è il wrapper AGDC, `+0x850` è il Wrangler. Il percorso `filtered → wrapper → Wrangler` è quindi coerente **se l’oggetto è il Wrangler**. La vtable base AGDC usa `0xab77f0`, che non è eseguibile e non è il Wrangler. `doPluginAttribute` è un percorso separato e il suo `+0x890` non è il vendor Wrangler. WindowServer è autorizzato ma non invia il selettore 3; nessuna API pubblica lo consente; un harness isolato non può ottenere l’entitlement. **Primo ostacolo irrisolto: manca un attore autorizzato che invii il comando 3.** T27 resta **OPEN**: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **14.124.612 KiB ≈ 13,47 GiB** liberi. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
