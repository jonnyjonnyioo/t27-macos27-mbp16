# T27 — AGENT-07 — DESKTOP / USERSPACE

**Scope:** WindowServer, loginwindow, Finder, Dock, Metal, IOSurface, IOGraphics, audio, rete, Wi-Fi, Bluetooth, sleep/wake, applicazioni.  
**Mode:** read-only. **Nessun boot, nessun WindowServer, nessun test desktop.**  
**Stato:** **BLOCKED; il desktop è non dimostrato sul MacBookPro16,1.**

---

## 1. Riferimento HAO

HAO documenta un desktop funzionante su **MacBookPro9,2 / HD 4000**. È un riferimento per la catena macOS 27.2.1 26B131, ma non è una prova per MacBookPro16,1:

| Elemento | MBP9,2 | MBP16,1 |
|---|---|---|
| CPU | Ivy Bridge | Coffee Lake |
| GPU | HD 4000 | UHD630 + Navi14 |
| Display | Intel | eDP + gMux |
| T2 | no | sì |
| Input | PS/2/USB | T2/VHCI |
| Desktop | **VERIFIED** | **BLOCKED** |

La differenza GPU/display/input è sostanziale.

---

## 2. Matrice desktop

| Funzione | Target 26B131 | Evidenza | Stato |
|---|---|---|---|
| kernel | presente | hash `3c931751…` | **PRESENTE** |
| launchd | binario presente | nessun boot | **BLOCKED** |
| loginwindow | metadata/userspace incompleto | nessun test | **BLOCKED** |
| WindowServer | non verificato | nessun display/Metal | **BLOCKED** |
| Finder | non verificato | dipende da WindowServer | **BLOCKED** |
| Dock | non verificato | dipende da WindowServer/Metal | **BLOCKED** |
| Metal | non verificato | MTL 25G-series recuperato, bundle incompleto/non 26B131 | **BLOCKED** |
| IOSurface | metadati | no runtime | **PARZIALE** |
| IOGraphicsFamily | metadati/26B116 | no runtime | **PARZIALE** |
| display interno eDP/gMux | non verificato | nessun test | **BLOCKED** |
| tastiera interna | non verificata | VHCI/BCE assenti | **BLOCKED** |
| trackpad interno | non verificato | VHCI/BCE assenti | **BLOCKED** |
| audio | driver donor 25G325 | no test | **UNPROVEN** |
| Wi-Fi | metadati/25G325 | no test | **UNPROVEN** |
| Bluetooth | non verificato | no test | **UNKNOWN/UNPROVEN** |
| sleep/wake | non verificato | no test | **UNPROVEN** |
| applicazioni | non verificate | dipendono dal desktop | **BLOCKED** |

---

## 3. Dipendenze del desktop

```text
kernel + launchd
  -> IOGraphics / IOSurface / IOAcceleratorFamily2
  -> Metal userspace + AMD X6000
  -> WindowServer
  -> loginwindow
  -> Finder / Dock
  -> applicazioni
```

Mancano:

- una coppia KC 26B131;
- AMD X6000 26B131; il binario MTL 25G-series recuperato non è un bundle 26B131;
- Metal/IOSurface/IOGraphics runtime verificati;
- display eDP/gMux;
- input T2;
- framework/userspace completi;
- audio/rete/BT/sleep verificati.

Il target 26B131 ha 340 framework e 2.496 PrivateFrameworks come catalogo, ma i sample non hanno binari correnti; non è un userspace completo.

---

## 4. Conclusione

**WindowServer, loginwindow, Finder, Dock e desktop: BLOCKED.** Non esiste una prova MacBookPro16,1. Un desktop su MBP9,2 o su display esterno non è una prova del pannello interno e dell’input T2.

**Handoff:** l’integratore deve rifiutare qualsiasi dichiarazione di desktop finché non sono verdi i gate display, input, Metal e WindowServer.
