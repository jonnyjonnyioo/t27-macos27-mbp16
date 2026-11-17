# T27 — AGENT-AMD — WRANGLER CALLER

**Scope:** ricostruire il collegamento tra `AMDRadeonServiceManager`, GPU Wrangler e l’invocazione dell’external method che attiva `LoadHWServices`; identificare tabella, selector, dispatch e caller.

**Modalità:** sola lettura; SystemKC, X6000FramebufferFull, X6000HWServices, X5000HWServices; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che `vendor_doDeviceAttribute` gestisce i selector 1/3 e scrive `LoadHWServices`; **REFUTED** che `createPowerPlayInterface` sia il suo caller; **UNPROVEN** il caller effettivo. STOP per caller non dimostrabile. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| X6000FramebufferFull (estratto, header normalizzato) | `7104d431bac240b1c60e5fa1d6308bec9cb7dbb689eaf263e79d1dc0796835eb` |
| X6000HWServices | `2aa47ceee99969d3eba360fe558a3fbcd7e69c4bea2cd76704350a9bdfafe453` |
| X5000HWServices | `8a88fe7276968d3b124c9ff7ccf26d18b5e918fc339ab3681dfcb5a2cbd3cfbf` |
| Report 134 | `651086f53b16b1bba39bfd6c98815bb0dcf35dad36a15569e8ca95f424b91867` |

**PROVEN:** gli artefatti sono quelli indicati.
**PROVEN:** l’estratto X6000FramebufferFull è Mach-O `cffaedfe`, 2.957.312 byte.

---

## 2. Metodi Wrangler

| Simbolo | Indirizzo |
|---|---:|
| `AMDRadeonX6000_AmdGpuWrangler::start` | `0xBF987C2` |
| `AMDRadeonX6000_AmdGpuWrangler::probe` | `0xBF985AE` |
| `AMDRadeonX6000_AmdGpuWrangler::attach` | `0xBF986D2` |
| `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute` | `0xBF9894E` |
| `AtiGpuWrangler::start` | `0x13B84000` |
| `AtiGpuWrangler::vendor_doDeviceAttribute` | `0x13B84370` |

**PROVEN:** i metodi e gli indirizzi.
**UNPROVEN:** il caller.

---

## 3. start

| Indirizzo | Operazione |
|---:|---|
| `0xBF987CF` | `callq *0x5D0` |
| `0xBF98802` | `"SpecialAMDKey"` |
| `0xBF9882E` | `"AMDRadeonLoadSvcMgr"` |
| `0xBF98838` | `callq *0x2B8` = getProperty |
| `0xBF98857` | `callq *0x278` = setProperty(key, true) |
| `0xBF98865` | `callq *0x5B0` = registerService(0) |

**PROVEN:** `start` pubblica `AMDRadeonLoadSvcMgr`.
**PROVEN:** registra il servizio.
**UNPROVEN:** l’ordine runtime.

---

## 4. vendor_doDeviceAttribute

| Indirizzo | Operazione |
|---:|---|
| `0xBF989A2` | selector `3` o `1` |
| `0xBF98A05` | `callq *0x680` |
| `0xBF98A25` | `"LoadHWServices"` |
| `0xBF98A34` | `callq *0x278` = setProperty(key, true) |
| `0xBF98A45` | `callq *0x5B0` = registerService(2) |
| `0xBF98A54` | `"LoadController"` |
| `0xBF98A72` | `"LoadAccelerator"` |
| `0xBF98A95` | `registerService(0)` |

**PROVEN:** selector 1 e 3.
**PROVEN:** `LoadHWServices=true` sul provider.
**PROVEN:** `LoadController`/`LoadAccelerator`.
**UNPROVEN:** chi lo invoca.

---

## 5. Tabella e dispatch

