# T27 — INTEGRAZIONE / AGENT-08

**Ruolo:** integratore indipendente.  
**Metodo:** ricezione dei sette rapporti di dominio, controllo delle fonti T25/T26, risoluzione delle contraddizioni, matrice unica, gate A–H.  
**Mode:** read-only; nessuna KC, nessun boot, nessuna installazione, nessuna modifica EFI/NVRAM/T2.  
**Stato:** **OPEN — nessun GO; progetto non chiuso.**

---

## 1. Input e regola di accettazione

Sono stati accettati solo fatti con:

- percorso locale;
- build e architettura;
- hash quando disponibile;
- test effettivamente eseguito;
- limite esplicito.

Non sono stati accettati come fatti:

- “AppleHIDTransport funziona”;
- “AMD è compatibile perché gli ID PCI sono presenti”;
- “T2 Linux prova macOS”;
- “la root 25G342 sostituisce 26B131”;
- “la BootKC T3 è una base SystemKC”;
- “HAO funziona su MBP9,2, quindi funziona su MBP16,1”.

---

## 2. Sintesi dei sette agenti

| Agente | Dominio | Conclusione | Stato |
|---|---|---|---|
| 01 | Kernel Collections | kernel 26B131 presente; BootKC T3 kernel-only; SystemKC assente | **BLOCKED** |
| 02 | Donor | root/KDK 25G342 presenti; installer 25G342 assente; root2 25G325 | **BLOCKED** |
| 03 | ACPI/PCI/Boot | ACPI/APIC assenti; PCI/storage solo metadati o build errata; launchd non raggiunto | **BLOCKED** |
| 04 | AMD Navi14 | kext donor 25G325/7.1.8; MTL 25G-series recuperato, bundle incompleto; nessun AMD 26B131; eDP/Metal non provati | **BLOCKED** |
| 05 | T2/HID | HIDTransport ARM-only; VHCI/BCE 26B131 assenti; TopCase donor 25G325 | **BLOCKED** |
| 06 | EFI/Boot | boot.efi 26B131 assente; OpenCore/SMBIOS/T2 Secure Boot/NVRAM non verificati | **BLOCKED** |
| 07 | Desktop | WindowServer/loginwindow/Finder/Dock non raggiungibili; MBP9,2 non è prova | **BLOCKED** |

Nessun agente ha prodotto un artefatto avviabile. La convergenza è unanime sui gate bloccanti.

---

## 3. Contraddizioni e risoluzione

### 3.1 Root2: 865 vs 875 primari

- T26 report conteneva `865 primari` in una riga descrittiva.
- T25 `T25-ROOT2-INVENTORY.csv` e T25 audit riportano **875 primari** su 905 bundle.
- **Risoluzione:** vale **875**; 865 era un refuso descrittivo, non un dato di inventario. T27 usa 875.

### 3.2 `AppleHIDTransport`: arm64e-only vs arm64/arm64e

- T25 lo descrive `arm64e-only`.
- T26 riporta `arm64/arm64e` per il KDK.
- **Risoluzione:** la differenza riguarda le slice osservate; **non esiste una slice x86_64**. Lo stato resta `ARCHITETTURA ERRATA` per il target Intel. Non è una contraddizione sostanziale.

### 3.3 TopCase “presente” vs “assente”

- T25 lo trova universale in **root2 25G325**.
- T26 lo trova solo come metadato nel **target 26B131** e con build 26B116 nel KDK.
- **Risoluzione:** non è una contraddizione: è la differenza tra codice donor e componente target. Il percorso è **plausibile nel donor**, **non disponibile in 26B131**.

### 3.4 KDK 26B123 “KC completa” vs KDK 26B131 “0 KC”

- Liberator costruisce una KC 26B123 da KDK + `.src`/`.delta`.
- Il KDK 26B131 non contiene `.kc`.
- **Risoluzione:** build e pipeline diverse. 26B123 non è una prova 26B131; il KDK 26B131 resta debug e non release.

### 3.5 “Primo boot 30%” vs “32%”

