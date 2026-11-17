# T27 — AGENT-AMD — COLLISIONE HWLIBS X6000/X6100 (157)

**Scope:** determinare staticamente se `IOMatchCategory=AMDRadeonHWLibs` condivisa da X6000 e X6100 può impedire il caricamento corretto di `AMDRadeonX6100HWLibs`; ricostruire `findPlugIn`, l’ordine dei child, le cross-reference di `Load6000`/`Load6100`/`LoadPlugIn` in SystemKC e il confronto sul target Navi 14 `ATY,Boa`.

**Verdetto:** **NON PUÒ sul target `ATY,Boa`**. La collisione di categoria è reale nei metadati, ma non produce due candidati: X6000 richiede `Load6000`, X6100 richiede `Load6100`, e il provider pubblica `Load6100`; solo X6100 supera `IOPropertyMatch`. `findPlugIn` è un **first-match** che non controlla `IOClass`/`LoadPlugIn`: **PUÒ** selezionare il child sbagliato solo in uno scenario non dimostrato in cui esista già un altro child con la stessa categoria. L’attach runtime resta **UNPROVEN**. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| X6000HWServices | `cc7aaca45446f98cc4ea03b1fdf80b402975c1b0e0d07585a304d78dcdf797f7` |
| X6000HWLibs `Info.plist` | `42599c7cdb3269e7ed39614766dc1955c3eba5eba52d3d1aeab5cad75ffcbd5c` |
| X6100HWLibs `Info.plist` | `414fa880bf31cfbdd5a0007825961c6cc9e231afba5210e563507b510deb86a1` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |

**Ambiente:** macOS `26.7.3`, build `25G342`.  
**Spazio:** **12.313.336 KiB ≈ 11,74 GiB** > 10 GiB.

**Nota:** il report 157 non ripete l’analisi di caricabilità di X6100 del report 156; ne usa solo i risultati necessari al confronto.

---

## 2. `findPlugIn`: algoritmo effettivo

### 2.1 Disassembly

`AMDRadeonX6000_AMDRadeonHWServicesAbstract::findPlugIn()` è a `0xc26dc80`.

| Indirizzo | Istruzione / significato |
|---:|---|
| `0xc26dc80` | inizio funzione |
| `0xc26dc90` | `found = 0` |
| `0xc26dc98` | carica vptr dell’oggetto |
| `0xc26dc9b` | `callq *0x6a8(%rax)` — `getChildIterator` |
| `0xc26dca1` | salva l’iteratore |
| `0xc26dca7` | se iteratore nullo → return null |
| `0xc26dcd9` | `callq *0x128(%rax)` — next object dell’iteratore |
| `0xc26dce8` | se child nullo → esci dal loop |
| `0xc26dd15` | `leaq "IOMatchCategory"` |
| `0xc26dd1c` | `callq *0x2b8(%rax)` — `getProperty("IOMatchCategory")` |
| `0xc26dd3a` | se proprietà nulla → next child |
| `0xc26dd49` | carica costante `HWLIB_PLUG_IN_MATCH_CATEGORY` = `AMDRadeonHWLibs` |
| `0xc26dd50` | `callq *0x158(%rax)` — `isEqualTo` |
| `0xc26dd56`–`0xc26dd5c` | se vero: `found = child`; break |
| `0xc26dd66` | altrimenti next child |
| `0xc26dd6b`–`0xc26dd72` | `callq *0x28(%rax)` — release dell’iteratore |
| `0xc26dd7d` | return `found` |

Costanti nel binario:

| Simbolo / stringa | Indirizzo |
|---|---:|
| `HWLIB_PLUG_IN_MATCH_CATEGORY` | `0xc26e3b0` |
| stringa `AMDRadeonHWLibs` | `0xc26e3b0` |
| stringa `IOMatchCategory` | `0xc26e388` |
| `findPlugIn` | `0xc26dc80` |

