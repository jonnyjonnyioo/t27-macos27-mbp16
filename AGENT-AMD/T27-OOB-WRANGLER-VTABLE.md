# T27 — AGENT-AMD — WRANGLER VTABLE

**Scope:** analizzare integralmente la vtable `0xC1F07B0`, inclusi gli slot `0x680` e `0x860`; identificare funzioni e prototipi; cercare riferimenti diretti/indiretti a `0xC1F1010` in SystemKC/BootKC; verificare dispatch alternativi verso `vendor_doDeviceAttribute`.

**Modalità:** sola lettura; SystemKC, BootKC, X6000FramebufferFull; nessun boot, trace, modifica, build, download o estrazione pesante.

**Nota:** il prompt 136 è arrivato troncato dopo “Esamina met…”; è stata eseguita la parte disponibile.

**Esito:** **PROVEN** che la vtable ha 279 slot e che `0x680` è `attach` e `0x860` è `vendor_doDeviceAttribute`; **REFUTED** un riferimento assoluto allo slot `0xC1F1010`; **UNPROVEN** un caller alternativo. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| X6000FramebufferFull (estratto, header normalizzato) | `7104d431bac240b1c60e5fa1d6308bec9cb7dbb689eaf263e79d1dc0796835eb` |
| Report 135 | `13bdc1dd628535a7e1b4470876e7b47febbdcf32f2f4fe51c1c18deb556a2e3c` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Dimensioni

| Elemento | Valore |
|---|---:|
| Vtable base | `0xC1F07B0` |
| MetaClass vtable | `0xC1F1068` |
| Intervallo | `0x8B8` |
| Slot | **279** |
| Slot Wrangler-specifici | **11** |
| Slot base/condivisi | **268** |

**PROVEN:** la vtable termina prima della MetaClass vtable.
**PROVEN:** `0x860` è dentro l’intervallo.
**UNPROVEN:** i prototipi dei 268 slot condivisi.

---

## 3. Slot Wrangler-specifici

| Slot | Funzione | Indirizzo | Prototipo |
|---:|---|---:|---|
| `0x10` | `~D1` | `0xBF98468` | deleting destructor |
| `0x18` | `~D0` | `0xBF98472` | deleting destructor |
| `0x48` | `getMetaClass` | `0xBF984B2` | `const OSMetaClass*()` |
| `0xA0` | `free` | `0xBF98876` | `void()` |
| `0x5C8` | `probe` | `0xBF985AE` | `bool(IOService*)` |
| `0x5D0` | `start` | `0xBF987C2` | `bool(IOService*)` |
| `0x5D8` | `stop` | `0xBF988B2` | `void(IOService*)` |
| `0x680` | `attach` | `0xBF986D2` | `bool(IOService*)` |
| `0x688` | `detach` | `0xBF988C4` | `void(IOService*)` |
| `0x6C8` | `callPlatformFunction` | `0xBF98BC0` | `bool(const OSSymbol*, bool, void*, void*, void*, void*)` |
| `0x860` | `vendor_doDeviceAttribute` | `0xBF9894E` | `uint32_t(uint32_t, uint64_t, uint64_t, uint64_t, uint64_t, IOExternalMethodArguments*)` |

**PROVEN:** i 11 slot e gli indirizzi.
**PROVEN:** `0x680` è `attach`.
**PROVEN:** `0x860` è `vendor_doDeviceAttribute`.
**UNPROVEN:** i caller.

---

## 4. Slot 0x680 e 0x860

| Slot | Raw | Target | Funzione |
|---:|---:|---:|---|
| `0x680` | `0x4000004BF986D2` | `0xBF986D2` | `attach` |
| `0x860` | `0x4000004BF9894E` | `0xBF9894E` | `vendor_doDeviceAttribute` |

**PROVEN:** i due slot sono distinti.
**PROVEN:** `0x860` non è `attach`.
**UNPROVEN:** il dispatch runtime.

---

## 5. Riferimenti a 0xC1F1010

| Immagine | Riferimenti assoluti |
|---|---:|
| SystemKC | **0** |
| BootKC | **0** |
| Vtable base | **1** in SystemKC, **0** in BootKC |

