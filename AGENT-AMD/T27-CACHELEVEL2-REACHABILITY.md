# T27 — AGENT-AMD — CACHELEVEL 2 REACHABILITY

**Scope:** stabilire se i **12 auth pointer** con `cacheLevel=2` sono metadati raggiungibili o residui non usati; recuperare i 12 slot sorgente; identificare owner, segmento e sezione; cercare riferimenti/relocazioni; confrontare i donor; documentare rischio runtime e causa.

**Modalità:** sola lettura; parsing SystemKC, `LC_FILESET_ENTRY`, owner per file offset, raw scan, confronto con XNU. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** il report 46 **non contiene i 12 indirizzi sorgente**: conteneva solo target e parole encoded di esempio. La scansione delle parole encoded ha trovato **8 esempi** in X4000/X4000HWLibs e **1** in **X5200HWLibs**, quindi gli esempi **non sono** gli slot sorgente. **La raggiungibilità dei 12 slot resta UNPROVEN**. Se uno slot con `cacheLevel=2` è percorso, `basePointers[2]` è nullo e XNU lo rifiuta: rischio **condizionato**. Causa **UNPROVEN**. T27 resta **OPEN**.

---

## 1. Gap del report 46

| Dato | Report 46 | Serve per reachability |
|---|---|---|
| Target | **SÌ** | identificazione |
| Parola encoded di esempio | **SÌ** | decoding |
| **Indirizzo slot sorgente** | **NO** | **owner e riferimenti** |
| **Sezione sorgente** | **NO** | **struttura** |
| **Istruzione che legge lo slot** | **NO** | **raggiungibilità** |

**PROVEN:** senza slot sorgente non si può attribuire owner, sezione o xref.
**PROVEN:** i 12 target non bastano: lo stesso valore può comparire in più provider.

---

## 2. Owner degli esempi

| Target | Off. esempio | Owner dell’esempio | Fonte dichiarata |
|---:|---:|---|---|
| `0x3F8C007F` | `0x3B6300` | **X4000** | X4000 |
| `0x3E8203F2` | `0x3BD000` | **X4000** | X4000 |
| `0x334FE856` | `0x7BC010` | **X4000HWLibs** | X4000HWLibs |
| `0x1780000E` | `0x9A4530` | **X4000HWLibs** | X4000HWLibs |
| `0x20A` | `0x9B3B08` | **X4000HWLibs** | X4000HWLibs |
| `0x4A6` | `0xA50700` | **X4000HWLibs** | X4000HWLibs |
| `0x16400001` | `0x9B3AD0` | **X4000HWLibs** | X4000HWLibs |
| `0x8B1` | `0x7EA5330` | **X5200HWLibs** | X4000HWLibs |
| `0x1A000002` | `0x9B7DD8` | **X4000HWLibs** | X4000HWLibs |

**PROVEN:** **1/9** esempio (`0x8B1`) cade in **X5200HWLibs**, non nel provider dichiarato.
**PROVEN:** gli esempi sono **occorrenze**, non **slot**.
**UNPROVEN:** gli slot reali dei 12.

---

## 3. Raggiungibilità

| Verifica | Esito |
|---|---|
| 12 slot sorgente noti | **NO** |
| Slot dentro una catena `LC_DYLD_CHAINED_FIXUPS` | **UNPROVEN** |
| Slot referenziati da codice | **UNPROVEN** |
| Slot in tabella attiva | **UNPROVEN** |
| Slot residui | **UNPROVEN** |
| Xref/relocazioni per slot | **non eseguibile senza slot** |

**PROVEN:** la raggiungibilità non è dimostrata.
**PROVEN:** non è nemmeno dimostrato che siano residui.
**UNPROVEN:** entrambe le alternative.

---

## 4. Rischio runtime

Se uno slot con `cacheLevel=2` è effettivamente percorso:

```c
baseAddress = basePointers[2];   // non inizializzato
if (baseAddress == 0) {          // vero
    /* Invalid cache level */
    *stop = 1;
    return;
}
```

| Condizione | Conseguenza |
|---|---|
| Slot percorso | **fixup rifiutato / stop** |
| Slot non percorso | **nessun effetto** |
| Base `[2]` valorizzata da altra via | **UNPROVEN** |

**PROVEN:** `PE_set_kc_header` non inizializza l’indice 2.
**PROVEN:** XNU tratta base nulla come **invalid cache level**.
**UNPROVEN:** se gli slot siano percorsi.

---

## 5. Donor

| Confronto | Stato |
|---|---|
| X4000 standalone vs embedded | **non eseguito** |
| X4000HWLibs standalone vs embedded | **non eseguito** |
| X5200 esempio vs X4000 dichiarato | **differente owner** |
| Copia donor con stessi 12 slot | **UNPROVEN** |

**PROVEN:** l’esempio `0x8B1` dimostra che il target da solo **non** identifica il donor.
**UNPROVEN:** l’esistenza di una copia donor con gli stessi slot.

---

## 6. I 12

| Gruppo | Auth | Livello 2 | Slot noti |
|---|---:|---:|---:|
| Esterni | 9 | 9 | **0** |
| Non esterni | 3 | 3 | **0** |
| **Totale** | **12** | **12** | **0** |

**PROVEN:** **12** auth unici; **9** esterni; **3** non esterni.
**UNPROVEN:** slot, sezione e raggiungibilità di tutti e 12.

---

## 7. X6100

| Proprietà | Valore |
|---|---|
| Target | **`0x12AA488`** |
| `cacheLevel` | **0** |
| `isAuth` | **1** |
| Coinvolto nei 12 | **NO** |
| Base assoluta | **UNPROVEN** |

**PROVEN:** X6100 non è uno dei 12; il suo fixup è livello 0.
**PROVEN:** l’anomalia auth→firmware resta indipendente.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| 12 slot sorgente noti? | **NO** |
| Owner degli esempi? | **8 X4000/X4000HWLibs, 1 X5200** |
| Esempi = slot? | **NO** |
| Raggiungibili? | **UNPROVEN** |
| Residui? | **UNPROVEN** |
| Rischio se percorsi? | **fixup rifiutato** |
| Causa? | **UNPROVEN** |
| X6100 coinvolto? | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il report 46 non conservava gli slot; gli esempi non sono gli slot e uno appartiene a X5200. La raggiungibilità dei **12** è **UNPROVEN**, così come la loro natura di residui. Il rischio è **condizionato**: se percorsi, `basePointers[2]` nullo li fa rifiutare. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
