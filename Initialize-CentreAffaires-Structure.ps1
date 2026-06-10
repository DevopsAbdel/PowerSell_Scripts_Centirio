<#
.SYNOPSIS
  Initialise une arborescence documentaire standard pour un centre d'affaires.
  Crée uniquement les dossiers manquants (aucune suppression).

.DESCRIPTION
  Ce script crée une structure de dossiers + sous-dossiers.
  L'utilisateur peut choisir :
   - Mode Direct : création directement dans le BasePath (sans dossier parent)
   - Mode SubfolderNamed : création dans un sous-dossier portant le nom du centre
   - Mode SubfolderNamedAndSuffix : création dans un sous-dossier du centre
     ET suffixe les dossiers de niveau 1 avec le nom du centre (ex: 01_Juridique_<Centre>)

.PARAMETER BasePath
  Emplacement cible où créer l'arborescence. Par défaut : dossier courant.

.PARAMETER CenterName
  Nom du centre d'affaires (utilisé pour le dossier parent et/ou suffixes).

.PARAMETER Mode
  - Direct
  - SubfolderNamed
  - SubfolderNamedAndSuffix

.PARAMETER Interactive
  Affiche un menu interactif pour choisir BasePath / CenterName / Mode.

.EXAMPLE
  # 1) Créer directement les dossiers dans D:\Docs (sans parent)
  .\Initialize-CentreAffairesStructure.ps1 -BasePath "D:\Docs" -Mode Direct

.EXAMPLE
  # 2) Créer dans D:\Docs\<NomCentre>\... (parent uniquement)
  .\Initialize-CentreAffairesStructure.ps1 -BasePath "D:\Docs" -CenterName "CENTRIO" -Mode SubfolderNamed

.EXAMPLE
  # 3) Créer dans D:\Docs\<NomCentre>\... + dossiers niveau 1 suffixés
  .\Initialize-CentreAffairesStructure.ps1 -BasePath "D:\Docs" -CenterName "CENTRIO" -Mode SubfolderNamedAndSuffix

.EXAMPLE
  # 4) Mode menu interactif
  .\Initialize-CentreAffairesStructure.ps1 -Interactive
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [Parameter(Mandatory=$false)]
  [string]$BasePath = (Get-Location).Path,

  [Parameter(Mandatory=$false)]
  [string]$CenterName,

  [Parameter(Mandatory=$false)]
  [ValidateSet("Direct","SubfolderNamed","SubfolderNamedAndSuffix")]
  [string]$Mode = "Direct",

  [Parameter(Mandatory=$false)]
  [switch]$Interactive
)

function Convert-ToSafeFolderName {
  param([Parameter(Mandatory=$true)][string]$Name)

  # Remplace les caractères invalides pour un nom de dossier
  $invalid = [IO.Path]::GetInvalidFileNameChars()
  foreach ($c in $invalid) {
    $Name = $Name.Replace($c, '_')
  }

  # Nettoyage additionnel
  $Name = $Name.Trim()
  $Name = $Name -replace '\s+', ' '          # espaces multiples -> simple
  $Name = $Name -replace '[\.]+$', ''        # évite un point final

  return $Name
}

