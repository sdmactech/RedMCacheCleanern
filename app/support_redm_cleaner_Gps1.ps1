Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$TargetDir = Join-Path $env:LOCALAPPDATA 'RedM\RedM.app\data'
$CacheFolders = @('cache', 'server-cache', 'server-cache-priv')
$NuiFolder = 'nui-storage'

# Professional RedM/RDR-inspired palette
$ColorWindow      = [System.Drawing.Color]::FromArgb(18, 16, 14)
$ColorSurface     = [System.Drawing.Color]::FromArgb(30, 26, 22)
$ColorSurface2    = [System.Drawing.Color]::FromArgb(39, 34, 29)
$ColorHeader      = [System.Drawing.Color]::FromArgb(79, 24, 20)
$ColorHeaderDark  = [System.Drawing.Color]::FromArgb(48, 18, 16)
$ColorAccent      = [System.Drawing.Color]::FromArgb(143, 45, 32)
$ColorAccentHover = [System.Drawing.Color]::FromArgb(166, 57, 42)
$ColorBorder      = [System.Drawing.Color]::FromArgb(86, 69, 51)
$ColorText        = [System.Drawing.Color]::FromArgb(242, 228, 204)
$ColorTextMuted   = [System.Drawing.Color]::FromArgb(194, 171, 138)
$ColorTextSoft    = [System.Drawing.Color]::FromArgb(224, 204, 172)
$ColorLogBg       = [System.Drawing.Color]::FromArgb(12, 10, 9)
$ColorLogText     = [System.Drawing.Color]::FromArgb(219, 197, 158)

$FontTitle    = New-Object System.Drawing.Font('Segoe UI Semibold', 22, [System.Drawing.FontStyle]::Bold)
$FontHeading  = New-Object System.Drawing.Font('Segoe UI Semibold', 10.5, [System.Drawing.FontStyle]::Bold)
$FontBody     = New-Object System.Drawing.Font('Segoe UI', 9.5)
$FontSmall    = New-Object System.Drawing.Font('Segoe UI', 8.75)
$FontButton   = New-Object System.Drawing.Font('Segoe UI Semibold', 9.5, [System.Drawing.FontStyle]::Bold)
$FontLog      = New-Object System.Drawing.Font('Consolas', 9)

function Add-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $script:LogBox.AppendText("[$timestamp] $Message`r`n")
    $script:LogBox.SelectionStart = $script:LogBox.TextLength
    $script:LogBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Remove-RedMFolder {
    param([string]$FolderName)

    $folderPath = Join-Path $TargetDir $FolderName

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

function New-Panel {
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height
    )
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($X, $Y)
    $panel.Size = New-Object System.Drawing.Size($Width, $Height)
    $panel.BackColor = $ColorSurface
    $panel.BorderStyle = 'FixedSingle'
    return $panel
}

function Set-ButtonStyle {
    param(
        [System.Windows.Forms.Button]$Button,
        [System.Drawing.Color]$BackColor,
        [System.Drawing.Color]$HoverColor,
        [System.Drawing.Color]$ForeColor = $ColorText
    )
    $Button.FlatStyle = 'Flat'
    $Button.BackColor = $BackColor
    $Button.ForeColor = $ForeColor
    $Button.Font = $FontButton
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $Button.FlatAppearance.BorderSize = 1
    $Button.FlatAppearance.BorderColor = $ColorBorder
    $Button.Add_MouseEnter({ $this.BackColor = $HoverColor })
    $Button.Add_MouseLeave({ $this.BackColor = $BackColor })
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'RedM Cache Cleanup'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(760, 590)
$form.MinimumSize = New-Object System.Drawing.Size(740, 570)
$form.MaximumSize = New-Object System.Drawing.Size(760, 590)
$form.BackColor = $ColorWindow
$form.Font = $FontBody
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false

$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.Size = New-Object System.Drawing.Size(760, 122)
$headerPanel.BackColor = $ColorHeader
$form.Controls.Add($headerPanel)

$headerRule = New-Object System.Windows.Forms.Panel
$headerRule.Location = New-Object System.Drawing.Point(0, 116)
$headerRule.Size = New-Object System.Drawing.Size(760, 6)
$headerRule.BackColor = $ColorHeaderDark
$headerPanel.Controls.Add($headerRule)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'RedM Cache Cleaner'
$title.ForeColor = $ColorText
$title.Font = $FontTitle
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(30, 22)
$headerPanel.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = 'Clean RedM cache files safely for the current Windows user.'
$subtitle.ForeColor = $ColorTextSoft
$subtitle.Font = $FontBody
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(34, 70)
$headerPanel.Controls.Add($subtitle)

$statusPill = New-Object System.Windows.Forms.Label
$statusPill.Text = "USER: $env:USERNAME"
$statusPill.ForeColor = $ColorText
$statusPill.BackColor = $ColorHeaderDark
$statusPill.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 8.25, [System.Drawing.FontStyle]::Bold)
$statusPill.TextAlign = 'MiddleCenter'
$statusPill.Location = New-Object System.Drawing.Point(575, 28)
$statusPill.Size = New-Object System.Drawing.Size(130, 28)
$headerPanel.Controls.Add($statusPill)

