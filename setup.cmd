@echo off
setlocal
set "ENV_SETUP_FILE=%~f0"
rem Use Windows PowerShell modules even when launched from PowerShell 7.
set "PSModulePath=%SystemRoot%\System32\WindowsPowerShell\v1.0\Modules"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$source = Get-Content -LiteralPath $env:ENV_SETUP_FILE -Raw; & ([scriptblock]::Create(($source -split '(?m)^# POWERSHELL_START\r?$', 2)[1]))"
exit /b %errorlevel%

# POWERSHELL_START
$ErrorActionPreference = 'Stop'

# Windows PowerShell's New-Item requires elevation even with Developer Mode enabled.
Add-Type @'
using System.Runtime.InteropServices;
public static class EnvSetupLinks {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.U1)]
    public static extern bool CreateSymbolicLink(string link, string target, uint flags);
}
'@

function Ensure-Directory($Path) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Link-Item($Source, $Destination) {
    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Link source does not exist: $Source"
    }
    $existing = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        if ($existing.LinkType -notin @('SymbolicLink', 'Junction')) {
            throw "$Destination already exists. Move it aside and run setup again."
        }
        if (@($existing.Target) -contains $Source) { return }
        # Delete only the link itself, including directory links and broken links.
        $existing.Delete()
    }
    $flags = 2 # SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE
    if ((Get-Item -LiteralPath $Source).PSIsContainer) { $flags = $flags -bor 1 }
    if (-not [EnvSetupLinks]::CreateSymbolicLink($Destination, $Source, $flags)) {
        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        if ($errorCode -eq 1314) {
            throw "Creating $Destination requires an Administrator terminal or Windows Developer Mode."
        }
        throw (New-Object System.ComponentModel.Win32Exception($errorCode))
    }
    Write-Host "Linked $Destination"
}

try {
    $profileRoot = [System.IO.Path]::GetFullPath($env:USERPROFILE)
    $repo = Split-Path -Parent $env:ENV_SETUP_FILE

    $agents = Join-Path $profileRoot '.agents'
    Link-Item $repo $agents

    $codex = Join-Path $profileRoot '.codex'
    Ensure-Directory $codex
    Link-Item (Join-Path $agents 'AGENTS.md') (Join-Path $codex 'AGENTS.md')
    Link-Item (Join-Path $agents 'agents') (Join-Path $codex 'agents')

    $claude = Join-Path $profileRoot '.claude'
    Ensure-Directory $claude
    Link-Item (Join-Path $agents 'AGENTS.md') (Join-Path $claude 'CLAUDE.md')
    Link-Item (Join-Path $agents 'skills') (Join-Path $claude 'skills')

    $copilot = Join-Path $profileRoot '.copilot'
    Ensure-Directory $copilot
    Link-Item (Join-Path $agents 'skills') (Join-Path $copilot 'skills')
    Link-Item (Join-Path $agents 'agents') (Join-Path $copilot 'agents')
    Write-Host 'Done!'
} catch {
    [Console]::Error.WriteLine("ERROR: " + $_.Exception.Message)
    exit 1
}
