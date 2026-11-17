# T27 — AGENT-AMD — HWLIBS LINK

> **RETTIFICA (Prompt 128):** il link statico a X6000HWLibs è **PROVEN** nei metadati: personality `AMDRadeonHWLibs`, `IOClass=AMDRadeonX6000_AMDRadeonHWLibsX6000`, `IOProviderClass=AMDRadeonX6000_AMDRadeonHWServicesInterface`, `LoadPlugIn=Load6000`. Resta **UNPROVEN** il runtime. X6000HWServices è a `0xC26C000` (size `0x23CB`), X6000HWLibs a `0xC273000` (size `0x54A86C`).

**Scope:** verificare il collegamento statico tra X6000 Interface e X6000HWLibs, classificare le 27 occorrenze del nome, ricostruire Interface/SWI/Abstract, distinguere registrazione OSMetaClass, matching e pubblicazione IOService, confrontare X5000.

**Modalità:** sola lettura; X5000HWServices, X6000HWServices, SystemKC, BootKC; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che il finder `0xC26DC80` seleziona un plugin con `IOMatchCategory == "AMDRadeonHWLibs"` e che l’helper usa `callPlatformFunction("AmdTtlInterfaceKey")`. **REFUTED** una referenza diretta a `X6000HWLibs` nel codice. **REFUTED** che Navi chiami `registerService`. Pubblicazione e matching X6000HWLibs restano **UNPROVEN**. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| X6000HWServices | `2aa47ceee99969d3eba360fe558a3fbcd7e69c4bea2cd76704350a9bdfafe453` |
| X5000HWServices | `8a88fe7276968d3b124c9ff7ccf26d18b5e918fc339ab3681dfcb5a2cbd3cfbf` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 125 | `73be5f531561fbf368a9ba9bf643db55bb6e70ab6f4a7cef447e1cc40c01e4a7` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Le 27 occorrenze

| Gruppo | N. | Offset | Tipo |
|---|---:|---|---|
| `__TEXT` XML | 7 | `0x60766`, `0x6143E`, `0x62116`, `0x62DEE`, `0x63AC6`, `0x6479E`, `0x65476` | stringa plist |
| X6 `__DATA` | 2 | `0xC26E200`, `0xC26E231` | stringa |
| `__REGION19` | 18 | `0x15A6DD56`, `0x15DA8421`, `0x15DA8460`, `0x15DA849F`, `0x15DA84DF`, `0x15DA851F`, `0x15DA855F`, `0x15DA859F`, `0x15DA85DC`, `0x15DA8620`, `0x15DA8656`, `0x15DA868C`, `0x15DA86C2`, `0x15DA86FA`, `0x15E134AD`, `0x15E134F0`, `0x15E26EC8`, `0x15E3BB19` | simboli `__Z...` |

**PROVEN:** 7 + 2 + 18 = 27.
**PROVEN:** nessuna occorrenza è codice eseguibile.
**UNPROVEN:** il mapping runtime dei 18 simboli.

---

## 3. Stringhe HWLibs

| Stringa | Occorrenze | Offset |
|---|---:|---|
| `X6000HWLibs` | 9 | `0x9750`, `0x600CE`, `0x60127`, `0x601AF`, `0x60583`, `0x606AF`, `0x60B4A`, `0x60BFD`, `0xC7D09E8` |
| `AMDRadeonX6000HWLibs` | 9 | `0x9747`, `0x600C5`, `0x6011E`, `0x601A6`, `0x6057A`, `0x606A6`, `0x60B41`, `0x60BF4`, `0xC7D09DF` |
| `AMDRadeonHWLibs` | 1 | `0xC26E3B0` |
| `AmdTtlInterfaceKey` | 14 | `0x457D21C`, `0x482F44F`, `0x6ADB43E`, `0x75DDFF0`, `0x8D2CE93`, `0xA67DBAC`, `0xC26E1ED`, `0xC4B7689`, `0xDFAF6F8`, `0xEF52580`, `0x10338244`, `0x11167558`, `0x12622E16`, `0x1324C034` |

**PROVEN:** `X6000HWLibs` compare 9 volte.
**PROVEN:** `AmdTtlInterfaceKey` compare 14 volte.
**UNPROVEN:** il significato di `0xC7D09E8` (mapping ambiguo).

---

## 4. Finder plugin `0xC26DC80`

