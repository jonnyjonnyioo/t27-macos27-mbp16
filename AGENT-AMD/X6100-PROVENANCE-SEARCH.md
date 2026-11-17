# T27 — AGENT-AMD — X6100HWLIBS GLOBAL PROVENANCE SEARCH

**Scope:** individuare una possibile sorgente locale di `AMDRadeonX6100HWLibs` presente in `systemkc-all`, senza presumere che root2 sia il donor.  
**Modalità:** sola lettura su `HAO-PROJECT/`, root25 e pool già acquisiti; `rg` non è installato (`RG_ABSENT`), quindi ricerca con `find`/`grep` e hash diretto. Nessuna estrazione, copia, build o boot.  
**Esito:** quattro copie binarie. **`e521d3cc…`** esiste solo in `systemkc-all` e nella copia `staged`; **`00b6214e…`** esiste in root2 e in una copia indipendente nel KDK25 (`<SESSION>`). Root3 non ha X6100; root25 e HAO-71 hanno solo metadati. **Nessuna sorgente indipendente di `e521` è emersa.**

---

## 1. Metodo e limiti

| Ricerca | Esito |
|---|---|
| `rg -l -i '533D1262…|X6100HWLibs|e521d3cc|00b6214e' HAO-PROJECT/` | **`RG_ABSENT`**: comando non disponibile |
| `grep -RIl -i 'X6100HWLibs'` | referenze in report, `Info.plist`, `CARRY-LIST`, matrici; non binari |
| `find HAO-PROJECT -type f -iname '*X6100HWLibs*'` | 4 binari + 2 report |
| `find` in root25 | solo `Info.plist`, `version.plist`, `_CodeSignature/CodeResources` |
| `find` in HAO-71 `root-full` | solo metadati; **nessun `Contents/MacOS`** |
| `find` in root3 | **nessun X6100** |

L’assenza di `rg` è una limitazione dello strumento, non una prova di assenza. La ricerca dei file è stata completata con `find` e hash.

---

## 2. Copie binarie trovate

| Percorso | Ruolo | Byte | SHA-256 | UUID | Firma | Match |
|---|---|---:|---|---|---|---|
| `<SESSION>/work/systemkc-all/com.apple.kext.AMDRadeonX6100HWLibs` | pool SystemKC | 16.985.840 | `e521d3cc…` | `533D1262` | **NO** | **e521 esatto** |
| `<SESSION>/work/staged/com.apple.kext.AMDRadeonX6100HWLibs` | copia di staging | 16.985.840 | `e521d3cc…` | `533D1262` | **NO** | **e521 esatto** |
| `<SESSION>/work/root2/.../AMDRadeonX6100HWLibs.kext/Contents/MacOS/AMDRadeonX6100HWLibs` | donor root2 | 17.256.336 | `00b6214e…` | `533D1262` | **SÌ** | **00b6 esatto** |
| `<SESSION>/source/kdk25-full/KDK.pkg/Payload/.../AMDRadeonX6100HWLibs` | KDK25 full | 17.256.336 | `00b6214e…` | `533D1262` | **SÌ** | **00b6 esatto** |

### 2.1 Hash completi

```text
e521d3cce8f9bb027642897fed8754ff4d9ef66dd08a8d13ab318e0c2db01bb5
  systemkc-all
  staged

00b6214e4771d84f2cda4a9943fceafaac0e632f57fbfda20e6ee5cbf051d61f
  root2
  HAO-93 KDK25
```

### 2.2 Dettaglio KDK25

`<SESSION>/source/kdk25-full/KDK.pkg/Payload/System/Library/Extensions/AMDRadeonX6000HWServices.kext/Contents/PlugIns/AMDRadeonX6100HWLibs.kext/Contents/MacOS/AMDRadeonX6100HWLibs`

