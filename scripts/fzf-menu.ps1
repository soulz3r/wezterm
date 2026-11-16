$ErrorActionPreference = "Stop"

$action = "cancel"
$menuFile = $env:WEZTERM_MENU_FILE
$tab = [char]9

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
        "--color", "fg:#d3c6aa,bg:#2d353b,hl:#a7c080,fg+:#d3c6aa,bg+:#3d484d,hl+:#a7c080,info:#a7c080,prompt:#e69875,pointer:#e67e80,marker:#a7c080,border:#475258"
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
