# T27 — AGENT-AMD — ACTUAL LOAD PATH

**Scope:** identificare il percorso effettivo, distinto dalla slide Auxiliary, con cui X5400/AMDSupport raggiungono `_i386_slide_individual_kext`; verificare il collegamento statico con `basePointers[1]`.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, vtable, disassemblaggio, simboli, stringhe; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN staticamente** il percorso `mapKCFileSet` → `addKextsFromKextCollection` → `initWithPrelinkedInfoDict` (slot 38) → `loadExecutable` (slot 53) → `_i386_slide_individual_kext`. Il setter Pageable `PE_set_kc_header(type=2)` è a `0xa3302f`, l’aggiunta dei kext è a `0xa33619`, quindi `basePointers[1]` è impostata **prima** del percorso di caricamento. **UNPROVEN** che a runtime `mapKCFileSet` venga eseguito e che X5400/AMDSupport vengano caricati. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 85 | `39a48d1a18057297070f6b356bf44c294783d5c139a63553e86cd437287d318a` |
| Report 86 | `4eb3ac9969066e270dffdd82a5a6465c193d58ab25e155f0ce18e3dfba82b1eb` |
| Report 87 | `1bdd8782da857fcc40c0ca78b0de788a2dfc2aa8d933a77cfadc106577b43bf1` |
| Report 88 | `7fab5ec6c9f2589a702d791b10e279b1ab9c74f6d27f987fbb9598c8d2d8ff8d` |
| Report 89 | `3f338959323aaaae910fba66c9fc4e63484fd2312e7d530360d0d0e0f8b7da01` |
| Report 90 | `38b8eaa62d4c71ae8762ed8fb50ca58caea3a398efadf7a7ce76330ed5fef68e` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Catena effettiva

```text
mapKCFileSet
  -> PE_set_kc_header(type=2)        0xa3302f   ; basePointers[1]
  -> addKextsFromKextCollection#1    0xa33619
     -> addKextsFromKextCollection#2 0xa33e29
        -> *0x130 slot 38            0xa33ff7 / 0xa3402f
           -> initWithPrelinkedInfoDict 0xa25090
              -> *0x1a8 slot 53      0xa25bc6
                 -> loadExecutable   0xa294e0
                    -> loader        0xa29629
```

| Passo | Indirizzo | Evidenza |
|---|---:|---|
| Setter Pageable | `0xa3302f` | `call PE_set_kc_header`, tipo 2 |
| Aggiunta kext | `0xa33619` | `call addKextsFromKextCollection#1` |
| #1 → #2 | `0xa33e29` | `call addKextsFromKextCollection#2` |
| #2 → slot 38 | `0xa33ff7`, `0xa3402f` | `call *0x130(%rax)` |
| Slot 38 | `0xa25090` | `initWithPrelinkedInfoDict` |
| Slot 53 | `0xa294e0` | `loadExecutable` |
| Loader | `0xa29629` | `call i386_slide_individual_kext` |

**PROVEN:** la catena esiste nel binario.
**PROVEN:** il setter precede l’aggiunta dei kext.
**PROVEN:** lo slot 38 è `initWithPrelinkedInfoDict`.
**PROVEN:** lo slot 53 è `loadExecutable`.

---

## 3. Vtable

| Slot | Offset | Puntatore | Simbolo |
|---:|---:|---:|---|
| 38 | `0x130` | `0xffffff8000a25090` | `initWithPrelinkedInfoDict` |
| 53 | `0x1a8` | `0xffffff8000a294e0` | `loadExecutable` |

**PROVEN:** lo slot 38 contiene `initWithPrelinkedInfoDict`.
**PROVEN:** lo slot 53 contiene `loadExecutable`.

---

## 4. `mapKCFileSet`

```text
0xa3302f: call PE_set_kc_header        ; type = 2 Pageable
...
0xa33619: call addKextsFromKextCollection#1
```

**PROVEN:** `basePointers[1]` è impostata prima della chiamata a `addKextsFromKextCollection#1`.
**PROVEN:** la stessa funzione `mapKCFileSet` esegue entrambe le operazioni.
**UNPROVEN:** che il ramo esegua sempre entrambe le chiamate.

