# T27 — AGENT-AMD — 994C60 IDENTITY

> **RETTIFICA (Prompt 110):** questo report ha decodificato la voce `0x5B0` come puntatore assoluto, ma il formato è `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` con entry da 4 byte. Con `cacheLevel 0` e base `0xFFFFFF8000100000`, il target è `0xFFFFFF8000A94C60` = **`IOService::registerService`**. Le conclusioni di questo report sono **SUPERATE**; vale il report 110.

**Scope:** identificare la funzione reale a `0x994C60`, determinare perché occupa lo slot `0x5B0` nelle vtable Navi/SWI/Abstract e separare fatti provati da ipotesi.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, disassemblaggio, symbol table, scansione puntatori e call; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che `0x994C60` **non è un entry point**: è il secondo byte dell’istruzione `jne` a `0x994C5F` (`75 6D`). **PROVEN** che non esistono puntatori assoluti né call dirette a `0x994C60` in BootKC/SystemKC. **REFUTED** che la voce `0x5B0` di Navi/SWI/Abstract sia un normale IMP o `registerService`. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 107 | `bac68d5031dc41b979599371eb7425ae9044d4af43152f2cb313defdb6d3f601` |
| Report 108 | `60ceab2365146e5c2667dbb6e08b231d424ccfe5fbf4c850f757493df1d9aab8` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Disassemblaggio

```text
0xFFFFFF8000994C5B: testb  $0x2, 0x4(%rbx)
0xFFFFFF8000994C5F: jne    0xFFFFFF8000994CCE     ; 75 6D
0xFFFFFF8000994C61: movq   $0x0, 0x28(%rbx)
0xFFFFFF8000994C69: movq   0x10(%rbx), %r15
```

| Indirizzo | Byte | Interpretazione |
|---:|---|---|
| `0x994C5F` | `75 6D` | `jne` |
| `0x994C60` | `6D` | **secondo byte di `jne`** |
| `0x994C61` | `C7` | inizio `movq` |

**PROVEN:** `0x994C60` è dentro `jne`.
**PROVEN:** `0x994C60` non è un entry point.
**PROVEN:** `0x994C61` è un boundary valido.

---

## 3. Riferimenti

| Ricerca | Esito |
|---|---|
| Puntatore assoluto `0xFFFFFF8000994C60` in BootKC | **0** |
| Puntatore assoluto in SystemKC | **0** |
| Call rel32 in `__TEXT_EXEC` BootKC | **0** |
| Simbolo esatto | **nessuno** |
| Simbolo più vicino | `_nxprov_close+0xE0` |

**PROVEN:** non ci sono xref dirette.
**PROVEN:** non è una funzione chiamata.
**UNPROVEN:** il significato della voce vtable.

---

## 4. Voce `0x5B0` X6000

| Vtable | Raw | Target decodificato | Entry valido |
|---|---:|---:|---|
| Navi | `0x40000000994C60` | `0x994C60` | **NO** |
| SWI | `0x40000000994C60` | `0x994C60` | **NO** |
| Abstract | `0x40000000994C60` | `0x994C60` | **NO** |

**PROVEN:** la decodifica a `0x994C60` produce un indirizzo non-entry.
**PROVEN:** la voce non è un normale IMP.
**UNPROVEN:** la codifica reale della voce.
**UNPROVEN:** il target reale.

---

## 5. Altre vtable

| Vtable | `0x5B0` raw |
|---|---:|
| IOPCIDevice | `0x04D8BF83900001E4` |
| IOUSBHostDevice | `0x040000002ACF252` |

**PROVEN:** anche altre vtable BootKC hanno voci non-assolute.
**PROVEN:** il formato non è un semplice array di IMP assoluti.
**UNPROVEN:** la decodifica corretta.

---

## 6. Perché occupa `0x5B0`

| Ipotesi | Stato |
|---|---|
| Override di `registerService` | **REFUTED** |
| Thunk | **REFUTED** |
| Puntatore a funzione | **REFUTED** |
| Voce base comune | **UNPROVEN** |
| Collisione ABI | **UNPROVEN** |
| Layout incompatibile | **UNPROVEN** |

**PROVEN:** non è un override valido.
**PROVEN:** non è un thunk.
**UNPROVEN:** la causa della voce.

---

## 7. Percorsi di pubblicazione

| Percorso | Esito |
|---|---|
| `registerService` via `0x5B0` | **REFUTED** |
| `registerService` diretto | **NO** |
| Callback/metaclass | **NO osservato** |
| Workloop | **NO osservato** |
| Provider | **NO osservato** |
| Pubblicazione automatica | **UNPROVEN** |

**PROVEN:** non è emerso un percorso alternativo.
**UNPROVEN:** runtime.

---

## 8. Conclusioni ritirate

| Conclusione | Stato |
|---|---|
| `0x5B0` = `registerService` in X6000 | **RITIRATA** |
| `Abstract::start` chiama `registerService` | **RITIRATA** |
| `0x994C60` è una funzione | **RITIRATA** |
| `registerService` è l’unico modo di pubblicare | **RITIRATA** |

**PROVEN:** nessuna delle quattro è sostenibile.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `0x994C60` è un entry point | **NO** |
| È dentro `jne` | **SÌ** |
| Xref dirette | **NO** |
| Voce `0x5B0` è un IMP | **NO** |
| `registerService` | **REFUTED** |
| Pubblicazione Navi | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `0x994C60` non è una funzione: è il secondo byte dell’istruzione `jne` a `0x994C5F` (`75 6D`), e non ha puntatori assoluti né call dirette. La voce `0x5B0` di Navi/SWI/Abstract non è quindi un normale IMP e non può essere `registerService`; la decodifica usata nei report 105/106/107/108 è invalida. La pubblicazione del servizio Navi e il matching X6000HWLibs → Navi restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
