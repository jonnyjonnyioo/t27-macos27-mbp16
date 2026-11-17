# T27 — AGENT-AMD — AMD SYSTEMKC POOL BINARY FINGERPRINTS

**Scope:** identificare se i sei binari AMD di `systemkc-all` corrispondono a copie presenti nei donor **root2**, **root3** o **root25**, senza presumere la provenienza della collezione.  
**Modalità:** sola lettura; `shasum`, `dwarfdump --uuid`, `file`, `stat`; nessuna estrazione, copia, modifica, build o boot.  
**Esito:** **5/6 esatti** tra `systemkc-all` e **root3**; **0/6** tra `systemkc-all` e root2; root25 non contiene binari AMD. `X6100HWLibs` non ha copia esatta in root3/root25; root2 ne ha una versione **diversa**.

---

## 1. Percorsi confrontati

| Pool | Percorso |
|---|---|
| `systemkc-all` | `HAO-PROJECT/Sessions/<SESSION>/work/systemkc-all` |
| root2 | `HAO-PROJECT/Sessions/<SESSION>/work/root2/System/Library/Extensions` |
| root3 | `HAO-PROJECT/Sessions/<SESSION>/work/root3/System/Library/Extensions` |
| root25 | `<DONOR_VOLUME>/System/Library/Extensions` |

I binari sono stati cercati per bundle esatto; per `X6100HWLibs` il percorso è annidato in `AMDRadeonX6000HWServices.kext/Contents/PlugIns/`.

---

## 2. Fingerprint completo

| Componente | systemkc-all SHA-256 / byte / UUID | root2 SHA-256 / byte / UUID | root3 SHA-256 / byte / UUID | root25 | Match esatto |
|---|---|---|---|---|---|
| `AMDSupport` | `c569698b…` / 1.415.088 / `736ECBBA` | `b222e4bc…` / 2.104.464 / `736ECBBA` | `c569698b…` / 1.415.088 / `736ECBBA` | **NO_BINARY** | **systemkc = root3** |
| `AMDRadeonX6000Framebuffer` | `a2469429…` / 3.452.992 / `F527F501` | `d037b095…` / 3.706.208 / `F527F501` | `a2469429…` / 3.452.992 / `F527F501` | **NO_BINARY** | **systemkc = root3** |
| `AMDRadeonX6000HWServices` | `cc7aaca4…` / 55.008 / `4A753C5A` | `9d50f380…` / 92.592 / `4A753C5A` | `cc7aaca4…` / 55.008 / `4A753C5A` | **NO_BINARY** | **systemkc = root3** |
| `AMDRadeonServiceManager` | `bdb566f3…` / 52.176 / `53316747` | `6b7586dc…` / 90.352 / `53316747` | `bdb566f3…` / 52.176 / `53316747` | **NO_BINARY** | **systemkc = root3** |
| `AMDRadeonX6000` | `2734aaf7…` / 2.090.264 / `1540D089` | `8874ae65…` / 2.379.536 / `1540D089` | `2734aaf7…` / 2.090.264 / `1540D089` | **NO_BINARY** | **systemkc = root3** |
| `AMDRadeonX6100HWLibs` | `e521d3cc…` / 16.985.840 / `533D1262` | `00b6214e…` / 17.256.336 / `533D1262` | **ASSENTE** | **NO_BINARY** | **nessuno** |

Tutti i binari sono `Mach-O 64-bit kext bundle x86_64`.

### 2.1 Hash completi

```text
AMDSupport
  systemkc/root3 c569698b689d3822ce3f18a51202b10f46f48e395e80a339dc3bae403754f2a4
  root2           b222e4bc84fd3662b1b2bfdcbbb5f97f1af9e752b271e9119a3885afa1d1e976

AMDRadeonX6000Framebuffer
  systemkc/root3 a2469429602210e64a74292a30b06353d9e0f75cd6b8b65f98324e64fa0b4536
  root2           d037b0957238b5bfd32fddfccb24917a6347f8daf0f3421f88827dbdf81a2824

AMDRadeonX6000HWServices
  systemkc/root3 cc7aaca45446f98cc4ea03b1fdf80b402975c1b0e0d07585a304d78dcdf797f7
  root2           9d50f380d06f8d669266ae3b78342c59cc0bc672e8cef657ff211f812903bed2

AMDRadeonServiceManager
  systemkc/root3 bdb566f37ce2be039e47bfb807fdc03b6d6bcd5b251eefc874916ed22b3cbf81
  root2           6b7586dc06dd39c1f90ed179eda6d65653030aa4cb9a17b94bfabd3f9a4212ac

AMDRadeonX6000
  systemkc/root3 2734aaf7bf338afb9dece81466651a0c9db3a99dc6c5930798dd1fb5da63a40b
  root2           8874ae65086394ad1bc6901b349b9373d8eb8fec2d5f35703c7681a79abefefb

AMDRadeonX6100HWLibs
  systemkc        e521d3cce8f9bb027642897fed8754ff4d9ef66dd08a8d13ab318e0c2db01bb5
  root2           00b6214e4771d84f2cda4a9943fceafaac0e632f57fbfda20e6ee5cbf051d61f
  root3           ASSENTE
```

