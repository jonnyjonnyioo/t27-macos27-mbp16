# T27 — AGENT-AMD — EXTERNAL RESEARCH 150

**Scope:** cercare soluzioni AMD/X6000 funzionanti su macOS 26/27; analizzare RembrandtGfx, Radeonized, NootRX e AMDRadeonRembrandtHook; ricostruire i punti di controllo per pubblicazione Interface, attivazione HWServices e caricamento HWLibs; confrontarli con i report T27 121–149.

**Modalità:** sola ricerca read-only su web, GitHub API, raw.githubusercontent e curl; nessun clone, build, boot, trace, installazione, modifica EFI/NVRAM/T2/SIP/AMFI o download >2 GiB. Nessuna modifica a T16–T26.

**Esito:** **NESSUNA SOLUZIONE DIRETTA VERIFICATA PER NAVI dGPU SU macOS 26/27**. I progetti funzionanti/experimentali trovati sono per **Rembrandt APU** (680M/660M), non per la Navi 14 di MacBookPro16,1. NootRX è l'unico progetto dGPU maturo, ma copre Navi 21/22/23 e non Navi 14/24/3x. Il contributo più utile è **Radeonized**: documenta la race `HWServices`/`HWLibs`, il fallimento di `createHWInterface` con `deviceTypeTable` non patchato e la soluzione “HWLibs-first, accelerator-last”. T27 resta **OPEN**.

---

## 1. Metodo e criteri

| Voce | Valore |
|---|---|
| Data | 2026-11-17 |
| Fonti | GitHub API, raw source, README, issue, commit |
| Progetti richiesti | RembrandtGfx, Radeonized, NootRX, AMDRadeonRembrandtHook |
| Criterio “funzionante” | boot reale + Metal/desktop documentato, non solo codice |
| Criterio “dGPU Navi” | GPU discreta Navi, non iGPU Rembrandt |
| Runtime T27 | **non osservato** |

**PROVEN:** le fonti sono pubbliche e i commit sono citati.
**PROVEN:** non è stata eseguita alcuna modifica al sistema.

---

## 2. Risposta breve

| Domanda | Risposta |
|---|---|
| Soluzione Navi dGPU macOS 26/27 verificata | **NO** |
| Rembrandt APU macOS 26/27 funzionante | **SÌ**, 680M/660M |
| NootRX per Navi 14 | **NO** |
| NootRX per Navi 21/22/23 | **SÌ**, con limiti |
| Progetto più vicino al problema T27 | **Radeonized** |
| Punto di controllo esterno | **HWServices + HWLibs**, non `0x1016E` |
| T27 GO? | **NO — OPEN** |

**FINDING:** non è stata trovata una prova esterna di una Navi 14 dGPU accelerata su macOS 26/27.
**PROVEN:** esistono prove di Rembrandt APU su Tahoe 26.7.x.

---

## 3. Fonti e commit

| Progetto | URL | Commit/versione | Data |
|---|---|---|---|
| Radeonized | `https://github.com/FranciumOS-org/Radeonized` | `e86b986d20fe84224473075ac3e62fb0809b364f` | 2026-11-15 |
| RembrandtGfx upstream | `https://github.com/caoshiyuan0211-blip/winmax2-2022-6800u-hackintosh` | `a114bdef1d48ecf7a4672d29097af3d91eb3ff80` | 2026-11-01 |
| Radeon 680M fork | `https://github.com/wzh4869/Radeon-680M-Hackintosh` | `a34b37d2839dff3223315188dad7851ca58060d7` | 2026-11-11 |
| M8 660M build | `https://github.com/youngminz/m8-hackintosh` | `8f31f63a7b0b6bb3296752064096d30498df7f47` | 2026-11-11 |
| AMDRadeonRembrandtHook | `https://github.com/SaKongA/AMDRadeonRembrandtHook` | `d99e1d75bbb8fb09de671a839ace415435df8444` | 2026-11-17 |
| NootRX | `https://github.com/ChefKissInc/NootRX` | `a65f2d6128af33af86ba58ddc5c609d635ab4fa6` | 2026-10-10 |
| NootRX sito | `https://chefkiss.dev/applehax/nootrx` | — | consultato 2026-11-17 |

