# T27 — AGENT-AMD — X6000 NX STUB COMPARISON

**Scope:** confrontare il percorso X6000 `0xBF84CFE` e le stub `0x1017A`/`0x10174` con `AMDFramebuffer::initializePM` (`0x28BF60`); risolvere GOT/target, argomenti, ritorni, helper condivisi e percorso `IOHibernateState`.

**Modalità:** sola lettura; AMDSupportPart, X6000FramebufferFull, SystemKC; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PATTERN DUPLICATO**. X6000 e `initializePM` usano la stessa sequenza `0x1017A → 0x10174 → 0x1016E`, gli stessi argomenti e lo stesso percorso `IOHibernateState`. I target sono NX; il comportamento runtime resta **UNPROVEN**. T27 **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| AMDSupportPart | `849ccf34c3976f6859eee962f2fc829c27061dff8d0b0526a1561d374f3b5cf4` |
| X6000FramebufferFull | `7104d431bac240b1c60e5fa1d6308bec9cb7dbb689eaf263e79d1dc0796835eb` |
| Report 148 | `fe54568ec3a30ad10ec2274ffdfbeca3c18c38369462b53d985ba1fcc5211fb9` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Funzioni confrontate

| Binario | Funzione | Inizio | Callsite |
|---|---|---|---:|
| X6000 | `AMDRadeonX6000_AmdRadeonFramebuffer::registerPowerManagementCapabilities` | `0xBF84C7C` | `0xBF84CFE` |
| AMDSupport | `AMDFramebuffer::initializePM` | `0x28BF60` | `0x28C021` |

**PROVEN:** entrambe implementano la registrazione PM.
**PROVEN:** entrambe chiamano la stessa stub.

---

## 3. Sequenza X6000

| Indirizzo | Istruzione | Argomenti |
|---:|---|---|
| `0xBF84CD0` | `callq 0x1017A` | `rdi = this` |
| `0xBF84CDD` | `callq 0x10174` | `rdi = this`, `esi = 1` |
| `0xBF84CE2` | `rdi = 0x1E8(this)` | oggetto PM |
| `0xBF84CF8` | `callq *0x278` | `"IOPMIsPowerManaged"`, `edx=1` |
| `0xBF84CFE` | `callq 0x1016E` | nessun argomento esplicito |
| `0xBF84D03` | `rcx = (%rax)` | vtable |
| `0xBF84D10` | `callq *0x2B8` | `"IOHibernateState"` |
| `0xBF84D23` | `callq 0x1007E` | risultato |
| `0xBF84D41` | `callq *0x268` | set `"IOHibernateState"` |

**PROVEN:** sequenza completa.
**PROVEN:** il ritorno è usato come oggetto.
**PROVEN:** il risultato è propagato.

---

## 4. Sequenza initializePM

| Indirizzo | Istruzione | Argomenti |
|---:|---|---|
| `0x28BFE1` | `callq 0x1017A` | `rdi = this` |
| `0x28BFF2` | `callq 0x10174` | `rdi = this`, `esi = 1` |
| `0x28C005` | `rdi = 0x1E8(this)` | oggetto PM |
| `0x28C01B` | `callq *0x278` | `"IOPMIsPowerManaged"`, `edx=1` |
| `0x28C021` | `callq 0x1016E` | nessun argomento esplicito |
| `0x28C029` | `rax = (%rdi)` | vtable |
| `0x28C033` | `callq *0x2B8` | `"IOHibernateState"` |
| `0x28C046` | `callq 0x1007E` | risultato |
| `0x28C07E` | `callq *0x268` | set `"IOHibernateState"` |

**PROVEN:** sequenza completa.
**PROVEN:** stessa semantica di X6000.
**PROVEN:** il ritorno è usato come oggetto.

---

## 5. Confronto diretto

| Elemento | X6000 | initializePM | Esito |
|---|---|---|---|
| `0x1017A` | `rdi=this` | `rdi=this` | **UGUALE** |
| `0x10174` | `rdi=this`, `esi=1` | `rdi=this`, `esi=1` | **UGUALE** |
| `0x1016E` | nessun arg | nessun arg | **UGUALE** |
| `IOPMIsPowerManaged` | sì | sì | **UGUALE** |
| slot `0x2B8` | sì | sì | **UGUALE** |
| `IOHibernateState` | sì | sì | **UGUALE** |
| helper `0x1007E` | sì | sì | **UGUALE** |
| slot `0x268` | sì | sì | **UGUALE** |

**PROVEN:** il pattern è duplicato.
**PROVEN:** gli argomenti coincidono.
**UNPROVEN:** l’oggetto runtime.

