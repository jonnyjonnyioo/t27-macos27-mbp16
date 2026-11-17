# T27 — AGENT-AMD — AGDC VENDOR PROTOCOL / COMMAND 3 (168)

**Scope:** ricostruire il protocollo AGDC del comando 3; verificare come `doDeviceAttribute`/`filtered_doDeviceAttribute` validano e inoltrano `in`, `inSize`, `out`, `outSize`; identificare il consumer virtuale del buffer; stabilire se AGDC produca o soltanto trasporti il bit `0x2`; confrontare l'immagine 26.7.2/25G325 con il KDK 27.2/26B116 e con il target 26.7.3/25G342.

**Modalità:** sola lettura. Nessun boot, trace, modifica, build o download. Comandi: `find`, `nm`, `otool`, `strings`, `plutil`, `shasum`, `df`.

**Esito:** **PROVEN** che il comando 3 di `AppleGraphicsDeviceControl` valida un input di 4 byte, esegue un effetto collaterale HDA solo se il primo byte ha il bit `0x4`, e poi **inoltra lo stesso comando e lo stesso buffer** a un callback virtuale (`*0x858`). **PROVEN** che il ramo Apple non produce, non cancella e non maschera il bit `0x2`. **PROVEN** che nel binario AGDC non esistono call dirette a `doDeviceAttribute`/`vendor_doDeviceAttribute` e non esiste alcuna scrittura del buffer. **INFERRED** che il bit `0x2` sia costruito dal caller esterno (client/plugin AGDC) e trasportato invariato fino al Wrangler AMD. **UNPROVEN** l'identità del caller, il valore effettivo sul target e l'equivalenza byte-per-byte con la build 25G342. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| AGDC `AppleGraphicsDeviceControl` — root2 26.7.2/25G325 | `a3effd46c2c22692019da818ecab43703b44bcb5e2357c174d1b1546fcc633a3` |
| AGDC `Info.plist` — root2 | `d521d429dbf95570ec5f6469d1286a846d30739be75e2fe1e1af6244431a5188` |
| AGDC `AppleGraphicsDeviceControl` — KDK 27.2/26B116 | `ea39241b0c99dae2fb4dd81a33af0b36e1c0ffd1ad04283140ea51555486a1d7` |
| AGDC `Info.plist` — KDK 27.2/26B116 | `f7980d85dd58900b16365a79aaa1c4b8c644264092af8057d864b303078c8268` |
| X6000Framebuffer executable | `a2469429602210e64a74292a30b06353d9e0f75cd6b8b65f98324e64fa0b4536` |
| AMDSupport executable | `c569698b689d3822ce3f18a51202b10f46f48e395e80a339dc3bae403754f2a4` |
| HWServices `Info.plist` | `c6dcc67430bbbff1490e7101d395b3dbcfe248c10adc889efd59dd1689810bf0` |
| Report 167 | `c0574f1983c75f39d1b13932a5cdd1c3911882b1ed1e66a859fbc9b94c07cd43` |

**Target:** macOS `26.7.3`, build `25G342`, MacBookPro16,1.
**Immagine AGDC più vicina:** root2 `26.7.2`, build `25G325`, `CFBundleVersion=8.1.12`, `DTSDKBuild=25G325`.
**KDK disponibile:** `KDK_27.2.1_26B131`, AGDC `26B116`, quindi **non** target.
**Spazio:** **15.403.056 KiB ≈ 14,69 GiB** > 10 GiB.

### 1.1 Ponte verso il target

| Evidenza | Stato |
|---|---|
| `Info.plist` AGDC target (SHA `d521…`) | **PROVEN byte-identico** a root2 |
| Eseguibile AGDC target 25G342 | **ASSENTE** dal root locale |
| Eseguibile AGDC root2 25G325 | **PROVEN** SHA `a3eff…` |
| Eseguibile AGDC KDK 26B116 | **PROVEN** SHA `ea392…` |
| Equivalenza binaria target ↔ root2 | **UNPROVEN** |

