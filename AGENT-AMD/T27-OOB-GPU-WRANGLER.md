# T27 — AGENT-AMD — GPU WRANGLER

**Scope:** verificare se GPU Wrangler collega HWServices, HWLibs e registrazione dell’acceleratore AMD; identificare `LoadController`, `LoadAccelerator`, `GPU Wrangler`, xref e sezioni Mach-O.

**Modalità:** sola lettura; SystemKC, X6000Framebuffer estratto, X6000HWServices, X5000HWServices; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che `AMDRadeonX6000_AmdGpuWrangler::start` pubblica `AMDRadeonLoadSvcMgr` e che `vendor_doDeviceAttribute` scrive `LoadHWServices`, `LoadController` e `LoadAccelerator` sul provider, followed by `registerService`. **UNPROVEN** il caller runtime dell’external method. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| X6000Framebuffer (estratto, header normalizzato) | `5335adf6916f3ce199402b72de370eb425dfaacd6cff0cc267f20bdef85ddec9` |
| X6000HWServices | `2aa47ceee99969d3eba360fe558a3fbcd7e69c4bea2cd76704350a9bdfafe453` |
| X5000HWServices | `8a88fe7276968d3b124c9ff7ccf26d18b5e918fc339ab3681dfcb5a2cbd3cfbf` |
| Report 133 | `84654514c4a0949e3e7701105c6f6d79e457ec31925b600d1146a1c2f7f41ba9` |

**PROVEN:** gli artefatti sono quelli indicati.
**PROVEN:** l’estratto X6000Framebuffer è Mach-O `cffaedfe`, 2.661.080 byte.

---

## 2. Simboli Wrangler

| Simbolo | Indirizzo |
|---|---:|
| `AMDRadeonX6000_AmdGpuWrangler::start` | `0xBF987C2` |
| `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute` | `0xBF9894E` |
| `AMDRadeonX6000_AmdGpuWrangler::probe` | `0xBF985AE` |
| `AMDRadeonX6000_AmdGpuWrangler::attach` | `0xBF986D2` |
| `AMDRadeonX6000_AmdGpuWrangler::stop` | `0xBF988B2` |
| `AtiGpuWrangler::start` | `0x13B84000` |
| `AtiGpuWrangler::vendor_doDeviceAttribute` | `0x13B84370` |

**PROVEN:** la classe X6000 è definita nel Framebuffer.
**PROVEN:** X5000 ha gli stessi metodi.
**UNPROVEN:** l’equivalenza del corpo X5000.

---

## 3. start

| Indirizzo | Operazione |
|---:|---|
| `0xBF987CF` | chiamata virtuale `*0x5D0` |
| `0xBF987F1` | `callq 0x1007E` |
| `0xBF98802` | `"SpecialAMDKey"` |
| `0xBF9882E` | `"AMDRadeonLoadSvcMgr"` |
| `0xBF98838` | `callq *0x2B8` = getProperty |
| `0xBF98857` | `callq *0x278` = setProperty(key, true) |
| `0xBF98865` | `callq *0x5B0` = registerService(0) |

**PROVEN:** `start` verifica `AMDRadeonLoadSvcMgr`.
**PROVEN:** se assente, lo imposta a `true`.
**PROVEN:** registra il servizio.
**UNPROVEN:** l’oggetto esatto restituito da `0x101C2`.

---

## 4. AMDRadeonServiceManager

```xml
<key>AMDRadeonServiceManager</key>
<dict>
  <key>CFBundleIdentifier</key>
  <string>com.apple.kext.AMDRadeonServiceManager</string>
  <key>IOClass</key>
  <string>AMDRadeonServiceManager</string>
  <key>IOMatchCategory</key>
  <string>AMDRadeonServiceManager</string>
  <key>IOPropertyMatch</key>
  <dict>
    <key>AMDRadeonLoadSvcMgr</key>
    <true/>
  </dict>
  <key>IOProviderClass</key>
  <string>IOResources</string>
  <key>IOResourceMatch</key>
  <string>IOKit</string>
</dict>
```

**PROVEN:** la personality consuma `AMDRadeonLoadSvcMgr=true`.
**PROVEN:** il provider è `IOResources`.
**UNPROVEN:** il runtime.

---

## 5. vendor_doDeviceAttribute

