# T27 — AGENT-AMD — METAL USERSPACE

**Scope:** ricerca read-only di uno stack AMD Metal userspace per Navi14 nei materiali già acquisiti: root2, root3, root25, KDK 26B131, `HAO-PROJECT/Artifacts`, root-full HAO-71 e recovery HAO-68.  
**Modalità:** nessuna compilazione, installazione, firma, `kextload`, boot o download.  
**Esito:** il binario Metal **esiste**, ma non è 26B131 e non è uno stack installabile: `AMDRadeonX6000MTLDriver` è stato recuperato dalla dyld shared cache del sistema **25G342**; l’SDK di compilazione è **25G325**. È x86_64h, `minos 26.7`, non firmato e privo del bundle eseguibile sul disco. La distinzione 25G342/25G325 è risolta in `PROVENANCE-REPORT.md`.

---

## 1. Inventario

| Radice | `AMDRadeonX6000MTLDriver` | Esito |
|---|---|---|
| root2 25G325 | assente | nessun bundle MTL |
| root3 25G342/26B116 | assente | nessun bundle MTL |
| root25 25G342 | bundle presente, **eseguibile assente** | `Contents/MacOS/...` non esiste; 9 file, 19 MB di risorse |
| root-full HAO-71 | bundle presente, **eseguibile assente** | `NO_MACHO` |
| KDK 26B131 | assente | 0 bundle AMD |
| target 26B131 | assente | 0 bundle AMD |
| `HAO-PROJECT/Artifacts` | assente | solo T6/BootKernelExtensions |
| HAO-68 `work/mtl-driver` | **binario presente** | estratto dalla dyld shared cache |
| HAO-68 / HAO-69 EFI `Payloads` | **binario presente** | copia dello stesso SHA; non caricata da OpenCore |

Nessun `AMDMetal` o `MTLDriver` 26B131 è stato trovato. `AMDRadeonX6000GLDriver` è presente, ma è **OpenGL**, non Metal.

---

## 2. Binario Metal recuperato

| Proprietà | Valore |
|---|---|
| Percorso di prova | `HAO-PROJECT/Sessions/<SESSION>/work/mtl-driver/AMDRadeonX6000MTLDriver` |
| Dimensione | **7.716.152 byte** |
| Tipo | Mach-O 64-bit dynamically linked shared library |
| Architettura | **x86_64h** |
| SHA-256 | `f4c8ef463b57792e7a982c4a4eb1b0d1c81098e1c4ee186c2ef13935c4bb9ff0` |
| UUID | `F89F483D-39AC-368D-B9D9-FB689179EFD2` |
| `LC_BUILD_VERSION` | macOS, **minos 26.7**, sdk **26.7.2** |
| Firma | **non firmato** (`code object is not signed at all`) |
| Install name | `/System/Library/Extensions/AMDRadeonX6000MTLDriver.bundle/Contents/MacOS/AMDRadeonX6000MTLDriver` |

Il bundle root25 dichiara `CFBundleIdentifier=com.apple.AMDRadeonX6000MTLDriver`, `CFBundleVersion=7.0.1`, `CFBundleShortVersionString=7.1.8`, `LSMinimumSystemVersion=26.7`. Il binario recuperato è quello atteso dal bundle, ma è stato estratto dalla cache e non è più firmato.

### Dipendenze dichiarate

```text
MetalPerformanceShaders, IOAccelerator, IOSurface, IOAccelMemoryInfo,
Foundation, Metal, IOKit, libobjc.A.dylib, libc++.1.dylib,
libSystem.B.dylib, CoreFoundation
```

Sono dipendenze Apple x86_64h; **non dimostrano** che le versioni presenti in 26B131 siano compatibili. `Metal.framework` e le altre dipendenze non sono presenti nel campione root25 ai path attesi.

---

## 3. GL e bundle incompleti

