# T27 — AGENT-02 — DONOR E MATERIALI LOCALI

**Scope:** installer e root 25G342, KDK 25G342, KDK 26B131, root2, root3, provenienza, firme, build.  
**Mode:** read-only. **Nessun download, nessuna installazione, nessuna scrittura sui volumi sorgente.**  
**Stato:** **BLOCKED per il target 26B131; il donor 25G342 è insufficiente.**

---

## 1. Inventario verificato

| Materiale | Percorso | Build | Stato | Uso |
|---|---|---|---|---|
| Root 25G342 | `<DONOR_VOLUME>` | 25G342 / Darwin 25.6 | **PRESENTE**; 705 kext top-level, 892 totali; BootKC+SystemKC+boot.efi | riferimento, **non installer** |
| BootKC 25G342 | `…/KernelCollections/BootKernelExtensions.kc` | 25G342 | 67.600.384 B; `9bb053cf…` | riferimento |
| SystemKC 25G342 | `…/KernelCollections/SystemKernelExtensions.kc` | 25G342 | 369.213.440 B; `b4b618bf…` | riferimento |
| boot.efi 25G342 | `…/CoreServices/boot.efi` | 25G342 | 723.512 B; `016ccd2d…` | riferimento |
| KDK 25G342 | `…/<SESSION>/source/kdk25G342/…dmg`; `<VOLUME>/Kernel Debug Kit/KernelDebugKit.pkg` | 25G342 | DMG 1.181.028.172 B; package Apple-signed | debug; non installer |
| KDK 26B131 | `…/<SESSION>/work/kdk/KDK_27.2.1_26B131.kdk`; DMG 1.251.401.698 B | 26B131 package; kext 26B116 | 706 top-level, 873 totali, **0 `.kc`**, 14 manifest ARM | debug; non release |
| root2 | `…/<SESSION>/work/root2` | 25G325/25G332 | 905 bundle, 875 primari, 387 x86_64; no framework/DriverKit/SystemOS/boot/Recovery | overlay KDK |
| root3 | `…/<SESSION>/work/root3` | 26B116 | 24 kext, 9 primari; niente ACPI/APIC | parziale |
| Target 26B131 | `<TARGET_ROOT>` | 26B131 | 694 top-level, **0 primari top-level**, 0 `.kc`, no boot.efi | catalogo/estrazione |
| Installer 25G342 | `/Applications`, progetto | 25G342 | **ASSENTE** | non disponibile |
| `SharedSupport.dmg` / `InstallESD.dmg` / `BaseSystem.dmg` | ricerca locale | 25G342 | **ASSENTI** | non disponibili |
| `<VOLUME>/Shared Support` | volume | MobileAsset | 17 GB cache | **non è installer** |
| IPSW 26B131 | `…/<SESSION>/downloads/UniversalMac_27.2.1_26B131_Restore.ipsw` | 26B131 | 25.595.954.706 B | restore asset, non KC/installer |

---

## 2. Risorse mancanti

1. Installer 25G342 completo e `SharedSupport.dmg`/`InstallESD.dmg`/`BaseSystem.dmg`.
2. Target 26B131 con primari x86_64 e `System.kext` release.
3. Set kext 26B131: ACPI, APIC, AMD X6000, T2/VHCI/BCE, storage e HID.
4. BootKC/SystemKC 26B131 complete.
5. `boot.efi`/Recovery/BaseSystem 26B131.
6. Framework/DriverKit/SystemOS 26B131 completi.
7. Ambiente 26B131 isolato con KDK registrato.
8. Spazio 80 GiB working set / 160 GiB workspace.

---

## 3. Provenienza e firme

- Root 25G342 e KDK: Authority Apple `macOS Software Signing` nei bundle campionati; `codesign --verify --strict` fallisce con **`invalid resource directory`** → **FIRMA NON VERIFICATA**.
- KDK 26B131: package Apple-signed; kext debug `DTPlatformBuild=26B116`; **non release 26B131**.
- BootKC T3: **non firmata**.
- Target 26B131: metadata-only; non ci sono primari da verificare.
- 25G342: KC e `boot.efi` coerenti con la build 25G342, non con 26B131.

---

## 4. Conclusione

**Il donor 25G342 non è sufficiente** per produrre una coppia 26B131:

- build/kernel diversi (Darwin 25.6 vs 27.2);
- installer completo assente;
- KDK 25G342 debug e non installer;
- root2 è un overlay 25G325, non un installer;
- la root 25G342 è utile solo come riferimento di forma/composizione.

**Stato:** **BLOCKED** per acquisizione target; **OPEN** come strategia di confronto.  
**Handoff:** l’integratore deve rifiutare il mapping “copia l’albero Extensions 25G342” e richiedere una chiusura 26B131 tracciata.