$builtByLabel = New-Object System.Windows.Forms.Label
$builtByLabel.Text = 'Built by Slimm'
$builtByLabel.ForeColor = $ColorTextSoft
$builtByLabel.BackColor = $ColorHeader
$builtByLabel.Font = New-Object System.Drawing.Font('Segoe UI', 7.75)
$builtByLabel.TextAlign = 'MiddleRight'
$builtByLabel.Location = New-Object System.Drawing.Point(575, 59)
$builtByLabel.Size = New-Object System.Drawing.Size(130, 18)
$headerPanel.Controls.Add($builtByLabel)

$infoPanel = New-Panel -X 30 -Y 145 -Width 685 -Height 88
$form.Controls.Add($infoPanel)

$pathHeading = New-Object System.Windows.Forms.Label
$pathHeading.Text = 'Target Directory'
$pathHeading.ForeColor = $ColorText
$pathHeading.Font = $FontHeading
$pathHeading.AutoSize = $true
$pathHeading.Location = New-Object System.Drawing.Point(18, 14)
$infoPanel.Controls.Add($pathHeading)

$pathLabel = New-Object System.Windows.Forms.Label
$pathLabel.Text = $TargetDir
$pathLabel.ForeColor = $ColorTextMuted
$pathLabel.Font = $FontSmall
$pathLabel.AutoEllipsis = $true
$pathLabel.Location = New-Object System.Drawing.Point(18, 43)
$pathLabel.Size = New-Object System.Drawing.Size(645, 24)
$infoPanel.Controls.Add($pathLabel)

$optionsPanel = New-Panel -X 30 -Y 248 -Width 685 -Height 112
$form.Controls.Add($optionsPanel)

$optionsHeading = New-Object System.Windows.Forms.Label
$optionsHeading.Text = 'Cleanup Options'
$optionsHeading.ForeColor = $ColorText
$optionsHeading.Font = $FontHeading
$optionsHeading.AutoSize = $true
$optionsHeading.Location = New-Object System.Drawing.Point(18, 14)
$optionsPanel.Controls.Add($optionsHeading)

$baseCleanupLabel = New-Object System.Windows.Forms.Label
$baseCleanupLabel.Text = 'The following folders will be deleted after confirmation: cache, server-cache, server-cache-priv'
$baseCleanupLabel.ForeColor = $ColorTextSoft
$baseCleanupLabel.Font = $FontSmall
$baseCleanupLabel.AutoSize = $true
$baseCleanupLabel.Location = New-Object System.Drawing.Point(18, 44)
$optionsPanel.Controls.Add($baseCleanupLabel)

$script:DeleteNuiCheckbox = New-Object System.Windows.Forms.CheckBox
$script:DeleteNuiCheckbox.Text = 'Also delete nui-storage'
$script:DeleteNuiCheckbox.ForeColor = $ColorText
$script:DeleteNuiCheckbox.Font = $FontBody
$script:DeleteNuiCheckbox.AutoSize = $true
$script:DeleteNuiCheckbox.Location = New-Object System.Drawing.Point(18, 73)
$optionsPanel.Controls.Add($script:DeleteNuiCheckbox)

$cleanButton = New-Object System.Windows.Forms.Button
$cleanButton.Text = 'Clean RedM Cache'
$cleanButton.Size = New-Object System.Drawing.Size(180, 42)
$cleanButton.Location = New-Object System.Drawing.Point(30, 378)
Set-ButtonStyle -Button $cleanButton -BackColor $ColorAccent -HoverColor $ColorAccentHover
$form.Controls.Add($cleanButton)

