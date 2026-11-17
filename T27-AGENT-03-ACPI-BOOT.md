# T27 — AGENT-03 — ACPI / PCI / BOOT

**Scope:** ACPI, APIC, IOPCIFamily, IOACPIFamily, PCI, VT-d, storage, APFS e dipendenze di `launchd` per MacBookPro16,1.  
**Mode:** read-only. **Nessun boot, nessun `kextload`, nessuna modifica EFI/NVRAM.**  
**Stato:** **BLOCKED prima di launchd.**

---

## 1. Matrice locale

| Componente | Target 26B131 | KDK 26B131 | root2 25G325 | root3 26B116 | Stato |
|---|---|---|---|---|---|
| `AppleACPIPlatform` | **ASSENTE** | **ASSENTE** | x86 25G325 | ASSENTE | **ASSENTE 26B131** |
| `AppleAPIC` | **ASSENTE** | **ASSENTE** | x86 25G325 | ASSENTE | **ASSENTE 26B131** |
| `IOPCIFamily` | metadati, 0 primari | x86 26B116 | x86 25G325 | x86 26B116 | **PARZIALE / BUILD ERRATO** |
| `IOACPIFamily` | metadati, 0 primari | x86 26B116 | x86 25G325 | x86 26B116 | **PARZIALE / BUILD ERRATO** |
| `apfs` | metadati, 0 primari | x86 26B116 | x86 25G325 | assente | **PARZIALE / BUILD ERRATO** |
| `IOStorageFamily` | metadati | x86 26B116 | x86 25G325 | assente | **PARZIALE** |
| `IONVMeFamily` | metadati | x86 26B116 | x86 25G325 | assente | **PARZIALE** |
| `IOGraphicsFamily` | metadati | x86 26B116 | x86 25G325 | 26B116 | **PARZIALE** |
| `launchd` | binario x86 presente | — | assente | assente | **PRESENTE, non eseguibile senza boot** |
| `dyld` | binario x86 presente | — | assente | assente | **PRESENTE, non eseguibile senza boot** |
| ACPI profile MBP16,1 | **ASSENTE** | non è profilo macchina | generico/overlay | assente | **UNPROVEN** |
| VT-d / DMAR / AppleVTD | **UNPROVEN** | non verificato | non verificato | non verificato | **UNPROVEN** |

Fonti: T26 `T26-SYSTEMKC-DEPENDENCIES.csv`, `T26-BOOTKC-DEPENDENCIES.csv`; T24; T25 boot dependencies.  
I percorsi target sono sotto `<TARGET_ROOT>/System/Library/Extensions`; `launchd` è `<TARGET_ROOT>/sbin/launchd`; `dyld` è `<TARGET_ROOT>/usr/lib/dyld`.

---

## 2. Catena minima

```text
kernel 26B131
  -> AppleACPIPlatform / AppleAPIC
  -> IOACPIFamily / IOPCIFamily
  -> IOStorageFamily / IONVMeFamily / apfs
  -> root filesystem / launchd
```

La catena non è completa:

1. ACPI/APIC non esistono in target/KDK 26B131.
2. IOPCI/IOACPI/storage sono solo metadati nel target; KDK/root2 sono build diverse.
3. `launchd` è presente come file, ma non c’è una root avviabile né una KC che lo raggiunga.
4. Non è stato eseguito alcun boot; la presenza di `launchd` non è una prova di esecuzione.

---

## 3. MacBookPro16,1

Il target ha un catalogo generico 26B131, non un profilo ACPI/EFI del MacBookPro16,1:

- nessun `ioreg` nativo della macchina;
- nessun dump ACPI/DSDT/SSDT del MacBookPro16,1;
- nessun profilo SMBIOS o NVRAM nativo verificato;
- nessuna prova che `AppleACPIPlatform`/`AppleAPIC` 25G325 si leghino al firmware T2/PCI di questa macchina;
- VT-d/DMAR e `AppleVTD` **non sono stati ispezionati**: non si può dire né “presente” né “assente”.

Un ACPI generico 26B131 non è una prova per il MacBookPro16,1.

---

## 4. Conclusione

**Il kernel 26B131 è presente e valido, ma la catena ACPI/PCI/storage non è completa.**  
`launchd` non può essere raggiunto con i materiali attuali. Il primo gate è una **BootKC/SystemKC 26B131** con ACPI/APIC e storage 26B131, non un boot di prova.

**Handoff:** l’integratore deve classificare ACPI/APIC come **BLOCKED**, VT-d/DMAR come **UNPROVEN**, e non accettare `launchd` presente come prova di boot.
