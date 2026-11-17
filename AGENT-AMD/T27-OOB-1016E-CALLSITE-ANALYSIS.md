# T27 — AGENT-AMD — 0x1016E CALLSITE ANALYSIS

**Scope:** identificare il significato delle tre chiamate alla stub `0x1016E` (`0x27C545`, `0x27C55C`, `0x28C021`), ricostruire registri/argomenti/ritorno, confrontarle con le 107 chiamate NX e cercare pattern equivalenti in altri driver AMD.

**Modalità:** sola lettura; AMDSupportPart, X6000FramebufferFull, SystemKC; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **OGGETTO, NON CALLBACK**. Tutti e tre i callsite usano il ritorno come puntatore a oggetto con vtable; `0x1016E` è una categoria NX ricorrente. Un’equivalenza AMD è confermata in `AmdRadeonFramebuffer::registerPowerManagementCapabilities` (`0xBF84CFE`). T27 **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| AMDSupportPart | `849ccf34c3976f6859eee962f2fc829c27061dff8d0b0526a1561d374f3b5cf4` |
| X6000FramebufferFull | `7104d431bac240b1c60e5fa1d6308bec9cb7dbb689eaf263e79d1dc0796835eb` |
| Report 147 | `c4effbeaba65bdac28b8e5d7b89b4acf2d03ff5f45e3f55bd1df475f06be3a22` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Funzioni chiamanti

| Callsite | Funzione | Inizio |
|---:|---|---:|
| `0x27C545` | `AMDFramebuffer::start` | `0x27BCF0` |
| `0x27C55C` | `AMDFramebuffer::start` | `0x27BCF0` |
| `0x28C021` | `AMDFramebuffer::initializePM` | `0x28BF60` |

**PROVEN:** due callsite in `start`, uno in `initializePM`.
**PROVEN:** entrambe le funzioni sono in AMDSupport.

---

## 3. Contesto di start

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x27C52C` | `callq 0x28B8E0` | condizione |
| `0x27C537` | `je 0x27C545` | se ritorno `0` |
| `0x27C545` | `callq 0x1016E` | stub |
| `0x27C54A` | `movq %rax,%rdi` | ritorno = oggetto |
| `0x27C54D` | `movq (%rdi),%rax` | vtable |
| `0x27C550` | `callq *0x868(%rax)` | slot `0x868` |
| `0x27C556` | `movl %eax,-0x124(%rbp)` | salva flag |
| `0x27C55C` | `callq 0x1016E` | stub |
| `0x27C561` | `movq %rax,%rdi` | ritorno = oggetto |
| `0x27C564` | `movl -0x124(%rbp),%esi` | flag |
| `0x27C56A` | `andl $-0x3,%esi` | maschera |
| `0x27C56D` | `movq (%rdi),%rax` | vtable |
| `0x27C570` | `callq *0x860(%rax)` | slot `0x860` |

**PROVEN:** il ritorno è trattato come oggetto.
**PROVEN:** vengono chiamati gli slot `0x868` e `0x860`.
**PROVEN:** il primo callsite è condizionato da `0x28B8E0 == 0`.
**UNPROVEN:** il tipo dell’oggetto.

---

## 4. Contesto di initializePM

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x28BFE1` | `callq 0x1017A` | stub vicino |
| `0x28BFF2` | `callq 0x10174` | stub vicino |
| `0x28C005` | `movq 0x1E8(%rax),%rdi` | oggetto PM |
| `0x28C00F` | `leaq "IOPMIsPowerManaged"` | proprietà |
| `0x28C01B` | `callq *0x278(%rax)` | vtable PM |
| `0x28C021` | `callq 0x1016E` | stub |
| `0x28C026` | `movq %rax,%rdi` | ritorno = oggetto |
| `0x28C029` | `movq (%rdi),%rax` | vtable |
| `0x28C02C` | `leaq "IOHibernateState"` | proprietà |
| `0x28C033` | `callq *0x2B8(%rax)` | slot `0x2B8` |
| `0x28C039` | `movq %rax,%rdi` | risultato |
| `0x28C046` | `callq 0x1007E` | helper |
| `0x28C04B` | `movq %rax,-0x140(%rbp)` | salva risultato |

**PROVEN:** il ritorno è trattato come oggetto.
**PROVEN:** lo slot `0x2B8` riceve `"IOHibernateState"`.
**PROVEN:** il risultato passa a `0x1007E`.
**UNPROVEN:** il tipo dell’oggetto.

---

## 5. Uso del ritorno

