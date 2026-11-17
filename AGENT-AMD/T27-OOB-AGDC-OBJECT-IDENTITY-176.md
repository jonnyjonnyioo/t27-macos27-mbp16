# T27 — OOB AGDC — Identità dell'oggetto e dispatch verso il Wrangler — Report 176

**Data:** 17 novembre 2026
**Sistema:** macOS 26.7.3 build 25G342, MacBookPro16,1
**Modalità:** sola analisi statica; nessun boot, trace, modifica, build o download.
**Vincolo spazio:** minimo 10 GiB liberi; nessun file eliminato.
**Stato T27:** **OPEN — 94% engineering / 32% first boot / 8% desktop.**

---

## 1. Ambiente e SHA-256

Target:

```text
/System/Library/KernelCollections/SystemKernelExtensions.kc
SHA-256: b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7
```

Report:

```text
HAO-PROJECT/T27/AGENT-AMD/T27-OOB-AGDC-OBJECT-IDENTITY-176.md
```

Comandi usati: `nm`, `ndisasm`, `otool`, `strings`, `python3`, `sha256sum`, `shasum -a 256`.
Nessun comando ha modificato il target o il sistema.

---

## 2. Correzione metodologica: vptr e simbolo della vtable

Questo report usa offset **relativi al vptr dell'oggetto**, non al simbolo `__ZTV...`.

Per una classe C++:

```text
symbol __ZTV...   = inizio della vtable
vptr dell'oggetto = __ZTV... + 0x10
slot oggetto +N   = memoria a (vptr + N)
```

Quindi:

```text
Wrangler:  __ZTV 0xc1f07b0, vptr 0xc1f07c0
AGDC:      __ZTV 0x13d44478, vptr 0x13d44488
AGDCPlugin:__ZTV 0x13d44e28, vptr 0x13d44e38
```

La verifica con `vptr + offset` produce i valori già riportati nel report 175; la lettura con `__ZTV + offset` sarebbe sfalsata di 0x10 e non va usata.

---

## 3. AMDRadeonX6000_AmdGpuWrangler: costruzione e vtable

### 3.1 Metaclasse e superclasse

Simboli:

```text
0xc1f07a0  __ZN29AMDRadeonX6000_AmdGpuWrangler9metaClassE
0xc1f07a8  __ZN29AMDRadeonX6000_AmdGpuWrangler10superClassE
0xc1f07b0  __ZTV29AMDRadeonX6000_AmdGpuWrangler
0xc262648  __ZN29AMDRadeonX6000_AmdGpuWrangler10gMetaClassE
```

Contenuto:

```text
[0xc1f07a0] = 0x4000004c262648  -> 0xc262648 (gMetaClass Wrangler)
[0xc1f07a8] = 0xc0000053d458e8  -> 0x13d458e8 (AppleGraphicsDeviceControl::gMetaClass)
```

`0x13d458e8` è il simbolo:

```text
__ZN26AppleGraphicsDeviceControl10gMetaClassE
```

**PROVEN:** la superclasse dichiarata del Wrangler è `AppleGraphicsDeviceControl`.
**PROVEN:** il Wrangler è una sottoclasse concreta di AGDC, non una classe indipendente.

### 3.2 Costruttori

`AMDRadeonX6000_AmdGpuWrangler::AmdGpuWrangler(OSMetaClass const*)` a `0xbf9841e`:

```asm
0xbf9841e  push rbp
0xbf9841f  mov rbp,rsp
0xbf98422  push rbx
0xbf98423  push rax
0xbf98424  mov rbx,rdi
0xbf98427  call 0x13d3fe34        ; AppleGraphicsDeviceControl::AppleGraphicsDeviceControl(OSMetaClass const*)
0xbf9842c  lea rax,[rel 0xc1f07c0]
0xbf98433  mov [rbx],rax          ; vptr = Wrangler
0xbf98436  add rsp,0x8
0xbf9843a  pop rbx
0xbf9843b  pop rbp
0xbf9843c  ret
```

