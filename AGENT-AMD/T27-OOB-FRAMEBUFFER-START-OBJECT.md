# T27 — AGENT-AMD — FRAMEBUFFER START OBJECT

**Scope:** identificare l’oggetto passato allo slot `0x860` da `AMDFramebuffer::start` (`0x27C570`) e stabilire se può essere `AmdGpuWrangler`; risolvere `0x1016E`; confrontare Wrangler, Controller e AgdcServices.

**Modalità:** sola lettura; AMDSupportPart, X6000FramebufferFull, SystemKC; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **REFUTED** che `0x1016E` sia uno stub/GOT: è una chiamata diretta a un indirizzo kernel basso. **UNPROVEN** l’oggetto di `start`. **REFUTED** `enableHardware` come caller Wrangler. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| AMDSupportPart | `849ccf34c3976f6859eee962f2fc829c27061dff8d0b0526a1561d374f3b5cf4` |
| X6000FramebufferFull | `7104d431bac240b1c60e5fa1d6308bec9cb7dbb689eaf263e79d1dc0796835eb` |
| Report 140 | `4402928cb369ec30fae8d1b8fe6ccd8ef92663547a5471355d09bccd9048d287` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Correzione su 0x1016E

| Test | Esito |
|---|---|
| `callq 0x1016E` | **diretto** |
| Stub/GOT | **NO** |
| Simbolo in SystemKC | **assente** |
| Intervallo | kernel VA basso |
| Target | **UNPROVEN** |

**PROVEN:** `0x1016E` è minore della base `AMDSupportPart` (`0x27B000`).
**PROVEN:** non è una stub locale né una GOT.
**REFUTED:** la descrizione “stub 0x1016E”.
**UNPROVEN:** il simbolo kernel.

---

## 3. start

| Indirizzo | Operazione |
|---:|---|
| `0x27BCF0` | inizio |
| `0x27C545` | `callq 0x1016E` |
| `0x27C54A` | `rdi = rax` |
| `0x27C550` | `callq *0x868` |
| `0x27C556` | salva il risultato in `-0x124` |
| `0x27C55C` | `callq 0x1016E` |
| `0x27C56A` | `esi = flags & -3` |
| `0x27C570` | `callq *0x860` |
| `0x27C576` | prosegue con `0x5D0` |

**PROVEN:** due chiamate allo stesso indirizzo kernel.
**PROVEN:** il primo slot `0x868` produce i flag.
**PROVEN:** il secondo slot `0x860` riceve `flags & -3`.
**UNPROVEN:** il tipo dell’oggetto.

---

## 4. Registri e provenienza

| Registro | Valore |
|---|---|
| `rax` | ritorno di `0x1016E` |
| `rdi` | stesso oggetto |
| `esi` | `flags & -3` |
| `rdx/rcx/r8/r9` | **non impostati** nel blocco |

**PROVEN:** la chiamata `0x860` imposta solo `rdi` e `rsi`.
**PROVEN:** non imposta gli altri argomenti.
**UNPROVEN:** la firma effettiva.

---

## 5. Vtable

| Classe | Vtable | Slot `0x860` | Target |
|---|---:|---:|---|
| Wrangler | `0xC1F07B0` | `0x860` | `0xBF9894E` vendor |
| Controller | `0xC1DF110` | `0x860` | `0xBFA1056` notify |
| AgdcServices | `0xC1E3FB0` | `0x860` | `0xBF73668` vendor |

**PROVEN:** i tre target sono distinti.
**PROVEN:** solo Wrangler ha `0xBF9894E`.
**UNPROVEN:** quale vtable usi l’oggetto di `start`.

---

## 6. enableHardware

| Indirizzo | Operazione |
|---:|---|
| `0x28ACF0` | inizio |
| `0x28AD58` | `rdi = 0xDD8(%rax)` |
| `0x28AD72` | `callq *0x860` |
| `0x28AD7F` | confronta con `0` |

**PROVEN:** `0xDD8` è il controller (`findController` in `attach`).
**PROVEN:** slot `0x860` = `notify` (`0xBFA1056`).
**REFUTED:** `enableHardware` chiama `0xBF9894E`.
**UNPROVEN:** il significato runtime.

---

## 7. AgdcServices

| Elemento | Valore |
|---|---|
| vendor | `0xBF73668` |
| vtable | `0xC1E3FB0` |
| slot `0x860` | `0xBF73668` |
| Relazione con Wrangler | **distinta** |

**PROVEN:** AgdcServices ha un proprio vendor.
**PROVEN:** non è Wrangler.
**UNPROVEN:** se `start` usi AgdcServices.

---

## 8. STOP

| Criterio | Esito |
|---|---|
| Oggetto `start` identificato | **NO** |
| `0x1016E` risolto | **NO** |
| `enableHardware` Wrangler | **REFUTED** |
| Mapping ambiguo | **SÌ** |
| Spazio >10 GiB | **SÌ** |
| Modifiche | **NO** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente con certezza.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `0x1016E` | chiamata kernel diretta |
| Stub/GOT | **NO** |
| Oggetto `start` | **UNPROVEN** |
| `enableHardware` | controller `notify` |
| `0xBF9894E` | solo Wrangler |
| Caller Wrangler | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `0x1016E` non è uno stub né una GOT: è una chiamata diretta a un indirizzo kernel basso, senza simbolo in SystemKC. `AMDFramebuffer::start` chiama due volte questo indirizzo, usa `*0x868` per ottenere i flag e poi `*0x860` con `esi = flags & -3`; imposta solo `rdi` e `rsi`, quindi la firma completa resta **UNPROVEN**. L’oggetto può essere Wrangler (`0xBF9894E`), controller (`0xBFA1056`) o AgdcServices (`0xBF73668`), ma non è dimostrabile. `enableHardware` è **REFUTED**: `0xDD8` è il controller e lo slot `0x860` è `notify`. STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
