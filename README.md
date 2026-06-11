# PowerSell Scripts Centirio

Suite de scripts PowerShell pour la gestion documentaire et la création de dossiers clients structurés destinée aux centres d'affaires au Maroc.

## Scripts

| Script | Description |
|--------|-------------|
| `New-Business-Centre-Folder.ps1` | Déploiement de l'arborescence documentaire complète (WinForms) avec TreeView, rapport HTML et ajout de clients. |
| `Generateur_Dossiers_Clients_2026.ps1` | Générateur de dossiers clients (WPF) avec chargement Excel (COM), copie de templates, gestion de conflits et guide HTML. |
| `CENTIRIO-Creation-Dossier-Domicilié.ps1` | Création individuelle de dossier client (WPF) avec interface sombre. |
| `Create-Dossier-DJ-DM.ps1` | Création rapide d'un dossier DJ (Consultation/Modification) au format `YYYY-MM-DD_DJ_{Cons\|Modif}_{SOCIÉTÉ}` avec interface WPF sombre, sélection du dossier de destination et ouverture automatique. |

## Prérequis

- PowerShell 7+
- Windows (WPF/WinForms)
- Excel (optionnel, pour le chargement des sociétés via COM)

## Utilisation rapide

```powershell
.\Generateur_Dossiers_Clients_2026.ps1
```

```powershell
.\New-Business-Centre-Folder.ps1
```

```powershell
.\New-Business-Centre-Folder.ps1 -NoGui -ParentPath "C:\Clients"
```

```powershell
.\Create-Dossier-DJ-DM.ps1
```

## Structure

- `Templates\` — Dossier contenant les fichiers modèles à copier dans chaque dossier client
- `Clients\` — Destination par défaut des dossiers générés
- `Logs\` — Journaux d'opérations (CSV horodaté)

## Liens

- Dépôt : https://github.com/DevopsAbdel/PowerSell_Scripts_Centirio.git
- Spécifications détaillées : `SPECS_CENTIRIO_APP.md`