`C1` a `0xbf9843e` è identico quanto a flusso: chiama `0x13d3fe34`, poi scrive `0xc1f07c0`.
`C1()` a `0xbf9854e` e `C2()` a `0xbf9857e` fanno lo stesso, passando `gMetaClass` del Wrangler.
`MetaClass::alloc()` a `0xbf984f2` alloca `0x148` byte, chiama il costruttore e imposta il vptr.

**PROVEN:** ogni costruttore Wrangler invoca prima il costruttore AGDC e poi sovrascrive il vptr con `0xc1f07c0`.
**PROVEN:** la dimensione dell'istanza Wrangler è `0x148` byte.

### 3.3 Vtable del Wrangler

Lettura con `vptr = 0xc1f07c0`:

```text
+0x850  0xc1f1010  raw 0x4000004bf9894e  -> 0xbf9894e
+0x858  0xc1f1018  raw 0x40000053d41c34  -> 0x13d41c34
+0x860  0xc1f1020  raw 0x40000053d42078  -> 0x13d42078
+0x868  0xc1f1028  raw 0x40000053d4208c  -> 0x13d4208c
+0x870  0xc1f1030  raw 0x40000053d420a2  -> 0x13d420a2
+0x890  0xc1f1050  raw 0x40000053d420fa  -> 0x13d420fa
```

Significati:

```text
0xbf9894e = AMDRadeonX6000_AmdGpuWrangler::vendor_doDeviceAttribute(...)
0x13d41c34 = AppleGraphicsDeviceControl::vendor_doDeviceAttribute(...)  [wrapper]
0x13d42078 = AppleGraphicsDeviceControl::_RESERVEDAppleGraphicsDeviceControl0()
0x13d4208c = _RESERVED...1()
0x13d420a2 = _RESERVED...2()
0x13d420fa = _RESERVED...6()
```

**PROVEN:** lo slot `+0x850` del Wrangler è il vendor Wrangler `0xbf9894e`.
**PROVEN:** lo slot `+0x858` del Wrangler è il wrapper AGDC `0x13d41c34`.
**PROVEN:** lo slot `+0x890` del Wrangler è `0x13d420fa`, non il vendor Wrangler e non `doPluginAttribute`.

### 3.4 Start del Wrangler

`AMDRadeonX6000_AmdGpuWrangler::start(IOService*)` a `0xbf987c2`:

```asm
0xbf987cf  mov rax,[rel 0xc1de110]   ; AGDC vtable / IOService super
0xbf987d6  call qword [rax+0x5d0]    ; super::start
0xbf987dc  test al,al
0xbf987de  jz 0xbf9886d
0xbf987e4  mov rax,[rel 0xc1de088]
0xbf987eb  mov rsi,[rax]
0xbf987ee  mov rdi,r14              ; provider
0xbf987f1  call 0x1007e             ; helper importato
0xbf987f6  mov [rbx+0x110],rax      ; provider / service
0xbf98802  lea rdi,[rel 0xc14f454]  ; "IOWorkLoop"
0xbf98809  call 0x1015c
0xbf9880e  mov [rbx+0x128],rax      ; workloop
0xbf98815  mov rax,[rbx]
0xbf9881b  xor esi,esi
0xbf9881d  call [rax+0x5b0]         ; registerService
0xbf98823  call 0x101c2
0xbf98838  call [rax+0x2b8]
```

**PROVEN:** `Wrangler::start` chiama lo start della superclasse IOService tramite `[+0x5d0]`; non chiama `AppleGraphicsDeviceControl::start` a `0x13d40392`.
**PROVEN:** il Wrangler inizializza `[+0x110]` (provider/service) e `[+0x128]` (workloop).
**UNPROVEN:** se i campi `[+0xb5]` e `[+0xb6]`, usati dal percorso comando 3, siano inizializzati a zero dal costruttore o restino valori non inizializzati. Il costruttore AGDC a `0x13d3fe34` chiama solo `OSObject` e imposta il vptr; non azzera esplicitamente quei byte.

---

## 4. AppleGraphicsDeviceControl: classe base astratta

### 4.1 Costruttore e vptr

`AppleGraphicsDeviceControl::AppleGraphicsDeviceControl(OSMetaClass const*)` a `0x13d3fe34`:

