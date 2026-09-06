[CmdletBinding()]
param(
    [switch]$Apply,
    [switch]$Check
)

$ErrorActionPreference = 'Stop'

$stcopRoot = Split-Path -Parent $PSScriptRoot
$addonsRoot = Split-Path -Parent $stcopRoot
$sgmRoot = Join-Path $addonsRoot 'ixray-sgm'

$sgmUpgradeRoot = Join-Path $sgmRoot 'configs\weapons\upgrades'
$stcopUpgradeRoot = Join-Path $stcopRoot 'configs\weapons\stcop\upgrades\families'
$stcopPatchRoot = Join-Path $stcopRoot 'configs\weapons\stcop\patches\upgrades'

foreach ($requiredPath in @($sgmUpgradeRoot, $stcopUpgradeRoot, $stcopPatchRoot)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Container)) {
        throw "Required upgrade directory is missing: $requiredPath"
    }
}

# LTX files in the inherited SGM data may use an 8-bit legacy encoding. Latin-1
# is used intentionally as a byte-preserving transport because every token that
# this tool reads or changes is ASCII. Non-ASCII comments remain byte-identical.
$byteEncoding = [System.Text.Encoding]::Latin1
$invariantCulture = [System.Globalization.CultureInfo]::InvariantCulture
$floatStyle = [System.Globalization.NumberStyles]::Float

$percentProperties = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@(
        'prop_reliability',
        'prop_bullet_speed',
        'prop_rpm',
        'prop_rpm, prop_autofire',
        'prop_recoil',
        'prop_dispersion',
        'prop_dispersion, prop_no_buck',
        'prop_inertion'
    ),
    [System.StringComparer]::Ordinal
)

function Get-LtxText {
    param([Parameter(Mandatory)][string]$Path)

    return $byteEncoding.GetString([System.IO.File]::ReadAllBytes($Path))
}

function Get-LtxLines {
    param([Parameter(Mandatory)][string]$Text)

    return [System.Text.RegularExpressions.Regex]::Matches(
        $Text,
        '[^\r\n]*(?:\r\n|\n|\r|$)'
    ) | ForEach-Object Value | Where-Object { $_.Length -gt 0 }
}

function Read-LtxSections {
    param([Parameter(Mandatory)][System.IO.FileInfo[]]$Files)

    $sections = [ordered]@{}
    foreach ($file in $Files) {
        $currentSection = $null
        foreach ($line in Get-LtxLines -Text (Get-LtxText -Path $file.FullName)) {
            $content = (($line -replace '[\r\n]+$') -replace ';.*$', '').Trim()
            if (-not $content) {
                continue
            }

            if ($content -match '^!?\[([^\]]+)\]\s*(?::\s*(.+))?$') {
                $currentSection = $matches[1].Trim()
                if (-not $sections.Contains($currentSection)) {
                    $sections[$currentSection] = [ordered]@{}
                }
                if ($matches[2]) {
                    $sections[$currentSection]['__parents'] = $matches[2].Trim()
                }
                continue
            }

            if ($null -ne $currentSection -and $content -match '^([^=]+?)\s*=\s*(.*)$') {
                $sections[$currentSection][$matches[1].Trim()] = $matches[2].Trim()
            }
        }
    }

    return $sections
}

function Merge-LtxSections {
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Base,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Overlay
    )

    $result = [ordered]@{}
    foreach ($sectionName in $Base.Keys) {
        $result[$sectionName] = $Base[$sectionName]
    }
    foreach ($sectionName in $Overlay.Keys) {
        if (-not $result.Contains($sectionName)) {
            $result[$sectionName] = [ordered]@{}
        }
        foreach ($key in $Overlay[$sectionName].Keys) {
            $result[$sectionName][$key] = $Overlay[$sectionName][$key]
        }
    }

    return $result
}

function Resolve-LtxSection {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Sections,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.HashSet[string]]$Visited
    )

    $result = [ordered]@{}
    if (-not $Sections.Contains($Name) -or $Visited.Contains($Name)) {
        return $result
    }
    [void]$Visited.Add($Name)

    $section = $Sections[$Name]
    if ($section.Contains('__parents')) {
        foreach ($parentName in ($section['__parents'] -split ',')) {
            $parent = Resolve-LtxSection -Name $parentName.Trim() -Sections $Sections -Visited $Visited
            foreach ($key in $parent.Keys) {
                $result[$key] = $parent[$key]
            }
        }
    }

    foreach ($key in $section.Keys) {
        if ($key -ne '__parents') {
            $result[$key] = $section[$key]
        }
    }
    return $result
}

