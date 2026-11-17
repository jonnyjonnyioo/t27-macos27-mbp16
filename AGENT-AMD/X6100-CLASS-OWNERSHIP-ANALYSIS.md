# T27 — AGENT-AMD — X6100 CLASS OWNERSHIP ANALYSIS

**Scope:** identificare le classi proprietarie delle **6 vtable C++**, degli **8 vptr store** e delle **11 chiamate** attribuite in precedenza a “X6100”. Chiarire la gerarchia **HWLibs → SWIP → X6100** e distinguere la **classe X6100 esatta** dalle classi **HWLibs/SWIP** dello stesso kext.

**Modalità:** sola lettura; `nm -n`, `otool -tvV`, parsing chained fixups. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** le **6 vtable** appartengono a **3 classi**: `AMDRadeonX6100_AMDRadeonHWLibsX6100` (`__ZTV35` + `__ZTVN35`), `AMDRadeonX6100_AMDRadeonHWLibs` (`__ZTV30` + `__ZTVN30`), `AMDRadeonX6100_AMDRadeonHWLibsSWIP` (`__ZTV34` + `__ZTVN34`). Gli **8 vptr store** sono **3 + 3 + 2**. Le **11 chiamate** sono **7 in HWLibs + 4 in SWIP + 0 nella classe X6100 esatta**. **Nessuna** delle 11 usa la main vtable del proprietario. T27 resta **OPEN**.

---

## 1. Correzione terminologica

Nel report precedente “**11 chiamate X6100**” indicava **funzioni del kext X6100**, non della **classe `…X6100`**. Con il filtro esatto:

| Filtro | Call |
|---|---:|
| **`__ZN35…HWLibsX6100…`** (classe X6100 esatta) | **0** |
| **`__ZN30…HWLibs…`** | **7** |
| **`__ZN34…SWIP…`** | **4** |
| **Totale kext** | **11** |

**PROVEN:** **0/283** vptr_load sono in metodi della **classe X6100 esatta**. Le 11 sono in **HWLibs** e **SWIP**.

---

## 2. Le 3 classi e le 6 vtable

| Classe | Vtable main | Size | MetaClass | Size | vptr store |
|---|---|---:|---|---:|---:|
| **`AMDRadeonX6100_AMDRadeonHWLibsX6100`** | `__ZTV35` `0xE11C130` | **0x870** | `__ZTVN35` `0xE11C9A0` | **0xE8** | **3** |
| **`AMDRadeonX6100_AMDRadeonHWLibs`** | `__ZTV30` `0xE11CA98` | **0x868** | `__ZTVN30` `0xE11D300` | **0xE8** | **3** |
| **`AMDRadeonX6100_AMDRadeonHWLibsSWIP`** | `__ZTV34` `0xE11D3F8` | **0x870** | `__ZTVN34` `0xE11DC68` | **0xE8** | **2** |
| **Totale** | **6 vtable** | **0x1C00** | **3 meta** | **0x2B8** | **8** |

**PROVEN:** ogni classe ha **main + MetaClass**; ogni main è preceduta dal simbolo **`metaClass`** e **`superClass`**. La regione completa va da **`0xE11C130`** a **`0xE11DD50`**.

---

## 3. Gli 8 vptr store

| # | Classe | Funzione | Store | Vtable |
|---:|---|---|---:|---|
| 1 | X6100 | `C2EPK11OSMetaClass` `0xDD6E9D0` | `0xDD6EA00` | `__ZTV35` |
| 2 | X6100 | `C1Ev` `0xDD6EBC0` | `0xDD6EC0F` | `__ZTV35` |
| 3 | X6100::MetaClass | `C2Ev` `0xDD6EB10` | `0xDD6EB4B` | `__ZTVN35` |
| 4 | HWLibs | `C2EPK11OSMetaClass` `0xDD6EDF0` | `0xDD6EE20` | `__ZTV30` |
| 5 | HWLibs | `C2Ev` `0xDD6F000` | `0xDD6F02F` | `__ZTV30` |
| 6 | HWLibs::MetaClass | `C2Ev` `0xDD6EF30` | `0xDD6EF6B` | `__ZTVN30` |
| 7 | SWIP | `C2EPK11OSMetaClass` `0xDD6F780` | `0xDD6F7B0` | `__ZTV34` |
| 8 | SWIP::MetaClass | `C2Ev` `0xDD6F820` | `0xDD6F85B` | `__ZTVN34` |

Pattern:

```text
leaq __ZTV…(%rip), %rcx
addq $0x10, %rcx
movq %rcx, (%rax)
```

**PROVEN:** **5 store main** + **3 store MetaClass**; **vptr = `__ZTV + 0x10`**; **0 `__ZTI`**; **0 scritture successive**.

---

## 4. Gerarchia

I simboli **`superClass`** e **`metaClass`** sono puntatori con fixup:

