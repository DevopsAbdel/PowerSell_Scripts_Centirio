#requires -Version 5.1
<#
.SYNOPSIS
CENTIRIO - Creation de la structure finale avec interface graphique interactive et rapport HTML en francais.

.DESCRIPTION
- Adapte a la structure finale fournie par l'utilisateur.
- Ouvre une vraie fenetre GUI/UX interactive (WinForms) avec boutons, zones de texte, cases a cocher et apercu de structure.
- Place la fenetre principale au premier plan (TopMost) pour la rendre visible au-dessus des autres fenetres Windows.
- Permet aussi un mode sans GUI via -NoGui.
- Genere un rapport HTML en francais, mode sombre, avec explication de chaque sous-dossier.
- Ecrit le HTML en UTF-8 BOM pour reduire fortement les problemes d'affichage du type gÃ©nÃ©rale / PÃ´les.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ParentPath,

    [Parameter(Mandatory = $false)]
    [string]$RootFolderName = 'NOM DU CENTRE',

    [Parameter(Mandatory = $false)]
    [switch]$NoGui,

    [Parameter(Mandatory = $false)]
    [switch]$AutoOpenReport,

    [Parameter(Mandatory = $false)]
    [switch]$SkipOpenPrompt
)

$ErrorActionPreference = 'Stop'

try { chcp 65001 > $null } catch {}
try {
    [Console]::InputEncoding  = [System.Text.UTF8Encoding]::new($true)
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($true)
    $OutputEncoding = [System.Text.UTF8Encoding]::new($true)
} catch {}

Add-Type -AssemblyName System.Windows.Forms | Out-Null
Add-Type -AssemblyName System.Drawing | Out-Null
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Win32TopMost {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@ | Out-Null

function Convert-TextToHtmlSafe {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $Text.ToCharArray()) {
        $code = [int][char]$ch
        switch ($ch) {
            '&' { [void]$sb.Append('&amp;') }
            '<' { [void]$sb.Append('&lt;') }
            '>' { [void]$sb.Append('&gt;') }
            '"' { [void]$sb.Append('&quot;') }
            default {
                if ($code -gt 127) {
                    [void]$sb.Append('&#' + $code + ';')
                }
                else {
                    [void]$sb.Append($ch)
                }
            }
        }
    }
    return $sb.ToString()
}

function Write-Utf8BomTextFile {
    param(
        [string]$Path,
        [string]$Content
    )
    $directory = Split-Path -Path $Path -Parent
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8Bom)
}

function New-CentirioFolder {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        return $true
    }
    return $false
}

function Select-FolderGui {
    param([System.Windows.Forms.IWin32Window]$Owner)
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Choisissez le dossier parent ou la structure $RootFolderName sera creee"
    $dialog.ShowNewFolderButton = $true
    $dialog.RootFolder = [System.Environment+SpecialFolder]::Desktop
    if ($dialog.ShowDialog($Owner) -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }
    return $null
}

