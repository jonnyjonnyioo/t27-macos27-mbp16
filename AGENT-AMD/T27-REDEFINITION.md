# T27 — Chiusura fase esplorativa e ridefinizione

**Data:** 2026-11-17  
**Input:** R-185, R-186, STOP DeepSeek  
**Modalità:** documentale; nessun boot, trace, build, download o modifica di sistema

---

## 1. Esito

La fase esplorativa read-only di T27 è conclusa. Il target Intel **MacBookPro16,1 / macOS 27.2.1 26B131** non è raggiungibile con gli artefatti disponibili.

| Filone | Esito | Report |
|---|---|---|
| Statico AMD/AGDC | chiuso | 181 |
| QEMU/Display | chiuso | 184, 185 |
| AGDC/GPUWrangler → X6000 su 26B131 | chiuso | 186 |

**Nessun GO.** Non esiste un'ulteriore azione read-only che possa sbloccare il target Intel.

---

## 2. Cosa resta PROVEN

- Boot del kernel ARM64 fino a shell su host Intel (risultato precedente).
- `R-185`: inventario di 173 hit, 75 candidati, 58 hash, 15 SHA-256 unici.
- `R-185`: 0 QEMU custom; 0 `AppleSimpleFB`; 25G342 con AMD X6000 ma build sbagliata; 26B123 con GPUWrangler/AGDC ma zero AMD; T10 ARM64e.
- `R-186`: catena AGDC/GPUWrangler → `AMDRadeonX6000_AmdGpuWrangler` assente nella 26B123; 25G342 completa ma non 26B131.
- Mappa statica AGDC/GPUWrangler/X6000 e audit di fattibilità negativa.

Hash:

```text
R-185.md  1d9ba7477fa5440dad40503900c95eb04c7e67e4ed6b8c9b0a31574ed983bc6f
R-186.md  8df88474cb7d0faf40ea166b72f58428d44c699962f77cb921dd56c5178a9bed
```

---

## 3. Cosa NON è possibile senza autorizzazione separata

1. Usare il donor 25G342 e verificare ABI/build su 26B131.
2. Ottenere una SystemKC 26B131 completa da fonte Apple legittima.
3. Costruire un fork QEMU `-M darwin`.
4. Ripristinare Time Machine con permessi corretti.
5. Eseguire boot, trace, `kmutil`, `kextload` o installazione.

Nessuna di queste è read-only. Restano fuori dal vincolo T27 attuale.

---

## 4. Ridefinizione proposta

### T27 — chiusura documentale

T27 viene conservato come **ricerca esplorativa conclusa**: il valore prodotto è la prova di fattibilità negativa e la mappa statica, non un desktop funzionante.

### T27-A — nuovo progetto distinto

**Host:** Apple Silicon con QEMU ARM64 nativo.  
**Perché:** DCP/display reale, kernel ARM64 nativo, niente emulazione Intel TCG.  
**Stato:** piano only; nessuna esecuzione.

Preflight T27-A:

1. inventario host e QEMU ARM64;
2. kernelcache ARM64 e KDK corrispondenti;
3. DCP/RTKit/DART e periferiche virtuali;
4. boot kernel → shell;
5. display DCP;
6. WindowServer/loginwindow;
7. documento di stop e rollback.

T27-A non eredita i vincoli di spazio/read-only di T27: richiede una nuova autorizzazione esplicita.

---

## 5. Decisione consigliata

| Opzione | Costo | Margine | Raccomandazione |
|---|---|---|---|
| Chiudere T27 come ricerca esplorativa | documentale | n/a | **default** |
| Aprire T27-A su Apple Silicon | nuovo progetto | alto | **nuovo ciclo** |
| Donor 25G342 + ABI su 26B131 | build/runtime | basso | solo se autorizzato |
| SystemKC 26B131 completa | download/accesso | medio | complementare |
| Fork QEMU `-M darwin` | build | basso | solo se riaperto QEMU |
| Time Machine | permessi | medio | propedeutico |

**Raccomandazione:** chiudere T27 come ricerca esplorativa e aprire T27-A su Apple Silicon, citando R-185/R-186 come preflight obbligatorio.

---

## 6. Stato

```text
T27: fase esplorativa conclusa; nessun GO
T27-A: proposta, non avviata
Nessun boot/build/download/modifica
Spazio libero: 14 GiB
```

Il presente documento non modifica il sistema e non autorizza alcuna delle opzioni 1–5.

---

**SHA-256 del corpo (prima di questa riga):** `28fbfed9af219c8e2983d6d28f753d87a6695d0fc9ac0ff37d971e9bec1cc2b4`
