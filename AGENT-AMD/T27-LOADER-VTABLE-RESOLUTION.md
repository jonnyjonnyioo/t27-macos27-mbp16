# T27 — AGENT-AMD — LOADER VTABLE RESOLUTION

**Scope:** identificare le destinazioni delle 33+8 call indirette di `addKextsFromKextCollection` e `registerDeferredKextCollection`; elencare offset vtable, registri e load; cercare vtable/RTTI/classi; verificare percorsi verso `PE_get_kc_*` o chained fixup.

**Modalità:** sola lettura; `lldb` su `__TEXT_EXEC`, parsing Mach-O, `nm`, `strings`; nessuna installazione, estrazione, modifica o boot.

**Esito:** le 41 indirette usano offset vtable **0x20–0x2E8**. I simboli `__ZTV` permettono di risolvere i metodi delle classi note: `OSDictionary::getObject`, `OSData::getLength`, `OSData::getBytesNoCopy`, `OSArray::getObject`, `OSObject::release`, `OSKext::getIdentifier`. **Nessun** metodo risolto è `PE_get_kc_*` e **nessun** offset porta a un loader chained. Il tipo runtime per singola call resta **non provato**. T27 resta **OPEN**.

---

## 1. Vtable note

| Classe | Simbolo | Indirizzo |
|---|---|---:|
| `OSDictionary` | `__ZTV12OSDictionary` | **0xFFFFFF8000259E80** |
| `OSData` | `__ZTV6OSData` | **0xFFFFFF8000259B88** |
| `OSArray` | `__ZTV7OSArray` | **0xFFFFFF8000259260** |
| `OSObject` | `__ZTV8OSObject` | **0xFFFFFF80002AE2C0** |
| `OSKext` | `__ZTV6OSKext` | **0xFFFFFF800025A508** |

**PROVEN:** i simboli vtable sono presenti.
**PROVEN:** `nm` riporta **4.199** simboli vtable.
**PROVEN:** `strings` non contiene `_ZTV`/`_ZTI`.

---

## 2. Metodi risolti

| Classe | Offset | Metodo |
|---|---:|---|
| `OSDictionary` | **0x28** | `OSObject::release` |
| `OSDictionary` | **0x38** | `getMetaClass` |
| `OSDictionary` | **0x120** | `initIterator` |
| `OSDictionary` | **0x130** | `getCount` |
| `OSDictionary` | **0x140** | `getCapacityIncrement` |
| `OSDictionary` | **0x1E8** | `removeObject(const char *)` |
| `OSDictionary` | **0x208** | **`getObject(const char *)`** |
| `OSData` | **0x28** | `OSObject::release` |
| `OSData` | **0x140** | **`getLength`** |
| `OSData` | **0x178** | **`getBytesNoCopy`** |
| `OSArray` | **0x130** | `getCount` |
| `OSArray` | **0x1E8** | **`getObject(unsigned int)`** |
| `OSKext` | **0x120** | `initWithPrelinkedInfoDict` |
| `OSKext` | **0x140** | `registerIdentifier` |
| `OSKext` | **0x178** | `getDependencies` |
| `OSKext` | **0x208** | `copyInfo` |
| `OSKext` | **0x268** | `getIdentifier` |
| `OSKext` | **0x2E8** | `isKernel` |

**PROVEN:** gli offset corrispondono ai metodi elencati per le classi indicate.
**UNPROVEN:** la classe runtime dell’oggetto a ogni call site.

---

## 3. `addKextsFromKextCollection` — 32 indirette

| Offset | N | Base | Metodo compatibile |
|---|---:|---|---|
| **0x208** | **3** | `%rax` | **`OSDictionary::getObject`** |
| **0x38** | **5** | `%rax` | `getMetaClass` |
| **0x130** | **5** | `%rax` | `getCount` |
| **0x1E8** | **1** | `%rax` | `OSArray::getObject` |
| **0x140** | **2** | `%rax` | `OSData::getLength` / `OSKext::registerIdentifier` |
| **0x178** | **1** | `%rax` | `OSData::getBytesNoCopy` |
| **0x28** | **5** | `%rax` | **`OSObject::release`** |
| **0x88** | **3** | `%rax` | `OSObject/OSCollection::init` |
| **0x118** | **1** | `%rax` | `iteratorSize` / `initWithCapacity` |
| **0x120** | **1** | `%rax` | `initIterator` / `initWithPrelinkedInfoDict` |
| **0x150** | **1** | `%rax` | `ensureCapacity` / `isLoadable` |
| **0x158** | **1** | **`%rcx`** | `flushCollection` / `resolveDependencies` |
| **0x268** | **2** | `%rax` | `getIdentifier` / `Dispatch` |
| **0x2E8** | **1** | `%rax` | `isKernel` / reserved |
| **Totale** | **32** | — | — |