# Structure finale adaptee au fichier fourni
$Structure = [ordered]@{
    '00_Pilotage_CENTIRIO' = [ordered]@{
        '01_Fiche_Signaletique'      = 'Fiche d''identite de CENTIRIO : informations societaires, identifiants, references et documents de base.'
        '02_Strategie_et_Organisation' = 'Organisation interne, choix de structure, notes de cadrage, plans d''action et rapport de reference.'
        '03_Reunions_et_PV'          = 'Comptes rendus, proces-verbaux, decisions, ordres du jour et suivi de reunions.'
        '04_Tableaux_de_Bord'        = 'KPI, fichiers de pilotage, suivis d''activite et tableaux de synthese direction.'
        '99_Archives'                = 'Versions anciennes ou documents de pilotage devenus inactifs.'
    }
    '01_Juridique_et_Conformite' = [ordered]@{
        '01_Documents_Societe_CENTIRIO' = 'Documents juridiques propres a la societe : statuts, RC, ICE, IF, patente et pieces de base.'
        '02_Formalites_Administratives' = 'Demandes, formulaires, recus et suivis de formalites administratives.'
        '03_Contrats_Internes'          = 'Contrats lies a la societe : bail, conventions, engagements et autres contrats internes.'
        '04_Veille_Legale_et_Reglementaire' = 'Lois, decrets, circulaires, guides et documentation reglementaire.'
        '05_Rapports_et_Certificats'    = 'Certificats, attestations officielles, rapports de conformite et pieces justificatives.'
        '99_Archives'                   = 'Documents juridiques anciens, remplaces ou clotures.'
    }
    '02_Domiciliation_Clients' = [ordered]@{
        '01_Actifs'                      = 'Dossiers des clients actuellement domicilies et suivis.'
        '02_En_Retard'                   = 'Clients en retard de paiement, de documents ou en situation de blocage.'
        '03_Resilies'                    = 'Dossiers de clients dont la domiciliation a ete arretee ou resiliee.'
        '04_Prospects_et_Dossiers_En_Cours' = 'Prospects, demandes non finalisees et dossiers en phase de constitution.'
        '05_Modeles_et_Checklists'       = 'Modeles et checklists operationnelles utiles a l''activite de domiciliation.'
        '06_Collaborateurs'              = 'Documents des partenaires, coursiers, experts et autres intervenants externes.'
        '07_Comptabilite_Domiciliation'  = 'Factures, commissions, recettes et suivi financier lies a la domiciliation.'
        '08_Autorisations_et_Conformite' = 'Autorisations, preuves de conformite et pieces reglementaires du metier.'
        '99_Archives'                    = 'Dossiers ou sous-dossiers de domiciliation devenus inactifs.'
    }
    '03_Comptabilite_et_Finance' = [ordered]@{
        '01_Depenses'                  = 'Justificatifs de charges, paiements, factures fournisseurs et sorties de tresorerie.'
        '02_Recettes'                  = 'Encaissements, documents de vente et pieces relatives aux recettes.'
        '03_Factures_Emises'           = 'Factures emises par CENTIRIO pour le suivi commercial et comptable.'
        '04_Banque'                    = 'RIB, releves, rapprochements, confirmations et autres documents bancaires.'
        '05_TVA_et_Declarations'       = 'Pieces preparatoires et justificatifs pour TVA et declarations.'
        '06_Tableaux_de_Suivi'         = 'Tableaux Excel et suivis financiers/comptables.'
        '99_Archives'                  = 'Elements comptables anciens ou periodes cloturees.'
    }
    '04_Organisme_et_Administration' = [ordered]@{
        '01_OMPIC'                     = 'Documents et formalites lies a l''OMPIC et aux procedures associees.'
        '02_DGI_et_Fiscalite'          = 'Relations DGI, documents fiscaux administratifs et correspondances associees.'
        '03_CNSS_et_Organismes'        = 'CNSS, DAMANCOM et autres organismes sociaux ou paraadministratifs.'
        '04_Operateurs_Telecom'        = 'Contrats, resiliations et correspondances avec operateurs telecom.'
        '05_Notifications_Officielles' = 'Avis, notifications et communications officielles recues.'
        '99_Archives'                  = 'Archives administratives hors exploitation courante.'
    }
    '05_Marketing_et_Commercial' = [ordered]@{
        '01_Plaquettes'                = 'Brochures, fiches de presentation et supports marketing de base.'
        '02_Offres_et_Tarifs'          = 'Offres commerciales, packs, tarifs et variantes d''offre.'
        '03_Campagnes'                 = 'Plans marketing, campagnes et actions de communication.'
        '04_Prospection_et_Partenariats' = 'Prospection, conventions de partenariat, listes cibles et documents de demarchage.'
        '05_Etudes_et_Benchmarks'      = 'Comparatifs, etudes de marche, analyses de concurrence et recherches.'
        '99_Archives'                  = 'Anciennes campagnes, offres ou documents marketing obsoletes.'
    }
    '06_Identite_Visuelle_et_Supports' = [ordered]@{
        '01_Logos'                     = 'Logos officiels, variantes, exports et fichiers source associes.'
        '02_Cachets'                   = 'Maquettes et exports des cachets administratifs et societes.'
        '03_Plaques'                   = 'Plaques, signaletique, maquettes, fontes, templates et exports.'
        '04_Charte_Graphique'          = 'Regles de marque, couleurs, typographies et standard visuel.'
        '05_Cartes_de_Visite'          = 'Modeles et versions finales des cartes de visite.'
        '06_Supports_Commerciaux (Packs)' = 'Supports commerciaux visuels et packs de presentation ou d''offre.'
        '99_Archives'                  = 'Versions anciennes ou projets graphiques abandonnes.'
    }
    '07_Modeles_et_Procedures' = [ordered]@{
        '01_Modeles_Contrats_Domiciliation' = 'Modeles officiels de contrats de domiciliation.'
        '02_Avenants'                    = 'Modeles d''avenants et modifications contractuelles.'
        '03_Attestations'                = 'Modeles d''attestations administratives et de domiciliation.'
        '03_Documents_Associes'          = 'Documents complements lies aux contrats ou au processus de domiciliation.'
        '04_Formulaires_Types'           = 'Formulaires standard, fiches et demandes recurrentes.'
        '05_Procedures_Internes'         = 'Instructions internes et modes operatoires.'
        '06_Fiche_Client_Standard'       = 'Modeles de fiche client et documents standards de saisie.'
        '07_Mise_En_Demeure'             = 'Modeles de mise en demeure et courriers de pression administrative.'
        '08_PV_Reunion'                  = 'Modeles de proces-verbaux et comptes rendus.'
        '09_Relances'                    = 'Modeles de relances clients et suivis de rappel.'
        '10_Resiliation'                 = 'Modeles de resiliation et documents de cloture.'
        '11_Checklists'                  = 'Listes de controle pour onboarding, suivi et cloture.'
        '99_Archives'                    = 'Anciens modeles, anciennes procedures et versions obsoletes.'
    }
    '08_Outils_et_Automatisation' = [ordered]@{
        '01_Odoo'                       = 'Exports, parametrages, documentations et travaux lies a Odoo.'
        '02_Scripts'                    = 'Scripts PowerShell et autres automatismes.'
        '03_Exports'                    = 'Exports de donnees, fichiers intermediaires et rapports techniques.'
        '04_Documentation'              = 'Documentation technique et guides d''utilisation.'
        '99_Archives'                   = 'Anciennes versions d''outils, scripts ou documentations.'
    }
    '90_Archives_Generales' = [ordered]@{
        '2025'                          = 'Archives generales relatives a l''annee 2025.'
        '2026'                          = 'Archives generales relatives a l''annee 2026.'
        'Anciens_Dossiers_Non_Classes'  = 'Zone temporaire pour les anciens elements a reclasser proprement.'
    }
    '99_Inventaires_et_Exports' = [ordered]@{
        '2026-02-20_Listes des dossiers et fichiers_02_CENTIRIO' = 'Inventaires et exports du 20/02/2026.'
        '2026-02-22_Listes des dossiers et fichiers_02_CENTIRIO' = 'Inventaires et exports du 22/02/2026.'
        '2026-03-21_Listes des dossiers et fichiers_02_CENTIRIO' = 'Inventaires et exports du 21/03/2026.'
        'Logs_et_Rapports' = 'Journaux, logs, rapports techniques et sorties de controle.'
    }
}

