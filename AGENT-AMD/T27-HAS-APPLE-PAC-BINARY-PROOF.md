# T27 — AGENT-AMD — HAS_APPLE_PAC: BINARY PROOF 26B131

> **CORREZIONE 2026-11-17:** il ramo non-PAC è provato, ma i 4 record OOB hanno `isAuth=0` e **non** lo attivano. La parte che li dichiara rifiutati è **RITIRATA**. Vedi `T27-OOB-ISAUTH0-CORRECTION.md`.

**Scope:** stabilire il valore effettivo di `HAS_APPLE_PAC` nel percorso x86_64 della build 26B131, senza dipendere dai soli header KDK, e verificare se i record AMD `isAuth=1` vengono rifiutati.

**Modalità:** sola lettura; BootKC x86_64, simboli, disassemblaggio mirato, mappatura VA→file offset; nessuna modifica, build, patch o boot.

**Esito:** **PROVEN.** Il codice x86_64 compilato contiene il ramo **non-PAC**: `testq %rcx,%rcx; js` salta a `"Unexpected authenticated fixup\n"`, imposta `eax=1` e **non scrive** il fixup. Il ramo `sign_pointer` non è presente in questa funzione. Quindi `HAS_APPLE_PAC` **non è attivo** nel percorso x86_64 26B131 e i 4 record OOB `isAuth=1` vengono **rifiutati sul record corrente**, senza applicare `next=10` e senza raggiungere il successore. **H5 SUPPORTATA**; **H8 UNPROVEN**. T27 resta **OPEN**.

---

## 1. Artefatto e mappatura

| Elemento | Valore |
|---|---|
| File | `BootKernelExtensions.kc` |
| SHA-256 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Arch | **x86_64** |
| `__TEXT` vmaddr | `0xffffff8000200000` |
| `__TEXT` fileoff | `0` |
| Funzione | `_i386_slide_individual_kext` |
| VA funzione | `0xffffff80004c5a20` |
| File offset | `0x2c5a20` |
| Byte iniziali | `55 48 89 e5 41 57 41 56 41 55 41 54 53 48 83 ec` |

**PROVEN:** `nm` espone `_i386_slide_individual_kext` a `0xffffff80004c5a20`.
**PROVEN:** `xxd` a `0x2c5a20` restituisce gli stessi byte del disassemblaggio.
**PROVEN:** la mappatura VA→file offset è corretta.

---

## 2. Disassemblaggio decisivo

```text
0xffffff80004c5d90: movq   (%rax), %rcx              ; raw64
0xffffff80004c5d93: cmpw   $0xb, %si                 ; pointer_format == 11
0xffffff80004c5d97: je     0xffffff80004c5da5
0xffffff80004c5d9f: jne    0xffffff80004c5e21
0xffffff80004c5da5: movl   %ecx, %esi
0xffffff80004c5da7: shrl   $0x1e, %esi               ; cacheLevel
0xffffff80004c5daa: movq   (%r15,%rsi,8), %rdx
0xffffff80004c5dae: testq  %rdx, %rdx
0xffffff80004c5db1: je     0xffffff80004c5e04        ; Invalid cache level
0xffffff80004c5db3: testq  %rcx, %rcx
0xffffff80004c5db6: js     0xffffff80004c5e0d        ; isAuth == 1
0xffffff80004c5db8: movl   %ecx, %esi
0xffffff80004c5dba: andl   $0x3fffffff, %esi         ; target
0xffffff80004c5dc0: addq   %rdx, %rsi
0xffffff80004c5dc3: movq   %rsi, (%rax)              ; write
0xffffff80004c5dc6: movzwl 0x6(%r13), %esi
0xffffff80004c5dcb: cmpl   $0xb, %esi
0xffffff80004c5dce: je     0xffffff80004c5df0
0xffffff80004c5df0: cmpq   %r12, %rcx
0xffffff80004c5df3: jb     0xffffff80004c5e1d
0xffffff80004c5df5: shrq   $0x33, %rcx               ; next = bits 51..62
0xffffff80004c5df9: addq   %rcx, %rax                ; advance
0xffffff80004c5dfc: jmp    0xffffff80004c5d90
0xffffff80004c5e0d: leaq   ...(%rip), %rdi           ; "Unexpected authenticated fixup\n"
0xffffff80004c5e14: xorl   %eax, %eax
0xffffff80004c5e16: callq  ...
0xffffff80004c5e1b: jmp    0xffffff80004c5e38
0xffffff80004c5e38: movl   $0x1, %eax                ; stop = 1
```

