# T27 — INSTALLATION ROADMAP

**Target:** macOS 27.2.1 26B131, MacBookPro16,1, x86_64, T2, Radeon Pro 5300M.  
**Stato:** **PROCEDURA NON ESEGUITA.** Nessuna KC, nessun boot, nessuna installazione, nessuna modifica EFI/NVRAM/T2.  
**Regola:** ogni fase ha un gate; se un gate fallisce, si torna indietro. Non si passa alla fase successiva “sperando che funzioni”.

---

## 1. Acquisizione dei componenti mancanti

### Prerequisiti

- Inventario T26/T27 congelato.
- Set target 26B131 x86_64: kernel, `System.kext`/KPI, ACPI/APIC, PCI/ACPI, storage/APFS, USB/T2, AMD, audio/rete.
- `boot.efi`, Recovery/BaseSystem 26B131.
- Eventuale installer 25G342 completo, se si vuole il donor.
- Fonte tracciata: URL, data, hash, build, architettura, firma.

### Test

- `shasum -a 256`, `stat`, `file`, `lipo -info`.
- `plutil` su `Info.plist`; `codesign -dvvv` e `codesign --verify --strict`.
- Confronto con lista attesa; 0 missing, 0 mismatch.
- Nessun download >2 GiB; totale ≤2 GiB; nessun IPSW/installer completo.

### Rollback

- Quarantena dei file non conformi; nessuna cancellazione dei materiali originali.
- Ripristino dell’inventario precedente.

### Rischi

- Build sbagliata (25G325/25G342/26B116).
- Architettura ARM-only.
- Firma Apple presente ma sigillo non verificabile.
- Installer 25G342 assente: la strategia donor non è ricostruibile.

**Gate 1:** set 26B131 completo, tracciato e verificato. **Oggi: FAIL** (installer e set 26B131 mancanti).

---

## 2. Preparazione del volume di destinazione

### Prerequisiti

- Volume/SSD esterno dedicato, non STELA-512.
- Spazio: 80 GiB working set + output; 160 GiB workspace.
- Backup/rollback esterni.
- Nessuna immagine disco da 80/160 GiB.

### Test

- `diskutil info`, `diskutil list`, `df -k`.
- APFS verificato;capacità sufficiente; volume non condiviso con dati irreversibili.
- Record di UUID, partizioni, punto di mount.

### Rollback

- Smontaggio del volume; nessuna scrittura sul disco interno.
- Ripristino da backup se il volume viene alterato.

### Rischi

- Spazio insufficiente: oggi ~11,95 GiB liberi, requisito 80/160 GiB.
- Cancellazione accidentale: vietato qualsiasi `erase` senza autorizzazione esplicita.
- Volume sbagliato: identificazione con UUID, non con il nome.

**Gate 2:** volume dedicato, spazio sufficiente, backup verificato. **Oggi: FAIL** (spazio).

---

## 3. Creazione BootKC/SystemKC

### Prerequisiti

- Ambiente macOS 26B131 isolato (VM/volume dedicato).
- KDK 26B131 installato/registrato **nell’ambiente**.
- Repository kext 26B131 completo.
- BootKC base per SystemKC.
- `kmutil` dell’ambiente 26B131, non l’host 25G342.

### Test

1. `kmutil create -n boot` con `--build 26B131`, `--arch x86_64`, kernel/repository/KDK.
2. `kmutil inspect --show-collection-metadata --show-kernel-uuid`.
3. `kmutil inspect --show-kext-uuids --show-fileset-entries`.
4. Verifica: build 26B131, kernel UUID `037E7B86-…`, >0 kext attesi, nessun ARM-only.
5. Solo dopo: `kmutil create -n sys` con la BootKC come base.
6. Verifica linked boot UUID.

### Rollback

- Output in directory separata, con hash.
- Conservare la BootKC precedente; non sovrascrivere.
- In caso di errore, scartare l’output e ricostruire da zero.

