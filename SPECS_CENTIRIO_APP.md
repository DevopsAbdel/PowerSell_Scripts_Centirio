# SPECS — CENTIRIO Application WPF .NET 8

## A donner a un agent IA pour developper l'application

---

## 1. Presentation

Application de bureau WPF .NET 8 pour la creation de dossiers clients structures destinee aux centres d'affaires au Maroc.

**Nom du projet :** `CENTIRIO.CreationDossier`

---

## 2. Architecture

```
CENTIRIO.CreationDossier/
├── CENTIRIO.CreationDossier.sln
├── src/
│   └── CENTIRIO.CreationDossier/
│       ├── CENTIRIO.CreationDossier.csproj
│       ├── Program.cs                          # Point d'entree + STAThread
│       ├── App.xaml / App.xaml.cs               # Resources globales, theming
│       ├── MainWindow.xaml / MainWindow.xaml.cs # Fenetre principale
│       ├── Models/
│       │   ├── CollaboratorType.cs              # Enum/class des types collaborateur
│       │   ├── DossierInfo.cs                   # Modele de donnees d'un dossier
│       │   └── AppConfig.cs                     # Configuration (prefixes, sous-dossiers)
│       ├── ViewModels/
│       │   └── MainViewModel.cs                 # ViewModel MVVM principal
│       ├── Views/
│       │   └── (utiliser MainWindow, pas de vues separees pour v1)
│       ├── Services/
│       │   ├── IDossierService.cs               # Interface
│       │   ├── DossierService.cs                # Creation, verification, rollback
│       │   ├── ILoggingService.cs
│       │   ├── LoggingService.cs                # Logs fichier + console
│       │   ├── IIdService.cs
│       │   └── IdService.cs                     # Gestion ID, auto-num, validation
│       ├── Data/
│       │   ├── AppDbContext.cs                  # Contexte SQLite
│       │   └── Migrations/                      # Migrations EF Core
│       ├── Converters/
│       │   └── BoolToVisibilityConverter.cs
│       ├── Styles/
│       │   ├── DarkTheme.xaml                   # Resources sombres
│       │   └── LightTheme.xaml                  # Resources claires
│       └── Helpers/
│           ├── SafeNameHelper.cs                # Nettoyage noms fichiers
│           └── StringExtensions.cs
├── tests/
│   └── CENTIRIO.CreationDossier.Tests/
│       ├── Services/
│       │   ├── DossierServiceTests.cs
│       │   └── IdServiceTests.cs
│       └── ...
└── docs/
    └── (ce fichier)
```

---

## 3. Fonctionnalites

### 3.1 Creation de dossier
- Prefixe ID : ComboBox editable (DOM-, FIXE-, PRJ- + libre)
- Numero : TextBox 0-1000 avec padding 4 chiffres (0001)
- Apercu ID en temps reel (lecture seule)
- Type collaborateur : ComboBox avec les 7 types
- Nom collaborateur : TextBox
- Societe : TextBox
- Emplacement racine : ReadOnly + bouton Parcourir
- Bouton Creer (desactive si champs incomplets)
- Bouton Nouveau (reset formulaire)
- Bouton Fermer

### 3.2 Regles de creation
- Nom dossier : `{ID}-[{CODE}-{NOM_COLLAB}]-{SOCIETE}`
  - Exemple : `DOM-0012-[EXP-FIDBA]-NOVA-INTELIGENCIA-GROUP`
  - Espaces remplaces par `-`, caracteres invalides nettoyes
- Sous-dossiers crees automatiquement :
  - `01_Docs_Recus`
  - `02_Docs_Envoyes`
  - `03_Docs_Comptable`
  - `04_Autres_Docs`
- Detection ID existant (debut du nom du dossier)
- Verification droits ecriture avant creation
- Rollback si echec partiel

### 3.3 Types collaborateur (3 lettres)

| Code | Libelle |
|------|---------|
| EXP | Expert Comptable |
| AGR | Comptable Agree |
| CPI | Comptable Independant |
| AGC | Coursier Comptable Agree |
| COU | Coursier Independant |
| ECP | Coursier Expert Comptable |
| CLT | Client Direct |

