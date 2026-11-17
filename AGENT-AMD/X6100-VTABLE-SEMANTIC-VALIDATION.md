# T27 — AGENT-AMD — X6100 VTABLE SEMANTIC VALIDATION

**Scope:** verificare se gli **869 slot** attribuiti alle vtable X6100 sono **vere entry virtuali** o soltanto **indirizzi vicini** a simboli `__ZTV`. Ricostruire confini, header, allineamento e offset per le **sei famiglie**; confrontare i target X4000 con l’ABI Itanium e con le sezioni reali.  
**Modalità:** sola lettura; `nm -n -S`, `otool -l`, `otool -s`, parsing Mach-O e chained fixups. Nessuna estrazione, modifica, build o boot.  
**Esito:** gli **869 slot esterni** sono **tutti dentro il corpo virtuale** delle vtable (`offset >= 0x10`), **8-byte aligned**, **0 nei 16 byte di header**. **16 vtable** hanno header a **16 byte tutti zero**: `offset-to-top = 0`, `typeinfo = 0`; **0 simboli `__ZTI`**. Quindi **non sono semplici vicinanze**: la posizione è PROVEN. Però **tutti i 869 target sono dati/stringhe X4000**, **0 codice**: come **function pointer virtuali standard** sono **incompatibili**. La semantica resta **INFERRED/UNPROVEN**; T27 resta **OPEN**.

---

## 1. Input e metodo

| Input | Uso |
|---|---|
| `X6100-EXTERNAL-SOURCE-ATTRIBUTION.md` | 870 `__const` + 16 `__got`; 869 vtable + 1 `superClass` |
| `X6100-CROSS-PROVIDER-ATTRIBUTION.md` | target X4000/AMD10000/X4400 |
| `X6100-KC-FIXUPS.md` | fileoff KC assoluti, sezioni |
| `systemkc-all/com.apple.kext.AMDRadeonX6100HWLibs` | `nm`, `otool`, byte |

Procedura:
1. **`nm -n -S`** per i simboli `__ZTV`/`__ZTI`;
2. **`otool -l`** per `__DATA,__const` e `__got`;
3. **`otool -s __DATA __const`** per i byte grezzi dell’header;
4. confini vtable = **simbolo `__ZTV` → simbolo successivo** (le size `nm -S` sono **sempre zero** su Mach-O, con warning);
5. offset di ogni slot esterno dal simbolo `__ZTV`; header `[0,16)`, corpo virtuale `[16,…)`;
6. target provider/sezione con il report precedente.

**Nota:** `nm -n -S` riporta **size 0** per tutti i simboli Mach-O; i limiti sono stati presi dal **simbolo successivo**, non da una size inaffidabile.

---

## 2. Sei famiglie `__ZTV`

| # | Famiglia | Simboli | Range | Size | Slot totali | Header | Vfunc | Slot esterni | Offset esterni | Target |
|---|---|---|---:|---:|---:|---:|---:|---:|---|---|
| 1 | **X6100 main** | `__ZTV35…X6100` | `0xE11C130–0xE11C9A0` | **2.160** | 270 | 2 | 268 | **255** | `0x20–0x858` | 199 data, 45 const, 10 cstring, 1 text const |
| 2 | **HWLibs main** | `__ZTV30…HWLibs` | `0xE11CA98–0xE11D300` | **2.152** | 269 | 2 | 267 | **255** | `0x20–0x858` | 199 data, 45 const, 10 cstring, 1 text const |
| 3 | **SWIP main** | `__ZTV34…SWIP` | `0xE11D3F8–0xE11DC68` | **2.160** | 270 | 2 | 268 | **256** | `0x20–0x860` | 200 data, 45 const, 10 cstring, 1 text const |
| 4 | **Metaclass** | `__ZTVN35…`, `__ZTVN30…`, `__ZTVN34…` | `0xE11C9A0–0xE11CA88`, `0xE11D300–0xE11D3E8`, `0xE11DC68–0xE11DD50` | **232 × 3** | 29 × 3 | 2 × 3 | 27 × 3 | **69** | `0x20–0xD8` | 14 data, 9 cstring per vtable |
| 5 | **AtiPowerPlayInterface** | `__ZTV21AtiPowerPlayInterface` | `0xE129328–0xE129450` | **296** | 37 | 2 | 35 | **32** | `0x20–0x118` | 32 data |
| 6 | **AtiApplePowerTuneServices** | `__ZTV25AtiApplePowerTuneServices` | `0xE1294C8–0xE1294F0` | **40** | 5 | 2 | 3 | **2** | `0x10–0x18` | 2 data |
| — | **Totale** | — | — | — | **938** | **16** | **922** | **869** | — | — |

