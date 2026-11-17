# T27 — AGENT-AMD — START DISPATCH

> **RETTIFICA (Prompt 110):** il formato è `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`, entry da 4 byte; `0x5B0` ha `cacheLevel 0` e target `0x994C60`. Con base livello 0 `0xFFFFFF8000100000`, il target reale è `0xFFFFFF8000A94C60` = **`IOService::registerService`**. La rettifica 107–109 è **RITIRATA**; vale il report 110.

**Scope:** ricostruire il dispatch di `start()` nella gerarchia Navi → SWI → Abstract e verificare perché Navi non raggiunge `Abstract::start`; esaminare le vtable complete, gli slot `start`/`probe`/`stop`, i costruttori e le super-call.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, symbol table, disassemblaggio; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che Navi usa `SWI::start` (`0x4C26CFF0`) e `Abstract::probe` (`0x4C26D650`); **PROVEN** che `Abstract::start` (`0x4C26D8C0`) è usato solo dalla vtable Abstract e chiama `registerService`. **UNPROVEN** un percorso alternativo da Navi a `Abstract::start`. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 104 | `19b1bdbf56988199ca7b8a0e77c7c90823b26e18a2c963cd86eace94dc91e2fe` |
| Report 105 | `c0185b2a997b57a999e0e19c17cb5bef65e555abde189238e3745fe28b5a6039` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Slot IOService

| Slot | Metodo |
|---:|---|
| `0x5B8` | `IOService::probe` |
| `0x5C0` | `IOService::start` |

**PROVEN:** gli offset sono quelli della vtable IOService.
**PROVEN:** `start` e `probe` sono distinti.

---

## 3. Vtable X6000HWServices

| Vtable | `start` (`0x5C0`) | `probe` (`0x5B8`) |
|---|---|---|
| Navi | `0x4C26CFF0` (`SWI::start`) | `0x4C26D650` (`Abstract::probe`) |
| SWI | `0x4C26CFF0` (`SWI::start`) | `0x4C26D650` (`Abstract::probe`) |
| Abstract | `0x4C26D8C0` (`Abstract::start`) | `0x4C26D650` (`Abstract::probe`) |

**PROVEN:** Navi usa `SWI::start`.
**PROVEN:** Navi usa `Abstract::probe`.
**PROVEN:** Abstract usa `Abstract::start`.

---

## 4. Perché Navi non raggiunge Abstract::start

```text
Navi vtable start -> SWI::start 0x4C26CFF0
SWI::start -> 0x4C26D060, *0x6C0
SWI::start -> nessuna chiamata a 0x4C26D8C0
```

| Evidenza | Esito |
|---|---|
| Navi `start` = `Abstract::start` | **NO** |
| SWI `start` = `Abstract::start` | **NO** |
| Super-call a `Abstract::start` | **NO osservata** |
| Chiamata diretta `0xC26D8C0` | **NO osservata** |
| `registerService` in `SWI::start` | **NO** |

**PROVEN:** Navi non passa per `Abstract::start`.
**PROVEN:** `SWI::start` non chiama `Abstract::start`.
**UNPROVEN:** un percorso indiretto alternativo.

---

## 5. Abstract::start

```text
0xc26d9d7: callq *0x270(%rax)   ; setProperty
0xc26da0d: callq *0x5b0(%rax)   ; registerService
```

| Elemento | Esito |
|---|---|
| `setProperty` | **PROVEN** |
| `registerService` | **PROVEN** |
| Usato da Navi | **NO** |
| Usato da SWI | **NO** |
| Usato da Abstract | **SÌ** |

**PROVEN:** solo Abstract pubblica il servizio con questa chiamata.

---

## 6. Costruttori e vptr

| Classe | Costruttore | Vtable |
|---|---|---:|
| Navi | `0xC26C930` | `0xC26F078` |
| SWI | `0xC26CDC0` | `0xC26F9F8` |
| Abstract | `0xC26D3F0` | `0xC270CF0` |
| Interface | `0xC26D210` | `0xC271828?` |

**PROVEN:** le vtable sono distinte.
**PROVEN:** Navi e SWI puntano allo stesso `start`.
**UNPROVEN:** il vptr Interface.

---

## 7. Confronto con X6000HWLibs

| Condizione | Esito |
|---|---|
| `IOProviderClass` X6000 Interface | **PROVEN** |
| `Load6000` | **PROVEN nella personalità** |
| Navi pubblica servizio | **UNPROVEN** |
| `Load6000` pubblicato | **UNPROVEN** |
| Matching | **UNPROVEN** |

---

## 8. Percorsi alternativi

| Percorso | Esito |
|---|---|
| Chiamata diretta a `Abstract::start` | **NO** |
| Super-call in `SWI::start` | **NO** |
| Slot vtable Navi → Abstract | **NO** |
| Slot vtable SWI → Abstract | **NO** |
| `registerService` fuori da Abstract | **NO osservato** |

**PROVEN:** non è emerso un percorso alternativo.
**UNPROVEN:** percorsi runtime.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Navi `start` | **`SWI::start`** |
| Navi `probe` | **`Abstract::probe`** |
| Abstract `start` | **`Abstract::start`** |
| Navi raggiunge `Abstract::start` | **NO** |
| `registerService` chiamato da Navi | **UNPROVEN** |
| Servizio Navi pubblicato | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la vtable Navi punta `start` a `SWI::start` (`0x4C26CFF0`) e `probe` a `Abstract::probe` (`0x4C26D650`). `Abstract::start` (`0x4C26D8C0`) è usato solo dalla vtable Abstract e chiama `registerService` a `0xC26DA0D`; `SWI::start` non chiama `Abstract::start` e non mostra una super-call. Non è emerso un percorso alternativo: la pubblicazione del servizio Navi e il matching X6000HWLibs → Navi restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