**PROVEN:** il test `isAuth` è il bit 63 (`testq` + `js`).
**PROVEN:** `isAuth=1` salta a `"Unexpected authenticated fixup\n"`.
**PROVEN:** il salto **non** esegue `movq %rsi,(%rax)`.
**PROVEN:** il ramo di errore imposta `stop=1`.
**PROVEN:** `sign_pointer` non è presente in questa funzione.
**PROVEN:** `next` per il formato 11 è `raw >> 51`, aggiunto in byte.
**PROVEN:** non c’è alcun confronto con `page_end`.

---

## 3. Valore di `HAS_APPLE_PAC`

| Evidenza | Esito |
|---|---|
| Ramo `sign_pointer` | **assente** |
| Ramo `"Unexpected authenticated fixup"` | **presente** |
| Scrittura dopo `isAuth=1` | **assente** |
| `stop=1` dopo `isAuth=1` | **presente** |
| Macro effettiva nel percorso | **non attiva** |
| `HAS_APPLE_PAC` | **0 per questo codice x86_64** |

**PROVEN:** il compilato x86_64 usa il ramo non-PAC.
**PROVEN:** la macro non è attiva in questa funzione.
**LIMITE:** la prova è sulla funzione `_i386_slide_individual_kext`, non su ogni TU del kernel.
**UNPROVEN:** una variante in un’altra funzione non disassemblata.

---

## 4. Effetto sui 4 record OOB

| Provider | Record | `isAuth` | Non-PAC |
|---|---|---:|---|
| X5400 | `0x9C78FF0` | **1** | **stop, no write, no next** |
| X5400 T6 | `0x9C6CFF0` | **1** | **stop, no write, no next** |
| AMDSupport | `0x13C13FF4` | **1** | **stop, no write, no next** |
| AMDSupport T6 | `0x13C07FF4` | **1** | **stop, no write, no next** |

**PROVEN:** ogni record OOB `isAuth=1` viene rifiutato sul posto.
**PROVEN:** `next=10` non viene applicato.
**PROVEN:** il successore a cavallo di pagina non viene letto.
**PROVEN:** il page crossing non avviene per questi record.
**INDICATIVO:** se il record è in una catena caricata, il segmento si ferma lì.
**UNPROVEN:** il comportamento di boot completo e l’ordine dei record.

---

## 5. H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H5** | loader rifiuta | **SUPPORTATA** | ramo non-PAC compilato; `stop=1` |
| **H8** | slot omesso | **UNPROVEN** | nessun conteggio in-band |
| **H2** | distanza + bound | **SUPPORTATA** | 2.244 distanze; 2 sforamenti |
| **H3** | linker error | **INDIZIARIA** | coda non terminata |

**PROVEN:** H5 è supportata dal binario.
**UNPROVEN:** H8.

---

## 6. Distinzione epistemica

| Categoria | Contenuto |
|---|---|
| **PROVEN** | ramo non-PAC nel binario; `isAuth=1` → stop; no write; no next |
| **SUPPORTED** | i 4 OOB sono rifiutati sul record corrente |
| **INDICATIVE** | il segmento si ferma al primo `isAuth=1` |
| **UNPROVEN** | boot completo; ordine dei record; altre TU |

**PROVEN:** la distinzione è completa.
**UNPROVEN:** il comportamento runtime globale.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| `HAS_APPLE_PAC` attiva in x86_64 | **NO, per questa funzione** |
| Ramo `sign_pointer` | **assente** |
| Ramo `Unexpected authenticated fixup` | **presente** |
| `isAuth=1` scrive il fixup | **NO** |
| `isAuth=1` applica `next=10` | **NO** |
| I 4 OOB raggiungono il successore | **NO** |
| Page crossing per i 4 OOB | **NO** |
| H5 | **SUPPORTATA** |
| H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il binario x86_64 26B131 contiene il ramo non-PAC: `testq %rcx,%rcx; js` porta a `"Unexpected authenticated fixup\n"`, imposta `stop=1` e **non scrive** né applica `next`. Il ramo `sign_pointer` non è presente. Quindi `HAS_APPLE_PAC` non è attiva in questa funzione e i 4 record OOB `isAuth=1` vengono rifiutati **sul record corrente**, senza page crossing. **H5 SUPPORTATA**; **H8 UNPROVEN**; il comportamento di boot completo resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,20 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna modifica/build/patch/boot.
