#requires -Version 5.1
$ErrorActionPreference = 'Stop'

Add-Type -Name DirectoryLink -Namespace AgentSetup -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("kernel32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode, SetLastError = true)]
[return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.U1)]
public static extern bool CreateSymbolicLink(string path, string target, uint flags);
'@

function Install-DirectoryLink([string] $Path, [string] $Target) {
    if (-not [IO.Directory]::Exists($Target)) { throw "Missing skill directory: $Target" }
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($item) {
        switch ($item.LinkType) {
            'SymbolicLink' { break }
            'Junction' { break }
            default { throw "Path already exists: $Path" }
        }
        if ($Target -in $item.Target) { return }
        $item.Delete()
    }
    # Directory link; allow unprivileged creation when Developer Mode is enabled.
    if (-not [AgentSetup.DirectoryLink]::CreateSymbolicLink($Path, $Target, 3)) {
        $code = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw "Cannot link ${Path}: $([ComponentModel.Win32Exception]::new($code).Message)"
    }
}

$profilePath = [IO.Path]::GetFullPath($env:USERPROFILE)
$agents = Join-Path $profilePath '.agents'
$dotfilesAgents = Join-Path $profilePath '.env\.agents'
if (-not (Get-Item -LiteralPath $agents -Force -ErrorAction SilentlyContinue) -and
    [IO.Directory]::Exists($dotfilesAgents)) {
    Install-DirectoryLink $agents $dotfilesAgents
}
$null = [IO.Directory]::CreateDirectory($agents)

$catalog = Join-Path $PSScriptRoot 'skills'
$shared = Join-Path $agents 'skills'
if ($shared -ine $catalog) { Install-DirectoryLink $shared $catalog }

foreach ($client in '.claude', '.copilot') {
    $directory = Join-Path $profilePath $client
    $null = [IO.Directory]::CreateDirectory($directory)
    Install-DirectoryLink (Join-Path $directory 'skills') $shared
}
Write-Output 'Done!'