**PROVEN:** nessun riferimento assoluto allo slot `0xC1F1010`.
**PROVEN:** un riferimento assoluto alla base `0xC1F07B0`.
**UNPROVEN:** i riferimenti indiretti via `*0x860`.

---

## 6. Dispatch alternativi

| Test | Esito |
|---|---|
| Puntatore a `vendor` | **solo** `0xC1F1010` |
| `IOExternalMethodDispatch` | **non trovata** |
| `getTargetAndMethodForIndex` Wrangler | **assente** |
| Chiamata diretta a `vendor` | **assente** |
| Chiamata indiretta nota | **solo** `*0x860` |

**PROVEN:** un solo puntatore a `vendor`.
**PROVEN:** nessun dispatch Wrangler.
**UNPROVEN:** l’invocazione effettiva.

---

## 7. createPowerPlayInterface

| Indirizzo | Operazione |
|---:|---|
| `0xBF63E62` | inizio |
| `0xBF63E88` | `rdi = 0x50(%rbx)` |
| `0xBF63E8C` | `rsi = &0x70(%rbx)` |
| `0xBF63E93` | `callq *0x860` |
| `0xBF63E99` | salva il ritorno in `0x68(%rbx)` |
| `0xBF63EA8` | `callq *0x30` sul ritorno |

**PROVEN:** chiama `*0x860`.
**REFUTED:** è `vendor_doDeviceAttribute` sul Wrangler.
**Motivo:** `vendor` restituisce `uint32_t`; qui il ritorno è un oggetto usato con `*0x30`.
**UNPROVEN:** il tipo dell’oggetto a `0x50(%rbx)`.

---

## 8. ServiceManager

| Test | Esito |
|---|---|
| Range | `0x2A50000`–`0x2A90000` |
| `Wrangler` | **0** |
| `LoadHWServices` | **0** |
| `AMDRadeonX6000_AmdGpuWrangler` | **0** |
| `AMDRadeonLoadSvcMgr` | **1** |
| Invocazione Wrangler | **UNPROVEN** |

**PROVEN:** nessun riferimento testuale a Wrangler.
**PROVEN:** solo la chiave `AMDRadeonLoadSvcMgr`.
**UNPROVEN:** l’invocazione indiretta.

---

## 9. X5000

| Elemento | Valore |
|---|---|
| `AtiGpuWrangler::start` | `0x13B84000` |
| `vendor_doDeviceAttribute` | `0x13B84370` |
| `LoadHWServices` | `0x13BE4880` |
| Vtable X5000 | **non analizzata** |
| Caller | **UNPROVEN** |

**PROVEN:** gli stessi simboli.
**UNPROVEN:** la vtable e il caller.

---

## 10. STOP

| Criterio | Esito |
|---|---|
| Caller dimostrabile | **NO** |
| Dispatch alternativo | **NO** |
| Riferimento allo slot | **NO** |
| Mapping ambiguo | **SÌ** |
| Spazio >10 GiB | **SÌ** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente con certezza.

---

## 11. Conclusione

| Domanda | Risposta |
|---|---|
| Vtable | 279 slot |
| `0x680` | `attach` |
| `0x860` | `vendor_doDeviceAttribute` |
| Puntatore a vendor | **solo** `0xC1F1010` |
| Riferimenti assoluti allo slot | **0** |
| Dispatch alternativo | **NO** |
| `createPowerPlayInterface` | **NO** |
| Caller effettivo | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la vtable Wrangler va da `0xC1F07B0` a `0xC1F1068` (279 slot). Gli slot `0x680` e `0x860` sono rispettivamente `attach` (`0xBF986D2`) e `vendor_doDeviceAttribute` (`0xBF9894E`). `vendor` compare solo in `0xC1F1010` (slot `0x860`); non esistono riferimenti assoluti a `0xC1F1010` in SystemKC o BootKC, né una struttura `IOExternalMethodDispatch`, né `getTargetAndMethodForIndex` nella classe Wrangler. `createPowerPlayInterface` chiama `*0x860`, ma restituisce un oggetto e non è compatibile con `vendor` (`uint32_t`): resta **UNPROVEN**. `AMDRadeonServiceManager` non contiene stringhe Wrangler. STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
