<#
.SYNOPSIS
  Crée l'arborescence standard pour UN centre d'affaires (GUI).
  - Dossiers en Title Case (première lettre majuscule).
  - Acronymes (KYC, PV, CA) conservés si option activée.
  - Bouton "Ajouter un client..." activé après la création (clone _Modele_Client).
  - Boutons AutoSize + couleurs + hover (pas de libellés tronqués).
  - Le dossier ne s’ouvre qu’APRÈS votre clic sur OK dans le message de succès.

.DESCRIPTION
  - Idempotent, chemins avec espaces OK (OneDrive, etc.).
  - Journal CSV horodaté.
  - Mode CLI (pas de GUI) si -RootPath ET -Centre sont fournis.
#>

[CmdletBinding()]
param(
  [string]$RootPath,        # Emplacement racine (CLI)
  [string]$Centre,          # Nom du centre (CLI)
  [switch]$PreserveAcronyms,# Conserver KYC/PV/CA en majuscules (défaut: true)
  [switch]$OpenAfter,       # Ouvrir le dossier après création (mais seulement après OK)
  [string]$LogCsv           # Chemin journal CSV
)

# ---------- RÉSOLUTION ROBUSTE DU DOSSIER DU SCRIPT ----------
$__ScriptPath = $PSCommandPath
if (-not $__ScriptPath) { $__ScriptPath = $MyInvocation.MyCommand.Path }
$__ScriptRoot = if ($__ScriptPath) { Split-Path -Path $__ScriptPath -Parent } else { (Get-Location).Path }

# Valeur par défaut sûre pour le CSV si non fourni
if ([string]::IsNullOrWhiteSpace($LogCsv)) {
  $LogCsv = Join-Path $__ScriptRoot ("arbo_log_{0:yyyyMMdd_HHmmss}.csv" -f (Get-Date))
}
# Par défaut, on conserve les acronymes
if (-not $PSBoundParameters.ContainsKey('PreserveAcronyms')) { $PreserveAcronyms = $true }

# ---------- UTILITAIRES ----------
function New-SafeFolder {
  param([Parameter(Mandatory)][string]$FullPath)
  if (-not (Test-Path -LiteralPath $FullPath)) {
    New-Item -ItemType Directory -Path $FullPath -Force | Out-Null
    return $true
  }
  return $false
}
function Ensure-Path {
  param([Parameter(Mandatory)][string]$Path)
  try {
    return (Resolve-Path -LiteralPath (New-Item -ItemType Directory -Path $Path -Force)).Path
  } catch {
    throw "Chemin invalide ou inaccessible: $Path. Détail: $($_.Exception.Message)"
  }
}
function Sanitize-Name {  # empêche les caractères invalides Windows
  param([string]$Name)
  $invalid = [System.IO.Path]::GetInvalidFileNameChars()
  return -join ($Name.ToCharArray() | ForEach-Object { if ($invalid -contains $_) { '_' } else { $_ } })
}
function Copy-Directory {
  param(
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][string]$Destination
  )
  if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
    throw "Source introuvable : $Source"
  }
  New-SafeFolder -FullPath $Destination | Out-Null
  Copy-Item -Path (Join-Path $Source '*') -Destination $Destination -Recurse -Force -ErrorAction Stop
}
# Conserver KYC/PV/CA
function Transform-RelPath {
  param([Parameter(Mandatory)][string]$Rel)
  if (-not $PreserveAcronyms) { return $Rel }
  $segments = $Rel -split '/'
  for ($i=0; $i -lt $segments.Count; $i++) {
    $parts = $segments[$i] -split '_'
    for ($j=0; $j -lt $parts.Count; $j++) {
      switch -Regex ($parts[$j]) {
        '^Kyc$' { $parts[$j] = 'KYC'; break }
        '^Pv$'  { $parts[$j] = 'PV';  break }
        '^Ca$'  { $parts[$j] = 'CA';  break }
      }
    }
    $segments[$i] = ($parts -join '_')
  }
  return ($segments -join '/')
}

