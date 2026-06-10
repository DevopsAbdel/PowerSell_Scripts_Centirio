<#
.SYNOPSIS
  Générateur de dossiers clients & fichiers Excel (WPF).
  Charge une liste de sociétés depuis Excel, copie les templates
  dans des dossiers clients nommés DOM-XXXX_RaisonSociale.
#>

# Charger les assemblies WPF
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
Add-Type -AssemblyName System.Windows.Forms

$scriptDir = Split-Path -Parent $PSCommandPath

# ─────────────────────────────────────────────────────────────
# XAML
# ─────────────────────────────────────────────────────────────
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Générateur de dossiers &amp; fichiers Excel"
        Height="720" Width="1150"
        Background="#121212"
        Foreground="#F5F5F5"
        WindowStartupLocation="CenterScreen">

    <Window.Resources>
        <SolidColorBrush x:Key="AccentBrush" Color="#4F46E5" />
        <SolidColorBrush x:Key="AccentBrushHover" Color="#6366F1" />
        <SolidColorBrush x:Key="AccentBrushPressed" Color="#3730A3" />
        <SolidColorBrush x:Key="CardBackgroundBrush" Color="#1E1E1E" />
        <SolidColorBrush x:Key="BorderBrushDark" Color="#2A2A2A" />
        <SolidColorBrush x:Key="TextMutedBrush" Color="#9CA3AF" />

        <Style TargetType="Button">
            <Setter Property="Background" Value="Transparent" />
            <Setter Property="Foreground" Value="White" />
            <Setter Property="BorderBrush" Value="{StaticResource AccentBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="Padding" Value="6,3" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="FontSize" Value="13" />
            <Setter Property="HorizontalAlignment" Value="Left" />
            <Setter Property="VerticalAlignment" Value="Center" />
            <Setter Property="SnapsToDevicePixels" Value="True" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="{StaticResource AccentBrushHover}" />
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="{StaticResource AccentBrushPressed}" />
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Foreground" Value="#555555" />
                                <Setter Property="BorderBrush" Value="#333333" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#111111" />
            <Setter Property="Foreground" Value="White" />
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushDark}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="Padding" Value="4,2" />
        </Style>

        <Style TargetType="DataGrid">
            <Setter Property="Background" Value="#111827" />
            <Setter Property="Foreground" Value="White" />
            <Setter Property="GridLinesVisibility" Value="None" />
            <Setter Property="HeadersVisibility" Value="Column" />
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushDark}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="RowBackground" Value="#020617" />
            <Setter Property="AlternatingRowBackground" Value="#030712" />
            <Setter Property="CellStyle">
                <Setter.Value>
                    <Style TargetType="DataGridCell">
                        <Setter Property="Foreground" Value="White" />
                        <Setter Property="Background" Value="Transparent" />
                        <Setter Property="BorderThickness" Value="0" />
                        <Style.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter Property="Background" Value="#1E3A5F" />
                                <Setter Property="Foreground" Value="White" />
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#162D50" />
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </Setter.Value>
            </Setter>
            <Setter Property="RowStyle">
                <Setter.Value>
                    <Style TargetType="DataGridRow">
                        <Setter Property="Background" Value="{Binding RelativeSource={RelativeSource Self}, Path=Background}" />
                        <Style.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter Property="Background" Value="#1E3A5F" />
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#111827" />
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="{x:Type DataGridColumnHeader}">
            <Setter Property="Background" Value="#111827" />
            <Setter Property="Foreground" Value="#E5E7EB" />
            <Setter Property="BorderBrush" Value="#1F2937" />
            <Setter Property="BorderThickness" Value="0,0,0,1" />
            <Setter Property="FontWeight" Value="SemiBold" />
        </Style>

        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="White" />
            <Setter Property="Margin" Value="0,0,0,2" />
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="White" />
        </Style>

        <Style TargetType="ProgressBar">
            <Setter Property="Background" Value="#1E1E1E" />
            <Setter Property="Foreground" Value="{StaticResource AccentBrush}" />
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushDark}" />
            <Setter Property="BorderThickness" Value="1" />
        </Style>

        <Style TargetType="ScrollViewer">
            <Setter Property="Background" Value="Transparent" />
        </Style>

        <Style TargetType="ScrollBar">
            <Setter Property="Background" Value="#020617" />
            <Setter Property="Foreground" Value="#4B5563" />
        </Style>
    </Window.Resources>

    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,12">
            <StackPanel>
                <TextBlock Text="Générateur de dossiers &amp; fichiers Excel"
                           FontSize="22"
                           FontWeight="Bold" />
                <TextBlock Text="Templates Excel → Dossiers &amp; fichiers par société"
                           Foreground="{StaticResource TextMutedBrush}"
                           Margin="0,4,0,0" />
            </StackPanel>
        </StackPanel>

        <Border Grid.Row="1"
                Background="{StaticResource CardBackgroundBrush}"
                CornerRadius="8"
                Padding="10"
                Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="2*" />
                    <ColumnDefinition Width="3*" />
                    <ColumnDefinition Width="2.5*" />
                </Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" Margin="0,0,10,0">
                    <TextBlock Text="Année cible (YYYY)"
                               FontWeight="SemiBold"
                               Margin="0,0,0,4" />
                    <TextBox x:Name="txtYear"
                             Width="90"
                             HorizontalAlignment="Left" />
                    <TextBlock Text="Conflits de fichiers"
                               FontWeight="SemiBold"
                               Margin="0,10,0,4" />
                    <StackPanel>
                        <RadioButton x:Name="rbOverwrite"
                                     Content="Écraser les fichiers existants"
                                     IsChecked="True"
                                     Margin="0,0,0,2" />
                        <RadioButton x:Name="rbAutoRename"
                                     Content="Renommer automatiquement les doublons" />
                    </StackPanel>
                </StackPanel>

                <StackPanel Grid.Column="1" Margin="10,0,10,0">
                    <TextBlock Text="Dossier des templates"
                               FontWeight="SemiBold"
                               Margin="0,0,0,4" />
                    <DockPanel>
                        <TextBox x:Name="txtTemplateFolder"
                                 IsReadOnly="True"
                                 Margin="0,0,8,0" />
                        <Button x:Name="btnBrowseTemplates"
                                Content="Parcourir..." />
                    </DockPanel>
                    <Button x:Name="btnReloadTemplates"
                            Content="Recharger les templates"
                            Margin="0,6,0,0"
                            Width="180" />
                </StackPanel>

                <StackPanel Grid.Column="2" Margin="10,0,0,0">
                    <TextBlock Text="Dossier de destination"
                               FontWeight="SemiBold"
                               Margin="0,0,0,4" />
                    <DockPanel>
                        <TextBox x:Name="txtDestinationFolder"
                                 IsReadOnly="True"
                                 Margin="0,0,8,0" />
                        <Button x:Name="btnBrowseDestination"
                                Content="Parcourir..." />
                    </DockPanel>
                    <Button x:Name="btnGenerateGuide"
                            Content="Générer le guide HTML"
                            Margin="0,6,0,0"
                            Width="200" />
                </StackPanel>
            </Grid>
        </Border>

        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="3*" />
                <ColumnDefinition Width="2*" />
            </Grid.ColumnDefinitions>

            <Border Grid.Column="0"
                    Background="{StaticResource CardBackgroundBrush}"
                    CornerRadius="8"
                    Margin="0,0,8,0"
                    Padding="8">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Orientation="Horizontal">
                        <TextBlock Text="Sociétés (Excel)"
                                   FontSize="14"
                                   FontWeight="SemiBold" />
                        <Button x:Name="btnLoadCompanies"
                                Content="Charger depuis Excel"
                                Margin="8,0,0,0" />
                        <Button x:Name="btnSelectAllCompanies"
                                Content="Tout sélectionner"
                                Margin="8,0,0,0" />
                        <Button x:Name="btnUnselectAllCompanies"
                                Content="Tout désélectionner"
                                Margin="8,0,0,0" />
                    </StackPanel>

                    <DataGrid x:Name="dgCompanies"
                              Grid.Row="1"
                              Margin="0,6,0,0"
                              AutoGenerateColumns="False"
                              CanUserAddRows="False"
                              SelectionMode="Extended">
                        <DataGrid.Columns>
                            <DataGridCheckBoxColumn Binding="{Binding IsSelected}"
                                                    Header="✔"
                                                    Width="40" />
                            <DataGridTextColumn Binding="{Binding RaisonSociale}"
                                                Header="Raison sociale"
                                                Width="*" />
                        </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </Border>

            <Border Grid.Column="1"
                    Background="{StaticResource CardBackgroundBrush}"
                    CornerRadius="8"
                    Margin="8,0,0,0"
                    Padding="8">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Orientation="Horizontal">
                        <TextBlock Text="Templates"
                                   FontSize="14"
                                   FontWeight="SemiBold" />
                        <Button x:Name="btnSelectAllTemplates"
                                Content="Tout sélectionner"
                                Margin="8,0,0,0" />
                        <Button x:Name="btnUnselectAllTemplates"
                                Content="Tout désélectionner"
                                Margin="8,0,0,0" />
                    </StackPanel>

                    <DataGrid x:Name="dgTemplates"
                              Grid.Row="1"
                              Margin="0,6,0,0"
                              AutoGenerateColumns="False"
                              CanUserAddRows="False"
                              SelectionMode="Extended">
                        <DataGrid.Columns>
                            <DataGridCheckBoxColumn Binding="{Binding IsSelected}"
                                                    Header="✔"
                                                    Width="40" />
                            <DataGridTextColumn Binding="{Binding Type}"
                                                Header="Type"
                                                Width="*" />
                            <DataGridTextColumn Binding="{Binding FileName}"
                                                Header="Fichier"
                                                Width="2*" />
                        </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </Border>
        </Grid>

        <Border Grid.Row="3"
                Background="{StaticResource CardBackgroundBrush}"
                CornerRadius="8"
                Margin="0,12,0,8"
                Padding="8">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="*" />
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Orientation="Horizontal">
                    <TextBlock Text="Logs"
                               FontSize="14"
                               FontWeight="SemiBold" />
                    <Button x:Name="btnClearLogs"
                            Content="Effacer"
                            Margin="8,0,0,0" />
                </StackPanel>

                <ScrollViewer Grid.Row="1"
                              VerticalScrollBarVisibility="Auto"
                              MaxHeight="80">
                    <TextBox x:Name="txtLogs"
                             Background="#111111"
                             BorderThickness="0"
                             IsReadOnly="True"
                             AcceptsReturn="True"
                             TextWrapping="Wrap" />
                </ScrollViewer>
            </Grid>
        </Border>

        <Grid Grid.Row="4">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="3*" />
                <ColumnDefinition Width="Auto" />
            </Grid.ColumnDefinitions>

            <StackPanel Grid.Column="0">
                <TextBlock Text="Progression"
                           Margin="0,0,0,4" />
                <ProgressBar x:Name="pbProgress"
                             Height="16"
                             Minimum="0"
                             Maximum="100" />
            </StackPanel>

            <StackPanel Grid.Column="1"
                        Orientation="Horizontal"
                        HorizontalAlignment="Right">
                <Button x:Name="btnGenerate"
                        Content="Générer"
                        Margin="8,0,0,0"
                        Width="140" />
                <Button x:Name="btnClose"
                        Content="Fermer"
                        Margin="8,0,0,0"
                        Width="100" />
            </StackPanel>
        </Grid>
    </Grid>
