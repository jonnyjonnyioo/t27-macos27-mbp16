# T27 — Compatibilità donor AMD 25G342 / kernel 26B131

**Data:** 2026-11-17  
**Input:** ChatGPT, decisione (a); R-185, R-186  
**Modalità:** sola lettura; nessun boot, trace, build, download, installazione o modifica di sistema  
**Esito Fase 1–2:** **STOP condizionale** — il donor 25G342 è incompleto per `AMDRadeonX6000HWLibs`.

---

## 1. Inventario

Kernel target:

| Campo | Valore |
|---|---|
| Percorso | `<TARGET_ROOT>/System/Library/Kernels/kernel` |
| Byte | 21.128.776 |
| Arch | x86_64 |
| SHA-256 | `3c9317518535791503970fbec322b9bba70e91f3a233536205ccd77b047ffc83` |
| UUID | `037E7B86-0AC8-3C67-AFB8-7C2C86435E9A` |

Donor: `Sessions/<SESSION>/work/root-full/System/Library/Extensions` (25G342).

| Bundle | Byte | SHA-256 eseguibile | UUID | Stato |
|---|---:|---|---|---|
| `AMDSupport.kext` | 1.415.088 | `c569698b689d3822ce3f18a51202b10f46f48e395e80a339dc3bae403754f2a4` | `736ECBBA-C9C9-3AF7-BE6A-EB1944DB515B` | presente |
| `AMDFramebuffer.kext` | 234.936 | `54033d995b2d40a6440da6b0dc686c345a70ec7dd16207dae3e07d4386394e88` | `2723D92D-6032-3051-9874-A87DE97B25CB` | presente |
| `AMDRadeonServiceManager.kext` | 52.176 | `bdb566f37ce2be039e47bfb807fdc03b6d6bcd5b251eefc874916ed22b3cbf81` | `53316747-531F-3003-97A7-4B51226A731D` | presente |
| `AMDRadeonX6000.kext` | 2.090.264 | `2734aaf7bf338afb9dece81466651a0c9db3a99dc6c5930798dd1fb5da63a40b` | `1540D089-EE2D-3339-B5A8-2024F9E38581` | presente |
| `AMDRadeonX6000Framebuffer.kext` | 3.452.992 | `a2469429602210e64a74292a30b06353d9e0f75cd6b8b65f98324e64fa0b4536` | `F527F501-CD46-34D0-AEB3-C8E5C8ADF2C8` | presente |
| `AMDRadeonX6000HWServices.kext` | 55.008 | `cc7aaca45446f98cc4ea03b1fdf80b402975c1b0e0d07585a304d78dcdf797f7` | `4A753C5A-7010-390E-B234-0DB2765A37E9` | presente |
| `AMDRadeonX6000HWLibs.kext` | — | — | — | **BINARIO ASSENTE** |

`AMDRadeonX6000HWLibs.kext` contiene solo `Info.plist`, `version.plist` e `_CodeSignature/CodeResources`; **nessun `Contents/MacOS/AMDRadeonX6000HWLibs`**.

Copie alternative dello stesso binario:

```text
Sessions/<SESSION>/work/root2/System/Library/Extensions/AMDRadeonX6000HWServices.kext/Contents/PlugIns/AMDRadeonX6000HWLibs.kext/Contents/MacOS/AMDRadeonX6000HWLibs
Sessions/<SESSION>/source/kdk25-full/KDK.pkg/Payload/System/Library/Extensions/AMDRadeonX6000HWServices.kext/Contents/PlugIns/AMDRadeonX6000HWLibs.kext/Contents/MacOS/AMDRadeonX6000HWLibs

29.233.952 B
SHA-256 7d078501330fbec5cadf369ff7bb6f6ea5311a8dd021f70da17b506154074706
```

Sono build **25G325** (root2) e KDK 25G, non 25G342. Usarli nel donor 25G342 introdurrebbe un mix di build.

---

