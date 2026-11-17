# T27 — AGENT-AMD — CORREZIONE ISAUTH=0 E REACHABILITY

**Scope:** correggere l’errore `isAuth=1` dei quattro record OOB; verificare il valore reale del bit 63, il walk completo delle due catene, la raggiungibilità statica di `_i386_slide_individual_kext` nel BootKC 26B131 e il comportamento del loader x86_64.

**Modalità:** sola lettura; SystemKC/BootKC, decode diretto, walk delle catene, simboli, disassemblaggio, scansione `E8 rel32`; nessuna modifica, build, patch, boot o download.

**Esito:** **CORREZIONE.** I quattro record OOB hanno `isAuth=0`, non `1`: il bit 63 è zero. Il walk completo dà **0 record auth** su **189** slot X5400 e **433** slot AMDSupport. Il loader x86_64 **non** prende il ramo `Unexpected authenticated fixup`; scrive il record corrente, applica `next=10`, legge il successore a cavallo di pagina, lo scrive e termina con `next=0`. La raggiungibilità **statica** del dispatcher è provata: `OSKext::loadExecutable` chiama `_i386_slide_individual_kext`; la raggiungibilità **runtime** dei due kext specifici resta **UNPROVEN**. **H5 “loader rifiuta” è REFUTED (auth)** per i quattro record; **H8 UNPROVEN**. T27 resta **OPEN**.

---

## 1. Correzione dell’errore

I report precedenti hanno letto `isAuth=1` guardando il nibble alto `0x5` del raw. Il campo `isAuth` è il **bit 63**, non il nibble alto: `0x5` = bit 62 acceso, bit 63 spento. Decodifica corretta:

```text
raw >> 63 = 0
```

**PROVEN:** `isAuth` è il bit 63.
**PROVEN:** i quattro raw OOB hanno bit 63 = **0**.
**PROVEN:** `isAuth=1` era un errore di lettura.
**RITIRATO:** ogni conclusione basata su “OOB isAuth=1”.

---

## 2. Decodifica dei quattro record

| Provider | Record | Byte | Raw | Target | Cache | `next` | `isAuth` |
| --- | --- | ---: | --- | ---: | ---: | ---: | ---: |
| X5400 | `0x9C78FF0` | `26 64 ca 48 00 00 50 00` | `0x0050000048CA6426` | `0x8CA6426` | **1** | **10** | **0** |
| X5400 T6 | `0x9C6CFF0` | `26 a4 c9 48 00 00 50 00` | `0x0050000048C9A426` | `0x8C9A426` | **1** | **10** | **0** |
| AMDSupport | `0x13C13FF4` | `e0 99 bb 53 00 00 50 00` | `0x0050000053BB99E0` | `0x13BB99E0` | **1** | **10** | **0** |
| AMDSupport T6 | `0x13C07FF4` | `e0 d9 ba 53 00 00 50 00` | `0x0050000053BAD9E0` | `0x13BAD9E0` | **1** | **10** | **0** |

**PROVEN:** tutti e quattro hanno `next=10`.
**PROVEN:** tutti e quattro hanno `isAuth=0`.
**PROVEN:** tutti e quattro hanno `cacheLevel=1`.
**PROVEN:** target/T6 differiscono di `0xC000`.

---

## 3. Walk completo delle due catene

| Provider | Page-start | Slot | Ultimo offset | Ultimo `next` | `isAuth=1` | Fine |
|---|---:|---:|---:|---:|---:|---:|
| X5400 | `0x698` | **189** | `0xFF0` | **10** | **0** | `0xFFA` |
| AMDSupport | `0x0` | **433** | `0xFF4` | **10** | **0** | `0xFFE` |

**PROVEN:** X5400 ha 189 slot, nessun auth.
**PROVEN:** AMDSupport ha 433 slot, nessun auth.
**PROVEN:** il record OOB è l’ultimo slot della catena.
**PROVEN:** non esiste un record auth precedente che possa fermare il loader prima dell’OOB.
**PROVEN:** il walk globale del SystemKC dà **0 `isAuth=1`** su **501.435** puntatori.

---

## 4. Successore a cavallo di pagina

| Provider | Successore | Byte | Raw | Target | Cache | `next` | `isAuth` |
|---|---:|---|---:|---:|---:|---:|---:|
| X5400 | `0xFFA` | `26 64 ca 48 00 00 00 00` | `0x0000000048CA6426` | `0x8CA6426` | **1** | **0** | **0** |
| AMDSupport | `0xFFE` | `10 9d bb 53 00 00 00 00` | `0x0000000053BB9D10` | `0x13BB9D10` | **1** | **0** | **0** |

**PROVEN:** X5400 legge 6 byte della pagina 3475 e 2 della 3476.
**PROVEN:** AMDSupport legge 2 byte della pagina 33 e 6 della 34.
**PROVEN:** entrambi i successori sono `isAuth=0` e `next=0`.
**PROVEN:** non sono slot dichiarati da `page_start`.
**PROVEN:** sono copie non allineate dei byte adiacenti.

---

## 5. Raggiungibilità statica

| Elemento | Valore |
|---|---|
| BootKC SHA-256 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| `_i386_slide_individual_kext` | `0xffffff80004c5a20` |
| File offset | `0x2c5a20` |
| Caller | `OSKext::loadExecutable` |
| Caller address | `0xffffff8000a294e0` |
| Call site | `0xffffff8000a29629` |
| Call | `callq 0xffffff80004c5a20` |
| Dopo la call | `testl %eax,%eax`; errore `0xdc00800c` |