</Window>
"@

# ─────────────────────────────────────────────────────────────
# Classes modèles
# ─────────────────────────────────────────────────────────────
Add-Type @"
using System;
using System.ComponentModel;
using System.Collections.ObjectModel;
public class SocieteViewModel : INotifyPropertyChanged {
    private bool _isSelected;
    public bool IsSelected {
        get { return _isSelected; }
        set { _isSelected = value; OnPropertyChanged("IsSelected"); }
    }
    public string RaisonSociale { get; set; }
    public string ICE { get; set; }
    public string RC { get; set; }
    public string IF { get; set; }
    public string Patente { get; set; }
    public string CIN { get; set; }
    public event PropertyChangedEventHandler PropertyChanged;
    protected void OnPropertyChanged(string name) {
        if (PropertyChanged != null)
            PropertyChanged(this, new PropertyChangedEventArgs(name));
    }
}

public class TemplateViewModel : INotifyPropertyChanged {
    private bool _isSelected;
    public bool IsSelected {
        get { return _isSelected; }
        set { _isSelected = value; OnPropertyChanged("IsSelected"); }
    }
    public string Type { get; set; }
    public string FileName { get; set; }
    public string FullPath { get; set; }
    public event PropertyChangedEventHandler PropertyChanged;
    protected void OnPropertyChanged(string name) {
        if (PropertyChanged != null)
            PropertyChanged(this, new PropertyChangedEventArgs(name));
    }
}
"@

