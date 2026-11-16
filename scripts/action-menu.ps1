param(
    [Parameter(Mandatory = $true)][int]$TargetPaneId,
    [ValidateSet("all", "shells")][string]$Mode = "all",
    [Parameter(Mandatory = $true)][string]$WezTermExe
)

$ErrorActionPreference = "Stop"
$script:Target = "$TargetPaneId"
$script:MenuPane = $env:WEZTERM_PANE
$script:Projects = "D:\projects\"
$script:FzfExe = (Get-Command "fzf.exe" -ErrorAction Stop).Source

function Invoke-Wez {
    param([string[]]$ArgsList)
    & $script:WezTermExe cli @ArgsList
    if ($LASTEXITCODE -ne 0) {
        throw "WezTerm command failed: cli $($ArgsList -join ' ')"
    }
}

function Add-Item {
    param([System.Collections.Generic.List[string]]$List, [string]$Label, [string]$Action)
    [void]$List.Add($Label + [char]9 + $Action)
}

function Pick {
    param([string[]]$Items, [string]$Prompt = "wezterm > ")
    $Items | & $script:FzfExe --height "80%" --layout reverse --border rounded --padding "1,2" --info inline --prompt $Prompt --pointer ">" --marker "|" --no-multi --delimiter ([string][char]9) --with-nth "1" --color "fg:#d3c6aa,bg:#2d353b,hl:#a7c080,fg+:#d3c6aa,bg+:#3d484d,hl+:#a7c080,info:#a7c080,prompt:#e69875,pointer:#e67e80,marker:#a7c080,border:#475258"
}

function Confirm {
    param([string]$Message)
    $answer = Pick @("Cancel" + [char]9 + "no", "Confirm" + [char]9 + "yes") ($Message + " > ")
    return ($answer -and $answer.EndsWith(([string][char]9) + "yes"))
}

function Launch-Shell {
    param([string]$Kind, [string]$Place = "tab")
    $base = @("spawn", "--pane-id", $script:Target)
    if ($Place -eq "window") { $base += "--new-window" }
    $base += @("--cwd", $script:Projects, "--")
    switch ($Kind) {
        "pwsh" { $base += @("pwsh.exe", "-NoLogo") }
        "cmd"  { $base += "cmd.exe" }
        "arch" { $base += @("wsl.exe", "-d", "Arch") }
    }
    Invoke-Wez $base
}

function Run-Action {
    param([string]$Action, [object[]]$Rows, [object]$TargetRow)

    switch -Regex ($Action) {
        "^shell:(pwsh|cmd|arch):(tab|window)$" {
            Launch-Shell $Matches[1] $Matches[2]
            break
        }
        "^shell:(pwsh|cmd|arch):split$" {
            $kind = $Matches[1]
            $args = @("split-pane", "--pane-id", $script:Target, "--right", "--")
            switch ($kind) {
                "pwsh" { $args += @("pwsh.exe", "-NoLogo") }
                "cmd"  { $args += "cmd.exe" }
                "arch" { $args += @("wsl.exe", "-d", "Arch") }
            }
            Invoke-Wez $args
            break
        }
        "^tab:(\d+)$" {
            Invoke-Wez @("activate-tab", "--pane-id", $script:Target, "--tab-id", $Matches[1])
            break
        }
        "^tab:rename$" {
            $name = Read-Host "New tab title"
            if (-not [string]::IsNullOrWhiteSpace($name)) {
                Invoke-Wez @("set-tab-title", "--pane-id", $script:Target, $name)
            }
            break
        }
        "^tab:close$" {
            if (Confirm "Close this tab and all its panes?") {
                $paneIds = @($Rows | Where-Object { $_.tab_id -eq $TargetRow.tab_id } | ForEach-Object { "$($_.pane_id)" })
                foreach ($id in $paneIds) { Invoke-Wez @("kill-pane", "--pane-id", $id) }
            }
            break
        }
        "^window:rename$" {
            $name = Read-Host "New window title"
            if (-not [string]::IsNullOrWhiteSpace($name)) {
                Invoke-Wez @("set-window-title", "--pane-id", $script:Target, $name)
            }
            break
        }
        "^pane:split:(left|right|top|bottom)$" {
            Invoke-Wez @("split-pane", "--pane-id", $script:Target, "--$($Matches[1])")
            break
        }
        "^pane:focus:(left|right|up|down|next|prev)$" {
            Invoke-Wez @("activate-pane-direction", "--pane-id", $script:Target, $Matches[1])
            break
        }
        "^pane:resize:(left|right|up|down)$" {
            Invoke-Wez @("adjust-pane-size", "--pane-id", $script:Target, "--amount", "5", $Matches[1])
            break
        }
        "^pane:zoom$" {
            Invoke-Wez @("zoom-pane", "--pane-id", $script:Target, "--toggle")
            break
        }
        "^pane:close$" {
            if (Confirm "Close the current pane?") {
                Invoke-Wez @("kill-pane", "--pane-id", $script:Target)
            }
            break
        }
        "^workspace:rename$" {
            $name = Read-Host "New workspace name"
            if (-not [string]::IsNullOrWhiteSpace($name)) {
                Invoke-Wez @("rename-workspace", "--pane-id", $script:Target, $name)
            }
            break
        }
        "^workspace:new:(pwsh|arch)$" {
            $name = Read-Host "New workspace name"
            if (-not [string]::IsNullOrWhiteSpace($name)) {
                $kind = $Matches[1]
                $args = @("spawn", "--pane-id", $script:Target, "--new-window", "--workspace", $name, "--cwd", $script:Projects, "--")
                if ($kind -eq "arch") { $args += @("wsl.exe", "-d", "Arch") }
                else { $args += @("pwsh.exe", "-NoLogo") }
                Invoke-Wez $args
            }
            break
        }
        "^scrollback:copy$" {
            $text = Invoke-Wez @("get-text", "--pane-id", $script:Target, "--start-line", "-10000")
            $selected = $text | & $script:FzfExe --height "85%" --layout reverse --border rounded --prompt "scrollback > " --pointer ">" --multi --no-sort --color "fg:#d3c6aa,bg:#2d353b,hl:#a7c080,fg+:#d3c6aa,bg+:#3d484d,hl+:#a7c080,prompt:#e69875,pointer:#e67e80,border:#475258"
            if ($selected) { $selected | Set-Clipboard }
            break
        }
    }
}

