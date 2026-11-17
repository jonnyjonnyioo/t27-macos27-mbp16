# T27 — AGENT-AMD — CHAIN BLOCKER / HWSERVICES PCI (161)

**Scope:** ricostruire la catena PCI → `AMDRadeonX6000_AMDRadeonHWServicesInterface` → matching X6100 → `Load6100` → `findPlugIn` → istanziazione della classe; distinguere passaggi dimostrati nei binari da quelli solo documentati; individuare il primo punto non dimostrabile e la prova statica necessaria.

**Modalità:** sola lettura. Nessun boot, trace, modifica, build o download. Comandi: `grep`, `plutil`, `find`, `nm`, `otool`, `strings`, `shasum`.

**Diagnosi prioritaria:** il blocco concreto non è nella personality X6100. È il **gate PCI/HWServices**: la personality HWServices richiede `IOPropertyMatch LoadHWServices=true` sul `IOPCIDevice`, ma nessun codice di HWServices pubblica quella proprietà e non esiste una prova statica che il device target la riceva. Se manca, HWServices non viene istanziato, `Load6100` non viene pubblicato e X6100 non può essere matchato. Questo è il primo passaggio **UNPROVEN**. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| HWServices `Info.plist` | `c6dcc67430bbbff1490e7101d395b3dbcfe248c10adc889efd59dd1689810bf0` |
| X6100HWLibs `Info.plist` | `414fa880bf31cfbdd5a0007825961c6cc9e231afba5210e563507b510deb86a1` |
| X6000HWServices executable | `cc7aaca45446f98cc4ea03b1fdf80b402975c1b0e0d07585a304d78dcdf797f7` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 159 | `fb74c4436131dccc1292b92062c1dd2672b94fabff1caa3b346df258013088a1` |

**Ambiente:** macOS `26.7.3`, build `25G342`.
**Spazio:** **15.421.620 KiB ≈ 14,71 GiB** > 10 GiB.

---

## 2. Catena completa

| # | Passaggio | Evidenza | Stato |
|---:|---|---|---|
| 1 | GPU compare come `IOPCIDevice` | documentazione hardware; nessun `ioreg` target | **UNPROVEN runtime** |
| 2 | `IOPCIDevice` ha `LoadHWServices=true` | HWServices plist lo richiede; produttore non dimostrato | **UNPROVEN** |
| 3 | HWServices matcha PCI | `IOPCIMatch` include `0x73401002`; `IOProbeScore=65051` | **PROVEN metadati** |
| 4 | HWServices diventa provider attivo | classe in SystemKC; `Abstract::start` | **PROVEN statico; runtime UNPROVEN** |
| 5 | HWServices pubblica `Load6100` per `ATY,Boa` | `getMatchProperty 0xc26cbe0` → `setProperty 0xc26d9d7` | **PROVEN statico** |
| 6 | `registerService(2)` avvia matching | `0xc26da0d` → `IOService::registerService 0xA94C60` | **PROVEN call-site** |
| 7 | X6100 supera `IOProviderClass` | Navi è sottoclasse di Interface | **PROVEN statico** |
| 8 | X6100 supera `IOPropertyMatch.LoadPlugIn` | X6100 `Load6100`; target `Load6100` | **PROVEN statico** |
| 9 | X6100 supera categoria | `IOMatchCategory=AMDRadeonHWLibs` | **PROVEN** |
| 10 | `findPlugIn` trova il child | `0xc26dc80`; solo categoria | **PROVEN codice; runtime UNPROVEN** |
| 11 | classe X6100 istanziata | `IOClass`; 78 simboli SystemKC | **PROVEN statico; runtime UNPROVEN** |
| 12 | X6100 operativo | attach/start e TTL | **UNPROVEN runtime** |

**PROVEN:** la catena X6100 è internamente coerente dal passaggio 7 al 11.
**PROVEN:** il primo anello non dimostrato è il passaggio 2 (proprietà PCI `LoadHWServices`).
**UNPROVEN:** il passaggio 1 (presenza PCI target) e il passaggio 4 (start HWServices).

---

## 3. HWServices: plist e codice

### 3.1 Personality

`AMDRadeonX6000HWServices.kext/Contents/Info.plist`:

| Campo | Valore |
|---|---|
| `CFBundleIdentifier` | `com.apple.kext.AMDRadeonX6000HWServices` |
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWServicesNavi` |
| `IOProviderClass` | `IOPCIDevice` |
| `IOPCIMatch` | include `0x73401002` (target Navi 14) |
| `IOPropertyMatch` | `{ LoadHWServices = true }` |
| `IOMatchCategory` | `AMDRadeonX6000HWServices` |
| `IOProbeScore` | `65051` |
| `IOPCITunnelCompatible` | `true` |
| `OSBundleLibraries` | IOACPIFamily, IOGraphicsFamily, IOPCIFamily, KPI |

**PROVEN:** HWServices richiede esplicitamente `LoadHWServices=true`.
**PROVEN:** `IOPCIMatch` contiene il device ID `0x73401002`, compatibile con Navi 14.
**PROVEN:** `IOPCITunnelCompatible=true` è solo un flag di matching, non una condizione di caricamento.
**UNPROVEN:** che il device target pubblichi `LoadHWServices=true`.

### 3.2 Codice HWServices

`AMDRadeonX6000_AMDRadeonHWServicesAbstract::start` a `0xc26d8c0`:

| Indirizzo | Azione |
|---:|---|
| `0xc26d9b3` | `getMatchProperty()` |
| `0xc26d9d7` | `setProperty("LoadPlugIn", value)` |
| `0xc26da0d` | `registerService(2)` |
| `0xc26da21` | `findPlugIn()` |

**PROVEN:** HWServices non pubblica `LoadHWServices`; pubblica `LoadPlugIn`.
**PROVEN:** `LoadHWServices` non compare nel binario HWServices.
**PROVEN:** il valore `Load6100` è calcolato da `getMatchProperty` per `ATY,Boa` e scritto prima di `registerService(2)`.

### 3.3 Chi pubblica `LoadHWServices`

| Immagine | Occorrenze | Stato |
|---|---:|---|
| SystemKC | 5 | 3 XML + 2 stringhe Wrangler |
| BootKC | 0 | assente |
| X6000HWServices | 0 | assente |
| AMDSupport | stringa presente | produttore **UNPROVEN** |
| X6000Framebuffer | stringa presente | produttore **UNPROVEN** |

**PROVEN:** `LoadHWServices` compare in AMDSupport e X6000Framebuffer come stringa.
**UNPROVEN:** il xref che porta da quella stringa a un `setProperty` sul `IOPCIDevice`.
**UNPROVEN:** che il percorso venga eseguito sul target.

---

## 4. Classi e registrazione IOKit

### 4.1 HWServices e X6100 nella stessa collezione

| Classe | SystemKC | BootKC |
|---|---:|---:|
| `AMDRadeonX6000_AMDRadeonHWServices*` | **100 simboli** | **0** |
| `AMDRadeonX6100_AMDRadeonHWLibs*` | **78 simboli** | **0** |

**PROVEN:** HWServices e X6100 sono entrambi in SystemKC.
**PROVEN:** nessuno dei due è in BootKC.
**INFERRED:** non c’è un gap BootKC/SystemKC tra le due classi; entrambe appartengono alla stessa kernel collection.
**UNPROVEN:** l’ordine di registrazione delle OSMetaClass all’interno di SystemKC.

### 4.2 X6100

| Elemento | Valore |
|---|---|
| `MetaClassC1` | `0xdd6e980` |
| ctor C2 | `0xdd6e9d0` |
| `MetaClassC2` | `0xdd6eb10` |
| `MetaClass::alloc` | `0xdd6eb60` |
| vtable | `0xe11c130` |
| `gMetaClass` | `0xed11a10` |
| base `probe` | `0xdd6f0b0` |
| base `attach` | `0xdd6f120` |
| base `start` | `0xdd6f320` |

**PROVEN:** la classe concreta e la base sono in SystemKC.
**PROVEN:** la classe ha i metodi IOService necessari.
**UNPROVEN:** che l’OSMetaClass sia registrata prima del match X6100.

### 4.3 HWServices

| Elemento | Valore |
|---|---|
| `Navi` ctor | `0xc26c980` |
| `Navi` `getMatchProperty` | `0xc26cbe0` |
| `Abstract::start` | `0xc26d8c0` |
| `findPlugIn` | `0xc26dc80` |
| `HWLIB_PLUG_IN_MATCH_CATEGORY` | `0xc26e3b0` |

**PROVEN:** HWServices contiene la catena Navi → Abstract → `findPlugIn`.
**UNPROVEN:** che l’oggetto Navi venga creato e avviato sul target.

---

## 5. Proprietà e dipendenze: cosa non è un blocco

| Condizione | Valore | Esito |
|---|---|---|
| `IOPCITunnelCompatible` | `true` | **non blocca** |
| `IOProbeScore` HWServices | `65051` | **non blocca** |
| `IOProbeScore` X6100 | assente → default 0 | **non blocca** (un solo match target) |
| `OSBundleRequired` X6100 | assente | **non blocca** |
| `IOResourceMatch` X6100 | assente | **non blocca** |
| `OSBundleLibraries` X6100 | IOPCIFamily 2.9, KPI ≥16 | **soddisfatte** |
| `IOMatchCategory` condivisa | 16 personalità | **non blocca** con un solo match |
| `findPlugIn` solo categoria | `0xc26dc80` | **non blocca** se esiste un solo child |

**PROVEN:** nessuna di queste condizioni spiega da sola un blocco di X6100.
**PROVEN:** X6100 non ha una dipendenza circolare da HWServices.
**PROVEN:** `Load6100` è una proprietà, non una chiamata.

---

## 6. Primo punto non dimostrabile

### 6.1 Catena causale del blocco

```text
IOPCIDevice
  └─ deve avere LoadHWServices=true
       └─ HWServices personality match
            └─ HWServices start
                 └─ setProperty("LoadPlugIn","Load6100")
                      └─ registerService(2)
                           └─ X6100 match
                                └─ X6100 attach/start
                                     └─ findPlugIn
                                          └─ TTL
