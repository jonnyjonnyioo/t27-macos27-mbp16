# T27 — AGENT-AMD — INDIRECT DISPATCH

**Scope:** verificare le chiamate indirette responsabili della pubblicazione del servizio Navi e cercare riferimenti a X6000 Interface (`0xC26D210`, `0xC271828`, `0x12AA488`); esaminare vtable, thunk e dispatch verso `registerService`.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, symbol table, disassemblaggio completo di `__text`; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che in tutto `__text` di X6000HWServices c’è un solo riferimento diretto a Interface (`0xC26D1FB`, catena del costruttore), nessun riferimento in codice a `0xC271828` o `0x12AA488` e nessuna chiamata diretta a `registerService`. **UNPROVEN** il dispatch indiretto e la pubblicazione del servizio. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 102 | `c3261a23086ba05b8063fd4a4f861d848f2c3b4f292025d69fc75c07d8f22f7e` |
| Report 103 | `592fc8084005a78bfa5c6e32d66efae9e3eee4e5ba9c5fc1ee97208bd9f66e88` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Riferimenti diretti

| Indirizzo | Istruzione | Contesto |
|---|---|---|
| `0xC26D1FB` | `callq 0xC26D210` | costruttore Interface |
| `0xC26D210` | `pushq %rbp` | MetaClassC1 Interface |

| Ricerca | Esito |
|---|---|
| `0xC26D210` in codice | **1, solo 0xC26D1FB** |
| `0xC271828` in codice | **nessuno** |
| `0x12AA488` in codice | **nessuno** |
| `registerService` diretto | **nessuno** |
| `setProperty` diretto | **nessuno** |

**PROVEN:** Interface è referenziata solo dalla catena del costruttore.
**PROVEN:** non ci sono riferimenti in codice agli slot Interface.
**UNPROVEN:** il dispatch indiretto.

---

## 3. Vtable e dispatch

| Funzione | Call indirette |
|---|---|
| `SWI::start` | `*%rax`, `*0x6C0(%rax)` |
| `Abstract::start` | `*0x868(%rax)`, `*0x270(%rax)`, `*0x5B0(%rax)`, `*0x20(%rax)` |
| `0xC26D060` | `*0x6C0(%rax)`, `*%rax` |
| `0xC26DB90` | `*0x2B8(%rax)`, `*0x20(%rax)`, `*0x178(%rax)`, `*0x6A8(%rax)` |
| `0xC26DC80` | `*0x6A8(%rax)`, `*0x128(%rax)`, `*0x2B8(%rax)`, `*0x158(%rax)`, `*0x28(%rax)` |

| Slot | Metodo | Esito |
|---:|---|---|
| `0x6C0` | sconosciuto | **UNPROVEN** |
| `0x868` | sconosciuto | **UNPROVEN** |
| `0x270` | sconosciuto | **UNPROVEN** |
| `0x5B0` | sconosciuto | **UNPROVEN** |
| `0x20` | sconosciuto | **UNPROVEN** |
| `0x2B8` | sconosciuto | **UNPROVEN** |
| `0x178` | sconosciuto | **UNPROVEN** |
| `0x6A8` | sconosciuto | **UNPROVEN** |

**PROVEN:** esistono dispatch indiretti.
**UNPROVEN:** che uno di essi sia `registerService`.

---

## 4. Import e stub

| Simbolo | Importato | Indirizzo |
|---|---|---|
| `IOService::registerService` | **SÌ** | **non risolto** |
| `IOService::probe` | **SÌ** | **non risolto** |
| `IOService::start` | **SÌ** | **non risolto** |
| `IOService::newUserClient` | **SÌ** | **non risolto** |
| `OSMetaClass` | **SÌ** | **non risolto** |

**PROVEN:** gli import esistono.
**UNPROVEN:** la mappa stub → simbolo.

---

## 5. Catena costruttore Interface

```text
0xC26D1D0: ...
0xC26D1FB: callq 0xC26D210   ; MetaClassC1 Interface
0xC26D210: pushq %rbp
0xC26D220: callq 0xC26D300
```

**PROVEN:** la chiamata è nella catena del costruttore.
**PROVEN:** non è una chiamata di registrazione del servizio.
**UNPROVEN:** il ruolo della catena.

---

## 6. Pubblicazione

| Elemento | Esito |
|---|---|
| `registerService` diretto | **NO** |
| `registerService` indiretto | **possibile** |
| `setProperty` | **NO** |
| `Load6000` in HWServices | **NO** |
| Pubblicazione servizio | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |

**PROVEN:** non c’è pubblicazione diretta visibile.
**UNPROVEN:** la pubblicazione indiretta.

---

## 7. Classificazione

| Affermazione | Esito |
|---|---|
| Interface referenziata in codice | **SÌ, solo costruttore** |
| `0xC271828` in codice | **NO** |
| `0x12AA488` in codice | **NO** |
| `registerService` diretto | **NO** |
| `registerService` indiretto | **UNPROVEN** |
| Servizio Navi pubblicato | **UNPROVEN** |
| Matching X6000HWLibs | **UNPROVEN** |

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Riferimento diretto Interface | **1, `0xC26D1FB`** |
| Riferimento a `0xC271828` | **NO** |
| Riferimento a `0x12AA488` | **NO** |
| `registerService` diretto | **NO** |
| `registerService` indiretto | **UNPROVEN** |
| Servizio pubblicato | **UNPROVEN** |
| Matching HWLibs | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** in tutto `__text` di X6000HWServices c’è un solo riferimento diretto a Interface, `0xC26D1FB`, nella catena del costruttore; non ci sono riferimenti in codice a `0xC271828` o `0x12AA488` e non c’è una chiamata diretta a `registerService`. Esistono dispatch indiretti (`0x6C0`, `0x868`, `0x270`, `0x5B0`, `0x20`, `0x2B8`, `0x178`, `0x6A8`) ma nessuno è risolto a `registerService`; la pubblicazione del servizio e il matching X6000HWLibs → Navi restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
