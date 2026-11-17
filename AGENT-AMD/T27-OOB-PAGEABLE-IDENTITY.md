# T27 — AGENT-AMD — PAGEABLE IDENTITY

**Scope:** stabilire se `r14` e gli oggetti dei dispatch virtuali in `loadFileSetKexts` identificano la stessa collection Pageable che valorizza `basePointers[1]`; ricostruire `r12`, `r14`, `rax`, `rdi` e i rami tra `PE_set_kc_header` e `i386_slide_individual_kext`.

**Modalità:** sola lettura; BootKC 26B131, disassemblaggio, simboli, dati; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **REFUTED** che `r12`/`r14` siano la collection Pageable. `r12` a `0xa41827` carica `collection_mach_headers[3]` (`0x13aa728`), cioè l’header **Auxiliary**. La slide a `0xa4205b` è quindi **Aux**; `slidePrelinkedExecutable` → `loadExecutable` resta **PROVEN** come dispatch virtuale generico, ma **non** come percorso Pageable. La catena Pageable → slide → `loadExecutable` è **ritirata**. T27 resta **OPEN**.

## CORREZIONE (Prompt 91)

Esiste un percorso distinto e più diretto: `mapKCFileSet` → `addKextsFromKextCollection` → `initWithPrelinkedInfoDict` (slot 38) → `loadExecutable`. La conclusione “Pageable → loadExecutable UNPROVEN” è superata **staticamente**; l’ordine runtime resta **UNPROVEN**. Vedi `T27-OOB-ACTUAL-LOAD-PATH.md`.

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 84 | `cf67fadc1a97c9261ed4984508b9b1eb6449a3255a29a0ba5998cc9fccdad41f` |
| Correzione 85 | `39a48d1a18057297070f6b356bf44c294783d5c139a63553e86cd437287d318a` |
| Report 86 | `4eb3ac9969066e270dffdd82a5a6465c193d58ab25e155f0ce18e3dfba82b1eb` |
| Report 87 corretto | `1bdd8782da857fcc40c0ca78b0de788a2dfc2aa8d933a77cfadc106577b43bf1` |
| Report 88 corretto | `7fab5ec6c9f2589a702d791b10e279b1ab9c74f6d27f987fbb9598c8d2d8ff8d` |
| Report 89 corretto | `3f338959323aaaae910fba66c9fc4e63484fd2312e7d530360d0d0e0f8b7da01` |

**PROVEN:** gli artefatti sono quelli indicati.
**PROVEN:** i report 88 e 89 sono corretti con il nuovo esito.

---

## 2. Provenienza di `r12`

```text
0xa41827: movq 0x968efa(%rip), %r12
```

Calcolo:

```text
next RIP = 0xa4182e
0xa4182e + 0x968efa = 0x13aa728
```

Simboli vicini:

| Simbolo | VA |
|---|---|
| `_collection_base_pointers` | `0xffffff80013aa6f0` |
| `_collection_mach_headers` | `0xffffff80013aa710` |
| `_collection_slide` | `0xffffff80013aa730` |

`0x13aa728` = `_collection_mach_headers + 3*8` = **`collection_mach_headers[3]`**.

**PROVEN:** `r12` carica l’header **Auxiliary**.
**PROVEN:** `r12` non è `collection_mach_headers[1]` (Pageable).
**PROVEN:** il valore nel file è **0x0**; viene scritto a runtime dal map Aux.

---

## 3. Provenienza di `r14`

```text
0xa42034: movq 0x95deed(%rip), %rax     ; global metaclass
0xa4203b: movq %r12, %rdi               ; Auxiliary header
0xa4203e: callq *0x88(%rax)             ; lookup
0xa4204d: movq %rax, %r14
```

**PROVEN:** `r14` deriva da un lookup che riceve `r12`, cioè l’header Auxiliary.
**PROVEN:** `r14` non è la collection Pageable per costruzione dell’argomento.
**UNPROVEN:** il tipo esatto restituito dal lookup.
**UNPROVEN:** che `r14` sia una `OSKext` completa.

---

## 4. Sequenza in `loadFileSetKexts`

| Indirizzo | Operazione |
|---:|---|
| `0xa41953` | `loadKCFileSet(kind=2)` **Pageable** |
| `0xa41a5d` | `loadKCFileSet(kind=3)` **Auxiliary** |
| `0xa41827` | `r12 = collection_mach_headers[3]` **Auxiliary** |
| `0xa4203e` | lookup con `r12` |
| `0xa4205b` | `call *0x1a0(%rax)` **slide Auxiliary** |