### Rischi

- `--allow-missing-kdk` produce KC kernel-only: **vietato**.
- `--manifest` è Apple Silicon only: **vietato**.
- Host 25G342: `kmutil` userebbe la build sbagliata.
- SystemKC costruita contro BootKC errata: linked UUID incoerente.

**Gate 3:** BootKC completa verificata; poi SystemKC prelinked. **Oggi: FAIL** (materiali).

---

## 4. Verifica firme e dipendenze

### Prerequisiti

- BootKC e SystemKC appena generate.
- Lista attesa dei bundle ID/KPI.
- Strumenti: `codesign`, `lipo`, `vtool`, `plutil`, `kmutil inspect`, `shasum`.

### Test

- `codesign --verify --strict` su ogni bundle.
- `lipo -info` su ogni primario: x86_64.
- `vtool -show-build`: build 26B131.
- `plutil -p`: `OSBundleLibraries` risolte.
- `kmutil inspect`: build/UUID/kext/linked boot.
- Confronto con manifest: 0 missing, 0 hash mismatch.

### Rollback

- Nessuna installazione: i file restano in staging.
- Se un bundle fallisce, la KC non è valida; ricostruire.

### Rischi

- Firma Apple ma sigillo invalido.
- Dipendenza KPI minima non soddisfatta.
- Bundle ARM-only mascherato da universale.
- Build 26B116/25G325/25G342 nel set.

**Gate 4:** tutte le firme e dipendenze verificate. **Oggi: FAIL** (nessuna KC 26B131).

---

## 5. Preparazione EFI isolata

### Prerequisiti

- `boot.efi` 26B131 verificato.
- OpenCore configurata per MacBookPro16,1, senza modificare la EFI reale.
- ESP separata o immagine EFI di test.
- SMBIOS nativo documentato; T2 Secure Boot/NVRAM analizzati.
- Piano di rollback e accesso fisico.

### Test

- Validazione config OpenCore; nessun driver ARM-only.
- `boot.efi` hash/build/arch.
- Test di sola lettura della catena; nessuna scrittura NVRAM/T2.
- Verifica che il volume di destinazione sia quello atteso.

### Rollback

- Rimuovere la EFI di test, non la EFI reale.
- Ripristinare la configurazione precedente da backup.
- Non alterare NVRAM/T2.

### Rischi

- Secure Boot/anti-rollback T2.
- SMBIOS sbagliato.
- EFI che scrive NVRAM o seleziona il volume errato.
- Bricking evitabile con supporto esterno.

**Gate 5:** EFI isolata valida, senza scritture reali. **Oggi: FAIL** (boot.efi 26B131 assente; OpenCore/T2 non verificati).

---

## 6. Primo boot controllato

### Prerequisiti

- Gate 3–5 verdi.
- BootKC/SystemKC 26B131 verificate.
- EFI isolata e rollback pronti.
- Log seriale/console, piano di cattura panic.

### Test

- Boot con `-v` e log; nessun `kextload`.
- Verifica kernel UUID/build; arresto al primo panic.
- Raccolta di: schermo, log, panic, stato APFS.
- Nessuna installazione o modifica persistente.

### Rollback

- Boot dal volume precedente.
- Ripristino EFI/volume di test.
- Nessuna scrittura NVRAM/T2.

### Rischi

- Panic ACPI/PCI/storage.
- UCLK/SMU hang su GPU.
- Perdita di dati se il volume è sbagliato.
- T2 Secure Boot blocca il boot.

**Gate 6:** kernel raggiunge il punto di handoff a launchd. **Oggi: FAIL** (nessuna KC/boot).

---

## 7. Verifica launchd

### Prerequisiti

- Gate 6 verde.
- Root APFS montata.
- `launchd`/`dyld` 26B131 coerenti.
- Log accessibili.

### Test

- `launchd` PID 1.
- Nessun panic; APFS stabile.
- Servizi minimi avviati; nessun loop di crash.
- Verifica userspace di base.

