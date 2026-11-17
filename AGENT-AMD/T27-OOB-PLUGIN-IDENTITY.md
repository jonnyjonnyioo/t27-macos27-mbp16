# T27 — AGENT-AMD — PLUGIN IDENTITY

> **RETTIFICA (Prompt 129):** `*0x20` sulla vtable HWLibsX6000 è `OSObject::release(int)`, non `start`; `Load6000` è una proprietà di matching restituita da `Navi::getMatchProperty` (`0xC26CBE0`), non una funzione invocata.

**Scope:** identificare il plugin restituito dal Finder, verificare il matching con X6000HWLibs, analizzare le personality XML/plist, bundle identifier, executable, dipendenze e confrontare X5000.

**Modalità:** sola lettura; SystemKC prelink XML, X5000HWServices, X6000HWServices; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che X6000HWLibs è una personality registrata nei metadati con `IOClass=AMDRadeonX6000_AMDRadeonHWLibsX6000`, `IOMatchCategory=AMDRadeonHWLibs`, `IOProviderClass=AMDRadeonX6000_AMDRadeonHWServicesInterface` e `LoadPlugIn=Load6000`. **PROVEN** lo stesso schema X5000 con `Load5000`. **UNPROVEN** la registrazione/runtime effettiva. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| X6000HWServices | `2aa47ceee99969d3eba360fe558a3fbcd7e69c4bea2cd76704350a9bdfafe453` |
| X5000HWServices | `8a88fe7276968d3b124c9ff7ccf26d18b5e918fc339ab3681dfcb5a2cbd3cfbf` |
| Report 127 | `ff68833090614f4cebeba13f8e6e493f474439fe2045ceabab9684964fd1e1f9` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Eseguibili prelink

| Executable | Base | Size |
|---|---:|---:|
| `AMDRadeonX5000HWServices` | `0x457B000` | `0x23FB` |
| `AMDRadeonX5000HWLibs` | `0x4582000` | `0x5C1B7C` |
| `AMDRadeonX6000HWServices` | `0xC26C000` | `0x23CB` |
| `AMDRadeonX6000HWLibs` | `0xC273000` | `0x54A86C` |

**PROVEN:** HWServices e HWLibs sono eseguibili distinti.
**PROVEN:** X6000HWServices occupa `0xC26C000`–`0xC26E3CB`.
**PROVEN:** X6000HWLibs inizia a `0xC273000`.

---

## 3. X6000HWLibs

| Campo | Valore |
|---|---|
| `CFBundleIdentifier` | `com.apple.kext.AMDRadeonX6000HWLibs` |
| `CFBundleExecutable` | `AMDRadeonX6000HWLibs` |
| `CFBundleName` | `AMDRadeonX6000HWLibs` |
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWLibsX6000` |
| `IOMatchCategory` | `AMDRadeonHWLibs` |
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch.LoadPlugIn` | `Load6000` |
| `IOPersonalityPublisher` | `com.apple.kext.AMDRadeonX6000HWLibs` |

Dipendenze:

```text
com.apple.iokit.IOPCIFamily   2.9
com.apple.kpi.bsd             16.0
com.apple.kpi.iokit           16.0
com.apple.kpi.libkern         16.0
com.apple.kpi.mach            16.0
```

**PROVEN:** la personality è dichiarata nel plist.
**PROVEN:** il provider è la classe Interface.
**PROVEN:** il match category è `AMDRadeonHWLibs`.
**PROVEN:** il plugin è `AMDRadeonX6000_AMDRadeonHWLibsX6000`.

---

## 4. X6000HWServices

