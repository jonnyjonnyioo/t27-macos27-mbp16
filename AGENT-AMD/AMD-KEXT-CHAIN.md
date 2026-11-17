# T27 — AGENT-AMD — AMD NAVI14 KEXT CHAIN

**Scope:** catena AMD realmente caricata su macOS **26.7.3 / 25G342**, confronto con i sette kext Navi14 root2 (+ `X6100HWLibs` annidato), X6000 root3 e ricerca di equivalenti in **26B131**.  
**Modalità:** sola lettura; nessun caricamento, modifica, boot o installazione.  
**Esito:** la catena **misurata** su 25G342 contiene **6 kext** e usa `AMDRadeonX6100HWLibs`, non `AMDRadeonX6000HWLibs`. Root2 contiene **entrambi** gli HWLibs (X6100 annidato in HWServices), ma non è mai stato caricato e usa versioni 7.1.8; root3 ha un solo componente; 26B131 ha **0** componenti AMD. Nessun equivalente target.

---

## 1. Catena misurata su 25G342

Fonte grezza: `<SESSION>/evidence/phase1-drivers.txt`  
SHA-256: `59de359db3f3fc638b825de2b1eb70c04ffee62b86036f4ae7e5304570d88ecb`  
mtime: 16 Nov 2026 02:42:12  
Comando dichiarato: `kmutil showloaded` (output in formato `kextstat`).

| # indice | Bundle identifier | Versione | UUID | Loaded size | Dipendenze (indici) |
|---:|---|---|---|---:|---|
| 147 | `com.apple.kext.AMDSupport` | 7.0.1 | `736ECBBA-C9C9-3AF7-BE6A-EB1944DB515B` | `0xc52a0` | `<121 120 19 17 9 7 6 3 1>` |
| 148 | `com.apple.kext.AMDRadeonX6000Framebuffer` | 7.0.1 | `F527F501-CD46-34D0-AEB3-C8E5C8ADF2C8` | `0x289ad8` | `<121 120 19 17 9 7 6 3 1>` |
| 179 | `com.apple.kext.AMDRadeonX6000HWServices` | 7.0.1 | `4A753C5A-7010-390E-B234-0DB2765A37E9` | `0x23cb` | `<120 19 17 9 7 6 3 1>` |
| 180 | `com.apple.kext.AMDRadeonServiceManager` | 7.0.1 | `53316747-531F-3003-97A7-4B51226A731D` | `0x2ec8` | `<19 6 3 1>` |
| 181 | `com.apple.kext.AMDRadeonX6100HWLibs` | 1.0 | `533D1262-BE83-3507-B48A-FDB91C9D8793` | `0x3adb28` | `<19 7 6 3 1>` |
| 185 | `com.apple.kext.AMDRadeonX6000` | 7.0.1 | `1540D089-EE2D-3339-B5A8-2024F9E38581` | `0x1560d8` | `<122 120 97 19 9 7 6 3 1>` |

**Totale: 6.**

`Loaded size` è la dimensione riportata dal registro caricato, non il numero di byte del file su disco: non va confrontata direttamente con i byte dei bundle root2.

### 1.1 Ordine

L’unico ordine registrato è quello degli **indici**:

```text
AMDSupport (147)
→ X6000Framebuffer (148)
→ X6000HWServices (179)
→ ServiceManager (180)
→ X6100HWLibs (181)
→ X6000 (185)
```

Gli indici sono assegnati dal kernel al caricamento e sono coerenti con una sequenza reale, ma **non esiste un log temporale di caricamento**. Classificazione: **MEASURED (index order)**; l’ordine degli eventi nel boot resta **UNPROVEN**.

### 1.2 Dipendenze

Mappatura certa dallo stesso output:

| Indice | Nome | Stato |
|---:|---|---|
| 19 | `IOPCIFamily` | presente nell’output Intel/AMD |
| 120 | `IOGraphicsFamily` | presente nell’output Intel/AMD |
| 121, 122, 97 | non nominati in `phase1` | **UNMAPPED** |
| 9, 7, 6, 3, 1 | KPI/kernel pseudo-kext | **UNMAPPED** (non servono per il confronto) |

