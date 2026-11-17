# T27 — AGENT-AMD — X6000 REGISTRATION

**Scope:** dimostrare staticamente se X6000HWServices pubblica `AMDRadeonX6000_AMDRadeonHWServicesInterface` e se X6000HWLibs può associarsi al provider; ricostruire costruttori, metaclass, superclass e matching IOKit.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, symbol table, disassemblaggio; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che la classe Navi X6000 registra la superclasse SWI (`0x4C271800`) e che SWI registra Abstract (`0x4C271850`). **PROVEN** che Abstract punta a `0x4C271828`. **UNPROVEN** che `0x4C271828` sia l’interfaccia X6000 e che X6000HWLibs si associ al provider Navi. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 98 | `4e2d91b4299c77152a7d975ffb692704c0a8fc9f2310c5f6a405c9e07b54046b` |
| Report 99 | `9ce2795322c67d124a134c48599043c7748458b2b067052d6bd9e1799d5c83fa` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Classi X6000HWServices

| Classe | MetaClassC1 | MetaClass |
|---|---:|---:|
| `AMDRadeonX6000_AMDRadeonHWServicesNavi` | `0xC26C930` | `0xC26F068` |
| `AMDRadeonX6000_AMDRadeonHWServicesSWI` | `0xC26CDC0` | `0xC26F9E8` |
| `AMDRadeonX6000_AMDRadeonHWServicesAbstract` | `0xC26D3F0` | `0xC270CE0` |
| `AMDRadeonX6000_AMDRadeonHWServicesInterface` | `0xC26D210` | `0xC271828` |

**PROVEN:** le quattro classi sono nel fileset X6000HWServices.
**PROVEN:** Navi, SWI e Abstract sono distinte dall’interfaccia.

---

## 3. Catena delle superclassi

| Classe | Slot superclasse | Raw | Target |
|---|---:|---|---:|
| Navi | `0xC26F070` | `0xC000004C271800` | `0x4C271800` |
| SWI | `0xC26F9F0` | `0xC000004C271850` | `0x4C271850` |
| Abstract | `0xC270CE8` | `0xC000004C271828` | `0x4C271828` |
| Interface | `0xC270370` | `0x400000012AA488` | `0x12AA488` |

**PROVEN:** Navi → SWI → Abstract.
**PROVEN:** Abstract → `0x4C271828`.
**PROVEN:** Interface → `0x12AA488`.
**UNPROVEN:** che `0x4C271828` sia Interface.

---

## 4. Puntatori MetaClass

| Simbolo | Slot | Raw | Target |
|---|---:|---|---:|
| Navi MetaClass | `0xC26F068` | `0x4000004C2717D8` | `0x4C2717D8` |
| SWI MetaClass | `0xC26F9E8` | `0x4000004C271800` | `0x4C271800` |
| Abstract MetaClass | `0xC270CE0` | `0x4000004C271850` | `0x4C271850` |
| Interface MetaClass | `0xC271828` | `0x0` | **non inizializzato** |

**PROVEN:** Navi punta a SWI come superclasse.
**PROVEN:** SWI punta ad Abstract.
**PROVEN:** Abstract punta a `0x4C271828`.
**UNPROVEN:** l’identità di `0x4C271828`.

---

## 5. Registrazione

```text
Navi MetaClassC1 0xc26c930
  -> superclass SWI  0x4c271800
     -> superclass Abstract 0x4c271850
        -> superclass 0x4c271828
           -> Interface?  (UNPROVEN)
```

| Passo | Esito |
|---|---|
| Navi registra SWI | **PROVEN** |
| SWI registra Abstract | **PROVEN** |
| Abstract registra `0x4C271828` | **PROVEN** |
| `0x4C271828` è Interface | **UNPROVEN** |
| Navi è sottoclasse di Interface | **UNPROVEN** |

---

## 6. X6000HWLibs

| Elemento | Valore |
|---|---|
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWLibsX6000` |
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `LoadPlugIn=Load6000` |
| Match con Navi | **UNPROVEN** |

**PROVEN:** la personalità richiede l’interfaccia X6000.
**PROVEN:** Navi non dichiara direttamente l’interfaccia come superclasse.
**UNPROVEN:** l’ereditarietà indiretta Navi → Interface.

---

## 7. IOKit

| Fase | Evidenza |
|---|---|
| Registrazione classe | **PROVEN** |
| Pubblicazione interfaccia | **UNPROVEN** |
| `registerService` | **non tracciato** |
| `probe` | **non tracciato** |
| `start` | **non tracciato** |
| Matching provider | **UNPROVEN** |

**PROVEN:** la registrazione delle classi è statica.
**UNPROVEN:** la pubblicazione e il matching runtime.

---

## 8. Classificazione

| Affermazione | Esito |
|---|---|
| Navi → SWI | **PROVEN** |
| SWI → Abstract | **PROVEN** |
| Abstract → `0x4C271828` | **PROVEN** |
| `0x4C271828` = Interface | **UNPROVEN** |
| Navi → Interface | **UNPROVEN** |
| X6000HWLibs → Navi | **UNPROVEN** |
| Pubblicazione interfaccia | **UNPROVEN** |
| Runtime | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Registrazione Navi | **PROVEN** |
| Superclasse Navi | **SWI `0x4C271800`** |
| Superclasse SWI | **Abstract `0x4C271850`** |
| Superclasse Abstract | **`0x4C271828`** |
| `0x4C271828` = Interface | **UNPROVEN** |
| X6000HWLibs matcha Navi | **UNPROVEN** |
| Pubblicazione interfaccia | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** X6000HWServices registra Navi con superclasse SWI (`0x4C271800`), SWI con superclasse Abstract (`0x4C271850`) e Abstract con superclasse `0x4C271828`. La metaclasse Interface ha valore statico zero e non è simbolicamente collegata a `0x4C271828`: l’ereditarietà Navi → Interface e il matching di X6000HWLibs restano **UNPROVEN**. La pubblicazione dell’interfaccia e il comportamento runtime non sono tracciati. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
