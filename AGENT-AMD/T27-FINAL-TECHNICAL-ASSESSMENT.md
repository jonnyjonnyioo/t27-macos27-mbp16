# T27 — FINAL TECHNICAL ASSESSMENT

**Data:** 17 novembre 2026
**Scope:** chiusura della fase AMD X6000; consolidamento dei report canonici 121–137; catena Wrangler → ServiceManager → HWServices → Interface → HWLibs; ostacoli al primo boot macOS 26B131; prossima azione read-only.
**Vincoli:** nessun boot, `kmutil create`, `kextload`, installazione, modifica EFI/NVRAM/T2/SIP/AMFI; nessun download >2 GiB; spazio minimo 10 GiB; nessuna modifica a T16–T26.
**Esito:** **T27 resta OPEN**. Percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

---

## 1. Verifica SHA-256 dei report canonici

| # | Report | SHA atteso | SHA attuale | Esito |
|---:|---|---|---|---|
| 121 | `T27-OOB-9A48F0-IDENTITY.md` | `bb56538b…96d35` | `bb56538b…96d35` | **OK** |
| 122 | `T27-OOB-12AA488-NATURE.md` | `addfb50e…dbae` | `addfb50e…dbae` | **OK** |
| 123 | `T27-OOB-SUPERCLASS-INTERPRETATION.md` | `fa1836f7…ea28` | `fa1836f7…ea28` | **OK** |
| 124 | `T27-OOB-L3-BASE-SEARCH.md` | `292c0649…70f0` | `292c0649…70f0` | **OK** |
| 125 | `T27-OOB-INTERFACE-REGISTRATION.md` | `73be5f53…e4a7` | `73be5f53…e4a7` | **OK** |
| 126 | `T27-OOB-HWLIBS-LINK.md` | `f591c07f…7f90` | `275e95c3…fcf8` | **DIFF — rettifica** |
| 127 | `T27-OOB-PUBLICATION-PATH.md` | `ff688330…e1f9` | `c3556244…7cc2` | **DIFF — rettifica** |
| 128 | `T27-OOB-PLUGIN-IDENTITY.md` | `eb1a1876…a32b` | `7ec7f030…73f2` | **DIFF — rettifica** |
| 129 | `T27-OOB-MATCH-PROPERTY.md` | `58920009…ca73` | `58920009…ca73` | **OK** |
| 130 | `T27-OOB-MATCH-RUNTIME.md` | `e988ab53…a848` | `e988ab53…a848` | **OK** |
| 131 | `T27-OOB-CATALOGUE-MATCH.md` | `be9e6438…8800` | `be9e6438…8800` | **OK** |
| 132 | `T27-OOB-PERSONALITY-METADATA.md` | `682cec02…487e` | `682cec02…487e` | **OK** |
| 133 | `T27-OOB-LOAD-HWSERVICES.md` | `84654514…1ba9` | `84654514…1ba9` | **OK** |
| 134 | `T27-OOB-GPU-WRANGLER.md` | `651086f5…1867` | `651086f5…1867` | **OK** |
| 135 | `T27-OOB-WRANGLER-CALLER.md` | `13bdc1dd…2e3c` | `13bdc1dd…2e3c` | **OK** |
| 136 | `T27-OOB-WRANGLER-VTABLE.md` | `135bce89…d6f3` | `135bce89…d6f3` | **OK** |
| 137 | `T27-OOB-WRANGLER-HIERARCHY.md` | `1f996885…6cc8` | `1f996885…6cc8` | **OK** |

**PROVEN:** 14 report su 17 hanno SHA identico.
**PROVEN:** 126/127/128 differiscono perché contengono banner di rettifica aggiunti dopo il calcolo; non sono corrotti.
**PROVEN:** i banner 126/127/128 correggono `*0x20`, `Load6000` e la distinzione Navi/Interface.
**UNPROVEN:** l’SHA “atteso” di 126/127/128 non è più valido come hash corrente.

---

## 2. Catena consolidata