```asm
0x13d3fe34  push rbp
0x13d3fe35  mov rbp,rsp
0x13d3fe38  push rbx
0x13d3fe39  push rax
0x13d3fe3a  mov rbx,rdi
0x13d3fe3d  call 0x10180          ; OSObject constructor
0x13d3fe42  lea rax,[rel 0x13d44488]
0x13d3fe49  mov [rbx],rax          ; vptr = AGDC
0x13d3fe4c  add rsp,0x8
0x13d3fe50  pop rbx
0x13d3fe51  pop rbp
0x13d3fe52  ret
```

**PROVEN:** il costruttore base imposta il vptr AGDC `0x13d44488`.

### 4.2 Allocazione della classe base

`AppleGraphicsDeviceControl::MetaClass::alloc()` a `0x13d3fe9e`:

```asm
0x13d3fe9e  push rbp
0x13d3fe9f  mov rbp,rsp
0x13d3fea2  xor eax,eax
0x13d3fea4  pop rbp
0x13d3fea5  ret
```

**PROVEN:** l'allocatore della metaclasse AGDC restituisce `NULL`.
**PROVEN:** `AppleGraphicsDeviceControl` non è istanziabile direttamente come oggetto concreto nel target.

### 4.3 Vtable AGDC

Lettura con `vptr = 0x13d44488`:

```text
+0x850  0x13d44cd8  raw 0x40000000ab77f0  -> 0xab77f0
+0x858  0x13d44ce0  raw 0x40000053d41c34  -> 0x13d41c34
+0x860  0x13d44ce8  raw 0x40000053d42078  -> 0x13d42078
+0x868  0x13d44cf0  raw 0x40000053d4208c  -> 0x13d4208c
+0x870  0x13d44cf8  raw 0x40000053d420a2  -> 0x13d420a2
+0x890  0x13d44d18  raw 0x40000053d420fa  -> 0x13d420fa
```

`0xab77f0` è in `__REGION49`, `vmaddr/fileoff 0xa895000`, `maxprot/initprot = 3` (RW), con byte non codice x86_64. Non è il vendor Wrangler.

**PROVEN:** la vtable base AGDC usa `0xab77f0` nello slot `+0x850`.
**PROVEN:** `0xab77f0` non è codice eseguibile e non è `0xbf9894e`.
**INFERRED:** un'istanza base AGDC non può essere il receiver valido del percorso comando 3, perché il wrapper chiamerebbe `0xab77f0`.

---

## 5. Percorso client: dal provider a filtered

### 5.1 initWithTask

`AppleGraphicsDeviceControlClient::initWithTask(task*, void*, unsigned int)` a `0x13d3f9b4`:

```asm
0x13d3fa01  call 0x106de
0x13d3fa06  mov [rbx+0xe0],rax      ; lock
0x13d3fa16  mov rax,0xaaaaaaaaaaaaaaaa
0x13d3fa24  mov [r13+0x0],rax
0x13d3fa3b  mov [rbx+0xe8],r14b
0x13d3fa42  mov [rbx+0xd8],r14      ; azzera il puntatore al servizio
0x13d3fa81  mov [rbx+0x111],r14b
0x13d3fa88  mov [rbx+0xf0],rbx      ; self
0x13d3fa8f  mov [rbx+0xf8],r12      ; task
0x13d3fa96  mov [rbx+0x108],r15d
0x13d3faa1  mov [rbx+0x100],rax     ; provider
```

**PROVEN:** `[client+0xd8]` è azzerato in `initWithTask`.
**PROVEN:** `client_start` è il punto in cui `[client+0xd8]` viene valorizzato.

### 5.2 client_start

`AppleGraphicsDeviceControlClient::start(IOService*)` a `0x13d3faee`:

