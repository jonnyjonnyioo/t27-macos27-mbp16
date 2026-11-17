# T27 — AGENT-AMD — HARDWARE EVIDENCE RECOVERY

**Scope:** recupero delle evidenze hardware reali del MacBookPro16,1 da T25/T26, HAO-68/69/71, audit e inventari; separazione tra misura locale, dichiarazione e ipotesi; verifica di provenienza, timestamp e SHA-256.  
**Modalità:** sola lettura; nessuna interrogazione hardware, nessun boot, nessuna modifica EFI/ACPI.  
**Esito:** **evidenza locale parziale recuperata** da `<SESSION>`, ma su **macOS 26.7.3 / 25G342**, non su **27.2.1 / 26B131**. Il target resta **UNPROVEN**; il subsystem `106b:0210` resta **UNVERIFIED**.

---

## 1. Risultato in una riga

Esiste **una** misura locale grezza del MacBookPro16,1: `<SESSION>/evidence/phase0.txt` (`system_profiler`), che conferma modello, `1002:7340`, rev `0043`, VBIOS, ROM, iGPU, gMux e display interno **sotto 25G342**. Non esiste alcuna misura equivalente sotto 26B131. Il subsystem `106b:0210` non compare in nessun output grezzo.

---

## 2. Metodo

1. Ricerca di `MacBookPro16,1`, `IOPCIDevice`, `1002:7340`, `106b:0210`, `8086:3e9b`, `system_profiler`, `ioreg`, `gfxutil`, `acpidump`, `kmutil` nei materiali indicati.
2. Distinzione di quattro classi:
   - **MISURA LOCALE**: output grezzo di un comando, con SHA e timestamp.
   - **DICHIARAZIONE**: valore riportato in un report senza output grezzo.
   - **DERIVATO**: valore copiato da un altro report o da una fonte esterna.
   - **ASSENTE**: nessun file o output.
3. Nessuna esecuzione di `ioreg`, `system_profiler`, `gfxutil`, `acpidump` o `kmutil` in questa sessione.

---

## 3. Evidenza locale trovata: HAO-86 / 25G342

`<SESSION>` è una baseline reale del **MacBookPro16,1 su macOS 26.7.3 build 25G342**. Non era nell’elenco iniziale, ma è l’unica fonte con output grezzi; va usata solo come baseline 25G342, **mai** come prova per 26B131.

### 3.1 `phase0.txt` — `system_profiler`

Output grezzo presente, 2.094 B:

```text
Model Identifier: MacBookPro16,1
Processor Name: 6-Core Intel Core i7
Memory: 16 GB
System Firmware Version: 2103.160.2.0.0 (iBridge: 24.16.6005.0.0,0)

AMD Radeon Pro 5300M:
  Vendor: AMD (0x1002)
  Device ID: 0x7340
  Revision ID: 0x0043
  ROM Revision: 113-D3220E-190
  VBIOS Version: 113-D32207P1-019
  gMux Version: 5.0.0

Intel UHD Graphics 630:
  Device ID: 0x3e9b
  gMux Version: 5.0.0

Color LCD:
  Resolution: 3072 x 1920 Retina
  Main Display: Yes
  Online: Yes
  Connection Type: Internal
```

**SHA-256:** `fc6137a7b51fe20d65d23bcc117f8326ef19f7cb84535b75314775731576b489`  
**mtime:** 16 Nov 2026 02:41:44  
**Macchina/build:** MacBookPro16,1 / 25G342, **non 26B131**.

### 3.2 `phase1-drivers.txt` — kext caricati

Output grezzo, 1.628 B: 6 kext AMD caricati (`AMDSupport`, `AMDRadeonX6000`, `X6000Framebuffer`, `X6000HWServices`, `ServiceManager`, `X6100HWLibs`), più `AppleIntelKBLGraphics`/`CFLGraphicsFramebuffer`.

**SHA-256:** `59de359db3f3fc638b825de2b1eb70c04ffee62b86036f4ae7e5304570d88ecb`  
**mtime:** 16 Nov 2026 02:42:12  
**Uso:** prova che **25G342** carica la GPU; non dice nulla su 26B131.

### 3.3 `pci-ids.txt` — snippet `ioreg`

Output grezzo parziale, 540 B, con `vendor-id`/`device-id`/`subsystem-id` in little-endian:

