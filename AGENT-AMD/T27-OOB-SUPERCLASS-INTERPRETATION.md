# T27 — AGENT-AMD — SUPERCLASS INTERPRETATION

**Scope:** determinare perché X5000/X6000 Interface dichiarano `superClass = 0xC00000012AA488`, verificare i byte attorno a `0xA29DCDE`, confrontare classi IOKit valide e distinguere errore di mapping da errore di relocation/slide.

**Modalità:** sola lettura; SystemKC/BootKC, segmenti, protezioni, byte, occorrenze; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che `0x12AA488` cade in quattro segmenti top-level sovrapposti con byte diversi e che `__REGION19` è zero-filled. **PROVEN** che `0xC00000012AA488` è un valore comune (≥10 occorrenze in SystemKC e BootKC). **REFUTED** che `0x12AA488` sia interpretabile come class descriptor da un singolo mapping. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 122 | `664e328a9d8084401d7db7db6c49b3b6fa787a3df88dea7b6dc47067adee123c` |
| Report 121 | `bb56538b77cf30969145921a8e1fa9a9d43a67d998c2b0ff1af5f69e98996d35` |

**PROVEN:** gli artefatti sono quelli indicati; 122 ha il banner di rettifica.

---

## 2. Finestra a `0xA29DCDE`

```text
-0x110 00 00 00 00 00 00 00 00 ...
-0x100 00 00 00 00 00 00 00 00 ...
-0x40  00 00 00 00 00 00 00 00 ...
-0x20  00 00 00 00 00 00 00 00 ...
 0x00  00 00 00 00 00 00 00 00 ...
+0x20  00 00 00 00 00 00 00 00 ...
+0x100 00 00 00 00 00 00 00 00 ...
```

| Test | Esito |
|---|---|
| 256 byte prima | **zero** |
| 256 byte dopo | **zero** |
| Codice | **NO** |
| Dato | **zero-fill** |
| Funzione | **NO** |

**PROVEN:** la finestra è vuota.
**REFUTED:** codice a `__REGION19`.
**UNPROVEN:** il contenuto runtime.

---

## 3. Segmenti candidati

| Segmento | vmaddr | fileoff | prot | Byte a target | Esito |
|---|---:|---:|---:|---|---|
| `__PRELINK_INFO` | `0x3C000` | `0x245760` | `3` | `9D 85 00 00 E8…` | metadati |
| `__REGION12` | `0x2AA000` | `0x2793472` | `5` | `0E C0 DF 24…` | codice/dato |
| `__REGION18` | `0x6E7000` | `0x7237632` | `5` | `00 01 78 02…` | dato |
| `__REGION19` | `0x984000` | `0x9977856` | `3` | `00 00 00 00…` | zero |

**PROVEN:** i segmenti si sovrappongono in VM.
**PROVEN:** i byte dipendono dal segmento scelto.
**PROVEN:** non esiste un mapping univoco con `otool -l`.
**UNPROVEN:** il mapping corretto.

---

## 4. Occorrenze del raw

| Immagine | Occorrenze (≥) | Primi offset |
|---|---:|---|
| SystemKC | `10` | `0x29FCE0`, `0x2A70A8`, `0x2A7A38`, `0x2A8398`, `0x6E39E8`, `0x9840B8`, `0x15D6058`, `0x23700B8`, `0x34B60B8`, `0x457F368` |
| BootKC | `10` | `0x13EF6D0`, `0x13FFBC0`, `0x1409098`, `0x141C138`, `0x143F608`, `0x1440DA8`, `0x16EA408`, `0x16EBCB8`, `0x1708030`, `0x17140A8` |

**PROVEN:** il valore è comune.
**PROVEN:** non è specifico di Interface.
**UNPROVEN:** il numero totale.

---

## 5. Campi superClass (letture invalide)

**Le righe seguenti sono il risultato del primo match top-level e NON rappresentano i campi reali.**

| Classe | Campo | Raw | Target | Livello |
|---|---:|---:|---:|---:|
| X4000 Interface | `0x6E39E8` | `0x75282800214D5044` | `0x214D5044` | `0` |
| X4000 Abstract | `0x6E4360` | `0x726946656C676E69` | `0x2C676E69` | `1` |
| X4000 CAIL | `0x6E3068` | `0x2029745F3631746E` | `0x3631746E` | `0` |
| X5000 Vega | `0x457E068` | `0xB99C000000000102` | `0x102` | `0` |
| X5000 Interface | `0x457F368` | `0xC00000012AA488` | `0x12AA488` | `3` |
| X5000 Abstract | `0x457FCE0` | `0x0` | `0` | `0` |
| X6000 Navi | `0xC26F070` | `0x5F32626D73006C6C` | `0x33006C6C` | `1` |
| X6000 SWI | `0xC26F9F0` | `0x6A00737868006669` | `0x28006669` | `1` |
| X6000 Interface | `0xC270370` | `0xC00000012AA488` | `0x12AA488` | `3` |
| X6000 Abstract | `0xC270CE8` | `0x726F6620646C6C25` | `0x246C6C25` | `1` |

**PROVEN:** le letture top-level non sono affidabili.
**PROVEN:** i valori sembrano ASCII/rumore.
**UNPROVEN:** i campi reali.

---

## 6. Interpretazione

| Ipotesi | Stato |
|---|---|
| `0x12AA488` è un class descriptor | **REFUTED** |
| `0x12AA488` è codice | **REFUTED** |
| È un target L3 | **PROVEN** |
| Serve una base L3 | **PROVEN** |
| Base L3 nota | **UNPROVEN** |
| Errore di relocation | **UNPROVEN** |
| Errore di slide | **UNPROVEN** |

**PROVEN:** il target non è autosufficiente.
**REFUTED:** le letture dirette.
**UNPROVEN:** la base.

---

## 7. Classi valide

| Classe | `superClass` |
|---|---:|
| Navi | `0x4C271800` (`SWI`) |
| SWI | `0x4C271850` (`Abstract`) |
| Abstract | `0x4C271828` |
| Interface X5000/X6000 | `0x12AA488` L3 |

**PROVEN:** Navi/SWI/Abstract usano puntatori L1.
**PROVEN:** Interface usa L3.
**UNPROVEN:** il significato della differenza.

---

## 8. Conseguenze

| Domanda | Risposta |
|---|---|
| Identità `0x12AA488` | **UNPROVEN** |
| Class descriptor | **NO** |
| Codice | **NO** |
| Superclass reale | **UNPROVEN** |
| Pubblicazione | **UNPROVEN** |
| Matching | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Byte a `__REGION19` | **zero** |
| Segmenti sovrapposti | **SÌ** |
| Mapping univoco | **NO** |
| Raw comune | **SÌ** |
| Target L3 | **SÌ** |
| Base L3 | **UNPROVEN** |
| Superclass | **UNPROVEN** |
| Pubblicazione | **UNPROVEN** |
| Matching | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `0x12AA488` non è interpretabile come indirizzo di classe: cade in quattro segmenti top-level sovrapposti con byte diversi, e `__REGION19` è zero-filled. Il valore `0xC00000012AA488` compare almeno dieci volte in SystemKC e dieci in BootKC, quindi è un `superClass` comune, non un puntatore specifico di Interface. Le letture dirette producono ASCII, rumore o codice a seconda del segmento scelto: il campo è un chained pointer L3 e richiede una base non nota. La superclass reale, la pubblicazione e il matching X6000HWLibs restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,2 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
