# T27 — AGENT-AMD — WRANGLER HIERARCHY

**Scope:** verificare se `vendor_doDeviceAttribute` è invocato tramite funzione ereditata, interfaccia IOKit o dispatch esterno; analizzare metaclass e superclassi; distinguere implementazione e caller degli slot `0x860`, `0x680`, `0x6C8`; verificare `IOUserClient`/GPU PowerPlay e X5000.

**Modalità:** sola lettura; SystemKC, X6000FramebufferFull, AGDC, AMDSupportPart; nessun boot, trace, modifica, build, download o estrazione pesante.

**Nota:** il prompt 137 è arrivato troncato dopo “STOP: nessun”; è stata eseguita la parte disponibile.

**Esito:** **PROVEN** che il Wrangler eredita da `AppleGraphicsDeviceControl`; **PROVEN** che non implementa `externalMethod`/`getTargetAndMethodForIndex`; **REFUTED** un caller diretto via `AppleGraphicsDeviceControlClient::externalMethod`; **UNPROVEN** il caller effettivo. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| X6000FramebufferFull | `7104d431bac240b1c60e5fa1d6308bec9cb7dbb689eaf263e79d1dc0796835eb` |
| AGDC (estratto) | `7a472f80849d77449b060efdd18c7397d878fd82175ec59a18363e8d2385f88c` |
| AMDSupportPart (estratto) | `849ccf34c3976f6859eee962f2fc829c27061dff8d0b0526a1561d374f3b5cf4` |
| Report 136 | `135bce89df267c6e2163a2ee911feb12bf7a33dcc16bd055ce24c9e782c2d6f3` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Gerarchia

| Classe | `superClass` raw | Target | Identità |
|---|---:|---:|---|
| `AMDRadeonX6000_AmdGpuWrangler` | `0x4000004C262648` | `0x13D458E8` | `AppleGraphicsDeviceControl::gMetaClass` |
| `AppleGraphicsDeviceControl` | `0xC00000012AA488` | `0x12AA488` | **UNPROVEN** |
| `AppleGraphicsDeviceControlClient` | `0xC00000012A9E78` | `0x12A9E78` | **UNPROVEN** |

**PROVEN:** Wrangler → `AppleGraphicsDeviceControl`.
**PROVEN:** `0x12AA488` è il superClass di AGDC.
**UNPROVEN:** l’identità di `0x12AA488` e `0x12A9E78`.
**COERENTE:** `0x12AA488` è lo stesso target OOB già `UNPROVEN` nei report precedenti.

---

## 3. Metodi ereditati

| Metodo | Wrangler | AGDC | AGDCClient |
|---|---|---|---|
| `externalMethod` | **NO** | **NO** | **SÌ** `0x13D3F6DC` |
| `getTargetAndMethodForIndex` | **NO** | **NO** | **NO** |
| `callPlatformFunction` | **SÌ** `0xBF98BC0` | **NO** | **NO** |
| `vendor_doDeviceAttribute` | **SÌ** `0xBF9894E` | **SÌ** `0x13D41C34` | **NO** |
| `newUserClient` | **NO** | **SÌ** `0x13D41CBE` | **NO** |

**PROVEN:** Wrangler non implementa `externalMethod`/`getTarget`.
**PROVEN:** AGDCClient implementa `externalMethod`.
**PROVEN:** Wrangler e AGDC hanno overload diversi di `vendor_doDeviceAttribute`.

---

## 4. Slot

| Slot | Implementazione | Caller |
|---:|---|---|
| `0x680` | `attach` `0xBF986D2` | **UNPROVEN** |
| `0x6C8` | `callPlatformFunction` `0xBF98BC0` | **UNPROVEN** |
| `0x860` | `vendor_doDeviceAttribute` `0xBF9894E` | **UNPROVEN** |

**PROVEN:** le tre implementazioni.
**PROVEN:** nessun caller statico.
**UNPROVEN:** il dispatch.

---

## 5. vendor: due overload

