# T27 — AGENT-AMD — VTABLE DISPATCH

**Scope:** identificare l’invocazione indiretta di `OSKext::loadExecutable` e `OSKext::loadFileSetKexts`, ricostruire vtable, slot virtuali e function pointer, e verificare se esiste un percorso statico Pageable → X5400/AMDSupport.

**Modalità:** sola lettura; BootKC 26B131, vtable, disassemblaggio, simboli, tabelle dati; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che `loadExecutable` è lo slot **53** della vtable `OSKext` e che `slidePrelinkedExecutable` lo invoca con `call *0x1a8(%rax)`. **PROVEN** che `loadFileSetKexts` invoca lo slot **52** (`slidePrelinkedExecutable`) con `call *0x1a0(%rax)` a `0xa4205b`, dopo la chiamata Pageable a `0xa41953`. **PROVEN** che esistono pointer a `loadFileSetKexts`, `handleRequest` e `loadExecutable` in tabelle dati. **UNPROVEN** che l’oggetto `r14` sia la stessa collection Pageable, che `handleRequest` sia invocato prima del caricamento dei due kext e che l’ordine runtime sia quello lineare. T27 resta **OPEN**.

## CORREZIONE (Prompt 90)

`r12` a `0xa41827` carica `collection_mach_headers[3]` (`0x13aa728`), cioè l’header **Auxiliary**, non Pageable. La slide a `0xa4205b` è quindi **Aux**; la conclusione “percorso Pageable → slide → loadExecutable” è **ritirata**. Il setter Pageable → `basePointers[1]` resta valido. Vedi `T27-OOB-PAGEABLE-IDENTITY.md`.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 84 | `cf67fadc1a97c9261ed4984508b9b1eb6449a3255a29a0ba5998cc9fccdad41f` |
| Correzione 85 | `39a48d1a18057297070f6b356bf44c294783d5c139a63553e86cd437287d318a` |
| Report 86 | `4eb3ac9969066e270dffdd82a5a6465c193d58ab25e155f0ce18e3dfba82b1eb` |
| Report 87 corretto | `1bdd8782da857fcc40c0ca78b0de788a2dfc2aa8d933a77cfadc106577b43bf1` |
| Report 88 corretto | `b5db8ef4fbf2f3aa57dd4db412f19288998e8ffa6f28a288fb172f9ba43922ea` |

**PROVEN:** gli artefatti sono quelli indicati.
**PROVEN:** il report 88 è corretto sul percorso indiretto.

---

## 2. Vtable `OSKext`

| Simbolo | VA |
|---|---|
| `__ZTV6OSKext` | `0xffffff800025a508` |
| file offset | `0x5a508` |

Slot rilevanti:

| Slot | Offset | Puntatore | Simbolo |
|---:|---:|---:|---|
| 50 | `0x190` | `0xffffff8000a27de0` | `OSKext::load` |
| 51 | `0x198` | `0xffffff8000a284f0` | `OSKext::unload` |
| 52 | `0x1a0` | `0xffffff8000a28ed0` | `OSKext::slidePrelinkedExecutable` |
| 53 | `0x1a8` | `0xffffff8000a294e0` | `OSKext::loadExecutable` |

**PROVEN:** `loadExecutable` è lo slot 53.
**PROVEN:** `slidePrelinkedExecutable` è lo slot 52.
**PROVEN:** gli slot contengono puntatori assoluti.

---

## 3. `slidePrelinkedExecutable` → `loadExecutable`

```text
0xa2946b: callq *0x1a8(%rax)   ; loadExecutable
0xa2947e: callq *0x1a8(%rax)   ; loadExecutable
```

**PROVEN:** `slidePrelinkedExecutable` invoca lo slot 53.
**PROVEN:** esistono due call site indiretti.
**UNPROVEN:** quale dei due venga eseguito a runtime.

---

## 4. `loadFileSetKexts` → `slidePrelinkedExecutable`

```text
0xa4204d: movq %rax, %r14
0xa42050: movq %rax, %rdi
0xa42053: movq (%r14), %rax
0xa42056: movl $0x2, %esi
0xa4205b: callq *0x1a0(%rax)   ; slidePrelinkedExecutable
```

**PROVEN:** `loadFileSetKexts` invoca lo slot 52.
**PROVEN:** il call site è `0xa4205b`.
**PROVEN:** la chiamata Pageable a `0xa41953` precede `0xa4205b` nel corpo della funzione.
**UNPROVEN:** che `r14` sia la stessa collection Pageable.
**UNPROVEN:** che il percorso lineare non venga deviato.

---

## 5. Catena statica

