# T27 — OOB AGDC — Verifica finale di coerenza e chiusura del filone statico — Report 181

**Data:** 17 novembre 2026
**Sistema:** macOS 26.7.3 build 25G342, MacBookPro16,1
**Modalità:** sola analisi statica; nessun boot, trace, modifica, build o download.
**Vincolo spazio:** minimo 10 GiB liberi; nessun file eliminabile proposto.
**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**

---

## 1. Oggetto

Questo report non introduce nuove scansioni. Verifica la coerenza dei quattro report consecutivi sul filone AMD/AGDC:

```text
Report 177  Call site Apple e ricerca del selettore 3
Report 178  SkyLight nella dyld shared cache
Report 179  Dispatch CGXUpdateDesktop e API private
Report 180  WindowServer executable
```

Obiettivo:

1. verificare che gli hash dichiarati corrispondano ai file;
2. verificare che le conclusioni dei quattro report siano compatibili;
3. identificare esplicitamente le affermazioni superate da report successivi;
4. separare i fatti statici dai limiti runtime;
5. formulare la conclusione motivata sul filone statico AMD/AGDC.

---

## 2. Hash dei report

```text
T27-OOB-AGDC-APPLE-CALLSITES-177.md
dfb5ea9b3050babe5d4633b25c4d4a14161c18ea52d1881148ebb7bd8a44827b
361 righe

T27-OOB-AGDC-SKYLIGHT-178.md
93c874ee35e441e37cf3f00eb9f06c417eb8bbc6c63c9d28a90aafe766db4902
453 righe

T27-OOB-AGDC-DISPATCH-179.md
a3f14a1407066431e627db40538d058d2276eec7ac9eaa939f8fc18706bd9cc5
653 righe

T27-OOB-AGDC-WINDOWSERVER-180.md
4e687fc38786f2bc059ade53ee54a3f4cc6241d6a1f35ca061334a57b0fda104
384 righe
```

**PROVEN:** i quattro hash sono stati ricalcolati con `/usr/bin/shasum -a 256` e corrispondono ai valori dichiarati.
**PROVEN:** i quattro report coprono 1851 righe complessive.

---

## 3. Hash degli artefatti

```text
SkyLight
1e8ead0ceaf2b8a2fe2c167fa299142939ec579f9df60ab30dae8a5c513bea56
.tmp/a178/SkyLight

CoreGraphics
34a2683052af18ae68ae66d6f6de08ee5b0111277627d0c9f67bd16d8174b6e0
.tmp/a179/CoreGraphics

CoreDisplay
d1d038dd7f88191d47db381ce776f7837d12408439d19f279c393c847c7c64fc
.tmp/a73/01_CoreDisplay

WindowServer x86_64
3a27afe3a84561dad412d917764d571f9915f85e4925e9a9a57900b6edb9e110
.tmp/WindowServer.x86_64
```

Hash di sistema:

```text
WindowServer universale
804cf101ec081e4f07946acaca35d694d8e9d48b25a12c5b4e1a6ce348c9000d
/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/Resources/WindowServer

SystemKernelExtensions.kc
b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7
/System/Library/KernelCollections/SystemKernelExtensions.kc
```

**PROVEN:** gli hash degli artefatti corrispondono a quelli usati nei Report 177–180.
**PROVEN:** il file WindowServer universale e la slice x86_64 hanno hash distinti ma coerenti: la slice è il sotto-binario effettivamente analizzato.

---

## 4. Catena logica consolidata

```text
WindowServer (loader)
  importa solo _SLXServer
  nessun import IOKit
  nessun dlsym/dlopen
  nessuna stringa AGDC
        |
        v
_SLXServer (SkyLight)
        |
        v
CoreDisplayManager::set_debug_options
        |
        v
WSAGDCSetDebugOptions (CoreDisplay)
        |
        v
gWSCallbacks + 0x628
        |
        v
CGXUpdateDesktop (SkyLight)
  95 byte
  nessun IOKit/AGDC
        |
        v
*0xe8 -> CoreDisplayManager::create_overall_region()
        |
        v
CGXCreateDisplayRegion (CoreDisplay)
  CGRegion* / session data
  nessun IOKit/AGDC
```

