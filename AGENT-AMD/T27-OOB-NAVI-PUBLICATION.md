# T27 — AGENT-AMD — NAVI PUBLICATION

> **RETTIFICA (Prompt 126):** la conclusione resta valida, ma la motivazione va corretta: `SWI::start` chiama `Abstract::start`; questi chiama `IOService::start` e poi lo slot `0x5B0`, che nella vtable Navi è `_RESERVEDIOService47`, non `registerService`. `registerService` è allo slot `0x5C0` Navi e non viene chiamato.

**Scope:** verificare definitivamente il percorso di pubblicazione Navi con il formato corretto `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` (11); ricostruire le vtable, le super-call di `SWI::start` e i percorsi alternativi verso `Abstract::start`/`registerService`.

**Modalità:** sola lettura; SystemKC/BootKC, fileset X6000HWServices, vtable, disassemblaggio, scansione call; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che Navi usa `SWI::start`, che `SWI::start` chiama `IOService::open` (slot `0x5D0`) e `AmdTtlInterfaceKey`, e che l’unico call site di `registerService` (`0x5B0`) è in `Abstract::start`. **UNPROVEN** la pubblicazione del servizio Navi e il matching X6000HWLibs. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 110 | `3354665f31801a66135b2b22aa9f0176443a2b36b68b8a41ec186b8898145255` |
| Report 105 rettificato | `b191bac97dfb40abc68e15f3c1c96c51f6d3983e3ac2d6e39a482a3b22897fd9` |
| Report 106 rettificato | `cc9904dc35a127b6160b40c0c6ff941022262a702a5be0372287aefb1941878a` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Vtable ricostruite

Formato: `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`, entry da 4 byte, `target:30`, `cacheLevel:2`; base livello 0 `0xFFFFFF8000100000`.

| Vtable | `0x5B0` | `0x5B8` | `0x5C0` | `0x5C8` | `0x5D0` | `0x5D8` | `0x5E0` |
|---|---|---|---|---|---|---|---|
| Navi | `registerService` | `Abstract::probe` | `SWI::start` | `SWI::stop` | `IOService::open` | `IOService::close` | `IOService::isOpen` |
| SWI | `registerService` | `Abstract::probe` | `SWI::start` | `SWI::stop` | `IOService::open` | `IOService::close` | `IOService::isOpen` |
| Abstract | `registerService` | `Abstract::probe` | `Abstract::start` | `Abstract::stop` | `IOService::open` | `IOService::close` | `IOService::isOpen` |

| Voce | Indirizzo |
|---|---:|
| `registerService` | `0xFFFFFF8000A94C60` |
| `Abstract::probe` | `0x0C26D650` |
| `SWI::start` | `0x0C26CFF0` |
| `SWI::stop` | `0x0C26D120` |
| `Abstract::start` | `0x0C26D8C0` |
| `Abstract::stop` | `0x0C26DD90` |
| `IOService::open` | `0xFFFFFF8000A94EB0` |
| `IOService::close` | `0xFFFFFF8000A94FD0` |
| `IOService::isOpen` | `0xFFFFFF8000A950E0` |

**PROVEN:** Navi e SWI condividono `start`/`stop`/`probe`.
**PROVEN:** Abstract è l’unica con `Abstract::start`.
**PROVEN:** `open`/`close`/`isOpen` sono IOService.

---

## 3. SWI::start

```text
0xC26D008: leaq 0x3CE1(%rip), %rax      ; 0xC270CF0 = vtable Abstract
0xC26D00F: movq 0x5D0(%rax), %rax       ; IOService::open
0xC26D01A: callq *%rax
0xC26D032: callq 0xC26D060              ; helper
```

| Elemento | Valore |
|---|---|
| Super-call | `IOService::open` |
| Slot | `0x5D0` |
| Helper | `0xC26D060` |
| Chiave | `AmdTtlInterfaceKey` |
| `callPlatformFunction` | **SÌ** |
| `Abstract::start` | **NO** |
| `registerService` | **NO** |

**PROVEN:** `SWI::start` apre il provider.
**PROVEN:** non chiama `Abstract::start`.
**PROVEN:** non chiama `registerService`.

---

## 4. Call site

| Pattern | Indirizzo | Funzione |
|---|---|---:|
| `call *0x5B0(%rax)` | `0xC26DA0D` | `Abstract::start` |
| `call *0x5C0(%rax)` | **nessuno** | — |
| `call *0x5D0(%rax)` | **nessuno** | — |
| call diretta `Abstract::start` | **nessuna** | — |
| call diretta `SWI::start` | **nessuna** | — |

**PROVEN:** l’unico `0x5B0` è in `Abstract::start`.
**PROVEN:** non ci sono altre chiamate indirette a `start`.
**PROVEN:** Navi non chiama `Abstract::start` né `registerService`.

---

## 5. Costruttori e provider

| Classe | Costruttore | Registrazione |
|---|---:|---|
| Navi | `0xC26C930` | **nessuna osservata** |
| SWI | `0xC26CDC0` | **nessuna osservata** |
| Abstract | `0xC26D3F0` | **nessuna osservata** |

**PROVEN:** i costruttori non chiamano `registerService`.
**UNPROVEN:** inizializzazione runtime del provider.
**UNPROVEN:** pubblicazione fuori dal binario.

---

## 6. Personalità X6000HWLibs

| Requisito | Valore |
|---|---|
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `LoadPlugIn=Load6000` |
| `Load6000` | **solo X6000HWLibs** |
| Navi pubblica Interface | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| Matching | **UNPROVEN** |

**PROVEN:** i requisiti della personalità.
**UNPROVEN:** la loro soddisfazione.

---

## 7. Percorsi alternativi

| Percorso | Esito |
|---|---|
| Navi → `Abstract::start` | **NO** |
| Navi → `registerService` | **NO** |
| `SWI::start` → `Abstract::start` | **NO** |
| `SWI::start` → `registerService` | **NO** |
| Callback/metaclass | **NO osservato** |
| Workloop | **NO osservato** |
| Pubblicazione automatica | **UNPROVEN** |

**PROVEN:** non è emerso un percorso alternativo.
**UNPROVEN:** runtime.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Navi `start` | **`SWI::start`** |
| `SWI::start` chiama `open` | **SÌ** |
| `SWI::start` chiama `Abstract::start` | **NO** |
| `Navi` chiama `registerService` | **NO statico** |
| `Navi` pubblica il servizio | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| Runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** con il formato corretto, Navi usa `SWI::start`, che chiama `IOService::open` via slot `0x5D0` e il helper `AmdTtlInterfaceKey`, ma non `Abstract::start` né `registerService`. L’unico call site di `registerService` è `Abstract::start` a `0xC26DA0D`, e nessuna chiamata indiretta a `0x5C0`/`0x5B0` collega Navi a quel percorso. La pubblicazione del servizio Navi e il matching X6000HWLibs → Navi restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
