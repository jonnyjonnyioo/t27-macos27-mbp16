# T27 — AGENT-AMD — X6100HWLibs BINARY IDENTITY

**Scope:** stabilire se il binario `X6100HWLibs` caricato su 25G342 corrisponde alla copia completa root2 (`00b6214e…`) o alla variante HAO-65 (`e521d3cc…`); confronto Mach-O, SHA, sezioni, simboli, segmenti, dipendenze e provenienza BootKC/SystemKC.  
**Modalità:** sola lettura; nessuna estrazione, compilazione, modifica, `kextload` o boot.  
**Esito:** **nessuna prova dell’identità binaria caricata**. Root2 e HAO-65 hanno stesso UUID/versione/architettura e struttura simile, ma **hash, `__text` e sezioni `__DATA` differiscono**; il log di caricamento contiene solo UUID/versione, non SHA. La variante HAO-65 è verosimilmente la copia KC, ma non è dimostrato che sia il byte-stream caricato.

---

## 1. Tre oggetti distinti

| Oggetto | Percorso | SHA-256 | Byte | UUID | Firmato |
|---|---|---|---:|---:|---|
| Root2 completo | `<SESSION>/work/root2/.../AMDRadeonX6100HWLibs.kext/Contents/MacOS/AMDRadeonX6100HWLibs` | `00b6214e4771d84f2cda4a9943fceafaac0e632f57fbfda20e6ee5cbf051d61f` | 17.256.336 | `533D1262-BE83-3507-B48A-FDB91C9D8793` | **SÌ**, macOS Software Signing |
| HAO-65 pool | `<SESSION>/work/systemkc-all/com.apple.kext.AMDRadeonX6100HWLibs` | `e521d3cce8f9bb027642897fed8754ff4d9ef66dd08a8d13ab318e0c2db01bb5` | 16.985.840 | `533D1262-BE83-3507-B48A-FDB91C9D8793` | **NO**, “not signed at all” |
| Caricato su 25G342 | `kmutil showloaded`, indice 181 | **non registrato** | **non registrato** | `533D1262-…` | **non registrato** |

Il terzo oggetto è quello che conta: il log di caricamento non espone né SHA né path del file. `kmutil showloaded` riporta UUID, versione, dipendenze e indirizzo, non un hash.

---

## 2. Confronto file

| Campo | Root2 | HAO-65 | Esito |
|---|---:|---:|---|
| Byte | 17.256.336 | 16.985.840 | **diversi** (Δ 270.496) |
| SHA-256 | `00b6214e…` | `e521d3cc…` | **diversi** |
| UUID | `533D1262…` | `533D1262…` | uguali |
| Versione | 1.0 | 1.0 | uguali |
| Arch | x86_64 | x86_64 | uguali |
| `__TEXT` size | 3.858.432 | 3.858.432 | uguali |
| `__DATA` size | 12.541.952 | 12.541.952 | uguali |
| `__DATA_CONST` size | 4.096 | 4.096 | uguali |
| `__LINKEDIT` size | 851.856 | 581.360 | **diversi** (Δ 270.496) |
| Code signature | 151.984 B, `LC_CODE_SIGNATURE` | assente | **diversi** |
| Simboli definiti | 72 | 72 | uguali come numero |
| Simboli indefiniti | 348 | 348 | uguali come numero |
| `nm -u` set hash | `b9105e1e…` | `b9105e1e…` | **uguale** |
| `nm -gU` **nomi** hash | `cf8ba277…` | `cf8ba277…` | **uguale** |
| `nm -gU` righe con indirizzi | `f72bbc62…` | `d1dbb261…` | **diverse** (indirizzi/slide) |

### 2.1 Sezioni Mach-O

| Sezione | Root2 SHA | HAO-65 SHA | Esito |
|---|---|---|---|
| `__TEXT,__text` | `c65134cb…` | `19dcb85d…` | **diversa** |
| `__TEXT,__cstring` | `444b2219…` | `444b2219…` | **uguale** |
| `__TEXT,__const` | `7fd5db4b…` | `7fd5db4b…` | **uguale** |
| `__DATA,__got` | `20b67510…` | `2c0de47f…` | diversa |
| `__DATA,__const` | `ca8588e7…` | `14a702c0…` | diversa |
| `__DATA,__data` | `829a9e43…` | `2a7a9522…` | diversa |
| `__DATA_CONST,__kalloc_type` | `3471db6a…` | `120511a0…` | diversa |

`__TEXT,__cstring` e `__TEXT,__const` sono **identiche**, quindi stringhe e costanti coincidono. `__text` e le sezioni `__DATA` differiscono.

### 2.2 Indirizzi

| Sezione | Root2 addr | HAO-65 addr | Delta |
|---|---|---|---|
| `__TEXT,__text` | `0x960` | `0xdd6e960` | `0xdd6e000` |
| `__TEXT,__cstring` | `0x241536` | `0xdfaf536` | `0xdd6e000` |
| `__DATA,__data` | `0x3be290` | `0xe12c290` | `0xdd6e000` |

