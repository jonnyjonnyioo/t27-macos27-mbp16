# T27 — AGENT-AMD — PROVENANCE / AMD METAL

**Scope:** ricostruire la provenienza di `AMDRadeonX6000MTLDriver` e risolvere `25G325` vs `25G342` usando root25, root-full HAO-71, HAO-68/69/71, manifest, log, `SystemVersion.plist` e metadata Mach-O.  
**Modalità:** sola lettura; nessuna estrazione, modifica o installazione.  
**Esito:** provenienza **risolta**: sistema/product build **25G342** (macOS 26.7.3); SDK build **25G325**; non è una contraddizione, sono campi diversi. Il driver non è 26B131.

---

## 1. Identità del file

| Campo | Valore | Fonte |
|---|---|---|
| Percorso | `HAO-PROJECT/Sessions/<SESSION>/work/mtl-driver/AMDRadeonX6000MTLDriver` | file |
| Dimensione | 7.716.152 byte | `stat` |
| SHA-256 | `f4c8ef463b57792e7a982c4a4eb1b0d1c81098e1c4ee186c2ef13935c4bb9ff0` | `shasum` |
| UUID | `F89F483D-39AC-368D-B9D9-FB689179EFD2` (x86_64h) | `dwarfdump --uuid` |
| Tipo | Mach-O 64-bit dynamically linked shared library | `file` |
| Architettura | x86_64h | `lipo -archs` |
| `LC_BUILD_VERSION` | platform macOS; minos **26.7**; sdk **26.7.2** | `vtool -show-build` |
| Firma | **non firmato** | `codesign -dv` |
| Timestamp file | **15 Nov 2026 15:59:48** | `stat` |

Copie con lo stesso SHA-256:

- HAO-68 `work/EFI-MBP161-HAO68/Payloads/AMDRadeonX6000MTLDriver` — 15 Nov 2026 16:01:15;
- HAO-69 `work/EFI-MBP161-HAO69/Payloads/AMDRadeonX6000MTLDriver` — 15 Nov 2026 16:16:44.

Le copie EFI non sono fonti indipendenti: sono derivate dal file HAO-68.

---

## 2. `SystemVersion.plist`: product build

### Root25

```text
ProductName         = macOS
ProductVersion      = 26.7.3
ProductBuildVersion = 25G342
BuildID             = A1A10DE2-D9A0-11F1-98FF-83F88BD5916F
```

### HAO-71 `root-full`

```text
ProductName         = macOS
ProductVersion      = 26.7.3
ProductBuildVersion = 25G342
BuildID             = A1A10DE2-D9A0-11F1-98FF-83F88BD5916F
```

### Target 26B131

```text
ProductName         = macOS
ProductVersion      = 27.2.1
ProductBuildVersion = 26B131
BuildID             = 04E08ABC-D9A2-11F1-9C65-55CCD2BE79EC
```

Questi sono **product build** del sistema, non SDK.

---

## 3. `Info.plist` del bundle MTL

```text
CFBundleIdentifier        = com.apple.AMDRadeonX6000MTLDriver
CFBundleVersion           = 7.0.1
CFBundleShortVersionString= 7.1.8
CFBundleGetInfoString     = AMDRadeonX6000MTLDriver 7.1.8 24649
NSPrincipalClass          = GFX10_MtlDevice
LSMinimumSystemVersion    = 26.7
DTPlatformVersion         = 26.7.2
DTSDKName                 = macosx26.7.internal
DTSDKBuild                = 25G325
DTPlatformBuild           = "" (vuoto)
BuildMachineOSBuild       = 23A344017
```

`DTSDKBuild` è la build dell’**SDK** usata per compilare, non il `ProductBuildVersion` del sistema. `DTPlatformBuild` è vuoto e non può essere usato come prova. `BuildMachineOSBuild` è la build della macchina di build, non del prodotto.

---

## 4. Metodo di estrazione

Documentato in `HAO-PROJECT/Sessions/<SESSION>/deliverables/METAL-USERSPACE-RECOVERY.md`:

```sh
ipsw dyld extract /System<VOLUME>/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_x86_64h \
  AMDRadeonX6000MTLDriver -o work/mtl-driver
```

Evidenze:

| Voce | Valore |
|---|---|
| Cache | `dyld_shared_cache_x86_64h` |
| Dimensione cache | **888.946.688 byte** |
| Timestamp cache | **6 Nov 2026 06:12** |
| Proprietario | `root:admin` |
| Occorrenze del nome driver | 1 |
| Output | `work/mtl-driver/AMDRadeonX6000MTLDriver` |
| Timestamp output | **15 Nov 2026 15:59:48** |

