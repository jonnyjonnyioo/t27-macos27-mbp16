# T27 — AGENT-AMD — INTERFACE / HWLIBS (154)

**Scope:** tracciare le istanze e i riferimenti a `AMDRadeonX6000_AMDRadeonHWServicesInterface` (costruttore, allocazione, pubblicazione, `registerService`); verificare la registrazione OSMetaClass di `AMDRadeonX6000_AMDRadeonHWLibsX6000` in SystemKC; verificare il percorso statico Interface → matching personality → attach.

**Modalità:** sola lettura; HWServices, SystemKC, plist HWLibs/HWServices; nessun boot, trace, modifica, build o download.

**Esito:** **PROVEN** che Interface non è un'istanza separata: è la superclasse di `AMDRadeonX6000_AMDRadeonHWServicesNavi`, e l'oggetto Navi viene pubblicato con `registerService(2)` da `Abstract::start`. **PROVEN** che la classe `AMDRadeonX6000_AMDRadeonHWLibsX6000` è presente in SystemKC con simboli OSMetaClass, costruttore e vtable (78 simboli della classe/base). **PROVEN** la catena statica; **UNPROVEN** l'attach runtime e la selezione univoca del child. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| X6000HWServices | `cc7aaca45446f98cc4ea03b1fdf80b402975c1b0e0d07585a304d78dcdf797f7` |
| HWServices `Info.plist` | `c6dcc67430bbbff1490e7101d395b3dbcfe248c10adc889efd59dd1689810bf0` |
| X6000HWLibs `Info.plist` | `42599c7cdb3269e7ed39614766dc1955c3eba5eba52d3d1aeab5cad75ffcbd5c` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Interface: classe e istanza

### 2.1 Costruttore e MetaClass

| Elemento | Indirizzo |
|---|---:|
| `AMDRadeonX6000_AMDRadeonHWServicesInterface::MetaClassC1` | `0xc26d210` |
| `MetaClassC2` | `0xc26d300` |
| `Interface` constructor | `0xc26d260` |
| `Interface` `getMetaClass` | `0xc26d2e0` |
| `Interface` `MetaClass::alloc` | `0xc26d350` |
| vtable `__ZTV…Interface` | `0xc270378` |
| `gMetaClass` | `0xc271828` |

Il costruttore `0xc26d260`:

| Indirizzo | Istruzione |
|---:|---|
| `0xc26d27c` | chiama lo stub base `0x10180` |
| `0xc26d285`–`0xc26d28c` | carica `__ZTV…Interface + 0x10` |
| `0xc26d290` | imposta il vptr |

**PROVEN:** Interface ha un costruttore, una MetaClass e un allocatore.
**PROVEN:** il costruttore non chiama `registerService`.
**PROVEN:** Interface non ha un'istanza separata creata dal costruttore; il costruttore è la base della catena Navi.

### 2.2 Catena Navi → SWIP → Abstract → Interface

| Classe | Costruttore | MetaClass |
|---|---:|---:|
| `Navi` | `0xc26c980` | `0xc26c930` |
| `SWIP` | `0xc26ce10` | `0xc26cdc0` |
| `Abstract` | `0xc26d4f0` (MetaClass) | `0xc26d4f0` |
| `Interface` | `0xc26d260` | `0xc26d210` |

**PROVEN:** `Navi` costruisce `SWIP`, che costruisce `Abstract`, che costruisce `Interface`; l'oggetto Navi è un'istanza della catena e quindi soddisfa `IOProviderClass=AMDRadeonX6000_AMDRadeonHWServicesInterface`.
**PROVEN:** non esiste un secondo oggetto Interface separato da pubblicare.

### 2.3 Pubblicazione

`AMDRadeonX6000_AMDRadeonHWServicesAbstract::start` a `0xc26d8c0`:

| Indirizzo | Azione |
|---:|---|
| `0xc26d9b3` | `getMatchProperty()` |
| `0xc26d9d7` | `setProperty("LoadPlugIn", value)` |
| `0xc26da0d` | `registerService(2)` |
| `0xc26da21` | `findPlugIn()` |

**PROVEN:** la pubblicazione avviene tramite `registerService(2)` sull'oggetto Navi/Interface, non tramite un `registerService` separato nella classe Interface.
**PROVEN:** `Interface` non ha un proprio call-site `registerService`; il simbolo `IOService::registerService` è importato da HWServices e usato nel dispatch `0x5b0`.
**UNPROVEN:** la pubblicazione IOService effettiva a runtime.

---

## 3. HWLibs: registrazione OSMetaClass

### 3.1 Simboli SystemKC

`nm -arch x86_64 -n SystemKC` trova la classe:

| Simbolo | Indirizzo |
|---|---:|
| `AMDRadeonX6000_AMDRadeonHWLibsX6000::MetaClassC1` | `0xc273980` |
| `MetaClassD1` | `0xc2739a0` |
| `HWLibsX6000` constructor C2 | `0xc2739d0` |
| `HWLibsX6000` constructor C1 | `0xc273a10` |
| `HWLibsX6000` destructor D2/D1/D0 | `0xc273a40`–`0xc273a90` |
| `getMetaClass` | `0xc273af0` |
| `MetaClassC2` | `0xc273b10` |
| `MetaClass::alloc` | `0xc273b60` |
| `populateFirmwareDirectory` | `0xc273c30` |
| `__GLOBAL__sub_I_AMDRadeonHWLibsX6000.cpp` | `0xc273f10` |