$ModeleClient = [ordered]@{
    '00_Fiche_Client' = 'Resume administratif et commercial du client.'
    '01_Contrat' = 'Contrat de domiciliation, avenants, renouvellements et pieces signees.'
    '02_KYC_et_Juridique' = 'CIN, RC, IF, ICE, statuts, CN et autres pieces juridiques/KYC.'
    '03_Paiements' = 'Factures, recus, echeanciers et preuves de paiement.'
    '04_Courrier' = 'E-mails, lettres, relances et correspondances officielles.'
    '05_Formalites_Administratives' = 'Demarches et documents lies aux formalites administratives du client.'
    '06_Incidents' = 'Retards, anomalies, litiges, blocages et actions correctives.'
    '07_Historique' = 'Anciennes versions et historique documentaire du dossier.'
    '99_Archives' = 'Pieces anciennes ou deplacees hors usage courant.'
}

$RoleDescriptions = [ordered]@{
    '00_Pilotage_CENTIRIO' = 'Gouvernance, organisation, pilotage et suivi global de CENTIRIO.'
    '01_Juridique_et_Conformite' = 'Base documentaire legale et reglementaire de la societe.'
    '02_Domiciliation_Clients' = 'Pôle coeur de metier pour le cycle de vie des dossiers clients de domiciliation.'
    '03_Comptabilite_et_Finance' = 'Flux financiers, justificatifs, facturation et outils de suivi comptable.'
    '04_Organisme_et_Administration' = 'Relations avec organismes, administrations et notifications officielles.'
    '05_Marketing_et_Commercial' = 'Offres, prospection, partenariats et materiel commercial.'
    '06_Identite_Visuelle_et_Supports' = 'Actifs graphiques, identite de marque et supports visuels.'
    '07_Modeles_et_Procedures' = 'Documents standards, modeles et procedures internes de reference.'
    '08_Outils_et_Automatisation' = 'Outils techniques, scripts et documentation d''automatisation.'
    '90_Archives_Generales' = 'Archives historiques hors usage courant.'
    '99_Inventaires_et_Exports' = 'Historique des inventaires, logs et fichiers d''export.'
}

function Resolve-Token {
    param([string]$Text, [string]$RootName)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $Text }
    return $Text.Replace('CENTIRIO', $RootName)
}

function Get-ResolvedStructure {
    param([string]$RootName)
    $resolved = [ordered]@{}
    foreach ($key in $Structure.Keys) {
        $newKey = Resolve-Token -Text $key -RootName $RootName
        $sub = [ordered]@{}
        foreach ($subKey in $Structure[$key].Keys) {
            $newSubKey = Resolve-Token -Text $subKey -RootName $RootName
            $sub[$newSubKey] = Resolve-Token -Text $Structure[$key][$subKey] -RootName $RootName
        }
        $resolved[$newKey] = $sub
    }
    return $resolved
}

function Get-ResolvedRoleDescriptions {
    param([string]$RootName)
    $resolved = [ordered]@{}
    foreach ($key in $RoleDescriptions.Keys) {
        $newKey = Resolve-Token -Text $key -RootName $RootName
        $resolved[$newKey] = Resolve-Token -Text $RoleDescriptions[$key] -RootName $RootName
    }
    return $resolved
}

$script:ResolvedStructure = Get-ResolvedStructure -RootName $RootFolderName
$script:ResolvedRoleDescriptions = Get-ResolvedRoleDescriptions -RootName $RootFolderName

function Update-ResolvedData {
    param([string]$RootName)
    $script:ResolvedStructure = Get-ResolvedStructure -RootName $RootName
    $script:ResolvedRoleDescriptions = Get-ResolvedRoleDescriptions -RootName $RootName
}

function Build-TreeView {
    param(
        [System.Windows.Forms.TreeView]$TreeView,
        [string]$RootName = $RootFolderName
    )
    $TreeView.Nodes.Clear()
    $rootNode = $TreeView.Nodes.Add($RootName)
    $st = Get-ResolvedStructure -RootName $RootName
    $mc = $ModeleClient
    foreach ($main in $st.Keys) {
        $mainNode = $rootNode.Nodes.Add($main)
        foreach ($sub in $st[$main].Keys) {
            [void]$mainNode.Nodes.Add($sub)
        }
        if ($main -match '^02_Domiciliation_Clients$') {
            $activeNode = $mainNode.Nodes | Where-Object { $_.Text -eq '01_Actifs' } | Select-Object -First 1
            if ($null -ne $activeNode) {
                $modelNode = $activeNode.Nodes.Add('_Modele_Client')
                foreach ($mcKey in $mc.Keys) {
                    [void]$modelNode.Nodes.Add($mcKey)
                }
            }
        }
    }
    $rootNode.Expand()
    foreach ($n in $rootNode.Nodes) { $n.Expand() }
}