### 3.4 Journalisation
- Fichier log horodate dans `%APPDATA%\CENTIRIO\Logs\`
- Niveaux : DEBUG, INFO, WARN, ERROR
- Contenu : date, niveau, message, nom machine, utilisateur

### 3.5 Persistance SQLite (v1)
- Table `Dossiers` :
  - `Id` (int, PK, auto-increment)
  - `DossierId` (string, ex: DOM-0012)
  - `FolderName` (string, nom complet du dossier)
  - `FullPath` (string, chemin absolu)
  - `CollaboratorCode` (string, EXP/AGR/...)
  - `CollaboratorName` (string)
  - `CompanyName` (string)
  - `CreatedAt` (datetime)
  - `CreatedBy` (string, nom utilisateur Windows)

---

## 4. UI / XAML Specifications

### 4.1 Theme
- Dark mode par defaut
- Possibilite basculer en clair (bouton ou menu)
- Palette couleurs :
  - Fond fenetre : `#1E1E1E`
  - Panels : `#252526`, `#2D2D30`
  - Texte : `#F0F0F0`
  - Accent bleu : `#0078D4`
  - Accent vert : `#2EA043` (validation, creation)
  - Accent rouge : `#D64545` (fermeture, erreur)
  - Selection : `#3A86FF`
  - Survol : `#3A3A3A`

### 4.2 Fenetre principale
- Taille : 860x600, non redimensionnable
- Centree ecran
- Titre : "CENTIRIO - Creation de dossier client"
- Header avec titre
- Formulaire 7 lignes, 3 colonnes
- Boutons en bas a droite

### 4.3 Controles specifiques
- ComboBox editable pour prefixe (template personnalise avec PART_EditableTextBox)
- ComboBox non-editable pour type collaborateur
- TextBox ID en lecture seule
- FolderBrowserDialog pour racine
- ToolTip sur chaque champ

---

## 5. Diagramme de navigation

```
Demarrage
    │
    ▼
┌─────────────────────────────────┐
│  Fenetre principale             │
│                                 │
│  [Prefixe] [______v______]      │
│  [Numero ] [___________]        │
│  [ID apercu] [___________]      │
│  [Type   ] [______v______]      │
│  [Collab ] [___________]        │
│  [Societe] [___________]        │
│  [Racine ] [________] [Browse]  │
│                                 │
│  [Creer] [Nouveau] [Fermer]     │
└─────────────────────────────────┘
    │        │         │
    │        │         └──> Quitter
    │        └──> Reset formulaire
    │
    ▼
Valider champs → Creer dossier → Sous-dossiers → Log → MsgBox succes
                                                        │
                                                        └──> [Oui] → Ouvrir Explorer
                                                             [Non] → Fin
```

---

## 6. Dependances NuGet

```xml
<ItemGroup>
  <!-- Core -->
  <PackageReference Include="CommunityToolkit.Mvvm" Version="8.*" />
  <PackageReference Include="Microsoft.Extensions.Hosting" Version="8.*" />
  <PackageReference Include="Microsoft.Extensions.DependencyInjection" Version="8.*" />

  <!-- Data -->
  <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" Version="8.*" />
  <PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="8.*" />

  <!-- Logging -->
  <PackageReference Include="Serilog" Version="3.*" />
  <PackageReference Include="Serilog.Sinks.File" Version="5.*" />
  <PackageReference Include="Serilog.Sinks.Async" Version="1.*" />
  <PackageReference Include="Serilog.Extensions.Hosting" Version="8.*" />

  <!-- PDF -->
  <PackageReference Include="QuestPDF" Version="2024.*" />

  <!-- Excel -->
  <PackageReference Include="ClosedXML" Version="0.102.*" />

  <!-- OCR -->
  <PackageReference Include="Tesseract" Version="5.*" />

  <!-- Microsoft Graph (cloud sync) -->
  <PackageReference Include="Azure.Identity" Version="1.*" />
  <PackageReference Include="Microsoft.Graph" Version="5.*" />

  <!-- Google Drive -->
  <PackageReference Include="Google.Apis.Drive.v3" Version="1.*" />

  <!-- Email -->
  <PackageReference Include="MailKit" Version="4.*" />

  <!-- Charts -->
  <PackageReference Include="LiveChartsCore.SkiaSharpView.WPF" Version="2.*" />

  <!-- Word templates -->
  <PackageReference Include="DocX" Version="3.*" />

  <!-- API (self-host) -->
  <PackageReference Include="Microsoft.AspNetCore.App" Version="8.*" />

  <!-- Tests -->
  <PackageReference Include="xunit" Version="2.*" />
  <PackageReference Include="Moq" Version="4.*" />
  <PackageReference Include="Microsoft.EntityFrameworkCore.InMemory" Version="8.*" />

  <!-- Encryption -->
  <PackageReference Include="System.Security.Cryptography.ProtectedData" Version="8.*" />
</ItemGroup>
```

---

## 7. Prompts pour l'agent IA

### Prompt 1 : Initialisation du projet
```
Cree un projet WPF .NET 8 en C# nomme CENTIRIO.CreationDossier avec :
- Architecture MVVM (CommunityToolkit.Mvvm)
- Entity Framework Core SQLite pour persistance
- Serilog pour logging
- Structure decoupee en Models/, ViewModels/, Services/, Data/, Converters/, Helpers/
- Program.cs avec [STAThread] et configuration du logging et de la db
```

