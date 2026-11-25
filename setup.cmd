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

function Test-LinkTarget($Item, $Source) {
    if ($Item.LinkType -notin @('SymbolicLink', 'Junction')) { return $false }
    $linkTarget = @($Item.Target)[0]
    if ([string]::IsNullOrEmpty($linkTarget)) { return $false }
    $parent = [System.IO.Path]::GetDirectoryName($Item.FullName)
    $target = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($parent, $linkTarget))
    return $target.TrimEnd('\') -ieq $Source
}

function New-ItemLink($Source, $Destination) {
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

function Link-Item($Source, $Destination) {
    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Link source does not exist: $Source"
    }
    $existing = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        if ($existing.LinkType -notin @('SymbolicLink', 'Junction')) {
            throw "$Destination already exists. Move it aside and run setup again."
        }
        if (Test-LinkTarget $existing $Source) { return }
        # Delete only the link itself, including directory links and broken links.
        $existing.Delete()
    }
    New-ItemLink $Source $Destination
}

try {
    $profileRoot = [System.IO.Path]::GetFullPath($env:USERPROFILE)
    $repo = Split-Path -Parent $env:ENV_SETUP_FILE
    $agents = Join-Path $profileRoot '.agents'
    $envAgents = Join-Path $profileRoot '.env\.agents'
    if (-not (Get-Item -LiteralPath $agents -Force -ErrorAction SilentlyContinue) -and
        (Test-Path -LiteralPath $envAgents -PathType Container)) {
        Link-Item $envAgents $agents
    }
    if (-not (Test-Path -LiteralPath $agents -PathType Container)) {
        Ensure-Directory $agents
    }

    $catalog = Join-Path $repo 'skills'
    $skills = Join-Path $agents 'skills'
    if ($catalog -ine $skills) { Link-Item $catalog $skills }

    $claude = Join-Path $profileRoot '.claude'
    Ensure-Directory $claude
    Link-Item $skills (Join-Path $claude 'skills')

    $copilot = Join-Path $profileRoot '.copilot'
    Ensure-Directory $copilot
    Link-Item $skills (Join-Path $copilot 'skills')
    Write-Host 'Done!'
} catch {
    [Console]::Error.WriteLine("ERROR: " + $_.Exception.Message)
    exit 1
}
