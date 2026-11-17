# T27 — AGENT-AMD — PAGEABLE KC ORDER

**Scope:** ricostruire l’ordine statico Pageable KC → caricamento kext, verificare `PE_set_kc_header`, `PE_reset_kc_header`, i chiamanti di `mapKCFileSet`/`loadExecutable` e stabilire se X5400/AMDSupport possono essere caricati dopo l’inizializzazione Pageable.

**Modalità:** sola lettura; BootKC 26B131, disassemblaggio, simboli, sorgente Apple; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN staticamente** che `loadKCFileSet(Pageable, kind=2)` → `mapKCFileSet` → `PE_set_kc_header(type=2)` assegna `basePointers[1]`. **PROVEN** che il reset avviene solo sul ramo d’errore e che il successo non azzera la base. **PROVEN** che il caricamento Pageable è attivato da `OSKext::handleRequest` → `loadFileSetKexts`, quindi è **request-driven**, non un passo diretto del boot. **PROVEN** che `loadFileSetKexts` non carica direttamente i singoli kext e che `loadExecutable` non ha chiamanti diretti `E8` nel BootKC. **UNPROVEN** che a runtime la richiesta Pageable preceda il caricamento di X5400/AMDSupport. T27 resta **OPEN**.

## CORREZIONE (Prompt 89)

`loadFileSetKexts` non carica direttamente i singoli kext, ma chiama `*0x1a0` (`slidePrelinkedExecutable`) a `0xa4205b`; questa chiama `*0x1a8` (`loadExecutable`) a `0xa2946b/0xa2947e`. La frase “non carica i singoli kext” va letta come “non li carica direttamente”; il percorso indiretto esiste. Vedi `T27-OOB-VTABLE-DISPATCH.md`.

## CORREZIONE (Prompt 90)

`r12` a `0xa41827` carica `collection_mach_headers[3]` (`0x13aa728`), cioè l’header **Auxiliary**, non Pageable. Quindi la slide a `0xa4205b` è **Aux**; la catena Pageable → slide → `loadExecutable` non è provata. Vedi `T27-OOB-PAGEABLE-IDENTITY.md`.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 84 | `cf67fadc1a97c9261ed4984508b9b1eb6449a3255a29a0ba5998cc9fccdad41f` |
| Correzione 85 | `39a48d1a18057297070f6b356bf44c294783d5c139a63553e86cd437287d318a` |
| Report 86 | `4eb3ac9969066e270dffdd82a5a6465c193d58ab25e155f0ce18e3dfba82b1eb` |
| Report 87 corretto | `1bdd8782da857fcc40c0ca78b0de788a2dfc2aa8d933a77cfadc106577b43bf1` |

**PROVEN:** gli artefatti sono quelli indicati.
**PROVEN:** il report 87 è stato corretto: `KCKindPageable=2`, non 1.

---

## 2. Enum `kc_kind_t`

```c
typedef enum kc_kind {
    KCKindNone      = -1,
    KCKindUnknown   = 0,
    KCKindPrimary   = 1,
    KCKindPageable  = 2,
    KCKindAuxiliary = 3,
    KCNumKinds      = 4,
} kc_kind_t;
```

Fonte: Apple `pexpert/pexpert/pexpert.h`.

**PROVEN:** `KCKindPageable` vale **2**.
**PROVEN:** `KCKindPrimary` vale **1**.
**PROVEN:** `KCKindAuxiliary` vale **3**.
**PROVEN:** `kc_kind2index` mappa Pageable all’indice **1**.

---

## 3. Catena Pageable

```text
OSKext::handleRequest                 0xa3ec00
  -> OSKext::loadFileSetKexts         0xa41670
     -> OSKext::loadKCFileSet         0xa42290
        -> OSKext::mapKCFileSet       0xa32ed0
           -> PE_set_kc_header(2)     0xb68770
              -> collection_base_pointers[1]
```

| Passo | Call site | Argomento |
|---|---:|---|
| `loadFileSetKexts` → `loadKCFileSet` | `0xa41953` | `esi=2` **Pageable** |
| `loadKCFileSet` → `mapKCFileSet` | `0xa424c2` | `kind=2` |
| `mapKCFileSet` → `PE_set_kc_header` | `0xa3302f` | `type=2` **Pageable** |
| `PE_set_kc_header` → base `[1]` | — | `lowest_vmaddr + slide` |

Disassemblaggio del setter:

```text
0xa32ee1: movl %r9d, %ebx          ; bl = kind
0xa33029: movzbl %bl, %edi
0xa3302c: xorl $0x3, %edi          ; type = bl ^ 3
0xa3302f: callq 0xffffff8000b68770 ; PE_set_kc_header
```

Per `kind=2`: `bl=1`, `1 ^ 3 = 2` = **KCKindPageable**.

**PROVEN:** il percorso Pageable chiama il setter con tipo 2.
**PROVEN:** `PE_set_kc_header` assegna `[1]`.
**PROVEN:** il tipo 1 a `0x4c6aba` è **Primary**, non Pageable.

---

## 4. Reset

| Percorso | Reset |
|---|---|
| Successo map | **NO** |
| Errore map | **SÌ** a `0xa33562` |

