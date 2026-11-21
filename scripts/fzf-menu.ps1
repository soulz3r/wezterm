$ErrorActionPreference = "Stop"

$action = "cancel"
$menuFile = $env:WEZTERM_MENU_FILE
$tab = [char]9

$variant = if ([string]::IsNullOrWhiteSpace($env:WEZTERM_MINMAX_VARIANT)) {
    "phosphor"
} else {
    $env:WEZTERM_MINMAX_VARIANT.ToLowerInvariant()
}

$fzfColors = switch ($variant) {
    "mono" {
        "fg:#a6c5a8,bg:-1,fg+:#e0f0df,bg+:#354b3c,hl:#c1b99b,hl+:#eff0df,info:#8497a8,prompt:#c1b99b,pointer:#b0d0cb,marker:#82a78a,spinner:#cbb4c2,header:#8497a8,border:#587360,label:#83aaa7,query:#e0f0df,gutter:-1"
    }
    "amber" {
        "fg:#d6a45d,bg:-1,fg+:#f2cf91,bg+:#51402b,hl:#d6a45d,hl+:#f2cf91,info:#7895b5,prompt:#d6a45d,pointer:#a3d0c8,marker:#9fbd78,spinner:#d5a0a0,header:#7895b5,border:#80633c,label:#78aaa4,query:#f2cf91,gutter:-1"
    }
    "oxide" {
        "fg:#83b5a3,bg:-1,fg+:#b4d8c4,bg+:#2d4943,hl:#c58b67,hl+:#e0ad83,info:#789caf,prompt:#c58b67,pointer:#a6d8ce,marker:#628f7c,spinner:#d0a4bc,header:#789caf,border:#496b61,label:#78b9b3,query:#b4d8c4,gutter:-1"
    }
    default {
        "fg:#9acb78,bg:-1,fg+:#c4e6a0,bg+:#344b32,hl:#d6a45d,hl+:#efc477,info:#7896b8,prompt:#d6a45d,pointer:#a4d8cf,marker:#79a85b,spinner:#d5a9c4,header:#7896b8,border:#58734a,label:#78b8b0,query:#c4e6a0,gutter:-1"
    }
}

try {
    if ([string]::IsNullOrWhiteSpace($menuFile)) {
        throw "WEZTERM_MENU_FILE was not provided by the WezTerm configuration."
    }

    if (-not (Test-Path -LiteralPath $menuFile -PathType Leaf)) {
        throw "The fzf menu data file does not exist: $menuFile"
    }

    $fzf = Get-Command "fzf.exe" -ErrorAction Stop
    $items = Get-Content -LiteralPath $menuFile -Raw -Encoding UTF8 | ConvertFrom-Json

    $rows = foreach ($item in $items) {
        if ($null -ne $item.label -and $null -ne $item.id) {
            $label = [string]$item.label
            $label = $label -replace "[`t`r`n]", " "
            "$label$tab$($item.id)"
        }
    }

    if (-not $rows) {
        throw "The fzf menu contains no usable entries."
    }

    $fzfArgs = @(
        "--height", "100%",
        "--layout", "reverse",
        "--border", "rounded",
        "--padding", "1,2",
        "--info", "inline",
        "--prompt", "wezterm > ",
        "--pointer", ">",
        "--marker", "|",
        "--delimiter", "$tab",
        "--with-nth", "1",
        "--no-multi",
        "--cycle",
        "--ansi",
        "--color", $fzfColors
    )

    $selected = $rows | & $fzf.Source @fzfArgs

    if ($LASTEXITCODE -eq 0 -and $selected) {
        $parts = $selected -split [regex]::Escape("$tab"), 2
        if ($parts.Count -eq 2 -and -not [string]::IsNullOrWhiteSpace($parts[1])) {
            $action = $parts[1]
        }
    }
}
catch {
    Write-Host ""
    Write-Host "  fzf menu failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Check that fzf.exe is on PATH and the menu file is readable." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 1200
}
finally {
    try {
        $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($action))
        [Console]::Write("$([char]27)]1337;SetUserVar=WEZTERM_MENU_ACTION=$encoded$([char]7)")
        [Console]::Out.Flush()
        Start-Sleep -Milliseconds 150
    }
    catch {
        # The WezTerm pane may already have closed; there is nothing left to notify.
    }
}