**PROVEN:** `255 + 255 + 256 + 69 + 32 + 2 = 869`. **Nessun** slot esterno nei 2 slot di header di ciascuna vtable; **tutti** gli esterni sono nel corpo virtuale.

Il simbolo esatto residuo `superClass` è **fuori** da queste sei famiglie: `__ZN30AMDRadeonX6100_AMDRadeonHWLibs10superClassE` a **0xE11CA90**, target **0x12AA488** (X4000 `__DATA,__data`, `_polaris10_kicker_smc_firmware`). Gli altri due `superClass` (N35 a `0xE11C128`, N34 a `0xE11D3F0`) puntano a **0xED11A60 / 0xED11A38**, interni X6100; **non sono esterni**.

---

## 3. Header ABI Itanium

Le **16 vtable definite** (`nm` mostra anche una `__ZTV9IOService` **undefined**, non una vtable locale) hanno i primi **16 byte tutti zero**:

| Offset | Campo Itanium | Valore |
|---:|---|---:|
| `+0` | `offset-to-top` | **0** |
| `+8` | `typeinfo pointer` | **0** |
| `+16` | prima entry virtuale | slot interno/esterno |

**PROVEN:**
- header presente, **2 word**;
- `offset-to-top = 0` per tutte le vtable (primary);
- `typeinfo = 0` per tutte;
- **0 simboli `__ZTI`** in X6100 (`nm` 0 righe);
- **RTTI disabilitato** o non serializzato.

**UNPROVEN:** che l’assenza di `__ZTI` permetta di trattare queste strutture come vtable C++ complete; l’header è strutturalmente valido, ma **senza RTTI**.

---

## 4. Offset e allineamento degli slot

| Famiglia | Slot esterni | Header `[0,16)` | Vfunc `[16,size)` | Min offset | Max offset | Allineati 8 B |
|---|---:|---:|---:|---:|---:|---|
| X6100 main | 255 | **0** | **255** | `0x20` | `0x858` | **SÌ** |
| HWLibs main | 255 | **0** | **255** | `0x20` | `0x858` | **SÌ** |
| SWIP main | 256 | **0** | **256** | `0x20` | `0x860` | **SÌ** |
| Metaclass (3) | 69 | **0** | **69** | `0x20` | `0xD8` | **SÌ** |
| AtiPowerPlayInterface | 32 | **0** | **32** | `0x20` | `0x118` | **SÌ** |
| AtiApplePowerTuneServices | 2 | **0** | **2** | `0x10` | `0x18` | **SÌ** |
| **Totale** | **869** | **0** | **869** | — | — | **SÌ** |

**PROVEN:** gli slot esterni non sono “vicinanze” generiche:
- stanno **dentro** il range del simbolo `__ZTV` (fino al simbolo successivo);
- sono **tutti dopo i 16 byte di header**;
- sono **tutti multipli di 8**;
- i loro offset coprono il corpo virtuale in modo regolare (`0x20`, `0x28`, …).

**Conclusione strutturale:** **non sono semplici proximity**; sono **posizioni di slot virtuali** nella vtable. **La semantica di ciò che puntano** è il problema successivo.

---

## 5. Compatibilità dei target

| Target X4000 | Slot vtable | Quota |
|---|---:|---:|
| `__DATA,__data` | **674** | 77,56% |
| `__DATA,__const` | **135** | 15,53% |
| `__TEXT,__cstring` | **57** | 6,56% |
| `__TEXT,__const` | **3** | 0,35% |
| **Totale vtable** | **869** | 100% |
| `superClass` esatto | **1** (`__DATA,__data`) | — |
| **Totale `__const`** | **870** | — |

**PROVEN:** **0 target in `__TEXT,__text`**; **tutti i 869 target sono dati, tabelle o stringhe X4000**.

**ABI Itanium:** una entry virtuale è un **function pointer** a codice eseguibile. Un target in `__data`, `__const` o `__cstring` **non è un function pointer valido**. Di conseguenza:
- la **posizione** degli slot nella vtable è PROVEN;
- la loro **funzione di vfunc** è **incompatibile** con l’ABI standard;
- non è possibile dichiarare che siano “vere entry virtuali” solo dalla posizione.

