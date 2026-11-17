# T27 — AGENT-AMD — FIXUP RESOLUTION

**Scope:** identificare il destinatario della relocation a `0xC26F018` e verificare se corrisponde a una classe AMD compatibile con X5000; ricostruire target, high8, next, bind e confrontare la gerarchia X5000/X6000.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, symbol table, disassemblaggio; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che X6000 Interface e X5000 Interface caricano la superclasse dallo stesso slot con lo stesso valore `0x400000012AA488` (`target 0x12AA488`, `high8 0`, `next 8`, `bind 0`). **PROVEN** che la classe Navi X6000 usa una superclasse diversa (`0xC000004C271800`, target `0x4C271800`). **REFUTED** che X6000 Interface erediti da X5000 Interface e che X6000 Navi fornisca il provider X5000 richiesto da X5400. **UNPROVEN** il caricamento runtime. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 95 | `3639ca461ee5da0b79b166fe5b10a3c11d055036b11625a23cc53c8644701b1e` |
| Report 96 | `de9f18fb4959cb8453ad586fcd83a2fd050b3b30dac814a4c1d99470ac609b22` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Fixup X6000 Interface

| Campo | Valore |
|---|---|
| Slot | `0xC26F018` |
| Raw | `0x400000012AA488` |
| Target | `0x12AA488` |
| high8 | `0` |
| next | `8` |
| bind | `0` |
| cacheLevel | **non presente nel fixup** |

**PROVEN:** il fixup è un rebase, non un bind.
**PROVEN:** `next=8` indica la continuazione della catena.
**PROVEN:** il target è `0x12AA488`.

---

## 3. Fixup X5000 Interface

| Campo | Valore |
|---|---|
| Slot | `0x457E018` |
| Raw | `0x400000012AA488` |
| Target | `0x12AA488` |
| high8 | `0` |
| next | `8` |
| bind | `0` |

**PROVEN:** lo slot X5000 contiene lo stesso valore dello slot X6000.
**PROVEN:** le due interfacce condividono la stessa superclasse.
**REFUTED:** X5000 come superclasse di X6000.

---

## 4. Fixup Navi X6000

| Campo | Valore |
|---|---|
| Slot | `0xC26F070` |
| Raw | `0xC000004C271800` |
| Target | `0x4C271800` |
| high8 | `0` |
| next | `24` |
| bind | `0` |

**PROVEN:** la superclasse Navi è diversa da quella dell’interfaccia X6000.
**PROVEN:** la superclasse Navi non è `0xC26D210`.
**REFUTED:** Navi come sottoclasse dell’interfaccia X6000.

---

## 5. Gerarchia risultante

```text
base comune 0x12AA488
  ├── X5000 Interface   (slot 0x457E018)
  └── X6000 Interface   (slot 0xC26F018)

base Navi 0x4C271800
  └── X6000 Navi        (slot 0xC26F070)
```

| Relazione | Esito |
|---|---|
| X6000 Interface → X5000 Interface | **REFUTED** |
| X5000 Interface → X6000 Interface | **REFUTED** |
| X6000 Navi → X6000 Interface | **REFUTED** |
| X6000 Interface e X5000 Interface | **SORELLE** |
| X6000 Navi e X6000 Interface | **SEPARATE** |

**PROVEN:** la gerarchia è quella indicata.
**REFUTED:** l’ereditarietà X6000 → X5000.

---

## 6. Conseguenza sul provider X5400

| Elemento | Esito |
|---|---|
| X5400 richiede X5000 Interface | **SÌ** |
| X6000 Interface è X5000 Interface | **NO** |
| X6000 Navi è X5000 Interface | **NO** |
| X6000 pubblica `Load5400` | **NO** |
| Provider X5000 su `0x7340` | **NON DISPONIBILE** |
| X5400 caricato | **UNPROVEN** |

**PROVEN:** X6000 non fornisce la classe X5000.
**PROVEN:** `Load5400` non è pubblicato da X6000.
**REFUTED:** la catena statica X6000 → X5000 → X5400.
**UNPROVEN:** il caricamento runtime di X5400.

---

## 7. Compatibilità ABI

| Elemento | Esito |
|---|---|
| Superclasse comune X5000/X6000 | **SÌ, `0x12AA488`** |
| Stessa vtable | **NO** |
| Stessa interfaccia | **NO** |
| Compatibilità ABI diretta | **NON DIMOSTRATA** |
| Alias | **nessuno osservato** |

**PROVEN:** la base comune non implica la stessa interfaccia.
**UNPROVEN:** una compatibilità ABI diretta.

---

## 8. Impatto su T27

| Domanda | Risposta |
|---|---|
| X5400 può usare X6000 come provider | **NO, staticamente** |
| X6000 Interface eredita X5000 | **NO** |
| X6000 Navi eredita X5000 | **NO** |
| `Load5400` disponibile | **NO** |
| X5400 caricato su `0x7340` | **UNPROVEN** |
| AMDSupport caricato | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Target fixup X6000 | **`0x12AA488`** |
| Target fixup X5000 | **`0x12AA488`** |
| Stessa superclasse | **SÌ** |
| X6000 figlia di X5000 | **NO** |
| Navi figlia di X6000 Interface | **NO** |
| Provider X5000 su Navi | **NO** |
| X5400 caricato | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il fixup `0xC26F018` decodifica `target=0x12AA488`, `high8=0`, `next=8`, `bind=0`. Lo stesso valore compare nello slot `0x457E018` di X5000 Interface: X6000 Interface e X5000 Interface sono **classi sorelle**, non parente/figlia. La classe Navi X6000 usa invece la superclasse `0x4C271800`. Di conseguenza X6000 non fornisce l’interfaccia X5000 richiesta da X5400 e non pubblica `Load5400`: la catena statica X6000 → X5000 → X5400 è **REFUTED**. Il caricamento runtime di X5400 resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