```asm
0x13d3faf8  mov r15,rsi             ; provider
0x13d3fafb  mov rbx,rdi             ; client
0x13d3fafe  mov rdi,[rdi+0xe0]      ; lock
0x13d3fb05  call 0x106f0
0x13d3fb0a  mov rax,[rel 0x13d43040]
0x13d3fb11  mov rdi,rbx
0x13d3fb14  mov rsi,r15
0x13d3fb17  call [rax+0x5d0]        ; super::start
0x13d3fb20  lea rax,[rel 0x13d44468] ; &AppleGraphicsDeviceControl::metaClass
0x13d3fb27  mov rsi,[rax]           ; metaClass AGDC
0x13d3fb2a  mov rdi,r15             ; provider
0x13d3fb2d  call 0x1007e            ; helper importato
0x13d3fb32  mov [rbx+0xd8],rax      ; servizio AGDC/Wrangler
0x13d3fb39  mov rdi,[rbx+0xe0]
0x13d3fb40  call 0x106f6
0x13d3fb45  mov rdi,[rbx+0xd8]
0x13d3fb4c  test rdi,rdi
0x13d3fb4f  jz 0x13d3fb91
0x13d3fb51  lea rdx,[rbx+0x130]
0x13d3fb58  mov esi,0x80
0x13d3fb5d  xor ecx,ecx
0x13d3fb5f  call 0x13d4078e         ; getDeviceAttribute(0x80,...)
0x13d3fb64  test byte [rbx+0x130],0x1
0x13d3fb6b  jz 0x13d3fbab
0x13d3fb6d  mov rdi,[rbx+0xd8]
0x13d3fb74  lea rdx,[rbx+0xf0]
0x13d3fb7b  mov ecx,0x40
0x13d3fb80  mov esi,0x81
0x13d3fb85  call 0x13d41bdc         ; setDeviceAttribute(0x81,...)
```

**PROVEN:** `[client+0xd8]` riceve il risultato di `0x1007e(provider, AGDC::metaClass)`.
**PROVEN:** subito dopo, `[client+0xd8]` è usato come `this` per `getDeviceAttribute` e `setDeviceAttribute`, metodi di `AppleGraphicsDeviceControl`.
**PROVEN:** quindi `[client+0xd8]` è il servizio AGDC/Wrangler del provider, non il client.

Il target della call `0x1007e` è un import:

```text
GOT 0x240a8: 0x4000000091c540  -> 0x91c540 (helper kernel, simbolo non presente nel kc)
```

**UNPROVEN:** il nome esatto dell'helper `0x1007e`; la sua semantica precisa non è disponibile nel solo `SystemKernelExtensions.kc`.

### 5.3 externalMethod

`AppleGraphicsDeviceControlClient::externalMethod(...)` a `0x13d3f6dc`:

```asm
0x13d3f6f3  mov r13,rdi             ; client
0x13d3f6f0  mov r14d,esi            ; selector
0x13d3f6ed  mov r15,rdx             ; args
0x13d3f796  mov rdi,[r13+0xd8]      ; servizio AGDC/Wrangler
0x13d3f79d  lea rdx,[rbp-0x68]      ; stato/args
0x13d3f7a1  mov esi,r14d            ; selector
0x13d3f7a4  call 0x13d41e60         ; UserKernelTransfer
```

**PROVEN:** il client non passa se stesso a `UserKernelTransfer`; passa `[client+0xd8]`.
**PROVEN:** lo stesso puntatore del servizio attraversa tutto il percorso.

### 5.4 UserKernelTransfer

`AppleGraphicsDeviceControl::UserKernelTransfer(unsigned int, AGDCClientState_t*)` a `0x13d41e60`:

```asm
0x13d41e71  mov [rbp-0x2c],esi      ; selector
0x13d41e74  mov [rbp-0x58],rdi      ; this = servizio
0x13d41e78  mov [rbp-0x60],rdx      ; args
0x13d41e7c  mov r14,[rdx+0x38]
0x13d41e80  mov r15,[r14+0x40]
0x13d41f37  mov r9,[r14+0x58]
0x13d41fac  lea rax,[rbp-0x68]
0x13d41fb0  mov rdi,[rbp-0x58]      ; stesso this
0x13d41fb4  mov esi,0x3             ; API = 3
0x13d41fb9  mov edx,[rbp-0x2c]      ; selector esterno
0x13d41fbc  mov r8,r15
0x13d41fbf  push qword [rbp-0x60]
0x13d41fc2  push rax
0x13d41fc3  call 0x13d407b0         ; filtered_doDeviceAttribute
```

