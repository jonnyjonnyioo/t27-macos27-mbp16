# T27 — AGENT-AMD — MATCH PROPERTY

**Scope:** verificare la coerenza tra personality X6000HWLibs e provider Interface, analizzare `Load6000`/`LoadPlugIn`, identificare il significato di `*0x20` e confrontare X5000 senza presumere equivalenza runtime.

**Modalità:** sola lettura; SystemKC XML, X6000HWServices, X5000HWServices, BootKC; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che `Load6000` è una proprietà di matching restituita da `Navi::getMatchProperty` (`0xC26CBE0`), non una funzione, e che `*0x20` sulla vtable HWLibsX6000 è `OSObject::release(int)`, non `start`. **UNPROVEN** il chiamante runtime di `getMatchProperty`. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| X6000HWServices | `2aa47ceee99969d3eba360fe558a3fbcd7e69c4bea2cd76704350a9bdfafe453` |
| X5000HWServices | `8a88fe7276968d3b124c9ff7ccf26d18b5e918fc339ab3681dfcb5a2cbd3cfbf` |
| Report 128 | `eb1a187664771f561235cc5d1505f926a9c51a1425a70795fc89bda63f65a32b` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Personality X6000HWLibs

| Campo | Valore |
|---|---|
| `CFBundleIdentifier` | `com.apple.kext.AMDRadeonX6000HWLibs` |
| `CFBundleExecutable` | `AMDRadeonX6000HWLibs` |
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWLibsX6000` |
| `IOMatchCategory` | `AMDRadeonHWLibs` |
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch.LoadPlugIn` | `Load6000` |
| `IOPersonalityPublisher` | `com.apple.kext.AMDRadeonX6000HWLibs` |

**PROVEN:** la personality è completa.
**PROVEN:** il provider è Interface.
**PROVEN:** il match richiede `LoadPlugIn=Load6000`.

---

## 3. OSMetaClass Interface

| Elemento | Indirizzo |
|---|---:|
| `gMetaClass` | `0xC270368` |
| oggetto `metaClass` | `0xC271828` |
| `superClass` | `0xC270370` |
| constructor | `0xC26D260` |
| MetaClassC2 | `0xC26D300` |
| nome | `0xC26E200` |
| size | `0x88` |

**PROVEN:** Interface ha un OSMetaClass registrato.
**PROVEN:** nome e size sono coerenti.
**UNPROVEN:** il runtime.

---

## 4. Load6000

| Offset | Contesto |
|---:|---|
| `0x6071A` | XML `IOPropertyMatch.LoadPlugIn` |
| `0xC26E120` | HWServices, stringa `"Load6000"` |
| `0xC26E18E` | HWServices, stringa `"Load6000Sim"` |

```text
0xC26CBE0  Navi::getMatchProperty()
0xC26CC02  leaq "Load6000"
0xC26CC1D  leaq "-amd_simnow"
0xC26CC45  leaq "Load6000Sim"
0xC26CCC8  return match property
```

| Test | Esito |
|---|---|
| `Load6000` funzione | **NO** |
| `Load6000` proprietà | **SÌ** |
| `Load6000Sim` | boot-arg `-amd_simnow` |
| Caller statico | **0** |
| Slot vtable | `0x878` |
| Entry vtable | `0xC26F8F0` = `0x4C26CBE0` |
| Target | `0xC26CBE0` |

**PROVEN:** `getMatchProperty` restituisce la stringa.
**PROVEN:** non esiste un call-site statico in HWServices.
**UNPROVEN:** il chiamante runtime.

---

## 5. *0x20

| Elemento | Valore |
|---|---|
| vtable HWLibsX6000 | `0xC7BE130` |
| slot `0x20` | `0xC7BE150` |
| raw | `0x91DF30` |
| livello | `0` |
| target | `0xFFFFFF8000A1DF30` |
| simbolo | `OSObject::release(int)` |

```text
0xC26DA42  movq 0xA8(%rax), %rdi
0xC26DA49  movq (%rdi), %rax
0xC26DA4C  callq *0x20(%rax)
```

**PROVEN:** `*0x20` è `OSObject::release(int)`.
**REFUTED:** `*0x20` è `start`.
**PROVEN:** il plugin viene rilasciato, non avviato.
**UNPROVEN:** il motivo del retain/release.

---

## 6. Coerenza del matching

```text
Navi::getMatchProperty
  -> "Load6000"
  -> proprietà LoadPlugIn del provider
X6000HWLibs personality
  -> IOPropertyMatch LoadPlugIn = Load6000
  -> IOProviderClass = Interface
Finder 0xC26DC80
  -> child IOMatchCategory = AMDRadeonHWLibs
  -> child = HWLibs
helper 0xC26D060
  -> child *0x6C0("AmdTtlInterfaceKey")
  -> Interface
```

| Test | Esito |
|---|---|
| Load6000 | proprietà |
| IOPropertyMatch | `Load6000` |
| IOProviderClass | Interface |
| Finder match | `AMDRadeonHWLibs` |
| Child | HWLibs |
| Chiave | `AmdTtlInterfaceKey` |

**PROVEN:** la catena statica è coerente.
**UNPROVEN:** l’ordine runtime.

---

## 7. X5000

| Campo | X5000 |
|---|---|
| `CFBundleIdentifier` | `com.apple.kext.AMDRadeonX5000HWLibs` |
| `CFBundleExecutable` | `AMDRadeonX5000HWLibs` |
| `IOClass` | `AMDRadeonX5000_AMDRadeonHWLibsX5000` |
| `IOMatchCategory` | `AMDRadeonHWLibs` |
| `IOProviderClass` | `AMDRadeonX5000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch.LoadPlugIn` | `Load5000` |
| `Load5000` string | `0x457D1AA` |
| `Abstract::start` | `0x457C970` |
| `findPlugIn` | `0x457CD30` |

**PROVEN:** schema statico identico.
**UNPROVEN:** equivalenza runtime.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| `Load6000` | proprietà di matching |
| Funzione `Load6000` | **NO** |
| `getMatchProperty` | `0xC26CBE0` |
| Caller statico | **NO** |
| Slot | `0x878` |
| `*0x20` | `OSObject::release(int)` |
| Plugin avviato da `*0x20` | **NO** |
| Link statico | **PROVEN** |
| Runtime | **UNPROVEN** |
| Pubblicazione | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `Load6000` **non è una funzione**: è la stringa restituita da `Navi::getMatchProperty` (`0xC26CBE0`) e usata come proprietà `LoadPlugIn` nella personality X6000HWLibs (`IOPropertyMatch LoadPlugIn=Load6000`). Non esiste un call-site statico di `getMatchProperty`; è nello slot vtable `0x878` (`0xC26F8F0`) e il chiamante è esterno, **UNPROVEN**. La chiamata `*0x20` sul plugin HWLibsX6000 non è `start`: la vtable `0xC7BE130` allo slot `0x20` punta a `OSObject::release(int)` (`0xA1DF30`), quindi il plugin viene rilasciato, non avviato. La catena statica `getMatchProperty → Load6000 → IOPropertyMatch → Interface → Finder → HWLibs → AmdTtlInterfaceKey` è coerente; l’ordine runtime, la registrazione e la pubblicazione restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,2 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
