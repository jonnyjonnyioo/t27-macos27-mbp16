# T27 — AGENT-AMD — RUNTIME CLOSURE / METAL NAVI14

**Scope:** chiusura delle dipendenze del binario `AMDRadeonX6000MTLDriver` recuperato in HAO-68; confronto con root2, root3, root25 e target 26B131.  
**Modalità:** read-only; nessuna estrazione, compilazione, firma, installazione, `kextload` o boot.  
**Esito:** **closure FALLITA**. Il binario MTL è presente, ma tutte le 11 dipendenze dichiarate mancano nei sample root2/root3/root25/target ai path attesi; inoltre `AMDRadeonX6000Shared` non ha un Mach-O. G resta **BLOCKED**.

---

## 1. Identità del driver

| Proprietà | Valore |
|---|---|
| Percorso | `HAO-PROJECT/Sessions/<SESSION>/work/mtl-driver/AMDRadeonX6000MTLDriver` |
| Dimensione | 7.716.152 byte |
| Tipo | Mach-O 64-bit dynamically linked shared library |
| Architettura | **x86_64h** |
| SHA-256 | `f4c8ef463b57792e7a982c4a4eb1b0d1c81098e1c4ee186c2ef13935c4bb9ff0` |
| UUID | `F89F483D-39AC-368D-B9D9-FB689179EFD2` |
| `LC_BUILD_VERSION` | platform macOS, **minos 26.7**, sdk 26.7.2 |
| `NSPrincipalClass` | `GFX10_MtlDevice` |
| `CFBundleIdentifier` | `com.apple.AMDRadeonX6000MTLDriver` |
| Bundle version | 7.0.1 / 7.1.8 |
| Firma | **non firmato** |

### 1.1 Build: 25G342 / 25G325 risolti

`SystemVersion.plist` di root25 e HAO-71 riporta **ProductBuildVersion 25G342** (macOS 26.7.3). Il `Info.plist` del bundle MTL riporta:

```text
DTSDKBuild      = 25G325
DTPlatformVersion = 26.7.2
LSMinimumSystemVersion = 26.7
```

`DTSDKBuild` è la build dell’**SDK**, non la product build. Quindi **25G342 = sistema sorgente**, **25G325 = SDK di compilazione**: non è una contraddizione. Il driver resta un artefatto 25G-series, non 26B131/27.2.1. Dettaglio in `PROVENANCE-REPORT.md`.

---

## 2. `otool -L` — dipendenze dichiarate

| # | Dipendenza | Versione richiesta | Tipo |
|---:|---|---|---|
| 1 | `MetalPerformanceShaders.framework` | 129.5.1 | framework |
| 2 | `IOAccelerator.framework` | 1.0.0 | private framework |
| 3 | `IOSurface.framework` | 1.0.0 | framework |
| 4 | `IOAccelMemoryInfo.framework` | 1.0.0 | private framework |
| 5 | `Foundation.framework` | 5026.6.7 | framework |
| 6 | `Metal.framework` | 373.7.1 | framework |
| 7 | `IOKit.framework` | 275.0.0 | framework |
| 8 | `libobjc.A.dylib` | 228.0.0 | dylib |
| 9 | `libc++.1.dylib` | 2100.43.0 | dylib |
| 10 | `libSystem.B.dylib` | 1356.0.0 | dylib |
| 11 | `CoreFoundation.framework` | 5026.6.7 | framework |

`nm -u` riporta **663 simboli non definiti**. La presenza di 663 undefined non è di per sé un errore: è normale per un driver; la chiusura dipende dai framework sopra. Senza di essi non c’è prova di risoluzione ABI.

---

## 3. Matrice disponibilità

Verifica dei path esatti, non della presenza nominale delle directory.

| Dipendenza | Root2 | Root3 | Root25 | Target 26B131 | Build match | Status |
|---|---|---|---|---|---|---|
| Metal | ASSENTE | ASSENTE | ASSENTE | ASSENTE | **NO** | MISSING |
| MetalPerformanceShaders | ASSENTE | ASSENTE | ASSENTE | ASSENTE | **NO** | MISSING |
| IOAccelerator | ASSENTE | ASSENTE | ASSENTE | ASSENTE | **NO** | MISSING |
| IOSurface | ASSENTE | ASSENTE | ASSENTE | ASSENTE | **NO** | MISSING |
| IOAccelMemoryInfo | ASSENTE | ASSENTE | ASSENTE | ASSENTE | **NO** | MISSING |
| Foundation | ASSENTE | ASSENTE | ASSENTE | ASSENTE | **NO** | MISSING |
| IOKit | ASSENTE | ASSENTE | ASSENTE | ASSENTE | **NO** | MISSING |
| libobjc | ASSENTE | ASSENTE | ASSENTE | ASSENTE | **NO** | MISSING |
| libc++ | ASSENTE | ASSENTE | ASSENTE | ASSENTE | **NO** | MISSING |
| libSystem | ASSENTE | ASSENTE | ASSENTE | ASSENTE | **NO** | MISSING |
| CoreFoundation | ASSENTE | ASSENTE | ASSENTE | ASSENTE | **NO** | MISSING |

