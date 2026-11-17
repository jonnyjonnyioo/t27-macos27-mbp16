# T27 — AGENT-AMD — AMDFRAMEBUFFER DISPATCH

**Scope:** verificare i due candidati `AMDFramebuffer::start` (`0x27BCF0`, call `0x27C570`) e `AMDFramebuffer::enableHardware` (call `0x28AD72`, oggetto `this+0xDD8`) come caller di `vendor_doDeviceAttribute` (`0xBF9894E`, slot `0x860`).

**Modalità:** sola lettura; AMDSupportPart, X6000FramebufferFull, SystemKC; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **REFUTED** `enableHardware` come caller Wrangler: `0xDD8` è il controller e lo slot `0x860` è `AmdRadeonController::notify` (`0xBFA1056`). **UNPROVEN** `start`: oggetto da stub `0x1016E` non risolto; le alternative note sono AgdcServices (`0xBF73668`) o controller (`0xBFA1056`), non Wrangler. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| AMDSupportPart | `849ccf34c3976f6859eee962f2fc829c27061dff8d0b0526a1561d374f3b5cf4` |
| X6000FramebufferFull | `7104d431bac240b1c60e5fa1d6308bec9cb7dbb689eaf263e79d1dc0796835eb` |
| Report 139 | `08ecb17653cdfa0aff648b3370f52b64f98a599c4a6d122e9283abd765889f87` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. AMDFramebuffer::start

| Indirizzo | Operazione |
|---:|---|
| `0x27BCF0` | inizio |
| `0x27C545` | `callq 0x1016E` |
| `0x27C550` | `callq *0x868` |
| `0x27C556` | salva il risultato in `-0x124` |
| `0x27C55C` | `callq 0x1016E` |
| `0x27C56A` | `esi = flags & -3` |
| `0x27C570` | `callq *0x860` |
| `0x27C576` | prosegue con `0x5D0` |

**PROVEN:** due chiamate allo stub `0x1016E`.
**PROVEN:** `*0x868`, poi `*0x860`.
**UNPROVEN:** il tipo dell’oggetto restituito da `0x1016E`.

### Stub 0x1016E

| Test | Esito |
|---|---|
| Simbolo locale | **assente** |
| Import stub | **sì** |
| Target | **UNPROVEN** |
| Oggetto | **UNPROVEN** |

**PROVEN:** lo stub non è risolto staticamente.
**UNPROVEN:** se restituisce AgdcServices, controller o provider.

---

## 3. AMDFramebuffer::enableHardware

| Indirizzo | Operazione |
|---:|---|
| `0x28ACF0` | inizio |
| `0x28AD58` | `rdi = 0xDD8(%rax)` |
| `0x28AD5F` | `callq 0x13B306A0` |
| `0x28AD68` | `rdi = 0xDD8(%rax)` |
| `0x28AD72` | `callq *0x860` |
| `0x28AD78` | salva il risultato |
| `0x28AD7F` | confronta con `0` |

**PROVEN:** chiama `*0x860` sull’oggetto `0xDD8`.
**PROVEN:** il risultato è trattato come `IOReturn`.
**UNPROVEN:** gli argomenti completi.

### Origine di 0xDD8

| Indirizzo | Operazione |
|---:|---|
| `0x27B830` | `AMDFramebuffer::attach` |
| `0x27B8B6` | `callq 0x27B910` = `findController` |
| `0x27B8C2` | `movq %rcx, 0xDD8(%rax)` |

**PROVEN:** `0xDD8` è il risultato di `findController`.
**PROVEN:** è un **controller**, non il Wrangler.
**UNPROVEN:** la classe esatta del controller.

---

## 4. Slot 0x860 per classe

| Classe | Vtable | Slot 0x860 | Target |
|---|---:|---:|---|
| `AmdGpuWrangler` | `0xC1F07B0` | `0x860` | `0xBF9894E` vendor |
| `AmdRadeonController` | `0xC1DF110` | `0x860` | `0xBFA1056` notify |
| `AmdAgdcServices` | `0xC1E3FB0` | `0x860` | `0xBF73668` vendor |

**PROVEN:** gli slot sono distinti.
**PROVEN:** il controller risolve a `notify`, non a vendor.
**PROVEN:** AgdcServices risolve al proprio vendor.

---

## 5. enableHardware è refutato

| Test | Esito |
|---|---|
| Oggetto `0xDD8` | controller |
| Slot `0x860` controller | `0xBFA1056` |
| `0xBFA1056` | `notify` |
| `0xBF9894E` | **NO** |
| Caller Wrangler | **REFUTED** |

**PROVEN:** `enableHardware` non chiama il vendor Wrangler.
**PROVEN:** chiama `notify` del controller.
**UNPROVEN:** il significato runtime di `notify`.

---

## 6. start resta unproven

| Test | Esito |
|---|---|
| Oggetto da `0x1016E` | **UNPROVEN** |
| Slot `0x860` Wrangler | `0xBF9894E` |
| Slot `0x860` AgdcServices | `0xBF73668` |
| Slot `0x860` controller | `0xBFA1056` |
| Caller Wrangler | **UNPROVEN** |

**PROVEN:** `start` non prova l’oggetto.
**UNPROVEN:** se sia Wrangler.
**REFUTED:** l’ipotesi che `enableHardware` sia lo stesso caller.

---

## 7. AgdcServices

| Elemento | Valore |
|---|---|
| vendor | `0xBF73668` |
| vtable | `0xC1E3FB0` |
| slot `0x860` | `0xBF73668` |
| Relazione con Wrangler | **distinta** |

**PROVEN:** AgdcServices ha un proprio vendor.
**PROVEN:** non è `0xBF9894E`.
**UNPROVEN:** se `start` usi AgdcServices.

---

## 8. STOP

| Criterio | Esito |
|---|---|
| Caller Wrangler dimostrabile | **NO** |
| enableHardware | **REFUTED** |
| start | **UNPROVEN** |
| Mapping ambiguo | **SÌ** |
| Spazio >10 GiB | **SÌ** |
| Modifiche | **NO** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente con certezza.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `start` oggetto | **UNPROVEN** |
| `enableHardware` oggetto | controller |
| `enableHardware` slot | `notify` |
| `start` slot | **UNPROVEN** |
| `0xBF9894E` | **NO** nei due |
| Caller Wrangler | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `AMDFramebuffer::enableHardware` chiama `*0x860` sull’oggetto `0xDD8`, che `AMDFramebuffer::attach` inizializza con `findController`: è un controller, e lo slot `0x860` della sua vtable è `AMDRadeonX6000_AmdRadeonController::notify` (`0xBFA1056`), non `vendor_doDeviceAttribute` (`0xBF9894E`). **REFUTED** come caller Wrangler. `AMDFramebuffer::start` chiama lo stub non risolto `0x1016E` e poi `*0x860`; l’oggetto può essere AgdcServices (`0xBF73668`) o controller (`0xBFA1056`), ma non è dimostrabile: **UNPROVEN**. Il caller Wrangler resta ignoto. STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
