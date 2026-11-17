# T27 — QEMU darwin — Blocco per artefatti mancanti — Report 182

**Data:** 17 novembre 2026
**Host:** macOS 26.7.3 build 25G342, MacBookPro16,1
**Target T27:** macOS 27.2.1 build 26B131, MacBookPro16,1 — i7-9750H — Radeon Pro 5300M — T2
**Modalità:** sola analisi statica read-only; nessun boot, trace, modifica, build o download.
**Vincolo spazio:** minimo 10 GiB liberi.
**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**

---

## 1. Oggetto

Il piano concordato prevedeva, come primo passo:

```text
analisi del DeviceTree della macchina QEMU `-M darwin`
```

e, come fallback:

```text
lettura delle ultime 30–50 righe del log console QEMU
dell'ultimo boot con finestra nera e
"guest has not initialized the display yet"
```

Questo report verifica se i due artefatti siano disponibili e se il DTB `darwin` sia producibile con il QEMU installato.

**Esito sintetico:** entrambi i percorsi sono **BLOCKED** per assenza degli artefatti. Il DTB `darwin` non è stato prodotto; il log di boot non è stato trovato. È stato prodotto solo un DTB `virt` diagnostico, che non è un sostituto di `darwin`.

---

## 2. PROVEN — QEMU installato

### 2.1 Binario e versione

```text
/usr/local/bin/qemu-system-aarch64
QEMU emulator version 10.2.2
```

### 2.2 La macchina `darwin` non esiste nella build installata

```text
$ qemu-system-aarch64 -M darwin
qemu-system-aarch64: unsupported machine type: "darwin"
Use -machine help to list supported machines
```

```text
$ qemu-system-aarch64 -M help | grep -i darwin
(nessun risultato)

$ qemu-system-x86_64 -M help | grep -i darwin
(nessun risultato)
```

### 2.3 L'opzione `-dumpdtb` non è valida in questa build

```text
$ qemu-system-aarch64 -M darwin -dumpdtb .tmp/qemu-darwin.dtb ...
qemu-system-aarch64: -dumpdtb: invalid option
exit_status=1
```

La sintassi corretta per questa versione è la proprietà della macchina:

```text
-M virt,dumpdtb=FILE
```

**PROVEN:** il comando richiesto non può produrre un DTB `darwin` con il QEMU installato, sia per assenza della macchina sia per sintassi errata dell'opzione.

---

## 3. PROVEN — ricerca del QEMU custom

Sono state cercate read-only le seguenti radici candidate:

```text
<HOME>
/Applications
/opt
/usr/local
<TMP>
/tmp
```

con:

```text
find ... -maxdepth 8 -type f -name 'qemu-system-aarch64'
find ... -type d -name 'qemu-sptm'
mdfind "kMDItemFSName == 'qemu-system-aarch64'"
```

Risultato:

```text
Nessun qemu-system-aarch64 diverso da /usr/local/bin/qemu-system-aarch64
Nessuna directory qemu-sptm
Nessun risultato Spotlight aggiuntivo
```

**PROVEN:** nelle radici candidate e nell'indice Spotlight interrogato non è presente un secondo `qemu-system-aarch64`.

**Limite esplicito:** una scansione integrale di `/` è stata tentata ma è andata in timeout e non è stata completata. Il risultato non dimostra l'assenza del binario sull'intero filesystem; dimostra che non è stato trovato nell'ambito effettivamente interrogato.

---

## 4. PROVEN — DTB `virt` diagnostico

Per verificare la sola sintassi disponibile è stato generato il DTB della macchina ARM standard `virt`:

```text
qemu-system-aarch64 -M virt,dumpdtb=.tmp/qemu-virt.dtb \
  -display none -nodefaults -m 256M -serial none -monitor none
exit_status=0
```

```text
File:    .tmp/qemu-virt.dtb
Size:    1.048.576 byte
SHA-256: de5becb5311b7f83807c66a1b69386b05afee4c2835d20fd62f58452c572d1ef
Magic:   d00dfeed
```

Nodi rilevati con `strings`:

```text
linux,dummy-virt
arm,psci-1.0
arm,psci-0.2
arm,psci
memory@40000000
fw-cfg@9020000
arm,cortex-a15-gic
arm,gic-v2m-frame
arm,armv7-timer
arm,pl011
arm,pl031
arm,pl061
pci-host-ecam-generic
pcie@10000000
```

