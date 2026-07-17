<#
    RedM Cache Cleaner  -  v2.0
    Refined Red Dead / RedM western theme, rebuilt in WPF.
    Same functionality as v1: cleans cache / server-cache / server-cache-priv
    (after confirmation) with an optional second-confirmed nui-storage delete,
    an "Open RedM Folder" action, and an activity log.

    Original utility by Slimm.
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms   # used only for DoEvents in the log

# ------------------------------------------------------------------ config
$script:TargetDir    = Join-Path $env:LOCALAPPDATA 'RedM\RedM.app\data'
$script:CacheFolders = @('cache', 'server-cache', 'server-cache-priv')
$script:NuiFolder    = 'nui-storage'

# ================================================================== MAIN XAML
$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="RedM Cache Cleaner" Height="672" Width="720"
    WindowStartupLocation="CenterScreen"
    WindowStyle="None" AllowsTransparency="True" Background="Transparent"
    ResizeMode="NoResize" FontFamily="Segoe UI">

  <Window.Resources>
    <SolidColorBrush x:Key="Parchment"  Color="#F2E4CC"/>
    <SolidColorBrush x:Key="TextSoft"   Color="#E0CCAC"/>
    <SolidColorBrush x:Key="TextMuted"  Color="#B29A78"/>
    <SolidColorBrush x:Key="Accent"     Color="#9A3326"/>
    <SolidColorBrush x:Key="AccentHi"   Color="#B84234"/>
    <SolidColorBrush x:Key="Gold"       Color="#8A6E4A"/>
    <SolidColorBrush x:Key="GoldDim"    Color="#4A3B2C"/>
    <SolidColorBrush x:Key="Surface"    Color="#241F1A"/>
    <SolidColorBrush x:Key="Surface2"   Color="#2E2822"/>
    <SolidColorBrush x:Key="LogBg"      Color="#0C0A09"/>
    <SolidColorBrush x:Key="LogText"    Color="#DBC59E"/>

    <Style x:Key="Card" TargetType="Border">
      <Setter Property="Background" Value="{StaticResource Surface}"/>
      <Setter Property="BorderBrush" Value="{StaticResource GoldDim}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="CornerRadius" Value="10"/>
      <Setter Property="Padding" Value="20,16"/>
      <Setter Property="Margin" Value="0,0,0,14"/>
    </Style>

    <Style x:Key="CardHeading" TargetType="TextBlock">
      <Setter Property="Foreground" Value="{StaticResource Parchment}"/>
      <Setter Property="FontSize" Value="11"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Margin" Value="0,0,0,8"/>
    </Style>

    <Style x:Key="PrimaryButton" TargetType="Button">
      <Setter Property="Foreground" Value="{StaticResource Parchment}"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="SnapsToDevicePixels" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" CornerRadius="8" BorderThickness="1" BorderBrush="{StaticResource Gold}">
              <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                  <GradientStop Color="#A6392A" Offset="0"/>
                  <GradientStop Color="#7E271D" Offset="1"/>
                </LinearGradientBrush>
              </Border.Background>
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#B84234"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#7E271D"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="bd" Property="Background" Value="#4A2420"/>
                <Setter Property="Foreground" Value="#9A8266"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="GhostButton" TargetType="Button">
      <Setter Property="Foreground" Value="{StaticResource TextSoft}"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="SnapsToDevicePixels" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" CornerRadius="8" BorderThickness="1"
                    Background="{StaticResource Surface2}" BorderBrush="{StaticResource GoldDim}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#3A332B"/>
                <Setter TargetName="bd" Property="BorderBrush" Value="{StaticResource Gold}"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#272119"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Foreground" Value="#7A6B55"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="ChromeButton" TargetType="Button">
      <Setter Property="Foreground" Value="{StaticResource TextSoft}"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Width" Value="40"/>
      <Setter Property="Height" Value="30"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" CornerRadius="6" Background="Transparent">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#33FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="CloseButton" TargetType="Button" BasedOn="{StaticResource ChromeButton}">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" CornerRadius="6" Background="Transparent">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#C0392B"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="ThemedCheck" TargetType="CheckBox">
      <Setter Property="Foreground" Value="{StaticResource Parchment}"/>
      <Setter Property="FontSize" Value="12.5"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <StackPanel Orientation="Horizontal">
              <Border x:Name="box" Width="20" Height="20" CornerRadius="5"
                      Background="{StaticResource Surface}" BorderBrush="{StaticResource Gold}"
                      BorderThickness="1" VerticalAlignment="Center">
                <TextBlock x:Name="tick" Text="&#10003;" FontSize="13" FontWeight="Bold"
                           Foreground="{StaticResource Parchment}"
                           HorizontalAlignment="Center" VerticalAlignment="Center" Visibility="Collapsed"/>
              </Border>
              <ContentPresenter VerticalAlignment="Center" Margin="10,0,0,0"/>
            </StackPanel>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="box" Property="Background" Value="{StaticResource Accent}"/>
                <Setter TargetName="tick" Property="Visibility" Value="Visible"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="box" Property="BorderBrush" Value="{StaticResource AccentHi}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border Margin="14" CornerRadius="16" BorderThickness="1" BorderBrush="{StaticResource Gold}">
    <Border.Background>
      <LinearGradientBrush StartPoint="0,0" EndPoint="0.4,1">
        <GradientStop Color="#1B1613" Offset="0"/>
        <GradientStop Color="#12100E" Offset="1"/>
      </LinearGradientBrush>
    </Border.Background>
    <Border.Effect>
      <DropShadowEffect BlurRadius="26" ShadowDepth="0" Opacity="0.75" Color="#000000"/>
    </Border.Effect>

    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>

      <Grid x:Name="TitleBar" Grid.Row="0" Height="46" Background="Transparent">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center" Margin="18,0,0,0">
          <Border Width="22" Height="22" CornerRadius="6" Background="{StaticResource Accent}"
                  BorderBrush="{StaticResource Gold}" BorderThickness="1">
            <TextBlock Text="R" Foreground="{StaticResource Parchment}" FontWeight="Bold"
                       FontSize="13" HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <TextBlock Text="RedM Cache Cleaner" Foreground="{StaticResource TextMuted}"
                     FontSize="11.5" FontWeight="SemiBold" VerticalAlignment="Center" Margin="10,0,0,0"/>
        </StackPanel>
        <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,14,0">
          <Button x:Name="BtnMin" Style="{StaticResource ChromeButton}" Content="&#8211;"/>
          <Button x:Name="BtnClose" Style="{StaticResource CloseButton}" Content="&#10005;"/>
        </StackPanel>
      </Grid>

      <Border Grid.Row="1" Margin="1,0,1,0">
        <Border.Background>
          <LinearGradientBrush StartPoint="0,0" EndPoint="1,0.6">
            <GradientStop Color="#5E211B" Offset="0"/>
            <GradientStop Color="#3A1512" Offset="1"/>
          </LinearGradientBrush>
        </Border.Background>
        <Grid Margin="30,20,26,22">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <StackPanel Grid.Column="0">
            <TextBlock Text="RedM Cache Cleaner" Foreground="{StaticResource Parchment}"
                       FontSize="27" FontWeight="Bold"/>
            <TextBlock Text="Clean RedM cache files safely for the current Windows user."
                       Foreground="{StaticResource TextSoft}" FontSize="12.5" Margin="1,6,0,0"/>
          </StackPanel>
          <StackPanel Grid.Column="1" VerticalAlignment="Center" HorizontalAlignment="Right">
            <Border Background="#3A1512" CornerRadius="14" Padding="14,6"
                    BorderBrush="{StaticResource Gold}" BorderThickness="1">
              <StackPanel Orientation="Horizontal">
                <Ellipse Width="8" Height="8" Fill="#7BC96F" VerticalAlignment="Center"/>
                <TextBlock x:Name="UserPill" Text="USER" Foreground="{StaticResource Parchment}"
                           FontSize="11" FontWeight="SemiBold" Margin="8,0,0,0" VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
            <TextBlock Text="Built by Slimm" Foreground="{StaticResource TextSoft}"
                       FontSize="10" HorizontalAlignment="Right" Margin="0,8,2,0" Opacity="0.85"/>
          </StackPanel>
        </Grid>
      </Border>
      <Border Grid.Row="1" Height="3" VerticalAlignment="Bottom" Margin="1,0,1,0" Background="#2A0F0C"/>

      <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" Padding="26,22,26,4">
        <StackPanel>

          <Border Style="{StaticResource Card}">
            <StackPanel>
              <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                <TextBlock Text="&#128193;" FontSize="13" VerticalAlignment="Center"/>
                <TextBlock Text="TARGET DIRECTORY" Style="{StaticResource CardHeading}" Margin="8,0,0,0"/>
              </StackPanel>
              <Border Background="{StaticResource LogBg}" CornerRadius="6" Padding="12,9"
                      BorderBrush="{StaticResource GoldDim}" BorderThickness="1">
                <TextBlock x:Name="PathLabel" Text="path" Foreground="{StaticResource LogText}"
                           FontFamily="Consolas" FontSize="12" TextTrimming="CharacterEllipsis"/>
              </Border>
            </StackPanel>
          </Border>

          <Border Style="{StaticResource Card}">
            <StackPanel>
              <TextBlock Text="CLEANUP OPTIONS" Style="{StaticResource CardHeading}"/>
              <TextBlock TextWrapping="Wrap" Foreground="{StaticResource TextSoft}" FontSize="12.5"
                         Text="After you confirm, these folders are deleted:"/>
              <StackPanel Orientation="Horizontal" Margin="0,10,0,4">
                <Border Background="{StaticResource Surface2}" CornerRadius="6" Padding="10,5" Margin="0,0,8,0"
                        BorderBrush="{StaticResource GoldDim}" BorderThickness="1">
                  <TextBlock Text="cache" Foreground="{StaticResource TextSoft}" FontFamily="Consolas" FontSize="11.5"/>
                </Border>
                <Border Background="{StaticResource Surface2}" CornerRadius="6" Padding="10,5" Margin="0,0,8,0"
                        BorderBrush="{StaticResource GoldDim}" BorderThickness="1">
                  <TextBlock Text="server-cache" Foreground="{StaticResource TextSoft}" FontFamily="Consolas" FontSize="11.5"/>
                </Border>
                <Border Background="{StaticResource Surface2}" CornerRadius="6" Padding="10,5"
                        BorderBrush="{StaticResource GoldDim}" BorderThickness="1">
                  <TextBlock Text="server-cache-priv" Foreground="{StaticResource TextSoft}" FontFamily="Consolas" FontSize="11.5"/>
                </Border>
              </StackPanel>
              <Border Height="1" Background="{StaticResource GoldDim}" Margin="0,14,0,14"/>
              <CheckBox x:Name="NuiCheck" Style="{StaticResource ThemedCheck}" Content="Also delete nui-storage"/>
              <TextBlock TextWrapping="Wrap" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="30,6,0,0"
                         Text="nui-storage can hold separate UI / browser data. You'll be asked to confirm this one separately."/>
            </StackPanel>
          </Border>

          <Grid Margin="0,2,0,14">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="12"/>
              <ColumnDefinition Width="Auto"/>
              <ColumnDefinition Width="10"/>
              <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Button x:Name="BtnClean" Grid.Column="0" Height="48" Style="{StaticResource PrimaryButton}" Content="Clean RedM Cache"/>
            <Button x:Name="BtnOpen" Grid.Column="2" Height="48" Width="150" Style="{StaticResource GhostButton}" Content="Open Folder"/>
            <Button x:Name="BtnExit" Grid.Column="4" Height="48" Width="96" Style="{StaticResource GhostButton}" Content="Exit"/>
          </Grid>

          <Border Style="{StaticResource Card}" Margin="0">
            <StackPanel>
              <TextBlock Text="ACTIVITY LOG" Style="{StaticResource CardHeading}"/>
              <Border Background="{StaticResource LogBg}" CornerRadius="6"
                      BorderBrush="{StaticResource GoldDim}" BorderThickness="1">
                <TextBox x:Name="LogBox" Height="128" Background="Transparent" BorderThickness="0"
                         Foreground="{StaticResource LogText}" FontFamily="Consolas" FontSize="12"
                         IsReadOnly="True" TextWrapping="NoWrap" Padding="12,10"
                         VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"/>
              </Border>
            </StackPanel>
          </Border>

        </StackPanel>
      </ScrollViewer>

      <Border Grid.Row="3" Height="34" CornerRadius="0,0,15,15" Background="#0E0C0A">
        <Grid Margin="26,0">
          <TextBlock Text="RedM Cache Cleaner" Foreground="{StaticResource TextMuted}" FontSize="10.5"
                     VerticalAlignment="Center" Opacity="0.7"/>
          <TextBlock Text="v2.0  &#8226;  Built by Slimm" Foreground="{StaticResource TextMuted}" FontSize="10.5"
                     VerticalAlignment="Center" HorizontalAlignment="Right" Opacity="0.7"/>
        </Grid>
      </Border>

    </Grid>
  </Border>
