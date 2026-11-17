# T27 — AGENT-AMD — INTERFACE IDENTITY

**Scope:** risolvere l’identità della superclasse `0x4C271828` e verificare se X6000HWServices pubblica davvero `AMDRadeonX6000_AMDRadeonHWServicesInterface`; ricostruire matching X6000HWLibs, `IOProviderClass`, `Load6000` e condizioni richieste.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, symbol table, disassemblaggio; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che Navi → SWI → Abstract e che Abstract punta a `0x4C271828`. **UNPROVEN** che `0x4C271828` sia l’interfaccia X6000: il target non ha simbolo e la metaclasse Interface ha valore statico zero. **UNPROVEN** il matching X6000HWLibs → Navi. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 100 | `93988c78548766bc642f5774f0f0bec15f576e55311ecd51814538519a41fa35` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Catena registrata

| Classe | Slot superclasse | Target |
|---|---:|---:|
| Navi | `0xC26F070` | `0x4C271800` (SWI) |
| SWI | `0xC26F9F0` | `0x4C271850` (Abstract) |
| Abstract | `0xC270CE8` | `0x4C271828` |
| Interface | `0xC270370` | `0x12AA488` |

**PROVEN:** Navi → SWI → Abstract.
**PROVEN:** Abstract → `0x4C271828`.
**PROVEN:** Interface → `0x12AA488`.
**UNPROVEN:** Abstract → Interface.

---

## 3. Identità `0x4C271828`

| Evidenza | Esito |
|---|---|
| Simbolo al target | **assente** |
| Target = `0x12AA488` | **NO** |
| Target = `0xC26D210` | **NO** |
| Target = metaclass Interface | **non dimostrato** |
| Slot `Interface.metaClass` | `0xC271828` = `0x0` statico |
| Riferimento incrociato | **non trovato** |
| Stringa Interface nel target | **non verificabile** |

**PROVEN:** il target non coincide con i simboli noti.
**UNPROVEN:** l’identità del target.
**UNPROVEN:** la pubblicazione dell’interfaccia.

---

## 4. Costruttore Interface

```text
0xc26d314: leaq 0xee5(%rip), %rsi   ; "AMDRadeonX6000_AMDRadeonHWServicesInterface"
0xc26d31b: movq 0x1cf6(%rip), %rdx  ; superclasse Interface 0x12AA488
0xc26d327: callq 0x10066
```

| Elemento | Valore |
|---|---|
| Nome registrato | **X6000 Interface** |
| Superclasse Interface | **`0x12AA488`** |
| Metaclass Interface | **`0xC271828` = 0** |
| Target Abstract | **`0x4C271828`** |

**PROVEN:** Interface registra il nome X6000.
**PROVEN:** la superclasse Interface è `0x12AA488`.
**UNPROVEN:** che `0x4C271828` sia l’oggetto Interface.

---

## 5. X6000HWLibs

| Condizione | Valore |
|---|---|
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWLibsX6000` |
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `LoadPlugIn=Load6000` |
| Provider Navi | **UNPROVEN** |
| Matching | **UNPROVEN** |

**PROVEN:** la personalità richiede l’interfaccia X6000.
**PROVEN:** richiede `Load6000`.
**UNPROVEN:** che Navi pubblichi l’interfaccia.

---

## 6. Registrazione e matching

| Fase | Evidenza |
|---|---|
| Costruttori MetaClass | **PROVEN** |
| Nomi registrati | **PROVEN** |
| Superclassi | **parzialmente PROVEN** |
| `registerService` | **non tracciato** |
| `probe` | **non tracciato** |
| `start` | **non tracciato** |
| Matching provider | **UNPROVEN** |

**PROVEN:** le classi vengono costruite.
**UNPROVEN:** la pubblicazione del servizio e il matching.

---

## 7. Classificazione

| Affermazione | Esito |
|---|---|
| Navi → SWI | **PROVEN** |
| SWI → Abstract | **PROVEN** |
| Abstract → `0x4C271828` | **PROVEN** |
| `0x4C271828` = Interface | **UNPROVEN** |
| Interface pubblicata | **UNPROVEN** |
| X6000HWLibs matcha Navi | **UNPROVEN** |
| Runtime | **UNPROVEN** |

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Catena Navi → SWI → Abstract | **SÌ** |
| Target Abstract | **`0x4C271828`** |
| Target è Interface | **UNPROVEN** |
| Interface pubblicata | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| Runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la catena registrata è Navi → SWI → Abstract, con Abstract che punta a `0x4C271828`. Il target non ha simbolo, non coincide con `0x12AA488` né con `0xC26D210`, e la metaclasse Interface ha valore statico zero: l’identità `0x4C271828 = Interface` resta **UNPROVEN**. Di conseguenza la pubblicazione dell’interfaccia e il matching di X6000HWLibs con Navi restano **UNPROVEN**; `registerService`, `probe` e `start` non sono tracciati. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
