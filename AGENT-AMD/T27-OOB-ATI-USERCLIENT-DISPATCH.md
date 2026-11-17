# T27 — AGENT-AMD — ATI USERCLIENT DISPATCH

**Scope:** verificare se `AtiPowerPlayUserClient::getTargetAndMethodForIndex` (`0x29B600`) o la method template (`0x2A1D40`) raggiungono `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute` (`0xBF9894E`, slot `0x860`); analizzare anche `AtiUserClient`.

**Modalità:** sola lettura; AMDSupportPart, SystemKC, X6000FramebufferFull; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **REFUTED** che `AtiPowerPlayUserClient` o `AtiUserClient` raggiungano direttamente il vendor; **PROVEN** che entrambi restituiscono solo method template; **UNPROVEN** i due candidati `AMDFramebuffer`. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| AMDSupportPart (estratto) | `849ccf34c3976f6859eee962f2fc829c27061dff8d0b0526a1561d374f3b5cf4` |
| X6000FramebufferFull | `7104d431bac240b1c60e5fa1d6308bec9cb7dbb689eaf263e79d1dc0796835eb` |
| Report 138 | `e05f245aaa0f0543a0dd6a7ae4417d325f47a08cab2027c363a4fc6204d4c679` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. getTargetAndMethodForIndex

### AtiPowerPlayUserClient 0x29B600

| Indirizzo | Operazione |
|---:|---|
| `0x29B61B` | `cmpl $0x3` |
| `0x29B621` | index ≥ 3 → `NULL` |
| `0x29B633` | scrive il target |
| `0x29B63B` | `leaq 0x66FE` → `0x2A1D40` |
| `0x29B642` | `index * 0x30` |
| `0x29B64D` | restituisce il puntatore |

**PROVEN:** 3 metodi.
**PROVEN:** nessuna chiamata.
**PROVEN:** nessun riferimento a `0x860` o `0xBF9894E`.

### AtiUserClient 0x291F70

| Indirizzo | Operazione |
|---:|---|
| `0x291F8B` | `cmpl $0xA` |
| `0x291F91` | index ≥ 10 → `NULL` |
| `0x291FAB` | scrive il target |
| `0x291FB3` | `leaq 0xF0F6` → `0x2A10B0` |
| `0x291FBA` | `index * 0x30` |
| `0x291FC5` | restituisce il puntatore |

**PROVEN:** 10 metodi.
**PROVEN:** nessuna chiamata.
**PROVEN:** nessun riferimento a `0x860` o `0xBF9894E`.

---

## 3. Method template

### AtiPowerPlay 0x2A1D40

| Entry | Funzione | Nome |
|---:|---:|---|
| 0 | `0x29B660` | `openUserClient` |
| 1 | `0x29B710` | `closeUserClient` |
| 2 | `0x29B7E0` | `cwddePassThrough` |

**PROVEN:** le tre funzioni sono in AMDSupport.
**PROVEN:** nessuna è `0xBF9894E`.
**REFUTED:** la template raggiunge il vendor.

### AtiUserClient 0x2A10B0

| Entry | Funzione |
|---:|---:|
| 0 | `0x291FD0` |
| 1 | `0x292110` |
| 2–9 | **UNPROVEN** |

**PROVEN:** 10 entry.
**PROVEN:** nessun puntatore a `0xBF9894E`.
**UNPROVEN:** i nomi delle 10 funzioni.

---

## 4. Riferimenti a *0x860

| Indirizzo | Funzione | Oggetto | Stato |
|---:|---|---|---|
| `0x27C570` | `AMDFramebuffer::start` | da `0x1016E` | **UNPROVEN** |
| `0x28AD72` | `AMDFramebuffer::enableHardware` | `0xDD8(%rax)` | **UNPROVEN** |
| `0xBF63E93` | `createPowerPlayInterface` | `0x50(%rbx)` | **REFUTED** (report 135) |

**PROVEN:** due chiamate in `AMDFramebuffer`.
**PROVEN:** nessuna chiamata in AtiUserClient/AtiPowerPlay.
**UNPROVEN:** il tipo dell’oggetto e la firma nei due casi AMDFramebuffer.

---

## 5. Puntatori e stringhe

| Test | Esito |
|---|---|
| `0xBF9894E` in AMDSupport | **0** |
| `vendor_doDeviceAttribute` in AMDSupport | **0** |
| `*0x860` in AtiUserClient | **0** |
| `*0x860` in AtiPowerPlay | **0** |
| Puntatore a vendor in SystemKC | **solo** `0xC1F1010` |

**PROVEN:** nessun puntatore/stringa nei client.
**PROVEN:** l’unico puntatore statico a vendor è la vtable Wrangler.
**UNPROVEN:** il dispatch dinamico.

---

## 6. AMDFramebuffer

| Funzione | Indirizzo | Chiamata |
|---|---:|---|
| `start` | `0x27BCF0` | `*0x860` a `0x27C570` |
| `enableHardware` | `0x28ACF0` | `*0x860` a `0x28AD72` |

**PROVEN:** le due funzioni chiamano `*0x860`.
**PROVEN:** non sono AtiUserClient.
**UNPROVEN:** se l’oggetto è Wrangler.
**UNPROVEN:** la compatibilità degli argomenti con `vendor_doDeviceAttribute`.

---

## 7. STOP

| Criterio | Esito |
|---|---|
| AtiUserClient → vendor | **REFUTED** |
| AtiPowerPlay → vendor | **REFUTED** |
| Caller dimostrabile | **NO** |
| Candidati AMDFramebuffer | **UNPROVEN** |
| Spazio >10 GiB | **SÌ** |
| Modifiche | **NO** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente con certezza.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| AtiPowerPlay metodi | 3 |
| AtiUserClient metodi | 10 |
| Template → vendor | **NO** |
| `*0x860` nei client | **0** |
| `0xBF9894E` in AMDSupport | **0** |
| AMDFramebuffer | 2 chiamate **UNPROVEN** |
| Caller effettivo | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `AtiPowerPlayUserClient::getTargetAndMethodForIndex` (`0x29B600`) espone 3 metodi e restituisce la template `0x2A1D40` (`openUserClient 0x29B660`, `closeUserClient 0x29B710`, `cwddePassThrough 0x29B7E0`). `AtiUserClient` (`0x291F70`) ne espone 10 e restituisce `0x2A10B0`. Nessuna delle due funzioni chiama `*0x860` e nessuna template contiene `0xBF9894E`: il percorso AtiUserClient/AtiPowerPlay → vendor è **REFUTED**. Le due chiamate `*0x860` trovate sono in `AMDFramebuffer::start` (`0x27C570`) e `AMDFramebuffer::enableHardware` (`0x28AD72`); il tipo dell’oggetto e la compatibilità degli argomenti restano **UNPROVEN**. STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
