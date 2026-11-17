# T27 — AGENT-AMD — REGISTRATION PATH

**Scope:** determinare se Navi pubblica un servizio compatibile con X6000 Interface e ricostruire staticamente il percorso di registrazione; esaminare `__DATA`, `__DATA_CONST`, metaclass, vtable, fixup, `registerService`, `probe`, `start`, `newUserClient` e la pubblicazione dei provider.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, symbol table, disassemblaggio; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che X6000HWServices contiene `SWI::start`, `SWI::stop`, `Abstract::probe`, `Abstract::start` e `Abstract::stop`, e che importa `IOService::registerService`. **PROVEN** che `Load6000` compare una sola volta nel SystemKC, nella personalità X6000HWLibs, non nel binario X6000HWServices. **UNPROVEN** la chiamata effettiva a `registerService`, la pubblicazione di `Load6000` e il matching X6000HWLibs → Navi. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 101 | `62ef7632ed03beca728695ba768b23f51b5435f7d0e7960a72fc665d30eaa2e7` |
| Report 102 | `c3261a23086ba05b8063fd4a4f861d848f2c3b4f292025d69fc75c07d8f22f7e` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Sezioni X6000HWServices

| Segmento | Sezione | Indirizzo | Dimensione |
|---|---|---:|---:|
| `__TEXT` | `__text` | `0xC26C910` | `0x1704` |
| `__TEXT` | `__cstring` | `0xC26E014` | `0x38C` |
| `__TEXT` | `__const` | `0xC26E3A0` | `0x2B` |
| `__DATA` | `__got` | `0xC26F000` | `0x38` |
| `__DATA` | `__mod_init_func` | `0xC26F038` | `0x18` |
| `__DATA` | `__mod_term_func` | `0xC26F050` | `0x18` |
| `__DATA` | `__const` | `0xC26F068` | `0x25F8` |
| `__DATA` | `__data` | — | `0x168` |
| `__DATA` | `__common` | — | `0xB0` |
| `__DATA_CONST` | `__kalloc_type` | — | — |

**PROVEN:** le sezioni sono presenti.
**PROVEN:** `__DATA` contiene i descrittori delle classi.

---

## 3. Metodi

| Simbolo | VA | Ruolo |
|---|---:|---|
| `SWI::start` | `0xC26CFF0` | start |
| `SWI::stop` | `0xC26D120` | stop |
| `Abstract::probe` | `0xC26D650` | probe |
| `Abstract::start` | `0xC26D8C0` | start |
| `Abstract::stop` | `0xC26DD90` | stop |
| `Navi::start` | **assente** | eredita |
| `Navi::probe` | **assente** | eredita |

**PROVEN:** Navi non implementa start/probe propri.
**PROVEN:** SWI e Abstract implementano start/probe.

---

## 4. Import

| Simbolo | Evidenza |
|---|---|
| `IOService::registerService` | **importato** |
| `IOService::probe` | **importato** |
| `IOService::start` | **importato** |
| `IOService::stop` | **importato** |
| `IOService::newUserClient` | **importato** |

**PROVEN:** la classe può chiamare `registerService`.
**UNPROVEN:** che lo faccia in `start`.

---

## 5. Disassemblaggio

| Funzione | Chiamate osservate |
|---|---|
| `SWI::start` | `callq *%rax`, `0xC26D060`, `*0x6C0(%rax)` |
| `Abstract::start` | `0x1007E`, `0x10114`, `0xC26DAA0`, `0xC26DB90`, `*0x868(%rax)`, `*0x270(%rax)`, `*0x5B0(%rax)`, `0xC26DC80`, `*0x20(%rax)` |

| Evidenza | Esito |
|---|---|
| `registerService` diretto | **non osservato** |
| `registerService` indiretto | **possibile, non risolto** |
| `setProperty` | **non osservato** |
| `Load6000` nel binario | **NO** |
| `newUserClient` | **non osservato** |

**PROVEN:** non c’è una chiamata diretta visibile.
**UNPROVEN:** la chiamata indiretta.

---

## 6. `Load6000`

| Evidenza | Esito |
|---|---|
| Occorrenze SystemKC | **1** |
| Offset | `0x60712` |
| Contesto | personalità X6000HWLibs |
| In X6000HWServices | **NO** |
| In X6000 accelerator | **NO osservato** |
| Pubblicazione runtime | **UNPROVEN** |

**PROVEN:** `Load6000` è solo nella personalità X6000HWLibs.
**UNPROVEN:** chi lo pubblichi sul provider.

---

## 7. Relazioni

```text
Navi -> SWI 0x4C271800
  -> Abstract 0x4C271850
     -> 0x4C271828
        -> Interface? UNPROVEN

X6000HWLibs -> IOProviderClass X6000 Interface
  -> Load6000
     -> provider Navi? UNPROVEN
```

| Relazione | Esito |
|---|---|
| Navi → SWI | **PROVEN** |
| SWI → Abstract | **PROVEN** |
| Abstract → `0x4C271828` | **PROVEN** |
| `0x4C271828` → Interface | **UNPROVEN** |
| Navi → Interface | **UNPROVEN** |
| X6000HWLibs → Navi | **UNPROVEN** |

---

## 8. Classificazione

| Affermazione | Esito |
|---|---|
| Navi pubblica un servizio | **UNPROVEN** |
| `registerService` chiamato | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| X6000HWLibs matcha Navi | **UNPROVEN** |
| Percorso alternativo | **NON OSSERVATO** |
| Runtime | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `SWI::start` presente | **SÌ** |
| `Abstract::start` presente | **SÌ** |
| `registerService` importato | **SÌ** |
| Chiamata diretta | **NO** |
| `Load6000` in HWServices | **NO** |
| `Load6000` in HWLibs | **SÌ** |
| Matching X6000HWLibs | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** X6000HWServices contiene `SWI::start`, `SWI::stop`, `Abstract::probe`, `Abstract::start` e `Abstract::stop`, e importa `IOService::registerService`, ma non mostra una chiamata diretta a `registerService` né pubblica `Load6000`; la stringa compare una sola volta nel SystemKC, nella personalità X6000HWLibs. La catena Navi → SWI → Abstract → `0x4C271828` resta **UNPROVEN** nel passaggio a Interface; il matching X6000HWLibs → Navi resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