## 2. Dipendenze dichiarate e versioni target

| Dipendenza | Richiesta dai kext AMD | Target 26B131 | Esito |
|---|---|---|---|
| `IOGraphicsFamily` | 1.0.0b1 / 1.3 / 2.4.1 | 600, compatible 1.0.0b1 | minima soddisfatta |
| `IOPCIFamily` | 1.0.0b1 / 1.2 / 2.9 | 2.9, compatible 1.0.0b1 | minima soddisfatta |
| `IOAcceleratorFamily2` | 2.0.0 | 491, compatible 2.0.0 | minima soddisfatta |
| `IOSurface` | 87.0 | 403.1, compatible 1.0 | minima soddisfatta |
| `IOACPIFamily` | 1.2 / 1.4 | 1.4, compatible 1.0.0d1 | minima soddisfatta |

Le versioni minime dichiarate sono compatibili. Questo **non prova** l'ABI: le versioni `OSBundleCompatibleVersion` sono basse e non dicono nulla sui singoli simboli C++ esportati.

---

## 3. Verifica statica dei simboli

Conteggio dei simboli non definiti (`nm -u`) nei sei primari:

| Bundle | Simboli non definiti |
|---|---:|
| `AMDSupport` | 502 |
| `AMDFramebuffer` | 697 |
| `AMDRadeonServiceManager` | 320 |
| `AMDRadeonX6000` | 1.171 |
| `AMDRadeonX6000Framebuffer` | 529 |
| `AMDRadeonX6000HWServices` | 305 |

Il kernel 26B131 esporta 24.399 simboli. Il confronto diretto con il solo kernel non è conclusivo: molti simboli non definiti sono classi IOKit fornite da `IOGraphicsFamily`, `IOPCIFamily`, `IOAcceleratorFamily2` e `IOSurface`, non dal kernel. Senza estrarre e confrontare gli export completi di quei kext, la risoluzione ABI resta **UNPROVEN**.

`otool -L` non mostra dylib: le dipendenze sono dichiarate in `OSBundleLibraries`, non linkate come library dinamiche.

---

## 4. Matching Navi14

**PROVEN:** `AMDRadeonX6000.kext` e `AMDRadeonX6000Framebuffer.kext` dichiarano gli ID PCI Navi14:

```text
0x73401002 0x73411002 0x73431002 0x73471002 0x734F1002
```

`AMDRadeonX6000HWServices.kext` include gli stessi ID. La Radeon Pro 5500M è Navi14; il matching PCI è quindi presente.

**UNPROVEN:** che il driver venga caricato e che il framebuffer/pubblished display funzioni sul target 26B131.

---

## 5. Esito Fase 1–2

### PROVEN

- Kernel 26B131 x86_64 presente, SHA `3c931751…`, UUID `037E7B86…`.
- Sei primari AMD 25G342 presenti, x86_64, con SHA/UUID registrati.
- ID PCI Navi14 presenti nei bundle X6000/Framebuffer/HWServices.
- Versioni minime IOKit del target soddisfatte.
- `AMDRadeonX6000HWLibs` **assente** dal donor 25G342.

### INFERRED

- Il donor 25G342 è incompleto per la catena HWServices/HWLibs.
- La copia 25G325/KDK 25G può colmare il file, ma introdurrebbe un mix di build non autorizzato.
- La compatibilità ABI 25G342 → 26B131 non è dimostrata.

### UNPROVEN

- Risoluzione dei simboli C++ contro gli export completi di IOGraphics/IOPCI/IOAccelerator/IOSurface.
- Firme, entitlements, kext loading, runtime.
- Display interno, Metal, WindowServer.

---

## 6. Decisione

**STOP condizionale della Fase 2.** Non si passa alla Fase 3/4 (compatibility layer o caricamento) perché manca un binario del donor e l'ABI non è dimostrata.

Per proseguire serve una scelta esplicita:

