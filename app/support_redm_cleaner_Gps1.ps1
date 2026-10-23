<#
    RedM Cache Cleaner  -  v3.0
    Apple-style redesign in WPF: grouped layout, system type, light/dark that
    follows the Windows app theme, eased motion, and a RedM red accent.
    Same functionality as v1/v2: cleans cache / server-cache / server-cache-priv
    (after confirmation) with an optional second-confirmed nui-storage delete,
    an "Open Folder" action, and an activity log.

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

# ------------------------------------------------------------------ theme
# Follow the Windows "app mode" setting (Settings > Personalization > Colors).
$script:Dark = $false
try {
    $personalize = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -ErrorAction Stop
    if ($personalize.AppsUseLightTheme -eq 0) { $script:Dark = $true }
}
catch { }

# Honor "Animation effects" (Settings > Accessibility > Visual effects).
# When it's off, fades stay but scaling and sliding are dropped.
$script:Motion = [System.Windows.SystemParameters]::ClientAreaAnimation

if ($script:Dark) {
    $script:Palette = @{
        Bg = '#1C1C1E'; Group = '#2C2C2E'; GroupBorder = '#14FFFFFF'; Hairline = '#33FFFFFF'
        Separator = '#3A3A3C'; Label = '#F5F5F7'; Secondary = '#A1A1A6'; Tertiary = '#6E6E73'
        Fill = '#3A3A3C'; FillHover = '#48484A'; FillPressed = '#2F2F31'
        Accent = '#D84B38'; AccentHover = '#E25D4A'; AccentPressed = '#BC3F2D'
        AccentTop = '#E8604C'; AccentBottom = '#B83A28'; FocusRing = '#99E0533F'
        TrackOff = '#39393D'; Scrim = '#66000000'; Scroll = '#40FFFFFF'
        Green = '#30D158'; CloseHover = '#E5484D'; ShadowOpacity = '0.55'
    }
}
else {
    $script:Palette = @{
        Bg = '#F2F2F7'; Group = '#FFFFFF'; GroupBorder = '#0F000000'; Hairline = '#26000000'
        Separator = '#E5E5EA'; Label = '#1D1D1F'; Secondary = '#6E6E73'; Tertiary = '#8E8E93'
        Fill = '#E8E8ED'; FillHover = '#DEDEE3'; FillPressed = '#D1D1D6'
        Accent = '#C0392B'; AccentHover = '#CD4637'; AccentPressed = '#A8301F'
        AccentTop = '#D9493A'; AccentBottom = '#A8291D'; FocusRing = '#99C0392B'
        TrackOff = '#E3E3E8'; Scrim = '#33000000'; Scroll = '#33000000'
        Green = '#34C759'; CloseHover = '#E5484D'; ShadowOpacity = '0.22'
    }
}
$script:Palette.Fast = if ($script:Motion) { '0:0:0.1' }  else { '0:0:0' }
$script:Palette.Med  = if ($script:Motion) { '0:0:0.28' } else { '0:0:0' }

function Expand-Theme {
    param([string]$Text)
    foreach ($key in $script:Palette.Keys) { $Text = $Text.Replace("@$key@", $script:Palette[$key]) }
    return $Text
}

# Critically damped feel: fast start, long soft settle, no overshoot.
$script:Ease = New-Object System.Windows.Media.Animation.ExponentialEase
$script:Ease.EasingMode = 'EaseOut'
$script:Ease.Exponent   = 6
$script:Ease.Freeze()