```text
vendor-id = <86800000>   → 0x8086 Intel
device-id = <c43e0000>   → 0x3ec4
vendor-id = <02100000>   → 0x1002 AMD
device-id = <78140000>   → 0x1478
device-id = <79140000>   → 0x1479
```

**SHA-256:** `456646ebff320a756d10b5ca5f73ed150c05b8362e5ec053ed970d3a7852e0c9`  
**mtime:** 16 Nov 2026 02:45:14

**Limite:** è uno snippet senza path, senza nome device e **senza `7340`**. Non è utilizzabile per identificare la GPU o il subsystem; non contraddice `phase0`, ma non aggiunge prova.

### 3.4 Altri output HAO-86

| File | Contenuto | Uso |
|---|---|---|
| `METAL-DEVICE-TEST.md` | 2 `MTLDevice`; Radeon default; `registryID` 4294969148 | baseline 25G342 |
| `DISPLAY-STATUS.md` | Color LCD 3072×1920, interno, sotto Radeon | baseline 25G342 |
| `REPORT.md` | sintesi e percentuali | derivato |
| `SHA256-MANIFEST.txt` | manifest datato `2026-11-16T01:45:21Z` | provenienza |

---

## 4. Cosa manca per 26B131

| Evidenza | 25G342 | 26B131 |
|---|---|---|
| `system_profiler` GPU | **SÌ** (`phase0`) | **NO** |
| `ioreg` GPU completo | **NO** (solo snippet parziale) | **NO** |
| Subsystem `106b:0210` | **NO** | **NO** |
| `gfxutil` | **NO** | **NO** |
| `acpidump` / DSDT / SSDT | **NO** | **NO** |
| `kmutil` con kext AMD caricati | **NO** | **NO** |
| Display interno sotto Radeon | **SÌ** (`phase0`) | **NO** |
| Metal compute | **SÌ** (`HAO-86`) | **NO** |

`HAO-86` non è un boot 26B131: è la macchina **25G342**. La build target non è stata avviata.

---

## 5. Matrice delle evidenze

| Evidenza | Classe | Macchina/build | Output grezzo | SHA-256 | Timestamp | Verdetto |
|---|---|---|---|---|---|---|
| `T25-AMD-NAVI14.md` | dichiarazione esterna | target dichiarato | no | `f0fbe90d…` | 16 Nov 21:51 | PCI/subsystem da patch Linux; non misura |
| `T25-AUDIT.json` | audit | target dichiarato | no | `c4ba42b1…` | 16 Nov 22:06 | ammette nessuna prova hardware |
| `T26-REPORT.md` | derivato | target dichiarato | no | `3d5ef15d…` | 16 Nov 22:29 | deriva da T25; nessun dump |
| `HAO-68/AMD-MACOS-POWER-COMPATIBILITY.md` | dichiarazione locale | 25G342? | no | `7e47071a…` | 15 Nov 16:03 | dice `system_profiler` su questa macchina; output assente |
| `HAO-69/UCLK-SMU-ANALYSIS.md` | dichiarazione locale | 25G342? | no | `36e94029…` | 15 Nov 16:19 | dice VBIOS/ROM/revision/subsystem letti; output assente |
| `HAO-71/GPU-STABILITY.md` | derivato | target dichiarato | no | `a5ff9d47…` | 15 Nov 16:34 | ripete HAO-69; nessuna fonte grezza |
| `HAO-68/desktop-probe.sh` | script | — | no | `ddda879d…` | 15 Nov 16:03 | mai eseguito |
| `HAO-68/desktop-probe.sh` output | assente | — | no | — | — | A–F tutti `NO` in `DESKTOP-READINESS` |
| `HAO-68/kmutil-kdk-refusal.txt` | log | 25G342 | sì | `99e1a785…` | 15 Nov 16:05 | rifiuto KDK; nessun hardware |
| `HAO-71/kmutil-hao71.log` | log | 25G342 | sì | `d1571ffa…` | 15 Nov 16:34 | nessuna enumeration AMD |
| `HAO-86/phase0.txt` | **misura locale** | **25G342** | **sì** | `fc6137a7…` | 16 Nov 02:41 | GPU/display confermati su 25G342 |
| `HAO-86/phase1-drivers.txt` | **misura locale** | **25G342** | **sì** | `59de359d…` | 16 Nov 02:42 | 6 kext AMD caricati |
| `HAO-86/pci-ids.txt` | misura parziale | 25G342 | sì | `456646eb…` | 16 Nov 02:45 | nessun `7340`; inutilizzabile per GPU |
| `References/.../pci-tree-two-roots.txt` | fixture | Mac Pro A2X | sì | — | — | non MBP16,1; nessun AMD |