# ─────────────────────────────────────────────────────────────
# Chargement XAML
# ─────────────────────────────────────────────────────────────
try {
    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Error "Erreur chargement XAML: $_"
    return
}

# Helper pour trouver un contrôle par son Name
function Get-Control($name) { $window.FindName($name) }

$txtYear           = Get-Control 'txtYear'
$rbOverwrite       = Get-Control 'rbOverwrite'
$rbAutoRename      = Get-Control 'rbAutoRename'
$txtTemplateFolder = Get-Control 'txtTemplateFolder'
$btnBrowseTemplates  = Get-Control 'btnBrowseTemplates'
$btnReloadTemplates  = Get-Control 'btnReloadTemplates'
$txtDestinationFolder = Get-Control 'txtDestinationFolder'
$btnBrowseDestination = Get-Control 'btnBrowseDestination'
$btnGenerateGuide   = Get-Control 'btnGenerateGuide'
$dgCompanies        = Get-Control 'dgCompanies'
$btnLoadCompanies   = Get-Control 'btnLoadCompanies'
$btnSelectAllCompanies = Get-Control 'btnSelectAllCompanies'
$btnUnselectAllCompanies = Get-Control 'btnUnselectAllCompanies'
$dgTemplates        = Get-Control 'dgTemplates'
$btnSelectAllTemplates = Get-Control 'btnSelectAllTemplates'
$btnUnselectAllTemplates = Get-Control 'btnUnselectAllTemplates'
$txtLogs            = Get-Control 'txtLogs'
$btnClearLogs       = Get-Control 'btnClearLogs'
$pbProgress         = Get-Control 'pbProgress'
$btnGenerate        = Get-Control 'btnGenerate'
$btnClose           = Get-Control 'btnClose'