```text
0xC26DC80  pushq %rbp
0xC26DC81  movq %rsp, %rbp
0xC26DC84  subq $0x40, %rsp
0xC26DC88  movq %rdi, -0x10(%rbp)
0xC26DC8C  movq -0x10(%rbp), %rdi
0xC26DC90  movq $0x0, -0x18(%rbp)
0xC26DC98  movq (%rdi), %rax
0xC26DC9B  callq *0x6A8(%rax)
0xC26DCA1  movq %rax, -0x20(%rbp)
...
0xC26DCD2  movq -0x20(%rbp), %rdi
0xC26DCD6  movq (%rdi), %rax
0xC26DCD9  callq *0x128(%rax)
0xC26DCDF  movq %rax, %rcx
...
0xC26DD15  leaq 0x66C(%rip), %rsi
0xC26DD1C  callq *0x2B8(%rax)
0xC26DD25  movq 0x12E4(%rip), %rax
0xC26DD2F  callq 0x1007E
...
0xC26DD49  leaq 0x660(%rip), %rsi
0xC26DD50  callq *0x158(%rax)
0xC26DD58  jne 0xC26DD5C
...
0xC26DD5C  movq -0x30(%rbp), %rax
0xC26DD60  movq %rax, -0x18(%rbp)
```

| Stringa | Indirizzo |
|---|---:|
| `IOMatchCategory` | `0xC26E388` |
| `AMDRadeonHWLibs` | `0xC26E3B0` |

**PROVEN:** il finder legge `IOMatchCategory`.
**PROVEN:** confronta con `AMDRadeonHWLibs`.
**PROVEN:** restituisce il plugin trovato.
**UNPROVEN:** il provider concreto.

---

## 5. SWI::start

```text
0xC26CFF0  pushq %rbp
0xC26CFF1  movq %rsp, %rbp
0xC26CFF4  subq $0x20, %rsp
0xC26CFF8  movq %rdi, -0x8(%rbp)
0xC26CFFC  movq %rsi, -0x10(%rbp)
0xC26D000  movq -0x8(%rbp), %rdi
0xC26D004  movq %rdi, -0x20(%rbp)
0xC26D008  leaq 0x3CE1(%rip), %rax
0xC26D00F  movq 0x5D0(%rax), %rax
0xC26D016  movq -0x10(%rbp), %rsi
0xC26D01A  callq *%rax
...
0xC26D027  movq -0x20(%rbp), %rdi
0xC26D02B  movq 0x88(%rdi), %rsi
0xC26D032  callq 0xC26D060
0xC26D037  movq -0x20(%rbp), %rcx
0xC26D03B  movq %rax, 0xD0(%rcx)
```

| Test | Esito |
|---|---|
| Vtable caricata | `0xC270CF0` |
| Slot `0x5D0` | `0xC26D8C0` = `Abstract::start` |
| Poi helper | `0xC26D060` |
| Interface | `this+0xD0` |
| `registerService` | **NO** |

**PROVEN:** `SWI::start` chiama `Abstract::start`.
**PROVEN:** poi chiama l’helper e salva l’interfaccia a `+0xD0`.
**PROVEN:** nessuna chiamata diretta a `registerService`.

---

## 6. Abstract::start

```text
0xC26D8C0  pushq %rbp
0xC26D8C8  movq %rdi, -0x8(%rbp)
0xC26D8CC  movq %rsi, -0x10(%rbp)
0xC26D8E3  movq $0x0, 0x88(%rax)
0xC26D8EE  movq -0x28(%rbp), %rdi
0xC26D8F2  movq 0x304F(%rip), %rax
0xC26D8FD  callq *%rax
...
0xC26D9B3  callq *0x868(%rax)
...
0xC26DA01  movq -0x28(%rbp), %rdi
0xC26DA05  movq (%rdi), %rax
0xC26DA08  movl $0x2, %esi
0xC26DA0D  callq *0x5B0(%rax)
...
0xC26DA1D  movq -0x28(%rbp), %rdi
0xC26DA21  callq 0xC26DC80
0xC26DA2D  movq %rcx, 0xA8(%rax)
...
0xC26DA5F  leaq 0x8E9(%rip), %rdi
```

| Test | Esito |
|---|---|
| `IOService::start` | `0xA94E70` |
| Slot `0x5B0` Navi | `0xBB8F70` = `_RESERVEDIOService47` |
| Slot `0x5C0` Navi | `0xA94C60` = `registerService` |
| Finder | `0xC26DC80` |
| Plugin | `this+0xA8` |
| Errore | `"Could not find HW Lib Plug In."` |