# ---------- ARBORESCENCE EN TITLE CASE ----------
$base = @(
  '01_Domiciliations_Actives',
  '02_Domiciliations_En_Retard',
  '02_Domiciliations_En_Retard/Retard_Paiement',
  '02_Domiciliations_En_Retard/Retard_Documents',
  '02_Domiciliations_En_Retard/Contrat_Expire',
  '03_Domiciliations_Resiliees',
  '04_Collaborateurs',
  '04_Collaborateurs/Experts_Comptables',
  '04_Collaborateurs/Comptables_Agrees',
  '04_Collaborateurs/Independants',
  '04_Collaborateurs/Coursiers',
  '05_Modeles_Documents',
  '05_Modeles_Documents/Contrats',
  '05_Modeles_Documents/Attestations',
  '05_Modeles_Documents/Relances',
  '05_Modeles_Documents/Mise_En_Demeure',
  '05_Modeles_Documents/Resiliation',
  '05_Modeles_Documents/Pv_Reunion',      # -> PV_Reunion si PreserveAcronyms
  '05_Modeles_Documents/Fiche_Client_Standard',
  '06_Procedures_Internes',
  '07_Autorisations_Administratives',
  '08_Comptabilite_Domiciliation',
  '08_Comptabilite_Domiciliation/Factures_Emises',
  '08_Comptabilite_Domiciliation/Recettes_Mensuelles',
  '08_Comptabilite_Domiciliation/Commissions_Collaborateurs',
  '08_Comptabilite_Domiciliation/Tableau_Bord_Ca', # -> Tableau_Bord_CA si PreserveAcronyms
  '09_Archives_Generales'
)
$clientModel = @(
  '_Modele_Client/01_Contrat',
  '_Modele_Client/02_Kyc_Juridique',      # -> 02_KYC_Juridique si PreserveAcronyms
  '_Modele_Client/03_Paiements',
  '_Modele_Client/04_Courrier',
  '_Modele_Client/05_Suivi_Administratif',
  '_Modele_Client/06_Incidents',
  '_Modele_Client/07_Historique'
)

# ---------- CRÉATION ----------
function Run-Creation {
  param(
    [Parameter(Mandatory)][string]$RootPathResolved,
    [Parameter(Mandatory)][string]$CentreName
  )

  $log  = [System.Collections.Generic.List[Object]]::new()
  $ts   = Get-Date
  $year = (Get-Date).Year

  $centreRoot = Join-Path $RootPathResolved $CentreName
  New-SafeFolder -FullPath $centreRoot | Out-Null

  foreach ($rel in $base) {
    $relFinal = Transform-RelPath -Rel $rel
    $full = Join-Path $centreRoot $relFinal
    $created = New-SafeFolder -FullPath $full
    $log.Add([pscustomobject]@{
      Time=$ts; Centre=$CentreName; RelativePath=$relFinal; FullPath=$full; Created=$created
    })
  }

  # _Modele_Client sous 01_Domiciliations_Actives (toujours créé)
  $actives = Join-Path $centreRoot (Transform-RelPath -Rel '01_Domiciliations_Actives')
  foreach ($rel in $clientModel) {
    $relFinal = Transform-RelPath -Rel $rel
    $full = Join-Path $actives $relFinal
    $created = New-SafeFolder -FullPath $full
    $log.Add([pscustomobject]@{
      Time=$ts; Centre=$CentreName; RelativePath=("01_Domiciliations_Actives/$relFinal"); FullPath=$full; Created=$created
    })
  }
  $readme = Join-Path $actives (Transform-RelPath -Rel '_Modele_Client/README_ModeleClient.txt')
  if (-not (Test-Path $readme)) {
@"
Modèle de dossier client – à dupliquer pour chaque nouvelle domiciliation.
Convention de nommage recommandée : DOM-AAAA-###_NOMCLIENT_ICE (ex: DOM-2026-001_DUPONT_001234567890)
Copiez le dossier _Modele_Client et renommez-le selon l'ID client.
"@ | Set-Content -Path $readme -Encoding UTF8
  }

  # Année courante sous "03_Domiciliations_Resiliees"
  $resRoot = Join-Path $centreRoot (Transform-RelPath -Rel '03_Domiciliations_Resiliees')
  New-SafeFolder -FullPath (Join-Path $resRoot $year) | Out-Null

  try { $log | Export-Csv -Path $LogCsv -NoTypeInformation -Encoding UTF8 } catch {
    Write-Warning "Impossible d'écrire le journal: $($_.Exception.Message)"
  }

  return $centreRoot
}