---

## 6. GOT e target

| Stub | GOT | Target | Segmento | Prot | Byte iniziali |
|---:|---:|---:|---|---:|---|
| `0x1017A` | `0x241F8` | `0x9BD150` | `__REGION19` | `0x3` | `00...` |
| `0x10174` | `0x241F0` | `0x9BD500` | `__REGION19` | `0x3` | `00...` |
| `0x1016E` | `0x241E8` | `0x9A7640` | `__REGION19` | `0x3` | `00 00 91 C4...` |

**PROVEN:** tutti i target sono NX.
**PROVEN:** `0x9BD150` e `0x9BD500` iniziano con zeri.
**PROVEN:** `0x9A7640` è dati.
**PROVEN:** i fixup sono rebase-only (report 145).
**UNPROVEN:** il valore runtime.

---

## 7. Helper condivisi

| Helper/slot | Uso |
|---|---|
| `0x1017A` | prima fase PM |
| `0x10174` | seconda fase PM, `esi=1` |
| `0x1016E` | oggetto hibernation |
| `0x1007E` | elaborazione risultato |
| slot `0x7A8` | configurazione iniziale |
| slot `0x278` | `IOPMIsPowerManaged` |
| slot `0x2B8` | `IOHibernateState` |
| slot `0x268` | set `IOHibernateState` |

**PROVEN:** gli helper sono condivisi.
**PROVEN:** la sequenza è identica.
**UNPROVEN:** il significato interno di `0x1017A/0x10174`.

---

## 8. Percorso IOHibernateState

| Passo | X6000 | initializePM |
|---|---|---|
| 1 | `IOPMIsPowerManaged` | `IOPMIsPowerManaged` |
| 2 | stub `0x1016E` | stub `0x1016E` |
| 3 | slot `0x2B8` + `"IOHibernateState"` | slot `0x2B8` + `"IOHibernateState"` |
| 4 | helper `0x1007E` | helper `0x1007E` |
| 5 | set `"IOHibernateState"` se non nullo | set `"IOHibernateState"` se non nullo |

**PROVEN:** percorso di sincronizzazione hibernation.
**PROVEN:** stessa sequenza.
**UNPROVEN:** il valore effettivo.

---

## 9. Statico vs runtime

| Elemento | Statico | Runtime |
|---|---|---|
| Sequenza | **PROVEN** | **UNPROVEN** |
| Argomenti | **PROVEN** | **UNPROVEN** |
| Ritorno come oggetto | **PROVEN** | **UNPROVEN** |
| Target NX | **PROVEN** | **UNPROVEN** |
| Fixup rebase | **PROVEN** | **UNPROVEN** |

**PROVEN:** la struttura statica è chiara.
**UNPROVEN:** l’esecuzione reale.

---

## 10. Verdetto

| Domanda | Risposta |
|---|---|
| X6000 = initializePM | **SÌ**, pattern duplicato |
| Stub condivise | **SÌ** |
| Target NX | **SÌ** |
| Uso come oggetto | **SÌ** |
| Uso come callback | **NO** |
| Runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**PROVEN:** X6000 e AMDSupport condividono il percorso.
**REFUTED:** uso come callback/codice.
**UNPROVEN:** validità runtime dei target NX.

---

## 11. Conclusione

| Domanda | Risposta |
|---|---|
| X6000 callsite | `0xBF84CFE` |
| Stub | `0x1017A`, `0x10174`, `0x1016E` |
| Target | `0x9BD150`, `0x9BD500`, `0x9A7640` |
| Prot | `0x3` NX |
| initializePM | `0x28BF60` |
| Pattern | **duplicato** |
| Helper | `0x1007E` |
| Runtime | **UNPROVEN** |

**Risposta netta:** X6000 e `AMDFramebuffer::initializePM` sono due implementazioni dello stesso percorso. Entrambe chiamano `0x1017A` con `rdi=this`, `0x10174` con `rdi=this, esi=1`, poi `0x1016E`; entrambe leggono `IOPMIsPowerManaged`, usano lo slot `0x2B8` con `"IOHibernateState"`, passano il risultato a `0x1007E` e impostano `"IOHibernateState"` sul controller se non nullo. I tre target sono `0x9BD150`, `0x9BD500`, `0x9A7640`, tutti in `__REGION19` RW/NX; i primi due iniziano con zeri, il terzo è dati. I fixup sono rebase-only e non trasformano NX in codice. La struttura statica è **PROVEN**; la validità runtime resta **UNPROVEN**. STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
