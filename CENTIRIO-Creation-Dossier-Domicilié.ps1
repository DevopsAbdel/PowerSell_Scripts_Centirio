<#
    CENTIRIO - Création de dossier client avec WPF (Mode Sombre & UI avec emojis)
    - ComboBox "Type de Collaborateur" 100% sombre (template personnalisé)
    - Préfixe d'ID libre (ComboBox éditable) + suffixe numérique (0–1000)
    - ID final auto : p.ex. DOM-0008, FIXE-0100, ABC-1000 (champ lecture seule)
    - Regex corrigée (utilise [regex]::Escape)
    - Message final avec emojis + proposition d’ouvrir le dossier
#>

Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase
Add-Type -AssemblyName System.Windows.Forms

#region Helpers
function Show-Info([string]$msg, [string]$title = "Information") {
    [System.Windows.MessageBox]::Show($msg, $title, 'OK', 'Information') | Out-Null
}
function Show-Warn([string]$msg, [string]$title = "Attention") {
    [System.Windows.MessageBox]::Show($msg, $title, 'OK', 'Warning') | Out-Null
}
function Show-Error([string]$msg, [string]$title = "Erreur") {
    [System.Windows.MessageBox]::Show($msg, $title, 'OK', 'Error') | Out-Null
}

function Get-SafeName([string]$name) {
    if ([string]::IsNullOrWhiteSpace($name)) { return "" }
    $invalid = [IO.Path]::GetInvalidFileNameChars()
    $sb = New-Object System.Text.StringBuilder($name.Trim())
    foreach ($c in $invalid) { $null = $sb.Replace($c, '-') }
    ($sb.ToString() -replace '\s{2,}',' ' -replace '[-]{2,}','-').Trim()
}

# FIX: éviter \Q ... \E -> on échappe via [regex]::Escape
function Test-IdExists([string]$root, [string]$id) {
    if (-not (Test-Path -LiteralPath $root)) { return $false }
    $escaped = [regex]::Escape($id)
    $pattern = '^' + $escaped + '\s-'
    Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $pattern } |
        Select-Object -First 1 |
        ForEach-Object { $true } |
        ForEach-Object { $_ }
}

function Ensure-Subfolders([string]$base) {
    $subs = @(
        "01_Docs_Recus",
        "02_Docs_Envoyes",
        "03_Docs_Comptable",
        "04_Autres_Docs"
    )
    foreach ($s in $subs) {
        $p = Join-Path $base $s
        if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
    }
}
#endregion Helpers