Lo spostamento è uniforme: **`0xdd6e000`**. Questo è compatibile con **link base diverso / rebasing**, non con una prova di codice diverso. Spiega perché `__text` e i puntatori in `__DATA` cambiano, mentre `__cstring`/`__const` restano uguali.

### 2.3 Cosa significa

- Root2 e HAO-65 **non sono byte-identici**: SHA e sezioni `__text`/`__DATA` differiscono.
- La differenza di `__LINKEDIT` (270.496 B) coincide con la differenza di dimensione totale; root2 include una firma di 151.984 B, HAO-65 no. Restano **118.512 B** di differenza non attribuiti (padding/struttura LINKEDIT): non vanno interpretati come codice.
- La struttura, le dimensioni, le stringhe e le costanti sono coerenti con **la stessa immagine a base di link diversa**, ma **non è una prova**. Non si può dedurre “stesso codice” solo dall’UUID o dal numero di simboli.

---

## 3. Provenienza BootKC / SystemKC

| Voce | Valore | Fonte |
|---|---|---|
| BootKC host | `/System/Library/KernelCollections/BootKernelExtensions.kc` | filesystem |
| SHA BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` | `HAO-65/evidence/donor-source-kc.txt`, ricalcolato |
| SystemKC host | `/System/Library/KernelCollections/SystemKernelExtensions.kc` | filesystem |
| SHA SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` | `donor-source-kc.txt`, ricalcolato |
| Estrazione HAO-65 | `ipsw kernel extract -a` | `BUILD-REPORT.md` |
| Kext BootKC / SystemKC | 204 / 172 | `BUILD-REPORT.md` |
| Pool HAO-65 | `work/systemkc-all`, `work/staged` | filesystem |
| Manifest HAO-65 | **esclude** `systemkc-all` e `staged` | `SHA256-MANIFEST.txt` |
| Hash per-kext nel manifest | **nessuno** | `SHA256-MANIFEST.txt` |

`HAO-65` ha un pool chiamato `systemkc-all`; il build report documenta sia BootKC (204 kext) sia SystemKC (172). **Non c’è un manifest per-file** che associ `e521d3cc…` a una delle due collection. La provenienza della singola copia è quindi **UNPROVEN**.

La hash della collection non identifica il singolo kext: BootKC/SystemKC sono contenitori firmati con molti kext. Senza un manifest per-kext o un log di caricamento con SHA, non si può mappare `533D1262…` a `9bb053cf…`/`b4b618bf…`.

---

## 4. Log di caricamento

`<SESSION>/evidence/phase1-drivers.txt` (SHA `59de359d…`, 16 Nov 02:42):

```text
181 0 0xffffff7f8ea57000 0x3adb28 0x3adb28
com.apple.kext.AMDRadeonX6100HWLibs (1.0)
533D1262-BE83-3507-B48A-FDB91C9D8793 <19 7 6 3 1>
```

| Domanda | Risposta |
|---|---|
| UUID caricato | `533D1262…` |
| Versione caricata | 1.0 |
| SHA caricato | **assente** |
| Path caricato | **assente** |
| Collection sorgente | **assente** |
| Arch caricata | **assente** |

Il log prova che **un** kext con quell’UUID/versione è stato caricato; non prova che sia root2 o HAO-65.

---

## 5. Classificazione

| Classe | Dato |
|---|---|
| **MEASURED** | Host: UUID/versione/indice/deps di X6100; root2 e HAO-65: SHA, sezioni, segmenti, simboli |
| **DOCUMENTED** | BootKC/SystemKC collection SHA; HAO-65 `ipsw` extraction; root2 firma Apple |
| **UNPROVEN** | Identità esatta del binario caricato; root2 = caricato; HAO-65 = caricato; ABI 26B131 |
| **ABSENT** | SHA/path/collection nel log di caricamento; manifest per-kext HAO-65 |

---

## 6. Conclusione

1. **Non esiste una prova** che il binario caricato sia root2 né HAO-65. Il log ha solo UUID/versione.
2. Root2 e HAO-65 condividono UUID, versione, architettura, dimensioni dei segmenti, stringhe e costanti, ma **non sono byte-identici**: `__text` e `__DATA` differiscono, con uno slide uniforme `0xdd6e000`.
3. La differenza di `__LINKEDIT` (270.496 B) è compatibile con la firma presente in root2 e assente in HAO-65; non è una prova di identità del codice.
4. BootKC e SystemKC hanno hash di collection, ma **non** un hash per-kext; HAO-65 esclude il pool dal manifest.
5. La variante HAO-65 è **plausibilmente** la copia KC, ma resta **UNPROVEN**; root2 è la copia completa firmata, non necessariamente quella caricata.
6. **X6100 resta un candidato documentato, non un componente verificato del target 26B131.**
7. **E (display), G (WindowServer), H (desktop): BLOCKED.**

**STOP rispettato:** sola lettura; nessuna estrazione su disco, compilazione, modifica, `kextload` o boot. Spazio libero 12.920.044 KiB (12,32 GiB) > 10 GiB.
