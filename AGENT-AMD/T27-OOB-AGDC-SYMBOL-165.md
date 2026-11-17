# T27 — AGENT-AMD — AGDC SYMBOL / TABLE (165)

**Scope:** identificare il componente Apple che risolve il simbolo AGDC esterno e invoca indirettamente `vendor_doDeviceAttribute`; chiarire l’origine di `rdx` e del bit `0x2`; analizzare relocation/import AGDC in SystemKC; cercare `AppleGraphicsDeviceControl` in dyld shared cache, framework, driver e kernel collection; ricostruire la tabella `0xc26e9c8` e i consumer; verificare ABI, registri e argomenti; cercare percorsi alternativi di inizializzazione; indicare il componente che può fornire la prova definitiva.

**Modalità:** sola lettura. Nessun boot, trace, modifica, build o download. Comandi: `nm`, `otool`, `strings`, `grep`, `find`, `plutil`, `shasum`.

**Esito:** **PROVEN** che SystemKC contiene **237** riferimenti a simboli `AppleGraphicsDeviceControl`, tutti **undefined (`U`)**, e **0 definizioni**. **PROVEN** che BootKC non contiene la classe, che nel root non esiste un eseguibile `AppleGraphicsDeviceControl` e che non esiste una dyld shared cache. **PROVEN** che la tabella `0xc26e9c8` contiene il puntatore a `vendor_doDeviceAttribute` insieme ad altri metodi del Wrangler, ma **non ha consumer riferibili staticamente**. **UNPROVEN** il componente che risolve il simbolo e il valore `flags & 0x2`. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| AppleGraphicsDeviceControl `Info.plist` | `d521d429dbf95570ec5f6469d1286a846d30739be75e2fe1e1af6244431a5188` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| X6000Framebuffer executable | `a2469429602210e64a74292a30b06353d9e0f75cd6b8b65f98324e64fa0b4536` |
| X6000Framebuffer `Info.plist` | `1b28b9aab877c4b3362edabde5a512d45d0cf97c10611b034c8ea53995a9f573` |
| Report 164 | `50d02e81345671bbc3ce57331d8ced3b1f8fc89fb08d58e938cf91ca1c90707c` |

**Ambiente:** macOS `26.7.3`, build `25G342`.
**Spazio:** **15.406.336 KiB ≈ 14,69 GiB** > 10 GiB.

---

## 2. Ricerca del componente AGDC

| Luogo | Ricerca | Esito |
|---|---|---|
| SystemKC | simboli `AppleGraphicsDeviceControl` | **237 U, 0 T** |
| BootKC | simboli/strings AGDC | **0** |
| Root completo | file `AppleGraphicsDeviceControl` | **0** |
| `AppleGraphicsDeviceControl.kext` | `Contents/MacOS` | **assente** |
| dyld shared cache | directory `System/Library/dyld` | **assente/vuota** |
| AppleGraphicsControl | eseguibili | solo `AGDCDiagnose`, `DisplayDiagnose`, `mpxdiagnose` |

**PROVEN:** l’implementazione del kext AGDC non è nel root estratto.
**PROVEN:** SystemKC non contiene il corpo delle funzioni AGDC.
**PROVEN:** non c’è una dyld cache da analizzare.
**UNPROVEN:** il componente live che risolve i simboli.

### 2.1 Simboli SystemKC

| Simbolo | Tipo |
|---|---|
| `AppleGraphicsDeviceControl::vendor_doDeviceAttribute` | **U** |
| `AppleGraphicsDeviceControl::doDeviceAttribute` | **U** |
| `AppleGraphicsDeviceControl::setDeviceAttribute` | **U** |
| `AppleGraphicsDeviceControl::getDeviceAttribute` | **U** |
| `AppleGraphicsDeviceControl::newUserClient` | **U** |
| `AppleGraphicsDeviceControl::start` / `stop` | **U** |
| `AppleGraphicsDeviceControl::gMetaClass` | **U** |
| `_RESERVEDAppleGraphicsDeviceControl0…7` | **U** |

**PROVEN:** sono import, non definizioni.
**PROVEN:** il numero di occorrenze è **237**.
**UNPROVEN:** quale kext fornisca le definizioni.

---

## 3. Tabella `0xc26e9c8`

### 3.1 Contenuto

Nel binario X6000Framebuffer, il puntatore `0xbf9894e` compare a file offset **3221960** (`0xc26e9c8`, `__DATA_CONST`) insieme a:

| Voce | Puntatore |
|---|---:|
| `getVendorInfo` | `0xbf98aec` |
| `callPlatformFunction` | `0xbf98bc0` |
| `vendor_doDeviceAttribute` | `0xbf9894e` |
| `free` | `0xbf98876` |
| `stop` | `0xbf988b2` |
| `probe` | `0xbf985ae` |
| `start` | `0xbf987c2` |

**PROVEN:** è una tabella di metodi del Wrangler.
**PROVEN:** contiene il puntatore alla funzione.
**PROVEN:** non ci sono riferimenti testuali al suo indirizzo nel codice.

### 3.2 Consumer

| Ricerca | Esito |
|---|---|
| `callq 0xbf9894e` | **0** |
| riferimenti a `0xc26e9c8` nel testo | **0** |
| riferimenti al puntatore nel codice | **0** |
| consumer identificato | **NO** |

**PROVEN:** la tabella non è referenziata direttamente dal codice del kext.
**INFERRED:** è usata tramite un oggetto/vtable esterno.
**UNPROVEN:** chi la usa e con quale indice.