$companies = [System.Collections.ObjectModel.ObservableCollection[SocieteViewModel]]::new()
$templates  = [System.Collections.ObjectModel.ObservableCollection[TemplateViewModel]]::new()
$dgCompanies.ItemsSource = $companies
$dgTemplates.ItemsSource  = $templates

# ─────────────────────────────────────────────────────────────
# Fonctions utilitaires
# ─────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $txtLogs.Dispatcher.Invoke([Action]{
        $txtLogs.AppendText("[$timestamp] $Message`r`n")
        $txtLogs.ScrollToEnd()
    }, [System.Windows.Threading.DispatcherPriority]::Normal)
}

function Set-Progress {
    param([double]$Value)
    $pbProgress.Dispatcher.Invoke([Action]{ $pbProgress.Value = $Value }, [System.Windows.Threading.DispatcherPriority]::Normal)
}

function Select-FolderDialog {
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dlg.SelectedPath
    }
    return $null
}

function Select-FileDialog {
    param([string]$Title, [string]$Filter)
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = $Title
    $dlg.Filter = $Filter
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dlg.FileName
    }
    return $null
}

function Sanitize-FolderName {
    param([string]$Name)
    $invalid = [System.IO.Path]::GetInvalidFileNameChars()
    return -join ($Name.ToCharArray() | ForEach-Object { if ($invalid -contains $_) { '_' } else { $_ } })
}