### 2.2 UUID completi

| Componente | systemkc | root2 | root3 |
|---|---|---|---|
| `AMDSupport` | `736ECBBA-C9C9-3AF7-BE6A-EB1944DB515B` | uguale | uguale |
| `X6000Framebuffer` | `F527F501-CD46-34D0-AEB3-C8E5C8ADF2C8` | uguale | uguale |
| `X6000HWServices` | `4A753C5A-7010-390E-B234-0DB2765A37E9` | uguale | uguale |
| `ServiceManager` | `53316747-531F-3003-97A7-4B51226A731D` | uguale | uguale |
| `X6000` | `1540D089-EE2D-3339-B5A8-2024F9E38581` | uguale | uguale |
| `X6100HWLibs` | `533D1262-BE83-3507-B48A-FDB91C9D8793` | uguale | **ASSENTE** |

**UUID uguale non significa binario identico**: root2 ha gli stessi UUID ma hash diversi per tutti e sei. L’identità è stata stabilita **solo** dallo SHA-256.

---

## 3. Matrice dei match

| Coppia | Match SHA esatti | Dettaglio |
|---|---:|---|
| `systemkc-all` ↔ root3 | **5/6** | tutti tranne `X6100HWLibs`, assente in root3 |
| `systemkc-all` ↔ root2 | **0/6** | stessi UUID, hash diversi; `X6100` differisce anche di 270.496 B |
| `systemkc-all` ↔ root25 | **0/6** | root25 ha solo metadati; nessun `Contents/MacOS` |
| root2 ↔ root3 | **0/6** | cinque root3 corrispondono a systemkc, non a root2; X6100 assente in root3 |

### 3.1 Il caso `X6100HWLibs`

| Fonte | Byte | SHA-256 | UUID |
|---|---:|---|---|
| `systemkc-all` | 16.985.840 | `e521d3cc…` | `533D1262` |
| root2 | 17.256.336 | `00b6214e…` | `533D1262` |
| root3 | **ASSENTE** | — | — |
| root25 | **NO_BINARY** (solo bundle/metadati) | — | — |

Root2 e `systemkc-all` condividono l’UUID ma **non** il binario: +270.496 B, hash diverso. La differenza non è spiegata dall’UUID e non rende root2 una copia esatta.

---

## 4. Interpretazione

### 4.1 PROVEN

- `systemkc-all` contiene **6** binari AMD; root3 contiene **5** di essi con SHA **identico**.
- root3 non contiene `X6100HWLibs`.
- root2 contiene tutti e sei, ma **0/6** ha SHA uguale a `systemkc-all`.
- root25 non contiene binari AMD: solo bundle/metadati.
- `X6100HWLibs` di root2 ha SHA diverso da `systemkc-all`.

### 4.2 Correzioni a documenti T27

La precedente affermazione **“root3 fornisce solo X6000: 1/6”** è **errata**: root3 fornisce **5/6** (tutti tranne X6100). Root3 `AMDRadeonX6000` ha hash `2734aaf7…`, **identico** a `systemkc-all`, non a root2 (`8874ae65…`). La correzione è applicata in `AMD-KEXT-CHAIN.md`, `REPORT.md` e `COMPATIBILITY-MATRIX.md`.

### 4.3 UNPROVEN

- Che root3 sia la **fonte** di `systemkc-all`: l’identità dei cinque binari è provata, la direzione della copia no.
- Che `systemkc-all` sia privo di modifiche: nessun manifest per-kext.
- La provenienza della X6100 `e521d3cc…`: non esiste copia esatta in root3/root25; root2 ha un binario diverso.
- L’ABI con 26B131 e il caricamento dei sei su 26B131.

---

## 5. Conclusione

| Domanda | Risposta |
|---|---|
| root3 contiene 5/6 binari identici a `systemkc-all`? | **PROVEN** (SHA) |
| root3 contiene X6100? | **NO** |
| root2 contiene copie esatte dei sei? | **NO**: 0/6 |
| root25 contiene binari AMD? | **NO**: solo metadati |
| X6100 di root2 è identico a `systemkc-all`? | **NO**: UUID uguale, SHA diverso |
| UUID uguali dimostrano identità? | **NO** |
| root3 è la fonte di `systemkc-all`? | **INFERRED**, non PROVEN |

La catena host 25G342 ha **5 componenti** con copia esatta in root3; il sesto, `X6100HWLibs`, esiste in `systemkc-all` (`e521d3cc…`) e in root2 in versione **diversa** (`00b6214e…`). Root3 non è una fonte completa per X6100.

**STOP rispettato:** sola lettura; nessuna estrazione, copia, modifica, build o boot. Spazio libero 12.920.044 KiB (12,32 GiB) > 10 GiB.
