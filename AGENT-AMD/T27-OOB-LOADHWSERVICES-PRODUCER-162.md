# T27 — AGENT-AMD — PRODUTTORE LOADHWSERVICES (162)

**Scope:** identificare chi deve pubblicare `LoadHWServices=true` sul dispositivo PCI AMD; estendere la ricerca a tutti i kext AMD, SystemKC, BootKC e plist; cercare `LoadHWServices`, `setProperty`, `OSBooleanTrue` e proprietà equivalenti; analizzare xref e chiamate da AMDSupport, AMDFramebuffer, HWServices e superclassi; verificare pubblicazioni indirette; indicare il produttore più probabile e la prova statica necessaria.

**Modalità:** sola lettura. Nessun boot, trace, modifica, build o download. Comandi: `grep`, `find`, `plutil`, `strings`, `nm`, `otool`, `shasum`.

**Esito:** **PROVEN** che il produttore esiste ed è `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute` in `AMDRadeonX6000Framebuffer`, funzione `0xbf9894e`, con xref diretto alla stringa `"LoadHWServices"` e chiamata `setProperty` con valore `true` sul provider. La personality `AMDGPUWrangler` matcha `0x73401002` con score `60000`. **PROVEN** anche l'equivalente `AtiGpuWrangler::vendor_doDeviceAttribute` in AMDSupport. **UNPROVEN** che il caller invochi il ramo con il bit di attributo `0x2` attivo sul target. Il 161 aveva cercato il produttore in HWServices/SystemKC e non aveva disassemblato i Wrangler: la conclusione “nessun produttore dimostrato” è **superata**. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| X6000Framebuffer `Info.plist` | `1b28b9aab877c4b3362edabde5a512d45d0cf97c10611b034c8ea53995a9f573` |
| X6000Framebuffer executable | `a2469429602210e64a74292a30b06353d9e0f75cd6b8b65f98324e64fa0b4536` |
| AMDSupport `Info.plist` | `e9fa60b1333f055a4308dcdaa45d6aef078f3e7ea7eee547a1f4a2b9f1e9ba72` |
| AMDSupport executable | `c569698b689d3822ce3f18a51202b10f46f48e395e80a339dc3bae403754f2a4` |
| HWServices `Info.plist` | `c6dcc67430bbbff1490e7101d395b3dbcfe248c10adc889efd59dd1689810bf0` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 161 | `fb9d0ffdb2b7b4c5d754129512f14bac1b717b799efba538bcf9b86fdb53a0a8` |

**Ambiente:** macOS `26.7.3`, build `25G342`.
**Spazio:** **15.417.680 KiB ≈ 14,70 GiB** > 10 GiB.

---

## 2. Correzione del 161

| Affermazione 161 | Esito 162 |
|---|---|
| HWServices non pubblica `LoadHWServices` | **PROVEN, resta vero** |
| Non esiste un produttore dimostrato | **REFUTED** |
| Produttore da cercare in AMDSupport/Framebuffer | **CONFERMATO** |
| Primo punto non dimostrato = proprietà PCI | **PROVEN che il codice la scrive; UNPROVEN il ramo flags** |
| X6100 bloccato da HWServices | **INFERRED, non PROVEN** |

**PROVEN:** il 161 aveva un perimetro troppo stretto: cercava la stringa in HWServices e nei plist, non nel codice di `vendor_doDeviceAttribute` dei Wrangler.
**PROVEN:** ora esistono due xref diretti alla stringa.
**UNPROVEN:** l'esecuzione del ramo sul target.

---

## 3. Produttore primario: X6000Framebuffer

### 3.1 Personality target

`AMDRadeonX6000Framebuffer.kext/Contents/Info.plist`, personalità `AMDGPUWrangler`:

| Campo | Valore |
|---|---|
| `IOClass` | `AMDRadeonX6000_AmdGpuWrangler` |
| `IOProviderClass` | `IOPCIDevice` |
| `IOPCIMatch` | include `0x73401002` (Navi 14 target) |
| `IOProbeScore` | `60000` |
| `IOMatchCategory` | `IOFramebuffer` |
| `IOPCITunnelCompatible` | `true` |
| `OSBundleRequired` | `Safe Boot` (a livello bundle) |

