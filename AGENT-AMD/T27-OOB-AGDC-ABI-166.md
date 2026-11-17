# T27 — AGENT-AMD — AGDC ABI / FLAGS (166)

**Scope:** ricostruire il contratto dell’interfaccia AGDC e determinare come viene fornito il parametro `flags` a `vendor_doDeviceAttribute` senza dipendere dall’eseguibile Apple mancante; cercare header, simboli e implementazioni locali; analizzare `IOFramebuffer`, `IOAccelerator` e `callPlatformFunction`; ricostruire l’ABI; confrontare X6000Framebuffer e AMDSupport con implementazioni AMD precedenti; cercare evidenze che colleghino `0x2` a proprietà PCI, configurazione GPU o DeviceTree; indicare la prova minima necessaria.

**Modalità:** sola lettura. Nessun boot, trace, modifica, build o download. Comandi: `grep`, `find`, `nm`, `otool`, `strings`, `plutil`, `shasum`.

**Esito:** **PROVEN** che un header locale ricostruito di `AppleGraphicsDeviceControl` definisce `vendor_doDeviceAttribute` con secondo argomento `unsigned long *in`: `rdx` è un **puntatore a buffer di input**, non un flag dedicato. **PROVEN** che `AmdGpuWrangler` legge la prima parola di quel buffer e testa il bit `0x2`. **PROVEN** che non esistono header AGDC ufficiali in MacKernelSDK né un’implementazione Apple locale. **UNPROVEN** chi riempia il buffer sul target e se il bit `0x2` sia legato a PCI/DeviceTree. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| `AppleGraphicsDeviceControl_re.h` locale | `99a829f1cefc5f3d56e005d17883cf854e2c6b2e056d7c570d4034fa83e26ffa` |
| `nvrm-agdc.cpp` locale | `ba68e3f1abdb4f9d0e4dbb9b7ae2ac1b2f19786b38714e42177f5a49665a40a9` |
| AppleGraphicsDeviceControl `Info.plist` | `d521d429dbf95570ec5f6469d1286a846d30739be75e2fe1e1af6244431a5188` |
| X6000Framebuffer executable | `a2469429602210e64a74292a30b06353d9e0f75cd6b8b65f98324e64fa0b4536` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| Report 165 | `1aa2c6bf9f8810dfd4db7d31cd155a6e3f63dce2a72627e2a88c94d33ab89c32` |

**Ambiente:** macOS `26.7.3`, build `25G342`.
**Spazio:** **15.402.776 KiB ≈ 14,69 GiB** > 10 GiB.

---

## 2. Header AGDC locale

Percorso:

```text
HAO-PROJECT/Sessions/<SESSION>/upstream/nvidia-macos-driver/kexts/NVRMAGDC/
  AppleGraphicsDeviceControl_re.h
  nvrm-agdc.cpp
```

### 2.1 Dichiarazione

```cpp
virtual IOReturn vendor_doDeviceAttribute(
    unsigned int cmd,
    unsigned long *in,
    unsigned long inSize,
    unsigned long *out,
    unsigned long *outSize,
    IOExternalMethodArguments *args) = 0;
```

| Campo | Significato |
|---|---|
| `cmd` | comando AGDC |
| `in` | puntatore al buffer di input |
| `inSize` | dimensione input |
| `out` | puntatore al buffer di output |
| `outSize` | dimensione output |
| `args` | argomenti external method |

**PROVEN (nell’header locale):** `rdx` è `in`, non un flag.
**PROVEN (nell’header locale):** la classe è astratta e il metodo è virtuale.
**INFERRED:** la stessa ABI vale per l’interfaccia AGDC del target.
**UNPROVEN:** l’header è una ricostruzione di terzi, non il sorgente Apple ufficiale.

### 2.2 Dimensione classe

`static_assert(sizeof(AppleGraphicsDeviceControl) == 0x110)`.

**PROVEN (header locale):** la classe è 0x110 byte.
**UNPROVEN:** la corrispondenza byte-per-byte con macOS 26.7.3.

