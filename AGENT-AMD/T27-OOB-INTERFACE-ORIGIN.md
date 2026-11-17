# T27 — AGENT-AMD — INTERFACE ORIGIN

> **RETTIFICA (Prompt 114):** X6000 Interface ha vtable completa a `0xC270378` e costruttore a `0xC26D260`; `0xC271828` è solo `gMetaClass`, non la vtable. La frase “vtable assente” è **RITIRATA**. Vale il report 114.

**Scope:** identificare l’origine effettiva di Abstract e X6000 Interface, verificare se i simboli X4000 costituiscono un’interfaccia condivisa utilizzabile da Navi, risolvere metaclass/superclass/vtable e stabilire se Interface è disponibile come provider.

**Modalità:** sola lettura; SystemKC/BootKC, symbol table, stringhe, riferimenti; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che Abstract e Interface usano simboli X4000 reali, che X6000 Interface ha metaclass `0xC26D210` e superclasse `0x12AA488`, e che `gMetaClass` Interface (`0xC271828`) è **0**. **UNPROVEN** che X6000 Interface sia istanziabile o pubblicabile come provider. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 112 | `12a7ded25a94a2b6549b5a2937e791f71c55e82871188d0aba9b7f70e66bc09b` |
| Report 111 | `e52dae97710ccf161ac7dcf619a74e803c0b2fb6870631b4ec1265db3f806b2b` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Simboli X4000

| Simbolo | Indirizzo |
|---|---:|
| `AMDRadeonX4000_AMDRadeonHWServicesInterface::MetaClassC1` | `0x6E0DA0` |
| `…Interface::MetaClassC2` | `0x6E0E90` |
| `…Interface::Interface(OSMetaClass*)` | `0x6E0DF0` |
| `…Interface::~Interface` | `0x6E0E30` |
| `…Interface::getMetaClass` | `0x6E0E70` |
| `…Abstract::getTtl` | `0x6E0D10` |
| `…Abstract::MetaClassC1` | `0x6E0F80` |
| `…Abstract::gMetaClass` | `0x6E5860` |
| `…Interface::gMetaClass` | `0x6E5838` |

**PROVEN:** X4000 ha Abstract e Interface completi.
**PROVEN:** i simboli sono in SystemKC.
**UNPROVEN:** il kext proprietario esatto.

---

## 3. X6000 Interface

| Elemento | Valore |
|---|---:|
| `MetaClassC1` | `0xC26D210` |
| Superclasse | `0x12AA488` |
| `gMetaClass` | `0xC271828` |
| Valore `gMetaClass` | **0** |
| Vtable | **assente** |
| Costruttore | **non osservato** |

**PROVEN:** la superclasse è `0x12AA488`.
**PROVEN:** `gMetaClass` è nullo.
**PROVEN:** non c’è vtable Interface a `0xC271828`.
**UNPROVEN:** l’identità della superclasse.

---

## 4. Riferimenti

| Indirizzo | Tipo | Offset |
|---|---:|---:|
| `0xC2717D8` (Navi gMetaClass) | storage | `358477928` |
| `0xC271800` (SWI gMetaClass) | storage + 4 byte | `358478184`, `15872711` |
| `0xC271828` (Interface gMetaClass) | storage | `358478808` |

**PROVEN:** i tre indirizzi sono presenti.
**PROVEN:** Interface è solo storage.
**PROVEN:** non ci sono xref di codice a Interface.
**UNPROVEN:** il riferimento a 4 byte di SWI.

---

## 5. Dipendenze X4000/X5000/X6000

| Elemento | Evidenza |
|---|---|
| X4000 Abstract | **simboli completi** |
| X4000 Interface | **simboli completi** |
| X5000 Interface | **superclasse `0x12AA488`** |
| X6000 Interface | **superclasse `0x12AA488`** |
| X6000 Navi/SWI | **metaclass X6000** |
| X6000 Abstract | **simboli X4000** |

**PROVEN:** X4000 fornisce implementazioni condivise.
**PROVEN:** X5000/X6000 condividono la superclasse Interface.
**UNPROVEN:** che `0x12AA488` sia X4000 Interface.
**UNPROVEN:** la catena di ereditarietà completa.

---

## 6. Interface come provider

| Requisito | Esito |
|---|---|
| Classe X6000 Interface | **presente** |
| Metaclass | **presente** |
| `gMetaClass` | **0** |
| Vtable | **assente** |
| Costruttore | **non osservato** |
| Pubblicazione | **UNPROVEN** |
| Disponibile come provider | **UNPROVEN** |

**PROVEN:** la classe è incompleta staticamente.
**PROVEN:** non è pubblicata.
**UNPROVEN:** un’istanza runtime.

---

## 7. X6000HWLibs

| Requisito | Valore |
|---|---|
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `LoadPlugIn=Load6000` |
| Interface disponibile | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| Matching | **UNPROVEN** |

**PROVEN:** i requisiti.
**UNPROVEN:** la disponibilità del provider.

---

## 8. Classificazione

| Affermazione | Esito |
|---|---|
| X4000 fornisce Abstract/Interface | **PROVEN** |
| X6000 Interface ha superclasse `0x12AA488` | **PROVEN** |
| X6000 Interface ha `gMetaClass=0` | **PROVEN** |
| X6000 Interface ha vtable | **NO** |
| Interface è provider | **UNPROVEN** |
| Navi pubblica Interface | **UNPROVEN** |
| Matching HWLibs | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Origine Abstract | **X4000** |
| Origine Interface | **X4000** |
| X6000 Interface completa | **NO** |
| `0x12AA488` risolta | **NO** |
| Interface provider | **UNPROVEN** |
| Navi pubblica Interface | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** Abstract e Interface hanno implementazioni X4000 reali in SystemKC; X6000 Interface ha metaclass `0xC26D210`, superclasse `0x12AA488` e `gMetaClass` nullo a `0xC271828`, senza vtable né costruttore osservato. I tre indirizzi `0xC2717D8`, `0xC271800` e `0xC271828` sono presenti come storage, ma Interface non ha xref di codice. X4000 fornisce la base condivisa, ma non è provato che `0x12AA488` sia X4000 Interface né che X6000 Interface sia istanziabile o pubblicabile come provider. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