# ---------- AJOUT CLIENT ----------
function Show-ClientInputDialog {
  param([string]$DefaultValue)

  $dlg = New-Object System.Windows.Forms.Form
  $dlg.Text = "Ajouter un client"
  $dlg.StartPosition = 'CenterParent'
  $dlg.FormBorderStyle = 'FixedDialog'
  $dlg.MaximizeBox = $false
  $dlg.MinimizeBox = $false
  $dlg.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
  $dlg.Font = New-Object System.Drawing.Font('Segoe UI', 10)
  $dlg.ClientSize = New-Object System.Drawing.Size(520, 140)

  $lbl = New-Object System.Windows.Forms.Label
  $lbl.Text = "Nom/ID client (ex : DOM-2026-001_DUPONT_001234567890) :"
  $lbl.AutoSize = $true
  $lbl.Location = New-Object System.Drawing.Point(12, 12)

  $txt = New-Object System.Windows.Forms.TextBox
  $txt.Location = New-Object System.Drawing.Point(16, 40)
  $txt.Width = 488
  $txt.Text = $DefaultValue

  $btnOk = New-Object System.Windows.Forms.Button
  $btnOk.Text = "Ajouter"
  $btnOk.Location = New-Object System.Drawing.Point(312, 84)
  $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $btnOk.AutoSize = $true
  $btnOk.AutoSizeMode = 'GrowAndShrink'

  $btnCancel = New-Object System.Windows.Forms.Button
  $btnCancel.Text = "Annuler"
  $btnCancel.Location = New-Object System.Drawing.Point(410, 84)
  $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
  $btnCancel.AutoSize = $true
  $btnCancel.AutoSizeMode = 'GrowAndShrink'

  $dlg.AcceptButton = $btnOk
  $dlg.CancelButton = $btnCancel

  $dlg.Controls.AddRange(@($lbl,$txt,$btnOk,$btnCancel))
  $res = $dlg.ShowDialog()
  if ($res -eq [System.Windows.Forms.DialogResult]::OK) { return $txt.Text } else { return $null }
}

