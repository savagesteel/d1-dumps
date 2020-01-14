
<#

.SYNOPSIS
    Script to generate Diablo/Hellfire disc dump JSON metadata file.

.DESCRIPTION
    Script to generate Diablo/Hellfire disc dump JSON metadata file.

.PARAMETER DumpPath
    The folder containing the dump (Generated with d1-dump.ps1).

#>
Param
(
    [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [String]
    $DumpPath
)

# Check dump folder and files
if( -not (Test-Path -Path $DumpPath -PathType Container) )
{
    Write-Error -Message 'Dump folder not found. Exiting...'
    exit
}

if( -not (Test-Path -Path $DumpPath\*.bin -PathType Leaf) `
    -or -not (Test-Path -Path $DumpPath\*.cue -PathType Leaf) )
{
    Write-Error -Message 'Dump files not found. Exiting...'
    exit
}

# Objects that will be used to generate the JSON metadata file
$metadata = New-Object -TypeName System.Object
$ringCodes = New-Object -TypeName System.Object

# Gathering general information from dump folder name and user input
try
{
    $dumpFolderName = Split-Path -Path $DumpPath -Leaf
    $splitName = $dumpFolderName.Split('.')
    $game = $($splitName[0])
    $platform = $($splitName[1])
    $region = $($splitName[2])
}
catch
{
    Write-Host -Object "Failed retrieving dump game, platform and region from dump folder name '$dumpFolderName'. Exiting..." -ForegroundColor Red
    Write-Host -Object $_ -ForegroundColor Red
    exit
}

$generalText = @"
General Information
-------------------

Game: $game
Platform: $platform
Region: $region

"@

Write-Host -Object $generalText

$metadata | Add-Member -MemberType NoteProperty -Name Game -Value $game
$metadata | Add-Member -MemberType NoteProperty -Name Platform -Value $platform
$metadata | Add-Member -MemberType NoteProperty -Name Region -Value $region

$metadata | Add-Member -MemberType NoteProperty -Name Description `
    -Value (Read-Host -Prompt 'Description')

if( $platform -eq 'PSX' )
{
    $metadata | Add-Member -MemberType NoteProperty -Name CountryCodeIsoAlpha2 -Value $null
    $metadata | Add-Member -MemberType NoteProperty -Name SerialNumber `
        -Value (Read-Host -Prompt 'Serial Number')
}
else
{
    $metadata | Add-Member -MemberType NoteProperty -Name CountryCodeIsoAlpha2 `
        -Value (Read-Host -Prompt 'ISO 3166 Alpha 2 Country Code')
    $metadata | Add-Member -MemberType NoteProperty -Name SerialNumber -Value $null
}
Write-Host -Object ''

# Gathering ring codes from user input
$ringCodesText = @"
Ring Codes
----------

Example:
  Mastering Code: AD/CA 24400 19 8 <8093> S6995710
  IFPI Mastering SID Code: IFPI L488
  Engraved Stamped Mastering Code: PP1
  IFPI Mould SID Code: IFPI 8153

"@

Write-Host -Object $ringCodesText

$masteringCode = Read-Host -Prompt 'Mastering Code'
if( $masteringCode -eq '' )
{
    $masteringCode = $null
}
$ifpiMasteringSidCode = Read-Host -Prompt 'IFPI Mastering SID Code'
if( $ifpiMasteringSidCode -eq '' )
{
    $ifpiMasteringSidCode = $null
}
$engravedStampedMasteringCode = Read-Host -Prompt 'Engraved Stamped Mastering Code'
if( $engravedStampedMasteringCode -eq '' )
{
    $engravedStampedMasteringCode = $null
}
$ifpiMouldSidCode = Read-Host -Prompt 'IFPI Mould SID Code'
if( $ifpiMouldSidCode -eq '' )
{
    $ifpiMouldSidCode = $null
}

$ringCodes | Add-Member -MemberType NoteProperty -Name MasteringCode -Value $masteringCode
$ringCodes | Add-Member -MemberType NoteProperty -Name IfpiMasteringSidCode -Value $ifpiMasteringSidCode
$ringCodes | Add-Member -MemberType NoteProperty -Name EngravedStampedMasteringCode -Value $engravedStampedMasteringCode
$ringCodes | Add-Member -MemberType NoteProperty -Name IfpiMouldSidCode -Value $ifpiMouldSidCode

$metadata | Add-Member -MemberType NoteProperty -Name RingCodes -Value $ringCodes

Write-Host -Object ''

# Compute checksums
Write-Host -Object 'Generating checksums...'
$checksums = @()

$binHash = Get-FileHash -Path "$DumpPath\$Game.bin" -Algorithm SHA256
$obj = New-Object -TypeName System.Object
$obj | Add-Member -MemberType NoteProperty -Name FileName -Value "$Game.bin"
$obj | Add-Member -MemberType NoteProperty -Name Algorithm -Value 'SHA256'
$obj | Add-Member -MemberType NoteProperty -Name Hash -Value $binHash.Hash
$checksums += $obj

$cueHash = Get-FileHash -Path "$DumpPath\$Game.cue" -Algorithm SHA256
$obj = New-Object -TypeName System.Object
$obj | Add-Member -MemberType NoteProperty -Name FileName -Value "$Game.cue"
$obj | Add-Member -MemberType NoteProperty -Name Algorithm -Value 'SHA256'
$obj | Add-Member -MemberType NoteProperty -Name Hash -Value $cueHash.Hash
$checksums += $obj

$metadata | Add-Member -MemberType NoteProperty -Name Checksums -Value $checksums

# Add the dump time
try
{
    $dumpDateTime = Get-Item -Path "$DumpPath\$Game.bin" | Select-Object -ExpandProperty LastWriteTime
    $metadata | Add-Member -MemberType NoteProperty -Name DumpDateTime -Value $dumpDateTime.ToString('yyyy-MM-ddTHH:mm:sszzz')
}
catch
{
    Write-Host -Object "Failed retrieving dump date and time from file '$DumpPath\$Game.bin'. Exiting..." -ForegroundColor Red
    Write-Host -Object $_ -ForegroundColor Red
    exit
}

# Exporting to JSON
try
{
    $jsonFilesCount = Get-ChildItem -Path "$DumpPath\*.json" | Measure-Object | Select-Object -ExpandProperty Count
    $jsonFilePath = $DumpPath + '\' + $game + '.' + ('{0:d3}' -f ($jsonFilesCount+1)) + '.json'
    $metadata | ConvertTo-Json | Set-Content -Path $jsonFilePath
}
catch
{
    Write-Host -Object "Failed exporting JSON metadata to file '$jsonFilePath'. Exiting..." -ForegroundColor Red
    Write-Host -Object $_ -ForegroundColor Red
    exit
}

Write-Host -Object "`r`nMetadata exported to '$jsonFilePath'"
Write-Host -Object ($metadata | ConvertTo-Json)