```text
0xffffff8000a29626: movq   (%rax), %rsi        ; collection_base_pointers[i]
0xffffff8000a29629: callq  0xffffff80004c5a20  ; i386_slide_individual_kext
0xffffff8000a2962e: testl  %eax, %eax
0xffffff8000a29630: je     0xffffff8000a2963f
0xffffff8000a29632: movl   $0xdc00800c, %r15d
```

**PROVEN:** `_i386_slide_individual_kext` ha corpo e symbol.
**PROVEN:** `OSKext::loadExecutable` la chiama direttamente.
**PROVEN:** la funzione è il dispatcher per un `mach_header` di kext.
**PROVEN:** la funzione contiene il walk del formato 11.
**PROVEN:** `OSKext::mapKCFileSet` chiama `_i386_slide_kext_collection_mh_addrs` per il collection header.

---

## 6. X5400 e AMDSupport

| Provider | Fileset entry | Segmento | Page-start | Catena |
|---|---|---|---:|---:|
| X5400 | **SÌ** | `__DATA` | `0x698` | **189** |
| AMDSupport | **SÌ** | `__DATA` | `0x0` | **433** |

**PROVEN:** entrambi sono kext `LC_FILESET_ENTRY` del SystemKC.
**PROVEN:** entrambi hanno una catena formato 11 nel proprio `__DATA`.
**PROVEN:** se il loro `mach_header` passa a `OSKext::loadExecutable`, entrambi passano dallo stesso dispatcher.
**PROVEN:** non ci sono dispatcher alternativi noti.
**UNPROVEN:** che il boot 26B131 carichi effettivamente questi due kext e li passi a quella call.

---

## 7. Comportamento effettivo del loader

Con `isAuth=0`:

1. `fixup_value` calcola `basePointers[1] + target`.
2. non entra nel ramo auth.
3. scrive `raw64` sul record corrente **se `basePointers[1]` è non nullo**.
4. `walk_chain` legge `next=10`.
5. avanza a `0xFFA`/`0xFFE`.
6. legge 8 byte a cavallo di pagina.
7. il successore è `isAuth=0`, `next=0`.
8. scrive il successore **se `basePointers[1]` è non nullo**.
9. termina.

**PROVEN (statico):** non c’è stop per `isAuth`.
**PROVEN (statico):** il page crossing avviene.
**PROVEN (statico):** il successore viene scritto se `basePointers[1]` è non nullo.
**PROVEN:** non c’è page-bound check.
**PROVEN:** la scrittura cade su una copia non dichiarata.
**UNPROVEN:** che `basePointers[1]` sia non nullo a runtime.
**UNPROVEN:** l’effetto sul boot e l’eventuale corruzione osservabile.

---

## 8. H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H5** | loader rifiuta i 4 record per auth | **REFUTED (auth)** | `isAuth=0`; nessun ramo auth; scrive e avanza |
| **H8** | slot omesso | **UNPROVEN** | nessun metadato in-band |
| **H2** | distanza + bound | **SUPPORTATA** | 2.244 distanze; 2 sforamenti |
| **H3** | linker error | **INDIZIARIA** | successore copia shiftata; page-start corretto |

**PROVEN:** H5 è refutata come rifiuto auth per i quattro record.
**UNPROVEN:** un rifiuto per base nulla o altra causa.
**UNPROVEN:** H8.

---

## 9. Report ritirati o corretti

| Report | Correzione |
|---|---|
| `T27-OOB-PAC-PATH.md` | `isAuth=1` errato; non-PAC non ferma i record |
| `T27-OOB-X86-REACHABILITY.md` | `isAuth=1` errato; il successore è raggiungibile |
| `T27-OOB-HAS-APPLE-PAC.md` | `isAuth=1` errato; il valore della macro non decide questi record |
| `T27-HAS-APPLE-PAC-BINARY-PROOF.md` | il ramo non-PAC è provato, ma **non** si applica ai quattro OOB |
| `T27-OOB-FORMAT-SPEC-VERIFICATION.md` | la frase “4 record isAuth=1” è errata |

**PROVEN:** la correzione è registrata.
**PROVEN:** i report restano utili per la parte non-auth.
**RITIRATO:** l’uso di quei report per concludere un rifiuto dei quattro record.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| `isAuth` dei 4 OOB | **0** |
| Bit 63 | **0** |
| Walk X5400 | **189 slot, 0 auth** |
| Walk AMDSupport | **433 slot, 0 auth** |
| Loader non-PAC ferma i 4 record | **NO** |
| Page crossing | **SÌ (statico, base non nulla)** |
| Successore scritto | **SÌ (statico, base non nulla)** |
| Successore dichiarato | **NO** |
| Raggiungibilità statica | **SÌ** |
| Raggiungibilità runtime | **UNPROVEN** |
| H5 | **REFUTED (auth)** |
| H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** l’errore `isAuth=1` è corretto: il bit 63 è **0** in tutti e quattro i record, e il walk completo non trova alcun auth (189 e 433 slot). Il loader x86_64 non prende il ramo `Unexpected authenticated fixup`; se `basePointers[1]` non è nullo, scrive il record corrente, applica `next=10`, legge e scrive il successore a cavallo di pagina, poi termina con `next=0`. La raggiungibilità **statica** è provata da `OSKext::loadExecutable` → `_i386_slide_individual_kext`; quella **runtime** dei due kext resta **UNPROVEN**. **H5 REFUTED come rifiuto auth** per i quattro record; **H8 UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,20 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna modifica/build/patch/boot.