function Add-ClientFromModel {
  param(
    [Parameter(Mandatory)][string]$CentreRoot,
    [Parameter(Mandatory)][string]$ClientName
  )
  $actives = Join-Path $CentreRoot (Transform-RelPath -Rel '01_Domiciliations_Actives')
  $model   = Join-Path $actives (Transform-RelPath -Rel '_Modele_Client')
  if (-not (Test-Path -LiteralPath $model -PathType Container)) {
    throw "Le dossier modèle est introuvable : $model"
  }

  $clientSafe = Sanitize-Name -Name $ClientName
  if ([string]::IsNullOrWhiteSpace($clientSafe)) {
    throw "Nom/ID client invalide."
  }

  $dest = Join-Path $actives $clientSafe
  if (Test-Path -LiteralPath $dest) {
    $overwrite = [System.Windows.Forms.MessageBox]::Show(
      "Le dossier client existe déjà : `"$clientSafe`".`nVoulez-vous écraser/compléter son contenu ?",
      "Existant", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($overwrite -ne [System.Windows.Forms.DialogResult]::Yes) { return $null }
  }
  Copy-Directory -Source $model -Destination $dest
  return $dest
}

# ---------- MODE CLI (pas de GUI) ----------
if ($PSBoundParameters.ContainsKey('RootPath') -and $PSBoundParameters.ContainsKey('Centre')) {
  $rp = Ensure-Path -Path $RootPath
  $centreSafe = Sanitize-Name -Name $Centre
  $centreRoot = Run-Creation -RootPathResolved $rp -CentreName $centreSafe
  # Attendre l'OK de l'utilisateur AVANT d'ouvrir
  if ($OpenAfter) {
    $res = [System.Windows.Forms.MessageBox]::Show("Arborescence créée.`nVoulez-vous ouvrir le dossier maintenant ?","Succès",[System.Windows.Forms.MessageBoxButtons]::OKCancel,[System.Windows.Forms.MessageBoxIcon]::Information)
    if ($res -eq [System.Windows.Forms.DialogResult]::OK) { try { Start-Process -FilePath $centreRoot } catch {} }
  }
  Write-Host "Création terminée. Journal: $LogCsv"
  return
}

# ---------- GUI AMÉLIORÉE ----------
try {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing
} catch {
  throw "La GUI n'est pas disponible sur ce PowerShell. Lancez en mode CLI avec -RootPath et -Centre."
}

# Palette + hover (mêmes couleurs que précédemment)
$Colors = @{
  Primary        = [System.Drawing.ColorTranslator]::FromHtml("#2563EB") # bleu
  PrimaryHover   = [System.Drawing.ColorTranslator]::FromHtml("#1D4ED8")
  Success        = [System.Drawing.ColorTranslator]::FromHtml("#10B981") # vert
  SuccessHover   = [System.Drawing.ColorTranslator]::FromHtml("#059669")
  Neutral        = [System.Drawing.ColorTranslator]::FromHtml("#E5E7EB") # gris clair
  NeutralHover   = [System.Drawing.ColorTranslator]::FromHtml("#D1D5DB")
  ForeOnPrimary  = [System.Drawing.Color]::White
  ForeOnNeutral  = [System.Drawing.Color]::Black
}

function Style-Button {
  param(
    [Parameter(Mandatory)][System.Windows.Forms.Button]$Btn,
    [ValidateSet('primary','success','neutral')][string]$Kind = 'neutral'
  )
  # Laisser Windows gérer la taille : plus de troncature
  $Btn.AutoSize = $true
  $Btn.AutoSizeMode = 'GrowAndShrink'
  $Btn.FlatStyle = 'Flat'
  $Btn.FlatAppearance.BorderSize = 0
  $Btn.Cursor = 'Hand'
  $Btn.Padding = New-Object System.Windows.Forms.Padding(10,6,10,6)

  switch ($Kind) {
    'primary' {
      $Btn.BackColor = $Colors.Primary
      $Btn.ForeColor = $Colors.ForeOnPrimary
      $Btn.Add_MouseEnter({ $this.BackColor = $Colors.PrimaryHover })
      $Btn.Add_MouseLeave({ $this.BackColor = $Colors.Primary })
    }
    'success' {
      $Btn.BackColor = $Colors.Success
      $Btn.ForeColor = $Colors.ForeOnPrimary
      $Btn.Add_MouseEnter({ $this.BackColor = $Colors.SuccessHover })
      $Btn.Add_MouseLeave({ $this.BackColor = $Colors.Success })
    }
    default {
      $Btn.BackColor = $Colors.Neutral
      $Btn.ForeColor = $Colors.ForeOnNeutral
      $Btn.Add_MouseEnter({ $this.BackColor = $Colors.NeutralHover })
      $Btn.Add_MouseLeave({ $this.BackColor = $Colors.Neutral })
    }
  }
}

# Fenêtre
$form = New-Object System.Windows.Forms.Form
$form.Text = "Création arborescence - Centre d'affaires"
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$form.ClientSize = New-Object System.Drawing.Size(800, 360)
$form.KeyPreview = $true

# Layout principal
$layout = New-Object System.Windows.Forms.TableLayoutPanel
$layout.Dock = 'Fill'
$layout.RowCount = 7
$layout.ColumnCount = 2
$layout.Padding = New-Object System.Windows.Forms.Padding(12,12,12,12)
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 200)))
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100)))
0..6 | ForEach-Object { $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) } | Out-Null
$layout.RowStyles[5] = New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)

# Champs
$lblCentre = New-Object System.Windows.Forms.Label
$lblCentre.Text = "Nom du centre :"
$lblCentre.AutoSize = $true
$lblCentre.Anchor = 'Left'

$txtCentre = New-Object System.Windows.Forms.TextBox
$txtCentre.Anchor = 'Left,Right'
$txtCentre.Width = 560
$txtCentre.TabIndex = 0

$lblRoot = New-Object System.Windows.Forms.Label
$lblRoot.Text = "Emplacement (RootPath) :"
$lblRoot.AutoSize = $true
$lblRoot.Anchor = 'Left'

$txtRoot = New-Object System.Windows.Forms.TextBox
$txtRoot.Anchor = 'Left,Right'
$txtRoot.ReadOnly = $true
$txtRoot.Width = 560
$txtRoot.TabStop = $false