**PROVEN:** il plist AGDC del target è identico a quello di root2; non prova che lo sia l'eseguibile.
**PROVEN:** root2 è la migliore approssimazione statica disponibile, a una build di distanza.
**UNPROVEN:** che il codice 25G325 sia identico a 25G342.

---

## 2. Entry point: `doDeviceAttribute`

### 2.1 Firma e marshalling

`AppleGraphicsDeviceControl::doDeviceAttribute` — root2 `0x2c00`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x2c00` | `doDeviceAttribute` | entry |
| `0x2c04` | `movq %r9, %rax` | salva `outSize` |
| `0x2c07` | `movq %r8, %r9` | `out` → arg6 |
| `0x2c0a` | `movq %rcx, %r8` | `inSize` → arg5 |
| `0x2c0d` | `movq %rdx, %rcx` | `in` → arg4 |
| `0x2c10` | `movl %esi, %edx` | `cmd` → arg3 |
| `0x2c12`–`0x2c1c` | normalizzazione null | input/output null → size 0 |
| `0x2c20` | `movl $0x2, %esi` | `api = 2` |
| `0x2c25` | `pushq $0x0` | `state = NULL` |
| `0x2c27` | `pushq %rax` | `outSize` |
| `0x2c28` | `call filtered_doDeviceAttribute` | dispatch |

**PROVEN:** `doDeviceAttribute(cmd, in, inSize, out, outSize)` inoltra a `filtered_doDeviceAttribute(api=2, cmd, in, inSize, out, outSize, NULL)`.
**PROVEN:** `in` è il puntatore del caller; AGDC non lo copia e non lo inizializza in questa funzione.
**PROVEN:** il percorso pubblico passa dall'API filtrata con `api=2`.

### 2.2 Assenza di call dirette

| Ricerca su root2 | Esito |
|---|---|
| `callq` diretto a `doDeviceAttribute 0x2c00` | **0** |
| `callq` diretto a `vendor_doDeviceAttribute 0x2c34` | **0** |
| `callq` diretto a `AGDCPlugin::doDeviceAttribute 0x33d4` | **0** |
| call al costruttore/vtable | **indirette** |

**PROVEN:** l'ingresso è virtuale o via user client; non esiste un call site statico nominato.
**UNPROVEN:** quale oggetto/plug-in riempia il slot virtuale sul target.

---

## 3. `filtered_doDeviceAttribute`: comando 3

### 3.1 Dispatch

`AppleGraphicsDeviceControl::filtered_doDeviceAttribute` — root2 `0x17b0`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x17b0` | entry | `api, cmd, in, inSize, out, outSize, state` |
| `0x17c4` | `movq %r9, %r15` | salva `out` |
| `0x17c7` | `movq %rcx, %r10` | salva `in` |
| `0x17ca` | `movl %edx, %r13d` | salva `cmd` |
| `0x1cba` | `cmpl $0x3, %r13d` | confronto comando 3 |
| `0x1cbe` | `je 0x22f0` | salto al ramo |

**PROVEN:** il comando **3** ha un ramo dedicato a `0x22f0`.
**PROVEN:** il valore di `cmd` non viene riscritto prima del ramo.

### 3.2 Validazione input/output