- T25: 30%; T26: 32%.
- **Risoluzione:** è un indice documentale, non una misura di boot. T26 ha migliorato la closure, non ha avviato nulla. T27 mantiene **32%** e non lo aumenta.

### 3.6 AMD “presente” vs “compatibile”

- root2 contiene 7 bundle AMD x86_64/7.1.8.
- target/KDK 26B131 non li contengono.
- **Risoluzione:** “codice donor presente” ≠ “AMD 26B131 compatibile”. Lo stato corretto è **BLOCKED** per il target.

### 3.7 KDK 25G342 presente vs installer assente

- Il KDK 25G342 è presente e Apple-signed.
- L’installer 25G342 completo è assente.
- **Risoluzione:** non è una contraddizione; il KDK è debug, non installer. Il donor resta insufficiente.

---

## 4. Matrice unica

La matrice completa è `T27-DEPENDENCY-MATRIX.csv` (50 righe). Sintesi per gate:

| Gate | Componenti critici | Stato | Motivo |
|---|---|---|---|
| A — BootKC | kernel, KPI, ACPI/APIC, IOPCI/IOACPI, APFS, USB | **BLOCKED** | T3 kernel-only; ACPI/APIC assenti; resto metadati/26B116 |
| B — SystemKC | ACPI/APIC, storage, USB/T2, AMD, audio/rete | **BLOCKED** | manca BootKC base e repository 26B131 |
| C — kernel | kernel 26B131 | **UNPROVEN** | hash/UUID validi, nessun boot |
| D — launchd | KC, ACPI/PCI, APFS, userspace | **BLOCKED** | nessuna catena boot |
| E — display | AMD X6000, IOGraphics, IOSurface, eDP/gMux | **BLOCKED** | AMD 26B131 assente; nessun test |
| F — input | VHCI/BCE, TopCase, HIDKeyboard/Multitouch | **BLOCKED** | VHCI/BCE 26B131 assenti |
| G — WindowServer | Metal, IOSurface, IOGraphics, AMD | **BLOCKED** | nessun runtime grafico; MTL 25G-series recuperato, non 26B131 |
| H — desktop | loginwindow, Finder, Dock, audio/rete/BT/sleep | **BLOCKED** | dipende da E/F/G |

---

## 5. Cosa è costruibile

### Oggi

- **Nessuna** BootKC/SystemKC completa.
- **Nessuna** EFI installabile.
- Solo documentazione, closure, manifest e test read-only.

### In teoria, con set 26B131 completo

1. BootKC 26B131 da kernel + repository + KDK registrato.
2. SystemKC 26B131 prelinked contro la BootKC.
3. EFI isolata con `boot.efi` 26B131.
4. Primo boot controllato.

### Non costruibile con i materiali attuali

- display interno;
- input T2 interno;
- WindowServer/Metal;
- desktop;
- installer completo 25G342;
- boot chain 26B131.

---

## 6. Gate A–H

| # | Domanda | Stato | Motivo sintetico |
|---|---|---|---|
| A | Creare BootKC 26B131? | **BLOCKED** | T3 kernel-only; set 26B131 incompleto |
| B | Creare SystemKC 26B131? | **BLOCKED** | manca BootKC base e repository |
| C | Avviare il kernel? | **UNPROVEN** | kernel valido, nessun boot |
| D | Arrivare a launchd? | **BLOCKED** | ACPI/PCI/storage e KC mancanti |
| E | Display interno? | **BLOCKED** | AMD/eDP/gMux non disponibili |
| F | Tastiera/trackpad? | **BLOCKED** | VHCI/BCE/TopCase 26B131 mancanti |
| G | WindowServer? | **BLOCKED** | Metal/AMD/display non verificati |
| H | Desktop? | **BLOCKED** | dipende da D–G |

**Nessun GO è emesso.**

---

## 7. Handoff finale

L’integratore raccomanda:

1. non avviare la fase di installazione;
2. non usare 25G342 come target;
3. chiudere la closure 26B131 con materiali tracciati;
4. eseguire il test read-only di diff ID/UUID/KPI;
5. solo dopo, progettare una build in ambiente 26B131 isolato.

Il progetto resta **OPEN**.
