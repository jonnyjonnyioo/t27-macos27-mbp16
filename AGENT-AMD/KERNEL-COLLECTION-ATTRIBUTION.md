# T27 — AGENT-AMD — KERNEL COLLECTION ATTRIBUTION

**Scope:** determinare quali componenti AMD sono incorporati nelle Kernel Collections 25G342 e se `X6100HWLibs` è attribuibile a BootKC o SystemKC.  
**Modalità:** sola lettura; nessuna estrazione, ricostruzione KC, modifica o boot.  
**Esito:** **BootKC = 0 componenti AMD**; **SystemKC = tutti e sei i componenti AMD misurati, incluso X6100**. L’attribuzione alla **SystemKC** è **PROVEN** a livello di pool; l’origine del caricamento runtime è **INFERRED**, non PROVEN, perché `kmutil showloaded` non riporta la collezione sorgente.

---

## 1. Le due collezioni

| Collezione | Byte | SHA-256 | Kext estratte | AMD |
|---|---:|---|---:|---:|
| `BootKernelExtensions.kc` | 67.600.384 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` | 204 | **0** |
| `SystemKernelExtensions.kc` | 369.213.440 | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` | 172 | **≥ 6** |

Fonte: `<SESSION>/deliverables/TAHOE-DONOR-INTEGRATION.md`, `evidence/donor-source-kc.txt`; hash ricalcolati sui file `/System/Library/KernelCollections/…` dell’host 25G342.  
Totale pool: **376 bundle** (204 + 172).

### 1.1 Pool estratti

| Directory | File | AMD |
|---|---:|---:|
| `<SESSION>/work/tahoe-bootkc-all` | 204 | **0** |
| `<SESSION>/work/systemkc-all` | 172 | **≥ 6** |
| `<SESSION>/work/staged` | 376 | unione/overlay |

`staged` contiene 376 file e include X6100; non è una collezione: è un pool di lavoro.

---

## 2. Presenza dei sei componenti AMD

| Bundle | BootKC | SystemKC | SHA SystemKC |
|---|---:|---:|---|
| `com.apple.kext.AMDSupport` | **0** | **1** | — |
| `com.apple.kext.AMDRadeonX6000Framebuffer` | **0** | **1** | — |
| `com.apple.kext.AMDRadeonX6000HWServices` | **0** | **1** | — |
| `com.apple.kext.AMDRadeonServiceManager` | **0** | **1** | — |
| `com.apple.kext.AMDRadeonX6000` | **0** | **1** | — |
| `com.apple.kext.AMDRadeonX6100HWLibs` | **0** | **1** | `e521d3cc…` |

**Nessun bundle AMD è in BootKC.** Tutti i sei sono in `systemkc-all`.

SystemKC contiene anche altri bundle AMD non caricati/estranei alla catena: `AMDFramebuffer`, `AMDRadeonX6000HWLibs`, `X4000`, `X5000`, `X6000HWServices`, `X6100HWLibs`, `X6200`, `X6300`, `X6700`, `X6800`, `X6810`, `AMD9500Controller`, `AMD10000Controller`. La presenza di X6100 non è quindi un caso isolato: **tutto lo stack AMD sta nella SystemKC**.

---

## 3. X6100 nella SystemKC

| Dato | Valore |
|---|---|
| File | `<SESSION>/work/systemkc-all/com.apple.kext.AMDRadeonX6100HWLibs` |
| Byte | 16.985.840 |
| SHA-256 | `e521d3cce8f9bb027642897fed8754ff4d9ef66dd08a8d13ab318e0c2db01bb5` |
| Arch | x86_64 |
| UUID | `533D1262-BE83-3507-B48A-FDB91C9D8793` |
| Versione | 1.0 |
| BootKC | **assente** |
| SystemKC | **presente** |

La copia `systemkc-all` è la variante non firmata, con hash `e521d3cc…`; la copia completa root2 ha hash `00b6214e…` ed è firmata. La differenza è analizzata in `X6100HWLIBS-IDENTITY.md`.

---

## 4. Caricamento runtime

