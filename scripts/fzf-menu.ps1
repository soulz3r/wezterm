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
        "fg:#a6c5a8,bg:-1,fg+:#e0f0df,bg+:#354b3c,hl:#c1d5c2,hl+:#eff8ee,info:#587360,prompt:#c1d5c2,pointer:#e0f0df,marker:#82a78a,spinner:#eff8ee,header:#82a78a,border:#587360,label:#82a78a,query:#e0f0df,gutter:-1"
    }
    "amber" {
        "fg:#d6a45d,bg:-1,fg+:#f2cf91,bg+:#51402b,hl:#9fbd78,hl+:#c5e39a,info:#80633c,prompt:#9fbd78,pointer:#f2cf91,marker:#b88748,spinner:#c5e39a,header:#b88748,border:#80633c,label:#b88748,query:#f2cf91,gutter:-1"
    }
    "oxide" {
        "fg:#83b5a3,bg:-1,fg+:#b4d8c4,bg+:#2d4943,hl:#c58b67,hl+:#e0ad83,info:#496b61,prompt:#c58b67,pointer:#b4d8c4,marker:#628f7c,spinner:#e0ad83,header:#628f7c,border:#496b61,label:#628f7c,query:#b4d8c4,gutter:-1"
    }
    default {
        "fg:#9acb78,bg:-1,fg+:#c4e6a0,bg+:#344b32,hl:#d6a45d,hl+:#efc477,info:#58734a,prompt:#d6a45d,pointer:#c4e6a0,marker:#79a85b,spinner:#efc477,header:#79a85b,border:#58734a,label:#79a85b,query:#c4e6a0,gutter:-1"
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
