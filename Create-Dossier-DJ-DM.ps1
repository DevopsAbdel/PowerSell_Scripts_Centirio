<#
    Create-Dossier-DJ-DM.ps1 (GUI WPF)
    Crée un dossier au format: YYYY-MM-DD_DJ_{Cons|Modif}_{NOM_STE_EN_MAJUSCULES}
#>

Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase
Add-Type -AssemblyName System.Windows.Forms

function Show-Info  { [System.Windows.MessageBox]::Show($args[0], $args[1], 'OK', 'Information') | Out-Null }
function Show-Error { [System.Windows.MessageBox]::Show($args[0], $args[1], 'OK', 'Error') | Out-Null }

#region XAML
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Création Dossier DJCrea / DJModif" Width="580" SizeToContent="Height" MinWidth="480"
        WindowStartupLocation="CenterScreen" ResizeMode="CanResize"
        FontFamily="Segoe UI" FontSize="13"
        Background="#1E1E2E" Foreground="#CDD6F4">
    <Window.Resources>
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="Margin" Value="0,0,0,4"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="Margin" Value="0,4,16,4"/>
        </Style>
        <Style TargetType="DatePicker">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="Margin" Value="0,4,0,4"/>
        </Style>
    </Window.Resources>
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Grid.Row="0" Text="📁 Création de dossier DJCrea / DJModif" FontSize="18"
                   FontWeight="Bold" Foreground="#CBA6F7" Margin="0,0,0,16"/>

        <Border Grid.Row="1" Background="#313244" CornerRadius="8" Padding="12" Margin="0,0,0,8">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Label Grid.Row="0" Grid.Column="0" Content="📅" FontSize="14" VerticalAlignment="Center"/>
                <CheckBox Grid.Column="1" Name="ChkToday" Content="Aujourd'hui" IsChecked="True"
                          VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBox Grid.Column="1" Name="TxtDate" Width="130" Text="2026-06-11" IsEnabled="False"
                         HorizontalContentAlignment="Center" FontFamily="Consolas" HorizontalAlignment="Right"/>
            </Grid>
        </Border>

        <Border Grid.Row="2" Background="#313244" CornerRadius="8" Padding="12" Margin="0,0,0,8">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Label Content="🏷️" FontSize="14" VerticalAlignment="Center"/>
                <RadioButton Grid.Column="1" Name="RbCons" Content="DJCrea" IsChecked="True"
                             GroupName="Type" VerticalAlignment="Center" Margin="8,0,0,0"/>
                <RadioButton Grid.Column="2" Name="RbModif" Content="DJModif" GroupName="Type"
                             VerticalAlignment="Center" Margin="16,0,0,0"/>
            </Grid>
        </Border>

        <Border Grid.Row="3" Name="BdrDateSte" Background="#313244" CornerRadius="8" Padding="12" Margin="0,0,0,8"
                Visibility="Collapsed">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Label Content="📅 Date création société" FontSize="14" VerticalAlignment="Center"/>
                <TextBox Grid.Column="1" Name="TxtDateSte" Width="130" Text=""
                         HorizontalContentAlignment="Center" FontFamily="Consolas"
                         HorizontalAlignment="Right"/>
            </Grid>
        </Border>

        <Border Grid.Row="4" Background="#313244" CornerRadius="8" Padding="12" Margin="0,0,0,8">
            <StackPanel>
                <Label Content="🏢 Société" FontSize="14" Padding="0"/>
                <TextBox Name="TxtSte" FontSize="14" FontWeight="Bold" Margin="0,4,0,0"/>
            </StackPanel>
        </Border>

        <Border Grid.Row="5" Background="#313244" CornerRadius="8" Padding="12" Margin="0,0,0,8">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBox Grid.Column="0" Name="TxtDest" FontSize="12"
                         IsReadOnly="True" Padding="6,4"/>
                <Button Grid.Column="1" Name="BtnBrowse" Content="📂 Parcourir..."
                        FontSize="12" Padding="10,4" Margin="8,0,0,0" Cursor="Hand"
                        Background="#585B70" Foreground="#CDD6F4" BorderThickness="0"/>
            </Grid>
        </Border>

        <Border Grid.Row="6" Background="#313244" CornerRadius="8" Padding="12" Margin="0,0,0,8">
            <StackPanel>
                <Label Content="🔍 Aperçu" FontSize="14" Padding="0"/>
                <TextBlock Name="Preview" FontSize="15" FontWeight="Bold" Margin="0,4,0,0"
                           Foreground="#A6E3A1" TextTrimming="CharacterEllipsis"/>
            </StackPanel>
        </Border>

        <StackPanel Grid.Row="7" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,8,0,0">
            <CheckBox Name="ChkOpen" Content="📂 Ouvrir le dossier" VerticalAlignment="Center"
                      IsChecked="True" Margin="0,0,16,0"/>
            <Button Name="BtnCreate" Content="   Créer le dossier   " FontSize="12" FontWeight="Bold"
                    Padding="10,4" Margin="0,0,12,0" IsEnabled="False"
                    Background="#A6E3A1" Foreground="#1E1E2E" BorderThickness="0">
                <Button.Resources>
                    <Style TargetType="Button">
                        <Setter Property="Background" Value="#A6E3A1"/>
                        <Setter Property="Foreground" Value="#1E1E2E"/>
                        <Setter Property="Cursor" Value="Hand"/>
                        <Style.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#94E2D5"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Background" Value="#45475A"/>
                                <Setter Property="Foreground" Value="#6C7086"/>
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </Button.Resources>
            </Button>
            <Button Name="BtnCancel" Content="Annuler" FontSize="12" Padding="10,4"
                    Background="#45475A" Foreground="#CDD6F4" BorderThickness="0" Cursor="Hand">
                <Button.Resources>
                    <Style TargetType="Button">
                        <Setter Property="Background" Value="#45475A"/>
                        <Setter Property="Foreground" Value="#CDD6F4"/>
                        <Style.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#585B70"/>
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </Button.Resources>
            </Button>
        </StackPanel>
    </Grid>