| Campo | Valore |
|---|---|
| Byte | 17.256.336 |
| SHA-256 | `00b6214e…` |
| UUID | `533D1262-BE83-3507-B48A-FDB91C9D8793` |
| Arch | x86_64 |
| `LC_CODE_SIGNATURE` | presente |
| `__LINKEDIT` | 851.856 B |
| `LC_SOURCE_VERSION` | 7.1.11 |

È **byte-identico a root2**, non a `systemkc-all`.

---

## 3. Corrispondenze

### 3.1 SHA esatti

| SHA | Copie | Indipendenza |
|---|---|---|
| `e521d3cc…` | `systemkc-all`, `staged` | `staged` è una copia di lavoro; **nessuna seconda fonte indipendente** |
| `00b6214e…` | root2, HAO-93 KDK25 | **due copie indipendenti** dello stesso binario firmato |

**Nessuna copia `e521` indipendente** da `systemkc-all`/`staged` è stata trovata.

### 3.2 Sole corrispondenze UUID

Tutte e quattro le copie condividono:

```text
533D1262-BE83-3507-B48A-FDB91C9D8793
```

L’UUID identifica lo **stesso modulo**, non lo stesso binario:
- `e521` è non firmato, 16.985.840 B;
- `00b6` è firmato, 17.256.336 B, con `__LINKEDIT` 851.856 B.

### 3.3 Assenze

| Fonte | X6100 |
|---|---|
| root3 | **ASSENTE** |
| root25 | **NO_BINARY**: solo metadati |
| HAO-71 `root-full` | **NO_BINARY**: solo metadati |
| target 26B131 / KDK 26B131 | **ASSENTE** |
| `tahoe-bootkc-all` | **ASSENTE** |

---

## 4. Classificazione

### 4.1 PROVEN

- Esistono **quattro** copie binarie X6100 nei materiali.
- `systemkc-all` e `staged` hanno SHA **`e521d3cc…`**, 16.985.840 B, non firmato.
- root2 e HAO-93 KDK25 hanno SHA **`00b6214e…`**, 17.256.336 B, firmato.
- root3, root25, HAO-71, target 26B131 e KDK 26B131 non hanno un binario X6100.
- Tutte le copie hanno UUID `533D1262…`; l’UUID non distingue `e521` da `00b6`.

### 4.2 INFERRED

- `staged` è una copia di lavoro di `systemkc-all` o della stessa estrazione; non è una fonte indipendente.
- root2 e KDK25 condividono lo stesso binario firmato `00b6`; KDK25 è una copia indipendente di quella variante.
- `systemkc-all` e `staged` rappresentano la variante **non firmata/rebased**; root2/KDK25 la variante **firmata/base 0**.

### 4.3 UNPROVEN

- La sorgente indipendente di `e521d3cc…`: non trovata.
- Che `staged` derivi da `systemkc-all` o viceversa: nessun log.
- Che root2 o KDK25 siano la sorgente di `systemkc-all`: **NO**, SHA diverso.
- La provenienza della variante `e521`.
- L’ABI e il caricamento su 26B131.

---

## 5. Conclusione

| Domanda | Risposta |
|---|---|
| Quante copie binarie X6100? | **4** |
| Copie `e521` | **2**: systemkc-all + staged |
| Copie `00b6` | **2**: root2 + KDK25 |
| `e521` ha una fonte indipendente? | **NO** |
| KDK25 è identico a `systemkc-all`? | **NO**: è identico a root2 |
| Root3 ha X6100? | **NO** |
| Root25/HAO-71 hanno il binario? | **NO**, solo metadati |
| UUID uguale implica SHA uguale? | **NO** |

La ricerca **non trova** una sorgente indipendente di `e521d3cc…`. L’unica altra copia esatta è `staged`, che è una copia di lavoro. Il KDK25 aggiunge una copia indipendente di `00b6214e…`, la variante firmata di root2, ma **non** della variante presente in `systemkc-all`.

**STOP rispettato:** sola lettura; nessuna estrazione, copia, build, firma o boot. Spazio libero 12.927.952 KiB (12,33 GiB) > 10 GiB.