**PROVEN:** 32 call indirette.
**PROVEN:** tutte le basi sono `%rax` tranne una `%rcx`.
**INFERRED:** `0x208` è `getObject` su `OSDictionary`, coerente con le chiavi `_PrelinkKCID`, `_PrelinkInfoDictionary` e `_PrelinkLinkKASLROffsets`.
**UNPROVEN:** la classe runtime delle altre basi.

---

## 4. `registerDeferredKextCollection` — 8 indirette

| Offset | N | Base | Metodo compatibile |
|---|---:|---|---|
| **0x38** | **2** | `%rax` | `getMetaClass` |
| **0x208** | **1** | `%rax` | `OSDictionary::getObject` |
| **0x140** | **2** | `%rax` | `OSData::getLength` / `registerIdentifier` |
| **0x178** | **1** | `%rax` | `OSData::getBytesNoCopy` |
| **0x20** | **1** | `%rax` | `OSObject::retain` |
| **0x28** | **1** | `%rax` | `OSObject::release` |
| **Totale** | **8** | — | — |

**PROVEN:** 8 call indirette.
**PROVEN:** nessuna base è una destinazione PE.

---

## 5. Percorsi verso `PE_get_kc_*`

| Accessor | In vtable note | In call risolte |
|---|---|---|
| `PE_get_kc_header` | **NO** | **NO** |
| `PE_get_kc_base_pointers` | **NO** | **NO** |
| `PE_get_kc_slide` | **NO** | **NO** |
| `PE_get_kc_format` | **NO** | **NO** |
| `PE_get_kc_baseaddress` | **NO** | **NO** |
| `PE_get_kc_vp` | **NO** | **NO** |

**PROVEN:** nessun metodo risolto è un accessor PE.
**PROVEN:** nessun offset vtable noto porta a PE.
**UNPROVEN:** un oggetto con vtable non nota.

---

## 6. Chained fixup

| Elemento | Trovato |
|---|---|
| `fixup_value` | **NO** |
| `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` | **NO** |
| metodo vtable chained | **NO** |
| chiamata a loader chained | **NO** |

**PROVEN:** nessun metodo risolto è un loader chained.
**UNPROVEN:** percorsi fuori dalle vtable note.

---

## 7. Limiti

| Limite | Effetto |
|---|---|
| tipo runtime per call | **non tracciato** |
| offset con più classi compatibili | **ambiguità** |
| vtable globali | **non tutte risolte** |
| RTTI typeinfo | **assente** |
| `0x158(%rcx)` | **base diversa** |

**PROVEN:** le destinazioni **non sono univocamente dimostrabili** per ogni call.
**STOP:** nessuna destinazione PE/chained dichiarata.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Vtable symbols? | **SÌ — 4.199** |
| Offset 0x208 risolto? | **SÌ — `OSDictionary::getObject`** |
| Offset 0x140 risolto? | **SÌ — `getLength` / `registerIdentifier`** |
| Offset 0x178 risolto? | **SÌ — `getBytesNoCopy`** |
| Qualche metodo PE? | **NO** |
| Qualche loader chained? | **NO** |
| Tipo runtime per call? | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** le 41 indirette usano vtable OS note; gli offset risolti corrispondono a `getObject`, `getLength`, `getBytesNoCopy`, `getCount`, `release`, `getIdentifier`. **Nessun** metodo è `PE_get_kc_*` o un loader chained. Il tipo runtime per singola call non è dimostrabile, quindi non si dichiara un percorso nascosto. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna installazione/estrazione/modifica/build/boot.