Le dipendenze **dichiarate** nei bundle root2 sono più informative dei soli indici: `IOAcceleratorFamily2`, `IOGraphicsFamily`, `IOPCIFamily`, `IOSurface`, `AppleGraphicsDeviceControl`, `IOACPIFamily`. La catena misurata conferma che `X6000` dipende da un `HWLibs` (indice 181) e da `IOGraphicsFamily`/`IOPCIFamily`; non conferma la mappatura di 121/122/97.

---

## 2. Confronto con root2 (sette kext Navi14)

Root2: `25G325 / 7.1.8`, x86_64: **7 bundle top-level + `X6100HWLibs` annidato** in `X6000HWServices` (8 bundle AMD totali).

| Root2 bundle | Versione | UUID | File bytes | Presente nella catena 25G342? |
|---|---|---|---:|---|
| `AMDSupport.kext` | 7.1.8 | `736ECBBA-…` | 2.104.464 | **SÌ**, ma versione 7.0.1 |
| `AMDFramebuffer.kext` | 7.1.8 | `2723D92D-…` | 312.576 | **NO** |
| `AMDRadeonServiceManager.kext` | 7.1.8 | `53316747-…` | 90.352 | **SÌ**, ma versione 7.0.1 |
| `AMDRadeonX6000HWServices.kext` | 7.1.8 | `4A753C5A-…` | 92.592 | **SÌ**, ma versione 7.0.1 |
| `AMDRadeonX6000Framebuffer.kext` | 7.1.8 | `F527F501-…` | 3.706.208 | **SÌ**, ma versione 7.0.1 |
| `AMDRadeonX6000HWLibs.kext` | 1.0 | `5CD4BC0C-…` | 29.233.952 | **NO** |
| `AMDRadeonX6100HWLibs.kext` (nested) | 1.0 | `533D1262-…` | 17.256.336 | **SÌ**, versione 1.0 |
| `AMDRadeonX6000.kext` | 7.1.8 | `1540D089-…` | 2.379.536 | **SÌ**, ma versione 7.0.1 |

### 2.1 Le differenze decisive

1. **`AMDRadeonX6100HWLibs` È presente in root2**, annidato in `X6000HWServices.kext/Contents/PlugIns/`, 17.256.336 B, UUID `533D1262-BE83-3507-B48A-FDB91C9D8793`, x86_64. La catena misurata usa proprio questo componente. La correzione rispetto alla prima versione di questo report è necessaria: non manca in root2.
2. **Root2 contiene anche `X6000HWLibs`** 1.0 (`5CD4BC0C…`, 29.233.952 B), che **non è caricato** su 25G342. I due HWLibs hanno UUID, nome e dimensione diversi: **non sono equivalenti**.
3. **Versioni diverse.** La macchina 25G342 carica la famiglia **7.0.1**; root2 dichiara **7.1.8** per i cinque kext principali, mentre X6100HWLibs è 1.0 in entrambi. Stessi UUID per X6000/Framebuffer/HWServices/Support/ServiceManager, ma **hash e dimensioni diversi**. UUID uguale non significa binario identico.
4. **`AMDFramebuffer`** è presente in root2 ma **non** nella catena caricata su 25G342.

`AMDFramebuffer` è presente in root2 ma **non** nella catena caricata su 25G342. Non è un errore: può essere un bundle non necessario per questa GPU/percorso.

### 2.2 Ordine topologico dichiarato vs ordine misurato

HAO-68 calcolò l’ordine topologico per la EFI:

```text
AMDSupport → AMDFramebuffer → AMDRadeonServiceManager
→ AMDRadeonX6000 → X6000Framebuffer → X6000HWServices
```

L’ordine misurato su 25G342 è diverso:

```text
AMDSupport → X6000Framebuffer → X6000HWServices
→ ServiceManager → X6100HWLibs → X6000
```