**PROVEN:** `UserKernelTransfer` conserva `this` in `[rbp-0x58]` e lo passa intatto a `filtered`.
**PROVEN:** il secondo argomento di `filtered` è `esi=3` (API), mentre il selettore esterno è `edx=[rbp-0x2c]`.
**PROVEN:** non esiste una conversione o un secondo oggetto tra `[client+0xd8]`, `UserKernelTransfer` e `filtered`.

### 5.5 filtered

`AppleGraphicsDeviceControl::filtered_doDeviceAttribute(...)` a `0x13d407b0`:

```asm
0x13d407ca  mov r13d,edx            ; selector
0x13d407e5  mov [rbp-0x38],rdi      ; this
0x13d407e9  mov [rbp-0x30],rcx
0x13d407ed  mov [rbp-0x40],r8
0x13d407db  xor r14d,r14d
0x13d407de  cmp r13d,0x2001
```

**PROVEN:** `r13d` è il selettore esterno; `[rbp-0x38]` è il servizio AGDC/Wrangler.
**PROVEN:** il receiver di `filtered` è esattamente il puntatore passato da `UserKernelTransfer`.

---

## 6. Comando 3: condizioni e dispatch

### 6.1 Ingresso nel ramo 3

```asm
0x13d40cba  cmp r13d,0x3
0x13d40cbe  jz 0x13d412f0
```

**PROVEN:** il selettore esterno 3 entra nel blocco a `0x13d412f0`.

### 6.2 Validazione ABI

```asm
0x13d412f0  test r8,r8
0x13d412f3  jz 0x13d41310
0x13d412f5  cmp r8,0x4
0x13d412f9  setnz al
0x13d412fc  test r10,r10
0x13d412ff  setz cl
0x13d41302  mov r12d,0xe00002c2
0x13d41308  or cl,al
0x13d4130a  jnz 0x13d418ca       ; errore ABI
0x13d41310  test r11,r11
0x13d41313  jz 0x13d41338
0x13d41315  mov rax,[r11]
0x13d41318  test rax,rax
0x13d4131b  jz 0x13d41338
0x13d4131d  cmp rax,0x4
0x13d41321  setnz al
0x13d41324  test r15,r15
0x13d41327  setz cl
0x13d4132a  mov r12d,0xe00002c2
0x13d41330  or cl,al
0x13d41332  jnz 0x13d418ca       ; errore ABI
0x13d41338  xor ebx,ebx
0x13d4133a  test r10,r10
0x13d4133d  jz 0x13d41789         ; dispatch generico
0x13d41343  test byte [rdi+0xb5],0x1
0x13d4134a  jz 0x13d41789         ; dispatch generico
0x13d41350  test byte [r10],0x4
0x13d41354  jz 0x13d41789         ; dispatch generico
0x13d4135a  test byte [rdi+0xb6],0x1
0x13d41361  jnz 0x13d41789        ; dispatch generico
0x13d41367  mov byte [rdi+0xb6],0x1
0x13d4136e  call 0x13d40150       ; publishHdaGfxProperties
0x13d41387  jmp 0x13d41789        ; dispatch generico
```

Regole ricavabili:

```text
r8 (dimensione input)  = 0 oppure 4
se r8 == 4: r10 (input) != NULL
r11 (dimensione output) = 0 oppure 4
se r11 != NULL: [r11] = 0 oppure 4; r15 (output) != NULL
```

**PROVEN:** se la validazione fallisce, il ritorno è `0xe00002c2` e il wrapper non viene chiamato.
**PROVEN:** se la validazione passa, **tutti** i percorsi vanno a `0x13d41789`; nessuno va a `doPluginAttribute`.
**PROVEN:** i flag `[+0xb5]`, `[r10] bit 2` e `[+0xb6]` non cambiano il dispatch: al massimo saltano l'effetto collaterale `publishHdaGfxProperties`.

### 6.3 Dispatch generico

