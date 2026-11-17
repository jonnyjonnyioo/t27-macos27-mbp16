# T27 — AGENT-AMD — NX STUBS ANALYSIS

**Scope:** classificare le 708 branch stub con destinazione NX per segmento, cluster GOT e pattern; confrontarle con le 956 RX; trovare callsite/xref, in particolare nel cluster `0x10162`–`0x1018C`; stabilire se `0x1016E` è ricorrente o anomalo.

**Modalità:** sola lettura; SystemKC, AMDSupportPart; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **CATEGORIA RICORRENTE**. Le stub NX sono 708, distribuite su sette segmenti NX; `0x1016E` è in un cluster di 8 stub NX e ha 3 callsite. Non è un caso isolato; il target resta dati NX e la semantica runtime **UNPROVEN**. T27 **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| AMDSupportPart | `849ccf34c3976f6859eee962f2fc829c27061dff8d0b0526a1561d374f3b5cf4` |
| Report 146 | `313bf4f6783eb2795b49bbe581c43eb37146ea8f0c353dbb61e88659d89ea58f` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Conteggi

| Categoria | Count |
|---|---:|
| Stub totali | `1669` |
| NX (`0x3`) | `708` |
| RX (`0x5`) | `956` |
| Altri | `5` |

**PROVEN:** 708 NX e 956 RX.
**PROVEN:** 1669 stub totali.

---

## 3. NX per segmento

| Segmento | Count | Quota |
|---|---:|---:|
| `__REGION25` | `353` | 49,9% |
| `__REGION19` | `266` | 37,6% |
| `__REGION22` | `48` | 6,8% |
| `__REGION4` | `32` | 4,5% |
| `__REGION7` | `5` | 0,7% |
| `__REGION5` | `3` | 0,4% |
| `__REGION1` | `1` | 0,1% |

**PROVEN:** le NX non sono concentrate solo in `__REGION19`.
**PROVEN:** `__REGION25` è il gruppo maggiore.

---

## 4. RX per segmento

| Segmento | Count |
|---|---:|
| `__REGION12` | `434` |
| `__REGION18` | `400` |
| `__REGION3` | `73` |
| `__REGION27` | `37` |
| `__REGION6` | `11` |
| `__REGION9` | `1` |

**PROVEN:** le RX sono 956.
**PROVEN:** `__REGION12/18` coprono 834 stub.

---

## 5. GOT NX

| GOT page | Count |
|---|---:|
| `0x24000` | `286` |
| `0x25000` | `337` |
| `0x26000` | `67` |
| `0x27000` | `18` |

**PROVEN:** le NX usano quattro pagine GOT.
**PROVEN:** il picco è la pagina `0x25000`.

---

## 6. Run NX

| Voce | Valore |
|---|---:|
| Run contigui | `107` |
| Run massimo | `606` byte |
| Cluster `0x10162`–`0x1018C` | `8` stub |
| Stub NX chiamate in A | `24` |
| Callsite NX in A | `107` |

**PROVEN:** 107 run NX.
**PROVEN:** il cluster `0x10162`–`0x1018C` contiene 8 stub.
**PROVEN:** 24 stub NX hanno callsite in AMDSupportPart.

---

## 7. Cluster `0x10162`–`0x1018C`

| Stub | Target | Segmento | Callsite |
|---:|---:|---|---|
| `0x10162` | `0x9A7630` | `__REGION19` | `0x28A98C`, `0x28AAF8` |
| `0x10168` | `0x9BDE00` | `__REGION19` | `0x28C3DA` |
| `0x1016E` | `0x9A7640` | `__REGION19` | `0x27C545`, `0x27C55C`, `0x28C021` |
| `0x10174` | `0x9BD500` | `__REGION19` | `0x28BFF2` |
| `0x1017A` | `0x9BD150` | `__REGION19` | `0x28BFE1` |
| `0x10180` | `0x9A48F0` | `__REGION19` | `0x2916BC`, `0x2918CB` |
| `0x10186` | `0x9A4930` | `__REGION19` | `0x291720`, `0x291748` |
| `0x1018C` | `0x9A5FA0` | `__REGION19` | `0x29227A`, `0x29B6AA` |

**PROVEN:** 14 callsite nel cluster.
**PROVEN:** `0x1016E` ha 3 callsite.
**PROVEN:** il terzo callsite è `0x28C021`.
**PROVEN:** tutti i target sono `__REGION19` NX.

---

## 8. Pattern NX vs RX

| Elemento | NX | RX |
|---|---|---|
| Byte | `ff 25 disp32` | `ff 25 disp32` |
| Lunghezza | 6 | 6 |
| GOT | `__BRANCH_GOTS` | `__BRANCH_GOTS` |
| Target | NX | RX |
| Formato | identico | identico |

**PROVEN:** la forma binaria è identica.
**PROVEN:** cambia solo il target/protezione.
**UNPROVEN:** la semantica della categoria NX.

---

## 9. Xref GOT

| Ricerca | Count |
|---|---:|
| `0x241E8` qword | `0` |
| `0x241E8` dword | `6` |
| `0x241D8` qword | `0` |
| `0x241D8` dword | `1` |

**PROVEN:** nessun riferimento qword.
**PROVEN:** sei occorrenze dword per `0x241E8`.
**UNPROVEN:** quante siano xref reali.

---

## 10. Categoria di 0x1016E

| Test | Esito |
|---|---|
| Target NX | **SÌ** |
| Cluster | **8 stub** |
| Callsite | **3** |
| Unico | **NO** |
| Ricorrente | **SÌ** |
| Anomalia isolata | **NO** |
| Runtime | **UNPROVEN** |

**PROVEN:** `0x1016E` è rappresentativo di una categoria NX.
**REFUTED:** anomalia isolata.
**UNPROVEN:** scopo della categoria.

---

## 11. STOP

| Criterio | Esito |
|---|---|
| Statistiche | **SÌ** |
| Cluster | **SÌ** |
| Callsite | **SÌ** |
| Categoria | **NX ricorrente** |
| Scopo runtime | **UNPROVEN** |
| Spazio >10 GiB | **SÌ** |
| Modifiche | **NO** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente con certezza.

---

## 12. Conclusione

| Domanda | Risposta |
|---|---|
| NX totali | `708` |
| RX totali | `956` |
| NX principali | `__REGION25` 353, `__REGION19` 266 |
| Cluster `0x1016E` | 8 stub |
| Callsite `0x1016E` | 3 |
| Target | `0x9A7640` NX |
| Anomalia isolata | **NO** |
| Categoria | **NX ricorrente** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** le 708 stub NX non sono un caso isolato: sono una categoria ricorrente, con 353 target in `__REGION25`, 266 in `__REGION19` e altri 89 distribuiti; le RX sono 956, concentrate in `__REGION12/18`. La forma binaria delle stub è identica (`ff 25 disp32`); cambia solo il target e la protezione. `0x1016E` appartiene a un cluster di 8 stub NX (`0x10162`–`0x1018C`) e ha 3 callsite reali (`0x27C545`, `0x27C55C`, `0x28C021`); non è un’anomalia unica, ma il suo target `0x9A7640` resta dati NX e la semantica runtime è **UNPROVEN**. STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
