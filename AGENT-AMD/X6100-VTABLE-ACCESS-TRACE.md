# T27 — AGENT-AMD — X6100 VTABLE ACCESS TRACE

**Scope:** stabilire se gli **835 slot esterni** delle **6 vtable istanziate** siano usati come **dati**, **puntatori** o **destinazioni di chiamate indirette**. Tracciare gli **8 vptr store**, i **568 accessi `*0xN(%rax)`**, le **2.212 chiamate indirette** e correlare offset, slot e target X4000.

**Modalità:** sola lettura; `otool -tvV`, `nm -n -S`, parsing Python, chained fixups. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** **283/568** chiamate `*0xN(%rax)` sono precedute da un **vptr load** (`movq (%reg), %rax`); **179** da un campo (`0xN(%reg), %rax`), **64** senza sorgente `%rax`, **38** da copia registro, **4** altro. Il caso più forte è **0x28**: **48/48 vptr load**, slot **`__ZTV+0x38`**, target **`0x91DF70` in `__TEXT,__cstring` X4000**. Se `%rax` è davvero il vptr X6100, la chiamata andrebbe su una **stringa**, quindi sarebbe invalida. **Non è dimostrato** che quegli oggetti siano X6100. T27 resta **OPEN**.

---

## 1. Input e metodo

| Input | Uso |
|---|---|
| `X6100-VTABLE-ACCESS-TRACE.md` | questo report |
| `X6100-HYBRID-VTABLE-SEMANTICS.md` | 835 slot, target, accessi |
| `X6100-ZTV-STRUCTURE-CLASSIFICATION.md` | 8 vptr store, 13 refs |
| `systemkc-all/com.apple.kext.AMDRadeonX6100HWLibs` | disassembly completo |

Procedura:
1. parse di **603.316** istruzioni `otool -tvV`;
2. estrazione di **568** `callq *0xN(%rax)`;
3. per ciascuna, scansione delle **6 istruzioni precedenti** e ricerca dell’ultima `movq …, %rax`;
4. classificazione:
   - **vptr_load**: `movq (%reg), %rax`;
   - **field_load**: `movq 0xN(%reg), %rax`;
   - **reg_copy**: `movq %reg, %rax`;
   - **no_rax_source**: nessuna `movq …, %rax`;
   - **other**.
5. correlazione offset → slot `__ZTV+0x10+offset` → target X4000.

---

## 2. vptr store e percorsi di inizializzazione

| Classe | Costruttore | vptr store | Vtable |
|---|---|---|---:|
| X6100 | `C2EPK11OSMetaClass` | `0xDD6EA00` | `__ZTV35` |
| X6100 | `C1Ev` | `0xDD6EC0F` | `__ZTV35` |
| X6100::MetaClass | `C2Ev` | `0xDD6EB4B` | `__ZTVN35` |
| HWLibs | `C2EPK11OSMetaClass` | `0xDD6EE20` | `__ZTV30` |
| HWLibs | `C2Ev` | `0xDD6F02F` | `__ZTV30` |
| HWLibs::MetaClass | `C2Ev` | `0xDD6EF6B` | `__ZTVN30` |
| SWIP | `C2EPK11OSMetaClass` | `0xDD6F7B0` | `__ZTV34` |
| SWIP::MetaClass | `C2Ev` | `0xDD6F85B` | `__ZTVN34` |

Sequenza:

```text
leaq __ZTV…(%rip), %rcx
addq $0x10, %rcx
movq %rcx, (%rax)
```

**PROVEN:** 8 oggetti/vtable installano **`vptr = __ZTV + 0x10`**; la vtable è **`__DATA,__const`** e non viene mai scritta.

---

## 3. Classificazione delle 568 chiamate

| Categoria | Chiamate | Quota |
|---|---:|---:|
| **vptr_load** (`movq (%reg), %rax`) | **283** | 49,82% |
| **field_load** (`movq 0xN(%reg), %rax`) | **179** | 31,51% |
| **no_rax_source** | **64** | 11,27% |
| **reg_copy** | **38** | 6,69% |
| **other** | **4** | 0,70% |
| **Totale** | **568** | 100% |