### Prompt 2 : Modeles et Configuration
```
Cree les modeles suivants :
- CollaboratorType : classe avec proprietes Code (string) et Label (string), liste statique des 7 types
- DossierInfo : classe avec Id, DossierId, FolderName, FullPath, CollaboratorCode, CollaboratorName, CompanyName, CreatedAt, CreatedBy
- AppConfig : classe statique avec Prefixes (liste), SubFolders (liste), MaxIdNumber = 1000, PadLength = 4
Ajoute le DbContext avec DbSet<DossierInfo>
```

### Prompt 3 : Services
```
Implemente les services :
- IIdService / IdService : construire ID, valider, extraire prefixe, auto-increment
- IDossierService / DossierService : CreateDossierAsync, TestIdExists, EnsureSubfolders, rollback
- ILoggingService / LoggingService : logger dans fichier Serilog
- SafeNameHelper : nettoyage nom fichier
- Test-DirectoryWritable equivalent
```

### Prompt 4 : ViewModel
```
Cree MainViewModel avec :
- Proprietes bindables : IdPrefix, IdNumber, IdPreview, SelectedType, CollaboratorName, CompanyName, RootPath
- Commandes : CreateCommand, NewCommand, BrowseCommand, CloseCommand
- Validation : CanCreate retourne true seulement si tous les champs valides
- Evenements : PropertyChanged pour mise a jour ID preview
```

### Prompt 5 : XAML UI
```
Cree MainWindow.xaml avec :
- Dark theme complet (resources dans Window.Resources)
- ComboBox editable pour prefixe avec template custom incluant PART_EditableTextBox
- ComboBox pour type collaborateur
- TextBox avec IsReadOnly pour ID preview
- FolderBrowserDialog sur bouton Parcourir
- DataBinding au MainViewModel
- ToolTip sur chaque controle
- Header panel, formulaire panel, boutons panel
```

### Prompt 6 : Dashboard et statistiques
```
Ajoute une page Dashboard a l'application avec :
- VueModel : DashboardViewModel avec KPI (total, mois, expirations, nouveaux)
- Graphiques LiveCharts2 : histogramme evolution mensuelle, camembert repartition types
- DataGrid : contrats arrivant a expiration dans les 30 jours
- DataGrid : 10 derniers dossiers crees
- Refresh automatique toutes les 60 secondes
- Export des donnees en CSV
- Navigation depuis le menu principal
```

### Prompt 7 : Generation PDF
```
Implemente le service IPdfService / PdfService avec QuestPDF :
- Methode : GenerateFicheClient(DossierInfo) → fichier PDF
- Methode : GenerateAttestationDomiciliation(DossierInfo, Contrat) → fichier PDF
- Methode : GenerateContrat(DossierInfo, Contrat, TemplatePath) → fichier PDF
- Template : logo, en-tete, pied de page, cadre juridique
- Cachet et signature positions configurable
```

### Prompt 8 : OCR et extraction
```
Implemente le service IOcrService / OcrService avec Tesseract :
- Methode : ExtractTextFromImage(string imagePath) → string
- Methode : ExtractCIN(string imagePath) → CINInfo (nom, prenom, numero, dateNaissance)
- Methode : ExtractICE(string imagePath) → ICEInfo (numero, raisonSociale, adresse)
- Preprocessing : deskew, denoise, binarize, resize
- Regex patterns pour formats marocains (CIN: XX-XXXXXX, ICE: 15 chiffres)
- Auto-remplissage du formulaire apres extraction
```

### Prompt 9 : Cloud sync (Microsoft Graph)
```
Implemente ICloudSyncService / CloudSyncService :
- Authentification OAuth2 avec Azure AD (device code flow)
- Methode : ConnectAsync() → boolean
- Methode : CreateFolderHierarchyAsync(DossierInfo) → folderId
- Methode : UploadFileAsync(string localPath, string remoteFolderId) → boolean
- Methode : SyncAllAsync() → SyncResult
- Methode : DisconnectAsync()
- Stockage securise des tokens (ProtectedData DPAPI)
- Indicateur de statut dans l'interface
```

### Prompt 10 : Validation ICE/RC/IF Maroc
```
Cree MoroccanIdValidator avec :
- ValidateICE(string ice) : 15 chiffres, check-digit LN modifie
- ValidateRC(string rc) : format flexible selon villes
- ValidateIF(string if) : 7 chiffres
- ValidateCNSS(string cnss) : format XX-XXXXXXX
- ValidateCIN(string cin) : format 2 lettres + 6 chiffres
- AutoFormat(string input, string type) : formate automatiquement
- Chaque methode retourne ValidationResult { IsValid, Message, FormattedValue }
- Integration UI : icone verte/rouge a cote du champ
```

