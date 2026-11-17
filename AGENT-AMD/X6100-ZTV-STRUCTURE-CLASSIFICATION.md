# T27 — AGENT-AMD — X6100 `__ZTV` STRUCTURE CLASSIFICATION

**Scope:** stabilire se le **16 strutture `__ZTV`** di X6100 sono **vtable C++ reali**, **tabelle proprietarie** o **strutture ibride**, usando solo dati read-only: symbol table, sezioni, header, disassembly dei costruttori, cross-reference delle **869 posizioni sorgente** e dei target X4000.

**Modalità:** sola lettura; `nm -n -S`, `otool -l`, `otool -s`, `otool -tvV`, parsing Mach-O/chained fixups. Nessuna estrazione, modifica, build o boot.

**Esito:** **6/16** `__ZTV` hanno **vptr write reali** nei costruttori (`lea __ZTV` + `addq $0x10` + `movq %rcx,(%rax)`), quindi sono **vtable C++ reali a livello di inizializzazione**. Le altre **2** con slot esterni (`AtiPowerPlayInterface`, `AtiApplePowerTuneServices`) **non hanno alcun riferimento** nel testo: sono **vtable-like non istanziate / proprietarie (UNPROVEN)**. Le **8** `__ZTV` senza slot esterni non hanno riferimenti utili. Poiché **tutti gli 869 target esterni sono dati/stringhe X4000 e 0 codice**, le **6 vtable reali** sono **ibride**: struttura C++ valida, ma **entry virtuali non standard**. T27 resta **OPEN**.

---

## 1. Input e metodo

| Input | Uso |
|---|---|
| `X6100-VTABLE-SEMANTIC-VALIDATION.md` | 869 slot, header, offset, target |
| `X6100-EXTERNAL-SOURCE-ATTRIBUTION.md` | 870 `__const` + 16 `__got` |
| `systemkc-all/com.apple.kext.AMDRadeonX6100HWLibs` | `nm`, `otool`, disassembly |

Procedura:
1. **16** simboli `__ZTV` definiti; **0** `__ZTI`;
2. header 16 byte e sezioni `otool -l`/`otool -s`;
3. **`otool -tvV`** completo, filtrato per:
   - riferimenti `__ZTV…`;
   - **vptr store** `movq %rcx,(%rax)`;
   - costruttori/distruttori `C1/C2/D1/D2`;
   - accessi indicizzati `(%rX,%rY,8)`;
4. cross-reference delle **869** posizioni `__ZTV` e dei target X4000.

**Nota:** `nm -n -S` riporta **size 0** per tutti i simboli Mach-O; i confini usati sono quelli del report precedente, basati sul simbolo successivo.

---

## 2. Le 16 `__ZTV`: stato

| Gruppo | Strutture | Slot esterni | vptr store | Riferimenti `__ZTV` | Classificazione |
|---|---:|---:|---:|---:|---|
| 3 main (`X6100`, `HWLibs`, `SWIP`) | 3 | **766** | **5** | **10** | **C++ vtable reale, ibrida** |
| 3 metaclass (`N35`, `N30`, `N34`) | 3 | **69** | **3** | **3** | **C++ vtable reale, ibrida** |
| `AtiPowerPlayInterface` | 1 | **32** | **0** | **0** | **vtable-like non istanziata / proprietaria UNPROVEN** |
| `AtiApplePowerTuneServices` | 1 | **2** | **0** | **0** | **vtable-like non istanziata / proprietaria UNPROVEN** |
| `__ZTV` senza slot esterni | 8 | **0** | **0** | **0** | **non classificabili dal solo dato esterno** |
| **Totale** | **16** | **869** | **8** | **13** | — |

**PROVEN:** solo **6** strutture hanno un **vptr store** diretto e **8** hanno slot esterni. **2** con slot esterni non sono mai referenziate.

---

## 3. vptr store e ABI Itanium

### 3.1 Costruttori principali

