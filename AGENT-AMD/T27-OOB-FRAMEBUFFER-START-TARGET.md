# T27 — AGENT-AMD — FRAMEBUFFER START TARGET

**Scope:** identificare la funzione chiamata da `AMDFramebuffer::start` a `0x1016E`; verificare segmento, mapping VA/file, byte, simboli, xref e convenzione; collegare a `0x27C545`/`0x27C55C`.

**Modalità:** sola lettura; SystemKC, BootKC, AMDSupportPart; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che `0x1016E` è una branch stub di SystemKC (`jmp *0x241E8`). **UNPROVEN** la funzione finale: il GOT contiene `0x400000009A7640`, e `0x9A7640` non è un function symbol. L’oggetto di `start` resta **UNPROVEN**; T27 **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf8b8340c987a98e33b039622e62b0a304fce9df799356f7f7d05ca840` |
| AMDSupportPart | `849ccf34c3976f6859eee962f2fc829c27061dff8d0b0526a1561d374f3b5cf4` |
| Report 141 | `91ee9d8b74d55a04d642a0f636b76c36f53f6b52971377038c10a2ff813bd787` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Contenitore di 0x1016E

| Contenitore | Intervallo | Esito |
|---|---|---|
| SystemKC `__BRANCH_STUBS` | `0x10000`–`0x24000` | **SÌ** |
| AMDSupportPart | base `0x27B000` | **NO** |
| BootKC | base alta `0xFFFFFF8000200000` | **NO** |

**PROVEN:** `0x1016E` è in SystemKC.
**REFUTED:** chiamata diretta a kernel o AMDSupport.
**PROVEN:** è una branch stub.

---

## 3. Byte e GOT

| Indirizzo | Byte | Istruzione |
|---:|---|---|
| `0x1016E` | `ff 25 74 40 01 00` | `jmp *0x241E8(%rip)` |
| `0x241E8` | `40 76 9a 00 00 00 40 00` | qword `0x400000009A7640` |
| low target | — | `0x9A7640` |

**PROVEN:** branch stub a 6 byte.
**PROVEN:** GOT `0x241E8`.
**PROVEN:** qword `0x400000009A7640`.
**UNPROVEN:** decodifica finale del qword.

---

## 4. Target 0x9A7640

| Test | Esito |
|---|---|
| Segmento SystemKC | `__REGION19` |
| File offset | `0x9A7640` |
| Simbolo di funzione | **assente** |
| Simbolo vicino | `_aRLC_Ucode` a `0x9A7000` +`0x640` |
| Prologo | **NO** |
| Funzione | **UNPROVEN** |

**PROVEN:** non esiste un simbolo di funzione a `0x9A7640`.
**PROVEN:** il target non è un function start riconoscibile.
**UNPROVEN:** cosa contenga il qword.

### Alternativa BootKC

| Indirizzo | Simbolo vicino | Delta |
|---|---|---:|
| `0xFFFFFF80009A7640` | `_nxprov_params_adjust` | `+0xA40` |

**PROVEN:** anche in BootKC non è un function start.
**UNPROVEN:** l’eventuale base corretta.

---

## 5. Chiamate

| Indirizzo | Operazione |
|---:|---|
| `0x27C545` | `callq 0x1016E` |
| `0x27C55C` | `callq 0x1016E` |
| `0x27C550` | `callq *0x868` |
| `0x27C570` | `callq *0x860` |

**PROVEN:** entrambe le chiamate passano per la branch stub.
**PROVEN:** il target finale non è identificato.
**UNPROVEN:** firma e convenzione.

---

## 6. Convenzione

| Elemento | Esito |
|---|---|
| `jmp` tail | **SÌ** |
| Return address originale | **preservato dal call** |
| Argomenti | **UNPROVEN** |
| `rdi/rsi` a `0x860` | solo questi impostati |

**PROVEN:** la branch stub non crea un frame.
**UNPROVEN:** la funzione finale.

---

## 7. STOP

| Criterio | Esito |
|---|---|
| `0x1016E` localizzato | **SÌ** |
| Funzione finale | **NO** |
| Oggetto `start` | **UNPROVEN** |
| Caller Wrangler | **UNPROVEN** |
| Spazio >10 GiB | **SÌ** |
| Modifiche | **NO** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente con certezza.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| `0x1016E` | branch stub SystemKC |
| Istruzione | `jmp *0x241E8` |
| GOT | `0x400000009A7640` |
| Target basso | `0x9A7640` |
| Funzione | **UNPROVEN** |
| Oggetto `start` | **UNPROVEN** |
| `enableHardware` | controller `notify` |
| Caller Wrangler | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `0x1016E` non è una chiamata diretta al kernel: è una branch stub di SystemKC, `ff 25 74 40 01 00` = `jmp *0x241E8(%rip)`. Il GOT a `0x241E8` contiene `0x400000009A7640`; il target basso `0x9A7640` cade in `__REGION19`, non ha un simbolo di funzione e non presenta un prologo riconoscibile. La funzione finale e l’oggetto di `AMDFramebuffer::start` restano **UNPROVEN**; `enableHardware` resta **REFUTED** come caller Wrangler (`0xDD8` = controller, slot `0x860` = `notify` `0xBFA1056`). STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