**PROVEN:** il confronto è con la stringa `AMDRadeonHWLibs`.
**PROVEN:** `findPlugIn` non confronta `LoadPlugIn`, `IOClass`, `IOProviderClass` o il nome del bundle.
**PROVEN:** viene restituito il **primo** child con categoria uguale; non viene cercato un match migliore.
**PROVEN:** `findPlugIn` non ordina e non deduplica i child.

### 2.2 Pseudo-codice ricostruito

```text
findPlugIn():
    found = null
    iterator = this->getChildIterator()
    if iterator == null:
        return null

    while (child = iterator->getNextObject()) != null:
        category = child->getProperty("IOMatchCategory")
        if category == null:
            continue
        if category->isEqualTo("AMDRadeonHWLibs"):
            found = child
            break

    iterator->release()
    return found
```

**FATTO:** questo è il comportamento delle istruzioni osservate.
**IPOTESI:** `0x128` è l’accessor “next object” dell’iteratore e `0x28` è il `release`; i simboli importati confermano `IORegistryEntry::getChildIterator`, ma i nomi esatti dei due slot non sono disponibili come simboli separati.

### 2.3 Ordine dei child

`findPlugIn` usa `IORegistryEntry::getChildIterator(IORegistryPlane const*)` (`0xFFFFFF8000A8F4E0`). Il selettore non impone un ordinamento.

**PROVEN:** in `findPlugIn` non c’è sort, confronto di priorità, `IOProbeScore`, `LoadPlugIn` o `IOClass`.
**UNPROVEN:** l’ordine deterministico dei child.
**INFERRED:** l’ordine è quello della collezione dei child (verosimilmente ordine di registrazione/attach), non un ordine garantito dal codice di `findPlugIn`.
**UNPROVEN:** se `getChildIterator` restituisca l’ordine di attach, l’ordine di inserimento o un ordine interno diverso.

### 2.4 Nessuna API di selezione per categoria

In BootKC sono presenti:

| Simbolo | Indirizzo |
|---|---:|
| `IORegistryEntry::getChildIterator` | `0xFFFFFF8000A8F4E0` |
| `IORegistryEntry::getChildEntry` | `0xFFFFFF8000A8F710` |
| `IORegistryEntry::getChildSetReference` | `0xFFFFFF8000A93840` |
| `IORegistryEntry::getChildCount` | `0xFFFFFF8000A93F80` |
| `IOService::attach` | `0xFFFFFF8000A95E30` |
| `IOService::getClientWithCategory` | `0xFFFFFF8000AA8560` |
| `IOService::copyClientWithCategory` | `0xFFFFFF8000A94730` |

**PROVEN:** `findPlugIn` non chiama `getChildByCategory`; non esiste un simbolo `getChildByCategory` nel BootKC consultato.
**PROVEN:** le API `getClientWithCategory`/`copyClientWithCategory` sono API di **client**, non usate da `findPlugIn`.
**INFERRED:** `IOMatchCategory` non fornisce a `findPlugIn` una selezione univoca; la selezione è interamente il loop sopra.

**Limite:** il corpo di `IOService::attach` e l’eventuale controllo di unicità della categoria non sono disassemblabili dai fileset disponibili. **UNPROVEN:** se IOKit impedisca due attach della stessa categoria prima di `findPlugIn`.

---

## 3. SystemKC: `Load6000`, `Load6100`, `LoadPlugIn`

### 3.1 Stringhe e simboli

| Stringa | Occorrenze in SystemKC | Offset esempio |
|---|---:|---:|
| `Load6000` | 3 | `0x60712` |
| `Load6100` | 2 | `0x613ea` |
| `LoadPlugIn` | 19 | `0x49f57`, `0x606f6`, `0x613ce`, … |
| `AMDRadeonHWLibs` | 1337 | molte, incluse classi/CAIL e XML |

