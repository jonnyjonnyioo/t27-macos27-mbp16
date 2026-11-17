# PROMPT OPERATIVO — T27 / INCARICO R-185

## RUOLO
Sei l'agente di coding read-only del progetto T27. Operi in sola analisi statica.
Non esegui nulla di distruttivo. Non esci dal perimetro. Non inventi risultati.

## OBIETTIVO
Eseguire R-185: audit di completezza dell'inventario locale di kernelcache/Boot.kc/SystemKC/.kc e binari qemu-system-*, per stabilire se il "non c'è" dei Report 182–183 (QEMU custom -M darwin assente; kernelcache x86_64 con AppleSimpleFB/AMDRadeonX6000/AppleGPUWrangler assente) è PROVEN su TUTTE le fonti locali, o se esistono omissioni. Output: R-185.md.

## STATO ATTUALE
T27 OPEN: 94% engineering / 32% first boot / 8% desktop. Report 157–184 in <PROJECT_ROOT>/AGENT-AMD. 181: filone statico AMD/AGDC chiuso. 182: solo QEMU stock 10.2.2, -M darwin non supportato. 183: solo kernelcache ARM64 (Mac18,5, Mac17,2_3_4) con AppleDCP/AppleDisplay; zero AppleGPUWrangler/AMDRadeonX6000/AppleSimpleFB; Boot.kc x86_64 senza stringhe display. 184: filone QEMU/Display chiuso. Loop Qwen: STOP definitivo. Spazio: 14 GiB liberi.

## VINCOLI T27 (INVIOLABILI)
- Solo read-only: NIENTE boot, trace, build, download, install, modifica di sistema, scritture fuori da AGENT-AMD.
- Scritture consentite SOLO in: <PROJECT_ROOT>/AGENT-AMD
- Mantenere ≥10 GiB liberi. Non cancellare nulla. Non modificare SIP/Gatekeeper/FileVault/EFI/NVRAM/T2/APFS/boot policy.
- Separare sempre PROVEN / INFERRED / UNPROVEN. Nessuna deduzione statica diventa prova runtime.

## PERIMETRO DI SCANSIONE (NON USCIRE)
Consentiti solo questi root, in lettura:
1. <HOME>
2. /Applications
3. /Library
4. /System<VOLUME>/Preboot
5. volumi attualmente montati (sola lettura, escludere <VOLUME>/*/private se non leggibile)
6. <PROJECT_ROOT>
Vietato: /System/Library oltre Preboot, /private, /var, rete, home di altri utenti, percorsi fuori dai root elencati.

## PASSI NUMERATI
1. Preflight: verifica spazio (df -h), verifica scrittura in AGENT-AMD, registra data/ora e hash dei Report 182–184 come riferimento.
2. Inventario file: per ogni root del perimetro, `find <root> -type f \( -iname 'kernelcache*' -o -iname 'Boot.kc*' -o -iname 'SystemKC*' -o -iname '*.kc' -o -iname 'qemu-system-*' -o -iname 'qemu-*' \) 2>/dev/null` — registra percorso e dimensione.
3. Per ogni hit: `file <path>` (architettura), `shasum -a 256 <path>`, `strings -a <path> | grep -E 'AppleSimpleFB|AMDRadeonX6000|AppleGPUWrangler|AGDC|DCP'` (solo conteggio e prime occorrenze; nessuna estrazione).
4. Flagga: arch (x86_64/arm64/universal), presenza/assenza di ciascuna delle 5 stringhe, SHA-256, dimensione, percorso.
5. Confronta l'inventario con Report 182 e 183: identifica OMISSIONI (artefatti non censiti) e CONFERME (assenza provata).
6. Scrivi R-185.md in AGENT-AMD con: tabella PROVEN/INFERRED/UNPROVEN (colonne: percorso, dimensione, architettura, SHA-256, AppleSimpleFB, AMDRadeonX6000, AppleGPUWrangler, AGDC, DCP), comandi eseguiti, output, limiti, criterio di stop.

## COMANDI CONSENTITI (read-only)
df, du, find, ls, file, shasum, sha256sum, strings (pipe grep), stat, mdls, plutil -p (solo lettura). Nessun altro.

## OUTPUT
File: <PROJECT_ROOT>/AGENT-AMD/R-185.md
Contenuto minimo: intestazione (data, perimetro, spazio iniziale/finale), tabella completa, sezione OMISSIONI, sezione CONFERME, sezione LIMITI, sezione STOP, SHA-256 di R-185.md stesso.

## CRITERIO DI STOP
- Se 0 hit x86_64 utili (nessun kernelcache x86_64 con AppleSimpleFB/AMDRadeonX6000/AppleGPUWrangler/AGDC/DCP e nessun qemu-system-* con supporto -M darwin): dichiarare FORMALMENTE CHIUSO il blocco kernelcache/QEMU e proporre ridefinizione obiettivo T27 (opzioni: fork QEMU -M darwin con build controllata; kernelcache x86_64 da fonte Apple Developer legittima; ripristino Time Machine; ridefinizione su host ARM64 o pista Linux/T2). Nessuna di queste è read-only: richiedono autorizzazione separata.
- Se emerge almeno 1 hit x86_64 utile o un qemu-system-* custom: NON procedere oltre; documentare in R-185.md e fermarsi in attesa di autorizzazione esplicita.
- In ogni caso: fermarsi dopo R-185.md. Nessuna azione successiva.

## COSA NON FARE
Non eseguire boot, trace, build, download, install, copia, cancellazione, modifica di file fuori da R-185.md. Non uscire dal perimetro. Non eseguire binari trovati. Non fare injection. Non dichiarare desktop raggiunto. Non trasformare INFERRED in PROVEN.

## SE SERVE UN'AUTORIZZAZIONE
Se un passo richiede qualcosa fuori dal perimetro o non read-only: fermati, scrivi in R-185.md la sezione "AUTORIZZAZIONE RICHIESTA" con (a) azione proposta, (b) motivazione, (c) rischio, (d) preflight spazio/reversibilità, (e) criterio di stop. Attendi. Non procedere.
