# T27 — AGENT-AMD — CLASS HIERARCHY

**Scope:** determinare se `AMDRadeonX6000_AMDRadeonHWServicesInterface` eredita dall’interfaccia X5000 richiesta da X5400; risolvere la relocation a `0xC26F018`; ricostruire vtable, metaclass, superclass e costruttori; verificare alias, superclassi intermedie, compatibilità ABI e `Load5400` indiretto.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, symbol table, disassemblaggio, plist `PRELINK_INFO`; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che il costruttore X6000 registra il nome `AMDRadeonX6000_AMDRadeonHWServicesInterface` e carica la superclasse da uno slot relocated. **PROVEN** che il valore low-36 è `0x12AA488`, senza simbolo e diverso dalla metaclasse X5000 `0x457F360`; la risoluzione completa del fixup resta non disponibile. **REFUTED** che X6000 pubblichi `Load5400`. **UNPROVEN** l’ereditarietà X6000 → X5000 e il caricamento X5400. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 93 | `516daa4e342f8cb04c4574950889a6c06d67100bbb1dda7e6dcd5a97e27da1a2` |
| Report 94 | `63609ac2c9362b7f982b1904666424e1562f5fbe98157ace608ed2c24a899086` |
| Report 95 | `3639ca461ee5da0b79b166fe5b10a3c11d055036b11625a23cc53c8644701b1e` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Simboli X6000

| Simbolo | VA |
|---|---:|
| `AMDRadeonX6000_AMDRadeonHWServicesInterface9MetaClassC1Ev` | `0xC26D210` |
| `AMDRadeonX6000_AMDRadeonHWServicesInterface10superClassE` | `0xC270370` |
| `AMDRadeonX6000_AMDRadeonHWServicesNavi9MetaClassC1Ev` | `0xC26C930` |
| `AMDRadeonX6000_AMDRadeonHWServicesNavi10superClassE` | `0xC26F070` |
| `AMDRadeonX6000_AMDRadeonHWServicesInterface10gMetaClassE` | `0xC271828` |

**PROVEN:** le classi X6000 sono presenti nel fileset.
**PROVEN:** interfaccia e Navi sono distinte.

---

## 3. Costruttore interfaccia X6000

```text
0xc26d314: leaq 0xee5(%rip), %rsi   ; "AMDRadeonX6000_AMDRadeonHWServicesInterface"
0xc26d31b: movq 0x1cf6(%rip), %rdx  ; superclasse
0xc26d327: callq 0x10066
```

| Elemento | Valore |
|---|---|
| Slot superclasse | `0xC26F018` |
| Valore grezzo | `0x400000012AA488` |
| Target low-36 | `0x12AA488` |
| Simbolo al target | **assente** |
| Metaclasse X5000 | `0x457F360` |
| Target == X5000 | **NO** |

**PROVEN:** la superclasse è caricata da `0xC26F018`.
**PROVEN:** il target low-36 è `0x12AA488`.
**PROVEN:** non coincide con la metaclasse X5000.
**UNPROVEN:** l’identità del target.

---

## 4. Costruttore Navi X6000

```text
0xc26c940: callq 0xc26cac0
0xc26c99c: callq 0xc26ce10
0xc26c9a5: leaq 0x26cc(%rip), %rcx
0xc26c9d8: callq 0xc26c980
```

| Elemento | Esito |
|---|---|
| MetaClass C2 | `0xc26cac0` |
| Costruttore intermedio | `0xc26ce10` |
| Superclasse Navi | `0xc26f070` |
| Interfaccia X6000 | `0xc26d210` |

**PROVEN:** Navi ha una catena di costruzione separata.
**UNPROVEN:** che Navi erediti dall’interfaccia X6000 o X5000.

---

## 5. Riferimenti X5000

| Evidenza | Esito |
|---|---|
| Letterale X5000 nel binario X6000 | **ASSENTE** |
| Occorrenze X5000 nel SystemKC | **5, solo `PRELINK_INFO` XML** |
| Metaclasse X5000 | `0x457F360` |
| Superclasse X5000 | `0x457F368` |
| Costruttore X5000 | `0x457C2C0` |

**PROVEN:** X6000 non contiene il letterale X5000.
**PROVEN:** la metaclasse X5000 esiste in X5000HWServices.
**UNPROVEN:** un collegamento indiretto X6000 → X5000.

---

## 6. `Load5400`

| Evidenza | Esito |
|---|---|
| Occorrenze in SystemKC | **1** |
| Dove | **solo personalità X5400** |
| Pubblicato da X6000 | **NO** |
| Pubblicato da X5000 | **NO** |
| Pubblicato da X5400 | **NO** |
| Soddisfazione indiretta | **NON DIMOSTRATA** |

**PROVEN:** `Load5400` non è una proprietà pubblicata da X6000.
**REFUTED:** la soddisfazione indiretta tramite X6000.
**UNPROVEN:** eventuali altri publisher runtime.

---

## 7. Vtable e ABI

| Elemento | Esito |
|---|---|
| Vtable X6000 Interface | **presente** |
| Vtable X6000 Navi | **presente** |
| Vtable X5000 Interface | **presente** |
| Superclasse X6000 risolta | **NO** |
| Compatibilità ABI X6000/X5000 | **UNPROVEN** |
| Alias X6000/X5000 | **nessuno osservato** |

**PROVEN:** le vtable esistono.
**UNPROVEN:** la compatibilità ABI.

---

## 8. Classificazione

| Collegamento | Esito |
|---|---|
| X6000HWServices → interfaccia X6000 | **PROVEN** |
| X6000 → interfaccia X5000 | **UNPROVEN** |
| X5000HWServices → GPU `0x7340` | **REFUTED** |
| X6000HWServices → GPU `0x7340` | **PROVEN** |
| X5400 → provider X5000 | **UNPROVEN** |
| X5400 → `Load5400` | **UNPROVEN** |
| AMDSupport → GPU | **PROVEN statico** |
| X5400 caricato | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Superclasse X6000 risolta | **NO** |
| Target `0x12AA488` = X5000 | **NO** |
| X6000 pubblica `Load5400` | **NO** |
| Ereditarietà X6000 → X5000 | **UNPROVEN** |
| X5000 su `0x7340` | **NO** |
| X6000 su `0x7340` | **SÌ** |
| X5400 caricato | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il costruttore dell’interfaccia X6000 registra il nome X6000 e carica la superclasse dallo slot `0xC26F018`; il valore low-36 `0x12AA488` non ha simbolo e non coincide con la metaclasse X5000 `0x457F360`. Il binario X6000 non contiene il letterale X5000 e non pubblica `Load5400`, che compare solo nella personalità X5400. L’ereditarietà X6000 → X5000, la compatibilità ABI e la soddisfazione indiretta di `Load5400` restano **UNPROVEN**; il caricamento di X5400 resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