</Window>
'@

# ================================================================== load window
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$TitleBar  = $window.FindName('TitleBar')
$BtnMin    = $window.FindName('BtnMin')
$BtnClose  = $window.FindName('BtnClose')
$UserPill  = $window.FindName('UserPill')
$PathLabel = $window.FindName('PathLabel')
$NuiCheck  = $window.FindName('NuiCheck')
$BtnClean  = $window.FindName('BtnClean')
$BtnOpen   = $window.FindName('BtnOpen')
$BtnExit   = $window.FindName('BtnExit')
$script:LogBox = $window.FindName('LogBox')

$UserPill.Text  = "USER: $env:USERNAME"
$PathLabel.Text = $script:TargetDir

# ================================================================== helpers
function Add-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $script:LogBox.AppendText("[$timestamp] $Message`r`n")
    $script:LogBox.ScrollToEnd()
    [System.Windows.Forms.Application]::DoEvents()
}

function Show-ThemedDialog {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet('YesNo','OK')] [string]$Mode = 'YesNo',
        [string]$YesText = 'Yes',
        [string]$NoText  = 'No',
        [switch]$Danger
    )

    $accentTop = if ($Danger) { '#B84234' } else { '#A6392A' }
    $accentBot = '#7E271D'
    if ($Mode -eq 'OK') { $iconGlyph = [char]0x2714 }
    elseif ($Danger)    { $iconGlyph = [char]0x26A0 }
    else                { $iconGlyph = [char]0x2753 }

    $dxaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        SizeToContent="Height" Width="440" ResizeMode="NoResize"
        WindowStartupLocation="CenterOwner" FontFamily="Segoe UI" ShowInTaskbar="False">
  <Border Margin="14" CornerRadius="14" BorderThickness="1" BorderBrush="#8A6E4A">
    <Border.Background>
      <LinearGradientBrush StartPoint="0,0" EndPoint="0.4,1">
        <GradientStop Color="#221C18" Offset="0"/>
        <GradientStop Color="#17130F" Offset="1"/>
      </LinearGradientBrush>
    </Border.Background>
    <Border.Effect><DropShadowEffect BlurRadius="24" ShadowDepth="0" Opacity="0.7" Color="#000000"/></Border.Effect>
    <StackPanel Margin="26,24,26,22">
      <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
        <Border Width="34" Height="34" CornerRadius="8" VerticalAlignment="Center">
          <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
              <GradientStop Color="$accentTop" Offset="0"/>
              <GradientStop Color="$accentBot" Offset="1"/>
            </LinearGradientBrush>
          </Border.Background>
          <TextBlock Text="$iconGlyph" FontSize="17" Foreground="#F2E4CC"
                     HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Border>
        <TextBlock Text="$Title" Foreground="#F2E4CC" FontSize="16" FontWeight="SemiBold"
                   VerticalAlignment="Center" Margin="14,0,0,0"/>
      </StackPanel>
      <TextBlock x:Name="Msg" Foreground="#E0CCAC" FontSize="12.5" TextWrapping="Wrap" Margin="2,0,0,20"/>
      <StackPanel x:Name="Btns" Orientation="Horizontal" HorizontalAlignment="Right"/>
    </StackPanel>
  </Border>