function Generate-ReportHtml {
    param(
        [string]$RootPath,
        [string]$RootFolderName,
        [bool]$IncludeModelClient = $true,
        [string]$ReportPilotageKey = ''
    )

    $st = Get-ResolvedStructure -RootName $RootFolderName
    $roleDesc = Get-ResolvedRoleDescriptions -RootName $RootFolderName
    $domKey = $st.Keys | Where-Object { $_ -like '*Domiciliation*' } | Select-Object -First 1

    $cards = @(
        @{ Title = 'Organisation par pôles'; Text = 'La structure distingue clairement le pilotage, le juridique, les operations clients, la comptabilite, l''administration, le marketing, l''identite visuelle, les modeles, les outils et les archives.' },
        @{ Title = "Pôle central : domiciliation"; Text = "Le bloc $domKey regroupe le coeur du metier de domiciliation : clients actifs, retards, prospects, conformite et comptabilite liee au service." },
        @{ Title = 'Moins de confusion'; Text = 'Chaque sous-dossier a une mission precise afin d''eviter les doublons, les melanges entre archives, modeles et documents actifs, et les pertes de temps lors de la recherche.' },
        @{ Title = 'Scalabilite'; Text = 'La structure peut s''agrandir sans perdre en lisibilite : nouveaux clients, nouvelles annees, nouveaux packs, nouveaux scripts et nouveaux suivis.' }
    )

    $cardsHtml = @()
    foreach ($card in $cards) {
        $cardsHtml += @"
        <div class="card">
          <h3>$([string](Convert-TextToHtmlSafe $card.Title))</h3>
          <p>$([string](Convert-TextToHtmlSafe $card.Text))</p>
        </div>
"@
    }

    $sectionsHtml = @()
    foreach ($main in $st.Keys) {
        $rows = @()
        foreach ($sub in $st[$main].Keys) {
            $rows += @"
            <div class="row-item">
              <div class="folder-name"><code>$([string](Convert-TextToHtmlSafe $sub))</code></div>
              <div class="folder-desc">$([string](Convert-TextToHtmlSafe $st[$main][$sub]))</div>
            </div>
"@
        }

        $extraHtml = ''
        if ($IncludeModelClient -and $main -eq $domKey) {
            $modelRows = @()
            foreach ($mc in $ModeleClient.Keys) {
                $modelRows += @"
                <div class="row-item">
                  <div class="folder-name"><code>$([string](Convert-TextToHtmlSafe $mc))</code></div>
                  <div class="folder-desc">$([string](Convert-TextToHtmlSafe $ModeleClient[$mc]))</div>
                </div>
"@
            }
            $extraHtml = @"
            <div class="nested-box">
              <div class="nested-title">Modèle standard de dossier client (dans <code>01_Actifs\_Modele_Client</code>)</div>
              <div class="rows">
                $($modelRows -join "`n")
              </div>
            </div>
"@
        }

        $sectionsHtml += @"
        <section class="pole">
          <div class="pole-header">
            <h3>$([string](Convert-TextToHtmlSafe $main))</h3>
            <p>$([string](Convert-TextToHtmlSafe $roleDesc[$main]))</p>
          </div>
          <div class="pole-body">
            <div class="intro-line">$([string](Convert-TextToHtmlSafe ('Sous-dossiers principaux : ' + $st[$main].Count + ' element(s).')))</div>
            <div class="rows">
              $($rows -join "`n")
            </div>
            $extraHtml
          </div>
        </section>
"@
    }

    $generatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $rootPathHtml = Convert-TextToHtmlSafe -Text $RootPath

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$([string](Convert-TextToHtmlSafe $RootFolderName)) - Rapport de structure finale</title>
  <style>
    :root {
      --bg: #0b1220;
      --panel: #111827;
      --panel-2: #162132;
      --text: #e5e7eb;
      --muted: #aab4c3;
      --accent: #22c55e;
      --accent2: #38bdf8;
      --border: #293548;
      --code: #c4b5fd;
      --code-bg: #0f172a;
      --shadow: 0 12px 28px rgba(0,0,0,.35);
    }
    * { box-sizing: border-box; }
    body { margin:0; font-family: Segoe UI, Arial, sans-serif; background: linear-gradient(180deg, #08111e 0%, #0b1220 100%); color: var(--text); }
    .wrap { max-width: 1360px; margin: 0 auto; padding: 28px; }
    .hero { background: linear-gradient(135deg, rgba(34,197,94,.16), rgba(56,189,248,.10)); border: 1px solid rgba(56,189,248,.20); border-radius: 22px; padding: 28px; box-shadow: var(--shadow); }
    .hero h1 { margin: 0 0 10px; font-size: 34px; }
    .hero p { margin: 6px 0; line-height: 1.65; }
    .meta { color: var(--muted); font-size: 14px; }
    .path-box { margin-top: 12px; padding: 12px 14px; background: rgba(15,23,42,.78); border: 1px solid var(--border); border-radius: 14px; overflow-wrap: anywhere; }
    .legend { display:flex; flex-wrap:wrap; gap:10px; margin-top: 14px; }
    .chip { background: #1f2937; border: 1px solid var(--border); color: var(--text); border-radius: 999px; padding: 8px 12px; font-size: 13px; }
    h2 { margin: 28px 0 16px; font-size: 24px; }
    .grid { display:grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; }
    .card, .section-panel { background: var(--panel); border: 1px solid var(--border); border-radius: 18px; box-shadow: var(--shadow); }
    .card { padding: 18px; }
    .card h3 { margin: 0 0 8px; font-size: 18px; }
    .card p { margin: 0; color: var(--muted); line-height: 1.65; }
    .section-panel { padding: 22px; }
    .tip { border-left: 4px solid var(--accent); background: rgba(34,197,94,.08); padding: 14px 16px; border-radius: 12px; margin-bottom: 16px; line-height: 1.7; }
    .pole { background: var(--panel-2); border: 1px solid var(--border); border-radius: 18px; margin-bottom: 16px; overflow: hidden; }
    .pole-header { padding: 18px 20px; background: linear-gradient(90deg, rgba(34,197,94,.08), rgba(56,189,248,.06)); border-bottom: 1px solid var(--border); }
    .pole-header h3 { margin: 0 0 6px; font-size: 20px; }
    .pole-header p { margin: 0; color: var(--muted); line-height: 1.6; }
    .pole-body { padding: 18px 20px 22px; }
    .intro-line { color: var(--muted); margin-bottom: 14px; }
    .rows { display: grid; gap: 10px; }
    .row-item { display: grid; grid-template-columns: minmax(260px, 360px) 1fr; gap: 12px; align-items: start; background: rgba(15,23,42,.68); border: 1px solid var(--border); border-radius: 14px; padding: 12px 14px; }
    .folder-name { font-weight: 600; }
    .folder-desc { color: var(--text); line-height: 1.65; }
    .nested-box { margin-top: 14px; background: rgba(2,8,23,.65); border: 1px dashed #3b4b63; border-radius: 16px; padding: 14px; }
    .nested-title { font-weight: 700; margin-bottom: 12px; color: #f8fafc; }
    code { background: var(--code-bg); color: var(--code); border: 1px solid #334155; padding: 3px 8px; border-radius: 8px; font-size: 13px; word-break: break-word; }
    ul { margin: 0; padding-left: 22px; }
    li { margin: 8px 0; line-height: 1.6; }
    .footer { margin-top: 26px; text-align: center; color: var(--muted); font-size: 13px; }
    @media (max-width: 920px) { .row-item { grid-template-columns: 1fr; } }
  </style>
</head>
<body>
  <div class="wrap">
    <section class="hero">
      <h1>Rapport de structure documentaire $([string](Convert-TextToHtmlSafe $RootFolderName))</h1>
      <p>Ce rapport est adapte a la structure finale validee. Il explique le role de chaque pôle fonctionnel ainsi que l'usage attendu de chaque sous-dossier pour faciliter le classement, la migration et la maintenance documentaire.</p>
      <div class="path-box"><strong>Chemin racine cible :</strong> <code>$rootPathHtml</code></div>
      <p class="meta"><strong>Genere le :</strong> $generatedAt</p>
      <div class="legend">
        <span class="chip">Français</span>
        <span class="chip">Mode sombre</span>
        <span class="chip">Structure finale</span>
        <span class="chip">Explication de chaque sous-dossier</span>
      </div>
    </section>

    <h2>1) Logique générale de l'organisation</h2>
    <div class="grid">
      $($cardsHtml -join "`n")
    </div>

    <h2>2) Organisation détaillée de la structure</h2>
    <div class="section-panel">
      <div class="tip">Lecture recommandée : chaque bloc ci-dessous correspond a un pôle fonctionnel. Pour chaque sous-dossier, une explication précise indique le contenu attendu et son usage recommandé.</div>
      $($sectionsHtml -join "`n")
    </div>

    <h2>3) Règles de nommage recommandées</h2>
    <div class="section-panel">
      <ul>
        <li><strong>Dossiers métier :</strong> utiliser <code>NN_Nom_Dossier</code> (ex. <code>03_Comptabilite_et_Finance</code>).</li>
        <li><strong>Dossiers clients domiciliés :</strong> utiliser <code>DOM-0001_NOM-CLIENT</code>.</li>
        <li><strong>Fichiers :</strong> utiliser <code>AAAA-MM-JJ_Type-Document_Entite_Vx.ext</code>.</li>
        <li>Utiliser <code>_et_</code> plutot que <code>&amp;</code> dans les noms crees automatiquement.</li>
        <li>Conserver une seule version officielle des modeles et documents de travail.</li>
      </ul>
    </div>

    <h2>4) Etape suivante conseillee</h2>
    <div class="section-panel">
      <p>Une fois la structure creee, l'etape la plus utile est de lancer un script de migration controlee pour reclasser les dossiers et fichiers existants vers les nouveaux emplacements normalises.</p>
    </div>

    <div class="footer">Rapport genere automatiquement par le script de deploiement de structure ($([string](Convert-TextToHtmlSafe $RootFolderName)))</div>
  </div>
</body>
</html>
"@

    return $html
}

function Create-CentirioStructure {
    param(
        [string]$ParentPath,
        [string]$RootFolderName,
        [bool]$OpenReportAutomatically,
        [bool]$SkipPrompt
    )

    if ([string]::IsNullOrWhiteSpace($ParentPath)) {
        throw 'Le dossier parent est obligatoire.'
    }
    if ([string]::IsNullOrWhiteSpace($RootFolderName)) {
        throw 'Le nom du dossier racine est obligatoire.'
    }

    $rootPath = Join-Path -Path $ParentPath -ChildPath $RootFolderName
    $createdCount = 0

    if (New-CentirioFolder -Path $rootPath) { $createdCount++ }

    $st = Get-ResolvedStructure -RootName $RootFolderName

    $pilotageKey = $st.Keys | Where-Object { $_ -like '*Pilotage*' } | Select-Object -First 1
    $domiciliationKeys = $st.Keys | Where-Object { $_ -like '*Domiciliation*' } | Select-Object -First 1

    foreach ($main in $st.Keys) {
        $mainPath = Join-Path -Path $rootPath -ChildPath $main
        if (New-CentirioFolder -Path $mainPath) { $createdCount++ }

        foreach ($sub in $st[$main].Keys) {
            $subPath = Join-Path -Path $mainPath -ChildPath $sub
            if (New-CentirioFolder -Path $subPath) { $createdCount++ }
        }
    }

    $modeleClientRoot = Join-Path -Path $rootPath -ChildPath "$domiciliationKeys\01_Actifs\_Modele_Client"
    if (New-CentirioFolder -Path $modeleClientRoot) { $createdCount++ }
    foreach ($mc in $ModeleClient.Keys) {
        if (New-CentirioFolder -Path (Join-Path -Path $modeleClientRoot -ChildPath $mc)) { $createdCount++ }
    }

    $strategieSub = if ($pilotageKey) { "$pilotageKey\02_Strategie_et_Organisation" } else { '00_Pilotage\02_Strategie_et_Organisation' }
    $readmePath = Join-Path -Path $rootPath -ChildPath "$strategieSub\README_Nommage_et_Classement.txt"

    $readmeContent = @"
REGLES DE NOMMAGE ET DE CLASSEMENT - $RootFolderName
============================================

1) DOSSIERS METIER
Format : NN_Nom_Dossier
Exemple : 03_Comptabilite_et_Finance

2) DOSSIERS CLIENTS DOMICILIES
Format : DOM-0001_NOM-CLIENT
Exemple : DOM-0007_MASTERLED-LIGHTING

3) FICHIERS
Format recommande : AAAA-MM-JJ_Type-Document_Entite_Vx.ext
Exemple : 2026-03-10_Contrat-Domiciliation_MASTERLED-LIGHTING_V1.pdf