### Prompt 11 : Contrats et echeances
```
Implemente le module contrats :
- Modele Contrat avec toutes les proprietes (type, dates, montant, statut...)
- Service IContratService : CRUD, renouvellement, expiration
- ViewModel ContratViewModel avec commandes Creer, Renouveler, Resilier
- Vue ContratWindow.xaml avec DataGrid et formulaire
- Alerte : notification automatique a J-30, J-15, J-7, J-1
- Generation du document Word via DocX (template avec merge fields)
- Historique des statuts
```

### Prompt 12 : Packaging
```
Ajoute un projet d'installation :
- Soit avec Inno Setup (script .iss)
- Soit avec WiX Toolset (.wxs)
- Ou utilise dotnet publish --self-contained pour .exe standalone
Genere un script build.ps1 qui compile, publie et cree l'installeur
```

---

### 3.6 Auto-numerotation intelligente
- Au chargement du formulaire, scruter le dossier racine pour trouver le dernier numero utilise
- Afficher automatiquement le numero suivant dans le champ
- Detection par prefixe : pour `DOM-`, chercher `DOM-` suivi de 4 chiffres
- Fallback : 1 si aucun dossier existant
- Possibilite de desactiver l'auto (check box "Auto")

### 3.7 Recherche de dossiers existants
- Fenetre modale de recherche (Ctrl+F)
- Filtres : ID, nom collaborateur, societe, type, date creation
- Liste resultats avec DataGrid triable
- Double-clic → ouvrir le dossier dans Explorer
- Bouton pour copier le chemin complet

### 3.8 Gestion des contrats et conventions
- Module dedie avec contrats lies a chaque dossier
- Types : Contrat de domiciliation, Convention de siege social, Avenant
- Dates : signature, debut, fin, renouvellement automatique
- Alertes echeance 30/15/7 jours avant expiration
- Etat : Actif, A renouveler, Expire, Resilie
- Generation du contrat depuis un template Word/DocX (docx template engine)

### 3.9 Gestion des associes et gerants
- Table `Associes` liee a un dossier :
  - Nom, prenom, CIN, date naissance, nationalite
  - Type : Associe, Gerant, Associe-Gerant
  - Parts sociales : nombre, valeur, % detenu
  - Adresse, email, telephone
- Historique des modifications de gerance

### 3.10 Validation ICE, RC, IF (format Maroc)
- **ICE** (Identifiant Commun Entreprise) : 15 chiffres, validation check-digit LN (Luhn modifie)
- **RC** (Registre de Commerce) : format `XXX-XXXXXX` ou libre selon ville
- **IF** (Identifiant Fiscal) : 7 chiffres
- **CNSS** : format `XX-XXXXXXX`
- **CIN** : format `XX-XXXXXX` (2 lettres + 6 chiffres)
- Validation visuelle (icone vert/rouge) + tooltip erreur
- Auto-formatage lors de la saisie

### 3.11 Generation PDF
- **Fiche client** : recapitulatif complet du dossier avec ID, type, collaborateur, societe
- **Attestation de domiciliation** : document officiel avec :
  - En-tete du centre d'affaires (logo, coordonnees)
  - Nom du client, siege social
  - Date de domiciliation
  - Cachet et signature (image)
  - Cadre juridique (articles de loi)
- **Contrat de domiciliation** : genere depuis template avec variables
- **Quittance/Renouvellement** : facture de domiciliation
- Bibliotheque : QuestPDF ou iTextSharp (open source)