# Barre boutons Emplacement (auto-size, pas de troncature)
$buttonsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonsPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
$buttonsPanel.WrapContents = $false
$buttonsPanel.AutoSize = $true
$buttonsPanel.AutoSizeMode = 'GrowAndShrink'
$buttonsPanel.Anchor = 'Left'

$btnScript = New-Object System.Windows.Forms.Button
$btnScript.Text = "Dossier du script"
Style-Button -Btn $btnScript -Kind neutral

$btnCurrent = New-Object System.Windows.Forms.Button
$btnCurrent.Text = "Dossier courant"
Style-Button -Btn $btnCurrent -Kind neutral

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Parcourir…"
Style-Button -Btn $btnBrowse -Kind neutral

$buttonsPanel.Controls.AddRange(@($btnScript,$btnCurrent,$btnBrowse))

# Options
$optsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$optsPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
$optsPanel.WrapContents = $false
$optsPanel.AutoSize = $true
$optsPanel.Anchor = 'Left'

$chkAcronyms = New-Object System.Windows.Forms.CheckBox
$chkAcronyms.Text = "Conserver les acronymes (KYC, PV, CA)"
$chkAcronyms.Checked = $true
$chkAcronyms.AutoSize = $true

$chkOpen = New-Object System.Windows.Forms.CheckBox
$chkOpen.Text = "Ouvrir le dossier après création"
$chkOpen.Checked = $false
$chkOpen.AutoSize = $true

$optsPanel.Controls.AddRange(@($chkAcronyms,$chkOpen))

# Actions (à droite)
$actionsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$actionsPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::RightToLeft
$actionsPanel.Dock = 'Bottom'
$actionsPanel.AutoSize = $true
$actionsPanel.AutoSizeMode = 'GrowAndShrink'

$btnCreate = New-Object System.Windows.Forms.Button
$btnCreate.Text = "Créer"
Style-Button -Btn $btnCreate -Kind primary

$btnAddClient = New-Object System.Windows.Forms.Button
$btnAddClient.Text = "Ajouter un client…"
$btnAddClient.Enabled = $false
Style-Button -Btn $btnAddClient -Kind success

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Annuler"
Style-Button -Btn $btnCancel -Kind neutral

$actionsPanel.Controls.AddRange(@($btnCreate,$btnAddClient,$btnCancel))

# Tooltips
$tip = New-Object System.Windows.Forms.ToolTip
$tip.SetToolTip($btnScript, "Utiliser le dossier où se trouve le script.")
$tip.SetToolTip($btnCurrent,"Utiliser le dossier courant (Get-Location).")
$tip.SetToolTip($btnBrowse, "Choisir un dossier via l'explorateur.")
$tip.SetToolTip($btnAddClient, "Dupliquer _Modele_Client pour créer un nouveau client.")
$tip.SetToolTip($btnCreate, "Créer l'arborescence du centre.")
$tip.SetToolTip($chkAcronyms, "Garde KYC/PV/CA en majuscules dans les noms de dossiers.")
$tip.SetToolTip($chkOpen, "N'ouvrira le dossier qu'après votre clic sur OK.")

# ErrorProvider
$err = New-Object System.Windows.Forms.ErrorProvider
$err.BlinkStyle = [System.Windows.Forms.ErrorBlinkStyle]::NeverBlink

# Disposition
$layout.Controls.Add($lblCentre, 0, 0)
$layout.Controls.Add($txtCentre, 1, 0)
$layout.Controls.Add($lblRoot,   0, 1)
$layout.Controls.Add($txtRoot,   1, 1)
$layout.Controls.Add($buttonsPanel, 1, 2)
$layout.Controls.Add($optsPanel,    1, 3)
$layout.Controls.Add($actionsPanel, 1, 6)
$form.Controls.Add($layout)

# Emplacement
$btnScript.Add_Click({ $txtRoot.Text = $__ScriptRoot })
$btnCurrent.Add_Click({ $txtRoot.Text = (Get-Location).Path })
$btnBrowse.Add_Click({
  $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
  $dlg.Description = "Choisissez le dossier racine (RootPath)"
  $dlg.SelectedPath = if ($txtRoot.Text) { $txtRoot.Text } else { $__ScriptRoot }
  if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $txtRoot.Text = $dlg.SelectedPath
  }
})