**PROVEN:** `Abstract::start` chiama `IOService::start`.
**PROVEN:** lo slot `0x5B0` Navi è `_RESERVEDIOService47`, non `registerService`.
**PROVEN:** il plugin viene cercato e salvato a `+0xA8`.
**PROVEN:** `registerService` è allo slot `0x5C0` e non viene chiamato.

---

## 7. Helper `0xC26D060`

```text
0xC26D060  pushq %rbp
0xC26D068  movq %rdi, -0x10(%rbp)
0xC26D06C  movq %rsi, -0x18(%rbp)
0xC26D07C  movq 0xA8(%rax), %rax
0xC26D08F  movq -0x28(%rbp), %rdi
0xC26D097  movq (%rdi), %rax
0xC26D09A  leaq 0x114C(%rip), %rsi
0xC26D0A1  xorl %edx, %edx
0xC26D0A3  leaq -0x20(%rbp), %r8
0xC26D0A7  xorl %r9d, %r9d
0xC26D0B2  callq *0x6C0(%rax)
```

| Argomento | Valore |
|---|---|
| plugin | `this+0xA8` |
| chiave | `"AmdTtlInterfaceKey"` |
| indice | `0` |
| output | `-0x20(%rbp)` |
| call | `*0x6C0` |
| risultato | `this+0xD0` |

**PROVEN:** l’helper chiama `callPlatformFunction` sul plugin.
**PROVEN:** la chiave è `AmdTtlInterfaceKey`.
**PROVEN:** il risultato è l’interfaccia.

---

## 8. Vtable

| Slot | Navi `0xC26F078` | Interface `0xC270388` |
|---:|---:|---:|
| `0x5B0` | `0xBB8F70` reserved47 | `0xA94C60` registerService |
| `0x5B8` | `0xA94C50` | `0xA94E60` probe |
| `0x5C0` | `0xA94C60` registerService | `0xA94E70` start |
| `0x5C8` | `0xC26D650` | `0xA94E80` |
| `0x5D0` | `0xC26CFF0` SWI::start | `0xA94EB0` open |
| `0x5D8` | `0xC26D120` | `0xA94FD0` |

**PROVEN:** gli slot sono specifici della classe.
**REFUTED:** `0x5B0 = registerService` come regola universale.
**PROVEN:** Navi non chiama `registerService`.

---

## 9. X5000

| Elemento | X5000 | X6000 |
|---|---:|---:|
| constructor | `0x457C310` | `0xC26D260` |
| MetaClassC2 | `0x457C3B0` | `0xC26D300` |
| nome | `0x457D22F` | `0xC26E200` |
| superclasse | `0x400000012AA488` | `0x400000012AA488` |
| size | `0x88` | `0x88` |
| stub | `0x10066` | `0x10066` |

**PROVEN:** la registrazione OSMetaClass è identica.
**UNPROVEN:** la catena start X5000 completa.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| Interface esiste | **SÌ** |
| OSMetaClass | **PROVEN** |
| Link HWLibs | **PROVEN generico** |
| Match category | `AMDRadeonHWLibs` |
| Chiave | `AmdTtlInterfaceKey` |
| Referenza diretta `X6000HWLibs` | **NO** |
| `registerService` Navi | **NO** |
| Pubblicazione | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il collegamento statico è **generico**: `Abstract::start` cerca un plugin con `IOMatchCategory == "AMDRadeonHWLibs"` e lo salva a `this+0xA8`; `SWI::start` usa quel plugin con `callPlatformFunction("AmdTtlInterfaceKey")` e salva l’interfaccia a `this+0xD0`. Non esiste una referenza diretta a `X6000HWLibs` nel codice: le 9 occorrenze sono stringhe XML/plist o dati a mapping ambiguo. La registrazione OSMetaClass è **PROVEN** (report 125), ma la pubblicazione IOService no: nella vtable Navi `registerService` è allo slot `0x5C0`, non `0x5B0`; `Abstract::start` chiama `0x5B0`, che è `_RESERVEDIOService47`. La vecchia regola “`0x5B0 = registerService`” vale solo per Interface. Pubblicazione, matching X6000HWLibs e catena start X5000 restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,2 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