Ramo comando 3 — root2 `0x22f0`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x22f0` | `testq %r8, %r8` | `inSize == 0`? |
| `0x22f3` | `je 0x2310` | sì: salta il controllo input |
| `0x22f5` | `cmpq $0x4, %r8` | `inSize == 4`? |
| `0x22f9` | `setne %al` | errore se diverso |
| `0x22fc` | `testq %r10, %r10` | `in != NULL`? |
| `0x22ff` | `sete %cl` | errore se nullo |
| `0x230a` | `jne 0x28ca` | uscita errore |
| `0x2310` | `testq %r11, %r11` | `outSize != NULL`? |
| `0x2315` | `movq (%r11), %rax` | valore `*outSize` |
| `0x231d` | `cmpq $0x4, %rax` | `*outSize == 4`? |
| `0x2324` | `testq %r15, %r15` | `out != NULL`? |
| `0x2332` | `jne 0x28ca` | uscita errore |

**PROVEN:** se `inSize` è diverso da zero, deve essere **4** e `in` non nullo.
**PROVEN:** se `outSize` è presente, il suo valore deve essere **4** e `out` non nullo.
**PROVEN:** il comando 3 è un contratto a **4 byte** per input e output.
**UNPROVEN:** il significato dei 4 byte oltre al bitmask.

### 3.3 Effetto HDA: bit `0x4`, non `0x2`

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x2338` | `xorl %ebx, %ebx` | default |
| `0x233a` | `testq %r10, %r10` | input presente? |
| `0x2343` | `testb $0x1, 0xb5(%rdi)` | gate HDA |
| `0x2350` | `testb $0x4, (%r10)` | **bit 0x4** nel primo byte input |
| `0x2354` | `je 0x2789` | senza bit → inoltro |
| `0x235a` | `testb $0x1, 0xb6(%rdi)` | già pubblicato? |
| `0x2367` | `movb $0x1, 0xb6(%rdi)` | marca pubblicazione |
| `0x236e` | `call publishHdaGfxProperties` | effetto collaterale |
| `0x2387` | `jmp 0x2789` | inoltro al vendor |

**PROVEN:** il ramo Apple del comando 3 testa **solo** il bit `0x4` per l'effetto HDA.
**PROVEN:** `publishHdaGfxProperties` è a `0x1150`.
**PROVEN:** non c'è alcun `testb $0x2` nel ramo.
**PROVEN:** il bit `0x2` non viene letto, scritto, mascherato o cancellato qui.
**INFERRED:** AGDC tratta `0x2` come payload opaco del vendor, non come flag Apple.

### 3.4 Inoltro invariato al vendor