function Get-NextDomNumber {
    param([string]$Destination, [int]$Year)
    $max = 0
    if (Test-Path -LiteralPath $Destination) {
        Get-ChildItem -LiteralPath $Destination -Directory | Where-Object { $_.Name -match "^DOM-${Year}-(\d+)_" } | ForEach-Object {
            $num = [int]$Matches[1]
            if ($num -gt $max) { $max = $num }
        }
    }
    return $max + 1
}

# ─────────────────────────────────────────────────────────────
# Événements Templates
# ─────────────────────────────────────────────────────────────
$btnBrowseTemplates.Add_Click({
    $path = Select-FolderDialog
    if ($path) {
        $txtTemplateFolder.Text = $path
        Load-Templates
    }
})

$btnReloadTemplates.Add_Click({ Load-Templates })

function Load-Templates {
    $templates.Clear()
    $folder = $txtTemplateFolder.Text
    if (-not (Test-Path -LiteralPath $folder)) { Write-Log "Dossier templates introuvable : $folder"; return }

    Get-ChildItem -LiteralPath $folder -File | ForEach-Object {
        $type = $_.BaseName -replace '_\d+\.\d+\.\d+$', ''
        $templates.Add([TemplateViewModel]@{
            IsSelected = $true
            Type = $type
            FileName = $_.Name
            FullPath = $_.FullName
        })
    }
    Write-Log "$($templates.Count) template(s) chargé(s) depuis $folder"
}

$btnSelectAllTemplates.Add_Click({ $templates | ForEach-Object { $_.IsSelected = $true } })
$btnUnselectAllTemplates.Add_Click({ $templates | ForEach-Object { $_.IsSelected = $false } })

# ─────────────────────────────────────────────────────────────
# Événements Destination
# ─────────────────────────────────────────────────────────────
$btnBrowseDestination.Add_Click({
    $path = Select-FolderDialog
    if ($path) { $txtDestinationFolder.Text = $path }
})

# ─────────────────────────────────────────────────────────────
# Chargement Excel
# ─────────────────────────────────────────────────────────────
$btnLoadCompanies.Add_Click({
    $xlsPath = Select-FileDialog -Title 'Sélectionnez le fichier Excel des sociétés' -Filter 'Fichiers Excel (*.xlsx;*.xls)|*.xlsx;*.xls'
    if (-not $xlsPath) { return }
    Load-CompaniesFromExcel -Path $xlsPath
})

function Load-CompaniesFromExcel {
    param([string]$Path)
    $companies.Clear()

    try {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $wb = $excel.Workbooks.Open($Path)
        $ws = $wb.Sheets.Item(1)
        $used = $ws.UsedRange
        $rows = $used.Rows.Count
        $cols = $used.Columns.Count

        # Lire l'en-tête pour trouver les colonnes
        $headers = @{}
        for ($c = 1; $c -le $cols; $c++) {
            $h = [string]$ws.Cells.Item(1, $c).Text
            if (-not [string]::IsNullOrWhiteSpace($h)) { $headers[$h.Trim()] = $c }
        }

        for ($r = 2; $r -le $rows; $r++) {
            $rs = [string]$ws.Cells.Item($r, $headers['RaisonSociale']).Text
            if ([string]::IsNullOrWhiteSpace($rs)) { continue }
            $companies.Add([SocieteViewModel]@{
                IsSelected   = $true
                RaisonSociale = $rs.Trim()
                ICE  = if ($headers.Contains('ICE'))  { [string]$ws.Cells.Item($r, $headers['ICE']).Text } else { '' }
                RC   = if ($headers.Contains('RC'))   { [string]$ws.Cells.Item($r, $headers['RC']).Text } else { '' }
                IF   = if ($headers.Contains('IF'))   { [string]$ws.Cells.Item($r, $headers['IF']).Text } else { '' }
                Patente = if ($headers.Contains('Patente')) { [string]$ws.Cells.Item($r, $headers['Patente']).Text } else { '' }
                CIN  = if ($headers.Contains('CIN'))  { [string]$ws.Cells.Item($r, $headers['CIN']).Text } else { '' }
            })
        }
        $wb.Close($false)
        $excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
        Write-Log "$($companies.Count) société(s) chargée(s) depuis $Path"
    } catch {
        Write-Log "Erreur lecture Excel : $_"
        try { $excel.Quit() } catch {}
    }
}

