# T27 — AGENT-AMD — PROVIDER CHAIN

**Scope:** verificare se esiste un percorso alternativo X6000HWServices → AMDSupport → X5400 sulla Radeon Pro 5300M (`0x7340`); ricostruire classi pubblicate, superclassi e riferimenti a `AMDRadeonX5000_AMDRadeonHWServicesInterface`, `Load5400` e `0x7340`; separare matching statico, provider disponibile e runtime.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, symbol table, disassemblaggio, plist `PRELINK_INFO`, `system_profiler`; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che X6000HWServices pubblica `AMDRadeonX6000_AMDRadeonHWServicesInterface` e `AMDRadeonX6000_AMDRadeonHWServicesNavi`, che la personalità Navi matcha `0x73401002` e che X5400 richiede `AMDRadeonX5000_AMDRadeonHWServicesInterface`. **REFUTED** che il letterale X5000 compaia nel binario X6000HWServices e che `Load5400` sia pubblicato da X6000. **UNPROVEN** l’ereditarietà X6000 → X5000 e il caricamento di X5400. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 92 | `771347abf31cb0e6f333861efc6569135059e1f91cc8ceb606e47f288c40a1b2` |
| Report 93 | `516daa4e342f8cb04c4574950889a6c06d67100bbb1dda7e6dcd5a97e27da1a2` |
| Report 94 | `63609ac2c9362b7f982b1904666424e1562f5fbe98157ace608ed2c24a899086` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Fileset entry

| Kext | vmaddr | fileoff | Dimensione |
|---|---:|---:|---:|
| `AMDRadeonX5000HWServices` | `0x457B000` | `72855552` | `28672` |
| `AMDRadeonX5400HWLibs` | `0x8A90000` | `145293312` | — |
| `AMDRadeonX6000HWServices` | `0xC26C000` | `203866112` | `28672` |

**PROVEN:** le tre entry sono `LC_FILESET_ENTRY` del SystemKC.
**PROVEN:** X6000HWServices è un kext separato.

---

## 3. Classi X6000HWServices

| Simbolo | VA | Ruolo |
|---|---:|---|
| `AMDRadeonX6000_AMDRadeonHWServicesInterface` | `0xC26D210` | meta-classe |
| `AMDRadeonX6000_AMDRadeonHWServicesNavi` | `0xC26C930` | meta-classe |
| `...Interface10superClassE` | `0xC270370` | superclasse |
| `...Navi10superClassE` | `0xC26F070` | superclasse |

**PROVEN:** il binario contiene entrambe le classi.
**PROVEN:** la classe Navi è distinta dall’interfaccia.

---

## 4. Costruttore dell’interfaccia X6000

```text
0xc26d314: leaq 0xee5(%rip), %rsi   ; "AMDRadeonX6000_AMDRadeonHWServicesInterface"
0xc26d31b: movq 0x1cf6(%rip), %rdx  ; superclasse
0xc26d327: callq 0x10066
```

| Elemento | Esito |
|---|---|
| Nome classe | **X6000 Interface** |
| Superclasse | **caricata da slot relocated** |
| Valore slot `0xC26F018` | `0x400000012AA488` (fixup) |
| Target risolto | **non disponibile** |
| Riferimento letterale X5000 | **assente nel binario** |

**PROVEN:** il costruttore registra il nome X6000.
**PROVEN:** la superclasse è un puntatore relocated.
**UNPROVEN:** che la superclasse sia l’interfaccia X5000.

---

## 5. Riferimenti

| Stringa | Occorrenze SystemKC | Dove |
|---|---:|---|
| `AMDRadeonX5000_AMDRadeonHWServicesInterface` | **5** | solo `PRELINK_INFO` XML |
| `AMDRadeonX6000_AMDRadeonHWServicesNavi` | **1** | personalità X6000 |
| `Load5400` | **1** | solo personalità X5400 |
| `0x73401002` | **3** | personalità X6000 |

**PROVEN:** `Load5400` non è pubblicato da X6000.
**PROVEN:** `0x73401002` è nelle personalità X6000.
**PROVEN:** il letterale X5000 non è nel binario X6000.

---

## 6. Personalità

| Kext | `IOClass` | Match | Esito |
|---|---|---|---|
| X5000HWServices | `AMDRadeonX5000_AMDRadeonHWServicesVega` | ID Vega | **non matcha `0x7340`** |
| X6000HWServices | `AMDRadeonX6000_AMDRadeonHWServicesNavi` | include `0x73401002` | **matcha la GPU** |
| X5400 | `AMDRadeonX5400_AMDRadeonHWLibsX5400` | provider X5000; `Load5400` | **provider non dimostrato** |
| AMDSupport | `AMDSupport` | `0x1002` / classe display | **match statico** |

**PROVEN:** X6000HWServices è il provider Navi per `0x7340`.
**UNPROVEN:** che X6000 pubblichi anche l’interfaccia X5000 richiesta da X5400.

---

## 7. Catena

```text
GPU 0x7340
  -> X6000HWServices (match Navi)
     -> classe Navi X6000
        -> interfaccia X6000
           -> X5400 richiede interfaccia X5000
              -> ereditarietà non dimostrata
```

| Passo | Esito |
|---|---|
| GPU → X6000HWServices | **PROVEN statico** |
| X6000HWServices → interfaccia X6000 | **PROVEN** |
| interfaccia X6000 → interfaccia X5000 | **UNPROVEN** |
| X5400 → provider X5000 | **UNPROVEN** |
| AMDSupport → GPU | **PROVEN statico** |
| X5400 caricato | **UNPROVEN** |

**PROVEN:** la catena Navi arriva a X6000.
**UNPROVEN:** il passaggio a X5400.

---

## 8. Runtime

| Evidenza | Esito |
|---|---|
| Boot log | **assente** |
| Trace IOKit | **assente** |
| `ioreg` X5400 | **assente** |
| Trace `loadExecutable` | **assente** |

**PROVEN:** non ci sono log o trace preesistenti.
**UNPROVEN:** il caricamento runtime.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| X6000HWServices matcha `0x7340` | **SÌ** |
| X5000HWServices matcha `0x7340` | **NO** |
| X6000 pubblica interfaccia X6000 | **SÌ** |
| X6000 pubblica interfaccia X5000 | **NON DIMOSTRATO** |
| X5400 richiede interfaccia X5000 | **SÌ** |
| `Load5400` pubblicato da X6000 | **NO** |
| AMDSupport matcha la GPU | **SÌ, statico** |
| X5400 caricato | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** X6000HWServices è il provider Navi che matcha la Radeon Pro 5300M `0x7340` e pubblica l’interfaccia X6000. X5400 richiede invece l’interfaccia X5000 e `Load5400`, che non risulta pubblicato da X6000. Il letterale X5000 non compare nel binario X6000 e la superclasse dell’interfaccia X6000 è un puntatore relocated non risolto: l’ereditarietà X6000 → X5000 resta **UNPROVEN**. AMDSupport ha un match statico con la GPU, ma il caricamento di X5400 resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