1. estrarre `AMDRadeonX6000HWLibs` dalla **SystemKC 25G342** (`b4b618bf…`) e usarlo nel donor 25G342;
2. autorizzare l'uso del binario 25G325/KDK 25G (`7d078501…`) con mix di build dichiarato;
3. ottenere un donor 25G342 completo;
4. fermare la pista donor e chiudere T27.

Nessuna di queste è stata eseguita. Il presente rapporto è read-only e non autorizza un boot o un caricamento.

---

## 7. Hash

Il file `T27-DONOR-COMPAT.md` è prodotto in `AGENT-AMD`; l'hash finale è in `T27-DONOR-COMPAT.sha256`.

---

**SHA-256 del corpo (prima di questa riga):** `ffeb86cc02c6be2305c7b39869a61e8fa265991d60c2691145d9e67627c12cbd`

---

## 8. Aggiornamento — HWLibs 25G342 estratto

La SystemKC 25G342 (`b4b618bf…`) contiene `com.apple.kext.AMDRadeonX6000HWLibs`. Estrazione selettiva eseguita con:

```text
ipsw kernel extract SystemKernelExtensions.kc \
  com.apple.kext.AMDRadeonX6000HWLibs \
  --output AGENT-AMD/.tmp/t27-donor-compat
```

Risultato:

```text
.tmp/t27-donor-compat/com.apple.kext.AMDRadeonX6000HWLibs
28.865.520 B
Mach-O 64-bit kext bundle x86_64
SHA-256 a6a1040fef266bef6773b3c5df703a4e7bc8a84579d45104c5ab6b019224707f
UUID 5CD4BC0C-C225-365F-A872-C885575B9A19
nm -u: 348 simboli non definiti
```

Confronto:

| Fonte | Byte | SHA-256 | UUID |
|---|---:|---|---|
| 25G342 SystemKC (estratto) | 28.865.520 | `a6a1040f…` | `5CD4BC0C…` |
| 25G325 root2 / KDK 25G | 29.233.952 | `7d078501…` | non usato |

I due binari sono **diversi**: il 25G342 non è il 25G325. Il donor 25G342 ora è completo in `.tmp`, ma l'ABI con 26B131 resta **UNPROVEN**. Nessuna installazione, boot o modifica di sistema.

---

## 9. Decisione ChatGPT — STOP tecnico temporaneo

ChatGPT, dopo il completamento del donor 25G342, ha emesso:

> STOP — verifica ABI sospesa. I 348 simboli non definiti di HWLibs non possono essere classificati correttamente confrontandoli soltanto con il kernel target. Prima occorre disporre delle tabelle di esportazione Mach-O dei provider effettivi di macOS 27.2.1 build 26B131. Non considero i simboli IOKit automaticamente incompatibili. Non considero le dipendenze soddisfatte come prova di compatibilità ABI. Non autorizzo sostituzioni dal donor 25G342. Nessun boot, trace, build o modifica.

Verifica locale del blocco:

- `<TARGET_ROOT>/System/Library/Extensions/IOGraphicsFamily.kext`: `Contents/MacOS` assente;
- `IOPCIFamily.kext`: binario assente;
- `IOAcceleratorFamily2.kext`: binario assente;
- `IOSurface.kext`: binario assente;
- `IOACPIFamily.kext`: binario assente (solo `IOACPIFamily.exports`);
- `/Library/Developer/KDKs`: nessuna delle cinque famiglie presente.

Quindi le tabelle export dei provider 26B131 **non sono disponibili localmente**. Lo STOP di ChatGPT è coerente con i dati.

### Stato finale

- T27 resta **OPEN**; nessun GO.
- Donor 25G342 completo solo in `.tmp/t27-donor-compat`, non installato.
- Nessun boot, trace, build, download, installazione o modifica di sistema.
- Prossimo passo, se autorizzato: ottenere i binari/export dei provider 26B131 da una fonte verificata e ripetere la classificazione ABI.