**PROVEN:** la personality copre il device ID target.
**PROVEN:** la classe è `AMDRadeonX6000_AmdGpuWrangler`.
**PROVEN:** la classe è presente in SystemKC (`MetaClassC1 0xbf983e2`, ctor `0xbf9841e`, `start 0xbf987c2`, `vendor_doDeviceAttribute 0xbf9894e`).

### 3.2 Xref diretto

`AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute` a `0xbf9894e`:

| Indirizzo | Istruzione / significato |
|---:|---|
| `0xbf98a05` | `movq (%r14), %rax` |
| `0xbf98a0b` | `callq *0x680(%rax)` → oggetto provider |
| `0xbf98a11` | `movq %rax, %r14` |
| `0xbf98a17` | `printChildrenNodes(provider)` |
| `0xbf98a1c` | `movl (%rbx), %eax` → bitmask attributi |
| `0xbf98a1e` | `testb $0x2, %al` |
| `0xbf98a25` | `leaq ... "LoadHWServices"` |
| `0xbf98a2c` | `movq %r14, %rdi` → provider |
| `0xbf98a2f` | `movl $0x1, %edx` → `true` |
| `0xbf98a34` | `callq *0x278(%rax)` → `setProperty` |
| `0xbf98a45` | `callq *0x5b0(%rax)` con `esi=2` → `registerService(2)` |

**PROVEN:** la stringa `"LoadHWServices"` è referenziata direttamente dal codice.
**PROVEN:** il valore passato è `1` (`true`).
**PROVEN:** il destinatario è l'oggetto restituito da `getProvider` (slot virtuale `0x680`; import `IOService::getProvider` presente).
**PROVEN:** la scrittura avviene solo se `(flags & 0x2) != 0`.
**PROVEN:** dopo la scrittura viene chiamato `registerService(2)`.

### 3.3 `start` non è il produttore

`AMDRadeonX6000_AmdGpuWrangler::start` a `0xbf987c2`:

| Indirizzo | Azione |
|---:|---|
| `0xbf987c2` | `start(IOService*)` |
| `0xbf9881d` | `registerService(0)` sull'oggetto Wrangler |
| `0xbf98838` | lookup `AMDRadeonLoadSvcMgr` |
| `0xbf98857` | `setProperty("AMDRadeonLoadSvcMgr", true)` |

**PROVEN:** `start` non contiene `LoadHWServices`.
**PROVEN:** la proprietà viene scritta solo nel percorso `vendor_doDeviceAttribute`.
**INFERRED:** il Wrangler deve ricevere l'attributo giusto dopo `start`.

---

## 4. Produttore secondario: AMDSupport

`AtiGpuWrangler::vendor_doDeviceAttribute` a `0x13b84370`:

| Indirizzo | Istruzione / significato |
|---:|---|
| `0x13b84584` | `callq *0x680(%rax)` → provider |
| `0x13b845ff` | `andl $0x2, %eax` |
| `0x13b84602`–`0x13b84605` | branch se bit 1 assente |
| `0x13b84611` | `leaq ... "LoadHWServices"` |
| `0x13b84618` | `movl $0x1, %edx` |
| `0x13b8461d` | `callq *0x278(%rax)` → `setProperty` |

**PROVEN:** anche AMDSupport contiene un produttore diretto.
**PROVEN:** la struttura è identica a X6000Framebuffer.
**INFERRED:** è un percorso generico/legacy, non la personality del target: `AMDSupport` ha `IOClass=AMDSupport`, non `AtiGpuWrangler`.
**UNPROVEN:** se `AtiGpuWrangler` venga istanziato sul target.

---

## 5. Perché prima non risultava

| Ricerca | Cosa copriva | Perché non bastava |
|---|---|---|
| HWServices binary | `LoadHWServices` | **0 occorrenze** |
| SystemKC XML | 3 personality | solo dichiarazioni |
| SystemKC stringhe | 2 stringhe Wrangler | nessun xref |
| BootKC | `LoadHWServices` | **0 occorrenze** |
| AMDSupport/Framebuffer `strings` | presenza della stringa | non dimostra il `setProperty` |
| `otool -tV` sui Wrangler | xref e ramo | **non era stato eseguito** |

**PROVEN:** il produttore è in due binari, non in HWServices.
**PROVEN:** la stringa da sola non bastava: serviva il disassemblaggio del chiamante.
**PROVEN:** il xref è ora localizzato.

---

## 6. Condizione residua

### 6.1 Il ramo è condizionale