```text
handleRequest
  -> loadFileSetKexts
     -> loadKCFileSet(kind=2)
        -> mapKCFileSet
           -> PE_set_kc_header(type=2)
              -> basePointers[1]
     -> slidePrelinkedExecutable (slot 52)  [r12 = Auxiliary]
        -> loadExecutable (slot 53)
           -> i386_slide_individual_kext
              -> fixup_value(basePointers[1])
```

**PROVEN:** gli edge esistono nel binario.
**PROVEN:** la chiamata Pageable è precedente alla slide nel corpo di `loadFileSetKexts`.
**UNPROVEN:** che la stessa richiesta esegua entrambi gli edge in sequenza.

---

## 6. Function pointer e tabelle

| Funzione | Puntatore in tabella | File offset |
|---|---:|---:|
| `handleRequest` | `0xffffff8000a3ec00` | `0x33af6e8` |
| `loadExecutable` | `0xffffff8000a294e0` | `0x33af778` |
| `loadFileSetKexts` | `0xffffff8000a41670` | `0x33af888` |
| `load` | `0xffffff8000a27de0` | `0x33b00e8` |

**PROVEN:** esistono riferimenti dati a queste funzioni.
**PROVEN:** `loadFileSetKexts` ha un chiamante diretto `handleRequest`.
**UNPROVEN:** che le tabelle siano usate come dispatch a runtime.
**UNPROVEN:** che `handleRequest` venga invocato prima dei due kext.

---

## 7. Dipendenza Pageable → kext

| Condizione | Esito |
|---|---|
| Pageable base settata | **sì, se `loadFileSetKexts` esegue `0xa41953`** |
| Slide dopo Pageable | **NO: r12 è Auxiliary** |
| Slide → loadExecutable | **sì, slot 53** |
| Stessa collection | **REFUTED per Pageable** |
| Ordine runtime | **UNPROVEN** |
| X5400/AMDSupport caricati dopo | **UNPROVEN** |

**PROVEN:** il percorso statico esiste.
**PROVEN:** non serve un chiamante `E8` diretto per `loadExecutable`.
**UNPROVEN:** che il percorso venga eseguito nell’ordine richiesto.

---

## 8. X5400 e AMDSupport

| Elemento | X5400 | AMDSupport |
|---|---|---|
| `cacheLevel=1` | **SÌ** | **SÌ** |
| Base `[1]` | **necessaria** | **necessaria** |
| Percorso statico Pageable → load | **SÌ** | **SÌ** |
| Stessa request | **UNPROVEN** | **UNPROVEN** |
| Kext caricato | **UNPROVEN** | **UNPROVEN** |

**PROVEN:** entrambi dipendono dalla stessa base.
**PROVEN:** non ci sono condizioni separate note.
**UNPROVEN:** l’ordine runtime e il caricamento effettivo.

---

## 9. Evidenze runtime

| Evidenza | Esito |
|---|---|
| Boot log | **assente** |
| Trace vtable | **assente** |
| Trace `handleRequest` | **assente** |
| Trace `loadExecutable` | **assente** |
| `ioreg`/DeviceTree | **assente** |
| Valore `[1]` | **UNPROVEN** |

**PROVEN:** non ci sono log o trace preesistenti.
**UNPROVEN:** il comportamento runtime.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| `loadExecutable` è virtuale | **SÌ, slot 53** |
| `slidePrelinkedExecutable` lo chiama | **SÌ, `*0x1a8`** |
| `loadFileSetKexts` chiama slide | **SÌ, `*0x1a0`** |
| Slide dopo Pageable | **NO: è Auxiliary** |
| Stessa collection | **REFUTED per Pageable** |
| `loadExecutable` ha chiamanti `E8` | **NO** |
| Dispatch indiretto usato | **SÌ staticamente** |
| Ordine runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `loadExecutable` non è raggiunto da alcun `E8`; è lo slot **53** della vtable `OSKext` e viene invocato da `slidePrelinkedExecutable` con `call *0x1a8(%rax)`. `loadFileSetKexts` invoca lo slot **52** con `call *0x1a0(%rax)` a `0xa4205b`, dopo le chiamate Pageable/Aux; `r12` è l’header **Auxiliary**, quindi la slide è Aux, non Pageable. Il percorso **Auxiliary** → slide → loadExecutable esiste; il percorso **Pageable** → slide **non è provato**, perché `r12` è l’header Auxiliary. Resta **UNPROVEN** che X5400/AMDSupport vengano caricati via `loadExecutable` dopo la base `[1]`. X5400 e AMDSupport dipendono dalla stessa base `[1]`; non ci sono condizioni separate note. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