`nm -arch x86_64 -n SystemKC | grep -E 'Load6000|Load6100|LoadPlugIn'` restituisce **zero** simboli.
**PROVEN:** `Load6000`, `Load6100` e `LoadPlugIn` non sono funzioni o simboli di codice in SystemKC; le occorrenze sono stringhe XML/plist incorporate.
**PROVEN:** le stringhe `Load6000`/`Load6100` sono `<string>…</string>` nelle personality, non nomi di metodi.

### 3.2 Disassembly target

`otool -tvV -arch x86_64 SystemKC` non produce disassembly utilizzabile per gli indirizzi delle classi X6100 (`0xdd6f0b0`, `0xdd6f120`, `0xdd6f320`, `0xdd6eb10`): i fileset della kernel collection non espongono quei corpi nel file con gli offset disponibili.

**PROVEN:** la limitazione è dello strumento/formato, non un’assenza dei simboli (i simboli `nm` esistono).
**UNPROVEN:** eventuali cross-reference byte-level a `Load6000`/`Load6100` in SystemKC.
**PROVEN:** nel binario HWServices la selezione del plugin non usa `Load6000`/`Load6100` direttamente; `getMatchProperty` produce il valore e `findPlugIn` usa solo `IOMatchCategory`.

### 3.3 Criteri aggiuntivi

| Criterio | Evidenza | Esito |
|---|---|---|
| `LoadPlugIn` in `findPlugIn` | nessun accesso alla chiave | **NON USATO** |
| `IOClass` in `findPlugIn` | nessun confronto | **NON USATO** |
| `IOProviderClass` in `findPlugIn` | nessun confronto | **NON USATO** |
| `IOProbeScore` in `findPlugIn` | nessun accesso | **NON USATO** |
| ordinamento/priorità | nessun sort o compare | **NON PRESENTE** |
| return code che blocchi il caricamento | `findPlugIn` ritorna null o child | **SOLO NULL/CHILD** |

**PROVEN:** nessun criterio aggiuntivo è presente nel codice di `findPlugIn`.
**PROVEN:** l’unico filtro è `IOMatchCategory == AMDRadeonHWLibs`.
**UNPROVEN:** eventuali filtri a monte, dentro `IOService::attach` o `IOCatalogue`, non disassemblabili.

---

## 4. X6000 vs X6100 sul target `ATY,Boa`