4) REGLES
- Eviter les fautes de frappe et les doublons.
- Eviter les espaces inutiles.
- Conserver une seule version officielle des modeles.
- Deplacer les anciens elements vers les archives si necessaire.
- Utiliser des noms stables et coherents dans toute la structure.
"@
    if (-not (Test-Path -LiteralPath $readmePath)) {
        Write-Utf8BomTextFile -Path $readmePath -Content $readmeContent
    }

    $clientReadmePath = Join-Path -Path $modeleClientRoot -ChildPath 'README_Modele_Client.txt'
    $clientReadmeContent = @"
MODELE STANDARD DE DOSSIER CLIENT - DOMICILIATION
================================================

00_Fiche_Client               : Resume administratif et commercial du client
01_Contrat                    : Contrat, avenants, renouvellements
02_KYC_et_Juridique           : CIN, RC, IF, ICE, statuts, CN, justificatifs
03_Paiements                  : Factures, recus, preuves de reglement
04_Courrier                   : E-mails, lettres, relances, courriers et accusés
05_Formalites_Administratives : Demarches et documents administratifs
06_Incidents                  : Retards, anomalies, blocages
07_Historique                 : Anciennes versions et historique du dossier
99_Archives                   : Pieces anciennes ou inactives
"@
    if (-not (Test-Path -LiteralPath $clientReadmePath)) {
        Write-Utf8BomTextFile -Path $clientReadmePath -Content $clientReadmeContent
    }

    $reportPath = Join-Path -Path $rootPath -ChildPath "$strategieSub\$($RootFolderName)_Rapport_Structure_Finale.html"
    $html = Generate-ReportHtml -RootPath $rootPath -RootFolderName $RootFolderName -IncludeModelClient $true -ReportPilotageKey $pilotageKey
    Write-Utf8BomTextFile -Path $reportPath -Content $html

    if ($OpenReportAutomatically) {
        Start-Process -FilePath $reportPath
    }
    elseif (-not $SkipPrompt) {
        $answer = [System.Windows.Forms.MessageBox]::Show(
            "La structure a ete creee avec succes ($createdCount dossiers crees ou verifies). Voulez-vous ouvrir le rapport HTML maintenant ?",
            "$RootFolderName - Rapport",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        if ($answer -eq [System.Windows.Forms.DialogResult]::Yes) {
            Start-Process -FilePath $reportPath
        }
    }

    return [PSCustomObject]@{
        RootPath = $rootPath
        ReportPath = $reportPath
        CreatedCount = $createdCount
    }
}

