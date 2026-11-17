# T27 — Chiusura definitiva filone QEMU/Display — Report 184

**Data:** 17 novembre 2026
**Host:** macOS 26.7.3 build 25G342, MacBookPro16,1
**Target T27:** macOS 27.2.1 build 26B131, MacBookPro16,1 — i7-9750H — Radeon Pro 5300M — T2
**Modalità:** sola analisi statica read-only; nessun boot, trace, modifica, build o download.
**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**

---

## 1. Oggetto

Questo report chiude formalmente il filone **QEMU/Display** aperto con il tentativo di usare la macchina custom `-M darwin`.

La chiusura si basa su:

- Report 182: blocco per artefatti QEMU assenti;
- Report 183: localizzazione finale e recupero di due kernelcache ARM64;
- analisi delle stringhe DeviceTree dei kernelcache;
- verifica dei Boot.kc x86_64;
- ricerche su volumi, archivi, Spotlight e log;
- accesso Time Machine non disponibile.

---

## 2. PROVEN

### 2.1 QEMU custom

```text
/usr/local/bin/qemu-system-aarch64
QEMU emulator version 10.2.2
```

- `-M darwin` non esiste nella build stock.
- `-dumpdtb` non è un’opzione valida.
- Nessun secondo `qemu-system-aarch64` trovato in `/Volumes`, `Documents`, `Downloads`, Spotlight.
- Nessun riferimento `qemu-sptm`, `bad6336` o `jprx` nei log del progetto.
- Il fork custom non è quindi disponibile nei percorsi accessibili.

### 2.2 Kernelcache ARM64 recuperati

| File | Dimensione | Architettura | SHA-256 |
|---|---:|---|---|
| `Sessions/<SESSION>/work/kc/26B131__Mac18,5/kernelcache.release.Mac18,5` | 120 MB | Mach-O arm64 | `441f93f2176a794bdd93dd7d7064ac604a1bd797fd46ecbaca0b996c0086c471` |
| `Sessions/<SESSION>/work/26B131__Mac17,2/kernelcache.release.Mac17,2_3_4` | 122 MB | Mach-O arm64e | `8eed005e876f209d6cdd51a2b4ef30df13e14b34a87d60f80d091b0017c10352` |

Conteggi display sul primo kernelcache:

```text
AppleDCP:                    113
AppleDisplay:                126
AppleGPUWrangler:              0
AMDRadeonX6000:                0
AppleSimpleFB:                 0
AppleGraphicsDeviceControl:    1
AGDC:                          1
```

Stringhe DeviceTree estratte:

```text
mac185_dt_strings.txt   2023 righe   101193 byte
SHA-256 54c697020bbfa25bbe402e029154b0bd1cbbcbabc6a06966d35722769f2b8b72

mac17_dt_strings.txt    2008 righe   100390 byte
SHA-256 32ef2ef54f5d5a72960be1956872fde7def1d86e39fd4680e52093c88cb0ffdb
```

Le stringhe contengono DART, DCP, framebuffer, display-controller e messaggi quali:

```text
"DCP standalone on this platform is not supported"
"missing DCP_CONTROLS mapping"
"'arm-io' EDT node not found."
```

### 2.3 Boot.kc x86_64

| File | Dimensione | SHA-256 | Stringhe display |
|---|---:|---|---:|
| `Sessions/<SESSION>/work/kc/test1/Boot.kc` | 17 MB | `b3cb72d125c078bdb2becab6dbbbe03746acb356d08ed36cd5a81b1966a24ad4` | 0 |
| `Sessions/<SESSION>/work/kc/full/Boot.kc` | 17 MB | `b3cb72d125c078bdb2becab6dbbbe03746acb356d08ed36cd5a81b1966a24ad4` | 0 |
| `Sessions/<SESSION>/work/kc/full/Boot.kc` | 18 MB | `659dfcc17c13797c141aba282b8d2d8c0b3988771603f1bc6959bfe4ea0b02af` | 0 |
| `Sessions/<SESSION>/evidence/amd-boot.kc` | 18 MB | `659dfcc17c13797c141aba282b8d2d8c0b3988771603f1bc6959bfe4ea0b02af` | 0 |

