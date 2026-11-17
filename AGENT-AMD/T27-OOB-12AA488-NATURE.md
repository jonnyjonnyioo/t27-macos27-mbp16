# T27 — AGENT-AMD — 12AA488 NATURE

> **RETTIFICA (Prompt 123):** i byte “codice” a `0xA29DCDE` erano il primo match `__PRELINK_INFO`, non un mapping valido; `__REGION19` è zero-filled e i segmenti top-level si sovrappongono. `0x12AA488` è un target L3 e non va letto come indirizzo VM. Vale il report 123.

**Scope:** verificare identità e natura del target `0x12AA488`, condiviso da X5000/X6000 Interface; ricostruire la mappatura Mach-O con vmaddr/fileoff e leggere i byte reali.

**Modalità:** sola lettura; SystemKC/BootKC, tabella segmenti, mapping VM/fileoff, byte originali; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che `0x12AA488` mappa a `__REGION19` fileoff `0xA29DCDE` e che i byte sono codice x86_64, non una struttura di classe. **UNPROVEN** l’identità della superclass. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 121 | `bb56538b77cf30969145921a8e1fa9a9d43a67d998c2b0ff1af5f69e98996d35` |
| Report 114 | `e60ceb180d7028ecbff2df76d1f25f8ca8ffd1fdafe740798f403017888698db` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Mapping VM/fileoff

| Segmento | vmaddr | fileoff | filesize | Offset | Fileoff reale |
|---|---:|---:|---:|---:|---:|
| `__PRELINK_INFO` | `0x3C000` | `0x245760` | `0x1359872` | `0x126E488` | `0x14B3BE8` |
| `__REGION12` | `0x2AA000` | `0x2793472` | `0x4157440` | `0x1000488` | `0x37938FA` |
| `__REGION18` | `0x6E7000` | `0x7237632` | `0x2740224` | `0xBC3488` | `0x7DFAABA` |
| `__REGION19` | `0x984000` | `0x9977856` | `0x11550720` | `0x926488` | `0xA29DCDE` |

**PROVEN:** i segmenti si sovrappongono in VM.
**PROVEN:** il mapping non è vmaddr=fileoff.
**UNPROVEN:** quale segmento sia effettivamente mappato.

---

## 3. Byte a `__REGION19`

```text
fileoff 0xA29DCDE:
9D 85 00 00 E8 4B 2A FF FF 0D 00 01 00 00 4C 89
FF BE 9D 85 00 00 89 C2 E8 07 2B FF FF C7 45 98
A7 85 00 00 48 B8 40 02 00 00 40 02 00 00 48 89
45 A0 C7 04 24 08 00 00 00 41 BE 01 00 00 00 4C
```

| Test | Esito |
|---|---|
| Codice x86_64 | **SÌ** |
| `call rel32` | **SÌ** |
| `mov`/`movabs` | **SÌ** |
| Vtable | **NO** |
| Class descriptor | **NO** |
| Zero-fill | **NO** |

**PROVEN:** i byte sono istruzioni.
**PROVEN:** non è una struttura di classe.
**UNPROVEN:** il punto di ingresso.

---

## 4. Disassemblaggio parziale

```text
E8 4B 2A FF FF   call  -0xD5B5
4C 89 FF         mov   %r15,%rdi
BE 9D 85 00 00   mov   $0x859D,%esi
89 C2            mov   %eax,%edx
E8 07 2B FF FF   call  -0xD4F9
C7 45 98 A7 85 00 00   movl $0x85A7,-0x68(%rbp)
48 B8 40 02 00 00 40 02 00 00   movabs $0x24000000240,%rax
48 89 45 A0      mov   %rax,-0x60(%rbp)
```

| Elemento | Valore |
|---|---|
| Codice | **x86_64** |
| Funzione | **UNPROVEN** |
| Entry point | **UNPROVEN** |
| Superclass | **NO** |

**PROVEN:** è codice.
**PROVEN:** non è una classe.
**UNPROVEN:** la funzione.

---

## 5. X5000/X6000 Interface

| Classe | `superClass` | Raw | Target |
|---|---:|---:|---:|
| X5000 Interface | `0x457F368` | `0xC00000012AA488` | `0x12AA488` |
| X6000 Interface | `0xC270370` | `0xC00000012AA488` | `0x12AA488` |

**PROVEN:** il target è condiviso.
**PROVEN:** è codice, non classe.
**UNPROVEN:** il rapporto con la superclass.

---

## 6. Natura del campo

| Ipotesi | Stato |
|---|---|
| Puntatore a class descriptor | **REFUTED** |
| Puntatore a codice | **PROVEN** |
| Puntatore a metaclass | **UNPROVEN** |
| Puntatore a constructor | **UNPROVEN** |
| Puntatore a vtable | **NO** |

**PROVEN:** il campo punta a codice.
**REFUTED:** class descriptor.
**UNPROVEN:** il ruolo.

---

## 7. Conseguenze

| Domanda | Risposta |
|---|---|
| `0x12AA488` è una classe | **NO** |
| È codice | **SÌ** |
| Superclass reale | **UNPROVEN** |
| Eredità | **UNPROVEN** |
| Pubblicazione | **UNPROVEN** |
| Matching | **UNPROVEN** |

---

## 8. X6000HWLibs

| Requisito | Valore |
|---|---|
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `LoadPlugIn=Load6000` |
| Interface completa | **SÌ** |
| Interface pubblicata | **UNPROVEN** |
| Matching | **UNPROVEN** |

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Mapping `0x12AA488` | `__REGION19` |
| Fileoff | `0xA29DCDE` |
| Byte | **codice x86_64** |
| Class descriptor | **NO** |
| Superclass | **UNPROVEN** |
| Pubblicazione | **UNPROVEN** |
| Matching | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `0x12AA488` mappa a `__REGION19` fileoff `0xA29DCDE`; i byte sono codice x86_64 (`call`, `mov`, `movabs`), non una struttura di classe. Il campo `superClass` di X5000/X6000 Interface punta quindi a codice, non a un class descriptor: la superclass reale e il ruolo del campo restano **UNPROVEN**. La pubblicazione di Interface e il matching X6000HWLibs restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