# ================================================================== MAIN XAML
$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="RedM Cache Cleaner" Width="600" SizeToContent="Height"
    WindowStartupLocation="CenterScreen"
    WindowStyle="None" AllowsTransparency="True" Background="Transparent"
    ResizeMode="NoResize" FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="13">

  <Window.Resources>
    <Style x:Key="FocusRing">
      <Setter Property="Control.Template">
        <Setter.Value>
          <ControlTemplate>
            <Border Margin="-3" CornerRadius="14" BorderThickness="2" BorderBrush="@FocusRing@"/>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Group" TargetType="Border">
      <Setter Property="Background" Value="@Group@"/>
      <Setter Property="BorderBrush" Value="@GroupBorder@"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="CornerRadius" Value="12"/>
    </Style>

    <Style x:Key="GroupHeader" TargetType="TextBlock">
      <Setter Property="Foreground" Value="@Secondary@"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Margin" Value="14,18,0,7"/>
    </Style>

    <Style x:Key="Separator" TargetType="Border">
      <Setter Property="Height" Value="1"/>
      <Setter Property="Background" Value="@Separator@"/>
      <Setter Property="Margin" Value="44,0,0,0"/>
    </Style>

    <Style x:Key="RowGlyph" TargetType="TextBlock">
      <Setter Property="FontFamily" Value="Segoe Fluent Icons, Segoe MDL2 Assets"/>
      <Setter Property="FontSize" Value="16"/>
      <Setter Property="Foreground" Value="@Accent@"/>
      <Setter Property="Width" Value="30"/>
      <Setter Property="VerticalAlignment" Value="Center"/>
    </Style>

    <Style x:Key="PrimaryButton" TargetType="Button">
      <Setter Property="Foreground" Value="#FFFFFF"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="FocusVisualStyle" Value="{StaticResource FocusRing}"/>
      <Setter Property="SnapsToDevicePixels" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" CornerRadius="12" Background="@Accent@" RenderTransformOrigin="0.5,0.5">
              <Border.RenderTransform><ScaleTransform/></Border.RenderTransform>
              <ContentPresenter Margin="{TemplateBinding Padding}" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="@AccentHover@"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="bd" Property="Background" Value="@AccentPressed@"/>
                <Trigger.EnterActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimation Storyboard.TargetName="bd" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" To="0.97" Duration="@Fast@"/>
                      <DoubleAnimation Storyboard.TargetName="bd" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" To="0.97" Duration="@Fast@"/>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.EnterActions>
                <Trigger.ExitActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimation Storyboard.TargetName="bd" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" To="1" Duration="@Med@">
                        <DoubleAnimation.EasingFunction><ExponentialEase EasingMode="EaseOut" Exponent="6"/></DoubleAnimation.EasingFunction>
                      </DoubleAnimation>
                      <DoubleAnimation Storyboard.TargetName="bd" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" To="1" Duration="@Med@">
                        <DoubleAnimation.EasingFunction><ExponentialEase EasingMode="EaseOut" Exponent="6"/></DoubleAnimation.EasingFunction>
                      </DoubleAnimation>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.ExitActions>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="bd" Property="Opacity" Value="0.5"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="SecondaryButton" TargetType="Button">
      <Setter Property="Foreground" Value="@Label@"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="Medium"/>
      <Setter Property="FocusVisualStyle" Value="{StaticResource FocusRing}"/>
      <Setter Property="SnapsToDevicePixels" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" CornerRadius="12" Background="@Fill@" RenderTransformOrigin="0.5,0.5">
              <Border.RenderTransform><ScaleTransform/></Border.RenderTransform>
              <ContentPresenter Margin="{TemplateBinding Padding}" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="@FillHover@"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="bd" Property="Background" Value="@FillPressed@"/>
                <Trigger.EnterActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimation Storyboard.TargetName="bd" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" To="0.97" Duration="@Fast@"/>
                      <DoubleAnimation Storyboard.TargetName="bd" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" To="0.97" Duration="@Fast@"/>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.EnterActions>
                <Trigger.ExitActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimation Storyboard.TargetName="bd" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" To="1" Duration="@Med@">
                        <DoubleAnimation.EasingFunction><ExponentialEase EasingMode="EaseOut" Exponent="6"/></DoubleAnimation.EasingFunction>
                      </DoubleAnimation>
                      <DoubleAnimation Storyboard.TargetName="bd" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" To="1" Duration="@Med@">
                        <DoubleAnimation.EasingFunction><ExponentialEase EasingMode="EaseOut" Exponent="6"/></DoubleAnimation.EasingFunction>
                      </DoubleAnimation>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.ExitActions>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="bd" Property="Opacity" Value="0.5"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="ChromeButton" TargetType="Button">
      <Setter Property="Foreground" Value="@Secondary@"/>
      <Setter Property="FontFamily" Value="Segoe Fluent Icons, Segoe MDL2 Assets"/>
      <Setter Property="FontSize" Value="10"/>
      <Setter Property="Width" Value="34"/>
      <Setter Property="Height" Value="28"/>
      <Setter Property="Margin" Value="4,0,0,0"/>
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" CornerRadius="8" Background="Transparent">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="@Fill@"/>
                <Setter Property="Foreground" Value="@Label@"/>
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
            <Border x:Name="bd" CornerRadius="8" Background="Transparent">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="@CloseHover@"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Switch" TargetType="CheckBox">
      <Setter Property="Foreground" Value="@Label@"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Grid Background="Transparent">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
              </Grid.ColumnDefinitions>
              <ContentPresenter VerticalAlignment="Center"/>
              <Grid Grid.Column="1" VerticalAlignment="Center">
                <Border x:Name="ring" Margin="-3" CornerRadius="15" BorderThickness="2"
                        BorderBrush="@FocusRing@" Visibility="Collapsed"/>
                <Border x:Name="track" Width="40" Height="24" CornerRadius="12">
                  <Border.Background><SolidColorBrush Color="@TrackOff@"/></Border.Background>
                  <Ellipse x:Name="knob" Width="20" Height="20" Fill="#FFFFFF"
                           HorizontalAlignment="Left" Margin="2,0,0,0">
                    <Ellipse.RenderTransform><TranslateTransform/></Ellipse.RenderTransform>
                    <Ellipse.Effect>
                      <DropShadowEffect BlurRadius="4" ShadowDepth="1" Direction="270" Opacity="0.25" Color="#000000"/>
                    </Ellipse.Effect>
                  </Ellipse>
                </Border>
              </Grid>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Trigger.EnterActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimation Storyboard.TargetName="knob" Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.X)" To="16" Duration="@Med@">
                        <DoubleAnimation.EasingFunction><ExponentialEase EasingMode="EaseOut" Exponent="6"/></DoubleAnimation.EasingFunction>
                      </DoubleAnimation>
                      <ColorAnimation Storyboard.TargetName="track" Storyboard.TargetProperty="(Border.Background).(SolidColorBrush.Color)" To="@Accent@" Duration="@Med@"/>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.EnterActions>
                <Trigger.ExitActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimation Storyboard.TargetName="knob" Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.X)" To="0" Duration="@Med@">
                        <DoubleAnimation.EasingFunction><ExponentialEase EasingMode="EaseOut" Exponent="6"/></DoubleAnimation.EasingFunction>
                      </DoubleAnimation>
                      <ColorAnimation Storyboard.TargetName="track" Storyboard.TargetProperty="(Border.Background).(SolidColorBrush.Color)" To="@TrackOff@" Duration="@Med@"/>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.ExitActions>
              </Trigger>
              <Trigger Property="IsKeyboardFocused" Value="True">
                <Setter TargetName="ring" Property="Visibility" Value="Visible"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Grid x:Name="Root" Margin="24" RenderTransformOrigin="0.5,0.5">
    <Grid.RenderTransform><ScaleTransform/></Grid.RenderTransform>

    <!-- shadow lives on its own layer so the text above stays crisp -->
    <Border CornerRadius="14" Background="@Bg@">
      <Border.Effect>
        <DropShadowEffect BlurRadius="32" ShadowDepth="8" Direction="270" Opacity="@ShadowOpacity@" Color="#000000"/>
      </Border.Effect>
    </Border>

    <Border CornerRadius="14" Background="@Bg@" BorderBrush="@Hairline@" BorderThickness="1">
      <StackPanel>

        <Grid x:Name="TitleBar" Height="40" Background="Transparent">
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,10,0">
            <Button x:Name="BtnMin" Style="{StaticResource ChromeButton}" Content="&#xE921;"/>
            <Button x:Name="BtnClose" Style="{StaticResource CloseButton}" Content="&#xE8BB;"/>
          </StackPanel>
        </Grid>

        <Grid x:Name="Header" Margin="28,0,28,4" Background="Transparent">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <Border Width="56" Height="56" CornerRadius="13">
            <Border.Background>
              <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                <GradientStop Color="@AccentTop@" Offset="0"/>
                <GradientStop Color="@AccentBottom@" Offset="1"/>
              </LinearGradientBrush>
            </Border.Background>
            <TextBlock Text="&#xE74D;" FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" FontSize="26"
                       Foreground="#FFFFFF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="16,0,12,0">
            <TextBlock Text="RedM Cache Cleaner" FontFamily="Segoe UI Variable Display, Segoe UI"
                       FontSize="24" FontWeight="SemiBold" Foreground="@Label@"/>
            <TextBlock Text="Clean RedM cache files safely for the current Windows user."
                       FontSize="13" Foreground="@Secondary@" Margin="0,2,0,0" TextWrapping="Wrap"/>
          </StackPanel>
          <Border Grid.Column="2" VerticalAlignment="Center" CornerRadius="12" Padding="10,5" Background="@Fill@">
            <StackPanel Orientation="Horizontal">
              <Ellipse Width="7" Height="7" Fill="@Green@" VerticalAlignment="Center"/>
              <TextBlock x:Name="UserPill" Text="user" FontSize="12" FontWeight="Medium" Foreground="@Label@"
                         Margin="7,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>
          </Border>
        </Grid>

        <StackPanel Margin="20,6,20,0">

          <TextBlock Text="Location" Style="{StaticResource GroupHeader}"/>
          <Border Style="{StaticResource Group}">
            <Grid Margin="14,8,8,8">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
              </Grid.ColumnDefinitions>
              <TextBlock Text="&#xE8B7;" Style="{StaticResource RowGlyph}"/>
              <TextBlock x:Name="PathLabel" Grid.Column="1" Text="path" Foreground="@Label@" VerticalAlignment="Center"
                         FontFamily="Cascadia Mono, Consolas" FontSize="12" TextTrimming="CharacterEllipsis" Margin="0,0,10,0"/>
              <Button x:Name="BtnOpen" Grid.Column="2" Style="{StaticResource SecondaryButton}" Content="Open Folder"
                      Height="30" Padding="14,0" FontSize="12.5"/>
            </Grid>
          </Border>

          <TextBlock Text="Folders to clean" Style="{StaticResource GroupHeader}"/>
          <Border Style="{StaticResource Group}">
            <StackPanel>
              <StackPanel Orientation="Horizontal" Height="40" Margin="14,0">
                <TextBlock Text="&#xE8B7;" Style="{StaticResource RowGlyph}" Foreground="@Tertiary@"/>
                <TextBlock Text="cache" Foreground="@Label@" VerticalAlignment="Center"/>
              </StackPanel>
              <Border Style="{StaticResource Separator}"/>
              <StackPanel Orientation="Horizontal" Height="40" Margin="14,0">
                <TextBlock Text="&#xE8B7;" Style="{StaticResource RowGlyph}" Foreground="@Tertiary@"/>
                <TextBlock Text="server-cache" Foreground="@Label@" VerticalAlignment="Center"/>
              </StackPanel>
              <Border Style="{StaticResource Separator}"/>
              <StackPanel Orientation="Horizontal" Height="40" Margin="14,0">
                <TextBlock Text="&#xE8B7;" Style="{StaticResource RowGlyph}" Foreground="@Tertiary@"/>
                <TextBlock Text="server-cache-priv" Foreground="@Label@" VerticalAlignment="Center"/>
              </StackPanel>
              <Border Style="{StaticResource Separator}"/>
              <Grid Height="44" Margin="14,0">
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="Auto"/>
                  <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <TextBlock Text="&#xE7BA;" Style="{StaticResource RowGlyph}"/>
                <CheckBox x:Name="NuiCheck" Grid.Column="1" Style="{StaticResource Switch}" Content="Also delete nui-storage"/>
              </Grid>
            </StackPanel>
          </Border>
          <TextBlock TextWrapping="Wrap" Foreground="@Secondary@" FontSize="12" LineHeight="17" Margin="14,7,14,0"
                     Text="nui-storage can hold separate UI and browser data. You'll be asked to confirm this one separately."/>

          <Grid Margin="0,20,0,0">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="Auto"/>
              <ColumnDefinition Width="10"/>
              <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Button x:Name="BtnExit" Grid.Column="0" Width="104" Height="44" Style="{StaticResource SecondaryButton}" Content="Exit"/>
            <Button x:Name="BtnClean" Grid.Column="2" Height="44" Style="{StaticResource PrimaryButton}" Content="Clean RedM Cache"/>
          </Grid>

          <TextBlock Text="Activity" Style="{StaticResource GroupHeader}"/>
          <Border Style="{StaticResource Group}">
            <TextBox x:Name="LogBox" Height="100" Margin="4,6" Background="Transparent" BorderThickness="0"
                     Foreground="@Secondary@" FontFamily="Cascadia Mono, Consolas" FontSize="11.5"
                     IsReadOnly="True" TextWrapping="Wrap" Padding="8,4"
                     VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
              <TextBox.Resources>
                <Style TargetType="ScrollBar">
                  <Setter Property="Width" Value="8"/>
                  <Setter Property="MinWidth" Value="8"/>
                  <Setter Property="Template">
                    <Setter.Value>
                      <ControlTemplate TargetType="ScrollBar">
                        <Track x:Name="PART_Track" IsDirectionReversed="True" Orientation="{TemplateBinding Orientation}">
                          <Track.Thumb>
                            <Thumb>
                              <Thumb.Template>
                                <ControlTemplate TargetType="Thumb">
                                  <Border Width="5" CornerRadius="2.5" Background="@Scroll@" HorizontalAlignment="Center"/>
                                </ControlTemplate>
                              </Thumb.Template>
                            </Thumb>
                          </Track.Thumb>
                        </Track>
                      </ControlTemplate>
                    </Setter.Value>
                  </Setter>
                </Style>
              </TextBox.Resources>
            </TextBox>
          </Border>
        </StackPanel>

        <Grid Margin="34,16,34,16">
          <TextBlock Text="Version 3.0" Foreground="@Tertiary@" FontSize="11" VerticalAlignment="Center"/>
          <TextBlock Text="Built by Slimm" Foreground="@Tertiary@" FontSize="11"
                     VerticalAlignment="Center" HorizontalAlignment="Right"/>
        </Grid>

      </StackPanel>
    </Border>

    <!-- dims the window while a confirmation is up -->
    <Border x:Name="Scrim" CornerRadius="14" Background="@Scrim@" Opacity="0" IsHitTestVisible="False"/>
  </Grid>