**PROVEN:** i commit sono quelli restituiti dall'API GitHub.
**PROVEN:** Radeonized e AMDRadeonRembrandtHook sono stati aggiornati pochi giorni prima della ricerca.

---

## 4. Radeonized

### 4.1 Stato dichiarato

| Elemento | Evidenza |
|---|---|
| Hardware | Ryzen 7 7735HS, Radeon 680M |
| macOS | Tahoe 26.7 |
| Metal | **funzionante**, Metal 3, ~22k Geekbench |
| Pannello interno | **funzionante**, `RBAMDFramebuffer` |
| OpenGL | **funzionante** |
| USB-C DP | **non funzionante** |
| Stato | APU Rembrandt, **non dGPU Navi** |

**PROVEN:** Radeonized dichiara e documenta Tahoe 26.7 su 680M.
**PROVEN:** non è una soluzione per MacBookPro16,1/Navi 14.

### 4.2 Race HWServices / HWLibs

Il README riporta, testualmente, un difetto aperto:

> “The accelerator races HWLibs, and the margin is ~3 ms. HWServices starts two children asynchronously — HWLibs, by IOKit matching, and the accelerator, internally — and the accelerator's `createHWInterface` needs a patch this plugin applies to HWLibs once it is loaded. Three archived good boots win that race by 2.5, 2.6 and 3.6 ms.”

E ancora:

> “Dropping the firmware images … moves the margin to −67.8 ms: three consecutive boots came up unaccelerated, with the patch landing 68 ms after the accelerator had given up.”

**PROVEN:** Radeonized misura la race e il fallimento di `createHWInterface`.
**PROVEN:** la patch a HWLibs deve precedere l'acceleratore.
**PROVEN:** la tempistica è marginale (2,5–3,6 ms).
**UNPROVEN:** che la stessa race esista identica su Navi 14.

### 4.3 File e funzioni

| Meccanismo | File/funzione | Evidenza |
|---|---|---|
| Personalità HWServices | `src/plugin/Info.plist`, “RembrandtGPU HWServices (0x1681)” | match `com.apple.kext.AMDRadeonX6000HWServices`, `AMDRadeonX6000_AMDRadeonHWServicesNavi`; `LoadHWServices` |
| Pubblicazione HWServices | `src/plugin/RembrandtGPUPeer.cpp`, `RBGPULoad`, `LoadHWServices` | proprietà sul nodo PCI |
| Patch HWLibs | `src/plugin/kern_start.cpp`, `processHWLibs` | `__ZL15deviceTypeTable`, `patchDeviceTypeTable` |
| Segnale patch | `src/plugin/kern_start.cpp`, `g_rb_hwlibs_patched` | impostato **all'ultima riga** di `processHWLibs` |
| Gate acceleratore | `src/plugin/RembrandtGPUPeer.cpp`, `rbgpu_hwlibs_gate_arm`, `rbgpu_hwlibs_gate_publish` | attende HWLibs, poi pubblica `LoadAccelerator` |
| Rematch | stessa funzione | `setProperty("LoadAccelerator")` + `registerService()` |
| HWServices | `src/plugin/kern_start.cpp`, `processHWServices` | **solo monitor**, non patch |

**PROVEN:** `processHWLibs` patcha `__ZL15deviceTypeTable` e segnala il completamento.
**PROVEN:** il gate pubblica `LoadAccelerator` solo dopo il segnale.
**PROVEN:** `registerService()` è necessario quando il matching è già concluso.
**PROVEN:** `processHWServices` non applica patch; HWServices serve a far caricare HWLibs via IOKit.

### 4.4 Perché è rilevante per T27

| Elemento T27 | Equivalente Radeonized |
|---|---|
| Pubblicazione Interface | `createHWInterface` dell'acceleratore |
| HWServices attivo | personalità HWServices + `LoadHWServices` |
| HWLibs non caricato/patchato | `deviceTypeTable` non patchato |
| Acceleratore parte troppo presto | gate `LoadAccelerator` |
| Race di pochi ms | 2,5–3,6 ms misurati |