#region XAML (Dark Mode complet + templates & emojis)
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="🗂️ CENTIRIO — Création de dossier client"
        Height="600" Width="860"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#1E1E1E" Foreground="#F0F0F0" FontFamily="Segoe UI" FontSize="14">

    <Window.Resources>
        <!-- Palette sombre -->
        <SolidColorBrush x:Key="BgDark" Color="#1E1E1E"/>
        <SolidColorBrush x:Key="PanelDark" Color="#252526"/>
        <SolidColorBrush x:Key="PanelDarker" Color="#2D2D30"/>
        <SolidColorBrush x:Key="AccentBlue" Color="#2078F4"/>
        <SolidColorBrush x:Key="AccentGreen" Color="#2EA043"/>
        <SolidColorBrush x:Key="AccentRed" Color="#D64545"/>
        <SolidColorBrush x:Key="AccentGray" Color="#5C5C5C"/>
        <SolidColorBrush x:Key="AccentGrayHover" Color="#707070"/>
        <SolidColorBrush x:Key="TxtLight" Color="#F0F0F0"/>
        <SolidColorBrush x:Key="TxtMuted" Color="#C0C0C0"/>
        <SolidColorBrush x:Key="SelBg" Color="#3A86FF"/>
        <SolidColorBrush x:Key="SelFg" Color="#FFFFFF"/>

        <!-- Overrides SystemColors pour popup, etc. -->
        <SolidColorBrush x:Key="{x:Static SystemColors.WindowBrushKey}" Color="#2D2D30"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.WindowTextBrushKey}" Color="#F0F0F0"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.ControlBrushKey}" Color="#2D2D30"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.ControlTextBrushKey}" Color="#F0F0F0"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="#3A86FF"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.HighlightTextBrushKey}" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.InactiveSelectionHighlightBrushKey}" Color="#324B81"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.GrayTextBrushKey}" Color="#B0B0B0"/>

        <!-- Labels -->
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="{StaticResource TxtLight}"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="Margin" Value="0,0,0,6"/>
        </Style>

        <!-- TextBox -->
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="{StaticResource PanelDarker}"/>
            <Setter Property="Foreground" Value="{StaticResource TxtLight}"/>
            <Setter Property="BorderBrush" Value="#3A3A3A"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="CaretBrush" Value="{StaticResource TxtLight}"/>
        </Style>

        <!-- ComboBox sombre (template personnalisé) -->
        <Style TargetType="ComboBox">
            <Setter Property="Foreground" Value="{StaticResource TxtLight}"/>
            <Setter Property="Background" Value="{StaticResource PanelDarker}"/>
            <Setter Property="BorderBrush" Value="#3A3A3A"/>
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton Name="ToggleButton"
                                          Grid.ZIndex="2"
                                          Background="{TemplateBinding Background}"
                                          BorderBrush="{TemplateBinding BorderBrush}"
                                          BorderThickness="1"
                                          Focusable="False"
                                          IsChecked="{Binding Path=IsDropDownOpen, RelativeSource={RelativeSource TemplatedParent}, Mode=TwoWay}">
                                <Grid>
                                    <ContentPresenter Margin="6,2,28,2"
                                                      Content="{TemplateBinding SelectionBoxItem}"
                                                      ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                                      ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}"
                                                      HorizontalAlignment="Left" VerticalAlignment="Center"
                                                      RecognizesAccessKey="True"/>
                                    <!-- Flèche -->
                                    <Path HorizontalAlignment="Right" Margin="0,0,10,0" VerticalAlignment="Center"
                                          Data="M 0 0 L 4 4 L 8 0 Z"
                                          Fill="{StaticResource TxtLight}" />
                                </Grid>
                            </ToggleButton>

                            <!-- Liste déroulante -->
                            <Popup Name="Popup"
                                   Placement="Bottom"
                                   IsOpen="{TemplateBinding IsDropDownOpen}"
                                   AllowsTransparency="True"
                                   Focusable="False"
                                   PopupAnimation="Slide">
                                <Border Background="{StaticResource PanelDarker}"
                                        BorderBrush="#3A3A3A" BorderThickness="1" CornerRadius="2">
                                    <ScrollViewer SnapsToDevicePixels="True">
                                        <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained"/>
                                    </ScrollViewer>
                                </Border>
                            </Popup>

                            <!-- Bordure -->
                            <Border x:Name="Border" Background="{TemplateBinding Background}"
                                    BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Border" Property="Opacity" Value="0.6"/>
                            </Trigger>
                            <Trigger SourceName="ToggleButton" Property="IsMouseOver" Value="True">
                                <Setter TargetName="Border" Property="BorderBrush" Value="#4A4A4A"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Items de ComboBox -->
        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="{StaticResource PanelDarker}"/>
            <Setter Property="Foreground" Value="{StaticResource TxtLight}"/>
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#3A3A3A"/>
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="{StaticResource SelBg}"/>
                    <Setter Property="Foreground" Value="{StaticResource SelFg}"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Boutons -->
        <Style x:Key="BaseButton" TargetType="Button">
            <Setter Property="Foreground" Value="{StaticResource TxtLight}"/>
            <Setter Property="Background" Value="{StaticResource AccentGray}"/>
            <Setter Property="BorderBrush" Value="#3A3A3A"/>
            <Setter Property="Padding" Value="12,8"/>
            <Setter Property="Margin" Value="6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="ToolTipService.ShowOnDisabled" Value="True"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="{StaticResource AccentGrayHover}"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style x:Key="GreenButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="{StaticResource AccentGreen}"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#35B34F"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style x:Key="BlueButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="{StaticResource AccentBlue}"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#3E8CFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style x:Key="RedButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="{StaticResource AccentRed}"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#E05555"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style x:Key="GrayButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="{StaticResource AccentGray}"/>
        </Style>
    </Window.Resources>

    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- En-tête -->
        <Border Grid.Row="0" Background="{StaticResource PanelDark}" Padding="14" CornerRadius="6" Margin="0,0,0,12">
            <DockPanel>
                <TextBlock Text="🗂️ Création de dossier client — CENTIRIO" FontSize="18" FontWeight="SemiBold" />
            </DockPanel>
        </Border>

        <!-- Formulaire -->
        <Border Grid.Row="1" Background="{StaticResource PanelDark}" Padding="16" CornerRadius="6">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>  <!-- Préfixe ID -->
                    <RowDefinition Height="Auto"/>  <!-- Numérique -->
                    <RowDefinition Height="Auto"/>  <!-- Aperçu ID -->
                    <RowDefinition Height="Auto"/>  <!-- Type collaborateur -->
                    <RowDefinition Height="Auto"/>  <!-- Nom collab -->
                    <RowDefinition Height="Auto"/>  <!-- Société -->
                    <RowDefinition Height="Auto"/>  <!-- Racine -->
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="260"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <!-- Préfixe ID (éditable) -->
                <TextBlock Grid.Row="0" Grid.Column="0" Text="🆔 Préfixe de l'ID (modif. possible)" Margin="0,0,12,4"/>
                <ComboBox  x:Name="CmbIdPrefix" Grid.Row="0" Grid.Column="1" Margin="0,0,12,8" IsEditable="True" ToolTip="✏️ Tapez votre propre préfixe si besoin (ex: ABC-).">
                    <ComboBoxItem Content="DOM-"  Tag="DOM-"/>
                    <ComboBoxItem Content="FIXE-" Tag="FIXE-"/>
                    <ComboBoxItem Content="PRJ-"  Tag="PRJ-"/>
                </ComboBox>

                <!-- Numérique (0–1000) -->
                <TextBlock Grid.Row="1" Grid.Column="0" Text="🔢 Numéro (0–1000)" Margin="0,0,12,4"/>
                <TextBox   x:Name="TxtIdNumber" Grid.Row="1" Grid.Column="1" Margin="0,0,12,8" MaxLength="4" ToolTip="Entrez un nombre entre 0 et 1000." />

                <!-- Aperçu ID (lecture seule) -->
                <TextBlock Grid.Row="2" Grid.Column="0" Text="🪪 ID Dossier (aperçu)" Margin="0,0,12,4"/>
                <TextBox   x:Name="TxtId" Grid.Row="2" Grid.Column="1" Margin="0,0,12,8" IsReadOnly="True" ToolTip="Construit automatiquement à partir du préfixe et du numéro (zéro‑padding)." />

                <!-- Type collaborateur -->
                <TextBlock Grid.Row="3" Grid.Column="0" Text="👥 Type de Collaborateur" Margin="0,0,12,4"/>
                <ComboBox  x:Name="CmbType" Grid.Row="3" Grid.Column="1" Margin="0,0,12,8" ToolTip="Choisissez le code du collaborateur.">
                    <ComboBoxItem Content="🧮 EXP-CPT — Expert Comptable" Tag="EXP-CPT"/>
                    <ComboBoxItem Content="🧾 CPT-AGR — Comptable Agréé"   Tag="CPT-AGR"/>
                    <ComboBoxItem Content="🧾 CPT-IND — Comptable Indépendant" Tag="CPT-IND"/>
                    <ComboBoxItem Content="🚚 COU-AGR — Coursier Comptable Agréé" Tag="COU-AGR"/>
                    <ComboBoxItem Content="🚚 COU-IND — Coursier Indépendant" Tag="COU-IND"/>
                    <ComboBoxItem Content="🚚 COU-EXP — Coursier Expert Comptable" Tag="COU-EXP"/>
                    <ComboBoxItem Content="👤 CLT-DIR — Client Direct"      Tag="CLT-DIR"/>
                </ComboBox>

                <!-- Nom Collaborateur -->
                <TextBlock Grid.Row="4" Grid.Column="0" Text="👤 Nom du Collaborateur" Margin="0,0,12,4"/>
                <TextBox   x:Name="TxtCollab" Grid.Row="4" Grid.Column="1" Margin="0,0,12,8" />

                <!-- Société -->
                <TextBlock Grid.Row="5" Grid.Column="0" Text="🏢 Nom de la Société du client" Margin="0,0,12,4"/>
                <TextBox   x:Name="TxtSociete" Grid.Row="5" Grid.Column="1" Margin="0,0,12,8" />

                <!-- Emplacement racine -->
                <TextBlock Grid.Row="6" Grid.Column="0" Text="📍 Emplacement racine" Margin="0,0,12,4"/>
                <TextBox   x:Name="TxtRacine" Grid.Row="6" Grid.Column="1" Margin="0,0,12,8" IsReadOnly="True"/>
                <Button    x:Name="BtnBrowse" Grid.Row="6" Grid.Column="2" Content="📂 Parcourir…" Style="{StaticResource GrayButton}" ToolTip="Sélectionnez l'emplacement de création." />
            </Grid>
        </Border>

        <!-- Boutons -->
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
            <Button x:Name="BtnCreate" Content="✅ Créer le dossier" Style="{StaticResource GreenButton}" IsEnabled="False" ToolTip="Lancer la création du dossier et des sous‑dossiers."/>
            <Button x:Name="BtnNew"    Content="🆕 Nouveau dossier"  Style="{StaticResource BlueButton}"  ToolTip="Réinitialiser le formulaire pour une nouvelle création."/>
            <Button x:Name="BtnClose"  Content="❌ Fermer"           Style="{StaticResource RedButton}"   ToolTip="Quitter l'application."/>
        </StackPanel>
    </Grid>