$btnSelectAllCompanies.Add_Click({ $companies | ForEach-Object { $_.IsSelected = $true } })
$btnUnselectAllCompanies.Add_Click({ $companies | ForEach-Object { $_.IsSelected = $false } })

# ─────────────────────────────────────────────────────────────
# Génération
# ─────────────────────────────────────────────────────────────
$btnGenerate.Add_Click({
    try {
        # Validations
        $year = $txtYear.Text.Trim()
        if ($year -notmatch '^\d{4}$') { Write-Log 'ERREUR : Année invalide (YYYY requis).'; return }
        $dest = $txtDestinationFolder.Text
        if ([string]::IsNullOrWhiteSpace($dest)) { Write-Log 'ERREUR : Choisissez un dossier de destination.'; return }
        $tmplDir = $txtTemplateFolder.Text
        if (-not (Test-Path -LiteralPath $tmplDir)) { Write-Log 'ERREUR : Dossier des templates introuvable.'; return }

        $selectedCompanies = $companies | Where-Object { $_.IsSelected }
        $selectedTemplates = $templates  | Where-Object { $_.IsSelected }
        if ($selectedCompanies.Count -eq 0) { Write-Log 'ERREUR : Aucune société sélectionnée.'; return }
        if ($selectedTemplates.Count -eq 0) { Write-Log 'ERREUR : Aucun template sélectionné.'; return }

        $overwrite = $rbOverwrite.IsChecked -eq $true
        $total = $selectedCompanies.Count * $selectedTemplates.Count
        $done = 0

        $nextNum = Get-NextDomNumber -Destination $dest -Year $year
        Write-Log "--- Début génération : $($selectedCompanies.Count) société(s), $($selectedTemplates.Count) template(s) ---"

        foreach ($societe in $selectedCompanies) {
            $safeName = Sanitize-FolderName -Name $societe.RaisonSociale
            $folderName = "DOM-${year}-$( $nextNum.ToString('D4') )_$safeName"
            $clientDir = Join-Path $dest $folderName
            New-Item -ItemType Directory -Path $clientDir -Force | Out-Null
            Write-Log "Dossier créé : $folderName"

            foreach ($tmpl in $selectedTemplates) {
                $nameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($tmpl.FileName)
                $ext = [System.IO.Path]::GetExtension($tmpl.FileName)
                $newName = "$nameNoExt $($societe.RaisonSociale)$ext"
                $destFile = Join-Path $clientDir $newName

                if (Test-Path -LiteralPath $destFile) {
                    if ($overwrite) {
                        Copy-Item -Path $tmpl.FullPath -Destination $destFile -Force
                        Write-Log "  Écrasé : $newName"
                    } else {
                        $i = 1
                        do {
                            $altName = "$nameNoExt $($societe.RaisonSociale) ($i)$ext"
                            $destFile = Join-Path $clientDir $altName
                            $i++
                        } while (Test-Path -LiteralPath $destFile)
                        Copy-Item -Path $tmpl.FullPath -Destination $destFile
                        Write-Log "  Renommé : $altName"
                    }
                } else {
                    Copy-Item -Path $tmpl.FullPath -Destination $destFile
                    Write-Log "  Copié : $newName"
                }

                $done++
                Set-Progress -Value (($done / $total) * 100)
                [System.Windows.Forms.Application]::DoEvents()
            }
            $nextNum++
        }

        Set-Progress -Value 100
        Write-Log "--- Génération terminée : $done fichier(s) créé(s) ---"
    } catch {
        Write-Log "ERREUR : $_"
    }
})

