# T27 — AGENT-AMD — PUBLICATION PATH

> **RETTIFICA (Prompt 129):** `*0x20` sulla vtable HWLibsX6000 è `OSObject::release(int)` (`0xA1DF30`), non `start`. Il plugin viene rilasciato, non avviato. `Load6000` è una proprietà di matching restituita da `Navi::getMatchProperty`, non una funzione.

> **RETTIFICA (Prompt 128):** il matching statico X6000HWLibs è **PROVEN** nel plist (`IOProviderClass=Interface`, `IOMatchCategory=AMDRadeonHWLibs`, `LoadPlugIn=Load6000`). Resta **UNPROVEN** la pubblicazione/runtime. Il Finder è confermato come match del plugin, non come pubblicazione del servizio.

**Scope:** verificare il percorso effettivo di pubblicazione IOService e matching di X6000 Interface, chiarire il ruolo del Finder `0xC26DC80`, ricostruire i call-site degli slot della vtable Interface e confrontare X5000.

**Modalità:** sola lettura; X6000HWServices, X5000HWServices, SystemKC, BootKC; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che il Finder ha un solo chiamante (`Abstract::start`) e che nessuno slot della vtable Interface viene invocato nel codice statico. **REFUTED** una pubblicazione IOService di Interface. **PROVEN** il matching generico `AMDRadeonHWLibs`. Pubblicazione e matching X6000HWLibs restano **UNPROVEN**. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| X6000HWServices | `2aa47ceee99969d3eba360fe558a3fbcd7e69c4bea2cd76704350a9bdfafe453` |
| X5000HWServices | `8a88fe7276968d3b124c9ff7ccf26d18b5e918fc339ab3681dfcb5a2cbd3cfbf` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 126 | `f591c07f41fdee4954007b337a8c4c6caf916bdbfe13351092027c55ad317f90` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Finder

| Test | Esito |
|---|---|
| Indirizzo | `0xC26DC80` |
| Chiamanti | `0xC26DA21` |
| Numero chiamanti | **1** |
| Argomento | `rdi = this` |
| Ritorno | plugin o `0` |
| `IOMatchCategory` | `0xC26E388` |
| Valore match | `0xC26E3B0` = `"AMDRadeonHWLibs"` |
| Errore | `"Could not find HW Lib Plug In."` |

**PROVEN:** un solo chiamante.
**PROVEN:** il Finder cerca `IOMatchCategory`.
**PROVEN:** il valore è `AMDRadeonHWLibs`.
**UNPROVEN:** il provider concreto.

---

## 3. this+0xA8

| Fase | Valore |
|---|---|
| Inizio `Abstract::start` | non inizializzato |
| Dopo Finder | plugin o `0` |
| Uso | helper `0xC26D060` |
| Errore Finder | log + fallimento |

```text
0xC26DA21  callq 0xC26DC80
0xC26DA2D  movq %rcx, 0xA8(%rax)
0xC26DA34  cmpq $0x0, 0xA8(%rax)
0xC26DA3C  je 0xC26DA51
0xC26DA4C  callq *0x20(%rax)
```

**PROVEN:** `+0xA8` è scritto dopo il Finder.
**PROVEN:** null produce errore.
**PROVEN:** il plugin viene avviato con `*0x20`.

---

## 4. Call-site vtable Interface

| Slot | Target Interface | Call-site |
|---:|---:|---|
| `0x5B0` | `0xA94C60` registerService | **0** |
| `0x5B8` | `0xA94E60` probe | **0** |
| `0x5C0` | `0xA94E70` start | **0** |
| `0x5C8` | `0xA94E80` | **0** |
| `0x5D0` | `0xA94EB0` open | **0** |
| `0x5D8` | `0xA94FD0` | **0** |

**PROVEN:** nessun call-site nella vtable Interface.
**PROVEN:** `call *0x5B0` esiste solo a `0xC26DA0D`.
**PROVEN:** quel `call` opera su un oggetto Navi, non Interface.

---

## 5. registerService / start

| Chiamata | Indirizzo | Esito |
|---|---:|---|
| `IOService::start` | `0xC26D8FD` | diretta, `0xA94E70` |
| `registerService` | `0xA94C60` | **nessuna nella catena** |
| `probe` | `0xA94E60` | **nessuna nella catena** |
| `open` | `0xA94EB0` | **nessuna nella catena** |

**PROVEN:** `IOService::start` è chiamato direttamente.
**PROVEN:** `registerService` non è chiamato.
**PROVEN:** `probe`/`open` non sono chiamati.
**UNPROVEN:** il comportamento runtime.

---

## 6. Flusso

```text
SWI::start
  -> Abstract::start
     -> IOService::start (0xA94E70)
     -> *0x5B0 (Navi: _RESERVEDIOService47)
     -> Finder (0xC26DC80)
     -> +0xA8 = plugin
     -> plugin *0x20
  -> helper 0xC26D060
     -> plugin *0x6C0("AmdTtlInterfaceKey")
     -> +0xD0 = interface
```

| Test | Esito |
|---|---|
| `registerService` | **NO** |
| `probe` | **NO** |
| `open` | **NO** |
| Publish | **NO** |

**PROVEN:** il flusso non pubblica.
**PROVEN:** il flusso collega il plugin.
**UNPROVEN:** l’interfaccia runtime.

---

## 7. X5000

| Elemento | X5000 | X6000 |
|---|---:|---:|
| `Abstract::start` | `0x457C970` | `0xC26D8C0` |
| Finder | `0x457CD30` | `0xC26DC80` |
| Stringa match | `0x457D3E0` | `0xC26E3B0` |
| `IOMatchCategory` | `0x457D3B7` | `0xC26E388` |
| `+0xA8` | `0x457CADD` | `0xC26DA2D` |
| slot `0x5B0` target | **UNPROVEN** | `_RESERVEDIOService47` |

**PROVEN:** X5000 usa lo stesso Finder pattern.
**PROVEN:** la stringa match è la stessa.
**UNPROVEN:** il target slot X5000.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Finder chiamanti | **1** |
| Finder ruolo | matching plugin |
| Match category | `AMDRadeonHWLibs` |
| Interface slot call-site | **0** |
| `registerService` | **NO** |
| `probe` | **NO** |
| `open` | **NO** |
| Pubblicazione Interface | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il Finder `0xC26DC80` ha un solo chiamante, `Abstract::start` a `0xC26DA21`; cerca `IOMatchCategory == "AMDRadeonHWLibs"` e salva il plugin a `this+0xA8`. La vtable Interface (`0xC270388`) non ha alcun call-site statico: `registerService`, `probe`, `open` e `start` non vengono mai invocati tramite quella vtable. L’unico `call *0x5B0` è in `Abstract::start` e opera su un oggetto Navi, dove lo slot è `_RESERVEDIOService47`. `IOService::start` è chiamato direttamente e ritorna `true`; `registerService` non è chiamato. Quindi **Interface non ha un percorso statico di pubblicazione IOService**: è un oggetto plugin, non un servizio pubblicato. Il matching è generico `AMDRadeonHWLibs`, non specifico `X6000HWLibs`; la pubblicazione e il matching X6000HWLibs restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,2 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