</Window>
"@

    $dr  = New-Object System.Xml.XmlNodeReader ([xml]$dxaml)
    $dlg = [Windows.Markup.XamlReader]::Load($dr)
    $dlg.Owner = $window
    $dlg.FindName('Msg').Text = $Message
    $btns = $dlg.FindName('Btns')

    $mkButton = {
        param($text, $primary, $value)
        $b = New-Object System.Windows.Controls.Button
        $b.Content  = $text
        $b.Height   = 40
        $b.MinWidth = 96
        $b.Margin   = New-Object System.Windows.Thickness(10,0,0,0)
        $b.Padding  = New-Object System.Windows.Thickness(16,0,16,0)
        $b.Style    = if ($primary) { $window.Resources['PrimaryButton'] } else { $window.Resources['GhostButton'] }
        $b.Tag      = $value
        $b.Add_Click({ $dlg.Tag = $this.Tag; $dlg.Close() }.GetNewClosure())
        $btns.Children.Add($b) | Out-Null
    }

    if ($Mode -eq 'OK') {
        & $mkButton 'OK' $true $true
    } else {
        & $mkButton $NoText  $false $false
        & $mkButton $YesText $true  $true
    }

    $dlg.Tag = $false
    $dlg.ShowDialog() | Out-Null
    return [bool]$dlg.Tag
}