**PROVEN:** i Boot.kc x86_64 disponibili non contengono AppleDCP, AppleSimpleFB, AMDRadeonX6000 o AppleGraphicsDeviceControl.

### 2.4 Altri limiti

- Time Machine: `No machine directory found for host`; `POSIXError Code=1 "Operation not permitted"`.
- KDK: solo `Bom`/`PackageInfo`; payload da 1,2 GB non estratto.
- Nessun kernelcache x86_64 completo con driver display.
- Nessun boot eseguito.

---

## 3. INFERRED

1. I kernelcache ARM64 sono completi per un guest Apple Silicon, ma non per il target Intel MacBookPro16,1.
2. AppleDCP/AppleDisplay descrivono la catena DCP/DART ARM64; non forniscono i driver AMD Radeon X6000 richiesti dal target.
3. L’assenza del QEMU custom impedisce di generare il DTB `-M darwin` e di avviare il guest previsto.
4. Il filone QEMU/Display non è recuperabile con i soli artefatti presenti.
5. Il target Intel e un eventuale guest ARM64 sono due percorsi distinti e non vanno confusi.

---

## 4. UNPROVEN

1. Esistenza del QEMU custom in backup Time Machine non accessibili.
2. Hash, commit e versione effettivi del fork `jprx/qemu-sptm`.
3. Completezza e utilizzabilità dei kernelcache ARM64 per un boot QEMU.
4. Esistenza di un kernelcache x86_64 completo altrove.
5. Comportamento runtime di DCP/RTKit/DART e del framebuffer.
6. Compatibilità con un host Linux/T2 alternativo.

---

## 5. Decisione

| Domanda | Esito |
|---|---|
| QEMU custom disponibile | **NO, nei percorsi accessibili** |
| Kernelcache ARM64 disponibile | **SÌ, due esemplari** |
| Kernelcache x86_64 con display | **NO** |
| AMD X6000 / AppleSimpleFB | **NO** |
| Time Machine accessibile | **NO** |
| DTB `-M darwin` producibile | **NO** |
| Display guest inizializzabile | **NO, con gli artefatti attuali** |
| T27 completo | **NO — OPEN 94/32/8** |

---

## 6. Conclusione

**PROVEN:** il filone QEMU/Display è bloccato dalla mancanza del binario QEMU custom `-M darwin` e di un kernelcache x86_64 con driver display/AMD. Sono stati recuperati solo kernelcache ARM64 con DCP/DART, non applicabili al target Intel.

**INFERRED:** non è tecnicamente possibile emulare o inizializzare il display guest rispettando i vincoli T27 attuali (nessuna build, nessun download, spazio limitato).

**UNPROVEN:** il comportamento con artefatti mancanti o su un host alternativo.

**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**
**Filone QEMU/Display:** **CHIUSO per impossibilità tecnica con gli artefatti disponibili.**

---

## 7. Prossimo passo

Qwen indica due opzioni:

1. audit documentale completo dei Report 1–184;
2. ridefinizione formale degli obiettivi del progetto T27.

Nessuna delle due implica boot, build, download o modifiche di sistema.

---

## 8. Comandi e verifiche

```sh
sha256sum T27-QEMU-DISPLAY-CLOSURE-184.md
shasum -a 256 T27-QEMU-DISPLAY-CLOSURE-184.md

shasum -a 256 \
  Sessions/<SESSION>/work/kc/26B131__Mac18,5/kernelcache.release.Mac18,5 \
  Sessions/<SESSION>/work/26B131__Mac17,2/kernelcache.release.Mac17,2_3_4

wc -l -c mac185_dt_strings.txt mac17_dt_strings.txt
shasum -a 256 mac185_dt_strings.txt mac17_dt_strings.txt
```

---

## 9. STOP

```text
Nessun boot
Nessun trace
Nessuna modifica ai file di sistema
Nessuna build
Nessun download
Nessuna cancellazione
```

Spazio libero: circa 14 GiB.