| Aspetto | X6000HWLibs | X6100HWLibs |
|---|---|---|
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWLibsX6000` | `AMDRadeonX6100_AMDRadeonHWLibsX6100` |
| `IOProviderClass` | `...HWServicesInterface` | `...HWServicesInterface` |
| `IOMatchCategory` | `AMDRadeonHWLibs` | `AMDRadeonHWLibs` |
| `IOPropertyMatch.LoadPlugIn` | `Load6000` | `Load6100` |
| Classe in SystemKC | sì (report 154) | sì (report 156) |
| Match su `ATY,Boa` | **NO** | **SÌ** |
| Motivo | provider pubblica `Load6100`, non `Load6000` | provider pubblica `Load6100` |

**PROVEN:** il target `ATY,Boa` produce `Load6100`; X6000 richiede `Load6000`.
**PROVEN:** X6000 non supera `IOPropertyMatch` sul target.
**PROVEN:** X6100 supera provider, categoria e property match.
**PROVEN:** la collisione di `IOMatchCategory` è solo una condivisione di categoria; non rende X6000 un candidato valido.

### 4.1 Effetto della collisione

| Scenario | Esito |
|---|---|
| Solo X6100 attaccato (match normale) | `findPlugIn` restituisce X6100 |
| X6000 non matcha `Load6000` | non dovrebbe diventare child del provider |
| X6000 e X6100 entrambi child con categoria | `findPlugIn` restituisce il primo; possibile child sbagliato |
| Child estraneo con categoria già presente | `findPlugIn` può restituirlo; `LoadPlugIn` non viene ricontrollato |
| Nessun child con categoria | `findPlugIn` restituisce null; `start` fallisce |

**PROVEN:** nel caso target normale solo X6100 è eleggibile.
**PROVEN:** se esistono più child con la stessa categoria, il primo vince e non c’è controllo di `LoadPlugIn`/`IOClass`.
**UNPROVEN:** che nel runtime target esista un secondo child con categoria.
**UNPROVEN:** che `IOService::attach` permetta o impedisca due child della stessa categoria.

---

## 5. Verdetto

### 5.1 Sul target `ATY,Boa`

**NON PUÒ** impedire il caricamento corretto di X6100 con il meccanismo della collisione di categoria, perché:

1. il provider pubblica `Load6100`;
2. X6000 richiede `Load6000` e non supera `IOPropertyMatch`;
3. X6100 richiede `Load6100` e lo supera;
4. `findPlugIn` vede solo i child già attaccati; nel percorso di matching target non viene creato un child X6000 con quella categoria.

**PROVEN:** la collisione non produce due candidati validi sul target.
**PROVEN:** `findPlugIn` non è la causa di un match X6000 sul target.

### 5.2 Rischio condizionale

**PUÒ** in linea di principio se un child con `IOMatchCategory=AMDRadeonHWLibs` è già presente e non è X6100 (per esempio un child residuo o creato da un altro percorso): `findPlugIn` restituisce il primo e non verifica `LoadPlugIn` né `IOClass`. In quel caso `SWIP::start` riceverebbe il child sbagliato e `AmdTtlInterfaceKey` potrebbe fallire.

**UNPROVEN:** l’esistenza di questo child estraneo nel target.
**UNPROVEN:** l’ordine dell’iteratore e l’esito dell’attach.
**NON DIMOSTRATO:** che la sola condivisione di `IOMatchCategory` crei il child estraneo.

### 5.3 Cosa servirebbe per chiudere

Una prova runtime read-only (non eseguibile in T27) dovrebbe:

1. elencare i child del provider HWServices e le loro `IOMatchCategory`;
2. verificare se esiste un child X6000/X6200/X6700 oltre a X6100;
3. verificare l’ordine restituito da `getChildIterator` e il valore di ritorno di `findPlugIn`;
4. verificare che `findPlugIn` restituisca l’oggetto X6100 e che `createTtlInterface` riceva `AmdTtlInterfaceKey`.

Senza questa prova, il verdetto target resta **NON PUÒ** per il percorso di matching statico, con rischio condizionale **UNPROVEN**.

---

## 6. Sintesi FATTO / IPOTESI / UNPROVEN

| Affermazione | Stato |
|---|---|
| `findPlugIn` itera i child con `getChildIterator` | **FATTO** |
| confronta `IOMatchCategory` con `AMDRadeonHWLibs` | **FATTO** |
| restituisce il primo match | **FATTO** |
| non controlla `LoadPlugIn`/`IOClass` | **FATTO** |
| non ordina i child | **FATTO** |
| l’ordine dei child è deterministico | **UNPROVEN** |
| X6000 matcha `ATY,Boa` | **REFUTED** |
| X6100 matcha `ATY,Boa` | **FATTO statico** |
| collisione categoria impedisce X6100 sul target | **NON PUÒ** |
| collisione può scegliere child sbagliato se multi-child | **PUÒ condizionale / UNPROVEN** |
| attach runtime X6100 | **UNPROVEN** |
| T27 GO | **NO — OPEN** |

**Risposta netta:** `findPlugIn` è un selettore first-match per sola `IOMatchCategory`, senza `LoadPlugIn`, `IOClass`, priorità o ordinamento. Sul target `ATY,Boa` X6000 non matcha (`Load6000` contro `Load6100`) e X6100 sì; quindi la collisione di categoria **non può** impedire il caricamento corretto nel percorso statico target. Resta il rischio condizionale di un child estraneo già attaccato, non dimostrato staticamente; l’attach runtime e l’ordine dei child restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **12.313.336 KiB ≈ 11,74 GiB** > 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
