# T27 — AGENT-05 — T2 / HID / INPUT

**Scope:** BCE, VHCI, USB, tastiera, trackpad, `AppleUSBTopCaseDriver`, `AppleTopCaseHIDEventDriver`, audio e componenti x86_64.  
**Mode:** read-only. **Nessun boot, nessun `kextload`, nessun test hardware.**  
**Stato:** **BLOCKED per input interno; percorso USB TopCase plausibile ma non 26B131.**

---

## 1. Componenti

| Componente | Target 26B131 | KDK 26B131 | root2 25G325 | Stato |
|---|---|---|---|---|
| `AppleUSBVHCI` | ASSENTE/PARZIALE | parziale x86 | x86 25G325 | **PARZIALE / BUILD ERRATO** |
| `AppleUSBVHCIBCE` | **ASSENTE** | **ASSENTE** | x86 25G325 | **ASSENTE 26B131** |
| `IOUSBHostFamily` | metadati, 0 primari | x86 26B116 | x86 25G325 | **PARZIALE** |
| `AppleUSBTopCaseDriver` | metadati, 0 primari | x86 26B116 | x86 25G325 | **PARZIALE / BUILD ERRATO** |
| `AppleTopCaseHIDEventDriver` | metadati/assente | non verificato | x86 25G325 | **PARZIALE** |
| `AppleHIDKeyboard` | metadati | x86 26B116 | x86 25G325 | **PARZIALE** |
| `AppleMultitouchDriver` | metadati | x86 26B116 | x86 25G325 | **PARZIALE** |
| `AppleHIDTransport` | metadati | **arm64/arm64e** | **arm64e** | **ARCHITETTURA ERRATA** |
| `IOHIDFamily` | metadati | x86 26B116 | x86 25G325 | **PARZIALE** |
| `BridgeAudioCommunication` | ASSENTE | ASSENTE | x86 25G325 | **ASSENTE / BUILD ERRATO** |
| `AppleBridgeAudioController` | ASSENTE | ASSENTE | x86 25G325 | **ASSENTE / BUILD ERRATO** |
| `AppleAVEBridge` | ASSENTE | ASSENTE | x86 25G325 | **ASSENTE / BUILD ERRATO** |

Fonti: T25 T2/HID; T26 `T26-SYSTEMKC-DEPENDENCIES.csv`; root2 inventory T25.

**Discrepanza registrata:** T25 descrive `AppleHIDTransport` come `arm64e-only`; T26 lo classifica `arm64/arm64e`. La differenza riguarda le slice osservate, non la conclusione: **non esiste una slice x86_64 utilizzabile**. L’integratore adotta `ARCHITETTURA ERRATA` in entrambi i casi.

---

## 2. Percorso interno corretto

```text
T2 / iBridge
  -> BCE / VHCI
  -> IOUSBHostFamily
  -> IOUSBHostHIDDevice
  -> AppleUSBTopCaseDriver
  -> AppleTopCaseHIDEventDriver
  -> AppleHIDKeyboard / AppleMultitouchDriver
```

Questo è il percorso **x86 plausibile**, non `AppleHIDTransport` (che è ARM-only). Nel donor root2 i componenti sono universal x86_64+arm64e, ma sono build 25G325. Nel target 26B131 mancano i primari e `AppleUSBVHCIBCE` è assente.

---

## 3. Input interno vs USB esterno

| Funzione | Percorso | Stato |
|---|---|---|
| Tastiera interna | T2 → VHCI/BCE → TopCase → HIDKeyboard | **UNPROVEN** |
| Trackpad interno | T2 → VHCI/BCE → TopCase → Multitouch | **UNPROVEN** |
| Touch Bar | TopCase plugins | **UNPROVEN** |
| Tastiera USB esterna | XHCI/IOUSBHostFamily | **PARTIAL**, non prova input interno |
| Trackpad USB esterno | XHCI/IOUSBHostFamily | **PARTIAL**, non prova input interno |
| Audio interno | BridgeAudio/AVE | **UNPROVEN** |
| Camera/AVE | AppleAVEBridge | **UNPROVEN** |

Un mouse/tastiera USB esterni non dimostrano il funzionamento del T2 interno.

---

## 4. T2 Linux

Il fork Linux `klizas/apple-bce-drv` dichiara test su MacBookPro16,1 per BCE/VHCI/input. È una prova hardware **Linux**, non macOS:

- non prova il caricamento dei kext Apple 26B131;
- non prova il match `AppleUSBTopCaseDriver`;
- non prova Touch Bar, audio, camera o sleep su macOS;
- i moduli Linux non sono riutilizzabili come kext.

Il valore è la conferma che il T2 espone un percorso USB virtuale; non è una certificazione macOS.

---

## 5. Conclusione

**Tastiera e trackpad interni: BLOCKED.** Mancano VHCI/BCE 26B131, i primari TopCase/HID e una prova di enumerazione USB del T2. `AppleHIDTransport` non è utilizzabile su Intel.

**Handoff:** l’integratore deve classificare l’input interno **BLOCKED**, l’input USB esterno **PARTIAL**, e non usare T2 Linux come prova macOS.
