# T27 — Provider 26B131 trovati localmente

**Data:** 2026-11-17  
**Richiesta:** trovare online o nel computer i binari/export dei provider 26B131.  
**Esito:** **trovati nel computer**, nel KDK 26B131 già verificato. Nessun download.

---

## 1. Fonte locale

KDK 26B131:

```text
Sessions/<SESSION>/work/kdk/KDK_27.2.1_26B131.kdk
```

Identità già verificata in T22/T23:

| Campo | Valore |
|---|---|
| DMG | `Kernel_Debug_Kit_27.2.1_build_26B131.dmg` |
| DMG SHA-256 | `287377a4c52ae3ad04476a35195fc143129a18a2d34cd585cbec7b35cfc42c81` |
| Package ID | `com.apple.pkg.KDK.26B131` |
| Build dichiarata | `26B131` |
| Kernel interno | SHA `3c931751…`, UUID `037E7B86…` — identico al target |
| Installato sull'host | no |

Fallback online (non usato):

```text
https://github.com/dortania/KdkSupportPkg/releases/tag/26B131
Kernel_Debug_Kit_27.2.1_build_26B131.dmg
SHA-256 287377a4c52ae3ad04476a35195fc143129a18a2d34cd585cbec7b35cfc42c81
```

---

## 2. Binari x86_64 trovati

Percorso base:

```text
Sessions/<SESSION>/work/kdk/KDK_27.2.1_26B131.kdk/System/Library/Extensions
```

| Provider | Percorso | Byte | SHA-256 | UUID x86_64 | Export |
|---|---|---:|---|---|---:|
| `IOGraphicsFamily` | `IOGraphicsFamily.kext/IOGraphicsFamily` | 1.903.776 | `42d1ad03c71ee3496209ae5f90fec4eb8af3a715c216c719eeaf59d97df6d5b6` | `B05F9EE8-4F53-3466-8701-1DCE53F1E10B` | 1.207 |
| `IOPCIFamily` | `IOPCIFamily.kext/Contents/MacOS/IOPCIFamily` | 2.148.224 | `bbe5d9bc84009bc2c96d6987ae5700358eab5d885623b4cd4edb2a7f60598e0d` | `742BC442-A2BA-3C65-A90C-58A17E91B193` | 673 |
| `IOAcceleratorFamily2` | `IOAcceleratorFamily2.kext/Contents/MacOS/IOAcceleratorFamily2` | 1.256.224 | `d5088d053d88d6177ac43a3b8fcde4e1e26db840d84be640b5d15ae1d487ade6` | `6B2B553C-B724-3502-A8C4-1DC515A00726` | 2.970 |
| `IOSurface` | `IOSurface.kext/Contents/MacOS/IOSurface` | 2.037.216 | `39b2f6bf494dbb463de5bc2fe1d6b9b2f7749659601d64128f39f0ebf19cb0b7` | `729B99E2-8CBF-3725-A67F-A049CC7F6D37` | 1.397 |
| `IOACPIFamily` | `IOACPIFamily.kext/Contents/MacOS/IOACPIFamily` | 100.032 | `d6a4e87f4af02f809e91673f04d6367a9018bc17e5e01a48d9884879d27bb5b5` | `2CA0D0E8-9D7F-3BD3-B2D9-69152EB1705B` | 146 |

`IOGraphicsFamily` usa il vecchio layout con eseguibile alla radice del bundle; gli altri sono in `Contents/MacOS`.

**Caveat:** il package KDK è 26B131 e il kernel coincide, ma i kext hanno `DTPlatformBuild` non uniforme (`26B116` per quattro provider). T23 lo documenta già. Sono i binari debug ufficiali del KDK 26B131, non i kext del sistema target.

---

## 3. Export generati

Directory:

```text
T27/AGENT-AMD/.tmp/providers-26B131/
```

File:

```text
IOGraphicsFamily.exports
IOPCIFamily.exports
IOAcceleratorFamily2.exports
IOSurface.exports
IOACPIFamily.exports
providers_union.exports          # 6.389 simboli
kernel_plus_providers.exports    # 30.787 simboli
providers_manifest.txt
```

Confronto statico con `HWLibs` 25G342 estratto dalla SystemKC:

| Insieme | Simboli non definiti | Irrisolti |
|---|---:|---:|
| `AMDRadeonX6000HWLibs` | 348 | **0** |