function Ensure-Directory {
  param([Parameter(Mandatory=$true)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    if ($PSCmdlet.ShouldProcess($Path, "Créer le dossier")) {
      New-Item -ItemType Directory -Path $Path -Force | Out-Null
      Write-Host "✅ Créé : $Path" -ForegroundColor Green
    }
    return $true
  } else {
    Write-Host "↩️ Déjà présent : $Path" -ForegroundColor DarkGray
    return $false
  }
}

# -------------------- Mode interactif (menu) --------------------
if ($Interactive -or ($PSBoundParameters.Count -eq 0)) {

  Write-Host ""
  Write-Host "=== Initialisation de l'arborescence (Centre d'affaires) ===" -ForegroundColor Cyan

  $inputBase = Read-Host "1) Emplacement cible BasePath [Entrée = dossier courant]"
  if (-not [string]::IsNullOrWhiteSpace($inputBase)) { $BasePath = $inputBase }

  Write-Host ""
  Write-Host "2) Nom du centre d'affaires (ex: CENTRIO) [optionnel pour Mode Direct]" -ForegroundColor Cyan
  $inputCenter = Read-Host "Nom du centre"
  if (-not [string]::IsNullOrWhiteSpace($inputCenter)) { $CenterName = $inputCenter }

  Write-Host ""
  Write-Host "3) Choix du mode :" -ForegroundColor Cyan
  Write-Host "   [1] Direct (sans dossier parent)"
  Write-Host "   [2] SubfolderNamed (dans un dossier parent <NomCentre>)"
  Write-Host "   [3] SubfolderNamedAndSuffix (parent <NomCentre> + dossiers niveau 1 suffixés)"
  $choice = Read-Host "Choix (1/2/3)"

  switch ($choice) {
    "2" { $Mode = "SubfolderNamed" }
    "3" { $Mode = "SubfolderNamedAndSuffix" }
    default { $Mode = "Direct" }
  }

  # Si mode nécessite un nom centre et qu'il est vide → demander
  if (($Mode -ne "Direct") -and [string]::IsNullOrWhiteSpace($CenterName)) {
    $CenterName = Read-Host "Le mode choisi nécessite un Nom du centre. Merci de le saisir"
  }
}

# -------------------- Validations --------------------
if (-not (Test-Path -LiteralPath $BasePath)) {
  throw "❌ Le chemin BasePath n'existe pas : $BasePath"
}

if (($Mode -ne "Direct") -and [string]::IsNullOrWhiteSpace($CenterName)) {
  throw "❌ CenterName est obligatoire pour le mode $Mode."
}

if (-not [string]::IsNullOrWhiteSpace($CenterName)) {
  $CenterName = Convert-ToSafeFolderName -Name $CenterName
}

# -------------------- Définition des dossiers niveau 1 --------------------
# (Sans suffixe) - base
$topLevel = @(
  "01_Juridique",
  "02_Textes_Législatifs_&_Réglementaires",
  "03_Cachets_&_Identité_Visuelle",
  "04_Banque_Administration",
  "05_Comptabilité",
  "06_Modèles_Contrats",
  "07_Marketing",
  "08_Dev_Outils"
)

# Sous-dossiers par dossier niveau 1 (clés = nom base du dossier niveau 1)
$subTree = @{
  "01_Juridique" = @(
    "01_Documents_Société",
    "02_Contrats_Internes",
    "03_Procédures_Juridiques",
    "04_Rapports_&_Certificats",
    "99_Archives"
  )
  "02_Textes_Législatifs_&_Réglementaires" = @(
    "01_Lois_Officielles",
    "02_BO_&_Circulaires",
    "03_Responsabilités_Domiciliataire",
    "04_Articles_Professionnels",
    "99_Archives"
  )
  "03_Cachets_&_Identité_Visuelle" = @(
    "01_Cachets",
    "02_Logos",
    "03_Plaques",
    "04_Charte_Graphique",
    "99_Archives"
  )
  "04_Banque_Administration" = @(
    "01_Banques",
    "02_Administration_Fiscale",
    "03_Sécurité_Sociale_&_Organismes",
    "04_Opérateurs_Télécom",
    "05_Notifications_Officielles",
    "99_Archives"
  )
  "05_Comptabilité" = @(
    "01_Dépenses",
    "02_Recettes",
    "03_Tableaux_Suivi",
    "04_Banque",
    "05_TVA",
    "06_Déclarations",
    "99_Archives"
  )
  "06_Modèles_Contrats" = @(
    "01_Contrats_Domiciliation",
    "02_Avenants",
    "03_Documents_Associés",
    "04_Formulaires_Types",
    "99_Archives"
  )
  "07_Marketing" = @(
    "01_Plaquettes",
    "02_Offres_&_Tarifs",
    "03_Campagnes",
    "04_Visuels",
    "99_Archives"
  )
  "08_Dev_Outils" = @(
    "01_Odoo",
    "02_Scripts",
    "03_Exports",
    "04_Documentation",
    "99_Archives"
  )
}

# -------------------- Calcul de la racine cible --------------------
$targetRoot = $BasePath

if ($Mode -eq "SubfolderNamed" -or $Mode -eq "SubfolderNamedAndSuffix") {
  $targetRoot = Join-Path $BasePath $CenterName
}

# -------------------- Construction de la liste des dossiers à créer --------------------
# Suffixe éventuel des dossiers niveau 1
function Get-TopFolderName([string]$baseName) {
  if ($Mode -eq "SubfolderNamedAndSuffix") {
    # Exemple : "01_Juridique_CENTRIO"
    return ($baseName + "_" + $CenterName)
  }
  else {
    # Exemple : "01_Juridique"
    return $baseName
  }
}

Write-Host ""
Write-Host "📌 BasePath     : $BasePath"
Write-Host "📌 Mode         : $Mode"
if ($CenterName) { Write-Host "📌 CenterName   : $CenterName" }
Write-Host "📌 Cible (Root) : $targetRoot"
Write-Host "---------------------------------------------"

# Crée la racine cible (BasePath ou BasePath\CenterName)
Ensure-Directory -Path $targetRoot | Out-Null

# Crée dossiers niveau 1 + sous-dossiers
foreach ($t in $topLevel) {
  $topFolder = Get-TopFolderName $t
  $topFull   = Join-Path $targetRoot $topFolder

  Ensure-Directory -Path $topFull | Out-Null

  foreach ($s in $subTree[$t]) {
    $subFull = Join-Path $topFull $s
    Ensure-Directory -Path $subFull | Out-Null
  }
}

Write-Host "---------------------------------------------"
Write-Host "🎉 Terminé : arborescence vérifiée / complétée." -ForegroundColor Cyan