</Window>
"@
#endregion XAML

# Charger la fenêtre
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Récupérer les contrôles
$CmbIdPrefix = $window.FindName("CmbIdPrefix")
$TxtIdNumber = $window.FindName("TxtIdNumber")
$TxtId       = $window.FindName("TxtId")

$CmbType    = $window.FindName("CmbType")
$TxtCollab  = $window.FindName("TxtCollab")
$TxtSociete = $window.FindName("TxtSociete")
$TxtRacine  = $window.FindName("TxtRacine")
$BtnBrowse  = $window.FindName("BtnBrowse")
$BtnCreate  = $window.FindName("BtnCreate")
$BtnNew     = $window.FindName("BtnNew")
$BtnClose   = $window.FindName("BtnClose")

# Valeurs par défaut
$TxtRacine.Text = [Environment]::GetFolderPath('MyDocuments')

# Construit l'ID (préfixe libre + numéro 0–1000, pad à 4 chiffres)
function Update-IdPreview {
    $prefix = $CmbIdPrefix.Text.Trim()
    if ($prefix -and ($prefix[-1] -ne '-')) { $prefix += '-' }     # ajoute '-' si manquant
    $numTxt = $TxtIdNumber.Text.Trim()

    $validNum = $false
    if ($numTxt -match '^\d{1,4}$') {
        [int]$n = [int]$numTxt
        if ($n -ge 0 -and $n -le 1000) { $validNum = $true }
        if ($n -gt 1000) { $n = 1000; $TxtIdNumber.Text = '1000' } # clamp
    }

    if (-not [string]::IsNullOrWhiteSpace($prefix) -and $validNum) {
        [int]$num = [int]$TxtIdNumber.Text
        $TxtId.Text = ('{0}{1}' -f $prefix, $num.ToString('0000'))
    } else {
        $TxtId.Text = ""
    }
}

