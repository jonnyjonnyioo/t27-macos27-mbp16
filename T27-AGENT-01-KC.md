# T27 — AGENT-01 — KERNEL COLLECTIONS

**Scope:** BootKC/SystemKC 25G342 vs 26B131, KPI, UUID, simboli, ABI, architetture, dipendenze e procedura teorica.  
**Mode:** read-only. **Nessuna KC creata, nessun `kmutil create`, nessun boot.**  
**Stato:** **BLOCKED per una coppia 26B131 completa; procedura teorica definita.**

---

## 1. Evidenze

| Oggetto | Percorso | Build | Arch | Dimensione / hash | Esito |
|---|---|---|---:|---|---|
| Kernel 26B131 | `<TARGET_ROOT>/System/Library/Kernels/kernel`; KDK 26B131 | 27.2.0 / 26B131 | x86_64 | 21.128.776 B; `3c931751…` | **PRESENTE** |
| BootKC T3 | `<DESKTOP>/BootKernelExtensions-T3-V.kc` | 26B131 | x86_64 | 18.055.168 B; `b3cb72d1…`; UUID `252CABB5-…` | **PARZIALE: 0 kext** |
| BootKC root2 | `…/<SESSION>/work/root2/System/Library/KernelCollections/BootKernelExtensions.kc` | 26B131 | x86_64 | hash T3 | **PARZIALE: copia kernel-only** |
| BootKC 25G342 | `<DONOR_VOLUME>/…/KernelCollections/BootKernelExtensions.kc` | 25G342 | x86_64 | 67.600.384 B; `9bb053cf…` | **RIFERIMENTO, build errata** |
| SystemKC 25G342 | `<DONOR_VOLUME>/…/KernelCollections/SystemKernelExtensions.kc` | 25G342 | x86_64 | 369.213.440 B; `b4b618bf…` | **RIFERIMENTO, build errata** |
| BootKC 26B123 | T16 | 26B123 | x86_64 | 64.995.328 B; 197 kext | **RIFERIMENTO, build errata** |
| SystemKC 26B131 | target / KDK / root2 / root3 | 26B131 | — | **assente** | **ASSENTE** |

Fonti: T26 report §5–8; `T26-BOOTKC-DEPENDENCIES.csv`; `T26-SYSTEMKC-DEPENDENCIES.csv`; `T26-ABI-COMPATIBILITY.csv`.

---

## 2. Confronto strutturale

### 2.1 Kernel e simboli

| Misura | 26B131 | 25G342 |
|---|---:|---:|
| Darwin | 27.2.0 | 25.6.0 |
| XNU | 13432.41.4~25 | 12377.161.15.701.48~2 |
| Simboli esportati | 24.399 | 23.794 |
| Comuni | 23.653 | 23.653 |
| Solo target | 746 | — |
| Solo donor | — | 141 |

Il confronto `nm -gU` è un confronto di **nomi**, non di layout ABI, tipi, KPI o comportamento. Non autorizza a usare kext 25G342 in una KC 26B131.

### 2.2 KPI

- BootKC 26B123/KPI: 27.2.0.
- BootKC 25G342/KPI: 25.6.0.
- Target 26B131: kernel 27.2.0, `System.kext` solo metadati.
- KDK 26B131: kext debug con `DTPlatformBuild=26B116`.

Le versioni `8.0`/`9.0` osservate in `OSBundleLibraries` sono **minimi dichiarati**, non la versione effettiva del kernel; non sono una prova di compatibilità.

### 2.3 BootKC e SystemKC

La BootKC T3 contiene solo `com.apple.kernel`; **0 estensioni**. Non può essere la base di una SystemKC di sistema. La SystemKC non è costruibile “da sola”: serve una BootKC valida e prelinked.

Sequenza corretta:

```text
kernel 26B131 + repository kext 26B131 + KDK registrato
  -> BootKC completa
  -> verifica UUID/build/kext/KPI
  -> SystemKC prelinked contro quella BootKC
```

La sequenza non è stata eseguita.

---

## 3. Procedura teorica (non eseguita)

```sh
# Solo in ambiente 26B131 isolato, KDK registrato.
kmutil create --new boot --arch x86_64 --build 26B131 \
  --kdk /Library/Developer/KDKs/KDK_27.2.1_26B131.kdk \
  --kernel /path/26B131/System/Library/Kernels/kernel \
  --repository /path/26B131/System/Library/Extensions \
  --boot-path /path/out/BootKernelExtensions.kc -v

kmutil create --new sys --arch x86_64 --build 26B131 \
  --kdk /Library/Developer/KDKs/KDK_27.2.1_26B131.kdk \
  --boot-path /path/out/BootKernelExtensions.kc \
  --system-path /path/out/SystemKernelExtensions.kc -v
```

Divieti:

- `--allow-missing-kdk`: in T69 ha prodotto solo KC kernel-only.
- `--manifest`: Apple Silicon only; i 14 manifest KDK sono ARM.
- `-Z`/`--no-authentication`: non è una scorciatoia.
- `--explicit-only`: solo con lista completa e verificata.
- Uso dell’host 25G342: vietato; senza `--build` usa la build host.

---

## 4. Conclusione

**BootKC 26B131 completa: BLOCKED.** Il kernel è presente, ma il set boot kext 26B131 non è completo; ACPI/APIC mancano in target e KDK; la T3 è kernel-only.  
**SystemKC 26B131: BLOCKED**, perché manca la BootKC base e il repository 26B131.  
**Teoricamente:** entrambe sono producibili con un set 26B131 completo e un ambiente isolato; **operativamente oggi: no**.

**Handoff:** l’integratore deve rifiutare qualsiasi proposta che usi la BootKC T3, la coppia 25G342 o kext KDK 26B116 come sostituti della closure 26B131.