Conteggi dei termini rilevanti:

```text
apple:        0
dcp:          0
display:      0
gpu:          0
framebuffer:  0
arm-io:       0
```

**PROVEN:** il DTB `virt` è un normale `linux,dummy-virt` con GIC, PL011, PL031, GPIO e PCIe.
**PROVEN:** non contiene nodi Apple, DCP, GPU o framebuffer.
**INFERRED:** è semanticamente inutile per il percorso display di macOS e non può sostituire un DTB `darwin`.

---

## 5. PROVEN — log di boot assente

Sono stati cercati, senza avviare processi:

```text
processi QEMU attivi
file serial / stdout / stderr / qemu*.log sotto Desktop
stringa esatta:
"guest has not initialized the display yet"
```

Risultato:

```text
Nessun processo QEMU attivo
Nessun file di log QEMU con quella stringa
Nessuna occorrenza della stringa nei file accessibili
```

**PROVEN:** nell'ambito interrogato non esiste il log richiesto dal fallback.

**Limite:** non è stato possibile distinguere un file mai creato da un file cancellato; l'assenza attuale è provata, la causa no.

---

## 6. PROVEN — il progetto Stela non è la fonte del comando

Il progetto presente in:

```text
MAC OS27/STELA-MBP161-01/src/Stela/xtask/src/boot.rs
```

definisce una macchina `q35,...` e usa:

```text
qemu-system-x86_64
```

non `qemu-system-aarch64` e non `-M darwin`.

**PROVEN:** Stela non prova né spiega il comando `-M darwin`.
**PROVEN:** Stela non è una fonte del DTB `darwin`.

---

## 7. PROVEN — kernel disponibili e kernelcache assente

### 7.1 Kernel principale

```text
<TARGET_ROOT>/System/Library/Kernels/kernel
Mach-O 64-bit executable x86_64
SHA-256: 3c9317518535791503970fbec322b9bba70e91f3a233536205ccd77b047ffc83
```

### 7.2 Kernel ARM64 disponibili

La stessa directory contiene, tra gli altri:

```text
kernel.release.t6000
kernel.release.t6020
kernel.release.t6030
kernel.release.t6031
kernel.release.t6041
kernel.release.t6050
kernel.release.t8103
kernel.release.t8112
kernel.release.t8122
kernel.release.t8132
kernel.release.t8140
kernel.release.t8142
kernel.release.t8152
kernel.release.vmapple
```

Verifica del primo:

```text
kernel.release.t6000
Mach-O 64-bit executable arm64e
SHA-256: 2428a175abae43a983515e232bfe4d43b46e9f8d18db21da6b6ad780584d33a8
```

Stringhe rilevanti:

```text
/arm-io
/arm-io/sgx
/arm-io/wdt
```

Conteggi:

```text
dcp:                 0
simplefb:            0
framebuffer:         0
display-controller:  0
gpu-controller:      0
```

### 7.3 Kernelcache

```text
<TARGET_ROOT>/System/Library/Kernels/kernelcache.release
MISSING
```

**PROVEN:** non esiste il `kernelcache.release` in quella directory.
**INFERRED:** i kext completi con i driver display non sono nel `kernel.release` nudo; l'analisi statica del percorso display non può essere completata senza kernelcache o senza il binario QEMU custom.

---

## 8. INFERRED — il fork citato dalla sintesi di progetto

La sintesi di progetto riportata nella sessione Qwen afferma che T27 avrebbe usato:

```text
fork jprx/qemu-sptm
commit bad6336
base QEMU 11.1.0
macchina custom -M darwin
accelerazione TCG
build nativa macOS
hash registrati
```

Questa affermazione **non è stata verificata localmente**:

- il PDF o il riepilogo citato non è presente nel workspace;
- non è stato trovato un binario `qemu-sptm`;
- non è stata trovata una directory sorgente `qemu-sptm`;
- non è stato trovato un file di hash del binario custom.

**INFERRED:** il binario custom è stato buildato in una sessione precedente ma non è più presente sul host, oppure si trova fuori dalle radici candidate.
**UNPROVEN:** il commit, la versione, l'hash e la capacità effettiva di `-M darwin` del fork.

---

## 9. Nota architetturale

I dati locali mostrano una discrepanza da chiarire:

