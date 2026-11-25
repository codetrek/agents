#requires -Version 5.1
$ErrorActionPreference = 'Stop'

function Get-AbsolutePath([string] $Path) {
    if ($Path -notmatch '^(?:[A-Za-z]:[\\/]|[\\/]{2}[^\\/]+[\\/][^\\/]+)') {
        throw "Expected an absolute Windows path: $Path"
    }
    [IO.Path]::GetFullPath($Path)
}

function Find-Entry([string] $Path) {
    $parent = [IO.Path]::GetDirectoryName($Path)
    if ($parent -and [IO.Directory]::Exists($parent)) {
        # Listing the parent also finds dangling links on Windows PowerShell.
        $name = [IO.Path]::GetFileName($Path)
        Get-ChildItem -Force -LiteralPath $parent -Filter $name | Where-Object { $_.Name -ieq $name }
    }
}

function Get-LinkTarget($Entry) {
    $target = @($Entry.Target)[0]
    if (-not $target) { throw "Cannot read link target: $($Entry.FullName)" }
    if ($target.StartsWith('\??\') -or $target.StartsWith('\\?\')) {
        $target = $target.Substring(4)
        if ($target -like 'UNC\*') { $target = '\\' + $target.Substring(4) }
    }
    [IO.Path]::GetFullPath([IO.Path]::Combine($Entry.Parent.FullName, $target))
}

function Resolve-DirectoryPath([string] $Path, [int] $RemainingLinks = 32) {
    $full = Get-AbsolutePath $Path
    $resolved = [IO.Path]::GetPathRoot($full)
    if (-not [IO.Directory]::Exists($resolved)) { throw "Unavailable filesystem root: $resolved" }
    foreach ($part in $full.Substring($resolved.Length).Split('\', [StringSplitOptions]::RemoveEmptyEntries)) {
        $resolved = [IO.Path]::Combine($resolved, $part)
        $entry = Find-Entry $resolved
        if ($null -eq $entry) { continue }
        if (-not $entry.PSIsContainer) { throw "Expected a directory: $resolved" }
        if ($entry.LinkType -in 'Junction', 'SymbolicLink') {
            if ($RemainingLinks -le 0) { throw "Too many directory links: $resolved" }
            $target = Resolve-DirectoryPath (Get-LinkTarget $entry) ($RemainingLinks - 1)
            if (-not [IO.Directory]::Exists($target)) { throw "Dangling parent directory: $resolved" }
            $resolved = $target
        }
    }
    $resolved
}

# Resolve parent aliases (such as .agents -> .env/.agents), keeping the final
# name even when the link that will occupy it has not been installed yet.
function Get-SlotPath([string] $Path) {
    $name = [IO.Path]::GetFileName($Path.TrimEnd('\'))
    if (-not $name) { throw "Expected a named directory: $Path" }
    $parent = Resolve-DirectoryPath ([IO.Path]::GetDirectoryName($Path.TrimEnd('\')))
    [IO.Path]::Combine($parent, $name)
}

function Test-Installed($Link) {
    $entry = Find-Entry $Link.Path
    if ($null -eq $entry) { return $false }
    if ($entry.PSIsContainer -and $entry.LinkType -in 'Junction', 'SymbolicLink') {
        $target = (Get-LinkTarget $entry).TrimEnd('\')
        if ($target -ieq $Link.Target -or (Get-SlotPath $target) -ieq $Link.Expected) { return $true }
    }
    throw "Path already in use; move it aside before installing: $($Link.Path)"
}

$profileRoot = Get-AbsolutePath $env:USERPROFILE
$catalog = Resolve-DirectoryPath (Join-Path $PSScriptRoot 'skills')
$skills = @(Get-ChildItem -LiteralPath $catalog -Directory | Where-Object {
    -not $_.Name.StartsWith('.') -and [IO.File]::Exists((Join-Path $_.FullName 'SKILL.md'))
})
if ($skills.Count -eq 0) { throw "No skills found in $catalog" }

$agents = Join-Path $profileRoot '.agents'
$legacy = Join-Path $profileRoot '.env\.agents'
$adoptLegacy = -not (Find-Entry $agents) -and [IO.Directory]::Exists($legacy)
$agentsDir = if ($adoptLegacy) { Resolve-DirectoryPath $legacy } else { Resolve-DirectoryPath $agents }
$shared = Join-Path $agentsDir 'skills'
$sharedPath = Join-Path $agents 'skills'
$tools = @('.claude', '.copilot') | ForEach-Object { Get-SlotPath (Join-Path $profileRoot "$_\skills") } | Sort-Object -Unique
$tools = @($tools | Where-Object { $_ -ine $shared -and $_ -ine $catalog })

# A redirected tool directory must not install a link inside its own target.
$slots = @(@($catalog, $shared) + $tools | Sort-Object -Unique)
for ($i = 0; $i -lt $slots.Count; $i++) {
    for ($j = $i + 1; $j -lt $slots.Count; $j++) {
        $left = $slots[$i]
        $right = $slots[$j]
        if ($left.StartsWith($right + '\', [StringComparison]::OrdinalIgnoreCase) -or
            $right.StartsWith($left + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Incompatible skill directories overlap: $left, $right"
        }
    }
}

$links = @(
    if ($adoptLegacy) { @{ Path = $agents; Target = $legacy; Expected = $agentsDir } }
    if ($shared -ine $catalog) { @{ Path = $shared; Target = $catalog; Expected = $catalog } }
    foreach ($tool in $tools) {
        @{ Path = $tool; Target = $sharedPath; Expected = $shared }
    }
)
$missing = @($links | Where-Object { -not (Test-Installed $_) })
foreach ($link in $missing) {
    $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($link.Path))
    $null = New-Item -ItemType Junction -Path $link.Path -Target $link.Target
    Write-Output "Linked $($link.Path)"
}