function Remove-RedMFolder {
    param([string]$FolderName)
    $folderPath = Join-Path $script:TargetDir $FolderName
    if (Test-Path -LiteralPath $folderPath) {
        Add-Log "Deleting $FolderName..."
        try {
            Remove-Item -LiteralPath $folderPath -Recurse -Force -ErrorAction Stop
            Add-Log "SUCCESS: $FolderName folder deleted."
            return $true
        }
        catch {
            Add-Log "ERROR: Failed to delete $FolderName. $($_.Exception.Message)"
            return $false
        }
    }
    else {
        Add-Log "INFO: $FolderName folder not found - skipping."
        return $true
    }
}

# ================================================================== events
$TitleBar.Add_MouseLeftButtonDown({ $window.DragMove() })
$BtnMin.Add_Click({ $window.WindowState = 'Minimized' })
$BtnClose.Add_Click({ $window.Close() })
$BtnExit.Add_Click({ $window.Close() })

$BtnOpen.Add_Click({
    if (Test-Path -LiteralPath $script:TargetDir) {
        Start-Process explorer.exe -ArgumentList "`"$script:TargetDir`""
        Add-Log "Opened RedM data folder in Explorer."
    }
    else {
        Show-ThemedDialog -Title 'Folder Not Found' -Mode OK -Danger `
            -Message "RedM data directory was not found:`n`n$script:TargetDir" | Out-Null
        Add-Log "ERROR: RedM data directory not found: $script:TargetDir"
    }
})

