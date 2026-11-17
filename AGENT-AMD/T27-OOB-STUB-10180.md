# T27 — AGENT-AMD — STUB 10180

> **RETTIFICA (Prompt 120):** `0x10180` è uno stub in `__BRANCH_STUBS` (`jmp *0x1407A(%rip)`) verso la GOT `0x24200`, non una funzione. La GOT porta a `0x9A48F0`, che non è codice x86_64. Vale il report 120.

**Scope:** identificare lo stub condiviso `0x10180`, ricostruire l’inizializzazione della superclass `0x12AA488` per X5000/X6000 Interface e verificare se produce registrazioni IOKit.

**Modalità:** sola lettura; fileset X5000/X6000, SystemKC/BootKC, costruttori, disassemblaggio; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che entrambi i costruttori chiamano `0x10180` prima di impostare il vptr e che non chiamano `registerService`. **UNPROVEN** l’identità dello stub e della superclass. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 117 | `04d67a09aad5a019651bebe6d0ad61350460c60f80eabb239d6baf3fa099919a` |
| Report 116 | `222759aa3b733e23bae7e543025519eab04dfa32b6ca1da97ee882f93cd8406b` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Stub `0x10180`

| Test | Esito |
|---|---|
| Indirizzo | `0x10180` |
| Nel range X5000 | **NO** |
| Nel range X6000 | **NO** |
| Simbolo | **nessuno** |
| Segmento | **UNPROVEN** |
| Chiamanti | **2 costruttori Interface** |

**PROVEN:** è fuori dal range estratto.
**PROVEN:** è condiviso.
**UNPROVEN:** il proprietario.

---

## 3. Costruttore X5000

```text
0x457C310: pushq %rbp
0x457C32C: callq 0x10180
0x457C335: leaq 0x3034(%rip), %rcx   ; 0x457F370
0x457C33C: addq $0x10, %rcx
0x457C340: movq %rcx, (%rax)
0x457C348: retq
```

**PROVEN:** chiama lo stub.
**PROVEN:** imposta il vptr.
**PROVEN:** non registra.

---

## 4. Costruttore X6000

```text
0xC26D260: pushq %rbp
0xC26D27C: callq 0x10180
0xC26D285: leaq 0x30EC(%rip), %rcx   ; 0xC270378
0xC26D28C: addq $0x10, %rcx
0xC26D290: movq %rcx, (%rax)
0xC26D298: retq
```

**PROVEN:** chiama lo stub.
**PROVEN:** imposta il vptr.
**PROVEN:** non registra.

---

## 5. Ordine di inizializzazione

| Fase | X5000 | X6000 |
|---:|---|---|
| 1 | `call 0x10180` | `call 0x10180` |
| 2 | `vptr = 0x457F380` | `vptr = 0xC270388` |
| 3 | `ret` | `ret` |
| `registerService` | **NO** | **NO** |

**PROVEN:** superclass prima, vptr dopo.
**PROVEN:** nessuna pubblicazione.

---

## 6. Implementazioni condivise

| Ricerca | Esito |
|---|---|
| Stub in X5000 | **chiamato** |
| Stub in X6000 | **chiamato** |
| Stub in X4000 | **UNPROVEN** |
| Superclass `0x12AA488` | **UNPROVEN** |
| Implementazione esterna | **UNPROVEN** |

**PROVEN:** lo stub è comune.
**UNPROVEN:** la sua implementazione.

---

## 7. Registrazione IOKit

| Percorso | Esito |
|---|---|
| `registerService` in ctor | **NO** |
| `registerService` nello stub | **UNPROVEN** |
| Pubblicazione nel ctor | **NO** |
| Pubblicazione nello stub | **UNPROVEN** |
| Pubblicazione differita | **UNPROVEN** |

**PROVEN:** il costruttore non pubblica.
**UNPROVEN:** lo stub.

---

## 8. X6000HWLibs

| Requisito | Valore |
|---|---|
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `LoadPlugIn=Load6000` |
| Interface completa | **SÌ** |
| Interface pubblicata | **UNPROVEN** |
| Matching | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Stub `0x10180` risolto | **NO** |
| Condiviso | **SÌ** |
| Superclass inizializzata | **SÌ, strutturale** |
| Identità superclass | **UNPROVEN** |
| Registrazione nel ctor | **NO** |
| Registrazione nello stub | **UNPROVEN** |
| Pubblicazione Interface | **UNPROVEN** |
| Matching | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** entrambi i costruttori Interface chiamano lo stesso stub `0x10180` e solo dopo impostano il proprio vptr (`0x457F380`, `0xC270388`). Lo stub è fuori dal range estratto e non ha simbolo, quindi la sua identità e quella della superclass `0x12AA488` restano **UNPROVEN**. I costruttori non chiamano `registerService`; una pubblicazione nello stub o in un percorso differito resta **UNPROVEN**, così come il matching X6000HWLibs. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