```

**Se `LoadHWServices` manca:** HWServices non viene istanziato; `Load6100` non esiste; X6100 non entra mai nel matching. Il fallimento è a monte e non produce il log `"Could not find HW Lib Plug In."`, perché `Abstract::start` non viene eseguito.

**Se `LoadHWServices` c’è:** la catena statica HWServices → X6100 è completa; restano solo runtime/attach e ordine di registrazione.

### 6.2 Perché è il primo

| Anello | Dipende da | Stato |
|---|---|---|
| PCI device presente | hardware/ACPI | **UNPROVEN runtime** |
| `LoadHWServices=true` | AMDSupport/Framebuffer | **UNPROVEN** |
| HWServices match | property + ID PCI | **PROVEN metadati; runtime UNPROVEN** |
| HWServices start | IOService matching | **PROVEN statico; runtime UNPROVEN** |
| X6100 match | Load6100 + classe | **PROVEN statico** |

**PROVEN:** `LoadHWServices` è la prima condizione **non pubblicata da HWServices** e non dimostrata da un xref.
**UNPROVEN:** la sua presenza sul target.
**NON DIMOSTRATO:** che AMDSupport/Framebuffer la impostino su Navi 14 in macOS 26.7.3.

### 6.3 Prova statica necessaria

Per chiudere il punto senza boot/trace:

1. trovare in AMDSupport o X6000Framebuffer il xref della stringa `LoadHWServices`;
2. risalire alla funzione che chiama `setProperty("LoadHWServices", true)` o `vendor_doDeviceAttribute`;
3. verificare che il caller sia raggiungibile dal percorso Navi 14 / `ATY,Boa`;
4. verificare che l’oggetto sia il `IOPCIDevice` del target, non un'altra classe;
5. in alternativa, un dump `ioreg` archiviato che mostri la proprietà sul device.

**PROVEN:** senza uno di questi elementi la presenza della proprietà resta **UNPROVEN**.
**UNPROVEN:** il xref e il caller target.
**UNPROVEN:** la presenza della proprietà nel sistema live.

---

## 7. Diagnosi prioritaria

| Priorità | Condizione | Impatto | Stato |
|---:|---|---|---|
| **1** | `LoadHWServices=true` sul `IOPCIDevice` | se assente, HWServices non parte | **UNPROVEN** |
| 2 | HWServices `start`/`registerService(2)` runtime | se non eseguito, `Load6100` non pubblicato | **UNPROVEN** |
| 3 | registrazione OSMetaClass X6100 prima del match | se assente, `IOClass` non istanziabile | **UNPROVEN** |
| 4 | attach/start X6100 e `findPlugIn` | se assente, TTL non creato | **UNPROVEN** |
| 5 | collisione categoria | non decisiva con un solo match | **NON PUÒ** |

**Diagnosi:** il blocco più concreto e più a monte è **HWServices non istanziato per assenza di `LoadHWServices=true`**, non un difetto di X6100. La personality X6100, la classe, le dipendenze, `Load6100` e `findPlugIn` sono coerenti; il punto che può impedire l’intera catena è la proprietà PCI che abilita HWServices.

**Alternativa:** se `LoadHWServices` è presente, il primo punto non dimostrabile diventa l’esecuzione runtime di `HWServices::start`/`registerService(2)`; la prova statica non basta più e serve un trace o un `ioreg`, non disponibili in T27.

---

## 8. Verdetto

| Domanda | Risposta |
|---|---|
| Catena PCI → HWServices → X6100 ricostruita | **SÌ** |
| X6100 ha proprietà/dipendenze coerenti | **SÌ — PROVEN** |
| Classe X6100 in SystemKC | **SÌ — PROVEN** |
| HWServices in SystemKC | **SÌ — 100 simboli** |
| `Load6100` pubblicato per `ATY,Boa` | **PROVEN statico** |
| Primo punto non dimostrato | **`LoadHWServices=true` sul PCI target** |
| Prova statica necessaria | **xref AMDSupport/Framebuffer → setProperty** |
| Attach runtime X6100 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la catena X6100 è staticamente completa dal provider Interface fino a `findPlugIn`, ma il suo innesco dipende da HWServices. HWServices richiede `IOPropertyMatch LoadHWServices=true` sul `IOPCIDevice`; la proprietà non è pubblicata da HWServices e non esiste una prova statica che AMDSupport/Framebuffer la impostino sul target. Questo è il **primo punto non dimostrabile** e il candidato prioritario al blocco. La prova necessaria è un xref completo dalla stringa `LoadHWServices` a un `setProperty` sul device Navi 14, oppure un `ioreg` archiviato; senza, resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **15.421.620 KiB ≈ 14,71 GiB** > 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
