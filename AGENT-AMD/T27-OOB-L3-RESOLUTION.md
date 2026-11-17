# T27 — AGENT-AMD — L3 RESOLUTION

**Scope:** identificare il meccanismo di risoluzione dei puntatori L3, verificare se X5000/X6000 Interface condividono realmente una superclass implementata, confrontare costruttori/metaclass/vtable e ricostruire le dipendenze X6000HWLibs.

**Modalità:** sola lettura; SystemKC/BootKC, fileset X5000/X6000, chained metadata, costruttori; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che entrambi i costruttori Interface chiamano lo stesso stub `0x10180` e impostano la propria vtable; **PROVEN** che condividono la superclass a livello di costruzione. **UNPROVEN** la base L3 e l’identità della superclass. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 116 | `222759aa3b733e23bae7e543025519eab04dfa32b6ca1da97ee882f93cd8406b` |
| Report 115 | `3be12c80b70f2d7bde309761e34f3331f1ef642af01a79ecf5548fb953d93308` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Metadati dyld

| Campo | Valore |
|---|---:|
| `fixups_version` | `0` |
| `starts_offset` | `28` |
| `imports_count` | `0` |
| `imports_format` | `1` |
| `symbols_format` | `0` |
| `pointer_format` | `11` |

**PROVEN:** non ci sono import.
**PROVEN:** non c’è una tabella di basi L2/L3.
**UNPROVEN:** la risoluzione L3 statica.

---

## 3. Costruttori Interface

| Classe | Costruttore | Stub superclass | Vtable |
|---|---:|---:|---:|
| X5000 Interface | `0x457C310` | `0x10180` | `0x457F370` |
| X6000 Interface | `0xC26D260` | `0x10180` | `0xC270378` |

**PROVEN:** entrambi chiamano lo stesso stub.
**PROVEN:** entrambi impostano la propria vtable.
**PROVEN:** la superclass è costruita dallo stesso stub.
**UNPROVEN:** l’identità dello stub.

---

## 4. Disassemblaggio comparato

```text
X5000 0x457C32C: callq 0x10180
X5000 0x457C335: leaq 0x3034(%rip), %rcx   ; 0x457F370
X5000 0x457C33C: addq $0x10, %rcx
X5000 0x457C340: movq %rcx, (%rax)

X6000 0xC26D27C: callq 0x10180
X6000 0xC26D285: leaq 0x30EC(%rip), %rcx   ; 0xC270378
X6000 0xC26D28C: addq $0x10, %rcx
X6000 0xC26D290: movq %rcx, (%rax)
```

| Test | Esito |
|---|---|
| Stub condiviso | **SÌ** |
| Vtable distinte | **SÌ** |
| Superclass costruita | **SÌ** |
| `registerService` | **NO** |

**PROVEN:** la struttura è identica.
**PROVEN:** le classi sono sorelle.
**PROVEN:** non pubblicano nel costruttore.

---

## 5. Superclass

| Elemento | Valore |
|---|---:|
| `superClass` X5000 | `0x457F368` |
| `superClass` X6000 | `0xC270370` |
| Raw | `0xC00000012AA488` |
| Target | `0x12AA488` |
| `cacheLevel` | `3` |
| Base L3 | **UNPROVEN** |
| Identità | **UNPROVEN** |

**PROVEN:** il puntatore è identico.
**PROVEN:** la superclass è condivisa.
**UNPROVEN:** la sua implementazione.

---

## 6. Implementazione della superclass

| Ricerca | Esito |
|---|---|
| Simbolo `0x12AA488` | **nessuno** |
| Classe C++ | **NO** |
| Implementazione in X4000 | **UNPROVEN** |
| Implementazione in X5000 | **UNPROVEN** |
| Implementazione in X6000 | **UNPROVEN** |
| Stub `0x10180` | **UNPROVEN** |

**PROVEN:** non c’è un simbolo.
**UNPROVEN:** l’implementazione.

---

## 7. Dipendenze X6000HWLibs

| Requisito | Valore |
|---|---|
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `LoadPlugIn=Load6000` |
| Interface completa | **SÌ** |
| Interface pubblicata | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| Matching | **UNPROVEN** |

**PROVEN:** i requisiti.
**UNPROVEN:** la disponibilità.

---

## 8. Separazione

| Concetto | Esito |
|---|---|
| Identità strutturale Interface | **PROVEN** |
| Ereditarietà superclass | **PROVEN strutturale** |
| Identità superclass | **UNPROVEN** |
| Pubblicazione Interface | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Base L3 | **UNPROVEN** |
| Stub superclass | `0x10180` |
| Superclass condivisa | **SÌ** |
| Identità superclass | **UNPROVEN** |
| Interface completa | **SÌ** |
| Interface pubblicata | **UNPROVEN** |
| Matching | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** i costruttori X5000 e X6000 Interface sono strutturalmente identici: chiamano lo stesso stub `0x10180` per la superclass e impostano la propria vtable (`0x457F370`, `0xC270378`). La superclass è quindi condivisa e costruita, ma la base L3 e l’identità di `0x12AA488` restano **UNPROVEN**; non esiste una tabella di basi L2/L3 nei metadati dyld. Interface è completa e non pubblica nel costruttore; pubblicazione e matching X6000HWLibs restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