Dopo il ramo HDA, il comando 3 confluisce nel blocco comune `0x2789`:

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0x2789` | `movq (%rdi), %rax` | vtable del controller |
| `0x278c` | `movq %rdx, (%rsp)` | settimo argomento |
| `0x2790` | `movl %r13d, %esi` | `cmd` invariato |
| `0x2793` | `movq %r10, %rdx` | `in` invariato |
| `0x2796` | `movq %r8, %rcx` | `inSize` invariato |
| `0x2799` | `movq %r15, %r8` | `out` invariato |
| `0x279c` | `movq %r11, %r9` | `outSize` invariato |
| `0x279f` | `callq *0x858(%rax)` | callback virtuale |

**PROVEN:** il comando 3 viene inoltrato al slot virtuale **`0x858`**.
**PROVEN:** l'input non viene copiato né modificato tra `0x22f0` e `0x279f`.
**PROVEN:** il bit `0x2` può attraversare questo percorso senza essere toccato da AGDC.
**INFERRED:** `0x858` è il consumer vendor/plug-in; l'implementazione target non è in questo binario.
**UNPROVEN:** che il slot `0x858` del target punti al Wrangler AMD.

---

## 4. Metodi virtuali e consumer

### 4.1 Slot osservati

| Metodo | Indirizzo root2 | Slot chiamato |
|---|---:|---|
| `AppleGraphicsDeviceControl::doDeviceAttribute` | `0x2c00` | `filtered` diretto |
| `AppleGraphicsDeviceControl::vendor_doDeviceAttribute` | `0x2c34` | `*0x850` |
| `AppleGraphicsDeviceControl::filtered_doDeviceAttribute` | `0x17b0` | `*0x858` |
| `AGDCPlugin::doDeviceAttribute` | `0x33d4` | `*0x858` su oggetto `0x108` |
| `AGDCPlugin::doPluginAttribute` | `0x340e` | `jmp *0x890` |

**PROVEN:** `vendor_doDeviceAttribute` root2 `0x2c34` non costruisce input: legge `state->0x38` e chiama `*0x850`.
**PROVEN:** `AGDCPlugin::doDeviceAttribute` root2 `0x33d4` inoltra a `*0x858` dell'oggetto a `0x108`.
**PROVEN:** `AGDCPlugin::doPluginAttribute` root2 `0x340e` salta a `*0x890`.
**INFERRED:** esistono più livelli virtuali (controller, plugin, vendor) e il buffer resta sempre quello del caller.
**UNPROVEN:** quale di questi slot sia usato dal percorso reale del comando 3.

### 4.2 Nessun produttore nel binario

| Ricerca | Esito |
|---|---|
| scrittura del primo word di `in` | **0** |
| `movl $0x2, (%reg)` sull'input | **0** |
| `orl $0x2` sull'input | **0** |
| `testb $0x2` nel ramo comando 3 | **0** |
| stringa `LoadHWServices` | **0** |
| call dirette ai metodi | **0** |

**PROVEN:** AGDC non inizializza il bit `0x2`.
**PROVEN:** AGDC non nomina `LoadHWServices`.
**PROVEN:** il bit deve arrivare già valorizzato nel buffer del caller.
**UNPROVEN:** chi lo valorizzi.

### 4.3 Indizi sul caller

Stringhe presenti in root2:

| Stringa | Indizio |
|---|---|
| `com.apple.private.applegraphicsdevicecontrol` | entitlement del client AGDC |
| `com.apple.private.gpuwrangler` | entitlement del client GPU |
| `WindowServer` | client privilegiato |
| `AGDCC: Unauthorized client '%s' blocked` | controllo di autorizzazione |

**PROVEN:** AGDC ha un percorso client autorizzato con entitlement dedicati.
**INFERRED:** il buffer può essere costruito da un client/plug-in privilegiato, non dal Wrangler.
**UNPROVEN:** il nome e il codice del client che invia il comando 3 con `0x2`.

---

## 5. Correzione del 167

| Affermazione 167 | Esito 168 |
|---|---|
| Il comando 3 porta il bit `0x2` | **CONFERMATO come carrier** |
| AGDC produce il bit `0x2` | **REFUTED**: non lo scrive |
| Il ramo Apple del comando 3 è il produttore | **REFUTED**: testa `0x4` per HDA |
| Il buffer è esterno | **CONFERMATO** |
| Il bit attraversa AGDC invariato | **PROVEN** |
| Caller identificato | **UNPROVEN** |

**PROVEN:** il 167 aveva ragione sul comando e sul bit, ma non aveva distinto **carrier** e **produttore**.
**PROVEN:** il comando 3 è il contenitore; il bit `0x2` è il payload.
**UNPROVEN:** l'origine del payload.

---

## 6. Confronto versioni

| Build | AGDC SHA | `CFBundleVersion` | `DTSDKBuild` | Comando 3 | Bit HDA |
|---|---|---|---:|---|---|
| root2 26.7.2 | `a3eff…` | 8.1.12 | 25G325 | **presente** | `0x4` |
| KDK 27.2 | `ea392…` | 8.1.12 | 26B116 | **presente** | `0x4` |
| target 26.7.3 | **assente** | 8.1.12 (plist) | 25G342 | **UNPROVEN** | **UNPROVEN** |

**PROVEN:** root2 e KDK condividono la stessa struttura del comando 3 e il bit HDA `0x4`.
**PROVEN:** nessuno dei due contiene `LoadHWServices` o un test `0x2`.
**INFERRED:** la separazione carrier/produttore è stabile tra 26.7.2 e 27.2.
**UNPROVEN:** il binario esatto 25G342.

---

## 7. Catena ricostruita

```text
caller esterno (client/plugin AGDC)
  └─ costruisce in[0] = 4 byte, con bit 0x2
       └─ AppleGraphicsDeviceControl::doDeviceAttribute(cmd=3, in, 4, out, outSize)
            └─ filtered_doDeviceAttribute(api=2, cmd=3, in, 4, out, outSize, NULL)
                 ├─ validazione: inSize 0/4, outSize 0/4
                 ├─ se in[0] & 0x4: publishHdaGfxProperties()
                 └─ call *0x858(cmd=3, in, 4, out, outSize, ...)
                      └─ implementazione vendor/plugin
                           └─ AmdGpuWrangler::vendor_doDeviceAttribute
                                └─ se in[0] & 0x2: setProperty("LoadHWServices", true)