### 4.1 Punti verificati

| Elemento | Indirizzo / simbolo | Fonte | Esito |
|---|---|---|---|
| WindowServer import non-libSystem | `_SLXServer` | 177, 180 | **PROVEN unico** |
| WindowServer call site grafico | `0x1000006cc -> _SLXServer` | 180 | **PROVEN unico** |
| SkyLight `IOConnectCallMethod` | — | 178 | **0** |
| SkyLight `IOConnectCallStructMethod` | — | 178 | **0** |
| SkyLight `IOConnectCallScalarMethod` | 2 siti | 178 | selettori `0x1c90`, `0` |
| SkyLight `AppleGraphicsDeviceControl` | — | 178 | **0 occorrenze** |
| `WSAGDCSetDebugOptions` | `0x7ff80539e038` | 178 | tail-jump a `gWSCallbacks+0x628` |
| `CGXUpdateDesktop` | `0x7ff80930258f` | 179 | 95 byte, senza IOKit/AGDC |
| vtable `CoreDisplayManager` | `0x7ff840ad2ea0` | 179 | **PROVEN** |
| slot `+0xe8` | `0x7ff809508686` | 179 | `create_overall_region()` |
| `CGXCreateDisplayRegion` | `0x7ff80541cf8a` | 179 | CoreDisplay, solo CGRegion/session |
| `WSCDInitializeVtable.callbacks` | 215 entry | 179 | nessun target AGDC |
| CoreGraphics `CGXUpdateDesktop` | — | 179 | **assente** |
| CoreGraphics stringhe AGDC | — | 179 | **0** |

**PROVEN:** la catena è continua e tutti gli indirizzi sono coerenti tra i report.
**PROVEN:** nessun passaggio della catena contiene un invio AGDC selector 3.

---

## 5. Coerenza tra i report

### 5.1 Report 177 -> Report 178

Il Report 177 dichiarava:

```text
SkyLight non presente come Mach-O standalone
call site SkyLight non enumerabili
UNPROVEN/BLOCKED
```

Il Report 178 ha estratto SkyLight dalla dyld shared cache e lo ha analizzato:

```text
SkyLight
SHA-256 1e8ead0c…
0 IOConnectCallMethod
0 IOConnectCallStructMethod
2 IOConnectCallScalarMethod
0 AppleGraphicsDeviceControl
```

**Esito:** nessuna contraddizione. Il BLOCKED del Report 177 è **superato** dal Report 178. La conclusione del 177 ("non verificabile") era corretta rispetto ai file allora disponibili; il 178 ha rimosso il limite.

### 5.2 Report 178 -> Report 179

Il Report 178 aveva identificato:

```text
WSAGDCSetDebugOptions
  -> gWSCallbacks+0x628
  -> CGXUpdateDesktop
```

e aveva lasciato UNPROVEN il virtual dispatch:

```text
call *0xe8(%rcx)
```

Il Report 179 ha risolto:

```text
vtable 0x7ff840ad2ea0
slot +0xe8 -> 0x7ff809508686
CoreDisplayManager::create_overall_region()
-> CGXCreateDisplayRegion
```

**Esito:** nessuna contraddizione. Il 179 **chiude** l'UNPROVEN principale del 178.

### 5.3 Report 177/178 -> Report 180

Il Report 177 aveva già osservato che WindowServer importa solo `_SLXServer`. Il Report 180 ha riesaminato l'eseguibile e ha confermato:

```text
23 import totali
unico non-libSystem: _SLXServer
0 import IOConnectCall*
0 IOServiceOpen
0 dlsym/dlopen
0 stringhe AGDC
unico call site grafico: 0x1000006cc -> _SLXServer
```

**Esito:** nessuna contraddizione; il 180 rende esplicito e definitivo il ruolo di WindowServer come loader.

### 5.4 Entitlement

Il Report 178 ha rilevato:

```text
com.apple.private.gpuwrangler = true
```

Il Report 180 ha ribadito che l'entitlement non crea un call site AGDC.

**Esito:** nessuna contraddizione. L'entitlement autorizza il processo; non aggiunge codice o simboli IOKit al binario.

### 5.5 Spazio

I report riportano valori leggermente diversi:

```text
177: 13,31 GiB
178: 13,72 GiB
179: ~14 GiB
180: ~14 GiB
```

**Esito:** variazione fisiologica dello spazio libero, non una contraddizione.

---

## 6. Affermazioni superate o da interpretare

| Affermazione | Report | Stato attuale |
|---|---|---|
| SkyLight non è disponibile / BLOCKED | 177 | **superata** dal 178 |
| Call site SkyLight non enumerabili | 177 | **superata** dal 178 |
| `WSAGDCSetDebugOptions` target non verificato | 177/178 | **risolto** dal 178/179 |
| `*0xe8` virtual dispatch UNPROVEN | 178 | **risolto** dal 179 |
| WindowServer possibile client indiretto | 177 | **escluso** dal 180 per il binario |
| CoreDisplay usa AGDC solo 1/0x10 | 177 | **confermato** |
| IOPresentment non usa selector 3 | 177 | **confermato** |
| CoreGraphics non contiene AGDC | 179 | **confermato** |

**PROVEN:** non esiste una contraddizione logica tra i report; esistono solo superamenti progressivi di limiti dichiarati.

---

## 7. Conclusione sul filone statico AMD/AGDC

### 7.1 Cosa è dimostrato staticamente

Nei componenti esaminati:

```text
WindowServer
SkyLight
CoreDisplay
CoreGraphics
IOPresentment
```

non esiste un percorso statico che invii:

```text
AppleGraphicsDeviceControl
  con selettore 3
  con buffer di 4 byte contenente il bit 0x2
```

Le uniche chiamate AGDC osservate sono:

```text
CoreDisplay:
  selettore 1   (inizializzazione)
  selettore 0x10 (display policy)

IOPresentment:
  0x711, 0x713, 0x921, 0x925, 0x988, 0x980
```

Il selettore 3 non compare in nessuno dei call site AGDC esaminati.

### 7.2 Cosa significa per il compatibility layer

Il layer client-only non può contare su un attore Apple già esistente che invii AGDC selector 3. I percorsi disponibili sono:

```text
WindowServer -> _SLXServer -> SkyLight
  -> aggiornamento desktop / debug options
  -> nessun AGDC selector 3

CoreDisplay -> AGDC
  -> selettori 1 / 0x10
  -> nessun selector 3

IOPresentment -> AGDC
  -> capability / pipeline / SDP
  -> nessun selector 3
```

**PROVEN:** il percorso `WSAGDCSetDebugOptions -> CGXUpdateDesktop` non è un ponte verso AGDC selector 3.
**PROVEN:** WindowServer non è un client AGDC diretto.
**INFERRED:** il selettore 3 non è usato dalle API AGDC osservate nei componenti Apple esaminati.

### 7.3 Cosa non è dimostrato

Restano fuori dalla dimostrazione statica:

1. una modifica runtime di `gWSCallbacks` o di una function pointer dopo l'inizializzazione;
2. API private in binari non estratti o non esaminati;
3. un percorso che richieda un attore diverso da WindowServer, CoreDisplay, SkyLight, CoreGraphics o IOPresentment;
4. il comportamento runtime del guest QEMU/TCG e dei driver DCP/RTKit;
5. il first boot e il desktop, che restano i blocchi principali di T27 e non dipendono dalla sola ricerca AGDC.

Questi punti sono **UNPROVEN**, non “inesistenti”. La loro assenza di evidenza non equivale a una prova di assenza.

---

## 8. Verdetto finale del filone statico

| Domanda | Esito |
|---|---|
| WindowServer è un client AGDC diretto | **NO, PROVEN** |
| SkyLight invia AGDC selector 3 | **NO, PROVEN** |
| `CGXUpdateDesktop` raggiunge AGDC selector 3 | **NO, PROVEN** |
| `CGXCreateDisplayRegion` raggiunge AGDC selector 3 | **NO, PROVEN** |
| CoreDisplay usa AGDC selector 3 | **NO, PROVEN** |
| IOPresentment usa AGDC selector 3 | **NO, PROVEN** |
| CoreGraphics contiene AGDC | **NO, PROVEN** |
| La tabella `gWSCallbacks` contiene target AGDC | **NO, PROVEN nella tabella statica** |
| Esiste un attore Apple noto che invii il 3 | **NO, nei componenti esaminati** |
| Esiste un percorso statico completo verso il 3 | **NO, non trovato** |
| Resta un percorso runtime non osservato | **SÌ, UNPROVEN** |
| T27 è completo | **NO — OPEN 94/32/8** |