| Indirizzo | Operazione |
|---:|---|
| `0xBF989A2` | selector `3` o `1` |
| `0xBF98A05` | `callq *0x680` = provider |
| `0xBF98A17` | `callq 0xBF8EC04` |
| `0xBF98A25` | `"LoadHWServices"` |
| `0xBF98A34` | `callq *0x278` = setProperty(key, true) |
| `0xBF98A45` | `callq *0x5B0` = registerService(2) |
| `0xBF98A54` | `"LoadController"` |
| `0xBF98A72` | `"LoadAccelerator"` |
| `0xBF98A95` | `registerService(0)` |
| `0xBF98A9E` | `callq 0xBF8EC04` |

**PROVEN:** il metodo scrive `LoadHWServices=true` sul provider.
**PROVEN:** scrive `LoadController=true` e `LoadAccelerator=true`.
**PROVEN:** chiama `registerService(2)` e `registerService(0)`.
**UNPROVEN:** chi invoca il metodo.

---

## 6. Catena statica

```text
Wrangler::start
  -> setProperty("AMDRadeonLoadSvcMgr", true)
  -> registerService(0)
  -> AMDRadeonServiceManager (IOResources, match AMDRadeonLoadSvcMgr)
  -> [caller runtime UNPROVEN]
  -> Wrangler::vendor_doDeviceAttribute
  -> setProperty("LoadHWServices", true) sul provider
  -> registerService(2)
  -> HWServices (IOPCIDevice, match LoadHWServices)
  -> LoadPlugIn=Load6000
  -> HWLibs
```

**PROVEN:** la catena statica esiste.
**PROVEN:** il Wrangler è il punto che pubblica entrambe le proprietà.
**UNPROVEN:** il passaggio ServiceManager → external method.
**UNPROVEN:** l’attivazione HWLibs.

---

## 7. Sezioni Mach-O

| Segmento | VM | Size |
|---|---:|---:|
| `__TEXT` | `0xBF54000` | `0x28A000` |
| `__DATA` | `0xC1DE000` | `0x8C000` |
| `__DATA_CONST` | `0xC26A000` | `0x2000` |
| `__LINKEDIT` | `0x1539C000` | `0xC5A677` |

| Sezione | VM | Size |
|---|---:|---:|
| `__text` | `0xBF549B0` | `0x1EC6A8` |
| `__cstring` | `0xC141060` | `0x392E7` |
| `__const` | `0xC17A350` | `0x63788` |

**PROVEN:** i segmenti locali sono adiacenti e non si sovrappongono.
**PROVEN:** `LoadHWServices` a `0xC14F4A3` è in `__cstring`.
**PROVEN:** il segmento globale `__REGION19` sovrasta i kext; la non-sovrapposizione locale non prova quella globale.

---

## 8. X5000

| Elemento | Valore |
|---|---|
| `AtiGpuWrangler::start` | `0x13B84000` |
| `vendor_doDeviceAttribute` | `0x13B84370` |
| `LoadHWServices` | `0x13BE4880` |
| `LoadAMDSupport` | `0x13BE4862` |
| Corpo disassemblato | **NO** |

**PROVEN:** X5000 ha gli stessi simboli e stringhe.
**UNPROVEN:** il corpo e l’equivalenza runtime.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Wrangler collega HWServices? | **SÌ, staticamente** |
| Pubblica `AMDRadeonLoadSvcMgr`? | **SÌ** |
| Pubblica `LoadHWServices`? | **SÌ** |
| Pubblica `LoadController`? | **SÌ** |
| Pubblica `LoadAccelerator`? | **SÌ** |
| Caller external method | **UNPROVEN** |
| HWLibs attivate | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** GPU Wrangler è il collegamento statico. `AMDRadeonX6000_AmdGpuWrangler::start` pubblica `AMDRadeonLoadSvcMgr=true` e registra il servizio; la personality `AMDRadeonServiceManager` lo consuma da `IOResources`. Lo stesso Wrangler, in `vendor_doDeviceAttribute` (`0xBF9894E`), scrive `LoadHWServices=true` sul provider e chiama `registerService(2)`, poi scrive `LoadController`/`LoadAccelerator` e registra. Le personality HWServices consumano `LoadHWServices=true`; `LoadPlugIn=Load6000` resta il passaggio dichiarativo verso HWLibs. Il caller dell’external method e l’attivazione HWLibs restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,2 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
