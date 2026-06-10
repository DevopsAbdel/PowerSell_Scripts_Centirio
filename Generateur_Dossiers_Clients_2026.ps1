<Window x:Class="CompanyTemplateGenerator.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Générateur de dossiers &amp; fichiers Excel"
        Height="720" Width="1150"
        Background="#121212"
        Foreground="#F5F5F5"
        WindowStartupLocation="CenterScreen">

    <Window.Resources>
        <!-- Couleurs -->
        <SolidColorBrush x:Key="AccentBrush" Color="#4F46E5" />
        <SolidColorBrush x:Key="AccentBrushHover" Color="#6366F1" />
        <SolidColorBrush x:Key="AccentBrushPressed" Color="#3730A3" />
        <SolidColorBrush x:Key="CardBackgroundBrush" Color="#1E1E1E" />
        <SolidColorBrush x:Key="BorderBrushDark" Color="#2A2A2A" />
        <SolidColorBrush x:Key="TextMutedBrush" Color="#9CA3AF" />

        <!-- Style général des boutons -->
        <Style TargetType="Button">
            <Setter Property="Background" Value="Transparent" />
            <Setter Property="Foreground" Value="White" />
            <Setter Property="BorderBrush" Value="{StaticResource AccentBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="Padding" Value="6,3" />
            <Setter Property="Margin" Value="0,0,0,0" />
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

        <!-- TextBox dark -->
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#111111" />
            <Setter Property="Foreground" Value="White" />
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushDark}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="Padding" Value="4,2" />
        </Style>

        <!-- DataGrid dark -->
        <Style TargetType="DataGrid">
            <Setter Property="Background" Value="#111827" />
            <Setter Property="Foreground" Value="White" />
            <Setter Property="GridLinesVisibility" Value="None" />
            <Setter Property="HeadersVisibility" Value="Column" />
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushDark}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="RowBackground" Value="#020617" />
            <Setter Property="AlternatingRowBackground" Value="#030712" />
        </Style>

        <!-- DataGridColumnHeader -->
        <Style TargetType="{x:Type DataGridColumnHeader}">
            <Setter Property="Background" Value="#111827" />
            <Setter Property="Foreground" Value="#E5E7EB" />
            <Setter Property="BorderBrush" Value="#1F2937" />
            <Setter Property="BorderThickness" Value="0,0,0,1" />
            <Setter Property="FontWeight" Value="SemiBold" />
        </Style>

        <!-- ScrollBar dark -->
        <Style TargetType="ScrollBar">
            <Setter Property="Background" Value="#020617" />
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

        <!-- En-tête -->
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

        <!-- Bloc configuration -->
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

                <!-- Année + options conflit -->
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

                <!-- Dossier templates -->
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

                <!-- Dossier destination + guide -->
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

        <!-- DataGrids -->
        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="3*" />
                <ColumnDefinition Width="2*" />
            </Grid.ColumnDefinitions>

            <!-- Sociétés -->
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

            <!-- Templates -->
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

        <!-- Logs -->
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
                              VerticalScrollBarVisibility="Auto">
                    <TextBox x:Name="txtLogs"
                             Background="#111111"
                             BorderThickness="0"
                             IsReadOnly="True"
                             AcceptsReturn="True"
                             TextWrapping="Wrap" />
                </ScrollViewer>
            </Grid>
        </Border>

        <!-- Progression + actions -->
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