**INFERRED:** questi slot possono essere:
1. **vtable parziali** con campi dati (non standard);
2. **tabelle `__ZTV`-like** usate come descrittori, non come vtable C++;
3. **riferimenti a dati** che il runtime tratta diversamente.

**UNPROVEN:** quale delle tre; e che un vfunc con target dati sia callable.

---

## 6. Verifica dei confini

| Simbolo | Start | Next symbol | Size | Coerenza |
|---|---:|---:|---:|---|
| `__ZTV35…X6100` | `0xE11C130` | `__ZTVN35…` `0xE11C9A0` | **2.160** | esatta |
| `__ZTVN35…` | `0xE11C9A0` | `superClass` `0xE11CA88` | **232** | esatta |
| `__ZTV30…HWLibs` | `0xE11CA98` | `__ZTVN30…` `0xE11D300` | **2.152** | esatta |
| `__ZTVN30…` | `0xE11D300` | `superClass` `0xE11D3E8` | **232** | esatta |
| `__ZTV34…SWIP` | `0xE11D3F8` | `__ZTVN34…` `0xE11DC68` | **2.160** | esatta |
| `__ZTVN34…` | `0xE11DC68` | `0xE11DD50` | **232** | esatta |
| `__ZTV21AtiPowerPlayInterface` | `0xE129328` | `0xE129450` | **296** | esatta |
| `__ZTV25AtiApplePowerTuneServices` | `0xE1294C8` | `0xE1294F0` | **40** | esatta |

**PROVEN:** i confini sono determinati dal simbolo successivo, non da size `nm` (sempre zero). **Nessun** range si sovrappone; **nessun** target esterno cade oltre il limite.

---

## 7. `otool` e header grezzi

| Comando | Esito |
|---|---|
| `nm -n -S` | **16** `__ZTV` definite, **0** `__ZTI`; warning: size Mach-O **sempre 0** |
| `otool -l` | `__DATA,__const` offset **3.858.720**, size **65.904** |
| `otool -s __DATA __const` | header `0xE11C130` = **16 byte zero**; header `0xE1294C8` = **16 byte zero** |
| `otool -Iv` | **nessuna** entry indirect (chained fixups) |

**PROVEN:** l’header a 16 byte è **zero** sia per la vtable principale sia per la power-tune.

---

## 8. Interpretazione

### PROVEN

- **869** slot esterni dentro **8 vtable** (6 famiglie).
- **0** slot nei 16 byte di header; **869** nel corpo virtuale.
- **Tutti** 8-byte aligned; offset `0x10–0x860`.
- **16** vtable con `offset-to-top=0`, `typeinfo=0`; **0 `__ZTI`**.
- **Tutti** i 869 target sono **X4000 data/const/cstring**; **0 codice**.
- **1** `superClass` esatto esterno (`0xE11CA90` → `0x12AA488`).

### INFERRED

- Gli slot sono **entry di vtable-like structures**, non semplici vicinanze.
- L’assenza di RTTI indica un **C++ kernel senza typeinfo**.
- I target dati suggeriscono **descrittori/tables**, non function pointer standard.

### UNPROVEN

- Che una vtable con target dati sia **callable** o **lecita** a runtime.
- Che l’header senza `__ZTI` sia sufficiente per l’ABI Itanium completa.
- Che gli slot siano usati come vfunc, callback o semplice dato.
- Risoluzione assoluta, `basePointers`, dipendenza AMD, boot/ABI.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Gli 869 slot sono semplici vicinanze? | **NO: sono dentro il corpo virtuale, allineati, dopo l’header** |
| Header Itanium presente? | **SÌ: 2 word, `offset-to-top=0`, `typeinfo=0`** |
| RTTI presente? | **NO: 0 `__ZTI`** |
| Target compatibili con vfunc standard? | **NO: 869/869 dati/stringhe, 0 codice** |
| Vtable semanticamente valide? | **UNPROVEN / incompatibili come vfunc standard** |
| Attribution posizionale PROVEN? | **SÌ** |
| T27 è GO? | **NO — OPEN** |

**Risposta netta:** gli slot **non sono semplici proximity**; sono **posizioni reali di slot virtuali** in vtable con header a 16 byte. Ma **non sono function pointer virtuali standard**, perché **tutti i target sono dati/stringhe X4000** e **nessuno è codice**. La struttura è PROVEN; la semantica è **INFERRED/UNPROVEN**. T27 resta **OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**STOP rispettato:** sola lettura; nessuna estrazione, copia, modifica, build o boot. Spazio libero ultimo controllo **≈12,30 GiB** > **10 GiB**.
