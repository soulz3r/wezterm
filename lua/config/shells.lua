local M = {}

M.git_bash = {
	"C:/Program Files/Git/bin/bash.exe",
	"--rcfile",
	"/d/config/bash/.bashrc",
	"-i",
}

M.items = {
	{ name = "Git Bash", args = M.git_bash },
	{ name = "PowerShell", args = { "pwsh.exe", "-NoLogo" } },
	{ name = "Command Prompt", args = { "cmd.exe" } },
	{ name = "Arch Linux (WSL)", args = { "wsl.exe", "-d", "Arch" } },
}

return M
