# T27 — AGENT-AMD — HARDWARE / DEVICETREE DISCOVERY

**Scope:** ricerca di DeviceTree, ioreg, ACPI/DSDT/SSDT, PCI `1002:7340/41/43/47/4F`, GFX0/PEG0/gMux/framebuffer/connectors e proprietà `AAPL` nei materiali T25/T26/T27/HAO-68/69/71/References.  
**Modalità:** sola lettura; nessun boot, nessuna modifica EFI/ACPI, nessun nuovo log.  
**Esito:** **nessun dump DeviceTree/ioreg/DSDT del MacBookPro16,1 è presente**. Il riconoscimento hardware di macOS 27.2.1 resta **UNPROVEN**; i dati PCI sono metadati/dichiarazioni, non misure locali.

---

## 1. Cosa è stato cercato

| Categoria | Ricerca | Esito |
|---|---|---|
| DeviceTree | file `*DeviceTree*`, `*.dtb`, dump ioreg | **nessun dump MBP16,1** |
| ioreg | `*ioreg*`, log `AppleGPUWrangler` | **nessun output** |
| ACPI | `DSDT`, `SSDT`, `*.aml`, `*.dsl` | solo `SSDT-PNLF.aml` generico e sorgenti ACPICA |
| PCI Navi14 | `1002:7340/41/43/47/4F` | presente in documenti e metadati driver, non in ioreg |
| GPU path | `GFX0`, `PEG0`, `gMux`, `IOFramebuffer` | solo documenti/reference, nessun percorso MBP16,1 |
| Proprietà | `AAPL,` / `device-id` | nessun dump locale |
| Target | `ioreg` / `DeviceTreeKit` | binari/cataloghi, non un registry live |

Fonti scansionate: T25, T26, T27, HAO-68, HAO-69, HAO-71, `HAO-PROJECT/References`.

---

## 2. DeviceTree / ioreg

Non esiste un file di dump `ioreg -l` o `IODeviceTree` del MacBookPro16,1. Le uniche tracce sono:

| File | Cosa è | Limite |
|---|---|---|
| `References/liberator/mac/tools/fixtures/pci-tree-two-roots.txt` | fixture ioreg generica, `A2XACPIPlatformExpert` | **non è MBP16,1**; nessun `AMD`, `PEG0`, `GFX0`, `1002` |
| `References/liberator/realmac27/README.md` | nota su `PEG0` del Mac Pro 6,1 | hardware diverso |
| `SSDT-PNLF.aml` | SSDT generico per backlight | non è un DSDT del laptop |
| `<TARGET_ROOT>/usr/sbin/ioreg` | binario target | non eseguito; nessun output |
| `<TARGET_ROOT>/.../DeviceTreeKit.framework` | framework catalogo | symlink `broken` verso `Versions/Current/DeviceTreeKit`; nessun dump |

Il target 26B131 non è avviato: non esiste un `IODeviceTree` live. Eseguire `ioreg` sull’host misurerebbe l’host, non il target, e sarebbe un nuovo log non autorizzato.

---

## 3. PCI ID e GPU

### 3.1 Metadati driver 25G342/25G325

`AMDRadeonX6000.kext` root2 dichiara:

```text
AMDRadeonX6000_AMDNavi14GraphicsAccelerator
0x73401002 0x73411002 0x73431002 0x73471002 0x734F1002
```

`AMDRadeonX6000Framebuffer.kext` dichiara il controller Navi14 e `AMDGPUWrangler`. Questo è **matching metadata**, non una prova che il PCI device sia presente o che macOS 27 lo enumeri.

### 3.2 Dati “hardware” in HAO-71

`HAO-PROJECT/Sessions/<SESSION>/deliverables/GPU-STABILITY.md` riporta:

```text
PCI 1002:7340, rev 0x0043, subsystem 106b:0210
VBIOS 113-D32207P1-019; ROM 113-D3220E-190
iGPU 8086:3e9b
```

Questi valori **non sono accompagnati da un ioreg o da un dump locale**. T25 dichiara esplicitamente che il subsystem non è stato verificato localmente. Vanno trattati come **dichiarazioni/documentazione**, non come misura del MacBookPro16,1 in questa sessione.

### 3.3 Target 26B131

Nel target e nel KDK 26B131:

- 0 bundle AMD/ATI;
- nessun `AMDRadeonX6000`, `AMDSupport`, `AMDFramebuffer`;
- nessun `Metal.framework`/`IOAccelerator.framework` binario ai path attesi;
- nessun `AMDNavi14`/`GFX10` runtime.

Non c’è un’interfaccia AMD sostitutiva.

---

## 4. GFX0 / PEG0 / gMux / connettori / AAPL

| Elemento | Evidenza | Stato |
|---|---|---|
| `GFX0` | solo riferimenti generici ACPICA/DSDT di esempio | **nessun path MBP16,1** |
| `PEG0` | nota Mac Pro 6,1 e fixture generica | **hardware diverso** |
| `gMux` | citato in T25/T27 come rischio display | **nessun nodo/percorso locale** |
| framebuffer | `IOFramebuffer` citato negli script HAO-68 | **nessun output** |
| connettori/eDP | 3072×1920 noto da documentazione | **nessuna misura runtime** |
| proprietà `AAPL` | nessun dump `ioreg`/DeviceTree | **ASSENTI** |

Un desktop su MBP9,2 o su display esterno non è una prova del percorso eDP/gMux del MacBookPro16,1.

---

## 5. Log già acquisiti

| Fonte | Contenuto | Esito |
|---|---|---|
| HAO-68 `desktop-probe.sh` | script A–F, `ioreg -rc IOFramebuffer` | **non eseguito** |
| HAO-68 `DESKTOP-READINESS.md` | A/B/C/D/E/F tutti `NO` | nessun livello grafico |
| HAO-68 `METAL-USERSPACE-RECOVERY.md` | driver MTL dalla cache | non è un log GPU |
| HAO-71 `GPU-STABILITY.md` | dati PCI/VBIOS dichiarati | nessun ioreg |
| HAO-71 `METAL-REPORT.md` | driver e dipendenze | nessun test runtime |
| HAO-69 `DARWIN27-AMD-ABI.md` | confronto ABI documentale | nessun boot |
| T25/T26 | analisi e matrici | nessun DeviceTree |

Nessun log contiene un’enumeration AMD del MacBookPro16,1 sotto macOS 27.2.1.

---

## 6. Conclusione

| Domanda | Risposta |
|---|---|
| macOS 27.2.1 riconosce la Radeon Pro 5300M a livello hardware? | **UNPROVEN**: nessun boot, nessun ioreg |
| Esiste un DeviceTree del MBP16,1? | **NO** nei materiali |
| Esiste un DSDT/SSDT del MBP16,1? | **NO**; solo SSDT generico |
| Il PCI `1002:7340` è verificato localmente? | **NO**; è nei metadati/dichiarazioni |
| GFX0/PEG0/gMux sono noti? | **NO**; solo riferimenti generici/altri hardware |
| Esiste un percorso grafico 26B131? | **NO**; AMD assente |
| E — display interno | **BLOCKED** |
| G — WindowServer | **BLOCKED** |
| H — desktop | **BLOCKED** |

**STOP rispettato:** sola lettura; nessun boot, modifica EFI/ACPI, installazione o nuovo log. Spazio libero 12.920.044 KiB (12,32 GiB) > 10 GiB. Nessuna modifica a T16–T26.