```asm
0x13d41789  mov rax,[rdi]          ; vptr del servizio
0x13d4178c  mov [rsp],rdx
0x13d41790  mov esi,r13d           ; selector = 3
0x13d41793  mov rdx,r10
0x13d41796  mov rcx,r8
0x13d41799  mov r8,r15
0x13d4179c  mov r9,r11
0x13d4179f  call qword [rax+0x858] ; wrapper AGDC
```

**PROVEN:** il comando 3 valido arriva sempre allo slot `+0x858`.
**PROVEN:** non c'è un ramo alternativo verso `AGDCPlugin::doPluginAttribute` nel percorso del selettore 3.

### 6.4 Wrapper

`AppleGraphicsDeviceControl::vendor_doDeviceAttribute(...)` a `0x13d41c34`:

```asm
0x13d41c34  push rbp
0x13d41c35  mov rbp,rsp
0x13d41c38  sub rsp,0x10
0x13d41c3c  mov rax,[rbp+0x10]     ; client state
0x13d41c40  test rax,rax
0x13d41c43  jz 0x13d41c4b
0x13d41c45  mov rax,[rax+0x38]
0x13d41c49  jmp 0x13d41c4d
0x13d41c4b  xor eax,eax
0x13d41c4d  mov r10,[rdi]           ; vptr
0x13d41c50  mov [rsp],rax
0x13d41c54  call qword [r10+0x850]  ; vendor
0x13d41c5b  add rsp,0x10
0x13d41c5f  pop rbp
0x13d41c60  ret
```

**PROVEN:** il wrapper non esamina il selettore 3 e non ha un ramo verso `doPluginAttribute`.
**PROVEN:** dopo aver preparato lo stato, chiama in modo incondizionato `[vptr+0x850]`.
**PROVEN:** non c'è alcun controllo di autorizzazione nel wrapper; l'autorizzazione è già stata fatta da `authorizeTask` in `newUserClient`.

### 6.5 Conseguenza per il comando 3

Se il receiver è un'istanza Wrangler:

```text
filtered selector 3
  -> [vptr+0x858] = 0x13d41c34 wrapper
  -> [vptr+0x850] = 0xbf9894e Wrangler::vendor_doDeviceAttribute
```

**PROVEN:** il percorso è necessario e non dipende da `[+0xa0]`, da `doPluginAttribute`, né da uno stato non inizializzato per la scelta del vendor.
**PROVEN:** uno stato `[+0xb5]=0` o `[+0xb6]=0` non devia il dispatch; al massimo salta `publishHdaGfxProperties`.
**UNPROVEN:** il valore effettivo di `[+0xb5]`/`[+0xb6]` a runtime, perché `Wrangler::start` non chiama `AGDC::start` e non è possibile osservare l'istanza senza trace.

Se il receiver fosse un'istanza base AGDC:

```text
[vptr+0x850] = 0xab77f0
```

`0xab77f0` non è codice eseguibile, quindi un'istanza base non può essere il receiver valido del comando 3.

---

## 7. Wrapper contro doPluginAttribute

### 7.1 Percorso generico

La chiamata `[vptr+0x858]` compare in più punti di `filtered`:

```text
0x13d40ba5  selector 0x980
0x13d40d09  selector 0x20
0x13d4179f  dispatch generico (include il 3)
0x13d418a2  retry 0x986
0x13d4191e  0x2001
```

**PROVEN:** il percorso del selettore 3 è quello generico a `0x13d4179f`.

### 7.2 Percorso diretto a doPluginAttribute (range 0x4100–0x4125)

`AGDCPlugin::doPluginAttribute(...)` è a `0x13d4240e`:

```asm
0x13d4240e  test rsi,rsi
0x13d42411  jz 0x13d42420
0x13d42413  mov rax,[rdi]
0x13d42416  mov rax,[rax+0x890]
0x13d4241d  jmp rax
0x13d42420  mov eax,0xe00002c0
0x13d42425  ret
```

**PROVEN:** `doPluginAttribute` fa tail-call sullo slot `+0x890` dell'oggetto plugin; non chiama direttamente il Wrangler.
**PROVEN:** lo slot `+0x890` del Wrangler è `0x13d420fa` (RESERVED6), non `0xbf9894e`.
**PROVEN:** lo slot `+0x890` di `AGDCPlugin` è `0x13d424b6` (RESERVED6), non `0xbf9894e`.

