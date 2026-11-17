# T27 — AGENT-AMD — INTERFACE REGISTRATION

**Scope:** verificare indipendentemente esistenza e registrazione di X6000 Interface con gli indirizzi già verificati, disassemblare costruttore e metaclass, cercare xref e chiamate a `OSMetaClass`/`registerService`, confrontare X5000.

**Modalità:** sola lettura; X5000HWServices, X6000HWServices, SystemKC; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che X6000 Interface ha una catena statica di registrazione `ctor → MetaClassC1 → MetaClassC2 → stub 0x10066` con nome, superclasse e size. **PROVEN** lo stesso schema in X5000. **REFUTED** una chiamata a `registerService` nella catena. Pubblicazione IOService e identità superclass restano **UNPROVEN**. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| X6000HWServices | `2aa47ceee99969d3eba360fe558a3fbcd7e69c4bea2cd76704350a9bdfafe453` |
| X5000HWServices | `8a88fe7276968d3b124c9ff7ccf26d18b5e918fc339ab3681dfcb5a2cbd3cfbf` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| Report 124 | `292c064979e6186c2666341745778a9fa77dbff9c5439f3b7f9f236e3df170f0` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. X6000 Interface

| Elemento | Indirizzo |
|---|---:|
| vtable | `0xC270378` |
| constructor | `0xC26D260` |
| MetaClassC1 | `0xC26D210` |
| MetaClassC2 | `0xC26D300` |
| metaClass symbol | `0xC270368` |
| superClass symbol | `0xC270370` |
| getMetaClass | `0xC26D2E0` |
| alloc | `0xC26D350` |

**PROVEN:** gli indirizzi sono coerenti con i report precedenti.

---

## 3. Constructor

```text
0xC26D260  pushq %rbp
0xC26D261  movq %rsp, %rbp
0xC26D264  subq $0x20, %rsp
0xC26D268  movq %rdi, -0x8(%rbp)
0xC26D26C  movq %rsi, -0x10(%rbp)
0xC26D270  movq -0x8(%rbp), %rdi
0xC26D274  movq %rdi, -0x18(%rbp)
0xC26D278  movq -0x10(%rbp), %rsi
0xC26D27C  callq 0x10180
0xC26D281  movq -0x18(%rbp), %rax
0xC26D285  leaq 0x30EC(%rip), %rcx
0xC26D28C  addq $0x10, %rcx
0xC26D290  movq %rcx, (%rax)
0xC26D293  addq $0x20, %rsp
0xC26D297  popq %rbp
0xC26D298  retq
```

| Test | Esito |
|---|---|
| Chiamata base | `0x10180` |
| Vptr | `0xC270378` |
| `registerService` | **NO** |
| Publish | **NO** |

**PROVEN:** il costruttore chiama solo lo stub base e imposta il vptr.
**PROVEN:** nessuna pubblicazione nel costruttore.

---

## 4. MetaClassC1

```text
0xC26D210  pushq %rbp
0xC26D211  movq %rsp, %rbp
0xC26D214  subq $0x10, %rsp
0xC26D218  movq %rdi, -0x8(%rbp)
0xC26D21C  movq -0x8(%rbp), %rdi
0xC26D220  callq 0xC26D300
0xC26D225  addq $0x10, %rsp
0xC26D229  popq %rbp
0xC26D22A  retq
```

**PROVEN:** MetaClassC1 inoltra a MetaClassC2.
**PROVEN:** nessun `registerService`.

---

## 5. MetaClassC2

```text
0xC26D300  pushq %rbp
0xC26D301  movq %rsp, %rbp
0xC26D304  subq $0x10, %rsp
0xC26D308  movq %rdi, -0x8(%rbp)
0xC26D30C  movq -0x8(%rbp), %rdi
0xC26D310  movq %rdi, -0x10(%rbp)
0xC26D314  leaq 0xEE5(%rip), %rsi
0xC26D31B  movq 0x1CF6(%rip), %rdx
0xC26D322  movl $0x88, %ecx
0xC26D327  callq 0x10066
0xC26D32C  movq -0x10(%rbp), %rax
0xC26D330  leaq 0x38C1(%rip), %rcx
0xC26D337  addq $0x10, %rcx
0xC26D33B  movq %rcx, (%rax)
0xC26D33E  addq $0x10, %rsp
0xC26D342  popq %rbp
0xC26D343  retq
```