---

## 4. ABI e argomenti

### 4.1 Firma osservata

```text
vendor_doDeviceAttribute(
    this,        // rdi
    command,     // esi
    arg2,        // rdx -> flags pointer
    arg3,        // rcx
    arg4,        // r8
    arg5,        // r9
    external     // stack
)
```

**PROVEN:** `rdx` viene salvato in `rbx` a `0xbf9895f`.
**PROVEN:** il bitmask è letto da `(%rbx)` a `0xbf98a1c`.
**PROVEN:** il bit `0x2` è testato a `0xbf98a1e`.
**PROVEN:** il valore `true` è passato a `setProperty` a `0xbf98a2f`.

### 4.2 Inizializzazione

| Metodo | Scrive flags? | Chiama vendor? |
|---|---|---|
| `C1 0xbf9854e` | **NO** | **NO** |
| `C2 0xbf9857e` | **NO** | **NO** |
| `probe 0xbf985ae` | **NO** | **NO** |
| `attach 0xbf986d2` | **NO** | **NO** |
| `start 0xbf987c2` | **NO** | **NO** |

**PROVEN:** il bit `0x2` non è inizializzato dal Wrangler.
**PROVEN:** l’unica sorgente è il chiamante.

---

## 5. Percorsi alternativi

| Immagine | `setProperty("LoadHWServices")` | Stato |
|---|---|---|
| X6000Framebuffer | `0xbf98a25` | **PROVEN** |
| AMDSupport | `0x13b84611` | **PROVEN** |
| HWServices | **0** | **REFUTED** |
| BootKC | **0** | **REFUTED** |
| SystemKC XML | 3 personality | solo dichiarazioni |
| AGDC | implementazione assente | **UNPROVEN** |

**PROVEN:** non esistono altri setter noti.
**PROVEN:** entrambi i Wrangler richiedono il bit `0x2`.
**UNPROVEN:** un percorso AGDC alternativo.

---

## 6. Componente decisivo

| Candidato | Disponibilità | Può chiudere? |
|---|---|---|
| `AppleGraphicsDeviceControl.kext` eseguibile | **assente** | **SÌ, se fornito** |
| SystemKC | solo import | **NO** |
| BootKC | assente | **NO** |
| dyld shared cache | assente | **NO** |
| `AGDCDiagnose` | tool userspace | **NO** |
| `ioreg` archiviato | assente | **SÌ, se disponibile** |

**PROVEN:** il componente che può chiudere la prova è l’eseguibile AGDC o un `ioreg`.
**PROVEN:** nessuno dei due è disponibile.
**UNPROVEN:** la condizione del target.

---

## 7. Target MacBookPro16,1

| Condizione | Esito |
|---|---|
| GPU Navi 14 `0x73401002` | **PROVEN metadati** |
| classe `AmdGpuWrangler` in SystemKC | **PROVEN** |
| tabella con `vendor_doDeviceAttribute` | **PROVEN** |
| caller AGDC risolto | **NO — UNPROVEN** |
| `flags & 0x2` sul target | **UNPROVEN** |
| `LoadHWServices=true` sul PCI | **UNPROVEN** |

**PROVEN:** il potenziale percorso esiste.
**UNPROVEN:** l’attivazione sul target.

---

## 8. Diagnosi

| Priorità | Elemento | Stato |
|---:|---|---|
| 1 | implementazione AGDC | **ASSENTE** |
| 2 | caller e bit `0x2` | **UNPROVEN** |
| 3 | scrittura `LoadHWServices` | **PROVEN codice; runtime UNPROVEN** |
| 4 | HWServices e X6100 | **PROVEN statico** |
| 5 | X6100 operativo | **UNPROVEN runtime** |

**Diagnosi:** la catena statica si ferma al confine AGDC. SystemKC importa 237 simboli ma non contiene l’implementazione; BootKC non la contiene; il bundle non ha eseguibile; non c’è dyld cache. La tabella `0xc26e9c8` è una method table del Wrangler, ma non ha consumer riferibili. Non è quindi possibile stabilire staticamente l’origine di `rdx` né il bit `0x2`. La prova definitiva richiede l’eseguibile AGDC o un `ioreg` archiviato.

---

## 9. Verdetto

| Domanda | Risposta |
|---|---|
| Simbolo AGDC risolto localmente | **NO** |
| Definizioni in SystemKC | **0** |
| Import in SystemKC | **237 U** |
| BootKC | **NO** |
| Eseguibile AGDC | **NO** |
| Tabella `0xc26e9c8` | **method table, consumer ignoto** |
| Bit `0x2` inizializzato dal Wrangler | **NO** |
| Target soddisfa bit `0x2` | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il componente Apple che risolve i simboli AGDC non è presente nei file disponibili. SystemKC contiene 237 riferimenti `U`, BootKC non contiene la classe, il bundle `AppleGraphicsDeviceControl.kext` non ha eseguibile e non esiste una dyld shared cache. La tabella `0xc26e9c8` contiene il puntatore a `vendor_doDeviceAttribute`, ma non è referenziata dal codice e non ha consumer ricostruibile. Il bit `0x2` resta un argomento `rdx` fornito dall’esterno. La prova definitiva può venire solo dall’eseguibile AGDC mancante o da un `ioreg` archiviato. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **15.406.336 KiB ≈ 14,69 GiB** > 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