| Classe | `metaClass` | `superClass` | Target |
|---|---|---|---:|
| **X6100** | `0xE11C120` | `0xE11C128` | **`0xED11A60` = SWIP::gMetaClass** |
| **HWLibs** | `0xE11CA88` | `0xE11CA90` | **`0x12AA488` esterno** |
| **SWIP** | `0xE11D3E8` | `0xE11D3F0` | **`0xED11A38` = HWLibs::gMetaClass** |

**PROVEN:**
- **X6100 → SWIP**;
- **SWIP → HWLibs**;
- **HWLibs → esterno `0x12AA488`**.

**UNPROVEN:** la classe del target **`0x12AA488`**; non è un `gMetaClass` del kext X6100.

**Conseguenza:** la gerarchia è **HWLibs (base) → SWIP → X6100 (derivata)**. Le 6 vtable sono **2 per livello**, non 6 vtable della stessa classe.

---

## 5. Le 11 chiamate: proprietario effettivo

| Classe | Call | Funzioni |
|---|---:|---|
| **X6100 esatta** | **0** | — |
| **HWLibs** | **7** | `free` 1, `attach` 4, `callPlatformFunction` 2 |
| **SWIP** | **4** | `free` 1, `callPlatformFunction` 1, `createTtlInterface` 2 |
| **Totale** | **11** | |

Dettaglio:
- **2** con `%rdi` da **campo** (`0xa8`, `0xb8`) nei due `free`;
- **9** con `%rdi` da **stack locale** (`attach`, `callPlatformFunction`, `createTtlInterface`);
- **0** con `%rdi` = `this` non modificato;
- **0** su `__ZTV35`, `__ZTV30` o `__ZTV34` main.

**PROVEN:** le 11 sono **HWLibs/SWIP**, non **X6100 esatta**.
**UNPROVEN:** la classe dei sotto-oggetti e dei locali puntati.

---

## 6. Ruolo delle 6 vtable

| Vtable | Proprietario | vptr store | Dispatch main | Uso osservato |
|---|---|---:|---:|---|
| `__ZTV35` | X6100 | 2 | **0** | costruzione |
| `__ZTVN35` | X6100::MetaClass | 1 | **0** | costruzione |
| `__ZTV30` | HWLibs | 2 | **0** | costruzione |
| `__ZTVN30` | HWLibs::MetaClass | 1 | **0** | costruzione |
| `__ZTV34` | SWIP | 1 | **0** | costruzione |
| `__ZTVN34` | SWIP::MetaClass | 1 | **0** | costruzione |
| **Totale** | **3 classi** | **8** | **0** | |

**PROVEN:** **0/283** call usano la main vtable del **proprietario**.
**INFERRED:** nel dataset le 6 vtable sono **artefatti di costruzione**, non dispatchate come vtable principali.

---

## 7. Le 179 chiamate “altre classi C++”

| Funzione | Call |
|---|---:|
| `AmdTtlServices::reportFwVersionInfo` | 26 |
| `AmdTtlServices::logSWIPError` | 11 |
| `AmdTtlServices::AmdTtlServices(IOPCIDevice*)` | 10 |
| `AmdTtlServices::cosWritePciConfigData` | 9 |
| `AmdTtlServices::getOSObjectData` | 9 |
| `AmdTtlServices::cosGetVbiosRomImage` | 8 |
| `_PECI_RetrieveBiosDataTable` | 6 |
| `AmdTtlServices::createPciDeviceCache` | 6 |
| `AmdTtlServices::getPciDevice` | 6 |
| `AmdTtlServices::initializeAMDLogProperties` | 6 |

**PROVEN:** il cluster dominante è **AmdTtlServices**, una classe **non** proprietaria delle 6 vtable.
**UNPROVEN:** la relazione esatta tra **AmdTtlServices** e **HWLibs/SWIP**.

---

## 8. Conclusioni

| Domanda | Risposta |
|---|---|
| Classi proprietarie delle 6 vtable? | **X6100, HWLibs, SWIP** |
| Vtable per classe? | **2** (main + MetaClass) |
| 8 vptr store? | **3 X6100 + 3 HWLibs + 2 SWIP** |
| Gerarchia? | **X6100 → SWIP → HWLibs → esterno** |
| Call nella classe X6100 esatta? | **0** |
| Call in HWLibs/SWIP? | **7 + 4 = 11** |
| Call su main vtable del proprietario? | **0** |
| Vtable usate come dispatch? | **UNPROVEN; 0 main** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** le **6 vtable** sono **2 per ciascuna delle 3 classi**; gli **8 vptr store** sono **3/3/2**. La gerarchia è **X6100 → SWIP → HWLibs**. Le **11** call sono **7 HWLibs + 4 SWIP**, **0 X6100 esatta**, e **0** usano la main vtable del proprietario. Le vtable risultano **construction-only** in questo dataset. T27 resta **OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
