# T27 — Localizzazione finale artefatti QEMU/Display — Report 183

**Data:** 17 novembre 2026
**Host:** macOS 26.7.3 build 25G342, MacBookPro16,1
**Target T27:** macOS 27.2.1 build 26B131, MacBookPro16,1 — i7-9750H — Radeon Pro 5300M — T2
**Modalità:** sola analisi statica read-only; nessun boot, trace, modifica, build o download.
**Vincolo spazio:** minimo 10 GiB liberi.
**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**

---

## 1. Oggetto

Questo report esegue il tentativo finale di localizzazione degli artefatti mancanti richiesto dal PROMPT 183:

1. backup Time Machine;
2. volumi esterni;
3. archivi di progetto alternativi;
4. file di log/report con riferimenti ai percorsi;
5. kernelcache e Boot.kc già presenti nel progetto.

Obiettivo: stabilire se il binario QEMU custom `-M darwin` e/o un kernelcache completo siano recuperabili senza build, download o estrazione di payload.

**Esito sintetico:** il binario QEMU custom **non è stato trovato**. Sono stati trovati **due kernelcache ARM64 completi con kext DCP/display**, ma nessun kernelcache x86_64 con display. Gli artefatti recuperati non sono sufficienti, da soli, a sbloccare il target MacBookPro16,1.

---

## 2. Dati tecnici

```text
Spazio libero host: 14 GiB
Volume host: /dev/disk1s1s1 466Gi 12Gi 14Gi 47% /
Time Machine: nessuna machine directory; POSIXError Code=1 "Operation not permitted"
Volumi montati: Kernel Debug Kit, Macintosh HD, Shared Support, <DONOR_VOLUME>
```

La directory `<VOLUME>/.timemachine` esiste, ma il contenuto non è accessibile con le autorizzazioni correnti. `tmutil listbackups` non restituisce backup utilizzabili.

---

## 3. PROVEN — ricerche eseguite

### 3.1 QEMU custom

```text
find /Volumes -maxdepth 7 -type f -name 'qemu-system-aarch64'
```

Risultato: nessun binario diverso da `/usr/local/bin/qemu-system-aarch64`.

```text
find <HOME>/Documents <HOME>/Downloads <HOME>/Projects ...
```

Risultato:

- `Documents`: nessuna directory QEMU/jprx;
- `Downloads`: nessuna directory QEMU/jprx;
- `Projects`: directory assente.

Spotlight:

```text
mdfind "kMDItemFSName == 'qemu-sptm'c || kMDItemFSName == 'qemu-system-aarch64'c"
```

Risultato: nessun percorso aggiuntivo oltre allo stock.

Riferimenti testuali nel progetto:

```text
rg -l -i --glob '*.md' --glob '*.txt' --glob '*.log' \
  'qemu-sptm|bad6336|jprx' <PROJECT_ROOT>
```

Risultato: **nessun file**.

**PROVEN:** nell’ambito interrogato non è presente il binario QEMU custom né una sua directory sorgente.
**Limite:** Time Machine non è accessibile; non è possibile dimostrare l’assenza nei backup.

### 3.2 Kernelcache e Boot.kc trovati

| File | Dimensione | Architettura | SHA-256 | Stringhe display |
|---|---:|---|---|---:|
| `Sessions/<SESSION>/work/kc/26B131__Mac18,5/kernelcache.release.Mac18,5` | 120 MB | Mach-O arm64 | `441f93f2176a794bdd93dd7d7064ac604a1bd797fd46ecbaca0b996c0086c471` | 114 |
| `Sessions/<SESSION>/work/26B131__Mac17,2/kernelcache.release.Mac17,2_3_4` | 122 MB | Mach-O arm64e | `8eed005e876f209d6cdd51a2b4ef30df13e14b34a87d60f80d091b0017c10352` | 114 |

Conteggi sul primo kernelcache:

```text
AppleDCP:                    113
AppleDisplay:                126
AppleGPUWrangler:              0
AMDRadeonX6000:                0
AppleSimpleFB:                 0
AppleGraphicsDeviceControl:    1
AGDC:                          1
```

Stringhe rappresentative:

```text
<key>com.apple.driver.AppleDCP</key>
<string>/System/Library/Extensions/AppleDCP.kext</string>
<string>/System/Library/Extensions/AppleDCPDPTXProxy.kext</string>
<string>/System/Library/Extensions/AppleDisplayCrossbar.kext</string>
<string>/System/Library/Extensions/AppleDisplayManager.kext</string>
<key>AppleDCPExpert</key>
<key>AppleDisplayConnectionManager</key>
```

**PROVEN:** i due kernelcache ARM64 contengono i kext DCP/AppleDisplay e le relative stringhe.
**PROVEN:** contengono **zero** occorrenze di `AppleGPUWrangler`, `AMDRadeonX6000` e `AppleSimpleFB`.

### 3.3 Boot.kc x86_64