### 3.12 OCR et extraction automatique de donnees
- Technologie : Tesseract OCR + Windows.Media.Ocr
- Documents supportes :
  - **CIN** (Carte d'Identite Nationale) : numero, nom, prenom, date naissance, photo
  - **RC** (Registre de Commerce) : numero RC, siege social, objet social, gerant
  - **ICE** (attestation) : numero ICE, raison sociale, adresse
  - **IF** (attestation fiscale) : numero IF
  - **CNSS** (attestation) : numero CNSS, code a activite
- Pipeline : Scan → Preprocessing (deskew, denoise, binarize) → OCR → Regex extraction → Auto-remplissage formulaire
- Mode batch : glisser-deposer plusieurs documents

### 3.13 Synchronisation cloud
- **SharePoint / OneDrive** via Microsoft Graph API :
  - Publication automatique de l'arborescence apres creation
  - Synchronisation des mises a jour (upload de documents)
  - Permission : dossier partage avec le client et le compta
  - Configuration OAuth2 avec Azure AD
- **Google Drive** via Google Drive API v3 :
  - Backup automatique
  - Export des rapports vers Drive
- Statut de synchro visible dans l'interface (icone cloud)

### 3.14 Dashboard et statistiques
- Page d'accueil apres connexion avec :
  - Nb total dossiers, creation aujourd'hui/ce mois/annee
  - Repartition par type collaborateur (camembert)
  - Evolution mensuelle (histogramme)
  - Contrats arrivant a expiration (datagrid)
  - Derniers dossiers crees (liste)
- Export des graphiques en PNG/PDF
- Technologie : LiveCharts2 (WPF) ou OxyPlot

### 3.15 Notifications et alertes
- **Notifications systeme** :
  - Expiration contrats (30j/15j/7j/1j avant)
  - Documents manquants (CIN, RC, ICE non fournis)
  - Echeance CNSS/AMO a declarer
  - Renouvellement annuel a effectuer
- **Email automatique** :
  - Confirmation de creation au gerant et au compta
  - Relance pour documents manquants
  - Alerte expiration avec modele d'email
  - Utilisation : SendGrid API / SMTP configurable

### 3.16 Gestion electronique de documents (GED)
- Visualisation de l'arborescence du dossier directement dans l'application
- Apercu des documents (PDF, images) dans un panel integre
- Tags et mots-cles par document
- Recherche full-text dans les documents (indexation PDF/OCR)
- Classification automatique par type de document (CIN, RC, ICE, Contrat, Facture...)
- Versionning des documents (historique des modifications)
- Corbeille avec restauration possible

### 3.17 Export Excel avance
- Registre complet des dossiers avec tous les champs
- Rapport par collaborateur (liste de ses dossiers)
- Rapport financier (encaissements, echeances)
- Rapport fiscal (TVA, IS) par mois/trimestre/annee
- Templates Excel personnalisables
- Technologie : ClosedXML (open source, pas de license)

### 3.18 Modules comptables integres
- **Tableau de bord TVA** : declaration mensuelle/trimestrielle
- **Suivi CNSS** : declarations, cotisations, attestations
- **Calcul IS** : estimation annuelle avec simulation
- **Retard / Penalites** : calcul automatique
- Export vers logiciel comptable (journal CSV/EDIFACT)

### 3.19 Signature electronique
- Integration avec service de signature (Yousign, Universign, DocuSign)
- OU signature locale avec certificat electronique Marocain
- Documents signables : contrat, attestation, avenant
- Horodatage certifie
- Historique des signatures (date, IP, certificat)

### 3.20 Multilingue
- Support complet : Francais, Arabe, Anglais
- Detection automatique de la langue du systeme
- Bascule en temps reel sans redemarrage
- Fichiers .resx ou JSON de traduction
- Interface RTL automatique pour l'arabe
- Dates, nombres et formats adaptes a chaque locale

### 3.21 Taches planifiees (Scheduler)
- Service Windows / Tache planifiee :
  - Backup automatique de la base SQLite
  - Nettoyage des logs > 90 jours
  - Envoi des notifications email
  - Synchronisation cloud
  - Generation des rapports periodiques
  - Archivage des dossiers anciens (> 5 ans)
- Configuration via l'interface utilisateur
- Log des executions

### 3.22 Mode hors-ligne et synchronisation
- Fonctionnement complet sans connexion Internet
- File d'attente pour les operations cloud
- Synchronisation automatique quand la connexion revient
- Conflit : resolution automatique (timestamp latest wins)
- Indicateur de statut connexion dans la barre d'etat

### 3.23 API REST
- API HTTP pour integration avec d'autres systemes :
  - `GET /api/dossiers` : liste des dossiers avec filtres
  - `GET /api/dossiers/{id}` : detail d'un dossier
  - `POST /api/dossiers` : creation d'un dossier
  - `GET /api/contrats` : liste des contrats
  - `POST /api/contrats/generate` : generer un contrat PDF
  - `GET /api/stats` : statistiques
  - `GET /api/search?q=...` : recherche full-text
- Authentification : API Key ou JWT
- Swagger / OpenAPI documentation
- Rate limiting, pagination, filtres

### 3.24 Gestion des utilisateurs et roles
- Types de comptes :
  - **Admin** : tous les droits, configuration
  - **Gerant** : creer/consulter ses dossiers
  - **Comptable** : consulter tous les dossiers, export
  - **Collaborateur** : consulter ses dossiers assignes
  - **Client** : portail de consultation (vue web)
- Authentification : Windows Auth (SSO), ou login/mot de passe
- Journal des actions (qui a fait quoi, quand)
- Permissions fines par module

### 3.25 Configuration et parametrage
- Interface de configuration complete :
  - Types de collaborateurs (ajout/suppression)
  - Prefixes ID personnalisables
  - Templates de sous-dossiers par type
  - Seuils d'alerte (delais, montants)
  - Couleurs du theme (personnalisation)
  - Signature email (texte, logo)
- Stockage : fichier `config.json` dans `%APPDATA%\CENTIRIO\`
- Export/Import de la configuration
- Multi-profils de configuration

---

## 8. Architecture detaillee (version complete)

### 8.1 Structure des fichiers etendue

```
CENTIRIO.CreationDossier/
├── CENTIRIO.CreationDossier.sln
├── src/
│   └── CENTIRIO.CreationDossier/
│       ├── CENTIRIO.CreationDossier.csproj
│       ├── Program.cs
│       ├── App.xaml / App.xaml.cs
│       ├── MainWindow.xaml / MainWindow.xaml.cs
│       ├── Models/
│       │   ├── CollaboratorType.cs
│       │   ├── DossierInfo.cs
│       │   ├── Contrat.cs
│       │   ├── Associe.cs
│       │   ├── Document.cs
│       │   ├── Notification.cs
│       │   ├── User.cs / UserRole.cs
│       │   ├── AuditLog.cs
│       │   └── AppConfig.cs
│       ├── ViewModels/
│       │   ├── MainViewModel.cs
│       │   ├── SearchViewModel.cs
│       │   ├── DashboardViewModel.cs
│       │   ├── ContratViewModel.cs
│       │   ├── AssocieViewModel.cs
│       │   ├── ConfigViewModel.cs
│       │   └── StatsViewModel.cs
│       ├── Views/
│       │   ├── MainWindow.xaml
│       │   ├── SearchWindow.xaml
│       │   ├── DashboardWindow.xaml
│       │   ├── ContratWindow.xaml
│       │   ├── AssocieWindow.xaml
│       │   ├── ConfigWindow.xaml
│       │   └── StatsWindow.xaml
│       ├── Services/
│       │   ├── IDossierService.cs / DossierService.cs
│       │   ├── IContratService.cs / ContratService.cs
│       │   ├── IAssocieService.cs / AssocieService.cs
│       │   ├── IIdService.cs / IdService.cs
│       │   ├── ILoggingService.cs / LoggingService.cs
│       │   ├── IPdfService.cs / PdfService.cs
│       │   ├── IExcelService.cs / ExcelService.cs
│       │   ├── IOcrService.cs / OcrService.cs
│       │   ├── ICloudSyncService.cs / CloudSyncService.cs
│       │   ├── INotificationService.cs / NotificationService.cs
│       │   ├── IEmailService.cs / EmailService.cs
│       │   ├── IAuthService.cs / AuthService.cs
│       │   ├── ISchedulerService.cs / SchedulerService.cs
│       │   ├── IValidationService.cs / ValidationService.cs
│       │   └── ISearchService.cs / SearchService.cs
│       ├── Data/
│       │   ├── AppDbContext.cs
│       │   ├── Migrations/
│       │   └── SeedData.cs
│       ├── Converters/
│       │   ├── BoolToVisibilityConverter.cs
│       │   ├── StatusToColorConverter.cs
│       │   ├── DateToRelativeConverter.cs
│       │   └── FileSizeConverter.cs
│       ├── Styles/
│       │   ├── DarkTheme.xaml
│       │   ├── LightTheme.xaml
│       │   └── Shared.xaml
│       ├── Localization/
│       │   ├── Resources.fr.resx
│       │   ├── Resources.ar.resx
│       │   └── Resources.en.resx
│       └── Helpers/
│           ├── SafeNameHelper.cs
│           ├── MoroccanIdValidator.cs
│           ├── StringExtensions.cs
│           └── EncryptionHelper.cs
├── tests/
│   └── CENTIRIO.CreationDossier.Tests/
│       ├── Services/
│       ├── Validators/
│       └── Helpers/
├── docs/
│   └── SPECS.md
├── scripts/
│   ├── build.ps1
│   ├── deploy.ps1
│   └── backup.ps1
├── installer/
│   ├── setup.iss (Inno Setup)
│   └── centirio.ico
└── config/
    ├── default.config.json
    └── logo.png
```

### 8.2 Schema de la base de donnees (complete)

```sql
-- Table centrale des dossiers
CREATE TABLE Dossiers (
    Id              INTEGER PRIMARY KEY AUTOINCREMENT,
    DossierId       TEXT NOT NULL,
    FolderName      TEXT NOT NULL,
    FullPath        TEXT NOT NULL,
    CollaboratorCode TEXT NOT NULL,
    CollaboratorName TEXT NOT NULL,
    CompanyName     TEXT NOT NULL,
    Ice             TEXT,
    Rc              TEXT,
    IfFiscal        TEXT,
    Cnss            TEXT,
    SiegeSocial     TEXT,
    ObjetSocial     TEXT,
    Capital         REAL,
    CreatedAt       DATETIME NOT NULL DEFAULT (datetime('now')),
    UpdatedAt       DATETIME,
    CreatedBy       TEXT NOT NULL,
    Status          TEXT NOT NULL DEFAULT 'actif',  -- actif, archive, resilie
    Notes           TEXT
);

-- Contrats lies a un dossier
CREATE TABLE Contrats (
    Id              INTEGER PRIMARY KEY AUTOINCREMENT,
    DossierId       INTEGER NOT NULL REFERENCES Dossiers(Id),
    Type            TEXT NOT NULL,  -- domiciliation, siege, avenant
    Reference       TEXT NOT NULL,
    DateSignature   DATETIME,
    DateDebut       DATETIME NOT NULL,
    DateFin         DATETIME NOT NULL,
    DateRenouvellement DATETIME,
    Montant         REAL,
    Frequence       TEXT DEFAULT 'annuel',  -- mensuel, trimestriel, annuel
    Statut          TEXT NOT NULL DEFAULT 'actif',  -- actif, a_renouveler, expiré, resilie
    Contenu         TEXT,          -- Texte integral ou reference template
    FichierPdf      TEXT,          -- Chemin vers le PDF signe
    CreatedAt       DATETIME DEFAULT (datetime('now'))
);

-- Associes et gerants
CREATE TABLE Associes (
    Id              INTEGER PRIMARY KEY AUTOINCREMENT,
    DossierId       INTEGER NOT NULL REFERENCES Dossiers(Id),
    Nom             TEXT NOT NULL,
    Prenom          TEXT NOT NULL,
    Cin             TEXT,
    DateNaissance   DATETIME,
    Nationalite     TEXT DEFAULT 'Marocaine',
    Type            TEXT NOT NULL,  -- associe, gerant, associe_gerant
    PartsSociales   INTEGER DEFAULT 0,
    Pourcentage     REAL DEFAULT 0,
    Adresse         TEXT,
    Email           TEXT,
    Telephone       TEXT,
    Fonction        TEXT,
    DateNomination  DATETIME,
    CreatedAt       DATETIME DEFAULT (datetime('now'))
);

-- Documents electroniques
CREATE TABLE Documents (
    Id              INTEGER PRIMARY KEY AUTOINCREMENT,
    DossierId       INTEGER NOT NULL REFERENCES Dossiers(Id),
    FileName        TEXT NOT NULL,
    OriginalName    TEXT NOT NULL,
    FilePath        TEXT NOT NULL,
    FileSize        INTEGER,
    MimeType        TEXT,
    TypeDocument    TEXT,  -- CIN, RC, ICE, IF, CNSS, Contrat, Facture, Autre
    Tags            TEXT,  -- JSON array
    OcrText         TEXT,  -- Texte extrait par OCR
    Version         INTEGER DEFAULT 1,
    CreatedAt       DATETIME DEFAULT (datetime('now')),
    CreatedBy       TEXT
);

-- Notifications
CREATE TABLE Notifications (
    Id              INTEGER PRIMARY KEY AUTOINCREMENT,
    DossierId       INTEGER REFERENCES Dossiers(Id),
    Type            TEXT NOT NULL,  -- expiration, document, renouvellement, systeme
    Titre           TEXT NOT NULL,
    Message         TEXT,
    Priorite        TEXT DEFAULT 'normal',  -- basse, normal, haute, critique
    EstLue          INTEGER DEFAULT 0,
    DateEnvoi       DATETIME,
    DateLecture     DATETIME,
    CreatedAt       DATETIME DEFAULT (datetime('now'))
);

-- Journal d'audit
CREATE TABLE AuditLogs (
    Id              INTEGER PRIMARY KEY AUTOINCREMENT,
    Action          TEXT NOT NULL,  -- create, update, delete, login, export, sync
    EntityType      TEXT,            -- Dossier, Contrat, Associe, Document
    EntityId        INTEGER,
    Details         TEXT,            -- JSON avec avant/apres
    UserName        TEXT NOT NULL,
    MachineName     TEXT,
    IpAddress       TEXT,
    CreatedAt       DATETIME DEFAULT (datetime('now'))
);

-- Utilisateurs
CREATE TABLE Users (
    Id              INTEGER PRIMARY KEY AUTOINCREMENT,
    Username        TEXT NOT NULL UNIQUE,
    PasswordHash    TEXT,            -- NULL si Windows Auth
    Email           TEXT,
    Role            TEXT NOT NULL DEFAULT 'collaborateur',  -- admin, gerant, comptable, collaborateur, client
    DisplayName     TEXT,
    IsActive        INTEGER DEFAULT 1,
    LastLogin       DATETIME,
    CreatedAt       DATETIME DEFAULT (datetime('now'))
);

-- Configuration synchronisation cloud
CREATE TABLE CloudSync (
    Id              INTEGER PRIMARY KEY AUTOINCREMENT,
    Provider        TEXT NOT NULL,  -- sharepoint, onedrive, googledrive
    AccessToken     TEXT,
    RefreshToken    TEXT,
    TokenExpiry     DATETIME,
    RootFolderId    TEXT,
    IsActive        INTEGER DEFAULT 0,
    LastSyncAt      DATETIME,
    SyncInterval    INTEGER DEFAULT 60  -- minutes
);
```

### 8.3 Diagramme de navigation complet

```
┌─────────────────────────────────────────────────────────────┐
│  Page de connexion (Windows Auth ou login)                   │
│  [Utilisateur: ________] [Mot de passe: ____] [Connexion]    │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  DASHBOARD (accueil)                                         │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                            │
│  │ 150 │ │ 12  │ │ 3   │ │ 8   │   ← KPI cards              │
│  │Total│ │Mois │ │Exp. │ │Nouv.│                            │
│  └─────┘ └─────┘ └─────┘ └─────┘                            │
│  [Graphique evolution]  [Repartition types]                   │
│  [Derniers dossiers]    [Contrats a expirer]                  │
│                                                               │
│  [Nouveau dossier] [Rechercher] [Rapports] [Configuration]    │
└───────────────────────┬─────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┬──────────────────┐
        ▼               ▼               ▼                  ▼
┌──────────────┐ ┌──────────────┐ ┌──────────┐   ┌──────────────┐
│ Creation      │ │ Recherche    │ │ Rapports │   │ Configuration│
│ dossier       │ │ dossiers     │ │ Excel    │   │              │
│ (formulaire)  │ │ DataGrid     │ │ PDF      │   │ Types/prefixes│
│              │ │ Filtres      │ │ Stats    │   │ Themes/Cloud │
│ [Creer]       │ │ [Ouvrir]     │ │          │   │ Utilisateurs │
│ [Nouveau]     │ │ [Export]     │ └──────────┘   │ Sauvegarde   │
└──────────────┘ └──────────────┘               └──────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  Detail dossier (fenetre onglets)                            │
│  [Infos] [Contrats] [Associes] [Documents] [Historique]     │
│                                                               │
│  - ID, Type, Collaborateur, Societe                          │
│  - ICE, RC, IF, CNSS                                         │
│  - Statut, Date creation                                     │
│  - Boutons : [Modifier] [Contrat] [Associe] [Documents]      │
│             [PDF Fiche] [Ouvrir dossier] [Sync Cloud]        │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. Regles de code

- **Toujours** `try/catch` avec rollback sur creation
- **Toujours** logging avant/action apres
- **Toujours**验证 `async/await` pour operations I/O
- **Toujours** interfaces pour les services (testabilite)
- **Namespace** : `CENTIRIO.CreationDossier.*`
- **Langue** : commentaires et identifiants en anglais (code), interface utilisateur en francais
- **Nullable enable** : activer `<Nullable>enable</Nullable>`

---

## 9. Tests unitaires

Framework : xUnit + Moq

Tests a couvrir :
- `IdService_TryParse_ValidPrefix_ReturnsTrue`
- `IdService_BuildId_ZeroPadding_4Digits`
- `IdService_BuildId_ClampAt1000`
- `SafeNameHelper_StripInvalidChars`
- `SafeNameHelper_ReplaceSpacesWithDash`
- `DossierService_TestIdExists_DirectoryMatch`
- `DossierService_CreateDossier_RollbackOnFail`

---

## 10. Roadmap

| Version | Features |
|---------|----------|
| **v1.0** | Creation dossier + sous-dossiers + log fichier + SQLite + auto-num + recherche |
| **v1.1** | Export Excel (ClosedXML) + theme clair/sombre + validation ICE/RC/IF |
| **v1.2** | Generation PDF (QuestPDF) + contrats + associes + gestion echeances |
| **v1.5** | Dashboard + stats + graphiques (LiveCharts2) + notifications |
| **v2.0** | OCR (Tesseract) + extraction auto CIN/RC/ICE + classement documents |
| **v2.1** | Synchronisation SharePoint/OneDrive (Microsoft Graph) + Google Drive |
| **v2.5** | GED complete + recherche full-text + versionning documents |
| **v3.0** | API REST + authentification + multi-utilisateurs + roles |
| **v3.5** | Signature electronique + modules comptables (TVA/IS/CNSS) |
| **v4.0** | Multilingue FR/AR/EN + taches planifiees + mode hors-ligne + portail web client |
