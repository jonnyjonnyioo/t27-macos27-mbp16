# T27 — AGENT-AMD — VERIFICA NAVI14 / RADEON PRO 5300M

**Scope:** inventario AMD/ATI nei materiali T25/T27, root2, root3, root25 e KDK 26B131; ricerca Navi14/PCI ID; confronto 25G325/25G342/26B116/26B131.  
**Modalità:** read-only. Nessuna compilazione, installazione, `kextload`, boot o download.  
**Esito:** **nessun componente classificabile `TRANSFERABLE` per 26B131.** Sette kext Navi14 x86_64 in root2 restano `UNPROVEN`; il percorso Metal donor è incompleto. Il binario `AMDRadeonX6000MTLDriver` esiste, ma è un’estrazione dalla dyld cache del sistema 25G342, con SDK 25G325: non è un bundle 26B131. Dettaglio in `PROVENANCE-REPORT.md` e `METAL-USERSPACE-REPORT.md`.

---

## 1. Inventario

| Radice | Bundle AMD/ATI top-level | Note |
|---|---:|---|
| root2 (`<SESSION>/work/root2`) | **12** | include i 7 bundle Navi14 + X4000/X5000/9500/10000 |
| root3 (`<SESSION>/work/root3`) | **6** | X6000, Framebuffer, HWServices, Support, AMDFramebuffer, ServiceManager |
| root25 (`<DONOR_VOLUME>`) | **24** | include kext e bundle userspace GL/MTL/VA |
| KDK 26B131 | **0** | nessun bundle AMD/ATI |
| target 26B131 (`<TARGET_ROOT>`) | **0** | nessun bundle AMD/ATI |

I 7 bundle Navi14 di root2 sono tutti **x86_64**, `CFBundleShortVersionString=7.1.8` (HWLibs `1.0`). Non sono 26B131: root2 è la base 25G325/25G332.

### 1.1 Root2 — set Navi14

| Bundle | Binario primario | Byte | SHA-256 primario | Arch | Classe |
|---|---|---:|---|---|---|
| `AMDRadeonX6000.kext` | `Contents/MacOS/AMDRadeonX6000` | 2.379.536 | `8874ae65086394ad1bc6901b349b9373d8eb8fec2d5f35703c7681a79abefefb` | x86_64 | `UNPROVEN` |
| `AMDRadeonX6000Framebuffer.kext` | `Contents/MacOS/AMDRadeonX6000Framebuffer` | 3.706.208 | `d037b0957238b5bfd32fddfccb24917a6347f8daf0f3421f88827dbdf81a2824` | x86_64 | `UNPROVEN` |
| `AMDRadeonX6000HWServices.kext` | `Contents/MacOS/AMDRadeonX6000HWServices` | 92.592 | `9d50f380d06f8d669266ae3b78342c59cc0bc672e8cef657ff211f812903bed2` | x86_64 | `UNPROVEN` |
| `AMDRadeonX6000HWServices.kext/Contents/PlugIns/AMDRadeonX6000HWLibs.kext` | `Contents/MacOS/AMDRadeonX6000HWLibs` | 29.233.952 | `7d078501330fbec5cadf369ff7bb6f6ea5311a8dd021f70da17b506154074706` | x86_64 | `UNPROVEN` |
| `AMDSupport.kext` | `Contents/MacOS/AMDSupport` | 2.104.464 | `b222e4bc84fd3662b1b2bfdcbbb5f97f1af9e752b271e9119a3885afa1d1e976` | x86_64 | `UNPROVEN` |
| `AMDFramebuffer.kext` | `Contents/MacOS/AMDFramebuffer` | 312.576 | `0e79c809a3ceadc7941063773b454672a106ba0c90add54c0d98d09486d87bc3` | x86_64 | `UNPROVEN` |
| `AMDRadeonServiceManager.kext` | `Contents/MacOS/AMDRadeonServiceManager` | 90.352 | `6b7586dc06dd39c1f90ed179eda6d65653030aa4cb9a17b94bfabd3f9a4212ac` | x86_64 | `UNPROVEN` |

Root2 contiene anche `AMD10000Controller`, `AMD9500Controller`, `AMDRadeonX4000`, `X4000HWServices`, `X5000`, `X5000HWServices`: **non sono Navi14** e non sono stati conteggiati come candidati al target.

### 1.2 Root3 — confronto X6000

| Percorso | Byte | SHA-256 primario | Arch | Versione | Classe |
|---|---:|---|---|---|---|
| `root3/System/Library/Extensions/AMDRadeonX6000.kext` | 2.090.264 | `2734aaf7bf338afb9dece81466651a0c9db3a99dc6c5930798dd1fb5da63a40b` | x86_64 | 7.1.8 / build 7.0.1 | `UNPROVEN` |

Il binario è **diverso** da root2: dimensione e hash non coincidono. Root3 non è 26B131 e non è una prova di compatibilità.

> **T27 fingerprint (16 Nov 2026):** root3 contiene **5/6** binari con SHA identico a `systemkc-all` (`AMDSupport`, `X6000Framebuffer`, `X6000HWServices`, `ServiceManager`, `X6000`); `X6100HWLibs` è assente. Root2 ha **0/6** match esatti; root25 non ha binari AMD. Dettaglio: `AMD-POOL-FINGERPRINTS.md`.

