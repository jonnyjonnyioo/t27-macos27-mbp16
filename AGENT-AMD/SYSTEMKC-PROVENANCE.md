# T27 — AGENT-AMD — SYSTEMKC PROVENANCE CHAIN

**Scope:** verificare se i **172 file** di `<SESSION>/work/systemkc-all` sono effettivamente gli input della `SystemKernelExtensions.kc` 25G342, senza dedurlo dalla sola presenza dei componenti AMD.  
**Modalità:** sola lettura; nessuna estrazione, ricostruzione KC, modifica o boot.  
**Esito:** il pool `systemkc-all` ha **172 file** e contiene **28 componenti AMD**, inclusi i sei della catena; `tahoe-bootkc-all` ha **204 file** e **0 AMD**. L’inclusione dei sei moduli nella SystemKC 25G342 è ora **PROVEN** dagli `LC_FILESET_ENTRY` della collezione; l’origine dell’intero pool resta **INFERRED** perché manca un log di estrazione per-pool. `DARWIN27` è stato corretto con la prova materiale.

> **Correzione 16 Nov 2026:** il pool contiene **28 AMD**, non sei; i sei elencati sono il sottoinsieme rilevante. Vedi `SYSTEMKC-INCLUSION-EVIDENCE.md`.

---

## 1. Prova materiale

| Pool | File | Contenuto AMD |
|---|---:|---|
| `work/tahoe-bootkc-all` | **204** | **0** |
| `work/systemkc-all` | **172** | **6** |
| `work/staged` | **376** | unione/overlay, non collezione |

I **28 AMD** in `systemkc-all` (sottoinsieme rilevante di sei):

```text
com.apple.kext.AMDSupport
com.apple.kext.AMDRadeonX6000Framebuffer
com.apple.kext.AMDRadeonX6000HWServices
com.apple.kext.AMDRadeonServiceManager
com.apple.kext.AMDRadeonX6000
com.apple.kext.AMDRadeonX6100HWLibs
```

`X6100HWLibs` in `systemkc-all`:

| Campo | Valore |
|---|---|
| Byte | 16.985.840 |
| SHA-256 | `e521d3cce8f9bb027642897fed8754ff4d9ef66dd08a8d13ab318e0c2db01bb5` |
| UUID | `533D1262-BE83-3507-B48A-FDB91C9D8793` |
| Arch | x86_64 |

Nessuno dei **28 AMD** è in `tahoe-bootkc-all`.

---

## 2. Documenti probatori

| Documento | SHA-256 | Contenuto |
|---|---|---|
| `TAHOE-DONOR-INTEGRATION.md` | `8e0153ed…` | BootKC 67.600.384 B / 204; SystemKC 369.213.440 B / 172; pool totale 376 |
| `BUILD-REPORT.md` | `d99c9f13…` | passo 2 “BootKC extract → 204”; passo 3 “SystemKC extract → 172” |
| `donor-source-kc.txt` | `1779bebb…` | SHA BootKC `9bb053cf…`; SHA SystemKC `b4b618bf…` |
| `DARWIN27-TAHOE-COMPATIBILITY.md` | corretto | conteneva “SystemKC non estratte”; ora corretto |
| `SHA256-MANIFEST.txt` | `059bd72d…` | esclude esplicitamente `systemkc-all`, `staged`, `tahoe-bootkc-all` |

### 2.1 Cosa dicono i conteggi

- `tahoe-bootkc-all` = **204**, esattamente il numero BootKC documentato.
- `systemkc-all` = **172**, esattamente il numero SystemKC documentato.
- `staged` = **376** = 204 + 172: è l’unione dei due pool, non una terza collezione.

Questa corrispondenza è forte, ma **non è un log**. Non esiste un file di comando con stdout/stderr che associ `systemkc-all` a `SystemKernelExtensions.kc`.

---

## 3. Ricerca di log, manifest e mappe

| Ricerca | Esito |
|---|---|
| `rg`/`grep` di `systemkc-all`, `SystemKernelExtensions`, `kcditto`, `kmutil inspect`, `KernelCollection` | nessun log di estrazione per-pool |
| `kmutil inspect` | **nessun output acquisito** |
| `kcditto` | **nessun output acquisito** |
| mappa di inclusione per-kext | **assente** |
| manifest hash del pool | **assente**: il manifest HAO-65 esclude i pool |
| comando `ipsw kernel extract` | citato nel `BUILD-REPORT` come passo, **senza log/stdout** |

Il `BUILD-REPORT` documenta i passi 2 e 3 e i conteggi, ma non conserva il comando completo né l’output. `donor-source-kc.txt` conserva gli hash delle **collezioni**, non dei singoli kext.

### 3.1 Ricerca di una traccia diretta (shell history)

