# T27 — AGENT-AMD — IOKIT PUBLICATION

**Scope:** verificare se Navi viene pubblicato indirettamente dal framework IOKit nonostante l’assenza di chiamate statiche a `registerService` in `SWI::start`; esaminare metaclass, `allocClassWithName`, callback, slot `0x5B0` e matching `X6000HWLibs`.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, disassemblaggio, symbol table; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che `IOService::start` restituisce solo `true` e non chiama `registerService`; **PROVEN** che nel testo BootKC non ci sono call dirette a `registerService` e che l’unico call site indiretto `0x5B0` è in `Abstract::start`. **REFUTED** la pubblicazione automatica via `IOService::start`. **UNPROVEN** un percorso runtime esterno. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 111 | `e52dae97710ccf161ac7dcf619a74e803c0b2fb6870631b4ec1265db3f806b2b` |
| Report 110 | `3354665f31801a66135b2b22aa9f0176443a2b36b68b8a41ec186b8898145255` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. IOService::start

```text
0xFFFFFF8000A94E70: pushq %rbp
0xFFFFFF8000A94E71: movq  %rsp, %rbp
0xFFFFFF8000A94E74: movb  $0x1, %al
0xFFFFFF8000A94E76: popq  %rbp
0xFFFFFF8000A94E77: retq
```

| Test | Esito |
|---|---|
| Restituisce `true` | **SÌ** |
| Chiama `registerService` | **NO** |
| Pubblica il servizio | **NO** |
| Registra il provider | **NO** |

**PROVEN:** `IOService::start` è banale.
**PROVEN:** non pubblica nulla.
**REFUTED:** pubblicazione automatica in `start`.

---

## 3. Call dirette a registerService

| Scope | Esito |
|---|---|
| `__TEXT_EXEC` BootKC | **0 call dirette** |
| X6000HWServices | **0 call dirette** |
| Import in HWServices | **nessuno** |
| Unico call indiretto | `0xC26DA0D` (`Abstract::start`) |
| Altri slot `0x5B0` | **nessuno** |

**PROVEN:** non esistono call dirette.
**PROVEN:** l’unico uso è `Abstract::start`.
**UNPROVEN:** call indirette fuori dal fileset.

---

## 4. Metaclass

| Classe | `gMetaClass` | Costruttore |
|---|---:|---:|
| Navi | `0xC2717D8` | `0xC26C930` |
| SWI | `0xC271800` | `0xC26CDC0` |
| Abstract | `0x6E5860` (`X4000`) | `0x6E0F80` (`X4000`) |
| Interface | `0x6E5838` (`X4000`) | `0x6E0DA0` (`X4000`) |

**PROVEN:** Navi e SWI hanno metaclass X6000.
**PROVEN:** Abstract/Interface usano simboli X4000.
**PROVEN:** i metaclass non chiamano `registerService`.
**UNPROVEN:** registrazione dinamica runtime.

---

## 5. SWI::start

| Elemento | Valore |
|---|---|
| Super-call | `IOService::open` |
| Slot | `0x5D0` |
| Helper | `0xC26D060` |
| Chiave | `AmdTtlInterfaceKey` |
| `callPlatformFunction` | **SÌ** |
| `registerService` | **NO** |
| `allocClassWithName` | **NO** |

**PROVEN:** apre il provider.
**PROVEN:** non pubblica.
**PROVEN:** non alloca classi.

---

## 6. Slot `0x5B0`

| Vtable | Valore | Significato |
|---|---:|---|
| Navi | `0x994C60` / L0 | `registerService` |
| SWI | `0x994C60` / L0 | `registerService` |
| Abstract | `0x994C60` / L0 | `registerService` |

**PROVEN:** lo slot è `registerService`.
**PROVEN:** Navi non lo chiama.
**UNPROVEN:** chiamata esterna sul oggetto Navi.

---

## 7. X6000HWLibs

| Requisito | Valore |
|---|---|
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `LoadPlugIn=Load6000` |
| Interface pubblicata | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| Matching | **UNPROVEN** |

**PROVEN:** i requisiti.
**UNPROVEN:** la pubblicazione del provider.

---

## 8. Classificazione

| Percorso | Esito |
|---|---|
| `IOService::start` → `registerService` | **REFUTED** |
| `SWI::start` → `registerService` | **REFUTED** |
| `Abstract::start` → `registerService` | **PROVEN** |
| Navi → `Abstract::start` | **NO** |
| Metaclass → pubblicazione | **NO osservato** |
| Callback esterna | **UNPROVEN** |
| Runtime | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `IOService::start` pubblica | **NO** |
| `SWI::start` pubblica | **NO** |
| `Navi` pubblica staticamente | **NO** |
| `Abstract::start` pubblica | **SÌ** |
| `Navi` lo raggiunge | **NO** |
| Pubblicazione Navi | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `IOService::start` è un semplice `return true` e non chiama `registerService`; nel testo BootKC non esistono call dirette a `registerService`, e l’unico call site indiretto `0x5B0` è in `Abstract::start`. `SWI::start` apre il provider e usa `AmdTtlInterfaceKey`, ma non pubblica; i metaclass non offrono un percorso di pubblicazione. La pubblicazione automatica via framework è **REFUTED**, quella runtime esterna resta **UNPROVEN**, così come il matching X6000HWLibs → Navi. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