### 1.3 Root25 — driver userspace

| Percorso | Binario | SHA-256 | Arch | Classe |
|---|---|---|---|---|
| `root25/.../AMDRadeonX6000GLDriver.bundle` | `Contents/MacOS/AMDRadeonX6000GLDriver` | `297665dfb1c3df5593807953041c00fe64328989f5a0b0cb64a3c903695b1f67` | x86_64h | `AVAILABLE` (OpenGL, non Metal) |
| `root25/.../AMDRadeonX6000MTLDriver.bundle` | **nessun Mach-O nel bundle**; binario recuperato in HAO-68 | `f4c8ef463b57792e7a982c4a4eb1b0d1c81098e1c4ee186c2ef13935c4bb9ff0` | x86_64h | `INCOMPLETE` |
| `root25/.../AMDRadeonX6000Shared.bundle` | **nessun Mach-O**; solo `.bc`/`.builtin` | — | — | `INCOMPATIBLE` |
| `root25/.../AMDRadeonVADriver.bundle` | **nessun Mach-O** | — | — | `INCOMPATIBLE` |
| `root25/.../AMDRadeonVADriver2.bundle` | **nessun Mach-O** | — | — | `INCOMPATIBLE` |
| `root25/.../AMDMTLBronzeDriver.bundle` | **nessun Mach-O** | — | — | `INCOMPATIBLE` |

`AMDRadeonX6000.kext` in root25 contiene solo `Info.plist`, `PkgInfo`, `version.plist` e `_CodeSignature`: **il binario `Contents/MacOS/AMDRadeonX6000` è assente**. Il bundle MTL root25 ha 9 file e 19 MB di risorse GFX10, ma **nessun Mach-O**; il binario `AMDRadeonX6000MTLDriver` è stato recuperato separatamente dalla dyld shared cache 25G-series (HAO-68: 25G342; bundle: `DTSDKBuild 25G325`), non è firmato e non è un bundle installabile.

---

## 2. Riferimenti Navi14

`AMDRadeonX6000` (root2) contiene le classi:

```text
AMDRadeonX6000_AMDNavi14GraphicsAccelerator
AMDRadeonX6000_AMDNavi14PM4Engine
AMDRadeonX6000_AMDNavi14Hardware
```

Le personalità `AMDNavi14GraphicsAccelerator` e `AMDNavi14Controller` dichiarano:

```text
0x73401002 0x73411002 0x73431002 0x73471002 0x734F1002
```

Questo prova **solo** che i metadati e il codice x86_64 nominano Navi14 e il PCI ID `1002:7340`. Non prova caricamento, inizializzazione GPU, eDP/gMux, Metal o WindowServer.

---

## 3. Dipendenze e build

Dipendenze dichiarate/richieste: `IOAcceleratorFamily2`, `IOGraphicsFamily`, `IOPCIFamily`, `IOSurface`, `AppleGraphicsDeviceControl`.

- `IOGraphicsFamily` è presente in root2 come bundle flat KDK, non caricato contro 26B131.
- KDK 26B131 non contiene AMD/ATI e non contiene `.kc`.
- Target 26B131 non contiene AMD/ATI.
- Root2/root3 sono build 25G325/25G342; il KDK 26B131 usa kext 26B116 per altri componenti.
- Non esiste un `AMDRadeonX6000` 26B131 né un `MTLDriver` 26B131; il binario MTL 25G-series recuperato è `x86_64h`, `minos 26.7`, non firmato.

---

## 4. Classificazione

| Classe | Significato | Esemplari |
|---|---|---|
| `TRANSFERABLE` | copiabile con prova di compatibilità 26B131 | **0** |
| `UNPROVEN` | codice x86_64 presente, nessun test 26B131 | 7 bundle root2 + 1 X6000 root3 |
| `INCOMPATIBLE` | build non target o stack non installabile | MTL 25G-series/26.7; GL/Shared/VA root25 |
| `ABSENT` | non presente nel materiale | AMD in KDK 26B131 e target |

**Nessun componente AMD è `TRANSFERABLE`.** La presenza di PCI ID e classi Navi14 non basta: manca la catena 26B131. Il driver Metal 25G-series è stato recuperato, ma è incompleto come bundle e incompatibile come build.

---

## 5. Conclusione

- **E — display interno:** resta **BLOCKED**. Il codice donor Navi14 esiste, ma non è 26B131 e non è mai stato caricato; eDP/gMux/backlight non sono provati.
- **G — WindowServer:** resta **BLOCKED**. Il bundle `AMDRadeonX6000MTLDriver.bundle` non contiene un Mach-O; il binario 25G-series recuperato è non firmato, `minos 26.7`, e non è uno stack 26B131 installabile. Dettaglio in `METAL-USERSPACE-REPORT.md`.
- **H — desktop:** resta **BLOCKED**.
- **UCLK/firmware/GPU init:** resta **UNPROVEN**; le fonti Linux non sono prove macOS.

**STOP rispettato:** nessuna compilazione, installazione, `kextload`, boot o download; spazio libero 12.920.044 KiB (12,32 GiB) > 10 GiB. Nessuna modifica a T16–T26.