if ($NoGui) {
    if ([string]::IsNullOrWhiteSpace($ParentPath)) {
        throw 'En mode -NoGui, le parametre -ParentPath est obligatoire.'
    }
    $result = Create-CentirioStructure -ParentPath $ParentPath -RootFolderName $RootFolderName -OpenReportAutomatically:$AutoOpenReport -SkipPrompt:$SkipOpenPrompt
    Write-Host "Structure creee : $($result.RootPath)" -ForegroundColor Cyan
    Write-Host "Rapport HTML  : $($result.ReportPath)" -ForegroundColor Cyan
    exit 0
}

# ===========================
# GUI / UX INTERACTIVE WINDOW
# ===========================
$form = New-Object System.Windows.Forms.Form
$form.Text = 'CENTIRIO - Création de la structure finale'
$form.Width = 1180
$form.Height = 840
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(18, 24, 38)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$form.Add_Shown({
    $form.Activate()
    [Win32TopMost]::SetForegroundWindow($form.Handle) | Out-Null
})

$header = New-Object System.Windows.Forms.Label
$header.Text = 'Créer la structure documentaire finale de CENTIRIO'
$header.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$header.AutoSize = $true
$header.Location = New-Object System.Drawing.Point(20, 16)
$form.Controls.Add($header)