| Classe | Costruttore | `lea __ZTV` | vptr store |
|---|---|---|---:|
| X6100 | `__ZN35…X6100C2EPK11OSMetaClass` @ `0xDD6E9D0` | `__ZTV35` @ `0xDD6E9F5` | **0xDD6EA00** |
| X6100 | `C1Ev` @ `0xDD6EBC0` | `__ZTV35` @ `0xDD6EC04` | **0xDD6EC0F** |
| X6100::MetaClass | `C2Ev` @ `0xDD6EB10` | `__ZTVN35` @ `0xDD6EB40` | **0xDD6EB4B** |
| HWLibs | `__ZN30…C2EPK11OSMetaClass` @ `0xDD6EDF0` | `__ZTV30` @ `0xDD6EE15` | **0xDD6EE20** |
| HWLibs | `C2Ev` @ `0xDD6F000` | `__ZTV30` @ `0xDD6F024` | **0xDD6F02F** |
| HWLibs::MetaClass | `C2Ev` @ `0xDD6EF30` | `__ZTVN30` @ `0xDD6EF60` | **0xDD6EF6B** |
| SWIP | `__ZN34…C2EPK11OSMetaClass` @ `0xDD6F780` | `__ZTV34` @ `0xDD6F7A5` | **0xDD6F7B0** |
| SWIP::MetaClass | `C2` @ `0xDD6F820` | `__ZTVN34` @ `0xDD6F850` | **0xDD6F85B** |

Sequenza comune:

```text
leaq __ZTV…(%rip), %rcx
addq $0x10, %rcx
movq %rcx, (%rax)
```

**PROVEN:** il vptr è impostato a **`__ZTV + 0x10`**, cioè **dopo i 16 byte di header**. È esattamente il layout Itanium: `offset-to-top` a `+0`, `typeinfo` a `+8`, **prima entry virtuale a `+0x10`**.

### 3.2 Header

| Campo | Valore |
|---|---:|
| `offset-to-top` | **0** |
| `typeinfo` | **0** |
| prima entry virtuale | **+0x10** |
| `__ZTI` | **0** |

**PROVEN:** header a 2 word e vptr a `+0x10`. **RTTI disabilitato/non serializzato**.

### 3.3 Riferimenti

`otool -tvV` contiene **13** riferimenti a simboli `__ZTV`:

| Simbolo | Riferimenti | vptr store |
|---|---:|---:|
| `__ZTV30…HWLibs` | **7** | **2** |
| `__ZTV35…X6100` | **2** | **2** |
| `__ZTV34…SWIP` | **1** | **1** |
| `__ZTVN30…MetaClass` | **1** | **1** |
| `__ZTVN35…MetaClass` | **1** | **1** |
| `__ZTVN34…MetaClass` | **1** | **1** |
| **Totale** | **13** | **8** |

**PROVEN:** **8** vptr store; **5** riferimenti non-store (passaggio/lettura del simbolo `__ZTV30`). **0 riferimenti** per `AtiPowerPlayInterface` e `AtiApplePowerTuneServices`.

---

## 4. Le 6 vtable C++

Le **6** strutture con vptr store sono:

1. `__ZTV35…X6100`
2. `__ZTV30…HWLibs`
3. `__ZTV34…SWIP`
4. `__ZTVN35…MetaClass`
5. `__ZTVN30…MetaClass`
6. `__ZTVN34…MetaClass`

**PROVEN (meccanica):**
- simboli **`__ZTV`**;
- **costruttori C1/C2** che chiamano la base;
- **vptr = vtable + 0x10**;
- **header a 16 byte**;
- **slot** nei corpi virtuali;
- **nessuna scrittura** alla vtable (è in `__DATA,__const`).

**PROVEN (contenuto):** **835/869** slot di queste 6 vtable puntano a **X4000 dati/tabelle/stringhe**; **0** a codice X4000. **Nessuna** delle 6 è una vtable di **sole funzioni**.

**Classificazione:** **C++ vtable reale a livello di inizializzazione + contenuto ibrido**. La meccanica è C++; il contenuto non è una vtable di funzioni standard.

---

## 5. Le 2 vtable-like non istanziate

| Struttura | Slot esterni | Riferimenti nel testo | vptr store | Header |
|---|---:|---:|---:|---|
| `__ZTV21AtiPowerPlayInterface` | **32** | **0** | **0** | 16 byte zero |
| `__ZTV25AtiApplePowerTuneServices` | **2** | **0** | **0** | 16 byte zero |

**PROVEN:** hanno forma di vtable (header + slot allineati), ma **non sono referenziate** da `otool -tvV`; **nessun costruttore** le installa.

**UNPROVEN:** se siano:
- vtable di **interfacce** mai istanziate in questo binario;
- **tabelle proprietarie** per il power management;
- strutture **dead code**.

**Classificazione:** **vtable-like non istanziate / proprietarie UNPROVEN**.

---

## 6. Le 8 `__ZTV` senza slot esterni

`__ZTV20AtiPowerPlayServices`, `__ZTV30AtiAppleTongaPowerTuneServices`, `__ZTV31AtiAppleVega10PowerTuneServices`, `__ZTV31AtiAppleTahitiPowerTuneServices`, `__ZTV31AtiAppleVega20PowerTuneServices`, `__ZTV31AtiAppleVega12PowerTuneServices`, `__ZTV31AtiAppleNavi10PowerTuneServices`, `__ZTV14AmdTtlServices`.

