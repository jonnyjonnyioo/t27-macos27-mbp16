# T27 — AGENT-AMD — SELEZIONE ENTRY

**Scope:** verificare se `addKextsFromKextCollection#1/#2` seleziona davvero X5400 e AMDSupport e li inoltra a `initWithPrelinkedInfoDict`; ricostruire iteratori, filtri, confronti di nome ed esclusioni; separare selezione statica e caricamento runtime.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, vtable, disassemblaggio, simboli, stringhe; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che `addKextsFromKextCollection#2` è un iteratore generico che costruisce una exclude list da `PRELINK_INFO` e chiama lo slot 38 `initWithPrelinkedInfoDict` per le entry selezionate. **PROVEN** che X5400/AMDSupport sono presenti nel SystemKC e hanno `cacheLevel=1`. **REFUTED** che esista un confronto diretto con i nomi `X5400` o `AMDSupport` nel codice di selezione. **UNPROVEN** che le due entry specifiche vengano selezionate e caricate a runtime. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 89 | `3f338959323aaaae910fba66c9fc4e63484fd2312e7d530360d0d0e0f8b7da01` |
| Report 90 | `38b8eaa62d4c71ae8762ed8fb50ca58caea3a398efadf7a7ce76330ed5fef68e` |
| Report 91 | `ff83147a9f1495cd5d182f0f54ccc79df45e95494425e1dd1d40d004152d8a3a` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Funzioni di selezione

| Funzione | VA | Ruolo |
|---|---:|---|
| `mapKCFileSet` | `0xa32ed0` | chiama #1 dopo il setter |
| `addKextsFromKextCollection#1` | `0xa33e10` | wrapper |
| `addKextsFromKextCollection#2` | `0xa33e60` | iteratore e init |
| `createExcludeListFromPrelinkInfo` | `0xa34a20` | costruisce la exclude list |
| `initWithPrelinkedInfoDict` | `0xa25090` | slot 38 |
| `loadExecutable` | `0xa294e0` | slot 53 |

**PROVEN:** la catena di chiamata è quella indicata.
**PROVEN:** #2 chiama `createExcludeListFromPrelinkInfo` a `0xa33fec`.
**PROVEN:** #2 chiama lo slot 38 a `0xa33ff7` e `0xa3402f`.

---

## 3. Iteratore e filtri

```text
0xa33fec: call createExcludeListFromPrelinkInfo
0xa33ff7: call *0x130(%rax)   ; initWithPrelinkedInfoDict
0xa3402f: call *0x130(%rax)   ; initWithPrelinkedInfoDict
```

| Elemento | Esito |
|---|---|
| Iterazione generica delle entry | **SÌ** |
| Exclude list da `PRELINK_INFO` | **SÌ** |
| Confronto diretto `X5400` | **NO** |
| Confronto diretto `AMDSupport` | **NO** |
| Filtro per nome nel codice | **NO osservato** |
| Esclusione delle due entry | **UNPROVEN** |

**PROVEN:** la selezione è generica e basata sulla exclude list.
**REFUTED:** un confronto testuale diretto con i due nomi.
**UNPROVEN:** l’esito della exclude list sulle due entry.

---

## 4. Presenza nel SystemKC

| Stringa | Rilievo |
|---|---|
| `com.apple.kext.AMDSupport` | **presente** |
| `AMDSupport` | **presente** |
| `AMDRadeonX5400HWLibs` | **presente** |
| `com.apple.kext.AMDRadeonX5400HWLibs` | **presente** |

| Provider | Entry vmaddr | `cacheLevel` |
|---|---:|---:|
| X5400 | `0x8A90000` | **1** |
| AMDSupport | `0x13B2C000` | **1** |

**PROVEN:** i nomi sono nel SystemKC.
**PROVEN:** gli indirizzi e `cacheLevel` provengono dai report precedenti.
**UNPROVEN:** l’associazione runtime tra indirizzo e oggetto selezionato.

---

## 5. Associazione entry → oggetto

| Passo | Evidenza |
|---|---|
| #2 riceve `mach_header` e `kc_kind` | **SÌ** |
| #2 costruisce exclude list | **SÌ** |
| #2 chiama init per le entry | **SÌ** |
| Init riceve l’entry corretta | **UNPROVEN** |
| Init chiama `loadExecutable` | **SÌ, slot 53** |
| Loader usa `basePointers[1]` | **SÌ** |

**PROVEN:** il percorso generico arriva al loader.
**UNPROVEN:** che l’entry X5400/AMDSupport sia quella passata.
**UNPROVEN:** che la exclude list non le rimuova.

---

## 6. Ordine statico

```text
mapKCFileSet
  -> PE_set_kc_header(type=2)        0xa3302f
  -> addKextsFromKextCollection#1    0xa33619
     -> #2                           0xa33e29
        -> init                       0xa25090
           -> loadExecutable          0xa25bc6
```

**PROVEN:** il setter precede l’iteratore.
**PROVEN:** l’iteratore può chiamare init.
**UNPROVEN:** che la sequenza venga eseguita a runtime.

---

## 7. Evidenze runtime

| Evidenza | Esito |
|---|---|
| Boot log | **assente** |
| Trace `mapKCFileSet` | **assente** |
| Trace `addKexts` | **assente** |
| Trace `init` | **assente** |
| Trace `loadExecutable` | **assente** |
| `ioreg`/DeviceTree | **assente** |

**PROVEN:** non ci sono log o trace preesistenti.
**UNPROVEN:** la selezione e il caricamento runtime.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| #2 itera le entry | **SÌ** |
| Usa una exclude list | **SÌ** |
| Confronta `X5400`/`AMDSupport` | **NO** |
| Chiama init | **SÌ, slot 38** |
| Init chiama loadExecutable | **SÌ, slot 53** |
| Entry X5400/AMDSupport selezionate | **UNPROVEN** |
| Base `[1]` pronta prima | **SÌ, staticamente** |
| Caricamento runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `addKextsFromKextCollection#2` non seleziona X5400/AMDSupport per nome. Costruisce una exclude list da `PRELINK_INFO` e itera le entry in modo generico, chiamando `initWithPrelinkedInfoDict` (slot 38) che a sua volta chiama `loadExecutable` (slot 53). Le due stringhe sono presenti nel SystemKC e gli indirizzi provengono dai report precedenti, ma resta **UNPROVEN** che le due entry specifiche superino la exclude list e vengano caricate. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