Il solo chiamante diretto di `0x13d4240e` dentro `filtered` è:

```asm
0x13d4160e  mov rdi,rbx
0x13d41611  mov rsi,rdx
0x13d41614  mov edx,r13d
0x13d41617  mov r9,r15
0x13d4161a  call 0x13d4240e
```

Questo blocco è raggiunto dal percorso che parte da `0x13d4091e`. L'ingresso a `0x13d4091e` è controllato da:

```asm
0x13d40845  cmp r13d,0x411c
0x13d4084c  setz al
0x13d4084f  cmp esi,0x1
0x13d40852  setnz cl
0x13d40855  test cl,al
0x13d40857  jz 0x13d4091e
0x13d4085d  mov r12d,0xe00002c2
0x13d40863  jmp 0x13d418ca
```

Interpretazione corretta: `al=1` solo per il selettore `0x411c`; `cl=1` se l'API non è 1; il salto a `0x13d4091e` avviene quando **non** si verifica la combinazione vietata (`0x411c` con API diversa da 1). Quindi il percorso plugin copre il range **0x4100–0x4125**, non il solo `0x411c`; la combinazione `0x411c` + API != 1 viene respinta con `0xe00002c2`.

**PROVEN:** il percorso diretto a `doPluginAttribute` appartiene al range di selettori plugin **0x4100–0x4125**, con la sola eccezione negativa `0x411c` + API != 1.
**PROVEN:** il selettore 3 non entra in questo range.
**PROVEN:** il comando 3 non può raggiungere `doPluginAttribute` tramite il ramo diretto di `filtered`.

### 7.3 doPlugin_Command

`doPlugin_Command` a `0x13d3fed2` chiama `doPluginAttribute` tre volte:

```text
0x13d4002a  selector 0x1200
0x13d4007e  selector 0x1000
0x13d4010e  selector 0x83
```

**PROVEN:** questi percorsi riguardano comandi plugin, non il selettore esterno 3.
**PROVEN:** `AGDCPlugin::doPluginAttribute` non è il vendor Wrangler e non è il percorso del comando 3.

---

## 8. Identità dell'oggetto: sintesi

### 8.1 Catena statica

```text
provider IOService (AGDC/Wrangler)
  -> client_start:
       [client+0xd8] = 0x1007e(provider, AGDC::metaClass)
  -> externalMethod:
       rdi = [client+0xd8]
       call UserKernelTransfer
  -> UserKernelTransfer:
       [rbp-0x58] = rdi
       call filtered(rdi=[rbp-0x58], api=3, selector=esterno)
  -> filtered:
       [rbp-0x38] = rdi
       selector 3 -> [vptr+0x858]
  -> wrapper 0x13d41c34:
       call [vptr+0x850]
```

**PROVEN:** non ci sono conversioni, copie o sostituzioni dell'oggetto lungo questa catena.
**PROVEN:** il receiver di `filtered` è il servizio ottenuto dal provider in `client_start`.

### 8.2 Tipo effettivo

| Affermazione | Stato |
|---|---|
| Il Wrangler deriva da `AppleGraphicsDeviceControl` | **PROVEN** |
| Il costruttore Wrangler chiama il costruttore AGDC e imposta il vptr Wrangler | **PROVEN** |
| `AppleGraphicsDeviceControl::MetaClass::alloc` restituisce `NULL` | **PROVEN** |
| Il Wrangler è una classe concreta allocabile (0x148 byte) | **PROVEN** |
| Il Wrangler è l'unica sottoclasse concreta osservata di AGDC nel target | **INFERRED** |
| Il provider vivo è un Wrangler e non un'istanza base | **INFERRED** |
| L'helper `0x1007e` restituisce esattamente il provider Wrangler | **UNPROVEN** |
| L'oggetto osservato a runtime ha vptr `0xc1f07c0` | **UNPROVEN** (nessun trace) |

La classe base non è istanziabile; l'unica sottoclasse concreta documentata è il Wrangler. Questo rende **altamente probabile** che il provider sia Wrangler, ma non è una prova runtime.