```text
0xa33524: testl %eax, %eax
0xa33527: je    0xa335fa        ; successo: salta il reset
...
0xa3355f: movl %r14d, %edi
0xa33562: callq PE_reset_kc_header
```

**PROVEN:** `PE_reset_kc_header` è sul ramo d’errore.
**PROVEN:** il successo non azzera `[1]`.
**PROVEN:** un errore di mapping azzera la base e ritorna errore.

---

## 5. Chiamanti

| Funzione | Chiamanti diretti |
|---|---|
| `loadFileSetKexts` | `OSKext::handleRequest` a `0xa3fb95` |
| `loadKCFileSet` | `loadFileSetKexts` a `0xa41953` (Pageable) e `0xa41a5d` (Aux) |
| `mapKCFileSet` | `loadKCFileSet`; `resetKCFileSetSegments`; ricorsione interna |
| `loadExecutable` | **nessun `E8` nel BootKC** |
| `i386_slide_individual_kext` | `OSKext::loadExecutable` a `0xa29629` |

**PROVEN:** il caricamento Pageable è attivato da una **richiesta kext**.
**PROVEN:** `loadFileSetKexts` carica la collection e le personalità, non i singoli kext.
**PROVEN:** `loadExecutable` non ha chiamanti diretti `E8`.
**UNPROVEN:** chiamanti indiretti di `loadExecutable`.
**UNPROVEN:** che `handleRequest` venga invocato prima del caricamento dei due kext.

---

## 6. Caricamento dei singoli kext

| Evidenza | Esito |
|---|---|
| `loadFileSetKexts` → `loadExecutable` diretto | **nessun `E8`** |
| `loadFileSetKexts` → `slidePrelinkedExecutable` | **sì, `*0x1a0` a `0xa4205b`** |
| `slidePrelinkedExecutable` → `loadExecutable` | **sì, `*0x1a8` a `0xa2946b/0xa2947e`** |
| `loadExecutable` chiamato da `E8` | **nessuno** |
| `loadExecutable` → loader | **sì, `0xa29629`** |
| Chiamante indiretto | **sì, via vtable** |

**PROVEN:** il caricamento della collection e quello dei singoli kext sono fasi separate nel BootKC.
**PROVEN:** `loadExecutable` usa `basePointers[1]` tramite il loader.
**UNPROVEN:** il percorso runtime che porta a `loadExecutable` per X5400/AMDSupport.

---

## 7. X5400 e AMDSupport

| Condizione | X5400 | AMDSupport |
|---|---|---|
| `cacheLevel=1` | **SÌ** | **SÌ** |
| Base richiesta | `[1]` | `[1]` |
| Base condivisa | **SÌ** | **SÌ** |
| Collection Pageable caricata | **UNPROVEN** | **UNPROVEN** |
| Kext caricato | **UNPROVEN** | **UNPROVEN** |
| Ordine Pageable→kext | **UNPROVEN** | **UNPROVEN** |

**PROVEN:** i due kext hanno lo stesso requisito.
**PROVEN:** non ci sono condizioni separate note.
**PROVEN:** se `[1]` è nullo, entrambi si fermano a `Invalid cache level`.
**UNPROVEN:** che la richiesta Pageable preceda il loro caricamento.

---

## 8. Evidenze runtime

| Evidenza | Esito |
|---|---|
| Boot log | **assente** |
| Trace `handleRequest` | **assente** |
| Trace `PE_set_kc_header` | **assente** |
| Trace `loadExecutable` | **assente** |
| `ioreg`/DeviceTree | **assente** |
| Valore `[1]` | **UNPROVEN** |

**PROVEN:** non ci sono log o trace preesistenti.
**UNPROVEN:** che la base sia non nulla al momento del caricamento.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `KCKindPageable` | **2** |
| `loadKCFileSet` Pageable | **sì, kind=2** |
| `mapKCFileSet` setta `[1]` | **sì, type=2** |
| Reset su successo | **NO** |
| Reset su errore | **SÌ** |
| Pageable è request-driven | **SÌ** |
| `loadFileSetKexts` carica i kext direttamente | **NO** |
| `loadFileSetKexts` → slide → loadExecutable | **SÌ, staticamente** |
| `loadExecutable` ha chiamanti diretti | **NO** |
| Ordine runtime Pageable→kext | **UNPROVEN** |
| X5400/AMDSupport possono caricarsi dopo Pageable | **SÌ, se la richiesta precede il load** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la catena statica esiste ed è completa: `handleRequest` → `loadFileSetKexts` → `loadKCFileSet(kind=2)` → `mapKCFileSet` → `PE_set_kc_header(type=2)` → `basePointers[1]`. Il reset è solo sul ramo d’errore. Tuttavia il caricamento Pageable è **request-driven**, non un passo diretto del boot; `loadFileSetKexts` non carica direttamente i singoli kext, ma chiama `slidePrelinkedExecutable`, che a sua volta chiama `loadExecutable`. X5400 e AMDSupport possono quindi caricarsi dopo l’inizializzazione Pageable **solo se** la richiesta Pageable è già avvenuta; l’ordine runtime resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