</Window>
'@

# ================================================================== load window
$reader = New-Object System.Xml.XmlNodeReader ([xml](Expand-Theme $xaml))
$window = [Windows.Markup.XamlReader]::Load($reader)

$script:Root  = $window.FindName('Root')
$script:Scrim = $window.FindName('Scrim')
$TitleBar  = $window.FindName('TitleBar')
$Header    = $window.FindName('Header')
$BtnMin    = $window.FindName('BtnMin')
$BtnClose  = $window.FindName('BtnClose')
$UserPill  = $window.FindName('UserPill')
$PathLabel = $window.FindName('PathLabel')
$NuiCheck  = $window.FindName('NuiCheck')
$BtnClean  = $window.FindName('BtnClean')
$BtnOpen   = $window.FindName('BtnOpen')
$BtnExit   = $window.FindName('BtnExit')
$script:LogBox = $window.FindName('LogBox')

$UserPill.Text  = $env:USERNAME
$PathLabel.Text = $script:TargetDir
$PathLabel.ToolTip = $script:TargetDir

# ================================================================== motion
# Animations start from the current on-screen value, so they can be
# interrupted and reversed without a jump.
function Start-Ease {
    param($Target, $Property, [double]$To, [double]$Ms, [scriptblock]$Done, $From)
    $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
    $anim.To = $To
    if ($null -ne $From) { $anim.From = [double]$From }
    $anim.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds($Ms))
    $anim.EasingFunction = $script:Ease
    if ($Done) { $anim.Add_Completed($Done) }
    $Target.BeginAnimation($Property, $anim)
}

