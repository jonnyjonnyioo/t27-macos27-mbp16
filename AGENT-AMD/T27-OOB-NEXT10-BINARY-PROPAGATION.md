# T27 — AGENT-AMD — NEXT10: PROPAGAZIONE BINARIA

**Scope:** dimostrare staticamente se il percorso `next=10` di `_i386_slide_individual_kext` legge e scrive davvero gli slot successori oltre il limite di pagina, con ampiezza 8 byte, e separare il comportamento binario dal runtime.

**Modalità:** sola lettura; BootKC 26B131, disassemblaggio, decodifica byte, simulazione aritmetica; nessuna modifica, build, patch, boot o download.

**Esito:** **PROVEN nel binario.** Il loop legge 8 byte con `movq (%rax),%rcx`, scrive 8 byte con `movq %rsi,(%rax)` e avanza con `rax += (raw >> 51)`. Non esiste alcun confronto con `page_end`. Per X5400 `0xFF0 + 10 = 0xFFA`: il successore legge 6 byte della pagina 3475 e 2 della 3476. Per AMDSupport `0xFF4 + 10 = 0xFFE`: legge 2 byte della pagina 33 e 6 della 34. Entrambi i successori hanno `next=0`, quindi il loop li scrive e termina. **Runtime UNPROVEN**; l’esecuzione dipende da `basePointers[1]` non nullo. T27 resta **OPEN**.

---

## 1. Artefatti e SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| `T27-HAS-APPLE-PAC-BINARY-PROOF.md` | `cf67fadc1a97c9261ed4984508b9b1eb6449a3255a29a0ba5998cc9fccdad41f` |
| `T27-OOB-ISAUTH0-CORRECTION.md` | `39a48d1a18057297070f6b356bf44c294783d5c139a63553e86cd437287d318a` |

**PROVEN:** il BootKC analizzato è quello della build 26B131.
**PROVEN:** il report 84 e la correzione 85 sono gli artefatti usati.

---

## 2. Disassemblaggio del loop

```text
0xffffff80004c5d90: movq   (%rax), %rcx          ; read 8 byte
0xffffff80004c5d93: cmpw   $0xb, %si             ; pointer_format == 11
0xffffff80004c5d97: je     0xffffff80004c5da5
0xffffff80004c5da5: movl   %ecx, %esi
0xffffff80004c5da7: shrl   $0x1e, %esi           ; cacheLevel
0xffffff80004c5daa: movq   (%r15,%rsi,8), %rdx
0xffffff80004c5dae: testq  %rdx, %rdx
0xffffff80004c5db1: je     0xffffff80004c5e04    ; base null
0xffffff80004c5db3: testq  %rcx, %rcx
0xffffff80004c5db6: js     0xffffff80004c5e0d    ; isAuth
0xffffff80004c5db8: movl   %ecx, %esi
0xffffff80004c5dba: andl   $0x3fffffff, %esi     ; target
0xffffff80004c5dc0: addq   %rdx, %rsi
0xffffff80004c5dc3: movq   %rsi, (%rax)          ; write 8 byte
0xffffff80004c5dc6: movzwl 0x6(%r13), %esi
0xffffff80004c5dcb: cmpl   $0xb, %esi
0xffffff80004c5dce: je     0xffffff80004c5df0
0xffffff80004c5df0: cmpq   %r12, %rcx
0xffffff80004c5df3: jb     0xffffff80004c5e1d    ; next == 0
0xffffff80004c5df5: shrq   $0x33, %rcx           ; next = raw >> 51
0xffffff80004c5df9: addq   %rcx, %rax            ; rax += next
0xffffff80004c5dfc: jmp    0xffffff80004c5d90    ; loop
```

**PROVEN:** la lettura è `movq`, **8 byte**.
**PROVEN:** la scrittura è `movq`, **8 byte**.
**PROVEN:** l’avanzamento è `raw >> 51`, in byte.
**PROVEN:** non esiste `page_end`, `page_size` o maschera di pagina nel loop.

---

## 3. Ampiezza e indirizzamento

| Operazione | Istruzione | Ampiezza | Indirizzo |
|---|---|---:|---|
| Lettura corrente | `movq (%rax),%rcx` | **8 byte** | `page_base + offset` |
| Scrittura corrente | `movq %rsi,(%rax)` | **8 byte** | `page_base + offset` |
| Avanzamento | `shrq $0x33` + `addq` | **next byte** | `rax += next` |
| Lettura successore | `movq (%rax),%rcx` | **8 byte** | nuovo `rax` |
| Scrittura successore | `movq %rsi,(%rax)` | **8 byte** | nuovo `rax` |

**PROVEN:** non c’è allineamento forzato.
**PROVEN:** non c’è controllo del bordo pagina.
**PROVEN:** una lettura o scrittura di 8 byte può attraversare due pagine mappate.