| Callsite | Uso | Codice? | Callback? | Oggetto? |
|---:|---|---|---|---|
| `0x27C545` | vtable `0x868` | **NO** | **NO** | **SÌ** |
| `0x27C55C` | vtable `0x860` | **NO** | **NO** | **SÌ** |
| `0x28C021` | vtable `0x2B8` | **NO** | **NO** | **SÌ** |

**PROVEN:** nessun uso come codice.
**PROVEN:** nessun uso come callback.
**PROVEN:** tutti usano il ritorno come oggetto.

---

## 6. Confronto con le 107 chiamate NX

| Voce | Valore |
|---|---:|
| Callsite NX in AMDSupport | `107` |
| Stub NX distinte | `24` |
| Callsite di `0x1016E` | `3` |
| Callsite del cluster `0x10162`–`0x1018C` | `14` |
| Target di `0x1016E` | `0x9A7640` NX |

**PROVEN:** i tre callsite sono un sottoinsieme delle 107.
**PROVEN:** `0x1016E` è una delle 24 stub NX chiamate.
**PROVEN:** il cluster ha 14 callsite.
**UNPROVEN:** la semantica delle altre 104 chiamate.

---

## 7. Equivalenza in altri driver AMD

| Elemento | Valore |
|---|---|
| Funzione | `AMDRadeonX6000_AmdRadeonFramebuffer::registerPowerManagementCapabilities` |
| Inizio | `0xBF84C7C` |
| Callsite | `0xBF84CFE` |
| Stub | `0x1016E` |
| Precedenti | `0x1017A`, `0x10174` |
| Proprietà | `"IOHibernateState"` |
| Slot | `0x2B8` |
| Helper | `0x1007E` |

**PROVEN:** X6000 ripete lo schema di `initializePM`.
**PROVEN:** il callsite è reale.
**PROVEN:** il target è lo stesso stub NX.
**UNPROVEN:** altre equivalenze AMD.

### Candidati grezzi

| Voce | Valore |
|---|---:|
| `E8` totali in SystemKC | `1390998` |
| Candidati verso `0x1016E` in RX | `75` |
| Equivalenza AMD confermata | `1` (`0xBF84CFE`) |

**PROVEN:** il candidato X6000 è confermato.
**UNPROVEN:** gli altri 74 candidati, molti possibili falsi positivi.

---

## 8. Flusso

| Funzione | Flusso |
|---|---|
| `start` | condizione → stub → vtable `0x868` → stub → vtable `0x860` |
| `initializePM` | PM property → stub → vtable `0x2B8` → helper |
| X6000 | stessa sequenza di `initializePM` |

**PROVEN:** lo schema è coerente tra AMDSupport e X6000.
**PROVEN:** il ritorno è sempre un oggetto.
**UNPROVEN:** l’oggetto reale a runtime.

---

## 9. Verdetto

| Domanda | Risposta |
|---|---|
| Ritorno usato come codice | **NO** |
| Ritorno usato come callback | **NO** |
| Ritorno usato come oggetto | **SÌ** |
| Target NX | **SÌ** |
| Pattern equivalente AMD | **SÌ** (X6000) |
| Anomalia isolata | **NO** |
| Runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**PROVEN:** il pattern è ricorrente e usato come oggetto.
**REFUTED:** uso come callback/codice nei tre callsite.
**UNPROVEN:** come un oggetto NX possa essere valido a runtime.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| `0x27C545` | `start`, vtable `0x868` |
| `0x27C55C` | `start`, vtable `0x860` |
| `0x28C021` | `initializePM`, vtable `0x2B8` |
| X6000 | `0xBF84CFE`, stesso schema |
| Ritorno | oggetto, non codice |
| Target | `0x9A7640` NX |
| Categoria | NX ricorrente |
| Caller Wrangler | **UNPROVEN** |

**Risposta netta:** i tre callsite non usano il ritorno come codice o callback. `AMDFramebuffer::start` lo usa come oggetto e chiama gli slot `0x868` e `0x860`; `AMDFramebuffer::initializePM` lo usa come oggetto e chiama lo slot `0x2B8` con `"IOHibernateState"`; il risultato passa a `0x1007E`. `AMDRadeonX6000_AmdRadeonFramebuffer::registerPowerManagementCapabilities` ripete lo stesso schema a `0xBF84CFE`, dopo gli stub `0x1017A` e `0x10174`. I tre callsite sono un sottoinsieme delle 107 chiamate NX; `0x1016E` è una delle 24 stub NX chiamate e non è un’anomalia isolata. Il target `0x9A7640` resta dati NX; la semantica runtime è **UNPROVEN**. STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
