# T27 — AGENT-AMD — DISPATCH SLOTS

> **RETTIFICA (Prompt 110):** il formato è `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`, entry da 4 byte; `0x5B0` ha `cacheLevel 0` e target `0x994C60`. Con base livello 0 `0xFFFFFF8000100000`, il target reale è `0xFFFFFF8000A94C60` = **`IOService::registerService`**. La rettifica 107–109 è **RITIRATA**; vale il report 110.

**Scope:** risolvere gli otto dispatch indiretti di X6000HWServices (`0x6C0`, `0x868`, `0x270`, `0x5B0`, `0x20`, `0x2B8`, `0x178`, `0x6A8`) e verificare i percorsi di pubblicazione Navi; esaminare i costruttori Navi/SWI/Abstract e il matching X6000 Interface.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, symbol table, disassemblaggio; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che la vtable IOService mappa `0x5B0` a `IOService::registerService`, `0x270` a `IORegistryEntry::setProperty` e `0x2B8` a `IORegistryEntry::getProperty`. **PROVEN** che `Abstract::start` chiama `registerService` a `0xC26DA0D`. **UNPROVEN** che Navi chiami `Abstract::start`: Navi eredita `SWI::start`, che non mostra la chiamata. **UNPROVEN** la pubblicazione Navi e il matching X6000HWLibs. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 103 | `592fc8084005a78bfa5c6e32d66efae9e3eee4e5ba9c5fc1ee97208bd9f66e88` |
| Report 104 | `19b1bdbf56988199ca7b8a0e77c7c90823b26e18a2c963cd86eace94dc91e2fe` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Vtable IOService

| Slot | Target | Simbolo |
|---:|---:|---|
| `0x20` | `0xFFFFFF8000A1DF60` | `OSObject::retain` |
| `0x178` | `0xFFFFFF8000BB8660` | `IORegistryEntry::_RESERVEDIORegistryEntry6` |
| `0x270` | `0xFFFFFF8000A8E720` | `IORegistryEntry::setProperty` |
| `0x2B8` | `0xFFFFFF8000A8EB00` | `IORegistryEntry::getProperty` |
| `0x5B0` | `0xFFFFFF8000A94C60` | **`IOService::registerService`** |
| `0x6A8` | `0xFFFFFF8000A965D0` | `IOService::getClientIterator` |
| `0x6C0` | `0xFFFFFF8000A96800` | `IOService::callPlatformFunction` |
| `0x868` | `0xFFFFFF800139FEB0` | `OSBoolean::gMetaClass` (dato, non metodo) |

**PROVEN:** `0x5B0` è `registerService`.
**PROVEN:** `0x270` è `setProperty`.
**PROVEN:** `0x2B8` è `getProperty`.
**PROVEN:** `0x868` non è un metodo di IOService.

---

## 3. `Abstract::start`

```text
0xc26d9b3: callq *0x868(%rax)
0xc26d9d7: callq *0x270(%rax)   ; setProperty
0xc26da0d: callq *0x5b0(%rax)   ; registerService
```

| Elemento | Esito |
|---|---|
| `setProperty` | **PROVEN** |
| `registerService` | **PROVEN** |
| Oggetto `%rax` | **IOService compatibile, UNPROVEN** |

**PROVEN:** `Abstract::start` chiama `registerService`.
**UNPROVEN:** che l’oggetto sia l’istanza Navi.

---

## 4. `SWI::start`

```text
0xc26d01a: callq *%rax
0xc26d032: callq 0xC26D060
0xc26d0b2: callq *0x6C0(%rax)   ; callPlatformFunction
```

| Elemento | Esito |
|---|---|
| `registerService` diretto | **NO** |
| `registerService` indiretto | **NO osservato** |
| Chiamata ad `Abstract::start` | **NO osservata** |
| `callPlatformFunction` | **PROVEN** |

**PROVEN:** SWI non chiama direttamente `registerService`.
**UNPROVEN:** una chiamata indiretta ad `Abstract::start`.

---

## 5. Ereditarietà Navi

| Classe | Start proprio | Start ereditato |
|---|---|---|
| Navi | **NO** | **SWI::start** |
| SWI | **SÌ** | `0xC26CFF0` |
| Abstract | **SÌ** | `0xC26D8C0` |

**PROVEN:** Navi eredita `SWI::start`.
**PROVEN:** `Abstract::start` è distinto.
**UNPROVEN:** che Navi esegua `Abstract::start`.

---

## 6. `Load6000`

| Evidenza | Esito |
|---|---|
| Occorrenze SystemKC | **1** |
| Contesto | personalità X6000HWLibs |
| In X6000HWServices | **NO** |
| `setProperty` con `Load6000` | **NO osservato** |
| Pubblicazione | **UNPROVEN** |

**PROVEN:** `Load6000` non è nel binario HWServices.
**UNPROVEN:** chi lo pubblichi.

---

## 7. Matching X6000HWLibs

| Condizione | Esito |
|---|---|
| `IOProviderClass` X6000 Interface | **PROVEN** |
| `Load6000` | **PROVEN nella personalità** |
| Provider Navi | **UNPROVEN** |
| Pubblicazione `Load6000` | **UNPROVEN** |
| Matching | **UNPROVEN** |

---

## 8. Classificazione

| Affermazione | Esito |
|---|---|
| `0x5B0` = registerService | **PROVEN** |
| `Abstract::start` chiama registerService | **PROVEN** |
| `SWI::start` chiama registerService | **NO osservato** |
| Navi esegue `Abstract::start` | **UNPROVEN** |
| Navi pubblica servizio | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| X6000HWLibs → Navi | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Slot `0x5B0` | **IOService::registerService** |
| Slot `0x270` | **IORegistryEntry::setProperty** |
| Slot `0x2B8` | **IORegistryEntry::getProperty** |
| `Abstract::start` chiama registerService | **SÌ, `0xC26DA0D`** |
| `SWI::start` lo chiama | **NO osservato** |
| Navi eredita Abstract::start | **NO, eredita SWI::start** |
| Servizio Navi pubblicato | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la vtable IOService risolve `0x5B0` in `IOService::registerService`, `0x270` in `setProperty` e `0x2B8` in `getProperty`. `Abstract::start` chiama `registerService` a `0xC26DA0D`, ma Navi eredita `SWI::start`, che non mostra la chiamata e non chiama `Abstract::start`; la pubblicazione del servizio Navi resta **UNPROVEN**. `Load6000` compare solo nella personalità X6000HWLibs, non nel binario HWServices, e il matching X6000HWLibs → Navi resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