try {
    $rows = @(Invoke-Wez @("list", "--format", "json") | ConvertFrom-Json)
    $targetRow = $rows | Where-Object { "$($_.pane_id)" -eq $script:Target } | Select-Object -First 1
    if (-not $targetRow) { throw "The pane that opened this menu no longer exists." }

    $items = [System.Collections.Generic.List[string]]::new()
    Add-Item $items "Shells / PowerShell" "shell:pwsh:tab"
    Add-Item $items "Shells / Command Prompt" "shell:cmd:tab"
    Add-Item $items "Shells / Arch Linux (WSL)" "shell:arch:tab"

    if ($Mode -eq "all") {
        Add-Item $items "Shells / PowerShell in new window" "shell:pwsh:window"
        Add-Item $items "Shells / Arch Linux in new window" "shell:arch:window"
        Add-Item $items "Shells / PowerShell split" "shell:pwsh:split"
        Add-Item $items "Shells / Command Prompt split" "shell:cmd:split"
        Add-Item $items "Shells / Arch Linux split" "shell:arch:split"

        Add-Item $items "Tabs / Rename current tab" "tab:rename"
        Add-Item $items "Tabs / Close current tab" "tab:close"
        Add-Item $items "Windows / Rename current window" "window:rename"

        foreach ($direction in @("left", "right", "top", "bottom")) {
            $label = switch ($direction) {
                "top" { "above" }
                "bottom" { "below" }
                default { $direction }
            }
            Add-Item $items "Panes / Split $label" "pane:split:$direction"
        }
        foreach ($direction in @("left", "right", "up", "down", "next", "prev")) {
            Add-Item $items "Panes / Focus $direction" "pane:focus:$direction"
        }
        foreach ($direction in @("left", "right", "up", "down")) {
            Add-Item $items "Panes / Resize $direction" "pane:resize:$direction"
        }
        Add-Item $items "Panes / Toggle zoom" "pane:zoom"
        Add-Item $items "Panes / Close current pane" "pane:close"

        Add-Item $items "Workspaces / Rename current workspace" "workspace:rename"
        Add-Item $items "Workspaces / New PowerShell workspace" "workspace:new:pwsh"
        Add-Item $items "Workspaces / New Arch Linux workspace" "workspace:new:arch"
        Add-Item $items "Scrollback / Search and copy lines" "scrollback:copy"

        $rows |
            Where-Object { $_.window_id -eq $targetRow.window_id } |
            Group-Object tab_id |
            ForEach-Object {
                $tabId = [int]$_.Name
                if ($tabId -ne $targetRow.tab_id) {
                    $pane = $_.Group | Select-Object -First 1
                    $title = [string]$pane.title
                    if ([string]::IsNullOrWhiteSpace($title)) { $title = "Tab $tabId" }
                    Add-Item $items "Tabs / Switch > $title" "tab:$tabId"
                }
            }
    }

    $selection = Pick $items.ToArray()
    if ($selection) {
        $action = $selection.Split([char]9, 2)[1]
        Run-Action $action $rows $targetRow
    }
}
catch {
    Write-Host ""
    Write-Host "  action menu: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "  Press Enter to close"
}
finally {
    if ($script:MenuPane) {
        & $script:WezTermExe cli kill-pane --pane-id $script:MenuPane 2>$null | Out-Null
    }
}