$BtnClean.Add_Click({
    if (-not (Test-Path -LiteralPath $script:TargetDir)) {
        Show-ThemedDialog -Title 'RedM Folder Not Found' -Mode OK -Danger `
            -Message ("RedM data directory was not found for Windows user '$env:USERNAME'.`n`nExpected location:`n$script:TargetDir`n`nMake sure RedM is installed and has been run at least once.") | Out-Null
        Add-Log "ERROR: RedM data directory not found: $script:TargetDir"
        return
    }

    $confirm = Show-ThemedDialog -Title 'Confirm Cleanup' -YesText 'Clean Now' -NoText 'Cancel' `
        -Message "Delete these RedM cache folders?`n`n    cache`n    server-cache`n    server-cache-priv`n`nClose RedM first so files aren't locked."
    if (-not $confirm) { Add-Log 'Operation cancelled by user.'; return }

    $BtnClean.IsEnabled = $false
    $BtnOpen.IsEnabled  = $false
    Add-Log 'Starting cleanup...'

    foreach ($folder in $script:CacheFolders) {
        Remove-RedMFolder -FolderName $folder | Out-Null
    }

    if ($NuiCheck.IsChecked) {
        $nuiConfirm = Show-ThemedDialog -Title 'Confirm nui-storage Deletion' -Danger `
            -YesText 'Delete It' -NoText 'Keep It' `
            -Message "You selected nui-storage.`n`nThis can contain separate UI / browser storage data. Do you also want to delete the nui-storage folder?"
        if ($nuiConfirm) { Remove-RedMFolder -FolderName $script:NuiFolder | Out-Null }
        else { Add-Log 'INFO: nui-storage folder was not deleted.' }
    }
    else {
        Add-Log 'INFO: nui-storage option was not selected.'
    }

    Add-Log 'Cleanup complete!'
    Show-ThemedDialog -Title 'Cleanup Complete' -Mode OK `
        -Message 'RedM cache cleanup finished successfully.' | Out-Null

    $BtnClean.IsEnabled = $true
    $BtnOpen.IsEnabled  = $true
})

$window.Add_ContentRendered({
    Add-Log "Ready. Running as Windows user: $env:USERNAME"
    Add-Log "Target directory: $script:TargetDir"
})

# ================================================================== run
$window.ShowDialog() | Out-Null
