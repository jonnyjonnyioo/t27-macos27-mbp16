# T27 — AGENT-AMD — CACHELEVEL 2 FORMAT FORENSICS

**Scope:** verificare la codifica dei tre raw `cacheLevel=2`; confrontare i bitfield dei formati 8/11; cercare altri puntatori con lo stesso pattern; verificare la compatibilità del decoder.

**Modalità:** sola lettura; parsing SystemKC 25G342, chained fixups, definizioni disponibili nei report T27. Nessuna rete, modifica o boot.

**Esito:** il decoder **stride 4 è incompatibile**. Il formato 11 usa `next` a **12 bit** con **stride 1** (byte), non 4. Con stride 1 il SystemKC contiene **501.435 puntatori, 0 `isAuth=1`, 0 `cacheLevel=2`**: gli slot `0xA99B60`, `0xDB9980`, `0xF80198` **non sono punti di partenza** (`page_start` 0xB20/0x940/0x18, non 0xB60/0x980/0x198) e i loro raw sono **parole dati** che sembrano auth. I **3 slot sono ritirati**; i 12 raw restano raw. T27 resta **OPEN**.

---

## 1. Formato 11

| Campo | Bit | Tipo | Valore nei tre raw |
|---|---:|---|---|
| `target` | 0–29 | unsigned 30 | `0x18C0074D`, `0x18C00EFC`, `0x18C00002` |
| `cacheLevel` | 30–31 | unsigned 2 | **2** |
| `diversity` | 32–47 | unsigned 16 | 6 / 0x2006 / 0x2005 |
| `addrDiv` | 48 | unsigned 1 | **0** |
| `key` | 49–50 | unsigned 2 | **0** |
| `next` | 51–62 | unsigned 12 | **0** |
| `isAuth` | 63 | unsigned 1 | **1** |

**PROVEN:** i tre raw hanno `isAuth=1`, `cacheLevel=2`, `next=0`.
**PROVEN:** `target` è unsigned a 30 bit; non c’è signedness.
**PROVEN:** `next` è a 12 bit.

---

## 2. Stride

| Formato | `next` | Stride | Evidenza |
|---|---:|---:|---|
| 8 | 11 bit (non usato) | **non applicato** | metadata `pointer_format=11` |
| **11** | **12 bit** | **1 byte** | catena X6100 `next` 16→32→80→96→144→160 |

**PROVEN:** il formato effettivo è **11** (`pointer_format=11`).
**PROVEN:** con stride 1 la catena X6100 percorre 16, 32, 80, 96, 144, 160; con stride 4 non li percorre.
**PROVEN:** il decoder stride 4 è **incompatibile**.

---

## 3. Conteggi con stride corretto

| Provider | Puntatori | `isAuth=1` | `cacheLevel=2` |
|---|---:|---:|---:|
| X4000 | **26.377** | **0** | **0** |
| X4000HWLibs | **9.954** | **0** | **0** |
| **SystemKC** | **501.435** | **0** | **0** |

**PROVEN:** con stride 1 non ci sono auth slot né cacheLevel 2 nel SystemKC.
**PROVEN:** i 3 slot precedenti erano un artefatto di stride 4.
**PROVEN:** X6100 aveva già **0/8.544 auth**; il nuovo conteggio è coerente.

---

## 4. I tre raw non sono slot

| Slot | `page_start` della pagina | Offset reale | È uno start? |
|---:|---:|---:|---|
| `0xA99B60` | **0xB20** | **0xB60** | **NO** |
| `0xDB9980` | **0x940** | **0x980** | **NO** |
| `0xF80198` | **0x18** | **0x198** | **NO** |

**PROVEN:** i tre offset sono **0x40/0x40/0x180** oltre il rispettivo `page_start`.
**PROVEN:** non sono raggiunti da una catena stride 1.
**PROVEN:** sono parole dati con bit `isAuth=1`, non fixup.

---

## 5. Pattern ricorrenti

| Raw | Occorrenze | Provider |
|---|---:|---|
| `0x8000000698C0074D` | **multiple** | X4000HWLibs, X4100, X4400, X4700, X5000, X5200, X5400, X5700 |
| `0x8000200698C00EFC` | **multiple** | X4000HWLibs, X5000 |
| `0x8000200598C00002` | **1** | X4000HWLibs |

**PROVEN:** il pattern non è isolato; ricorre in più HWLibs AMD.
**PROVEN:** la ricorrenza è in **dati**, non in slot di catena.
**UNPROVEN:** una struttura o una funzione comune.

---

## 6. Formato 8 vs 11

| Aspetto | Formato 8 | Formato 11 |
|---|---|---|
| Nome | `DYLD_CHAINED_PTR_64_KERNEL_CACHE` | `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` |
| Uso nel SystemKC | **no** | **sì — pfmt 11** |
| `next` | **11 bit** (definizione non locale) | **12 bit** |
| Decoder applicato | **non applicato** | **corretto con stride 1** |
| Differenza provata | **UNPROVEN** | **PROVEN** |

**PROVEN:** il SystemKC usa il formato 11.
**PROVEN:** il formato 8 non è stato applicato.
**UNPROVEN:** la differenza completa 8/11; non serve per questi dati.

---

## 7. Compatibilità del decoder

| Verifica | Esito |
|---|---|
| `pointer_format=11` | **SÌ** |
| `next` 12 bit | **SÌ** |
| stride 1 | **SÌ** |
| stride 4 | **NO — incompatibile** |
| target 30 bit unsigned | **SÌ** |
| isAuth bit 63 | **SÌ** |
| 3 slot reali | **NO — ritirati** |

**PROVEN:** il decoder corretto è target/cacheLevel/diversity/addrDiv/key/next12/isAuth con stride 1.
**PROVEN:** i tre raw non sono slot.
**UNPROVEN:** qualsiasi auth slot nel SystemKC.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Formato effettivo | **11** |
| Stride corretto | **1 byte** |
| Stride 4 compatibile? | **NO** |
| Auth slot nel SystemKC | **0** |
| CacheLevel 2 nel SystemKC | **0** |
| 3 slot reali? | **NO — ritirati** |
| 12 raw? | **raw, non slot** |
| Formato 8 usato? | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il decoder stride 4 era **incompatibile**; con `next` a 12 bit e stride 1 il SystemKC ha **0 auth** e **0 cacheLevel 2**. I tre raw sono **parole dati** a offset `page_start+0x40/0x40/0x180`, non slot; i **3 slot sono ritirati**. I 12 raw restano raw. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna rete/download/modifica/build/boot.