**PROVEN:** **283** chiamate hanno un **caricamento da memoria a offset 0** prima della call: è il pattern tipico del **vptr**. **179** usano un **campo** e **64** non hanno una sorgente `%rax` nelle 6 istruzioni precedenti.

**UNPROVEN:** che il `%rdi`/`%reg` caricato appartenga a un oggetto **X6100**. Il pattern vptr è comune a molte classi kernel.

---

## 4. Offset, slot e target

**Regola:** se `%rax` è il vptr, lo slot è **`__ZTV + 0x10 + offset`**.

| Call offset | Chiamate | vptr_load | Slot (`+0x10`) | Main range | Target | Sezione X4000 | Simbolo nearest |
|---:|---:|---:|---:|---|---:|---|---|
| **0x28** | **48** | **48** | `+0x38` | **SÌ** | `0x91DF70` | `__TEXT,__cstring` | `MCILDebugPrint.cold.1` |
| 0x40 | 43 | 1 | `+0x50` | SÌ | `0x91C1F0` | `__TEXT,__cstring` | `MCILDebugPrint.cold.1` |
| 0x38 | 40 | 5 | `+0x48` | SÌ | `0xDD6EAF0` | **interno X6100** | — |
| **0x10** | **32** | **24** | `+0x20` | **SÌ** | `0x91DF30` | `__TEXT,__cstring` | `MCILDebugPrint.cold.1` |
| **0x60** | **26** | **19** | `+0x70` | **SÌ** | `0x969CC0` | `__TEXT,__const` | `_PwrVirusTable` |
| **0xB8** | **22** | **18** | `+0xC8` | **SÌ** | `0xAB6F10` | `__DATA,__data` | `_aF32_MEC_Ucode` |
| 0x80 | 18 | 1 | `+0x90` | SÌ | `0xAB6C20` | `__DATA,__data` | `_aF32_MEC_Ucode` |
| **0x08** | **15** | **0** | `+0x18` | **SÌ** | `0xDD6EA90` | **interno X6100** | — |
| **0x1D0** | **14** | **13** | `+0x1E0` | **SÌ** | `0xAB87C0` | `__DATA,__data` | `_aF32_MEC_Ucode` |
| **0xB0** | **13** | **8** | `+0xC0` | **SÌ** | `0xAB6EF0` | `__DATA,__data` | `_aF32_MEC_Ucode` |
| **0x100** | **12** | **8** | `+0x110` | **SÌ** | `0xAB7030` | `__DATA,__data` | `_aF32_MEC_Ucode` |
| **0x128** | **11** | **10** | `+0x138` | **SÌ** | `0x98DFE0` | `__DATA,__const` | `__ZL20CAIL_ASIC_CAPS_TABLE` |
| **0x30** | **10** | **6** | `+0x40` | **SÌ** | `0x91DF80` | `__TEXT,__cstring` | `MCILDebugPrint.cold.1` |
| **0x2B8** | **10** | **10** | `+0x2C8` | **SÌ** | `0x98EB00` | `__DATA,__const` | `__ZL20CAIL_ASIC_CAPS_TABLE` |
| 0x8F0 | 9 | 9 | `+0x900` | **NO** | `0xAB6C20`* | `__DATA,__data` | `_aF32_MEC_Ucode` |
| 0x8E8 | 8 | 8 | `+0x8F8` | **NO** | `0xAB6BF0`* | `__DATA,__data` | `_aF32_MEC_Ucode` |
| 0x8F8 | 7 | 7 | `+0x908` | **NO** | `0xDD6EB60`* | **interno X6100** | — |
| 0x48 | 8 | 0 | `+0x58` | SÌ | `0x91E100` | `__TEXT,__cstring` | `MCILDebugPrint.cold.1` |
| 0x18 | 7 | 0 | `+0x28` | SÌ | `0x91DF50` | `__TEXT,__cstring` | `MCILDebugPrint.cold.1` |
| 0xA8 | 7 | 0 | `+0xB8` | SÌ | `0xAB6ED0` | `__DATA,__data` | `_aF32_MEC_Ucode` |