**Conclusione:** l’ordine topologico della EFI **non** è una prova dell’ordine di caricamento reale; il set root2 non è stato caricato su 25G342 in quella forma. La catena misurata è la riferimento per 25G342.

---

## 3. Root3 e target

| Fonte | Componenti AMD | Catena completa? |
|---|---|---|
| root3 `25G342/26B116` | 5/6 esatti: `AMDSupport`, `X6000Framebuffer`, `X6000HWServices`, `ServiceManager`, `X6000`; `X6100HWLibs` assente | **QUASI**: 5/6, manca X6100 |
| target 26B131 | **0** bundle AMD/ATI | **NO** |
| KDK 26B131 | **0** bundle AMD/ATI | **NO** |

Root3 X6000 ha lo stesso UUID di root2 ma hash diverso; **è invece identico a `systemkc-all` X6000** (`2734aaf7…`). Root3 fornisce 5/6 binari esatti; `X6100HWLibs` è assente. Root2 resta 0/6 esatti.

### 3.1 Ricerca equivalenti 26B131

| Ricerca | Esito |
|---|---|
| `AMD*` / `*Radeon*` in target Extensions | **0** |
| `AMDRadeonX6000`, `AMDSupport`, `AMDFramebuffer`, `ServiceManager` | **0** |
| `AMDRadeonX6100HWLibs` / `X6000HWLibs` | **0** |
| `Metal.framework` / `IOAccelerator.framework` binari attesi | **ASSENTI** |
| `AMDRadeonX6000MTLDriver` 26B131 | **ASSENTE** |
| sostituto AMD generico | **NESSUNO** |

Il catalogo framework non è un runtime. Non esiste una catena alternativa.

---

## 4. Matching PCI e percorso grafico

| Elemento | 25G342 | 26B131 |
|---|---|---|
| PCI GPU | `1002:7340`, rev `0043` (`phase0`) | **nessun output** |
| Matching nei kext | `0x73401002` in `AMDNavi14GraphicsAccelerator` | **0 kext AMD** |
| Display interno | Color LCD 3072×1920 sotto Radeon (`phase0`) | **nessun output** |
| Percorso eDP/gMux | gMux 5.0.0 dichiarato dal sistema | **UNPROVEN** |
| Metal | compute reale su Radeon (`HAO-86`) | **ASSENTE** |

Il matching PCI è **DOCUMENTED** nei metadati root2 e **MEASURED** su 25G342 tramite `system_profiler`; non è **MEASURED** su 26B131.

---

## 5. Classificazione

| Classe | Componenti | Prova |
|---|---|---|
| **MEASURED** | 6 kext caricati su 25G342 | `phase1`; GPU e display reali |
| **DOCUMENTED** | matching PCI e dipendenze dichiarate root2 | Info.plist e metadati |
| **UNPROVEN** | sette root2 + X6000 root3; ordine eventi; ABI | nessun caricamento 26B131 |
| **ABSENT** | tutta la catena AMD in 26B131/KDK | 0 bundle |

---

## 6. Conclusione

1. La catena **funzionante** su 25G342 è di **6 kext**, con `X6100HWLibs` e **senza** `AMDFramebuffer`.
2. Root2 contiene **tutti e 6** i componenti della catena (incluso X6100HWLibs annidato), più `AMDFramebuffer` e `X6000HWLibs`: è un **superset**, non un set mancante. Non è mai stato caricato in questa forma e usa 7.1.8 / 25G325, quindi resta **UNPROVEN**.
3. Root3 fornisce **5/6** binari esatti (tutti tranne X6100); root2 fornisce **0/6** esatti.
4. 26B131 non fornisce **nessuno** dei 6 e nessun sostituto.
5. L’ABI, la selezione X6100 vs X6000 e l’ordine degli eventi restano **UNPROVEN**; l’UUID condiviso non è una prova di compatibilità.
6. **E (display), G (WindowServer), H (desktop): BLOCKED.**

**STOP rispettato:** sola lettura; nessun caricamento, modifica, boot o installazione. Spazio libero 12.920.044 KiB (12,32 GiB) > 10 GiB.