**PROVEN:** la classe `AMDRadeonX6000_AMDRadeonHWLibsX6000` è presente in SystemKC con MetaClass, costruttore, distruttore, `getMetaClass`, `alloc` e inizializzatore globale.
**PROVEN:** la classe base `AMDRadeonX6000_AMDRadeonHWLibs` è presente a `0xc273f60`–`0xc274710`; la classe X6000 è una specializzazione.
**PROVEN:** il nome classe compare 25 volte in SystemKC; il nome bundle `AMDRadeonX6000HWLibs` compare 9 volte.
**UNPROVEN:** che l'OSMetaClass sia registrata **prima** del matching; la presenza dei simboli non prova l'ordine di inizializzazione.

### 3.2 Plist

| Campo | Valore |
|---|---|
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWLibsX6000` |
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOMatchCategory` | `AMDRadeonHWLibs` |
| `IOPropertyMatch.LoadPlugIn` | `Load6000` |
| `OSBundleLibraries` | IOPCIFamily, bsd, iokit, libkern, mach; **no HWServices** |

**PROVEN:** il plist punta alla classe registrata in SystemKC.
**PROVEN:** il legame con HWServices è il provider class, non una dipendenza di linkage.

---

## 4. Percorso statico Interface → matching → attach

| Fase | Evidenza | Stato |
|---|---|---|
| 1. Istanza Navi/Interface | ctor Navi `0xc26c980` → SWIP `0xc26ce10` → Interface `0xc26d260` | **PROVEN** |
| 2. `LoadHWServices=true` | plist HWServices | **PROVEN** |
| 3. HWServices `start` | `0xc26d8c0` | **PROVEN** |
| 4. `getMatchProperty` | `0xc26cbe0`; caller `0xc26d9b3` | **PROVEN** |
| 5. `setProperty("LoadPlugIn")` | `0xc26d9d7` | **PROVEN** |
| 6. `registerService(2)` | `0xc26da0d`; target `0xA94C60` | **PROVEN** |
| 7. matching IOKit | `registerService → startMatching → findDrivers` | **PROVEN sorgente / simboli** |
| 8. classe HWLibs disponibile | SystemKC simboli `0xc273980…` | **PROVEN statico** |
| 9. attach HWLibs | IOCatalogue / IOService | **UNPROVEN runtime** |
| 10. `findPlugIn` | `0xc26dc80`; solo `IOMatchCategory` | **PROVEN statico** |
| 11. `createTtlInterface` | `0xc26d060`; `AmdTtlInterfaceKey` | **PROVEN statico** |

**PROVEN:** la catena statica Interface → HWServices → `LoadPlugIn` → matching → HWLibs → `AmdTtlInterfaceKey` è completa.
**PROVEN:** non c'è un'istanza Interface separata da pubblicare; l'oggetto Navi è l'Interface.
**UNPROVEN:** l'attach effettivo e l'ordine runtime.
**UNPROVEN:** che `findPlugIn` scelga proprio X6000 e non un altro HWLibs della stessa categoria.

---

## 5. Controlli e rischi

| Controllo | Stato |
|---|---|
| Interface è una classe base, non un'istanza separata | **PROVEN** |
| Interface ctor non pubblica | **PROVEN** |
| HWServices pubblica con `registerService(2)` | **PROVEN statico** |
| HWLibs class in SystemKC | **PROVEN** |
| HWLibs OSMetaClass registrata prima del match | **UNPROVEN** |
| `findPlugIn` verifica `IOClass` | **NO** |
| `findPlugIn` verifica `LoadPlugIn` | **NO** |
| `findPlugIn` verifica solo `IOMatchCategory` | **SÌ** |
| Attach runtime | **UNPROVEN** |

**PROVEN:** `findPlugIn` non distingue X6000/X6100/X6200/X6700: cerca solo `IOMatchCategory == AMDRadeonHWLibs`.
**RISCHIO STATICO:** se più HWLibs sono figli dello stesso provider, `findPlugIn` può restituire il primo della categoria, non necessariamente quello selezionato da `LoadPlugIn`.
**UNPROVEN:** se IOKit attacca un solo HWLibs per provider, eliminando il rischio.

---

## 6. Verdetto

| Domanda | Risposta |
|---|---|
| Interface è un'istanza separata? | **NO — è la superclasse dell'oggetto Navi** |
| Interface ctor pubblica? | **NO** |
| Chi pubblica? | **`Abstract::start` con `registerService(2)`** |
| HWLibsX6000 è in SystemKC? | **SÌ — 78 simboli classe/base** |
| OSMetaClass presente? | **SÌ — MetaClassC1/C2, alloc, getMetaClass** |
| Percorso statico completo? | **SÌ** |
| Attach runtime | **UNPROVEN** |
| `findPlugIn` selezione univoca? | **NO — solo categoria** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `AMDRadeonX6000_AMDRadeonHWServicesInterface` non è un oggetto separato da pubblicare: è la superclasse di `AMDRadeonX6000_AMDRadeonHWServicesNavi`, e l'oggetto Navi viene costruito dalla catena Navi → SWIP → Abstract → Interface. La pubblicazione avviene in `Abstract::start` con `setProperty("LoadPlugIn")` e `registerService(2)`; Interface non ha un proprio `registerService`. La classe `AMDRadeonX6000_AMDRadeonHWLibsX6000` è presente in SystemKC con MetaClass, costruttore, alloc, getMetaClass e 78 simboli complessivi della classe/base. Il percorso statico Interface → matching → HWLibs è completo; restano **UNPROVEN** la registrazione OSMetaClass prima del match, l'attach runtime e la selezione univoca del child, perché `findPlugIn` controlla solo `IOMatchCategory`. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **12.324.392 KiB ≈ 11,75 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