```

**PROVEN:** il percorso Apple non altera `in`.
**PROVEN:** il bit `0x2` è compatibile con il buffer a 4 byte.
**INFERRED:** il Wrangler AMD è raggiunto tramite il callback virtuale.
**UNPROVEN:** il caller e il valore runtime.

---

## 8. Significato del bit `0x4` vs `0x2`

| Bit | Consumatore | Effetto | Stato |
|---:|---|---|---|
| `0x4` | AGDC Apple | `publishHdaGfxProperties` | **PROVEN root2** |
| `0x2` | AMD Wrangler | `LoadHWServices` + `LoadAccelerator` | **PROVEN codice AMD; runtime UNPROVEN** |
| `0x6` | entrambi | HDA + load | **INFERRED** |

**PROVEN:** i due bit hanno consumatori diversi.
**PROVEN:** non sono alias.
**INFERRED:** un caller può inviare `0x6` per ottenere entrambi gli effetti.
**UNPROVEN:** la maschera usata sul target.

---

## 9. Prova minima necessaria

| Prova | Cosa dimostra | Stato |
|---|---|---|
| binario AGDC 25G342 | equivalenza con root2 | **ASSENTE** |
| call site/user client del comando 3 | identità del caller | **ASSENTE** |
| buffer `in` osservato | presenza di `0x2` | **ASSENTE** |
| `ioreg` con `LoadHWServices=true` | effetto runtime | **ASSENTE** |
| trace AGDC del comando 3 | sequenza reale | **VIETATO in T27** |

**PROVEN:** nessuna delle prove runtime è disponibile.
**PROVEN:** la prova statica ha separato carrier e produttore.
**UNPROVEN:** il valore effettivo sul MacBookPro16,1.

---

## 10. Diagnosi

| Priorità | Elemento | Stato |
|---:|---|---|
| 1 | comando 3 come carrier | **PROVEN** |
| 2 | validazione 4 byte | **PROVEN** |
| 3 | inoltro invariato a `0x858` | **PROVEN** |
| 4 | bit `0x2` non prodotto da AGDC | **PROVEN** |
| 5 | caller e buffer | **UNPROVEN** |
| 6 | Wrangler raggiunto sul target | **INFERRED** |
| 7 | `LoadHWServices=true` runtime | **UNPROVEN** |

**Diagnosi:** il collo di bottiglia non è più il comando né il produttore AMD; è il **caller AGDC** che costruisce il buffer a 4 byte. AGDC valida e trasporta, ma non genera il bit `0x2`. Il comando 3 è il carrier corretto; il bit `0x4` è un effetto HDA parallelo e non sostituisce `0x2`.

---

## 11. Verdetto

| Domanda | Risposta |
|---|---|
| Comando carrier | **3** |
| Dimensione input | **4 byte** |
| AGDC scrive `0x2`? | **NO** |
| AGDC altera il buffer? | **NO** |
| Bit HDA Apple | **`0x4`** |
| Bit LoadHWServices AMD | **`0x2`** |
| Callback vendor | **`*0x858`** |
| Caller identificato | **NO — UNPROVEN** |
| Target 25G342 dimostrato | **NO — binario assente** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il comando 3 è il **carrier** provato del bit `0x2`, ma non il produttore. `AppleGraphicsDeviceControl` valida un input di 4 byte, esegue l'effetto HDA solo sul bit `0x4` e inoltra comando e buffer invariati al callback virtuale `*0x858`; il bit `0x2` attraversa AGDC senza essere toccato e raggiunge il Wrangler AMD. Resta **UNPROVEN** chi costruisca il buffer e se sul target 25G342 contenga `0x2`. La prossima prova statica è il call site/user client del comando 3, non un altro ramo del Wrangler. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **15.403.056 KiB ≈ 14,69 GiB** > 10 GiB. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