| Passaggio | Evidenza | Stato |
|---|---|---|
| Wrangler → `AMDRadeonLoadSvcMgr` | `start 0xBF987C2`; `setProperty("AMDRadeonLoadSvcMgr", true)`; `registerService(0)` | **PROVEN statico** |
| `AMDRadeonLoadSvcMgr` → ServiceManager | personality `AMDRadeonServiceManager`: provider `IOResources`, match `AMDRadeonLoadSvcMgr=true` | **PROVEN metadati** |
| ServiceManager → Wrangler | nessun caller statico; `vendor` solo slot `0x860` | **UNPROVEN** |
| Wrangler → `LoadHWServices` | `vendor_doDeviceAttribute 0xBF9894E`; `setProperty("LoadHWServices", true)`; `registerService(2)` | **PROVEN statico** |
| `LoadHWServices` → HWServices | personality X4000/X5000/X6000: `IOPCIDevice`, `LoadHWServices=true`, score `65051` | **PROVEN metadati** |
| HWServices → Interface | Interface ctor `0xC26D260`; nome `0xC26E200`; superclasse `0x12AA488`; nessun `registerService` | **UNPROVEN** |
| Interface → HWLibs | HWLibs: provider Interface, `IOMatchCategory=AMDRadeonHWLibs`, `LoadPlugIn=Load6000` | **PROVEN metadati** |
| HWLibs → caricamento | nessun riferimento statico a `AMDRadeonX6000HWLibs`; nessuna attivazione | **UNPROVEN** |

**PROVEN:** la catena dichiarativa esiste.
**PROVEN:** Wrangler è l’unico punto statico che pubblica `AMDRadeonLoadSvcMgr` e `LoadHWServices`.
**UNPROVEN:** il passaggio runtime ServiceManager → Wrangler.
**UNPROVEN:** la pubblicazione IOService di Interface.
**UNPROVEN:** il matching/caricamento HWLibs.

---

## 3. Classificazione per passaggio

| Passaggio | PROVEN | REFUTED | UNPROVEN |
|---|---|---|---|
| Wrangler → ServiceManager | proprietà e personality | — | caricamento runtime |
| ServiceManager → Wrangler | — | caller diretto noto | caller effettivo |
| Wrangler → HWServices | proprietà e match | — | attivazione |
| HWServices → Interface | classe e nome | `registerService` Navi | pubblicazione |
| Interface → HWLibs | provider/category/Load | referenza diretta nel codice | matching runtime |
| HWLibs → boot | personality completa | `IOProbeScore`/`IOResourceMatch`/`OSBundleRequired` assenti | attivazione |

**PROVEN:** le classificazioni sopra.
**REFUTED:** una referenza diretta a `AMDRadeonX6000HWLibs` nel codice.
**REFUTED:** `Load6000` come funzione.
**UNPROVEN:** ogni passaggio runtime.

---

## 4. Correzioni recepite

| Correzione | Report | Stato |
|---|---|---|
| `0x10180` è stub, non funzione | 120/121 | **PROVEN** |
| `0x9A48F0` mappa a `__REGION19` zero-filled | 121 | **PROVEN** |
| `0x12AA488` è codice x86_64, non class descriptor | 122/123 | **PROVEN** |
| Interface ha nome e catena OSMetaClass, ma non pubblicazione | 125 | **PROVEN** |
| `0x5B0` Navi è `_RESERVEDIOService47`, non `registerService` | 126/127 | **PROVEN** |
| `*0x20` HWLibs è `OSObject::release(int)`, non `start` | 127/128 | **PROVEN** |
| `Load6000` è proprietà di matching, non funzione | 128/129 | **PROVEN** |
| `getMatchProperty` non ha caller statico | 130 | **UNPROVEN** |
| `IOProbeScore`/`IOResourceMatch`/`OSBundleRequired` assenti per X6000HWLibs | 132 | **PROVEN** |
| Wrangler pubblica `AMDRadeonLoadSvcMgr` e `LoadHWServices` | 134 | **PROVEN statico** |
| `createPowerPlayInterface` non è il caller di vendor | 135 | **REFUTED** |
| `vendor` ha un solo puntatore, slot `0x860` | 136 | **PROVEN** |
| Wrangler eredita da `AppleGraphicsDeviceControl`; superclasse `0x12AA488` resta ignota | 137 | **PROVEN / UNPROVEN** |