$subHeader = New-Object System.Windows.Forms.Label
$subHeader.Text = 'Choisissez le dossier parent, vérifiez l''aperçu de la structure, puis lancez la création.'
$subHeader.AutoSize = $true
$subHeader.ForeColor = [System.Drawing.Color]::LightGray
$subHeader.Location = New-Object System.Drawing.Point(22, 48)
$form.Controls.Add($subHeader)

$labelParent = New-Object System.Windows.Forms.Label
$labelParent.Text = 'Dossier parent :'
$labelParent.AutoSize = $true
$labelParent.Location = New-Object System.Drawing.Point(22, 88)
$form.Controls.Add($labelParent)

$textParent = New-Object System.Windows.Forms.TextBox
$textParent.Width = 760
$textParent.Location = New-Object System.Drawing.Point(22, 108)
$textParent.Text = if ($ParentPath) { $ParentPath } else { [Environment]::GetFolderPath('Desktop') }
$form.Controls.Add($textParent)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = 'Parcourir...'
$btnBrowse.Width = 110
$btnBrowse.Height = 30
$btnBrowse.Location = New-Object System.Drawing.Point(792, 106)
$form.Controls.Add($btnBrowse)

$labelRoot = New-Object System.Windows.Forms.Label
$labelRoot.Text = 'Nom du dossier racine :'
$labelRoot.AutoSize = $true
$labelRoot.Location = New-Object System.Drawing.Point(22, 148)
$form.Controls.Add($labelRoot)

$textRoot = New-Object System.Windows.Forms.TextBox
$textRoot.Width = 250
$textRoot.Location = New-Object System.Drawing.Point(22, 168)
$textRoot.Text = $RootFolderName
$form.Controls.Add($textRoot)

$textRoot.Add_TextChanged({
    Update-ResolvedData -RootName $textRoot.Text
    Build-TreeView -TreeView $tree -RootName $textRoot.Text
    Update-InfoPanel -NodeText $textRoot.Text -ParentText ''
})

$checkAutoOpen = New-Object System.Windows.Forms.CheckBox
$checkAutoOpen.Text = 'Ouvrir automatiquement le rapport HTML après création'
$checkAutoOpen.AutoSize = $true
$checkAutoOpen.Location = New-Object System.Drawing.Point(320, 168)
$checkAutoOpen.Checked = [bool]$AutoOpenReport
$form.Controls.Add($checkAutoOpen)

$checkSkipPrompt = New-Object System.Windows.Forms.CheckBox
$checkSkipPrompt.Text = 'Ne pas demander avant d''ouvrir le rapport'
$checkSkipPrompt.AutoSize = $true
$checkSkipPrompt.Location = New-Object System.Drawing.Point(320, 194)
$checkSkipPrompt.Checked = [bool]$SkipOpenPrompt
$form.Controls.Add($checkSkipPrompt)

$groupPreview = New-Object System.Windows.Forms.GroupBox
$groupPreview.Text = 'Aperçu interactif de la structure'
$groupPreview.Width = 540
$groupPreview.Height = 470
$groupPreview.Location = New-Object System.Drawing.Point(22, 228)
$groupPreview.ForeColor = [System.Drawing.Color]::White
$groupPreview.BackColor = [System.Drawing.Color]::FromArgb(18, 24, 38)
$form.Controls.Add($groupPreview)

$tree = New-Object System.Windows.Forms.TreeView
$tree.Width = 510
$tree.Height = 430
$tree.Location = New-Object System.Drawing.Point(15, 25)
$tree.BackColor = [System.Drawing.Color]::FromArgb(25, 34, 52)
$tree.ForeColor = [System.Drawing.Color]::White
$tree.BorderStyle = 'FixedSingle'
$groupPreview.Controls.Add($tree)
Build-TreeView -TreeView $tree

$groupInfo = New-Object System.Windows.Forms.GroupBox
$groupInfo.Text = 'Description du dossier sélectionné'
$groupInfo.Width = 585
$groupInfo.Height = 470
$groupInfo.Location = New-Object System.Drawing.Point(575, 228)
$groupInfo.ForeColor = [System.Drawing.Color]::White
$groupInfo.BackColor = [System.Drawing.Color]::FromArgb(18, 24, 38)
$form.Controls.Add($groupInfo)

