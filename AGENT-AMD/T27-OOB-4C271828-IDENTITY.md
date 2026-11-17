# T27 — AGENT-AMD — 4C271828 IDENTITY

**Scope:** determinare l’identità reale di `0x4C271828` e verificare il matching X6000HWLibs → Navi sulla Radeon Pro 5300M (`0x7340`); esaminare metaclass, vtable, simboli, riferimenti incrociati e registrazione IOKit.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, symbol table, disassemblaggio, mappa dei segmenti; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che `0x4C271828` non ricade in nessun segmento di BootKC o SystemKC e non ha simbolo. **UNPROVEN** che sia l’interfaccia X6000. **UNPROVEN** il matching X6000HWLibs → Navi. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 101 | `62ef7632ed03beca728695ba768b23f51b5435f7d0e7960a72fc665d30eaa2e7` |

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

---

## 3. Mappa dei segmenti

| Binario | Segmenti contenenti `0x4C271828` |
|---|---|
| BootKC | **nessuno** |
| SystemKC | **nessuno** |

| Evidenza | Esito |
|---|---|
| Indirizzo in `__TEXT` BootKC | **NO** |
| Indirizzo in `__DATA` BootKC | **NO** |
| Indirizzo in `__TEXT_EXEC` SystemKC | **NO** |
| Indirizzo in `__DATA` SystemKC | **NO** |
| Byte leggibili | **NO** |
| Simbolo | **NO** |

**PROVEN:** il target non è mappato nei due file.
**PROVEN:** non è possibile leggere l’oggetto.
**UNPROVEN:** l’identità del target.

---

## 4. Fixup

| Slot | Raw | Target | high8 | next | bind |
|---|---:|---:|---:|---:|---:|
| `0xC270CE8` | `0xC000004C271828` | `0x4C271828` | `0` | `24` | `0` |
| `0xC26F070` | `0xC000004C271800` | `0x4C271800` | `0` | `24` | `0` |
| `0xC26F9F0` | `0xC000004C271850` | `0x4C271850` | `0` | `24` | `0` |

**PROVEN:** i tre fixup sono rebase.
**PROVEN:** i target sono consecutivi (`0x...1800`, `0x...1850`, `0x...1828`).
**UNPROVEN:** la classe del target finale.

---

## 5. Interface

| Elemento | Valore |
|---|---|
| Nome registrato | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| MetaClassC1 | `0xC26D210` |
| Superclasse | `0x12AA488` |
| Slot `metaClass` | `0xC271828` = `0x0` statico |
| Target Abstract | `0x4C271828` |
| Corrispondenza | **NON DIMOSTRATA** |

**PROVEN:** Interface registra il nome X6000.
**PROVEN:** la superclasse Interface è `0x12AA488`.
**UNPROVEN:** che `0x4C271828` sia Interface.

---

## 6. X6000HWLibs

| Condizione | Valore |
|---|---|
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWLibsX6000` |
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `LoadPlugIn=Load6000` |
| Provider Navi | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| Matching | **UNPROVEN** |

**PROVEN:** la personalità richiede l’interfaccia X6000 e `Load6000`.
**UNPROVEN:** che Navi pubblichi l’interfaccia e la proprietà.

---

## 7. Registrazione IOKit

| Fase | Evidenza |
|---|---|
| Costruttori MetaClass | **PROVEN** |
| Nomi registrati | **PROVEN** |
| Superclassi | **parzialmente PROVEN** |
| `registerService` | **non tracciato** |
| `probe` | **non tracciato** |
| `start` | **non tracciato** |
| Percorsi alternativi | **nessuno osservato** |

**PROVEN:** le classi vengono costruite.
**UNPROVEN:** pubblicazione e matching runtime.

---

## 8. Classificazione

| Affermazione | Esito |
|---|---|
| Navi → SWI | **PROVEN** |
| SWI → Abstract | **PROVEN** |
| Abstract → `0x4C271828` | **PROVEN** |
| `0x4C271828` = Interface | **UNPROVEN** |
| Interface pubblicata | **UNPROVEN** |
| X6000HWLibs → Navi | **UNPROVEN** |
| Percorso alternativo | **NON OSSERVATO** |
| Runtime | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Target in BootKC/SystemKC | **NO** |
| Target simbolizzato | **NO** |
| Target = Interface | **UNPROVEN** |
| Interface pubblicata | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| Runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la catena registrata è Navi → SWI → Abstract → `0x4C271828`. Il target non ricade in nessun segmento di BootKC o SystemKC, non ha simbolo e non è leggibile staticamente; la metaclasse Interface ha valore statico zero. L’identità `0x4C271828 = Interface`, la pubblicazione dell’interfaccia e il matching X6000HWLibs → Navi restano **UNPROVEN**. `registerService`, `probe` e `start` non sono tracciati e non sono emersi percorsi alternativi. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