---

## 4. Simulazione X5400

| Passo | Calcolo | Valore |
|---|---|---:|
| Page base | `0x9C78000` | — |
| Current | `0x9C78000 + 0xFF0` | `0x9C78FF0` |
| Current read | `8 byte` a `0x9C78FF0–0x9C78FF7` | dentro pagina |
| Current raw | `0x0050000048CA6426` | `next=10` |
| Current write | `8 byte` a `0x9C78FF0–0x9C78FF7` | dentro pagina |
| Next | `0x9C78FF0 + 10` | `0x9C78FFA` |
| Successor read | `8 byte` a `0x9C78FFA–0x9C79001` | **6 byte pagina 3475 + 2 pagina 3476** |
| Successor raw | `0x0000000048CA6426` | `next=0` |
| Successor write | `8 byte` a `0x9C78FFA–0x9C79001` | **attraversa il bordo** |
| Fine | `next=0` | catena terminata |

**PROVEN:** il successore inizia a `0xFFA`, dentro la pagina.
**PROVEN:** lo slot di 8 byte termina a `0x1001`, 2 byte nella pagina successiva.
**PROVEN:** la scrittura è a cavallo del bordo.

---

## 5. Simulazione AMDSupport

| Passo | Calcolo | Valore |
|---|---|---:|
| Page base | `0x13C13000` | — |
| Current | `0x13C13000 + 0xFF4` | `0x13C13FF4` |
| Current read | `8 byte` a `0x13C13FF4–0x13C13FFB` | dentro pagina |
| Current raw | `0x0050000053BB99E0` | `next=10` |
| Current write | `8 byte` a `0x13C13FF4–0x13C13FFB` | dentro pagina |
| Next | `0x13C13FF4 + 10` | `0x13C13FFE` |
| Successor read | `8 byte` a `0x13C13FFE–0x13C14005` | **2 byte pagina 33 + 6 pagina 34** |
| Successor raw | `0x0000000053BB9D10` | `next=0` |
| Successor write | `8 byte` a `0x13C13FFE–0x13C14005` | **attraversa il bordo** |
| Fine | `next=0` | catena terminata |

**PROVEN:** il successore inizia a `0xFFE`, dentro la pagina.
**PROVEN:** lo slot termina a `0x1005`, 6 byte nella pagina successiva.
**PROVEN:** la scrittura è a cavallo del bordo.

---

## 6. Condizioni

| Condizione | Effetto |
|---|---|
| `isAuth=0` | **ramo auth non preso** |
| `basePointers[1]` non nullo | **scrive e avanza** |
| `basePointers[1]` nullo | **stop a `Invalid cache level`** |
| `next=10` | **avanza di 10 byte** |
| `next=0` al successore | **termina la catena** |
| Page-end check | **assente** |
| Pagine mappate | **sì, stesso segmento** |
| Page fault | **no, se la mappatura è quella del file** |

**PROVEN:** il comportamento binario è quello descritto.
**UNPROVEN:** `basePointers[1]` non nullo a runtime.
**UNPROVEN:** la mappatura runtime e l’esecuzione effettiva.

---

## 7. Binario vs runtime

| Livello | Esito |
|---|---|
| Lettura 8 byte | **PROVEN** |
| Scrittura 8 byte | **PROVEN** |
| `next` in byte | **PROVEN** |
| Page crossing | **PROVEN staticamente** |
| `next=0` successore | **PROVEN** |
| Base non nulla | **UNPROVEN** |
| Boot reale | **UNPROVEN** |
| Corruzione osservabile | **UNPROVEN** |

**PROVEN:** il codice compilato legge e scrive gli slot a cavallo.
**UNPROVEN:** l’esecuzione sul sistema.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Lettura 8 byte | **SÌ** |
| Scrittura 8 byte | **SÌ** |
| `next=10` in byte | **SÌ** |
| Page-end check | **NO** |
| X5400 slot | `0xFFA–0x1001` |
| AMDSupport slot | `0xFFE–0x13C14005` |
| X5400 attraversa | **2 byte** |
| AMDSupport attraversa | **6 byte** |
| Successore `next=0` | **SÌ** |
| Scrittura successore | **SÌ, se base non nulla** |
| Runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il binario è esplicito. Il loop legge 8 byte, scrive 8 byte e avanza di `next` byte. Non esiste alcun controllo `page_end`. X5400 va da `0xFF0` a `0xFFA` e il suo slot termina a `0x1001`, 2 byte nella pagina 3476; AMDSupport va da `0xFF4` a `0xFFE` e termina a `0x13C14005`, 6 byte nella pagina 34. Entrambi i successori hanno `next=0` e vengono scritti se `basePointers[1]` è non nullo. Il comportamento binario è **PROVEN**; l’esecuzione runtime resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,20 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna modifica/build/patch/boot.