# Drag & drop sur RootPath
$txtRoot.AllowDrop = $true
$txtRoot.Add_DragEnter({
  if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
    $_.Effect = [System.Windows.Forms.DragDropEffects]::Copy
  }
})
$txtRoot.Add_DragDrop({
  $items = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
  if ($items -and (Test-Path $items[0] -PathType Container)) { $txtRoot.Text = $items[0] }
})

# Variable session
$global:__LastCentreRoot = $null

# Création (valider + exécuter)
function Validate-And-Run {
  $err.SetError($txtCentre,''); $err.SetError($txtRoot,'')
  if ([string]::IsNullOrWhiteSpace($txtCentre.Text)) {
    $err.SetError($txtCentre, "Saisissez le nom du centre.")
    $txtCentre.Focus(); return
  }
  if ([string]::IsNullOrWhiteSpace($txtRoot.Text)) {
    $err.SetError($txtRoot, "Choisissez l'emplacement (RootPath).")
    return
  }
  try {
    $rp = Ensure-Path -Path $txtRoot.Text
    $script:PreserveAcronyms = $chkAcronyms.Checked
    $centreSafe = Sanitize-Name -Name $txtCentre.Text
    $global:__LastCentreRoot = Run-Creation -RootPathResolved $rp -CentreName $centreSafe

    # 1) Montrer le message de succès en premier
    $res = [System.Windows.Forms.MessageBox]::Show(
      "Arborescence créée pour `"$($txtCentre.Text)`".`nJournal : $LogCsv",
      "Succès",
      [System.Windows.Forms.MessageBoxButtons]::OK,
      [System.Windows.Forms.MessageBoxIcon]::Information
    )

    # 2) Puis ouvrir (si coché) APRES le clic sur OK
    if ($res -eq [System.Windows.Forms.DialogResult]::OK -and $chkOpen.Checked) {
      try { Start-Process -FilePath $global:__LastCentreRoot } catch {}
    }

    # 3) Activer "Ajouter un client…"
    $btnAddClient.Enabled = $true
  } catch {
    [System.Windows.Forms.MessageBox]::Show("Erreur : $($_.Exception.Message)","Erreur",0,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
  }
}

# Ajouter un client
$btnAddClient.Add_Click({
  if (-not $global:__LastCentreRoot) {
    [System.Windows.Forms.MessageBox]::Show("Créez d'abord le centre pour activer l'ajout de client.","Information",0,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    return
  }
  $suggest = "DOM-$(Get-Date -Format yyyy)-001_NOMCLIENT_ICE"
  $client = Show-ClientInputDialog -DefaultValue $suggest
  if ($client) {
    try {
      $dest = Add-ClientFromModel -CentreRoot $global:__LastCentreRoot -ClientName $client
      if ($dest) {
        # Afficher d'abord le message, puis ouvrir si OK
        $r = [System.Windows.Forms.MessageBox]::Show(
          "Client ajouté : `"$client`"`n$dest",
          "Succès",
          [System.Windows.Forms.MessageBoxButtons]::OK,
          [System.Windows.Forms.MessageBoxIcon]::Information
        )
        if ($r -eq [System.Windows.Forms.DialogResult]::OK) {
          try { Start-Process -FilePath $dest } catch {}
        }
      }
    } catch {
      [System.Windows.Forms.MessageBox]::Show("Erreur lors de l'ajout du client : $($_.Exception.Message)","Erreur",0,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
  }
})

# Créer / Annuler
$btnCreate.Add_Click({ Validate-And-Run })
$btnCancel.Add_Click({ $form.Close() })

# Raccourcis clavier
$form.AcceptButton = $btnCreate
$form.CancelButton = $btnCancel

# Tab order
$txtCentre.TabIndex = 0
$btnScript.TabIndex = 1
$btnCurrent.TabIndex = 2
$btnBrowse.TabIndex = 3
$chkAcronyms.TabIndex = 4
$chkOpen.TabIndex = 5
$btnAddClient.TabIndex = 6
$btnCancel.TabIndex = 7
$btnCreate.TabIndex = 8

# Valeur par défaut
$txtRoot.Text = $__ScriptRoot

# Afficher
[void]$form.ShowDialog()