---

## 6. Audit delle affermazioni

### 6.1 PCI `1002:7340`

- **25G342:** `phase0` → `Device ID: 0x7340`, vendor `0x1002`. **MISURATO**.
- **26B131:** nessun output. **UNPROVEN**.
- **`IOPCIDevice`:** nessun dump completo; lo snippet `pci-ids` non contiene `7340`.

### 6.2 Revision `0x0043`

- **25G342:** `phase0` → `Revision ID: 0x0043`. **MISURATO**.
- **26B131:** nessun output. **UNPROVEN**.

### 6.3 VBIOS `113-D32207P1-019` e ROM `113-D3220E-190`

- **25G342:** `phase0` → `VBIOS Version` e `ROM Revision`. **MISURATI**.
- **26B131:** nessun output. **UNPROVEN**.
- HAO-69 dice “LETTO dalla nostra macchina”; HAO-86 fornisce l’output che lo conferma **per 25G342**, non per 26B131.

### 6.4 Subsystem `106b:0210`

Questa è l’affermazione più problematica:

| Fonte | Affermazione | Output grezzo |
|---|---|---|
| T25 | “subsystem **non verificato localmente**; nessun `ioreg`” | nessuno |
| HAO-69 | “revision 0x43, subsystem 106b:0210 — **LETTO** dalla nostra macchina — dump hardware” | **nessuno** |
| HAO-71 | ripete `subsystem 106b:0210` | **nessuno** |
| HAO-86 | “subsystem **non letto** con `system_profiler SPPCIDataType`; resta da verificare con `ioreg`” | **nessuno** |

**Verdetto:** `106b:0210` è **UNVERIFIED**. La dichiarazione HAO-69 non è supportata da un output; HAO-86 la contraddice esplicitamente. Non va usata come prova di identità board.

### 6.5 iGPU `8086:3e9b`

- **25G342:** `phase0` → `Intel UHD Graphics 630`, `Device ID: 0x3e9b`. **MISURATO**.
- **26B131:** nessun output. **UNPROVEN**.

### 6.6 gMux e display interno

- **25G342:** `phase0` → `gMux Version: 5.0.0`; Color LCD 3072×1920, `Connection Type: Internal`, sotto Radeon. **MISURATO**.
- **26B131:** nessun output. **UNPROVEN**.

---

## 7. Provenienza, timestamp, SHA

- `HAO-86` è datato **2026-11-16T01:45:21Z** nel proprio manifest; `phase0` mtime 02:41:44, `phase1` 02:42:12, `pci-ids` 02:45:14.
- Il manifest HAO-86 contiene gli SHA dei file; `phase0`, `phase1` e `pci-ids` sono coerenti con i valori sopra.
- `T25`, `T26`, `HAO-68/69/71` sono documenti senza output grezzi; i loro SHA identificano il **documento**, non una misura.
- Non esiste un hash di un dump `ioreg`/`system_profiler` **26B131**: non c’è nulla da verificare.
- Il seriale/UDID della macchina NON viene riportato in questo report.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Esiste una misura hardware locale del MacBookPro16,1? | **SÌ, parziale: HAO-86 / 25G342** |
| Esiste una misura del target 26B131? | **NO** |
| `1002:7340` è verificato? | **SÌ su 25G342; NO su 26B131** |
| Rev `0043`, VBIOS, ROM sono verificati? | **SÌ su 25G342; NO su 26B131** |
| Subsystem `106b:0210` è verificato? | **NO**; dichiarato senza output, contraddetto da HAO-86 |
| iGPU `8086:3e9b` è verificata? | **SÌ su 25G342; NO su 26B131** |
| Display interno/gMux sono verificati? | **SÌ su 25G342; NO su 26B131** |
| macOS 27.2.1 riconosce la GPU? | **UNPROVEN** |

**Impatto:** E (display), G (WindowServer) e H (desktop) restano **BLOCKED** sul target. La baseline 25G342 dimostra che l’hardware è funzionante con i driver corretti, ma non che 26B131 lo enumera o lo inizializzi.

**STOP rispettato:** sola lettura; nessun `ioreg`/`system_profiler`/`gfxutil`/`acpidump` eseguito, nessun boot, nessuna modifica EFI/ACPI. Spazio libero 12.920.044 KiB (12,32 GiB) > 10 GiB.