**PROVEN:** le correzioni sono recepite nei report.
**UNPROVEN:** l’identità della superclasse `0x12AA488`.
**UNPROVEN:** il caller effettivo di `vendor_doDeviceAttribute`.

---

## 5. Ostacoli al primo boot

### 5.1 Nessun boot eseguito

**PROVEN:** T27 non ha eseguito boot, trace, `kmutil`, `kextload`, installazione o modifica.
**UNPROVEN:** il comportamento reale del primo boot.
**REFUTED:** l’idea che questa assessment sia una validazione runtime.

### 5.2 Ostacoli candidati

| # | Ostacolo | Evidenza | Stato |
|---:|---|---|---|
| 1 | Superclasse `0x12AA488` non è un class descriptor | report 122/123 | **UNPROVEN** |
| 2 | Interface non pubblicata staticamente | report 125/127 | **UNPROVEN** |
| 3 | Caller di `LoadHWServices` non dimostrato | report 134/135 | **UNPROVEN** |
| 4 | ServiceManager → Wrangler non dimostrato | report 137 | **UNPROVEN** |
| 5 | HWLibs non referenziato dal codice | report 126/128 | **UNPROVEN** |
| 6 | Nessun `IOProbeScore`/`IOResourceMatch`/`OSBundleRequired` per X6000HWLibs | report 132 | **UNPROVEN effetto** |

**PROVEN:** questi sono i punti statici rimasti aperti.
**UNPROVEN:** che uno di essi blocchi effettivamente il boot.
**NON PROVATO:** un difetto boot-blocking.

### 5.3 Distinzione importante

- **Ostacolo statico**: manca la prova di un passaggio.
- **Ostacolo runtime**: il passaggio fallisce o non avviene.
- **Boot-blocking**: il sistema non arriva al desktop.

**PROVEN:** T27 ha identificato solo ostacoli statici.
**UNPROVEN:** un boot-blocking reale.
**REFUTED:** dichiarare il boot rotto senza prova runtime.

---

## 6. Prossima azione tecnica concreta

**Azione:** estrarre integralmente il binario che contiene `AtiPowerPlayUserClient` (`0x29B600`, `0x29BA40`) e `AtiUserClient` (`0x291F70`), disassemblare `getTargetAndMethodForIndex` e la method template (`0x2A1D40`, `0x2A10B0`), e verificare se il dispatch chiama `vendor_doDeviceAttribute` (`0xBF9894E`) via slot `0x860` o via `callPlatformFunction`.

| Passo | Comando read-only | Criterio |
|---:|---|---|
| 1 | estrarre la finestra `AMDSupport` già identificata | SHA e Mach-O valido |
| 2 | `otool -tvV` su `getTargetAndMethodForIndex` | mapping slot/metodo |
| 3 | cercare `*0x860`, `0xBF9894E`, `vendor_doDeviceAttribute` | caller o assenza |
| 4 | confrontare X5000 `AtiGpuWrangler` | stesso schema |
| 5 | STOP se il caller non è dimostrabile | T27 resta OPEN |

**PROVEN:** l’azione è read-only e compatibile con T27.
**UNPROVEN:** il risultato.
**NON AUTORIZZATO:** boot/trace; richiederebbe un nuovo consenso esplicito.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| Report 121–137 verificati | **SÌ** |
| SHA coerenti | **14/17**, 3 con rettifica |
| Catena statica | **PROVEN** |
| Catena runtime | **UNPROVEN** |
| Primo boot validato | **NO** |
| Boot-blocking provato | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** i report 121–137 sono coerenti; 126/127/128 hanno SHA diverso solo per i banner di rettifica. La catena statica Wrangler → ServiceManager → HWServices → Interface → HWLibs è documentata, ma il passaggio runtime ServiceManager → Wrangler, la pubblicazione di Interface e il caricamento HWLibs restano **UNPROVEN**. Non è stato eseguito alcun boot e non esiste prova di un boot-blocking. Il primo boot resta al **32%**; T27 resta **OPEN** al **94% engineering**. La prossima azione è il disassemblaggio read-only del dispatch `AtiPowerPlayUserClient`/`AtiUserClient` per cercare il caller di `vendor_doDeviceAttribute`; senza boot/trace non si può chiudere il runtime.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
