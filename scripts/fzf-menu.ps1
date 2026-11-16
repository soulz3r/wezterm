$ErrorActionPreference = "Stop"

try {
    $fzf = Get-Command "fzf.exe" -ErrorAction Stop
    $items = Get-Content -LiteralPath $env:WEZTERM_MENU_FILE -Raw | ConvertFrom-Json
    $tab = [char]9
    $rows = foreach ($item in $items) {
        "$($item.label)$tab$($item.id)"
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
        $action = ($selected -split [regex]::Escape("$tab"), 2)[1]
    }
    else {
        $action = "cancel"
    }

    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($action))
    [Console]::Write("$([char]27)]1337;SetUserVar=WEZTERM_MENU_ACTION=$encoded$([char]7)")
    Start-Sleep -Milliseconds 1200
}
catch {
    Write-Host ""
    Write-Host "  fzf menu failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Install fzf and ensure fzf.exe is available on PATH." -ForegroundColor Yellow
    Read-Host "  Press Enter to close"
}