# ─────────────────────────────────────────────────────────────
# Guide HTML
# ─────────────────────────────────────────────────────────────
$btnGenerateGuide.Add_Click({
    $dest = $txtDestinationFolder.Text
    if ([string]::IsNullOrWhiteSpace($dest)) { Write-Log 'ERREUR : Choisissez d''abord un dossier de destination.'; return }

    $year = if ($txtYear.Text -match '^\d{4}$') { $txtYear.Text } else { (Get-Date).Year }
    $htmlPath = Join-Path $dest "Guide_Generation_${year}.html"

    $companyLines = & {
        $sb = [System.Text.StringBuilder]::new()
        foreach ($c in $companies) {
            if ($c.IsSelected) {
                $null = $sb.AppendLine("  <li><strong>$($c.RaisonSociale)</strong> - ICE : $($c.ICE)</li>")
            }
        }
        $sb.ToString()
    }

    $html = @"
<!DOCTYPE html><html lang="fr"><head><meta charset="utf-8">
<title>Guide de génération $year</title>
<style>
  body { font-family: Segoe UI,sans-serif; background:#0b1220; color:#e5e7eb; max-width:900px; margin:30px auto; padding:20px; }
  h1 { color:#22c55e; } h2 { color:#38bdf8; }
  code { background:#1f2937; color:#c4b5fd; padding:2px 6px; border-radius:4px; }
  .card { background:#111827; border:1px solid #293548; border-radius:12px; padding:16px; margin:12px 0; }
</style></head><body>
<h1>Guide de génération $year</h1>
<div class="card">
<h2>Structure générée</h2>
<p>Les dossiers clients sont créés au format : <code>DOM-${year}-####_RAISONSOCIALE</code></p>
<ul>
  <li>Chaque dossier contient les templates sélectionnés</li>
  <li>Les fichiers sont renommés avec le nom de la société</li>
  <li>En cas de conflit : écrasement ou renommage automatique</li>
</ul>
</div>
<div class="card">
<h2>Sociétés traitées</h2>
<ul>
$companyLines
</ul>
</div>
<p style="text-align:center;color:#6b7280;margin-top:30px">Généré le $(Get-Date -Format 'dd/MM/yyyy HH:mm')</p>
</body></html>
"@

    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($htmlPath, $html, $utf8Bom)
    Write-Log "Guide HTML généré : $htmlPath"
    Start-Process -FilePath $htmlPath
})

# ─────────────────────────────────────────────────────────────
# Logs & Fermeture
# ─────────────────────────────────────────────────────────────
$btnClearLogs.Add_Click({ $txtLogs.Clear() })
$btnClose.Add_Click({ $window.Close() })

# ─────────────────────────────────────────────────────────────
# Initialisation
# ─────────────────────────────────────────────────────────────
$txtYear.Text = (Get-Date).Year

$defTmpl = Join-Path $scriptDir 'Templates'
if (Test-Path -LiteralPath $defTmpl) {
    $txtTemplateFolder.Text = $defTmpl
    Load-Templates
} else {
    Write-Log "Dossier Templates par défaut introuvable : $defTmpl"
}

$defDest = Join-Path $scriptDir 'Clients'
if (-not (Test-Path -LiteralPath $defDest)) { New-Item -ItemType Directory -Path $defDest -Force | Out-Null }
$txtDestinationFolder.Text = $defDest

# ─────────────────────────────────────────────────────────────
# Affichage
# ─────────────────────────────────────────────────────────────
$window.ShowDialog() | Out-Null