---

## 5. `addKextsFromKextCollection`

| Funzione | VA | Ruolo |
|---|---:|---|
| #1 | `0xa33e10` | wrapper, chiama #2 |
| #2 | `0xa33e60` | costruisce e inizializza i kext |

**PROVEN:** #1 chiama #2 a `0xa33e29`.
**PROVEN:** #2 chiama lo slot 38 a `0xa33ff7` e `0xa3402f`.
**PROVEN:** #2 riceve `kc_kind` e lo passa all’inizializzazione.
**UNPROVEN:** che #2 elabori proprio le entry X5400/AMDSupport a runtime.

---

## 6. `initWithPrelinkedInfoDict` → `loadExecutable`

```text
0xa25bc0: movq (%rdi), %rax
0xa25bc6: callq *0x1a8(%rax)   ; loadExecutable
```

**PROVEN:** l’inizializzazione chiama lo slot 53.
**PROVEN:** `loadExecutable` prosegue verso `_i386_slide_individual_kext` a `0xa29629`.
**UNPROVEN:** che il ramo venga eseguito per le due entry.

---

## 7. Riferimenti X5400/AMDSupport

Stringhe in SystemKC:

| Stringa | Rilievo |
|---|---|
| `com.apple.kext.AMDSupport` | **presente** |
| `AMDSupport` | **presente** |
| `AMDRadeonX5400HWLibs` | **presente** |
| `com.apple.kext.AMDRadeonX5400HWLibs` | **presente** |

Fileset entry:

| Provider | Entry vmaddr | Segmento | `cacheLevel` |
|---|---:|---|---:|
| X5400 | `0x8A90000` | `__DATA` | **1** |
| AMDSupport | `0x13B2C000` | `__DATA` | **1** |

**PROVEN:** entrambi sono descritti nel SystemKC.
**PROVEN:** entrambi usano `cacheLevel=1`.
**UNPROVEN:** il caricamento runtime.

---

## 8. Collegamento con `basePointers[1]`

| Elemento | Esito |
|---|---|
| Setter Pageable | **0xa3302f** |
| Base `[1]` | **lowest_vmaddr + slide** |
| Aggiunta kext | **0xa33619** |
| Init kext | **0xa25090** |
| Loader | **0xa29629** |
| Ordine statico | **base → init → loader** |
| Ordine runtime | **UNPROVEN** |

**PROVEN:** staticamente la base `[1]` è disponibile prima del loader.
**PROVEN:** X5400/AMDSupport richiedono `cacheLevel=1`.
**UNPROVEN:** che il percorso venga eseguito a runtime.

---

## 9. Evidenze runtime

| Evidenza | Esito |
|---|---|
| Boot log | **assente** |
| Trace `mapKCFileSet` | **assente** |
| Trace `addKextsFromKextCollection` | **assente** |
| Trace `initWithPrelinkedInfoDict` | **assente** |
| Trace `loadExecutable` | **assente** |
| `ioreg`/DeviceTree | **assente** |

**PROVEN:** non ci sono log o trace preesistenti.
**UNPROVEN:** il comportamento runtime.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| Percorso distinto dalla slide Aux | **SÌ** |
| `mapKCFileSet` → addKexts | **SÌ, `0xa33619`** |
| addKexts → init | **SÌ, slot 38** |
| init → loadExecutable | **SÌ, slot 53** |
| Setter prima del loader | **SÌ, staticamente** |
| X5400/AMDSupport nel SystemKC | **SÌ** |
| `cacheLevel=1` | **SÌ** |
| Caricamento runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il percorso effettivo non è la slide Auxiliary. `mapKCFileSet` imposta `basePointers[1]` con `PE_set_kc_header(type=2)` a `0xa3302f`, poi chiama `addKextsFromKextCollection#1` a `0xa33619`; #1 → #2 → slot 38 `initWithPrelinkedInfoDict` → slot 53 `loadExecutable` → `_i386_slide_individual_kext`. Staticamente la base `[1]` è pronta prima del loader e X5400/AMDSupport hanno `cacheLevel=1`. Resta **UNPROVEN** che `mapKCFileSet` venga eseguito e che le due entry vengano caricate a runtime. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