### 8.3 Stato non inizializzato

- `[+0xb5]` è impostato in `AGDC::start` a `0x13d40626` con `setnz` sul risultato di una chiamata su `IOPCITunnelled`.
- `[+0xb6]` è un flag one-shot, impostato a 1 prima di `publishHdaGfxProperties`.
- `Wrangler::start` non chiama `AGDC::start`; quindi `[+0xb5]` e `[+0xb6]` possono essere zero.
- Anche con entrambi a zero, il percorso del selettore 3 passa per `0x13d41789` e chiama il wrapper.
- **PROVEN:** lo stato non cambia il vendor chiamato; cambia solo se viene eseguito `publishHdaGfxProperties`.
- **UNPROVEN:** il valore iniziale effettivo dei due byte e l'eventuale effetto collaterale HDA a runtime.

---

## 9. Primo ostacolo ancora irrisolto

### 9.1 Ostacolo statico locale

**L'identità runtime del provider non è dimostrabile senza osservazione.**
La gerarchia e l'allocatore astratto rendono il Wrangler l'unica implementazione concreta plausibile, ma:

- l'helper `0x1007e` è un import senza nome nel kc;
- non è possibile leggere il vptr dell'oggetto vivo;
- non è possibile verificare che il provider restituito sia lo stesso Wrangler e non un wrapper di servizio.

Questo è il primo punto **staticamente** non chiuso del report 176.

### 9.2 Ostacolo operativo

**Manca un attore autorizzato che invii il selettore 3.**
WindowServer è autorizzato (`com.apple.private.gpuwrangler`) ma non invia il 3; nessun altro client osservato lo invia; un harness isolato non può ottenere l'entitlement e `agdc_entitle` non è impostato.

Anche risolvendo l'identità dell'oggetto, senza un client autorizzato che effettui la chiamata il percorso non è attivabile.

**Primo ostacolo complessivo:** l'assenza di un attore autorizzato che invii il comando 3; il residuo statico è l'identità runtime del provider.

---

## 10. Verdetto

| Elemento | Esito |
|---|---|
| Wrangler sottoclasse di AGDC | **PROVEN** |
| Costruttore Wrangler -> costruttore AGDC -> vptr Wrangler | **PROVEN** |
| AGDC base astratta (`alloc` = NULL) | **PROVEN** |
| Wrangler vtable `+0x850` = `0xbf9894e` | **PROVEN** |
| Wrangler vtable `+0x858` = `0x13d41c34` | **PROVEN** |
| AGDC base vtable `+0x850` = `0xab77f0` non eseguibile | **PROVEN** |
| `filtered` selector 3 -> `[+0x858]` | **PROVEN** |
| wrapper -> `[+0x850]` incondizionato | **PROVEN** |
| comando 3 -> `doPluginAttribute` | **NO, PROVEN** |
| percorso 0x4100–0x4125 -> `doPluginAttribute` | **PROVEN** |
| provider vivo = Wrangler | **INFERRED** |
| vptr runtime = `0xc1f07c0` | **UNPROVEN** |
| stato `[+0xb5]`/`[+0xb6]` a runtime | **UNPROVEN** |
| client autorizzato che invia il 3 | **NO, PROVEN** |
| T27 | **OPEN — 94% engineering / 32% first boot / 8% desktop** |

**Risposta netta:** il percorso del comando 3, se il receiver è il Wrangler, raggiunge **necessariamente** il vendor Wrangler `0xbf9894e`: `filtered` non ha un ramo alternativo per il 3, il wrapper non ha condizioni e `doPluginAttribute` appartiene al percorso plugin 0x4100–0x4125. Non dipende da uno stato non inizializzato per la scelta del vendor; lo stato influisce solo su `publishHdaGfxProperties`. L'identità runtime del provider resta **INFERRED/UNPROVEN**; il primo ostacolo operativo resta l'assenza di un attore autorizzato che invii il selettore 3.

**Spazio:** **14.127.984 KiB ≈ 13,47 GiB** liberi. Nessuna cancellazione; nessun file eliminabile proposto.
**STOP rispettato:** sola lettura; nessun boot/trace/modifica/build/download.