**AVAILABLE = 0/11.** I sample root2/root3/root25 non sono root completi; il target è un catalogo con directory framework ma senza i binari correnti. La matrice dice “non disponibile in questi materiali”, non “assente da ogni macOS”.

**BUILD MATCH = 0/11.** Il driver richiede API dichiarate a 26.7; il target è 27.2.1/26B131. Non esiste un test ABI.

---

## 4. Plugin e registrazione GPU

### 4.1 Risorse plugin presenti

Nel bundle root25:

- `Contents/Resources/MPSPlugin_GFX10.dict` — Apple binary plist, kernel/plugin data;
- `Contents/Resources/TensileKernels_GFX10.plist` — kernel Tensile GFX10;
- `Contents/Resources/GFX10Statistics-*.plist/js`.

Stringhe del driver MTL:

```text
amd_mtl_gfx10_acceleration_structure_cmd_encoder.m
amd_mtl_gfx10_library.m
AMD_GFX10_NAVI10_P_A0
AMD_GFX10_NAVI12_P
AMD_GFX10_NAVI14_M
NAVI14_fp16pk_stride1_v3
NAVI14_fp16dot2_stride1_v3
NAVI14_fp32_stride1_v3
AMDMTL_USE_MPSPLUGIN_NV14
/System/Library/Extensions/AMDRadeonX6000Shared.bundle/Contents/MacOS/AMDRadeonX6000Shared
```

Questo prova riferimenti a **GFX10/Navi14** e a un plugin MPS, non il caricamento.

### 4.2 `AMDRadeonX6000Shared` mancante

Il driver MTL referenzia:

```text
/System/Library/Extensions/AMDRadeonX6000Shared.bundle/Contents/MacOS/AMDRadeonX6000Shared
```

Il bundle root25 `AMDRadeonX6000Shared.bundle` contiene solo `runtime.amdil.bc`, `runtime.amdil.builtin`, `runtime.amdil_instrumented.*`, `Info.plist` e `version.plist`: **nessun Mach-O**. La closure fallisce anche su questo componente.

### 4.3 Registrazione kext / GPU

`AMDRadeonX6000.kext` root2 dichiara:

```text
AMDRadeonX6000_AMDNavi14GraphicsAccelerator
0x73401002 0x73411002 0x73431002 0x73471002 0x734F1002
```

`AMDRadeonX6000Framebuffer.kext` dichiara il controller Navi14. Questo è **registrazione metadata** del kext, non una prova che il driver Metal venga caricato o che la GPU venga inizializzata.

---

## 5. Build e architetture

| Componente | Arch | Build / minos | SHA-256 |
|---|---|---|---|
| MTL driver | x86_64h | minos 26.7 / sdk 26.7.2; DTSDKBuild 25G325 | `f4c8ef46…` |
| Root2 X6000 kext | x86_64 | 25G325 / 7.1.8 | `8874ae65…` |
| Root3 X6000 kext | x86_64 | 25G342/26B116 / 7.1.8 | `2734aaf7…` |
| Root25 MTL bundle | — | 7.1.8; bundle senza eseguibile | — |
| Target 26B131 | x86_64 | 27.2.1 / 26B131 | — |

**Mismatch:** il driver MTL non è 26B131; la provenienza 25G342 è in conflitto con `DTSDKBuild 25G325`; il kext root2 è 25G325, il kext root3 è 25G342/26B116. Non esiste una tripletta kext+MTL+framework della stessa build.

---

## 6. Conclusione

| Gate | Stato | Motivo |
|---|---|---|
| MTL binary present | **AVAILABLE (prova)** | 1 Mach-O x86_64h recuperato |
| Bundle MTL completo | **INCOMPLETE** | `Contents/MacOS` assente nel bundle root25 |
| Dipendenze 11/11 | **MISSING** | nessun path esatto nei sample |
| Build match 26B131 | **NO** | minos 26.7; sistema 25G342, SDK 25G325 |
| Firma | **NO** | code object not signed |
| GPU registration | **METADATA ONLY** | Navi14 in Info.plist, nessun runtime |
| Metal runtime | **BLOCKED** | closure fallita |
| WindowServer / desktop | **BLOCKED** | dipendono da Metal/display |

**G — WindowServer: BLOCKED.** Il driver esiste come prova, ma non è chiudibile in 26B131 con i materiali attuali. **E — display interno: BLOCKED.** **H — desktop: BLOCKED.**

**STOP rispettato:** nessuna estrazione, compilazione, firma, installazione, `kextload`, boot o download; spazio libero 12.920.044 KiB (12,32 GiB) > 10 GiB. Nessuna modifica a T16–T26.