| Fonte | Dimensione / mtime | Risultato |
|---|---|---|
| `~/.zsh_history` | 266.989 B, 16 Nov 2026 19:21 | 4 match generici `kmutil`/`ps`; **nessun** `systemkc-all`, `ipsw`, `kcditto`, `SystemKernelExtensions` |
| `~/.bash_history` | 23.082 B, 30 Mar 2026 | 1 match `sudo kmutil install --volume-root / --update-all`; **nessun** comando di estrazione |
| log di progetto HAO-65/HAO-86 | — | **nessun** log di `ipsw kernel extract` o di creazione dei pool |

**Esito:** traccia diretta dell’estrazione `systemkc-all` **ASSENTE**. Le uniche occorrenze storiche di `kmutil` non riguardano l’estrazione o la creazione della SystemKC.

---

## 4. Classificazione

### 4.1 PROVEN

- `tahoe-bootkc-all` contiene **204** file; `systemkc-all` contiene **172**; `staged` contiene **376**.
- I **28 componenti AMD** sono in `systemkc-all`; **0** in `tahoe-bootkc-all`.
- `X6100HWLibs` in `systemkc-all` ha SHA `e521d3cc…`, UUID `533D1262…`, 16.985.840 B, x86_64.
- Le collezioni host hanno SHA `9bb053cf…` (BootKC) e `b4b618bf…` (SystemKC); i conteggi 204/172 coincidono con i pool.
- `DARWIN27` affermava “non estratte”: la presenza di 172 file lo contraddice.

### 4.2 INFERRED

- `systemkc-all` è l’estrazione della **SystemKC 25G342**: 172 coincide con il conteggio documentato, il nome del pool è `systemkc-all`, e i **28 AMD** sono solo lì.
- `tahoe-bootkc-all` è l’estrazione della BootKC: 204 coincide e non contiene AMD.
- La catena AMD caricata su 25G342 proviene dalla SystemKC (BootKC non ne contiene).

**Perché non PROVEN:** manca il log del comando di estrazione e manca un manifest che associ ogni file al collezione. La corrispondenza numerica è un’inferenza forte, non una prova diretta.

### 4.3 UNPROVEN

- Che **tutti** i 172 file siano input non filtrati della SystemKC (potrebbero essere un sottoinsieme/selezione).
- Che `systemkc-all` sia pristino rispetto alla collection (nessuna modifica/rimozione).
- La collezione sorgente registrata dal kernel per il caricamento dei sei AMD della catena (la collezione ne contiene 28).
- Lo SHA del binario `X6100` effettivamente caricato.
- L’ABI con 26B131.

---

## 5. Correzione DARWIN27

In `<SESSION>/deliverables/DARWIN27-TAHOE-COMPATIBILITY.md`, la riga:

```text
| Kext non-boot (SystemKC, 369 MB) | non estratte | stessa procedura sulla SystemKernelExtensions.kc |
```

è stata sostituita con:

```text
| Kext non-boot (SystemKC, 369 MB) | estratte 172 in `work/systemkc-all`; nessun manifest per-kext | verifica per-kext con manifest/hash (assente) |
```

ed è stata aggiunta una nota T27 con:
- 172 file in `systemkc-all`, 204 in `tahoe-bootkc-all`, 376 in `staged`;
- 28 AMD solo in SystemKC, 0 in BootKC; i sei della catena sono un sottoinsieme;
- SHA delle due collezioni;
- manifest HAO-65 che esclude i pool;
- distinzione **INFERRED** (origine SystemKC) vs **PROVEN** (presenza nel pool).

La correzione documenta la prova materiale e non attribuisce al pool una provenienza che non è registrata da un log.

---

## 6. Conclusione

| Domanda | Risposta |
|---|---|
| `systemkc-all` ha 172 file? | **PROVEN** |
| I **28 AMD** sono in `systemkc-all` e 0 in `tahoe-bootkc-all`? | **PROVEN** |
| `systemkc-all` deriva dalla SystemKC 25G342? | **INFERRED**, non PROVEN |
| Esiste una traccia diretta dell’estrazione? | **NO**: né history né log |
| Esiste un log/manifest per-kext dell’estrazione? | **NO** |
| La catena caricata proviene dalla SystemKC? | **INFERRED** |
| `X6100` caricato ha SHA `e521d3cc…`? | **UNPROVEN** |
| 26B131 contiene AMD? | **NO** |

`DARWIN27` è corretto. La provenienza SystemKC è **fortemente inferita** da 172/204, dai nomi e dalla distribuzione AMD, ma **non è dimostrata** da un log di estrazione o da un manifest per-kext.

**STOP rispettato:** sola lettura; nessuna estrazione, ricostruzione KC, modifica o boot. Spazio libero 12.920.044 KiB (12,32 GiB) > 10 GiB.