# Validation dynamique
function Update-CreateButton {
    $idOk      = -not [string]::IsNullOrWhiteSpace($TxtId.Text)
    $typeOk    = $CmbType.SelectedItem -ne $null
    $collOk    = -not [string]::IsNullOrWhiteSpace($TxtCollab.Text)
    $socOk     = -not [string]::IsNullOrWhiteSpace($TxtSociete.Text)
    $rootOk    = -not [string]::IsNullOrWhiteSpace($TxtRacine.Text)
    $BtnCreate.IsEnabled = ($idOk -and $typeOk -and $collOk -and $socOk -and $rootOk)
}

# Événements (ID)
$CmbIdPrefix.Add_SelectionChanged({ Update-IdPreview; Update-CreateButton })
$CmbIdPrefix.Add_TextChanged({ Update-IdPreview; Update-CreateButton })
$TxtIdNumber.Add_TextChanged({
    # Filtre : digits uniquement, longueur max 4
    if ($TxtIdNumber.Text -notmatch '^\d{0,4}$') {
        $TxtIdNumber.Text = ($TxtIdNumber.Text -replace '[^\d]', '')
        if ($TxtIdNumber.Text.Length -gt 4) { $TxtIdNumber.Text = $TxtIdNumber.Text.Substring(0,4) }
        $TxtIdNumber.CaretIndex = $TxtIdNumber.Text.Length
    }
    Update-IdPreview
    Update-CreateButton
})