| Componente | Stato | Evidenza |
|---|---|---|
| `AMDRadeonX6000GLDriver.bundle` | **AVAILABLE (OpenGL)** | x86_64h, `minos 26.7`, SHA `297665dfb1c3df5593807953041c00fe64328989f5a0b0cb64a3c903695b1f67`; non è Metal |
| `AMDRadeonX6000MTLDriver.bundle` | **INCOMPLETE** | solo `Info.plist`, `PkgInfo`, `version.plist`, `_CodeSignature` e risorse GFX10; nessun Mach-O |
| `AMDRadeonX6000Shared.bundle` | **INCOMPLETE** | solo bitcode/`runtime.amdil` e metadata; nessun Mach-O |
| `AMDRadeonVADriver` / `VADriver2` | **INCOMPLETE** | nessun Mach-O |
| `AMDMTLBronzeDriver` | **INCOMPLETE** | nessun Mach-O |
| 26B131 AMD MTL | **ABSENT** | nessun bundle/binario nel target o KDK |

---

## 4. Classificazione

| Classe | Significato | Risultato |
|---|---|---|
| `AVAILABLE` | binario Mach-O utilizzabile come prova | **1**: MTL x86_64h estratto; **non** è uno stack completo |
| `INCOMPLETE` | bundle/risorse presenti ma eseguibile o metadata mancanti | MTL bundle root25/HAO-71, Shared, VA, MTLBronze |
| `INCOMPATIBLE` | build/versione non allineata a 26B131 | MTL 25G-series/26.7 e GL 25G342/26.7 |
| `ABSENT` | non presente nei materiali | MTL 26B131, KDK 26B131, `AMDMetal` |

**Il binario è `AVAILABLE`, ma lo stack NON è `AVAILABLE`.** Un file Mach-O estratto dalla cache non è un bundle firmato, non è installabile sul volume sigillato e non è stato compilato per 27.2.1.

---

## 5. Perché G resta BLOCKED

1. **Build:** `minos 26.7` / SDK `26.7.2`, non 27.2.1/26B131; product build **25G342**, SDK build **25G325** (campi diversi, non contraddizione).
2. **Bundle:** root25 e HAO-71 non hanno `Contents/MacOS/AMDRadeonX6000MTLDriver`; il binario è separato in `work/mtl-driver`.
3. **Firma:** il binario recuperato non è firmato; reintegrarlo cambia il CDHash e richiede la rottura del sigillo.
4. **Dipendenze:** Metal.framework, MPS, IOAccelerator e IOAccelMemoryInfo non sono verificati nel target 26B131.
5. **Caricamento:** `Metal.framework` cerca il driver nel bundle di sistema; OpenCore non carica dylib userspace.
6. **Runtime:** nessun test Metal, WindowServer, eDP/gMux o GPU.

**E — display interno:** resta **BLOCKED**.  
**G — WindowServer:** resta **BLOCKED**, ma il blocco corretto è **“driver 25G-series recuperato, incompatibile/incompleto per 26B131”**, non “driver assente”.  
**H — desktop:** resta **BLOCKED**.

---

## 6. Provenienza

La recovery è documentata in `HAO-PROJECT/Sessions/<SESSION>/deliverables/METAL-USERSPACE-RECOVERY.md`: estrazione con `ipsw dyld extract` dalla `dyld_shared_cache_x86_64h`; il file è conservato in `work/mtl-driver/` e copiato nei payload EFI senza essere caricato. HAO-68 dichiara **25G342**; il bundle root25 dichiara `DTSDKBuild 25G325`. La verifica di `SystemVersion.plist` conferma **ProductBuildVersion 25G342** e SDK build **25G325**: non è una contraddizione, sono campi diversi. Certamente non 26B131.

**STOP rispettato:** nessuna compilazione, installazione, firma, `kextload`, boot o download; spazio libero 12.920.044 KiB (12,32 GiB), sopra 10 GiB. Nessuna modifica a T16–T26.