Quindi i 348 simboli di HWLibs sono tutti presenti nel kernel 26B131 o nei cinque provider. **Non** è una prova di runtime: resta da verificare il caricamento, la firma, le dipendenze e il comportamento.

Altri residui AMD (provider aggiuntivi non inclusi nei cinque):

| Bundle | Non definiti | Irrisolti |
|---|---:|---:|
| `AMDSupport` | 502 | 17 (`AppleGraphicsDeviceControl`) |
| `AMDFramebuffer` | 697 | 264 (`ATIConnector`, `GammaTable`, …) |
| `AMDRadeonX6000` | 1.171 | 1 (`AMDHardware::decrementInternalRefCount`) |
| `AMDRadeonX6000Framebuffer` | 529 | 19 (`AppleGraphicsDeviceControl`) |
| `AMDRadeonServiceManager` | 320 | 0 |
| `AMDRadeonX6000HWServices` | 305 | 0 |

`AppleGraphicsDeviceControl.kext` non è nel KDK 26B131; i 17+19 simboli AGDC non sono quindi coperti da questa fonte. Non vanno dichiarati incompatibili: manca il provider.

---

## 4. Conclusione

- I cinque provider 26B131 **esistono già nel computer**, nel KDK 26B131.
- Le tabelle export sono state generate e sono disponibili in `.tmp/providers-26B131`.
- `HWLibs` è staticamente risolto: **0/348** irrisolti.
- `AMDSupport`/`X6000Framebuffer` richiedono ancora `AppleGraphicsDeviceControl`, assente dal KDK.
- T27 resta **OPEN**; nessun boot, build, installazione o modifica di sistema.
- Il prossimo passo tecnico è decidere se i binari KDK 26B131 sono una base ABI accettabile e come coprire AGDC.

---

## 5. Aggiornamento — AGDC 26B131 e copertura completa

`AppleGraphicsDeviceControl` non è un kext top-level: è un plugin dentro
`AppleGraphicsControl.kext` del KDK 26B131.

```text
Sessions/<SESSION>/work/kdk/KDK_27.2.1_26B131.kdk/System/Library/Extensions/
  AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDeviceControl.kext/
    Contents/MacOS/AppleGraphicsDeviceControl
```

| Campo | Valore |
|---|---|
| Byte | 89.088 |
| SHA-256 | `ea39241b0c99dae2fb4dd81a33af0b36e1c0ffd1ad04283140ea51555486a1d7` |
| Arch | x86_64 |
| UUID | `9F5BC20A-36D8-3AB5-9932-02359219C933` |
| Export | 98 |

Sono stati aggiunti gli export dei sei kext AMD 25G342 e di HWLibs 25G342.
I 13 provider locali esportano **20.801** simboli; l'unione con i 24.399 export
del kernel 26B131 è **45.199** simboli (file `kernel_plus_all_local_base.exports`).

### Copertura con tutti i provider locali

| Bundle | Non definiti | Irrisolti |
|---|---:|---:|
| `AMDSupport` | 502 | **0** |
| `AMDFramebuffer` | 697 | **0** |
| `AMDRadeonServiceManager` | 320 | **0** |
| `AMDRadeonX6000` | 1.171 | **1** |
| `AMDRadeonX6000Framebuffer` | 529 | **0** |
| `AMDRadeonX6000HWServices` | 305 | **0** |
| `AMDRadeonX6000HWLibs` | 348 | **0** |

### Unico simbolo irrisolto

```text
__ZN26AMDRadeonX6000_AMDHardware25decrementInternalRefCountEj
AMDRadeonX6000_AMDHardware::decrementInternalRefCount(unsigned int)
```

Verifiche eseguite:

- tutte le copie locali di `AMDRadeonX6000` lo importano come `U`;
- `AMDRadeonX6000HWLibs` 25G342 estratto dalla SystemKC: non lo definisce;
- `AMDRadeonX6000HWLibs` 25G325/KDK25: non lo definisce;
- nessuna definizione nei sei AMD 25G342;
- il KDK 26B131 non contiene kext AMD.

Quindi, esauriti i provider locali verificabili, **1 simbolo resta irrisolto**.
Si applica il criterio di STOP richiesto da ChatGPT. Non è una prova che il
driver non funzioni a runtime, ma la verifica statica non è completa.

### Stato

- HWLibs: 0/348 irrisolti.
- Cinque bundle AMD su sei: 0 irrisolti.
- `AMDRadeonX6000`: 1/1.171 irrisolto.
- T27 resta **OPEN**; nessun boot, build, download o modifica.