**PROVEN:** **0** slot esterni; **0** riferimenti `__ZTV` in `otool -tvV`; fuori dagli **869**.

**UNPROVEN:** ruolo; non sono classificabili come vtable C++ attive né come tabelle usate, sulla sola base statica.

---

## 7. Cross-reference dei 869 slot e dei target

| Aspetto | Valore |
|---|---:|
| Slot esterni totali | **869** |
| In vtable con vptr store | **835** |
| In vtable-like senza riferimenti | **34** |
| Target X4000 data/const/cstring | **869** |
| Target X4000 codice | **0** |
| `superClass` esatto esterno | **1** (N30, `0xE11CA90` → `0x12AA488`) |

**PROVEN:** gli slot delle 6 vtable reali e delle 2 non istanziate puntano **solo dati/stringhe X4000**; **nessun** target è codice.

**INFERRED:** le vtable reali sono usate per **dispatch**, ma le entry esterne non sono function pointer standard; possono essere **descrittori dati** o **tabelle di servizio**.

---

## 8. Accessi indicizzati e scritture

| Misura | Valore |
|---|---:|
| Istruzioni `(%rX,%rY,8)` | **1.895** |
| vptr store `movq %rcx,(%rax)` | **70+** (generici, non tutti `__ZTV`) |
| vptr store attribuibili a `__ZTV` | **8** |
| Scritture a `__DATA,__const` | **0** |
| Scritture a `__ZTV` | **0** |

**PROVEN:** le vtable sono **statiche e read-only**; i costruttori scrivono il **vptr nell’oggetto**, non nella vtable. I **1.895** accessi indicizzati sono generici e **non** dimostrano un uso delle 869 entry.

---

## 9. Classificazione finale

| Categoria | Strutture | Evidenza |
|---|---:|---|
| **C++ vtable reale (meccanica)** | **6** | vptr store + header + vtable symbol |
| **Ibrida (vtable reale + target dati)** | **6** | 835/869 slot dati X4000, 0 codice |
| **Vtable-like non istanziata / proprietaria UNPROVEN** | **2** | 34 slot, 0 riferimenti |
| **Non classificabile** | **8** | 0 slot esterni, 0 riferimenti |
| **Tabella proprietaria pura PROVEN** | **0** | nessuna prova |
| **Vtable C++ standard con vfunc di codice** | **0** | 0 target codice |

**Risposta netta:** le **16 `__ZTV` non sono un blocco unico**. **6** sono **vtable C++ reali** per inizializzazione e layout, ma **ibride** perché contengono target dati; **2** sono **vtable-like non istanziate**; **8** non hanno slot esterni. **Nessuna** è una vtable C++ standard con funzioni virtuali di codice. **Nessuna** è dimostrabile come tabella proprietaria pura.

---

## 10. Limiti

- `nm -S` non fornisce size Mach-O: i confini sono dal simbolo successivo, non da una size.
- `otool -tvV`的非-store references sono state contate, non decompilate semanticamente.
- I **1.895** accessi indicizzati non sono attribuibili automaticamente alle vtable.
- **RTTI assente**: impossibile validare `typeinfo`/`__ZTI`.
- **Nessun boot**: la callability delle entry dati resta **UNPROVEN**.

---

## 11. Conclusione

| Domanda | Risposta |
|---|---|
| 16 `__ZTV` sono tutte vtable C++? | **NO: 6 reali meccanicamente, 2 non istanziate, 8 senza slot esterni** |
| Le 6 hanno vptr store? | **SÌ: 8 store, vptr = `__ZTV + 0x10`** |
| Hanno RTTI? | **NO: 0 `__ZTI`** |
| Sono standard? | **NO: 835/869 target dati, 0 codice** |
| Sono ibride? | **SÌ, per le 6 vtable reali** |
| Sono tabelle proprietarie? | **0 PROVEN; 2 UNPROVEN** |
| T27 è GO? | **NO — OPEN** |

**Sintesi:** la meccanica C++ è **PROVEN** per **6** strutture (vptr a `+0x10`, header a 16 byte, costruttori C1/C2). Il contenuto è **ibrido**: **835** slot verso dati/stringhe X4000, **0** verso codice. Le **2** vtable-like con slot esterni non sono mai referenziate; le **8** senza slot esterni restano fuori. T27 resta **OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**STOP rispettato:** sola lettura; nessuna estrazione, copia, modifica, build o boot. Spazio libero ultimo controllo **≈12,28 GiB** > **10 GiB**.