| Argomento | Valore |
|---|---|
| `rsi` nome | `0xC26E200` = `"AMDRadeonX6000_AMDRadeonHWServicesInterface"` |
| `rdx` superclasse | `0xC26F018` = `0x400000012AA488` |
| `ecx` size | `0x88` |
| call | `0x10066` |

**PROVEN:** nome e size sono corretti.
**PROVEN:** il target superclasse è `0x12AA488` con livello `0`.
**UNPROVEN:** il significato esatto del campo `0xC26F018`.

---

## 6. Stub 0x10066

```text
0x10066  FF 25 1C 40 01 00   jmp *0x1401C(%rip)
GOT      0x24088
raw      0x4000000091C3E0
target   0x91C3E0
```

| Test | Esito |
|---|---|
| Target | `0x91C3E0` |
| Simbolo `nm` | **assente** |
| `U OSMetaClassC2EPKcPKS_j` | **presente** |
| Pattern argomenti | **OSMetaClass ctor** |
| Simbolo esatto | **UNPROVEN** |

**PROVEN:** lo stub porta a `0x91C3E0`.
**PROVEN:** la firma chiamata è `(char const*, OSMetaClass const*, unsigned int)`.
**UNPROVEN:** il nome simbolico esatto.

---

## 7. Xref

| Riferimento | Indirizzo | Tipo |
|---|---:|---|
| ctor | `0xC26D45C` | call |
| MetaClassC1 | `0xC26D1FB` | call |
| MetaClassC2 | `0xC26D220` | call |
| vtable raw | **0** | relocated |
| metaClass raw | **0** | relocated |

**PROVEN:** il ctor è chiamato una volta.
**PROVEN:** la catena metaclass è chiamata.
**PROVEN:** vtable/metaClass non hanno xref assolute.
**UNPROVEN:** gli xref runtime.

---

## 8. Nome classe

| Immagine | Occorrenze |
|---|---:|
| SystemKC | **27** |
| BootKC | **0** |

**PROVEN:** il nome è presente in SystemKC.
**PROVEN:** il nome è assente in BootKC.
**UNPROVEN:** la tabella di registrazione runtime.

---

## 9. Confronto X5000

| Elemento | X5000 | X6000 |
|---|---:|---:|
| constructor | `0x457C310` | `0xC26D260` |
| MetaClassC1 | `0x457C2C0` | `0xC26D210` |
| MetaClassC2 | `0x457C3B0` | `0xC26D300` |
| nome | `0x457D22F` | `0xC26E200` |
| superclasse source | `0x457E018` | `0xC26F018` |
| superclasse raw | `0x400000012AA488` | `0x400000012AA488` |
| size | `0x88` | `0x88` |
| stub | `0x10066` | `0x10066` |
| metaClass | `0x457F360` | `0xC270368` |
| superClass symbol | `0x457F368` | `0xC270370` |

**PROVEN:** lo schema è identico.
**PROVEN:** la superclasse è la stessa.
**UNPROVEN:** l’identità della superclasse.

---

## 10. registerService

| Test | Esito |
|---|---|
| ctor | **NO** |
| MetaClassC1 | **NO** |
| MetaClassC2 | **NO** |
| slot `0x5B0` | **NO** |
| simbolo `registerService` | **NO** |
| publish | **NO** |

**PROVEN:** la catena non pubblica il servizio.
**PROVEN:** la registrazione è solo OSMetaClass.
**UNPROVEN:** la pubblicazione IOService.

---

## 11. Conclusione

| Domanda | Risposta |
|---|---|
| Classe esistente | **SÌ** |
| Nome registrato | **PROVEN** |
| OSMetaClass | **PROVEN** |
| `registerService` | **NO** |
| Pubblicazione | **UNPROVEN** |
| Superclasse | `0x12AA488` |
| Identità superclasse | **UNPROVEN** |
| Matching | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** X6000 Interface esiste e ha una catena statica completa `0xC26D260 → 0xC26D210 → 0xC26D300 → 0x10066 → 0x91C3E0`, con nome `"AMDRadeonX6000_AMDRadeonHWServicesInterface"`, superclasse `0x12AA488` e size `0x88`. Lo stesso schema è presente in X5000. La chiamata allo stub `0x10066` ha la firma di `OSMetaClass::OSMetaClass`, quindi la registrazione della classe è **PROVEN** a livello statico; il simbolo esatto a `0x91C3E0` resta **UNPROVEN**. Non c’è alcuna chiamata a `registerService` né allo slot `0x5B0`: la pubblicazione IOService resta **UNPROVEN**, così come l’identità della superclasse e il matching X6000HWLibs. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,2 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