```text
kernel principale T27 .............. Mach-O x86_64
kernel.release.t6000 ............... Mach-O arm64e
QEMU richiesto ..................... qemu-system-aarch64
Macchina richiesta ................. -M darwin
Target dichiarato .................. MacBookPro16,1 (Intel)
```

**PROVEN:** il kernel principale T27 è x86_64; `qemu-system-aarch64` non può eseguire quel kernel.
**INFERRED:** se il target resta MacBookPro16,1, il fork ARM64 `-M darwin` non è il percorso corretto per quel kernel, a meno che non esista un distinto guest ARM64 T27.
**UNPROVEN:** quale architettura il fork `jprx/qemu-sptm` supporti e quale kernel il piano QEMU intendesse avviare.

Questa discrepanza non viene risolta in questo report e non deve essere nascosta.

---

## 10. Stato dei due passi del piano

| Passo | Artefatto | Esito | Evidenza |
|---|---|---|---|
| 1 | DTB `-M darwin` | **BLOCKED** | macchina assente; `-dumpdtb` invalido |
| 1b | DTB `virt` diagnostico | **PROVEN, non sostitutivo** | SHA `de5becb5…`; zero nodi Apple |
| 2 | log ultimo boot | **BLOCKED** | nessun processo/log/stringa trovata |
| — | QEMU custom | **NON TROVATO nell'ambito** | ricerca bounded + Spotlight |
| — | kernelcache | **ASSENTE** | directory T27 |
| — | kernel ARM64 nudo | **PROVEN disponibile** | `t6000`, SHA `2428a175…` |

---

## 11. Conclusione

**PROVEN:**

1. Il QEMU installato è lo stock 10.2.2.
2. La macchina `darwin` non è presente.
3. `-dumpdtb` non è un'opzione valida in questa build.
4. Il DTB `virt` non contiene nodi Apple/display.
5. Non è stato trovato un QEMU custom nelle radici candidate.
6. Non è stato trovato il log dell'ultimo boot.
7. Il kernel principale T27 è x86_64; esistono kernel ARM64 nudi ma non il kernelcache.
8. Lo spazio libero è compatibile con il vincolo.

**INFERRED:**

1. Il fork custom è un artefatto di una sessione precedente non più presente nel percorso interrogato.
2. Senza quel binario non è producibile il DTB `darwin`.
3. Senza kernelcache o driver display non è completabile l'analisi statica del percorso grafico.
4. Il DTB `virt` non è utilizzabile come prova del comportamento macOS.

**UNPROVEN:**

1. Esistenza del binario custom altrove nel filesystem.
2. Hash, commit e versione effettivi del fork.
3. Contenuto del DTB `darwin`.
4. Contenuto del log dell'ultimo boot.
5. Comportamento runtime di DCP/RTKit/DART e del display.
6. Relazione tra target Intel e macchina ARM64 `-M darwin`.

**Verdetto:** il primo passo e il fallback sono **BLOCKED per artefatti mancanti**. T27 resta **OPEN — 94% engineering / 32% first boot / 8% desktop**. Non viene dichiarato alcun progresso di boot o desktop.

---

## 12. Prossimo passo necessario

Per sbloccare il piano serve uno dei seguenti artefatti, con percorso verificabile:

1. il binario custom `qemu-system-aarch64` del fork `jprx/qemu-sptm`, con versione e SHA-256;
2. il comando esatto dell'ultimo boot e il percorso del log seriale/stdout/stderr;
3. il kernelcache completo usato dal guest.

Senza uno di questi, l'unica azione legittima è documentare il blocco e ridefinire il piano. Non è stata eseguita alcuna build, download, modifica di sistema o cancellazione.

---

## 13. Comandi di verifica

```sh
/usr/bin/shasum -a 256 \
  T27-QEMU-DARWIN-ARTIFACTS-182.md

/usr/bin/shasum -a 256 \
  .tmp/qemu-virt.dtb \
  <TARGET_ROOT>/System/Library/Kernels/kernel \
  <TARGET_ROOT>/System/Library/Kernels/kernel.release.t6000

file \
  <TARGET_ROOT>/System/Library/Kernels/kernel \
  <TARGET_ROOT>/System/Library/Kernels/kernel.release.t6000

df -h /
```

---

## 14. STOP

```text
Nessun boot
Nessun trace
Nessuna modifica ai file di sistema
Nessuna build
Nessun download
Nessuna cancellazione
```

**Spazio libero:** circa 14 GiB (≥ 10 GiB richiesti).

**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**