### Rollback

- Boot precedente; snapshot/backup.
- Nessuna modifica permanente al volume.

### Rischi

- `launchd` non parte per KPI/kext mancanti.
- APFS montato in sola lettura.
- Servizi che dipendono da T2/AMD non disponibili.

**Gate 7:** launchd stabile. **Oggi: BLOCKED** (Gate 6 non superato).

---

## 8. Verifica display e input

### Prerequisiti

- Gate 7 verde.
- AMD X6000 26B131, IOGraphics/IOSurface/IOAccelerator.
- VHCI/BCE, TopCase, HIDKeyboard/Multitouch 26B131.
- Test separato per display interno e input interno.

### Test

- Display interno eDP: init, backlight, gMux.
- Input interno: tastiera, trackpad, Touch Bar.
- Un display/USB esterno non è accettato come prova dell’interno.
- Log di enumerazione USB T2 e match driver.

### Rollback

- Boot precedente; nessuna modifica EFI/NVRAM.
- Se il display interno non funziona, fermarsi: non dichiarare desktop.

### Rischi

- gMux/eDP/backlight.
- UCLK/SMU GPU.
- VHCI/BCE assente o TopCase non matchato.
- Input esterno che maschera il fallimento interno.

**Gate 8:** display interno e input interno funzionanti. **Oggi: BLOCKED** (AMD/VHCI/BCE/TopCase 26B131 mancanti).

---

## 9. Avvio WindowServer

### Prerequisiti

- Gate 8 verde.
- Metal/IOSurface/IOGraphics/IOAccelerator runtime.
- AMD X6000 26B131.
- `WindowServer` e loginwindow disponibili.

### Test

- `WindowServer` avviato senza crash.
- Metal device disponibile; superfici IOSurface.
- Loginwindow visibile sul display interno.
- Nessun fallback a display esterno.

### Rollback

- Boot precedente; nessuna modifica persistente.
- Se WindowServer crasha, raccogliere log e tornare al Gate 8.

### Rischi

- Metal 26B131 mancante; binario MTL 25G-series recuperato ma incompleto/incompatibile.
- AMD driver non caricato.
- IOSurface/IOGraphics incoerenti.
- WindowServer senza input.

**Gate 9:** WindowServer e loginwindow stabili. **Oggi: BLOCKED** (Gate 8).

---

## 10. Loginwindow e desktop

### Prerequisiti

- Gate 9 verde.
- Finder/Dock/loginwindow.
- Audio, rete/Wi-Fi, Bluetooth, sleep/wake.
- Applicazioni di accettazione.

### Test

- Login con tastiera/trackpad interni.
- Finder, Dock, menu bar.
- Audio interno, Wi-Fi/BT, sleep/wake.
- Applicazioni: apertura, rendering, chiusura.
- Nessun crash ripetuto; log puliti.

### Rollback

- Boot precedente; snapshot/backup.
- Se un requisito desktop fallisce, stato **PARTIAL**, non “desktop funzionante”.

### Rischi

- Metal instabile.
- Audio/AVE T2.
- Wi-Fi/BT non compatibili.
- Sleep/wake con GPU/T2.
- Applicazioni che richiedono ARM/AVX.

**Gate 10:** desktop operativo e ripetibile su MacBookPro16,1. **Oggi: BLOCKED** (Gate 3–9).

---

## 11. Criteri di stop globali

Fermarsi immediatamente se:

- una KC non corrisponde a 26B131;
- un kext è ARM-only;
- una firma/sigillo non è verificato;
- un test richiede `kextload` sull’host;
- un test richiede modifica EFI/NVRAM/T2/SIP/AMFI;
- il display interno non è disponibile;
- l’input interno non è disponibile;
- il volume di destinazione non è identificato con UUID;
- lo spazio è insufficiente;
- manca il rollback.

**Nessuna fase è stata eseguita in T27.**