</Window>
"@
#endregion XAML

#region Load & events
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$chkToday   = $window.FindName('ChkToday')
$txtDate = $window.FindName('TxtDate')
$rbCons     = $window.FindName('RbCons')
$rbModif    = $window.FindName('RbModif')
$txtSte     = $window.FindName('TxtSte')
$preview    = $window.FindName('Preview')
$btnCreate  = $window.FindName('BtnCreate')
$btnCancel  = $window.FindName('BtnCancel')
$txtDest    = $window.FindName('TxtDest')
$btnBrowse  = $window.FindName('BtnBrowse')
$chkOpen    = $window.FindName('ChkOpen')
$bdrDateSte = $window.FindName('BdrDateSte')
$txtDateSte = $window.FindName('TxtDateSte')
$destPath = [Environment]::GetFolderPath('Desktop')

$chkToday.Add_Checked({
    $txtDate.IsEnabled = $false
    $txtDate.Text = (Get-Date).ToString('yyyy-MM-dd')
    Update-Preview
})
$chkToday.Add_Unchecked({
    $txtDate.IsEnabled = $true
    Update-Preview
})
$txtDate.Add_TextChanged({ Update-Preview })

$rbCons.Add_Checked({
    $bdrDateSte.Visibility = 'Collapsed'
    Update-Preview
})
$rbModif.Add_Checked({
    $bdrDateSte.Visibility = 'Visible'
    if ([string]::IsNullOrWhiteSpace($txtDateSte.Text)) { $txtDateSte.Text = (Get-Date).ToString('yyyy-MM-dd') }
    Update-Preview
})

$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Choisir le dossier de destination"
    $dlg.SelectedPath = $script:destPath
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:destPath = $dlg.SelectedPath
        $txtDest.Text = $script:destPath
    }
})