function Start-Scale {
    param($Target, [double]$To, [double]$Ms, $From)
    if (-not $script:Motion) { return }
    Start-Ease $Target.RenderTransform ([System.Windows.Media.ScaleTransform]::ScaleXProperty) $To $Ms -From $From
    Start-Ease $Target.RenderTransform ([System.Windows.Media.ScaleTransform]::ScaleYProperty) $To $Ms -From $From
}

# Arrive and leave along the same path: scale + fade in, scale + fade out.
function Show-Materialize {
    param($Target, [double]$FromScale = 0.96)
    Start-Ease $Target ([System.Windows.UIElement]::OpacityProperty) 1 260 -From 0
    Start-Scale $Target 1 420 -From $FromScale
}

function Hide-Materialize {
    param($Target, [scriptblock]$Done, [double]$ToScale = 0.96)
    Start-Scale $Target $ToScale 160
    Start-Ease $Target ([System.Windows.UIElement]::OpacityProperty) 0 160 $Done
}

$script:Closing = $false
function Close-App {
    if ($script:Closing) { return }
    $script:Closing = $true
    Hide-Materialize $script:Root { $window.Close() }
}

# ================================================================== helpers
function Add-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $script:LogBox.AppendText("[$timestamp] $Message`r`n")
    $script:LogBox.ScrollToEnd()
    [System.Windows.Forms.Application]::DoEvents()
}