function Get-EffectPropertyMap {
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Sections)

    $result = @{}
    foreach ($sectionName in $Sections.Keys) {
        $resolveArguments = @{
            Name = $sectionName
            Sections = $Sections
            Visited = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        }
        $resolved = Resolve-LtxSection @resolveArguments
        if ($resolved.Contains('section') -and $resolved.Contains('property')) {
            $result[$resolved['section']] = $resolved['property']
        }
    }
    return $result
}

function Get-NormalizedPercent {
    param([Parameter(Mandatory)][double]$Value)

    if ($Value -eq 0) {
        return 0
    }

    $magnitude = [Math]::Floor([Math]::Abs($Value) / 5) * 5
    if ($magnitude -lt 5) {
        $magnitude = 5
    }
    return [Math]::Sign($Value) * $magnitude
}

function Convert-UpgradeFile {
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$File,
        [Parameter(Mandatory)][hashtable]$EffectProperties,
        [Parameter(Mandatory)][bool]$Write
    )

    $originalText = Get-LtxText -Path $File.FullName
    $lines = @(Get-LtxLines -Text $originalText)
    $currentSection = $null
    $changed = 0

    for ($index = 0; $index -lt $lines.Count; $index++) {
        $lineWithoutEnding = $lines[$index] -replace '[\r\n]+$', ''
        $content = ($lineWithoutEnding -replace ';.*$', '').Trim()
        if ($content -match '^!?\[([^\]]+)\]') {
            $currentSection = $matches[1].Trim()
            continue
        }
        if ($null -eq $currentSection -or -not $EffectProperties.ContainsKey($currentSection)) {
            continue
        }
        if (-not $percentProperties.Contains($EffectProperties[$currentSection])) {
            continue
        }
        if ($lines[$index] -notmatch '^(\s*value\s*=\s*)([+-]?\d+(?:\.\d+)?)(\s*(?:;[^\r\n]*)?)(\r\n|\n|\r)?$') {
            continue
        }

        $value = 0.0
        if (-not [double]::TryParse($matches[2].TrimStart('+'), $floatStyle, $invariantCulture, [ref]$value)) {
            throw "Invalid numeric value in $($File.FullName): $($matches[2])"
        }
        $normalized = Get-NormalizedPercent -Value $value
        if ([Math]::Abs($value - $normalized) -lt 0.000001) {
            continue
        }

        $sign = if ($normalized -gt 0 -and $matches[2].StartsWith('+')) { '+' } else { '' }
        $lines[$index] = $matches[1] + $sign + ([Math]::Abs($normalized) * [Math]::Sign($normalized)).ToString('0', $invariantCulture) + $matches[3] + $matches[4]
        $changed++
        Write-Verbose ("{0}:{1}: {2} -> {3}" -f $File.FullName, ($index + 1), $value, $normalized)
    }

    if ($Write -and $changed -gt 0) {
        $updatedText = [string]::Concat($lines)
        [System.IO.File]::WriteAllBytes($File.FullName, $byteEncoding.GetBytes($updatedText))
    }
    return $changed
}

$sgmFiles = @(Get-ChildItem -LiteralPath $sgmUpgradeRoot -Filter 'w_*_up.ltx' -File | Sort-Object FullName)
$familyFiles = @(Get-ChildItem -LiteralPath $stcopUpgradeRoot -Filter '*.ltx' -File | Sort-Object FullName)
$patchFiles = @(Get-ChildItem -LiteralPath $stcopPatchRoot -Filter '*.ltx' -File | Sort-Object FullName)

$sgmSections = Read-LtxSections -Files $sgmFiles
$familySections = Read-LtxSections -Files $familyFiles
$patchSections = Read-LtxSections -Files $patchFiles
$stcopDefinitions = Merge-LtxSections -Base $sgmSections -Overlay $familySections
$stcopSections = Merge-LtxSections -Base $stcopDefinitions -Overlay $patchSections

$sgmEffectProperties = Get-EffectPropertyMap -Sections $sgmSections
$stcopEffectProperties = Get-EffectPropertyMap -Sections $stcopSections

$changeCount = 0
foreach ($file in $sgmFiles) {
    $changeCount += Convert-UpgradeFile -File $file -EffectProperties $sgmEffectProperties -Write $Apply
}
foreach ($file in @($familyFiles) + @($patchFiles)) {
    $changeCount += Convert-UpgradeFile -File $file -EffectProperties $stcopEffectProperties -Write $Apply
}

if ($Check -and $changeCount -gt 0) {
    throw "$changeCount weapon upgrade percentage values are not normalized"
}

Write-Output "Normalized weapon upgrade percentage values: $changeCount"
