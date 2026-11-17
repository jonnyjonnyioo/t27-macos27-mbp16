# T27 — AGENT-AMD — AUTH POINTER COMPARATIVE ANALYSIS

**Scope:** individuare tutti i puntatori **`isAuth=1`** nelle chained fixups del SystemKC, classificarne sorgente, target, bundle, sezione e simbolo, confrontare `cacheLevel`, `diversity`, `addrDiv`, `key` e verificare se il caso **X6100 HWLibs::superClass → 0x12AA488** è isolato o sistemico.

**Modalità:** sola lettura; parsing `LC_DYLD_CHAINED_FIXUPS`, provider e sezioni, Python. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** **55 auth pointer** trovati nella scansione, **+1 noto** in X6100 (`HWLibs::superClass`), per **56 totali**. **50** provengono da **X4000HWLibs**, **5** da **X4000**, **1** da **X6100**. I target sono **38 ignoti/esterni**, **17 in AMD10000Controller**, **1 in X4000** (`_polaris10_kicker_smc_firmware + 0x100D8`). **Nessun auth pointer verso un `gMetaClass`**. Il caso X6100 è **l’unico auth pointer noto verso firmware/dati**; il meccanismo auth è **sistemico in X4000**, ma l’anomalia semantica X6100 è **isolata**. T27 resta **OPEN**.

---

## 1. Metodo

1. Parse dei **172 provider** del SystemKC.
2. Parse di **4 segmenti** chained fixups; **2** con `pointer_format 11` (`X86_64_KERNEL_CACHE`).
3. Walk di **288 fixup**; estrazione di **55** con `isAuth=1`.
4. Aggiunta del fixup X6100 noto a `0xE11CA90` (raw `0x00C00000012AA488`), non catturato dal walk perché fuori catena.
5. Classificazione di sorgente, target, bundle, sezione, cache/key/addrDiv.

---

## 2. Totale

| Voce | Valore |
|---|---:|
| Provider | **172** |
| Fixup totali | **288** |
| **Auth pointer (scan)** | **55** |
| **Auth pointer noto X6100** | **1** |
| **Auth pointer totali** | **56** |
| Auth pointer verso `gMetaClass` | **0** |
| Auth pointer verso firmware/dati | **1** (X6100) |

**PROVEN:** gli auth pointer sono **56**; **nessuno** punta a un `gMetaClass`.

---

## 3. Sorgente

| Bundle | Auth | Quota |
|---|---:|---:|
| **`com.apple.kext.AMDRadeonX4000HWLibs`** | **50** | 89,29% |
| **`com.apple.kext.AMDRadeonX4000`** | **5** | 8,93% |
| **`com.apple.kext.AMDRadeonX6100HWLibs`** | **1** | 1,79% |
| **Totale** | **56** | 100% |

| Sezione sorgente | Auth |
|---|---:|
| **`__TEXT`** | **36** |
| **`__DATA`** | **19** |
| **`__DATA,__const` X6100** | **1** |
| **Totale** | **56** |

**PROVEN:** **55/56** sono in **X4000**; **1/56** in **X6100**.
**PROVEN:** **36** sono in **`__TEXT`**, quindi auth **function pointer**; **20** in **`__DATA`/`__const`**.

---

## 4. Target

| Target | Auth |
|---|---:|
| **UNKNOWN / esterno al KC** | **38** |
| **`AMD10000Controller`** | **17** |
| **X4000 `_polaris10_kicker_smc_firmware + 0x100D8`** | **1** |
| **`gMetaClass`** | **0** |
| **Totale** | **56** |

| Sezione target | Auth |
|---|---:|
| **UNKNOWN** | **38** |
| **`?` (provider senza sezione)** | **17** |
| **`__DATA,__data` X4000** | **1** |
| **Totale** | **56** |

**PROVEN:** **38** target non ricadono in alcun provider del KC; **17** in AMD10000Controller; **1** in X4000 `__data`.
**PROVEN:** **0** target `gMetaClass`.

---

## 5. Campi

| Campo | Distribuzione |
|---|---|
| **cacheLevel** | **3:17, 0:16, 2:12, 1:11** |
| **key** | **0:39, 1:6, 2:6, 3:5** |
| **addrDiv** | **0:31, 1:25** |
| **diversity=0** | **8** |
| **target ripetuti** | `0x16415341` ×2; gli altri ×1 |

**PROVEN:** il caso X6100 ha **cacheLevel=0, key=0, addrDiv=0, diversity=0**: non è il profilo dominante per `key`/`addrDiv`, ma è compatibile con una parte dei 56.
**PROVEN:** **8/56** hanno diversity nulla, incluso X6100.

---

## 6. X6100

| Simbolo | Address | Raw | Target | isAuth | Target valido |
|---|---:|---|---:|---:|---|
| X6100::metaClass | `0xE11C120` | rebase | `0xED11A10` | **0** | **gMetaClass** |
| X6100::superClass | `0xE11C128` | rebase | `0xED11A60` | **0** | **SWIP gMetaClass** |
| HWLibs::metaClass | `0xE11CA88` | rebase | `0xED11A38` | **0** | **HWLibs gMetaClass** |
| **HWLibs::superClass** | **`0xE11CA90`** | **`0x00C00000012AA488`** | **`0x12AA488`** | **1** | **NO — firmware** |
| SWIP::metaClass | `0xE11D3E8` | rebase | `0xED11A60` | **0** | **SWIP gMetaClass** |
| SWIP::superClass | `0xE11D3F0` | rebase | `0xED11A38` | **0** | **HWLibs gMetaClass** |

**PROVEN:** **5/6** fixup X6100 sono **non autenticati** e puntano a `gMetaClass`.
**PROVEN:** **1/6** è **autenticato** e punta a **firmware**.
**INFERRED:** l’anomalia X6100 è **isolata** nella gerarchia X6100.

---

## 7. Confronto con X4000

| Bundle | Auth | Target noti | Target firmware | Target metaclass |
|---|---:|---:|---:|---:|
| **X4000HWLibs** | **50** | 17 AMD10000 + 33 unknown | **0** | **0** |
| **X4000** | **5** | 0 | **0** | **0** |
| **X6100** | **1** | 0 | **1** | **0** |

**PROVEN:** **X4000 non ha auth pointer verso firmware**.
**PROVEN:** **X6100 è l’unico** con auth pointer verso firmware.
**UNPROVEN:** la natura dei **38 target unknown**; potrebbero essere codice kernel fuori KC.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Auth pointer totali | **56** |
| Auth pointer in X6100 | **1** |
| Auth pointer X6100 verso `gMetaClass` | **0** |
| Auth pointer X6100 verso firmware | **1** |
| Auth pointer X4000 verso firmware | **0** |
| Auth pointer verso `gMetaClass` | **0** |
| Meccanismo auth sistemico? | **SÌ, in X4000** |
| Anomalia X6100 isolata? | **SÌ, semanticamente** |
| Causa | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** gli **auth pointer** sono **56**, concentrati in **X4000** (**55/56**). **Nessuno** punta a un `gMetaClass`. Il caso **X6100 HWLibs::superClass → 0x12AA488** è **l’unico auth pointer noto verso firmware/dati**: è **isolato** e **semanticamente invalido**, mentre il meccanismo auth è **sistemico**. T27 resta **OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