**PROVEN:** la sequenza esterna è direttamente confrontabile con il problema T27.
**UNPROVEN:** la corrispondenza esatta delle classi/funzioni sul target.

---

## 5. RembrandtGfx e build Tahoe

### 5.1 Upstream

| Elemento | Valore |
|---|---|
| Repo | `caoshiyuan0211-blip/winmax2-2022-6800u-hackintosh` |
| Commit | `a114bde` (2026-11-01) |
| Sorgente | `src/RembrandtGfx` |
| Target | Rembrandt 6800U/680M |
| Licenza | GPL-2.0 |

**PROVEN:** RembrandtGfx è la base dichiarata di wzh4869 e youngminz.

### 5.2 Meccanismo di ordinamento

| File/funzione | Comportamento |
|---|---|
| `kern_start.cpp`, `processHWLibs` | hook su TTL/PSP/SMU/GC di HWLibs |
| `kern_start.cpp`, `wrapOSKextStart` | chiama `scanKmods()` **prima** di `OSKext::start` |
| `kern_start.cpp`, commento | “scan the kmod list for HWLibs before any kext starts” |
| `kern_start.cpp`, `wrapMessageAccelerator` | attende che l'acceleratore esista, fino a 20 s |
| `kern_start.cpp`, `routePciDevid` | spoof del device ID `1681 → 73ff` |
| `kern_start.cpp`, `kexts[]` | watcher HWLibs, Framebuffer, Accelerator |

**PROVEN:** il patch HWLibs viene installato prima dello start dei kext.
**PROVEN:** il framebuffer attende l'acceleratore invece di inviare PPLIB troppo presto.
**PROVEN:** il device ID viene presentato come Navi 23.
**UNPROVEN:** che il pre-scan da solo elimini la race su un dGPU.

### 5.3 Prove Tahoe

| Build | Hardware | macOS | Risultato |
|---|---|---|---|
| wzh4869 | RedmiBook Pro 14 2022, 680M | Tahoe 26.7.2 / 25G332 | Metal, desktop 2560×1600 120 Hz |
| youngminz | GMKtec M8, 660M | Tahoe 26.7.3 / 25G342 | Metal, 4K USB-C, H.264/HEVC/AV1/VP9 |
| Radeonized | 7735HS, 680M | Tahoe 26.7 | Metal, pannello, OpenGL |

**PROVEN:** tre implementazioni Rembrandt APU raggiungono un desktop accelerato su Tahoe 26.7.x.
**PROVEN:** non sono Navi dGPU e non validano MacBookPro16,1.

---

## 6. AMDRadeonRembrandtHook

### 6.1 Stato

| Elemento | Valore |
|---|---|
| Tipo | Lilu plugin, Rembrandt iGPU |
| PCI ID | `1002:1681`, `1002:164d` |
| macOS dichiarato | Big Sur–Tahoe |
| Metal | osservato su Ryzen 7 6800HS |
| Stato | **experimental** |
| Issue aperta | #1 “Black Screen after boot menu”, 2026-11-17 |

**PROVEN:** il progetto è sperimentale e non garantisce tutti i modelli.
**PROVEN:** esiste un'issue aperta di schermo nero.
**PROVEN:** non è una soluzione Navi dGPU.

### 6.2 Meccanismo di matching

| File/funzione | Comportamento |
|---|---|
| `src/Hooks/Kernel/DriverMatchingHooks.cpp` | hook `IOCatalogue::addDrivers` |
| stessa | aggiunge `0x16811002 0x164d1002` a `IOPCIMatch` |
| stessa | target: `AmdGpuWrangler`, `AmdRadeonControllerNavi23`, `AMDNavi23GraphicsAccelerator`, `AMDRadeonHWServicesNavi` |
| `src/Hooks/Kernel/KextLoadHooks.cpp` | hook `OSKext::start` |
| stessa | `scanLoadedKexts()` **prima** dello start originale |
| stessa | installa `installHwLibsHooks` quando vede HWLibs |
| `src/Hooks/Kexts/.../HWLibsHooks.cpp` | patch GC version `0xa0303 → 0xa0304`, golden registers |