\* Per `0x8F0/0x8E8/0x8F8` lo slot calcolato da **main** è **fuori** dal range `__ZTV35`; il target mostrato è solo il candidato a `__ZTV35+0x10+offset`, **non** una prova di appartenenza.

**PROVEN:** gli offset **0x28, 0x10, 0x60, 0xB8, 0x1D0, 0xB0, 0x100, 0x128, 0x30, 0x2B8** mappano su **slot esterni** delle main vtable e su target **X4000 dati/stringhe**. **0x38** e **0x08** mappano su **slot interni** con target **X6100**.

---

## 5. Il caso 0x28

**48 chiamate**, **48/48 vptr_load**, slot `__ZTV35+0x38`, target `0x91DF70` in **`__TEXT,__cstring`** X4000. Sequenza tipica:

```text
movq -0x10(%rbp), %rax
movq 0xA8(%rax), %rdi
movq (%rdi), %rax
callq *0x28(%rax)
```

**PROVEN:** il pattern è **vptr load + call a offset 0x28**.
**INFERRED:** se l’oggetto è X6100, la call usa lo slot **`__ZTV35+0x38`**, che punta a una **stringa X4000**.
**UNPROVEN:** che `%rdi` sia un oggetto X6100; può essere un’altra classe kernel con vptr e layout diverso.

**Conseguenza:** o (a) il chiamante usa **un’altra vtable**, o (b) la vtable X6100 contiene **entry non callable** e il percorso è **dead/invalid**. **Nessuna** delle due è provata senza boot.

---

## 6. Dati, puntatori o chiamate?

| Uso | Evidenza | Stato |
|---|---|---|
| **Dati** | 835 slot in `__const`; 0 scritture; target firmware/tabelle | **PROVEN (contenuto)** |
| **Puntatori** | slot allineati; target X4000 | **PROVEN (raw)** |
| **Destinazioni di chiamata** | 283 vptr_load; 48 a 0x28; target cstring | **UNPROVEN** |
| **Chiamate valide** | solo 0x38/0x08 verso codice interno; 5+0 | **INFERRED/parziale** |
| **Chiamate a dati** | se vptr X6100, 0x28/0x10/0x60/0xB8... | **UNPROVEN, potenzialmente invalide** |

**Sintesi:** la struttura è **dati/puntatori** in modo provato; l’uso come **call target** è **solo compatibile con il pattern**, non attribuito. **0x28** è l’anomalia più forte.

---

## 7. Perché non si può chiudere

- Il **vptr_load** dimostra un **caricamento da offset 0**, non l’appartenenza a X6100.
- Le **48** chiamate a `0x28` potrebbero appartenere a **un’altra classe**.
- I target `0x8F0/0x8E8/0x8F8` cadono **fuori** da `__ZTV35`; la mappatura main è **solo candidata**.
- Non ci sono **simboli** per le call destination; `otool` non risolve il vptr.
- **Nessun boot**: non si può osservare il dispatch reale.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| 8 vptr store? | **SÌ, vptr = `__ZTV+0x10`** |
| 568 chiamate via `*0xN(%rax)`? | **SÌ** |
| Quante con vptr_load? | **283/568 (49,82%)** |
| Offset più forte? | **0x28: 48/48 vptr_load, target cstring X4000** |
| Gli slot sono dati? | **SÌ, contenuto PROVEN** |
| Sono destinazioni di chiamata? | **UNPROVEN; 283 pattern compatibili** |
| Chiamate a dati X4000? | **Possibili, non attribuite** |
| T27 è GO? | **NO — OPEN** |

**Risposta netta:** gli **835 slot** sono **dati/puntatori** in modo PROVEN; **283** chiamate hanno un **pattern vptr** e **48** usano l’offset **0x28** con target **stringa X4000**. Se appartenessero a X6100, sarebbero **chiamate invalide**. Non è possibile attribuirle senza un boot o un’emulazione. T27 resta **OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