$window.Add_Loaded({
    $txtDate.Text = (Get-Date).ToString('yyyy-MM-dd')
    $txtDest.Text = $script:destPath
    Update-Preview
})

function Update-Preview {
    $dateStr = if ($chkToday.IsChecked) {
        (Get-Date).ToString('yyyy-MM-dd')
    } else {
        $inputDate = $txtDate.Text.Trim()
        try {
            $parsed = [datetime]::ParseExact($inputDate, 'yyyy-MM-dd', $null)
            $parsed.ToString('yyyy-MM-dd')
        } catch {
            $preview.Text = "Date invalide: YYYY-MM-DD"
            $preview.Foreground = "#F38BA8"
            $btnCreate.IsEnabled = $false
            return
        }
    }
    $script:dateStr = $dateStr
    $script:type = if ($rbCons.IsChecked) { 'DJCrea' } else { 'DJModif' }
    $script:ste = $txtSte.Text.Trim().ToUpper()
    $script:ste = $script:ste -replace '\s+', ' '
    if ([string]::IsNullOrWhiteSpace($script:ste)) {
        $preview.Foreground = "#A6E3A1"
        $preview.Text = "$dateStr`_$($script:type)`_{NOM_STE}"
        $btnCreate.IsEnabled = $false
        return
    }
    $folderName = "$dateStr`_$($script:type)`_$($script:ste)"
    $preview.Foreground = "#A6E3A1"
    if ($rbModif.IsChecked) {
        $dateSte = $txtDateSte.Text.Trim()
        try {
            $parsed = [datetime]::ParseExact($dateSte, 'yyyy-MM-dd', $null)
            $dateSteOk = $parsed.ToString('yyyy-MM-dd')
        } catch { $dateSteOk = $null }
        if ($dateSteOk) {
            $subFolder = "$dateSteOk`_DJCrea`_$($script:ste)"
            $preview.Text = "$folderName`n  └─ $subFolder"
        } else {
            $preview.Text = "$folderName`n  └─ {date_création}_DJCrea_{NOM_STE}"
        }
    } else {
        $preview.Text = $folderName
    }
    $btnCreate.IsEnabled = $true
}

$txtSte.Add_TextChanged({ Update-Preview })

$btnCreate.Add_Click({
    $dateStr = if ($chkToday.IsChecked) { (Get-Date).ToString('yyyy-MM-dd') } else { $txtDate.Text.Trim() }
    $folderName = "$dateStr`_$($script:type)`_$($script:ste)"
    $targetPath = Join-Path $script:destPath $folderName

    if (Test-Path $targetPath) {
        $r = [System.Windows.MessageBox]::Show(
            "Le dossier existe déjà :`n$folderName`n`nRemplacer ?",
            "Dossier existant", 'YesNo', 'Warning')
        if ($r -ne 'Yes') { return }
        Remove-Item -LiteralPath $targetPath -Recurse -Force
    }
    New-Item -Path $targetPath -ItemType Directory | Out-Null

    if ($rbModif.IsChecked) {
        $dateSte = $txtDateSte.Text.Trim()
        try {
            $parsed = [datetime]::ParseExact($dateSte, 'yyyy-MM-dd', $null)
            $subFolder = "$($parsed.ToString('yyyy-MM-dd'))_DJCrea`_$($script:ste)"
            New-Item -Path (Join-Path $targetPath $subFolder) -ItemType Directory | Out-Null
        } catch {}
    }

    try { Set-Clipboard -Value $targetPath } catch {}

    if ($chkOpen.IsChecked) { Invoke-Item -LiteralPath $targetPath }

    Show-Info "Dossier créé :`n$folderName`n`n📋 Chemin copié dans le presse-papiers" "Succès"
    $window.Close()
})

$btnCancel.Add_Click({ $window.Close() })
#endregion

$null = $window.ShowDialog()