### 2.3 Implementazione locale

`nvrm-agdc.cpp` implementa `NVDADeviceControl::vendor_doDeviceAttribute`:

| Comando | Funzione |
|---|---|
| `1` | vendor info |
| `0x980` | GPU capability / framebuffer table |
| `NVK5_CMD_*` | link config / capabilities |

**PROVEN:** l’implementazione locale usa `in`/`inSize`/`out`/`outSize`.
**PROVEN:** non contiene `LoadHWServices`.
**UNPROVEN:** un comportamento AMD equivalente.

---

## 3. ABI del Wrangler AMD

`AmdGpuWrangler::vendor_doDeviceAttribute` `0xbf9894e`:

| Registro | Argomento | Uso |
|---|---|---|
| `rdi` | `this` | oggetto Wrangler |
| `esi` | `cmd` | confronto comando |
| `rdx` | `in` | salvato in `rbx` |
| `rcx` | `inSize` | controllo |
| `r8` | `out` | output |
| `r9` | `outSize` | output |
| stack | `args` | external method |

### 3.1 Lettura del bit

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0xbf9895f` | `movq %rdx, %rbx` | `rbx = in` |
| `0xbf98a1c` | `movl (%rbx), %eax` | prima parola del buffer |
| `0xbf98a1e` | `testb $0x2, %al` | test bit `0x2` |
| `0xbf98a20` | `je 0xbf98a4d` | salta se assente |
| `0xbf98a25` | `leaq "LoadHWServices"` | chiave |
| `0xbf98a34` | `callq *0x278(%rax)` | `setProperty` |

**PROVEN:** il bit `0x2` è nel primo word del buffer `in`.
**PROVEN:** non è un registro separato né un campo del Wrangler.
**UNPROVEN:** chi costruisca il buffer.

### 3.2 AMDSupport

`AtiGpuWrangler::vendor_doDeviceAttribute` `0x13b84370`:

| Indirizzo | Istruzione |
|---:|---|
| `0x13b8457a` | `callq *0x680(%rax)` provider |
| `0x13b845ff` | `andl $0x2, %eax` |
| `0x13b84611` | `leaq "LoadHWServices"` |
| `0x13b8461d` | `callq *0x278(%rax)` |

**PROVEN:** stessa ABI e stesso bit.
**PROVEN:** il buffer è input esterno.

---

## 4. Header ufficiali disponibili

| Header | Presenza |
|---|---|
| `AppleGraphicsDeviceControl` in MacKernelSDK | **NO** |
| `AGDC` in MacKernelSDK | **NO** |
| `IOFramebuffer` | **presente** |
| `IOAccelerator` | **non trovato** |
| `IOService::callPlatformFunction` | **presente** |
| `vendor_doDeviceAttribute` ufficiale | **NO** |

**PROVEN:** MacKernelSDK non contiene l’interfaccia AGDC.
**PROVEN:** `callPlatformFunction` è documentato come dispatch generico, non come AGDC.
**UNPROVEN:** il contratto ufficiale Apple.

---

## 5. `callPlatformFunction`

`IOService::callPlatformFunction` (header MacKernelSDK):

| Proprietà | Valore |
|---|---|
| scopo | chiamare funzioni di platform/provider |
| nome | `OSSymbol` o C string |
| wait | sincrono/asincrono |
| relazione con AGDC | **non diretta** |

**PROVEN:** `AmdGpuWrangler::callPlatformFunction` esiste a `0xbf98bc0`.
**PROVEN:** gestisce `AcceleratorMatchCategory` e `ControllerMatchCategory`.
**UNPROVEN:** che AGDC usi `callPlatformFunction` per `LoadHWServices`.

---

## 6. Implementazioni AMD precedenti

| Famiglia | HWServices richiede `LoadHWServices` | Wrangler locale |
|---|---|---|
| X4000 | **SÌ** | **NO** |
| X5000 | **SÌ** | **NO** |
| X6000 | **SÌ** | **SÌ** (`0xbf9894e`) |
| AMDSupport | **SÌ** (generico) | **SÌ** (`0x13b84370`) |

**PROVEN:** X4000/X5000 dichiarano la stessa proprietà.
**PROVEN:** i loro Wrangler non sono nel root estratto.
**UNPROVEN:** se il bit `0x2` sia identico nelle versioni precedenti.
**INFERRED:** è una convenzione AMD stabile, non un’API Apple documentata.

---

## 7. Legame con PCI / GPU / DeviceTree

| Possibile fonte di `0x2` | Evidenza |
|---|---|
| proprietà PCI `LoadHWServices` | **solo richiesta da HWServices** |
| DeviceTree | **nessuna occorrenza** |
| configurazione GPU / ATY | **nessuna occorrenza diretta** |
| AGDC input buffer | **PROVEN che il Wrangler lo legge** |
| caller AGDC | **assente** |

**PROVEN:** `LoadHWServices` compare nei plist HWServices e nel codice dei Wrangler.
**PROVEN:** non compare in DeviceTree o in un plist PCI.
**UNPROVEN:** che il bit `0x2` derivi da una proprietà PCI o DeviceTree.
**INFERRED:** è un attributo del comando AGDC, non una proprietà statica del device.

---

## 8. Prova minima necessaria

| Prova | Cosa dimostrerebbe | Disponibilità |
|---|---|---|
| buffer `in` del comando target | primo word con bit `0x2` | **assente** |
| caller AGDC | costruzione del buffer | **assente** |
| `ioreg` con `LoadHWServices` | effetto sul PCI | **assente** |
| header Apple ufficiale | ABI certa | **assente** |

**PROVEN:** nessuna delle quattro prove è disponibile.
**PROVEN:** l’ABI locale è coerente ma non ufficiale.
**UNPROVEN:** la condizione target.

---

## 9. Diagnosi

| Priorità | Elemento | Stato |
|---:|---|---|
| 1 | buffer `in` e bit `0x2` | **UNPROVEN** |
| 2 | caller AGDC | **ASSENTE** |
| 3 | `LoadHWServices` sul provider | **PROVEN codice; runtime UNPROVEN** |
| 4 | HWServices e X6100 | **PROVEN statico** |
| 5 | X6100 operativo | **UNPROVEN runtime** |

**Diagnosi:** l’ABI è chiarita: `rdx` è il puntatore `in`, e il bit `0x2` è la prima parola del buffer di input. Non è un flag del Wrangler né una proprietà PCI letta direttamente. L’header locale dimostra il contratto, ma non è Apple ufficiale e non prova chi riempia il buffer. Non c’è alcuna evidenza che il bit derivi da DeviceTree o da una proprietà PCI. La prova minima è il buffer `in` del comando target o un `ioreg` con `LoadHWServices=true`.

---

## 10. Verdetto

| Domanda | Risposta |
|---|---|
| `rdx` è un flag dedicato? | **NO — è `in`** |
| Il bit `0x2` è nel buffer `in`? | **PROVEN** |
| Header Apple ufficiale disponibile | **NO** |
| Header locale disponibile | **SÌ, ricostruito** |
| `LoadHWServices` in DeviceTree/PCI | **NO dimostrato** |
| Caller del buffer | **UNPROVEN** |
| Target soddisfa bit `0x2` | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il contratto AGDC locale mostra che `vendor_doDeviceAttribute` riceve in `rdx` un puntatore `in`, non un flag. `AmdGpuWrangler` legge la prima parola di quel buffer e testa `0x2`; `AtiGpuWrangler` fa lo stesso. Non esistono header Apple ufficiali né un’implementazione AGDC locale; il legame del bit con PCI, GPU o DeviceTree non è dimostrato. La prova minima è il buffer di input del comando target o un `ioreg` che mostri `LoadHWServices=true`. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **15.402.776 KiB ≈ 14,69 GiB** > 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