**PROVEN:** il progetto inietta gli ID a livello di catalogo IOKit.
**PROVEN:** installa gli hook HWLibs prima dello start.
**PROVEN:** non usa un gate `LoadAccelerator` esplicito.
**PROVEN:** non patcha `createHWInterface` direttamente.
**UNPROVEN:** sufficiente per evitare la race su un dGPU.

---

## 7. NootRX

### 7.1 Supporto

| GPU | macOS | Stato |
|---|---|---|
| Navi 21 | macOS 11+ | supportata |
| Navi 22 | macOS 12+ | supportata |
| Navi 23 | macOS 12+ | supportata |
| Navi 24 | — | “coming soon”, issue #45 aperta |
| Navi 3x | — | issue #144 aperta, non supportata |
| Navi 40+ | — | issue #129 aperta |

**PROVEN:** NootRX non copre Navi 14.
**PROVEN:** non copre Navi 24/3x/40x.
**UNPROVEN:** supporto macOS 26/27 per Navi 21/22/23; il sito dichiara macOS 11+, non Tahoe.

### 7.2 Meccanismo

| File/funzione | Comportamento |
|---|---|
| `NootRX/HWLibs.cpp`, `processKext` | intercetta `AMDRadeonX6000HWServices` |
| stessa | route `AMDRadeonX6000_AMDRadeonHWServicesNavi::getMatchProperty` |
| stessa | `wrapGetMatchProperty` restituisce `Load6800` o `Load6810` |
| stessa | intercetta `AMDRadeonX6800HWLibs`/`X6810HWLibs` |
| stessa | risolve `__ZL15deviceTypeTable`, `CAIL_ASIC_CAPS_TABLE`, `_DeviceCapabilityTbl` |
| stessa | scrive il device ID nella tabella |
| stessa | patch PSP/SMU/GC |

**PROVEN:** NootRX usa **getMatchProperty** per attivare la personalità HWLibs corretta.
**PROVEN:** patcha `deviceTypeTable` e le tabelle ASIC.
**PROVEN:** è un'implementazione dGPU, non APU.
**UNPROVEN:** applicabilità a Navi 14; le tabelle e la classe possono differire.

---

## 8. Matrice di confronto

| Progetto | Target | macOS 26/27 | HWServices | HWLibs | Interface/`createHWInterface` | Ordinamento |
|---|---|---|---|---|---|---|
| Radeonized | Rembrandt APU | **SÌ**, 26.7 | personalità + `LoadHWServices` | `deviceTypeTable` patch | **race documentata** | gate `LoadAccelerator` |
| RembrandtGfx | Rembrandt APU | **SÌ**, 26.7.x | watcher | hook TTL/PSP/SMU/GC | attesa acceleratore | `OSKext::start` pre-scan |
| AMDRadeonRembrandtHook | Rembrandt APU | dichiarato, non garantito | `IOCatalogue::addDrivers` | GC/golden hooks | non trattata | `OSKext::start` pre-scan |
| NootRX | Navi 21/22/23 dGPU | non verificato | `getMatchProperty` | `deviceTypeTable` patch | non trattata | matching IOKit |
| T27 | Navi 14 dGPU | in corso | **UNPROVEN** | **UNPROVEN** | **UNPROVEN** | **UNPROVEN** |

**PROVEN:** nessuno dei progetti esaminati copre esattamente T27.
**PROVEN:** i punti di controllo esterni sono HWServices e HWLibs.

---

## 9. Confronto con T27 121–149