# Événements (autres champs)
$TxtCollab.Add_TextChanged({ Update-CreateButton })
$TxtSociete.Add_TextChanged({ Update-CreateButton })
$CmbType.Add_SelectionChanged({ Update-CreateButton })

# Parcourir
$BtnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.ShowNewFolderButton = $true
    if (Test-Path $TxtRacine.Text) { $dlg.SelectedPath = $TxtRacine.Text }
    $res = $dlg.ShowDialog()
    if ($res -eq [System.Windows.Forms.DialogResult]::OK) {
        $TxtRacine.Text = $dlg.SelectedPath
    }
    Update-CreateButton
})

# Nouveau dossier (reset)
$BtnNew.Add_Click({
    $CmbIdPrefix.Text = ""      # on le laisse vide pour permettre une nouvelle saisie libre
    $TxtIdNumber.Text = ""
    $TxtId.Text = ""

    $CmbType.SelectedIndex = -1
    $TxtCollab.Text = ""
    $TxtSociete.Text = ""
    Update-CreateButton
    $CmbIdPrefix.Focus()
})

# Fermer
$BtnClose.Add_Click({ $window.Close() })

# Créer le dossier
$BtnCreate.Add_Click({
    try {
        $root = $TxtRacine.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($root) -or -not (Test-Path -LiteralPath $root)) {
            Show-Warn "⚠️ Veuillez choisir un emplacement racine valide."
            return
        }

        # Champs et sécurisation
        $idRaw    = $TxtId.Text.Trim()
        $id       = Get-SafeName $idRaw
        $collRaw  = $TxtCollab.Text.Trim()
        $coll     = Get-SafeName $collRaw
        $socRaw   = $TxtSociete.Text.Trim()
        $societe  = Get-SafeName $socRaw

        if ($CmbType.SelectedItem -eq $null) {
            Show-Warn "🧭 Veuillez sélectionner un type de collaborateur."
            return
        }
        $code = ($CmbType.SelectedItem).Tag

        if ([string]::IsNullOrWhiteSpace($id) -or [string]::IsNullOrWhiteSpace($coll) -or [string]::IsNullOrWhiteSpace($societe)) {
            Show-Warn "✍️ Tous les champs sont requis."
            return
        }

        # Vérifier si l'ID existe déjà (au début du nom)
        $idExists = Test-IdExists -root $root -id $id
        if ($idExists) {
            Show-Warn "🆔 L'ID '$id' existe déjà dans cet emplacement. Choisissez un autre numéro ou préfixe."
            return
        }

        # Nom final : ID - [CODE-NOM_COLLABORATEUR] - NOM_SOCIETE
        $folderName = "{0} - [{1}-{2}] - {3}" -f $id, $code, $coll, $societe
        $target = Join-Path $root $folderName

        if (Test-Path -LiteralPath $target) {
            Show-Warn "📂 Le dossier '$folderName' existe déjà à cet emplacement."
            return
        }

        # Création
        New-Item -ItemType Directory -Path $target | Out-Null
        Ensure-Subfolders -base $target

        # Message final enrichi + proposition d’ouverture
        $msg = "🎉 Dossier créé avec succès !
        
📁 Nom : $folderName
📌 Emplacement : $target
🧩 Sous-dossiers créés : 4

➡️ Souhaitez-vous ouvrir ce dossier maintenant ?"
        $res = [System.Windows.MessageBox]::Show($msg, "Succès — CENTIRIO", 'YesNo', 'Question')
        if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
            Start-Process explorer.exe "`"$target`""
        }
    }
    catch {
        Show-Error ("❌ Échec lors de la création : {0}" -f $_.Exception.Message)
    }
})

# Afficher la fenêtre
Update-CreateButton
$null = $window.ShowDialog()