```text
AmdGpuWrangler::vendor_doDeviceAttribute(..., flags, ...)
  ├─ flags & 0x2 == 0 → NON scrive LoadHWServices
  └─ flags & 0x2 != 0 → setProperty(provider, "LoadHWServices", true)
                         └─ registerService(2)
                              └─ HWServices può matchare
```

**PROVEN:** senza il bit `0x2` il produttore non scrive la proprietà.
**PROVEN:** con il bit `0x2` la scrive sul provider.
**UNPROVEN:** chi valorizza `flags` con `0x2` sul target.
**UNPROVEN:** se il caller AGDC/AMDSupport esegua quel ramo in macOS 26.7.3.

### 6.2 Cosa manca staticamente

| Prova | Stato |
|---|---|
| Xref stringa → `setProperty` | **PROVEN** |
| Oggetto destinatario = provider | **PROVEN via slot 0x680; classe IOPCIDevice INFERRED** |
| Valore `true` | **PROVEN** |
| Ramo `flags & 0x2` | **PROVEN** |
| Caller che passa `0x2` | **UNPROVEN** |
| Esecuzione sul target | **UNPROVEN** |

**PROVEN:** il produttore non è più il punto mancante.
**UNPROVEN:** l'input che lo attiva.

### 6.3 Prova necessaria

1. trovare il caller di `AmdGpuWrangler::vendor_doDeviceAttribute` (AGDC/AMDSupport/IOExternalMethod);
2. risalire al valore del bitmask `flags` passato al ramo `0xbf98a1e`;
3. dimostrare che il valore include `0x2` per Navi 14 / `ATY,Boa`;
4. in alternativa, un `ioreg` archiviato che mostri `LoadHWServices=true` sul `IOPCIDevice`.

**PROVEN:** senza 1–4 resta **UNPROVEN** che HWServices riceva la proprietà.
**PROVEN:** il codice per pubblicarla esiste.

---

## 7. Catena aggiornata

| # | Passaggio | Stato |
|---:|---|---|
| 1 | `AmdGpuWrangler` matcha `0x73401002` | **PROVEN plist** |
| 2 | `AmdGpuWrangler` diventa provider attivo | **PROVEN statico; runtime UNPROVEN** |
| 3 | `vendor_doDeviceAttribute` riceve flags con bit `0x2` | **UNPROVEN** |
| 4 | `setProperty(provider, "LoadHWServices", true)` | **PROVEN codice** |
| 5 | HWServices matcha `LoadHWServices=true` | **PROVEN metadati; runtime UNPROVEN** |
| 6 | HWServices pubblica `Load6100` | **PROVEN statico** |
| 7 | X6100 matcha e viene istanziata | **PROVEN statico** |
| 8 | X6100 operativo | **UNPROVEN runtime** |

**Diagnosi:** il collo di bottiglia si è spostato dal produttore al **caller/flag**. Il produttore è `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute`; il punto non dimostrato è che venga chiamato con `flags & 0x2`.

---

## 8. Verdetto

| Domanda | Risposta |
|---|---|
| Chi deve pubblicare `LoadHWServices`? | **`AmdGpuWrangler::vendor_doDeviceAttribute`** |
| Dove? | `AMDRadeonX6000Framebuffer`, `0xbf9894e` |
| Su quale oggetto? | provider del Wrangler (`getProvider`, slot `0x680`) |
| Con quale valore? | `true` (`edx=1`) |
| Sempre? | **NO — solo se `flags & 0x2`** |
| Produttore AMDSupport? | **SÌ, secondario/legacy** |
| Produttore dimostrato? | **SÌ** |
| Caller/flags dimostrato? | **NO — UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il produttore di `LoadHWServices=true` è `AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute` in `AMDRadeonX6000Framebuffer`, non HWServices. La personality `AMDGPUWrangler` copre `0x73401002`, la classe è in SystemKC e il codice chiama `setProperty` sul provider con valore `true`; la stessa struttura esiste in `AtiGpuWrangler` dentro AMDSupport. Il 161 non l'aveva visto perché non aveva disassemblato i Wrangler. Resta **UNPROVEN** il ramo che deve attivare la scrittura: `vendor_doDeviceAttribute` scrive solo se il bitmask contiene `0x2`; non è dimostrato chi lo passi sul target. Questa è ora la prova statica necessaria. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **15.417.680 KiB ≈ 14,70 GiB** > 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