function Close-ThemedDialog {
    param([bool]$Value)
    if ($script:DlgState.Closing) { return }
    $script:DlgState.Closing = $true
    $script:DlgState.Result  = $Value
    Hide-Materialize ($script:Dlg.FindName('Root')) { $script:Dlg.Close() } 0.94
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

    # Icon tile: warning for problems, check for a finished job, trash for "delete these?"
    if ($Danger) {
        $iconGlyph = '&#xE7BA;'; $iconTop = '@AccentTop@'; $iconBottom = '@AccentBottom@'
    }
    elseif ($Mode -eq 'OK') {
        $iconGlyph = '&#xE73E;'; $iconTop = '#3DDC68'; $iconBottom = '#248A3D'
    }
    else {
        $iconGlyph = '&#xE74D;'; $iconTop = '@AccentTop@'; $iconBottom = '@AccentBottom@'
    }

    $dxaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        SizeToContent="Height" Width="372" ResizeMode="NoResize"
        WindowStartupLocation="CenterOwner" FontFamily="Segoe UI Variable Text, Segoe UI" ShowInTaskbar="False">
  <Grid x:Name="Root" Margin="24" RenderTransformOrigin="0.5,0.5">
    <Grid.RenderTransform><ScaleTransform/></Grid.RenderTransform>
    <Border CornerRadius="14" Background="@Group@">
      <Border.Effect>
        <DropShadowEffect BlurRadius="32" ShadowDepth="10" Direction="270" Opacity="@ShadowOpacity@" Color="#000000"/>
      </Border.Effect>
    </Border>
    <Border CornerRadius="14" Background="@Group@" BorderBrush="@Hairline@" BorderThickness="1">
      <StackPanel Margin="24,26,24,20">
        <Border Width="56" Height="56" CornerRadius="13" HorizontalAlignment="Center">
          <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
              <GradientStop Color="$iconTop" Offset="0"/>
              <GradientStop Color="$iconBottom" Offset="1"/>
            </LinearGradientBrush>
          </Border.Background>
          <TextBlock Text="$iconGlyph" FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" FontSize="26"
                     Foreground="#FFFFFF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Border>
        <TextBlock Text="$Title" FontFamily="Segoe UI Variable Display, Segoe UI" FontSize="16" FontWeight="SemiBold"
                   Foreground="@Label@" TextAlignment="Center" TextWrapping="Wrap" Margin="0,16,0,0"/>
        <TextBlock x:Name="Msg" FontSize="13" LineHeight="19" Foreground="@Secondary@"
                   TextAlignment="Center" TextWrapping="Wrap" Margin="0,8,0,22"/>
        <UniformGrid x:Name="Btns" Rows="1"/>
      </StackPanel>
    </Border>
  </Grid>
</Window>
"@

    $dr  = New-Object System.Xml.XmlNodeReader ([xml](Expand-Theme $dxaml))
    $dlg = [Windows.Markup.XamlReader]::Load($dr)
    $dlg.Owner = $window
    $dlg.FindName('Msg').Text = $Message
    $btns = $dlg.FindName('Btns')

    $script:Dlg      = $dlg
    $script:DlgState = @{ Result = $false; Closing = $false; Danger = [bool]$Danger }

    $mkButton = {
        param($text, $primary, $value, $margin)
        $b = New-Object System.Windows.Controls.Button
        $b.Content  = $text
        $b.Height   = 36
        $b.FontSize = 13
        $b.Margin   = $margin
        $b.Style    = if ($primary) { $window.Resources['PrimaryButton'] } else { $window.Resources['SecondaryButton'] }
        $b.Tag      = $value
        $b.Add_Click({ Close-ThemedDialog ([bool]$this.Tag) })
        $btns.Children.Add($b) | Out-Null
    }

    # Cancel on the left, the action on the right.
    if ($Mode -eq 'OK') {
        & $mkButton 'OK' $true $true (New-Object System.Windows.Thickness(0))
    }
    else {
        & $mkButton $NoText  $false $false (New-Object System.Windows.Thickness(0,0,5,0))
        & $mkButton $YesText $true  $true  (New-Object System.Windows.Thickness(5,0,0,0))
    }

    # Esc cancels. Enter takes the action, except on a destructive prompt.
    $dlg.Add_PreviewKeyDown({
        if ($_.Key -eq 'Escape') {
            Close-ThemedDialog $false
            $_.Handled = $true
        }
        elseif ($_.Key -eq 'Return' -and -not $script:DlgState.Danger) {
            Close-ThemedDialog $true
            $_.Handled = $true
        }
    })

    $dlg.Add_Loaded({ Show-Materialize ($script:Dlg.FindName('Root')) 0.94 })

    Start-Ease $script:Scrim ([System.Windows.UIElement]::OpacityProperty) 1 220
    $dlg.ShowDialog() | Out-Null
    Start-Ease $script:Scrim ([System.Windows.UIElement]::OpacityProperty) 0 220

    return [bool]$script:DlgState.Result
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
$Header.Add_MouseLeftButtonDown({ $window.DragMove() })
$BtnMin.Add_Click({ $window.WindowState = 'Minimized' })
$BtnClose.Add_Click({ Close-App })
$BtnExit.Add_Click({ Close-App })

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

    $confirm = Show-ThemedDialog -Title 'Delete RedM cache folders?' -YesText 'Clean Now' -NoText 'Cancel' `
        -Message "cache, server-cache and server-cache-priv will be deleted.`n`nClose RedM first so files aren't locked."
    if (-not $confirm) { Add-Log 'Operation cancelled by user.'; return }

    $BtnClean.IsEnabled = $false
    $BtnOpen.IsEnabled  = $false
    $BtnClean.Content   = "Cleaning$([char]0x2026)"
    Add-Log 'Starting cleanup...'

    foreach ($folder in $script:CacheFolders) {
        Remove-RedMFolder -FolderName $folder | Out-Null
    }

    if ($NuiCheck.IsChecked) {
        $nuiConfirm = Show-ThemedDialog -Title 'Also delete nui-storage?' -Danger `
            -YesText 'Delete It' -NoText 'Keep It' `
            -Message "You selected nui-storage. It can contain separate UI and browser storage data."
        if ($nuiConfirm) { Remove-RedMFolder -FolderName $script:NuiFolder | Out-Null }
        else { Add-Log 'INFO: nui-storage folder was not deleted.' }
    }
    else {
        Add-Log 'INFO: nui-storage option was not selected.'
    }

    Add-Log 'Cleanup complete!'
    Show-ThemedDialog -Title 'Cleanup Complete' -Mode OK `
        -Message 'RedM cache cleanup finished successfully.' | Out-Null

    $BtnClean.Content   = 'Clean RedM Cache'
    $BtnClean.IsEnabled = $true
    $BtnOpen.IsEnabled  = $true
})

$window.Add_Loaded({ Show-Materialize $script:Root })

$window.Add_ContentRendered({
    Add-Log "Ready. Running as Windows user: $env:USERNAME"
    Add-Log "Target directory: $script:TargetDir"
})

# ================================================================== run
$window.ShowDialog() | Out-Null
