# T27 — AGENT-AMD — CACHELEVEL 2 EXTERNAL REGION

**Scope:** identificare la provenienza dei tre target `0x18C0074D`, `0x18C00EFC`, `0x18C00002`; cercare la pagina `0x18C00000` nei 172 `LC_FILESET_ENTRY`, nei segmenti e nelle mappe VM; verificare se `cacheLevel=2` possa riferirsi a una collection esterna.

**Modalità:** sola lettura; parsing SystemKC 25G342, `LC_FILESET_ENTRY`, `LC_SEGMENT_64`, directory KernelCollections, report esistenti. Nessuna modifica, build o boot.

**Esito:** **nessun** provider e **nessun** segmento del SystemKC contiene la pagina `0x18C00000`. L’ultimo `LC_FILESET_ENTRY` è a `0x15387000`; la fine massima di un segmento è `0x15FF6677`. Il target `0x18C00000` è **oltre** di circa **46 MB**. Nella directory KernelCollections ci sono solo **Boot** e **System**, nessuna collection ausiliaria. `cacheLevel=2` verso una collection esterna resta **plausibile ma UNPROVEN**. T27 resta **OPEN**.

---

## 1. Limiti del SystemKC

| Dato | Valore |
|---|---:|
| Provider | **172** |
| `LC_FILESET_ENTRY` vmaddr massimo | **`0x15387000`** |
| Fine massima di un segmento | **`0x15FF6677`** |
| Size SystemKC | **369.213.440 B** (`0x1601C000`) |
| Pagina target | **`0x18C00000`** |
| Distanza oltre la fine massima | **≈46 MB** |

**PROVEN:** `0x18C00000` è oltre ogni entry e ogni segmento del SystemKC.
**PROVEN:** non è un offset interno al SystemKC.

---

## 2. Ricerca nei 172 provider

| Verifica | Risultato |
|---|---:|
| Entry con vmaddr ≤ target < vmaddr+size | **0** |
| Segmenti che contengono il target | **0** |
| Provider con UUID candidato | **0** |
| `LC_FILESET_ENTRY` con fileoff compatibile | **0** |
| `_PrelinkExecutableSize` candidato | **—** |

**PROVEN:** **0/172** provider contiene la pagina.
**PROVEN:** **0** segmenti la contengono.
**UNPROVEN:** una entry esterna non presente nel SystemKC.

---

## 3. KernelCollections disponibili

| File | Size | Contiene `0x18C00000`? |
|---|---:|---|
| `SystemKernelExtensions.kc` | **352 MB** | **NO** |
| `BootKernelExtensions.kc` | **64 MB** | **NO** |
| `AuxiliaryKernelExtensions.kc` | **assente** | **—** |

**PROVEN:** non c’è una collection ausiliaria locale.
**PROVEN:** BootKC è più piccolo del target e ha una base VM diversa.
**UNPROVEN:** una collection esterna caricata a runtime.

---

## 4. `cacheLevel=2`

| Proprietà | Valore |
|---|---|
| `kcformat.c` mapping | **2 non mappato** |
| `basePointers[2]` | **non serializzato** |
| Target nel SystemKC | **NO** |
| Target in BootKC | **NO** |
| Target in AuxKC locale | **— assente** |
| Collection esterna | **UNPROVEN** |

**PROVEN:** `cacheLevel=2` non ha un `KCKind` nel codice disponibile.
**PROVEN:** la base non è nel file.
**INFERRED:** i tre target possono appartenere a una collection esterna.
**UNPROVEN:** quale collection, se esiste, e la sua base.

---

## 5. UUID, vmaddr, fileoff, `_PrelinkExecutableSize`

| Campo | Candidati |
|---|---:|
| UUID | **0** |
| vmaddr | **0** |
| fileoff | **0** |
| `_PrelinkExecutableSize` | **0** |

**PROVEN:** non ci sono candidati da confrontare.
**UNPROVEN:** l’identità di una collection esterna.

---

## 6. Report e mappe esistenti

| Fonte | Occorrenze della pagina |
|---|---:|
| `T27-X4000HWLIBS-THREE-AUTH-POINTERS.md` | **3 target, stessa pagina** |
| Altri report T27 | **0** |
| Mappe VM del SystemKC | **0** |
| BootKC | **0** |

**PROVEN:** solo il report 52 documenta la pagina.
**PROVEN:** nessuna mappa esistente la attribuisce a un provider.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| Pagina nel SystemKC? | **NO** |
| Pagina in un provider? | **NO — 0/172** |
| Pagina in un segmento? | **NO — 0** |
| AuxKC locale? | **NO** |
| UUID/vmaddr/fileoff candidati? | **0** |
| `_PrelinkExecutableSize` candidato? | **0** |
| Collection esterna? | **UNPROVEN** |
| Attribuzione per prossimità? | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la pagina `0x18C00000` è **fuori** dal SystemKC e da ogni suo provider; non ci sono candidati UUID, vmaddr, fileoff o `_PrelinkExecutableSize`. Non esiste una AuxKC locale. L’ipotesi di una collection esterna è **plausibile ma non dimostrata**; nessuna attribuzione per prossimità. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