Il comando è documentato, non rieseguito in T27. La cache è quella dell’host 25G342, coerente con il `SystemVersion.plist` root25/HAO-71.

---

## 5. Risoluzione `25G325` vs `25G342`

| Campo | Valore | Significato |
|---|---|---|
| `ProductBuildVersion` root25 / HAO-71 | **25G342** | build del sistema macOS 26.7.3 |
| `DTSDKBuild` bundle MTL | **25G325** | build dell’SDK usata per compilare |
| `DTPlatformVersion` | 26.7.2 | versione SDK |
| `DTPlatformBuild` | vuoto | non disponibile |
| `LC_BUILD_VERSION` | minos 26.7 / sdk 26.7.2 | target minimo e SDK |
| `BuildMachineOSBuild` | 23A344017 | macchina di build, non prodotto |

**Conclusione:** non c’è contraddizione. `25G342` è la **product build del sistema** da cui viene la dyld cache; `25G325` è la **SDK build** con cui è stato compilato il driver. La provenienza del file è **OS 25G342 / SDK 25G325**. Entrambi sono 25G-series, non 26B131.

### Cosa non è provato

- Non c’è un hash della cache nella documentazione HAO-68; la catena è comando documentato + root 25G342 + hash del file, non una firma crittografica della cache.
- Il binario non contiene `ProductBuildVersion`; la build del sistema non è leggibile dal solo Mach-O.
- `DTPlatformBuild` è vuoto; non si può usare per dedurre la product build.
- Il file è non firmato e non è un bundle installabile.

---

## 6. UUID correlati

| Componente | UUID | Nota |
|---|---|---|
| MTL driver | `F89F483D-39AC-368D-B9D9-FB689179EFD2` | x86_64h |
| GL driver root25 | `346DD4A5-26E9-3F13-9E16-BF2329A590D2` | x86_64h; OpenGL, non Metal |
| X6000 kext root2 | `1540D089-EE2D-3339-B5A8-2024F9E38581` | x86_64; hash root2 `8874ae65…` |
| X6000 kext root3 | `1540D089-EE2D-3339-B5A8-2024F9E38581` | stesso UUID, hash `2734aaf7…`; non è una coppia automatica |
| `AMDRadeonX6000Shared` | — | bundle senza Mach-O |

L’UUID del MTL non coincide con quello del kext X6000: sono componenti diversi, non una prova di pairing. La somiglianza di versione 7.1.8 non è una prova ABI.

---

## 7. Fonti HAO-68/69/71

| Fonte | Dato | Limite |
|---|---|---|
| HAO-68 `METAL-USERSPACE-RECOVERY.md` | cache, comando, UUID, minos 26.7, “build 25G342” | documentale; nessun hash cache |
| HAO-68 `evidence/mtl-driver.txt` | SHA, UUID, minos 26.7, sdk 26.7.2 | identità, non provenienza |
| HAO-68 `SHA256-MANIFEST.txt` | SHA del file e payload | hash, non build |
| HAO-69 `METAL-USERSPACE-ABI.md` | cache host 26.7.3; UUID | conferma indiretta |
| HAO-71 `METAL-REPORT.md` | provenienza dyld cache 25G342 | documentale |
| HAO-71 `root-full/SystemVersion.plist` | ProductBuildVersion 25G342 | conferma product build |
| root25 `SystemVersion.plist` | ProductBuildVersion 25G342 | conferma product build |
| target `SystemVersion.plist` | ProductBuildVersion 26B131 / 27.2.1 | target, non sorgente |

Nessuna fonte è stata modificata.

---

## 8. Verdetto

| Domanda | Risposta |
|---|---|
| Provenienza del binario | **25G342** (macOS 26.7.3), dyld shared cache |
| SDK di compilazione | **25G325** (`DTSDKBuild`) |
| Contraddizione 25G325/25G342 | **NO**: campi diversi (SDK vs product build) |
| Build target 26B131 | **NO** |
| Firma | **NO** |
| Bundle completo | **NO**: il bundle root25 non ha l’eseguibile |
| Installabile su 26B131 | **NO/UNPROVEN** |
| G — WindowServer | **BLOCKED** |

**STOP rispettato:** sola lettura; nessuna estrazione, modifica, compilazione, firma, installazione, `kextload` o boot. Spazio libero 12.920.044 KiB (12,32 GiB) > 10 GiB. Nessuna modifica a T16–T26.