| Campo | Valore |
|---|---|
| `CFBundleIdentifier` | `com.apple.kext.AMDRadeonX6000HWServices` |
| `CFBundleName` | `AMDRadeonX6000HWServices` |
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWServicesNavi` |
| `IOMatchCategory` | `AMDRadeonX6000HWServices` |
| `IOProviderClass` | `IOPCIDevice` |
| `IOPCIMatch` | lista PCI Navi |

Dipendenze:

```text
com.apple.iokit.IOACPIFamily       1.4
com.apple.iokit.IOGraphicsFamily   2.4.1
com.apple.iokit.IOPCIFamily        2.9
com.apple.kpi.bsd                  15.0.0
com.apple.kpi.iokit                15.0.0
com.apple.kpi.libkern              15.0.0
com.apple.kpi.mach                 15.0.0
com.apple.kpi.unsupported          15.0.0
```

**PROVEN:** HWServices è il servizio PCI Navi.
**PROVEN:** Interface è la sua classe di interfaccia.
**UNPROVEN:** il runtime.

---

## 5. X5000HWLibs

| Campo | Valore |
|---|---|
| `CFBundleIdentifier` | `com.apple.kext.AMDRadeonX5000HWLibs` |
| `CFBundleExecutable` | `AMDRadeonX5000HWLibs` |
| `IOClass` | `AMDRadeonX5000_AMDRadeonHWLibsX5000` |
| `IOMatchCategory` | `AMDRadeonHWLibs` |
| `IOProviderClass` | `AMDRadeonX5000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch.LoadPlugIn` | `Load5000` |
| `IOPersonalityPublisher` | `com.apple.kext.AMDRadeonX5000HWLibs` |

Dipendenze:

```text
com.apple.iokit.IOPCIFamily   2.9
com.apple.kpi.bsd             16.0
com.apple.kpi.iokit           16.0
com.apple.kpi.libkern         16.0
com.apple.kpi.mach            16.0
```

**PROVEN:** schema identico a X6000.
**PROVEN:** cambiano solo prefisso e `LoadPlugIn`.
**UNPROVEN:** il runtime X5000.

---

## 6. Finder → +0xA8 → *0x20

```text
Finder 0xC26DC80
  -> provider *0x6A8
  -> child iterator *0x128
  -> getProperty "IOMatchCategory"
  -> compare "AMDRadeonHWLibs"
  -> return child
Abstract::start 0xC26DA21
  -> +0xA8 = child
  -> child *0x20
helper 0xC26D060
  -> child *0x6C0("AmdTtlInterfaceKey")
  -> +0xD0 = interface
```

| Test | Esito |
|---|---|
| Finder match | `AMDRadeonHWLibs` |
| Child provider | Interface |
| Child IOClass | `AMDRadeonX6000_AMDRadeonHWLibsX6000` |
| `+0xA8` | plugin |
| `*0x20` | avvio plugin |
| chiave | `AmdTtlInterfaceKey` |

**PROVEN:** il Finder restituisce il servizio HWLibs.
**PROVEN:** il servizio è agganciato a Interface.
**PROVEN:** la chiave restituisce Interface.
**UNPROVEN:** l’esito runtime.

---

## 7. Provider registrato o metadata?

| Ipotesi | Stato |
|---|---|
| `X6000HWLibs` solo identificatore | **REFUTED** |
| Personality registrata | **PROVEN** |
| IOClass dedicata | **PROVEN** |
| Provider Interface | **PROVEN** |
| Registrazione runtime | **UNPROVEN** |

**PROVEN:** X6000HWLibs è una personality completa, non un semplice nome.
**PROVEN:** il plist dichiara IOClass, provider, match category e LoadPlugIn.
**UNPROVEN:** la presenza effettiva in IORegistry.

---

## 8. Conferme indipendenti

| Fonte | Evidenza |
|---|---|
| XML X6000HWLibs | `IOProviderClass=Interface` |
| XML X6000HWLibs | `IOMatchCategory=AMDRadeonHWLibs` |
| XML X6000HWLibs | `LoadPlugIn=Load6000` |
| Finder | confronto `AMDRadeonHWLibs` |
| Helper | chiave `AmdTtlInterfaceKey` |
| X5000 | schema identico con `Load5000` |

**PROVEN:** tre riferimenti indipendenti convergono.
**UNPROVEN:** il runtime.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Plugin Finder | HWLibs |
| IOClass | `AMDRadeonX6000_AMDRadeonHWLibsX6000` |
| Provider | Interface |
| Match category | `AMDRadeonHWLibs` |
| LoadPlugIn | `Load6000` |
| X5000 | stesso schema, `Load5000` |
| Registrazione runtime | **UNPROVEN** |
| Pubblicazione | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il Finder restituisce il servizio **HWLibs** agganciato a Interface. La personality X6000HWLibs dichiara `IOClass=AMDRadeonX6000_AMDRadeonHWLibsX6000`, `IOMatchCategory=AMDRadeonHWLibs`, `IOProviderClass=AMDRadeonX6000_AMDRadeonHWServicesInterface` e `LoadPlugIn=Load6000`; X5000 è identico con `Load5000`. Quindi `X6000HWLibs` **non è solo un identificatore**: è una personality completa con IOClass e provider. Il link statico è **PROVEN**; la registrazione runtime, la pubblicazione IOService e il matching effettivo restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,2 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