| Report | Risultato | Lettura esterna |
|---|---|---|
| 140 | `enableHardware` refutato come caller Wrangler | esterno non usa quel percorso |
| 141 | `start` usa `0x1016E` | non è il percorso di matching |
| 142 | `0x1016E` è branch stub, GOT `0x241E8` | stub NX, non funzione |
| 143 | `0x9A7640` è dati NX | nessun codice eseguibile |
| 144 | cluster NX ricorrente | categoria, non Interface |
| 145 | fixup rebase-only | NX resta NX |
| 146 | binari coerenti | analisi valida |
| 147 | 708 NX, 24 stub, 107 callsite | `0x1016E` su 3 |
| 148 | ritorno usato come oggetto | non callback |
| 149 | X6000/initializePM duplicato | percorso PM/hibernation |

### 9.1 Cosa cambia

| Ipotesi T27 | Evidenza esterna | Stato |
|---|---|---|
| `0x1016E` è il punto di pubblicazione Interface | nei sorgenti esaminati non compare un percorso equivalente; i punti sono HWServices/HWLibs | **indebolita** |
| `AMDFramebuffer::start` è il caller critico | Radeonized parla di `createHWInterface` dell'acceleratore | **non dimostrata** |
| Il problema è la race HWServices/HWLibs | Radeonized la misura e la nomina | **plausibile** |
| Il fix è patchare HWLibs prima dell'acceleratore | Radeonized/NootRX/RembrandtGfx lo fanno | **concreto** |

**PROVEN:** nessuna fonte esterna esaminata collega `0x1016E` a `createHWInterface`.
**PROVEN:** Radeonized collega esplicitamente `createHWInterface` a HWLibs non patchato.
**UNPROVEN:** che T27 abbia la stessa causa.

### 9.2 Inferenza

`0x1016E` restituisce un oggetto usato per `IOHibernateState`/PM in `AMDFramebuffer`; è un percorso di **power management**, non un factory di Interface. Il target è dati NX, quindi una chiamata diretta è staticamente implausibile. Le implementazioni esterne non hanno un equivalente di questo percorso: agiscono su **matching HWServices** e **tabelle HWLibs**. Per T27 è quindi più produttivo verificare `createHWInterface`, `deviceTypeTable` e `LoadAccelerator` che continuare a inseguire `0x1016E`.

**PROVEN:** `0x1016E` è usato come oggetto PM.
**PROVEN:** il target è NX.
**INFERENZA:** non è il punto di pubblicazione Interface.
**UNPROVEN:** la causa reale del fallimento T27.

---

## 10. Strategia concreta alternativa

### S1 — HWLibs-first, accelerator-last (raccomandata)

**Modello:** Radeonized.

| Passo | Azione | Riferimento |
|---:|---|---|
| 1 | Attivare HWServices con `LoadHWServices`/personalità corretta | `Info.plist`, `RembrandtGPUPeer.cpp` |
| 2 | Lasciare che HWLibs venga caricato da IOKit | `processHWServices` |
| 3 | Patchare `__ZL15deviceTypeTable` e le tabelle ASIC per il device target | `processHWLibs`, `patchDeviceTypeTable` |
| 4 | Segnare `hwlibs_patched` solo a fine patch | `g_rb_hwlibs_patched` |
| 5 | Non pubblicare `LoadAccelerator` prima del segnale | `rbgpu_hwlibs_gate_arm` |
| 6 | Pubblicare `LoadAccelerator` e chiamare `registerService()` se il matching è già concluso | `rbgpu_hwlibs_gate_publish` |
| 7 | Solo allora l'acceleratore esegue `createHWInterface` con HWLibs patchato | `createHWInterface` |

**PROVEN:** Radeonized usa questa sequenza su Rembrandt.
**PROVEN:** la race misurata è 2,5–3,6 ms.
**PROVEN:** il fallimento a −67,8 ms è attribuito alla patch in ritardo.
**UNPROVEN:** il comportamento su Navi 14.

### S1 — Modifiche teoriche per T27

| File/componente teorico | Modifica |
|---|---|
| `T27/HWLibsGate.cpp` | gate `LoadAccelerator` su `hwlibs_patched` |
| `T27/DriverMatch.cpp` | personalità HWServices / `getMatchProperty` |
| `T27/HWLibsPatch.cpp` | patch `__ZL15deviceTypeTable` e ASIC caps per Navi 14 |
| `T27/Info.plist` | match `AMDRadeonX6000HWServices`, `...HWServicesNavi` |
| `T27/AcceleratorHook.cpp` | osservare `createHWInterface`, non chiamare `0x1016E` |

