# T27 — AGENT-06 — EFI / BOOT

**Scope:** OpenCore, `boot.efi`, SMBIOS nativo, T2 Secure Boot, NVRAM, catena di boot.  
**Mode:** read-only. **Nessuna modifica alla EFI reale, NVRAM, T2, SIP, AMFI o Secure Boot; nessun boot.**  
**Stato:** **BLOCKED prima della EFI.**

---

## 1. Asset di boot

| Asset | Target 26B131 | Root 25G342 | Stato |
|---|---|---|---|
| `boot.efi` | **ASSENTE** | 723.512 B; `016ccd2d…` | **ASSENTE 26B131** |
| BootKC | **ASSENTE** | 67.600.384 B; `9bb053cf…` | **ASSENTE 26B131** |
| SystemKC | **ASSENTE** | 369.213.440 B; `b4b618bf…` | **ASSENTE 26B131** |
| Recovery/BaseSystem | **ASSENTE** | presente, build 25G342 | **BUILD ERRATO** |
| OpenCore | non verificato per MBP16,1 | non applicabile | **UNPROVEN** |
| SMBIOS nativo | non verificato | non applicabile | **UNPROVEN** |
| T2 Secure Boot | non verificato | non applicabile | **UNPROVEN** |
| NVRAM | non verificata | non applicabile | **UNPROVEN** |

Fonti: T26 inventory e donor mapping; root 25G342; T25 desktop. I file 25G342 non sono 26B131.

---

## 2. Catena

```text
firmware T2 / Secure Boot
  -> EFI isolata / OpenCore
  -> boot.efi 26B131
  -> BootKC 26B131
  -> kernel 26B131
  -> SystemKC 26B131
  -> launchd
```

La catena è interrotta in più punti:

1. `boot.efi` 26B131 assente.
2. BootKC/SystemKC 26B131 assenti.
3. OpenCore non è stato configurato né testato su MacBookPro16,1/T2.
4. SMBIOS nativo e NVRAM non sono stati ispezionati.
5. T2 Secure Boot/anti-rollback non è stato analizzato in questa sessione.

---

## 3. OpenCore e specificità T2

OpenCore è uno strumento di bootloader, non un driver GPU/T2 e non una prova di compatibilità. Una EFI OpenCore ben formata può avviare un kernel, ma **non garantisce**:

- il match ACPI/PCI del MacBookPro16,1;
- il percorso T2/VHCI;
- il display eDP/gMux;
- Metal;
- la policy Secure Boot/anti-rollback.

La EFI reale non è stata modificata. Qualsiasi prova futura deve usare una EFI separata, con rollback e senza scrivere NVRAM/T2.

---

## 4. Conclusione

**Il boot non è eseguibile oggi.** Manca `boot.efi` 26B131 e manca la coppia KC. OpenCore/SMBIOS/T2 Secure Boot/NVRAM sono **UNPROVEN**, non “funzionanti”.

**Handoff:** l’integratore deve bloccare la fase EFI finché non esistono boot.efi + BootKC + SystemKC 26B131 verificati e un piano di rollback.