$richInfo = New-Object System.Windows.Forms.RichTextBox
$richInfo.Width = 555
$richInfo.Height = 430
$richInfo.Location = New-Object System.Drawing.Point(15, 25)
$richInfo.ReadOnly = $true
$richInfo.BackColor = [System.Drawing.Color]::FromArgb(25, 34, 52)
$richInfo.ForeColor = [System.Drawing.Color]::White
$richInfo.BorderStyle = 'FixedSingle'
$richInfo.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$groupInfo.Controls.Add($richInfo)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Prêt.'
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(22, 712)
$statusLabel.ForeColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($statusLabel)

$btnCreate = New-Object System.Windows.Forms.Button
$btnCreate.Text = 'Créer la structure'
$btnCreate.Width = 160
$btnCreate.Height = 38
$btnCreate.Location = New-Object System.Drawing.Point(740, 706)
$btnCreate.BackColor = [System.Drawing.Color]::FromArgb(34, 197, 94)
$btnCreate.ForeColor = [System.Drawing.Color]::Black
$form.Controls.Add($btnCreate)

$btnOpenReport = New-Object System.Windows.Forms.Button
$btnOpenReport.Text = 'Ouvrir le rapport'
$btnOpenReport.Width = 140
$btnOpenReport.Height = 38
$btnOpenReport.Location = New-Object System.Drawing.Point(910, 706)
$btnOpenReport.Enabled = $false
$form.Controls.Add($btnOpenReport)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = 'Fermer'
$btnClose.Width = 110
$btnClose.Height = 38
$btnClose.Location = New-Object System.Drawing.Point(1050, 706)
$form.Controls.Add($btnClose)

$script:LastReportPath = $null
$script:LastRootPath = $null

function Update-InfoPanel {
    param([string]$NodeText, [string]$ParentText)

    if ([string]::IsNullOrWhiteSpace($NodeText)) {
        $richInfo.Text = ''
        return
    }

    if ($NodeText -eq $RootFolderName) {
        $richInfo.Text = "Dossier racine.`n`nIl contiendra toute la structure documentaire finale."
        return
    }

    if ($script:ResolvedStructure.Contains($NodeText)) {
        $richInfo.Text = "Pôle fonctionnel : $NodeText`n`n$($script:ResolvedRoleDescriptions[$NodeText])`n`nSous-dossiers :`n- " + (($script:ResolvedStructure[$NodeText].Keys) -join "`n- ")
        return
    }

    if ($ParentText -and $script:ResolvedStructure.Contains($ParentText) -and $script:ResolvedStructure[$ParentText].Contains($NodeText)) {
        $richInfo.Text = "Sous-dossier : $NodeText`n`nPôle parent : $ParentText`n`nUsage recommandé : $($script:ResolvedStructure[$ParentText][$NodeText])"
        return
    }

    if ($ParentText -eq '_Modele_Client' -and $ModeleClient.Contains($NodeText)) {
        $richInfo.Text = "Sous-dossier du modèle client : $NodeText`n`nUsage recommandé : $($ModeleClient[$NodeText])"
        return
    }

    if ($NodeText -eq '_Modele_Client') {
        $richInfo.Text = "Modèle standard de dossier client.`n`nCe modèle doit servir de base à la création de chaque nouveau dossier client de domiciliation."
        return
    }

    $richInfo.Text = $NodeText
}

$tree.Add_AfterSelect({
    $nodeText = $_.Node.Text
    $parentText = if ($_.Node.Parent) { $_.Node.Parent.Text } else { '' }
    Update-InfoPanel -NodeText $nodeText -ParentText $parentText
})

$btnBrowse.Add_Click({
    $chosen = Select-FolderGui -Owner $form
    if ($chosen) {
        $textParent.Text = $chosen
        $statusLabel.Text = "Dossier parent sélectionné : $chosen"
    }
    $form.TopMost = $true
    $form.Activate()
    [Win32TopMost]::SetForegroundWindow($form.Handle) | Out-Null
})

$btnCreate.Add_Click({
    try {
        $statusLabel.Text = 'Création en cours...'
        $form.Refresh()
        $parent = $textParent.Text.Trim()
        $root = $textRoot.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($parent)) { throw 'Veuillez choisir un dossier parent.' }
        if ([string]::IsNullOrWhiteSpace($root)) { throw 'Veuillez renseigner le nom du dossier racine.' }

        $result = Create-CentirioStructure -ParentPath $parent -RootFolderName $root -OpenReportAutomatically:$checkAutoOpen.Checked -SkipPrompt:$checkSkipPrompt.Checked
        $script:LastReportPath = $result.ReportPath
        $script:LastRootPath = $result.RootPath
        $btnOpenReport.Enabled = $true
        $statusLabel.Text = "Succès : $($result.CreatedCount) dossier(s) créé(s) ou vérifié(s). Racine : $($result.RootPath)"
        [System.Windows.Forms.MessageBox]::Show(
            "La structure a été créée avec succès.`n`nRacine : $($result.RootPath)`nRapport : $($result.ReportPath)",
            "$($textRoot.Text) - Création terminée",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    }
    catch {
        $statusLabel.Text = 'Erreur : ' + $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "$($textRoot.Text) - Erreur",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
})

$btnOpenReport.Add_Click({
    if ($script:LastReportPath -and (Test-Path -LiteralPath $script:LastReportPath)) {
        Start-Process -FilePath $script:LastReportPath
    }
})

$btnClose.Add_Click({ $form.Close() })

Update-InfoPanel -NodeText $RootFolderName -ParentText ''
[void]$form.ShowDialog()