**Nota:** nomi teorici; nessun file è stato creato o modificato.

### S1 — Verifica statica prima di qualsiasi boot

| Controllo | Comando read-only |
|---|---|
| Simbolo tabella | `nm -arch x86_64 .../AMDRadeonX6000HWLibs | grep deviceTypeTable` |
| Simbolo matching | `nm ... | grep HWServicesNavi` |
| Simbolo Interface | `nm .../AMDRadeonX6000 | grep -i createHWInterface` |
| Proprietà | `strings ... | grep -E 'LoadAccelerator|LoadHWServices|Load6800|Load6810'` |
| Offsets | `otool -tvV` sul target, confronto con report 149 |

**PROVEN:** questi controlli sono statici e read-only.
**UNPROVEN:** l'esito sul binario T27; da eseguire nel prossimo prompt.

### S2 — NootRX-style matching

| Passo | Azione |
|---:|---|
| 1 | Route `AMDRadeonHWServicesNavi::getMatchProperty` |
| 2 | Restituire la proprietà `Load...` corretta per Navi 14 |
| 3 | Patchare `deviceTypeTable` e ASIC caps |
| 4 | Lasciare che IOKit avvii HWLibs e l'acceleratore |

**PROVEN:** NootRX usa `getMatchProperty` e `deviceTypeTable`.
**UNPROVEN:** Navi 14 usa la stessa classe/property.

### S3 — IOCatalogue + OSKext pre-start

| Passo | Azione |
|---:|---|
| 1 | Hook `IOCatalogue::addDrivers` |
| 2 | Aggiungere il device ID a Wrangler/Controller, Accelerator, HWServices |
| 3 | Hook `OSKext::start` |
| 4 | Scansionare `_kmod` e installare gli hook HWLibs prima dello start |

**PROVEN:** AMDRadeonRembrandtHook e RembrandtGfx usano questo schema.
**PROVEN:** è più semplice del gate.
**UNPROVEN:** non elimina da solo la race `createHWInterface`.

---

## 11. Limiti

| Limite | Conseguenza |
|---|---|
| Nessuna soluzione Navi dGPU 26/27 | T27 non ha una ricetta verificata |
| Rembrandt APU ≠ Navi 14 | classi/tabelle possono differire |
| NootRX non copre Navi 14 | richiede port e nuove tabelle |
| NootRX non valida Tahoe | supporto 26/27 non provato |
| Radeonized è APU | la race è analoga, non identica |
| Nessun runtime T27 | tutto resta statico |
| `0x1016E` target NX | chiamata diretta implausibile |

**PROVEN:** i limiti sono espliciti nelle fonti o derivano dai report T27.
**UNPROVEN:** qualsiasi risultato di boot T27.

---

## 12. Decisione

| Domanda | Risposta |
|---|---|
| Soluzione esterna pronta per T27 | **NO** |
| Strategia esterna concreta | **S1: HWLibs-first, accelerator-last** |
| Seconda strategia | **S2: getMatchProperty + table patch** |
| Terza strategia | **S3: IOCatalogue + OSKext pre-start** |
| `0x1016E` da inseguire | **NO**, priorità bassa |
| T27 | **OPEN** |
| Percentuali | **94% engineering / 32% first boot / 8% desktop** |

**Raccomandazione:** il prossimo passo statico deve cercare `__ZL15deviceTypeTable`, `AMDRadeonHWServicesNavi::getMatchProperty`, `createHWInterface` e `LoadAccelerator` nel SystemKC/AMDSupport, non nuove chiamate a `0x1016E`. Solo dopo la verifica dei simboli si può decidere se S1 è portabile a Navi 14. Nessun boot o modifica senza autorizzazione.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto.

**STOP rispettato:** sola ricerca read-only; nessun boot/trace/modifica/build/installazione; nessuna modifica a T16–T26; T27 **OPEN**.