$openFolderButton = New-Object System.Windows.Forms.Button
$openFolderButton.Text = 'Open RedM Folder'
$openFolderButton.Size = New-Object System.Drawing.Size(170, 42)
$openFolderButton.Location = New-Object System.Drawing.Point(224, 378)
Set-ButtonStyle -Button $openFolderButton -BackColor $ColorSurface2 -HoverColor ([System.Drawing.Color]::FromArgb(55, 48, 41))
$form.Controls.Add($openFolderButton)

$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = 'Exit'
$exitButton.Size = New-Object System.Drawing.Size(104, 42)
$exitButton.Location = New-Object System.Drawing.Point(408, 378)
Set-ButtonStyle -Button $exitButton -BackColor $ColorSurface2 -HoverColor ([System.Drawing.Color]::FromArgb(55, 48, 41))
$form.Controls.Add($exitButton)

$logPanel = New-Panel -X 30 -Y 438 -Width 685 -Height 100
$form.Controls.Add($logPanel)

$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = 'Activity Log'
$logLabel.ForeColor = $ColorText
$logLabel.Font = $FontHeading
$logLabel.AutoSize = $true
$logLabel.Location = New-Object System.Drawing.Point(18, 10)
$logPanel.Controls.Add($logLabel)

$script:LogBox = New-Object System.Windows.Forms.TextBox
$script:LogBox.Multiline = $true
$script:LogBox.ReadOnly = $true
$script:LogBox.ScrollBars = 'Vertical'
$script:LogBox.BackColor = $ColorLogBg
$script:LogBox.ForeColor = $ColorLogText
$script:LogBox.BorderStyle = 'FixedSingle'
$script:LogBox.Font = $FontLog
$script:LogBox.Location = New-Object System.Drawing.Point(18, 36)
$script:LogBox.Size = New-Object System.Drawing.Size(649, 48)
$logPanel.Controls.Add($script:LogBox)

$cleanButton.Add_Click({
    if (-not (Test-Path -LiteralPath $TargetDir)) {
        [System.Windows.Forms.MessageBox]::Show(
            "RedM data directory was not found for Windows user '$env:USERNAME'.`r`n`r`nExpected location:`r`n$TargetDir`r`n`r`nPlease verify RedM is installed and the path is correct.",
            'RedM Folder Not Found',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        Add-Log "ERROR: RedM data directory not found: $TargetDir"
        return
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to delete these folders?`r`n`r`n- cache`r`n- server-cache`r`n- server-cache-priv",
        'Confirm RedM Cache Cleanup',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
        Add-Log 'Operation cancelled by user.'
        return
    }

    $cleanButton.Enabled = $false
    $openFolderButton.Enabled = $false
    Add-Log 'Starting cleanup...'

    foreach ($folder in $CacheFolders) {
        Remove-RedMFolder -FolderName $folder | Out-Null
    }

    if ($script:DeleteNuiCheckbox.Checked) {
        $nuiConfirm = [System.Windows.Forms.MessageBox]::Show(
            "You selected nui-storage.`r`n`r`nDo you also want to delete the nui-storage folder?",
            'Confirm nui-storage Deletion',
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        if ($nuiConfirm -eq [System.Windows.Forms.DialogResult]::Yes) {
            Remove-RedMFolder -FolderName $NuiFolder | Out-Null
        }
        else {
            Add-Log 'INFO: nui-storage folder was not deleted.'
        }
    }
    else {
        Add-Log 'INFO: nui-storage option was not selected.'
    }

    Add-Log 'Cleanup complete!'
    [System.Windows.Forms.MessageBox]::Show(
        'Cleanup complete!',
        'RedM Cache Cleaner',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null

    $cleanButton.Enabled = $true
    $openFolderButton.Enabled = $true
})

$openFolderButton.Add_Click({
    if (Test-Path -LiteralPath $TargetDir) {
        Start-Process explorer.exe -ArgumentList "`"$TargetDir`""
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "RedM data directory was not found:`r`n$TargetDir",
            'Folder Not Found',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }
})

$exitButton.Add_Click({
    $form.Close()
})

$form.Add_Shown({
    Add-Log "Ready. Running as Windows user: $env:USERNAME"
    Add-Log "Target directory: $TargetDir"
})

[void]$form.ShowDialog()