**PROVEN:** la slide segue entrambe le mappe.
**PROVEN:** l’oggetto della slide è costruito dall’header Auxiliary.
**PROVEN:** la slide non è Pageable.
**UNPROVEN:** che la mappa Pageable e la slide Aux siano nello stesso ramo runtime.

---

## 5. Identità della collection

| Oggetto | Fonte | Collection |
|---|---|---|
| `r12` | `collection_mach_headers[3]` | **Auxiliary** |
| `r14` | lookup con `r12` | **Auxiliary** |
| base `[1]` | `PE_set_kc_header(type=2)` | **Pageable** |
| base `[3]` | `PE_set_kc_header(type=3)` | **Auxiliary** |

**PROVEN:** `r12`/`r14` e `base[1]` appartengono a collection diverse.
**REFUTED:** identità Pageable di `r12`/`r14`.
**UNPROVEN:** il percorso Pageable → `loadExecutable`.

---

## 6. `slidePrelinkedExecutable` → `loadExecutable`

| Call site | Oggetto |
|---:|---|
| `0xa2946b` | `r12` (Auxiliary) |
| `0xa2947e` | `0x60(%r15)` (secondo oggetto) |

Entrambi usano `call *0x1a8(%rax)`, slot **53** = `loadExecutable`.

**PROVEN:** il dispatch virtuale verso `loadExecutable` esiste.
**PROVEN:** il primo call site usa l’oggetto Auxiliary.
**UNPROVEN:** il secondo oggetto e il percorso Pageable.
**UNPROVEN:** che X5400/AMDSupport passino da qui.

---

## 7. Rami tra setter e loader

| Elemento | Esito |
|---|---|
| Edge diretto setter → loader | **NO** |
| Setter Pageable | **in `mapKCFileSet`** |
| Loader | **in `loadExecutable`** |
| Stessa funzione | **NO** |
| Stessa collection | **NO per Pageable** |
| Ramo alternativo Pageable | **UNPROVEN** |

**PROVEN:** non esiste un edge di controllo diretto tra il setter Pageable e il loader.
**PROVEN:** la slide osservata è Auxiliary.
**UNPROVEN:** un ramo Pageable separato.

---

## 8. X5400 e AMDSupport

| Elemento | X5400 | AMDSupport |
|---|---|---|
| `cacheLevel=1` | **SÌ** | **SÌ** |
| Base `[1]` | **necessaria** | **necessaria** |
| Base settata da Pageable | **SÌ, staticamente** | **SÌ, staticamente** |
| LoadExecutable Pageable | **UNPROVEN** | **UNPROVEN** |
| Ordine runtime | **UNPROVEN** | **UNPROVEN** |

**PROVEN:** la base `[1]` viene settata dalla mappa Pageable.
**PROVEN:** i due kext condividono lo stesso requisito.
**UNPROVEN:** che il loro `loadExecutable` avvenga dopo la base `[1]`.

---

## 9. Evidenze runtime

| Evidenza | Esito |
|---|---|
| Boot log | **assente** |
| Trace `loadFileSetKexts` | **assente** |
| Trace `slidePrelinkedExecutable` | **assente** |
| Trace `loadExecutable` | **assente** |
| `ioreg`/DeviceTree | **assente** |
| Valore `[1]` | **UNPROVEN** |

**PROVEN:** non ci sono log o trace preesistenti.
**UNPROVEN:** il comportamento runtime.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| `r12` è Pageable | **NO — è Auxiliary** |
| `r14` è Pageable | **NO — deriva da r12** |
| Slide a `0xa4205b` | **Auxiliary** |
| Slide → loadExecutable | **SÌ, slot 53** |
| Pageable → slide | **NO** |
| Pageable → loadExecutable | **UNPROVEN** |
| Base `[1]` settata | **SÌ, dalla mappa Pageable** |
| X5400/AMDSupport dopo Pageable | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** l’identità Pageable è **refutata**. `r12` a `0xa41827` carica `collection_mach_headers[3]` (`0x13aa728`), cioè l’header **Auxiliary**; `r14` deriva da un lookup con quell’header e la slide a `0xa4205b` è Auxiliary. `slidePrelinkedExecutable` → `loadExecutable` è un dispatch virtuale valido, ma non prova il percorso Pageable. La base `[1]` resta settata dalla mappa Pageable, mentre il percorso `loadExecutable` di X5400/AMDSupport resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