| Classe | Simbolo | Ultimo argomento |
|---|---|---|
| Wrangler | `0xBF9894E` | `IOExternalMethodArguments*` |
| AGDC | `0x13D41C34` | `AGDCClientState_t*` |

**PROVEN:** le firme differiscono.
**PROVEN:** non sono la stessa funzione.
**UNPROVEN:** il percorso che raggiunge l’overload Wrangler.

---

## 6. AGDCClient externalMethod

| Indirizzo | Operazione |
|---:|---|
| `0x13D3F6DC` | `externalMethod` |
| `0x13D3F796` | carica `0xD8(%r13)` |
| `0x13D3F7A4` | `callq 0x13D41E60` |
| `0x13D41C34` | `vendor_doDeviceAttribute` AGDC |
| `0x13D41C54` | `callq *0x850` |

**PROVEN:** externalMethod chiama `0x13D41E60`.
**PROVEN:** usa la firma AGDC.
**REFUTED:** chiama direttamente `0xBF9894E`.
**UNPROVEN:** `0x13D41E60`.

---

## 7. IOUserClient / PowerPlay

| Classe | Metodo | Indirizzo |
|---|---|---:|
| `AtiUserClient` | `getTargetAndMethodForIndex` | `0x291F70` |
| `AtiPowerPlayUserClient` | `getTargetAndMethodForIndex` | `0x29B600` |
| `AtiPowerPlayUserClient` | `start` | `0x29BA40` |
| `AtiUserClient` | `start` | `0x2928A0` |

| Test | Esito |
|---|---|
| Puntatore a `0xBF9894E` in AMDSupport | **NO** |
| Stringa vendor in AMDSupport | **NO** |
| Metodo template | `0x2A10B0`, `0x2A1D40` |
| Caller Wrangler | **UNPROVEN** |

**PROVEN:** esistono user client con dispatch.
**PROVEN:** nessun puntatore statico a vendor.
**UNPROVEN:** la tabella dei metodi e il caller.

---

## 8. X5000

| Elemento | Valore |
|---|---|
| `AtiGpuWrangler::start` | `0x13B84000` |
| `vendor_doDeviceAttribute` | `0x13B84370` |
| `callPlatformFunction` | `0x13B84810` |
| `LoadHWServices` | `0x13BE4880` |
| Vtable | **non analizzata** |
| Caller | **UNPROVEN** |

**PROVEN:** gli stessi simboli.
**UNPROVEN:** la vtable e il caller.

---

## 9. STOP

| Criterio | Esito |
|---|---|
| Caller dimostrabile | **NO** |
| Ereditarietà sufficiente | **NO** |
| Dispatch esterno | **NO** |
| Mapping ambiguo | **SÌ** |
| Spazio >10 GiB | **SÌ** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente con certezza.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| Superclasse Wrangler | `AppleGraphicsDeviceControl` |
| Superclasse AGDC | `0x12AA488` **UNPROVEN** |
| `externalMethod` Wrangler | **NO** |
| `getTarget` Wrangler | **NO** |
| `callPlatformFunction` | `0xBF98BC0` |
| Slot `0x860` | `vendor_doDeviceAttribute` |
| Caller | **UNPROVEN** |
| IOUserClient | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il Wrangler eredita da `AppleGraphicsDeviceControl`; non implementa `externalMethod` né `getTargetAndMethodForIndex`. `AppleGraphicsDeviceControlClient::externalMethod` (`0x13D3F6DC`) usa la firma AGDC (`AGDCClientState_t*`) e chiama `0x13D41E60`, non l’overload Wrangler (`0xBF9894E`, `IOExternalMethodArguments*`). Gli user client `AtiUserClient` e `AtiPowerPlayUserClient` hanno `getTargetAndMethodForIndex`, ma non contengono puntatori o stringhe verso il vendor Wrangler. Lo slot `0x860` resta l’unico riferimento alla funzione; il caller non è dimostrabile. STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