**Conclusione:** il filone statico AMD/AGDC è **chiuso** per i componenti Apple esaminati. Non esiste un client Apple noto che invii AGDC selector 3 con il buffer richiesto; l'unico wrapper AGDC disponibile, `WSAGDCSetDebugOptions`, termina in un aggiornamento desktop e non in un comando AGDC. WindowServer è un loader minimale e non un client IOKit.

Questa conclusione **non chiude T27**: chiude solo la ricerca statica sul selettore 3. T27 resta OPEN al 94% engineering / 32% first boot / 8% desktop, perché il primo boot e il desktop dipendono da DCP, RTKit, DART, interrupt e dal comportamento runtime del guest, non dalla presenza di un call site AGDC.

---

## 9. Giudizio sulla matrice PROVEN / INFERRED / UNPROVEN

### PROVEN

1. I quattro report e i loro hash sono coerenti.
2. Gli hash degli artefatti corrispondono.
3. WindowServer importa solo `_SLXServer` da SkyLight.
4. WindowServer non importa IOKit e non usa `dlsym`/`dlopen`.
5. SkyLight non ha `IOConnectCallMethod`/`IOConnectCallStructMethod` e non contiene `AppleGraphicsDeviceControl`.
6. `CGXUpdateDesktop` è in SkyLight, non in CoreGraphics.
7. Il dispatch `*0xe8` è `create_overall_region()`.
8. `CGXCreateDisplayRegion` è in CoreDisplay e non usa IOKit/AGDC.
9. La tabella statica `WSCDInitializeVtable.callbacks` non contiene target AGDC.
10. Non esiste un percorso statico completo verso AGDC selector 3 nei componenti esaminati.

### INFERRED

1. Il selettore 3 non è usato dalle API AGDC osservate nei componenti Apple esaminati.
2. `WSAGDCSetDebugOptions` è un hook di aggiornamento desktop, non un comando AGDC.
3. WindowServer delega tutta la logica grafica a SkyLight.

### UNPROVEN

1. Modifica runtime di function pointer o callback table.
2. API private in binari non estratti.
3. Comportamento runtime del guest QEMU/TCG.
4. Percorso DCP/RTKit/DART per il first boot e il desktop.
5. Qualsiasi conclusione sul desktop che non sia stata verificata con boot o trace.

---

## 10. Comandi di verifica

```sh
shasum -a 256 \
  T27-OOB-AGDC-APPLE-CALLSITES-177.md \
  T27-OOB-AGDC-SKYLIGHT-178.md \
  T27-OOB-AGDC-DISPATCH-179.md \
  T27-OOB-AGDC-WINDOWSERVER-180.md

wc -l \
  T27-OOB-AGDC-APPLE-CALLSITES-177.md \
  T27-OOB-AGDC-SKYLIGHT-178.md \
  T27-OOB-AGDC-DISPATCH-179.md \
  T27-OOB-AGDC-WINDOWSERVER-180.md

shasum -a 256 \
  .tmp/a178/SkyLight \
  .tmp/a179/CoreGraphics \
  .tmp/a73/01_CoreDisplay \
  .tmp/WindowServer.x86_64

shasum -a 256 \
  /System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/Resources/WindowServer \
  /System/Library/KernelCollections/SystemKernelExtensions.kc

df -h /
```

Nessuna nuova scansione di codice; solo verifica di hash, conteggi e coerenza testuale.

---

## 11. Spazio e STOP

```text
df -h /
/dev/disk1s1s1   466Gi   12Gi   14Gi   47%   /
```

Spazio libero: **circa 14 GiB** (≥ 10 GiB richiesti).

**STOP rispettato:** nessun boot, trace, modifica ai file di sistema, build o download. Nessuna cancellazione. Nessun file eliminabile proposto.

**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**

**Filone statico AMD/AGDC:** **CHIUSO nei componenti esaminati.**