| Test | Esito |
|---|---|
| Puntatore a `vendor` | `0xC1F1010` |
| Vtable Wrangler | `0xC1F07B0` |
| Offset puntatore | `0x860` |
| Struttura `IOExternalMethodDispatch` | **non trovata** |
| `getTargetAndMethodForIndex` Wrangler | **assente** |
| Caller diretto | **assente** |
| Selector | `1`, `3` |

**PROVEN:** un solo puntatore a `vendor`.
**PROVEN:** nessun dispatch Wrangler.
**UNPROVEN:** il caller dinamico.

---

## 6. createPowerPlayInterface

| Indirizzo | Operazione |
|---:|---|
| `0xBF63E62` | inizio funzione |
| `0xBF63E6C` | check `0x50(%rdi)` |
| `0xBF63E88` | `rdi = 0x50(%rbx)` |
| `0xBF63E8C` | `rsi = &0x70(%rbx)` |
| `0xBF63E93` | `callq *0x860` |
| `0xBF63E99` | salva il ritorno in `0x68(%rbx)` |
| `0xBF63EA8` | `callq *0x30` sul ritorno |

**PROVEN:** la funzione chiama `*0x860`.
**PROVEN:** il ritorno è un oggetto usato con `*0x30`.
**REFUTED:** è `vendor_doDeviceAttribute`.
**Motivo:** `vendor` restituisce `unsigned int`; qui il ritorno è un puntatore a oggetto.

---

## 7. ServiceManager

| Test | Esito |
|---|---|
| Range analizzato | `0x2A50000`–`0x2A90000` |
| `Wrangler` | **0** |
| `LoadHWServices` | **0** |
| `AMDRadeonX6000_AmdGpuWrangler` | **0** |
| `AMDRadeonLoadSvcMgr` | **1** |
| Metodi | `start 0x2A5A38`, `probe 0x2A5970` |

**PROVEN:** ServiceManager non contiene riferimenti testuali a Wrangler.
**PROVEN:** contiene solo la propria chiave `AMDRadeonLoadSvcMgr`.
**UNPROVEN:** un’invocazione indiretta.

---

## 8. X5000

| Elemento | Valore |
|---|---|
| `AtiGpuWrangler::start` | `0x13B84000` |
| `vendor_doDeviceAttribute` | `0x13B84370` |
| `LoadHWServices` | `0x13BE4880` |
| Caller | **UNPROVEN** |
| Corpo disassemblato | **NO** |

**PROVEN:** gli stessi simboli.
**UNPROVEN:** il caller e il corpo.

---

## 9. STOP

| Criterio | Esito |
|---|---|
| Caller dimostrabile | **NO** |
| Mapping ambiguo | **SÌ** |
| Dispatch Wrangler | **NO** |
| Spazio >10 GiB | **SÌ** |
| Modifiche | **NO** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente con certezza.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| `vendor_doDeviceAttribute` | selector 1/3 |
| `LoadHWServices` | **SÌ** |
| Caller | **UNPROVEN** |
| `createPowerPlayInterface` | **NO** |
| ServiceManager → Wrangler | **UNPROVEN** |
| Catena statica | **SÌ** |
| Runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `vendor_doDeviceAttribute` (`0xBF9894E`) gestisce i selector 1/3, scrive `LoadHWServices=true`, `LoadController`, `LoadAccelerator` e chiama `registerService`; il suo unico riferimento è il puntatore `0xC1F1010`. Non esiste un dispatch `getTargetAndMethodForIndex` nella classe Wrangler e non è stata trovata una struttura `IOExternalMethodDispatch`. Il candidato `createPowerPlayInterface` (`0xBF63E62`) chiama `*0x860`, ma restituisce un oggetto e chiama `*0x30`: la firma è incompatibile con `vendor_doDeviceAttribute`, che restituisce `unsigned int`. `AMDRadeonServiceManager` non contiene stringhe Wrangler/LoadHWServices. Il caller effettivo resta **UNPROVEN**; STOP. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,0 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