| File | Dimensione | Architettura | SHA-256 | Stringhe display |
|---|---:|---|---|---:|
| `Sessions/<SESSION>/work/kc/test1/Boot.kc` | 17 MB | Mach-O x86_64 | `b3cb72d125c078bdb2becab6dbbbe03746acb356d08ed36cd5a81b1966a24ad4` | 0 |
| `Sessions/<SESSION>/work/kc/full/Boot.kc` | 17 MB | Mach-O x86_64 | `b3cb72d125c078bdb2becab6dbbbe03746acb356d08ed36cd5a81b1966a24ad4` | 0 |
| `Sessions/<SESSION>/work/kc/full/Boot.kc` | 18 MB | Mach-O x86_64 | `659dfcc17c13797c141aba282b8d2d8c0b3988771603f1bc6959bfe4ea0b02af` | 0 |
| `Sessions/<SESSION>/evidence/amd-boot.kc` | 18 MB | Mach-O x86_64 | `659dfcc17c13797c141aba282b8d2d8c0b3988771603f1bc6959bfe4ea0b02af` | 0 |

**PROVEN:** i Boot.kc x86_64 disponibili non contengono stringhe dei driver display cercati.
**PROVEN:** non è stato trovato un kernelcache x86_64 completo con AppleDCP/AMD.

### 3.4 KDK

Il volume KDK contiene solo:

```text
<VOLUME>/Kernel Debug Kit/KernelDebugKit.pkg
```

Il `Bom` di `KDK.pkg` contiene i percorsi dei kext DCP/Display/GPU, ma il payload da 1,2 GB non è stato estratto.

**PROVEN:** il KDK fornisce metadati, non binari già estratti.

---

## 4. INFERRED

1. I due kernelcache ARM64 sono associati a modelli Apple Silicon (`Mac18,5`, `Mac17,2`), non al target Intel `MacBookPro16,1`.
2. La presenza di AppleDCP/AppleDisplay conferma che i kernelcache sono completi per un guest ARM64, ma non forniscono i driver AMD Radeon X6000 richiesti dal target Intel.
3. Il kernelcache ARM64 può essere utile solo se il piano QEMU prevede un guest ARM64 distinto; non sblocca il target MacBookPro16,1.
4. Il binario QEMU custom non è presente nei percorsi accessibili; l’affermazione del riepilogo di progetto secondo cui sarebbe stato buildato resta non verificata.
5. Time Machine non accessibile impedisce di escludere backup storici.

---

## 5. UNPROVEN

1. Esistenza del QEMU custom in backup Time Machine non accessibili.
2. Hash, commit e versione effettivi del fork `jprx/qemu-sptm`.
3. Completezza e utilizzabilità dei kernelcache ARM64 per un boot QEMU.
4. Esistenza di un kernelcache x86_64 completo altrove.
5. Compatibilità dei kernelcache ARM64 con la macchina `-M darwin`.
6. Comportamento runtime di DCP/RTKit/DART e del display.
7. Relazione tra il target Intel dichiarato e l’eventuale guest ARM64.

---

## 6. Criteri di decisione

| Risultato | Esito |
|---|---|
| QEMU custom trovato | **NO** nell’ambito accessibile |
| Kernelcache ARM64 trovato | **SÌ**, due esemplari |
| Kernelcache x86_64 display trovato | **NO** |
| Kext AMD X6000 / AppleSimpleFB | **NO** |
| Log con percorso custom | **NO** |
| Time Machine | **INACCESSIBILE** |
| T27 sbloccato | **NO** |

---

## 7. Conclusione

**PROVEN:** sono stati recuperati due kernelcache ARM64 completi con AppleDCP/AppleDisplay. Non sono stati trovati il QEMU custom, un kernelcache x86_64 con display, i kext AMD X6000 o AppleSimpleFB, né riferimenti a `qemu-sptm`/`bad6336`/`jprx`.

**INFERRED:** il recupero è parziale. I kernelcache ARM64 non corrispondono al target Intel MacBookPro16,1 e non sostituiscono il QEMU custom mancante. Il filone QEMU/Display del target Intel resta bloccato.

**UNPROVEN:** l’esistenza degli artefatti in backup non accessibili e la possibilità di usare i kernelcache ARM64 per un guest ARM64 distinto.

**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**

Nessun boot, build, download, modifica di sistema o cancellazione è stato eseguito. Lo spazio libero resta circa 14 GiB.

---

## 8. Comandi eseguiti

```sh
df -h /
tmutil listbackups
ls -la <VOLUME>/.timemachine
find /Volumes -maxdepth 7 -type f -name 'qemu-system-aarch64'
find /Volumes -maxdepth 7 -type f \( -name 'kernelcache*' -o -name 'System.kc' -o -name 'Boot.kc' \)
find <HOME>/Documents <HOME>/Downloads <HOME>/Projects \
  -maxdepth 6 -type d \( -iname '*qemu*' -o -iname 'jprx' \)
mdfind "kMDItemFSName == 'qemu-sptm'c || kMDItemFSName == 'qemu-system-aarch64'c"
rg -l -i --glob '*.md' --glob '*.txt' --glob '*.log' \
  'qemu-sptm|bad6336|jprx' <PROJECT_ROOT>
find <PROJECT_ROOT> -type f \
  \( -iname 'kernelcache*' -o -iname '*System.kc' -o -iname '*Boot.kc' \)
file <kernelcache>
shasum -a 256 <kernelcache>
strings <kernelcache> | grep -icE 'AppleDCP|AppleSimpleFB|AMDRadeonX6000|AppleGraphicsDeviceControl'
```