Fonte: `<SESSION>/evidence/phase1-drivers.txt` (SHA `59de359d…`, 16 Nov 02:42), `kmutil showloaded`.

Tutti e sei i componenti risultano caricati:

```text
AMDSupport 7.0.1
X6000Framebuffer 7.0.1
X6000HWServices 7.0.1
ServiceManager 7.0.1
X6100HWLibs 1.0
X6000 7.0.1
```

Il log **non riporta**:
- la collezione sorgente (BootKC o SystemKC);
- il path del file;
- lo SHA-256 del kext;
- l’indice di inclusione nella KC.

Quindi:

| Domanda | Stato |
|---|---|
| I sei kext sono caricati su 25G342? | **PROVEN** (`phase1`) |
| I sei kext sono presenti nella SystemKC? | **PROVEN** (pool systemkc-all) |
| I sei kext sono assenti dalla BootKC? | **PROVEN** (pool bootkc-all, 0 AMD) |
| Il caricamento proviene dalla SystemKC? | **INFERRED**, non PROVEN |
| Lo SHA del binario caricato è `e521d3cc…`? | **UNPROVEN** |

L’inferenza è forte: se BootKC non contiene AMD e SystemKC sì, e tutti e sei sono caricati, la sorgente più plausibile è SystemKC. Ma senza un `kmutil inspect` o un log di caricamento con path/collection, resta un’inferenza.

---

## 5. Strumenti e manifest

| Fonte | Contenuto | Esito |
|---|---|---|
| `donor-source-kc.txt` | hash completi BootKC/SystemKC | **PROVEN** |
| `TAHOE-DONOR-INTEGRATION.md` | 204 / 172, byte e hash | **PROVEN** |
| `systemkc-all` | 172 file, sei AMD | **PROVEN** (pool) |
| `tahoe-bootkc-all` | 204 file, 0 AMD | **PROVEN** (pool) |
| `SHA256-MANIFEST.txt` HAO-65 | esclude `systemkc-all`, `staged` | **nessun hash per-kext** |
| `kmutil inspect` | nessun output acquisito | **ASSENTE** |
| `kcditto` | nessun output acquisito | **ASSENTE** |
| `KernelCollection` / inclusion map | nessuna mappa per-kext | **ASSENTE** |
| `phase1` HAO-86 | sei kext caricati, solo UUID/versione | **PROVEN runtime, non sorgente** |

### 5.1 Conflitto documentale

`DARWIN27-TAHOE-COMPATIBILITY.md` afferma: “Kext non-boot (SystemKC, 369 MB) — non estratte”.  
Il pool `systemkc-all` contiene invece **172 file** ed è la fonte dei sei AMD. La frase è **superata/errata** rispetto ai file presenti; non va usata per negare l’estrazione. La prova materiale è il pool con 172 file e i sei bundle.

---

## 6. Conclusioni

| Classe | Dato |
|---|---|
| **PROVEN** | BootKC 204 kext, 0 AMD; SystemKC 172 kext, sei AMD inclusa X6100; hash delle due KC; pool `systemkc-all`/`tahoe-bootkc-all` |
| **INFERRED** | La catena AMD caricata su 25G342 proviene dalla SystemKC, non dalla BootKC |
| **UNPROVEN** | Collezione sorgente registrata dal kernel; SHA del binario caricato; identità root2/HAO-65 ↔ caricato |
| **ABSENT** | Mappa di inclusione per-kext, `kmutil inspect`, `kcditto`, hash per-kext nel manifest |

**Risposta secca:** `X6100HWLibs` è nella **SystemKC**, non nella BootKC. L’attribuzione alla SystemKC è **PROVEN** per presenza nel pool; l’attribuzione del **caricamento** alla SystemKC è **INFERRED**.

**Impatto:** il componente è disponibile nella SystemKC dell’host 25G342, ma **non** in 26B131. E (display), G (WindowServer), H (desktop) restano **BLOCKED** sul target.

**STOP rispettato:** sola lettura; nessuna estrazione, ricostruzione KC, modifica o boot. Spazio libero 12.920.044 KiB (12,32 GiB) > 10 GiB.
