<#

.SYNOPSIS
    Script to dump Diablo/Hellfire discs with DiscImageCreator.

.DESCRIPTION
    Script to dump Diablo/Hellfire discs with DiscImageCreator.
    DiscImageCreator folder path must be in the PATH environment variable.
    The current directory is used as base path for the dumps.

.PARAMETER DriveLetter
    The CD-ROM drive letter that will be used to dump the game.

.PARAMETER Game
    The game being dumped.
    Accepted values Diablo, Hellfire.

.PARAMETER Platform
    The game platform.
    Accepted values PC, PC-Mac, PSX.

.PARAMETER Region
    The game region.
    Accepted values NA, EU, PAL, NTSC, NTSC-J.

#>
Param
(
    [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateSet('A','B','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')]
    [String]
    $DriveLetter,
    [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateSet('Diablo','Diablo-Shareware','Diablo-Beta','Hellfire')]
    [String]
    $Game,
    [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateSet('PC','PC-Mac','PSX')]
    [String]
    $Platorm,
    [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateSet('NA','EU','PAL','NTSC-UC','NTSC-J')]
    [String]
    $Region
)

# Check if CD-ROM is in the drive
if( -not (Test-Path -Path "$DriveLetter`:") )
{
    Write-Host -Object 'Drive not found or CD-ROM not in the drive. Exiting...' -ForegroundColor Red
    Write-Host -Object $_ -ForegroundColor Red
    exit
}

# TODO: Check parameters (e.g. Hellfire PSX is not possible)

# Build dump folder path
$dumpFolderBasePath = '.'
$dumpFolderPath = "$dumpFolderBasePath\temp"

try
{
    if( -not (Test-Path -Path $dumpFolderPath) )
    {
        New-Item -Path $dumpFolderPath -ItemType Directory | Out-Null
    }
    else
    {
        Remove-Item -Path $dumpFolderPath\* -Recurse -Force -Confirm:$false
    }
}
catch
{
    Write-Host -Object 'Failed setting up dump folder. Exiting...' -ForegroundColor Red
    Write-Host -Object $_ -ForegroundColor Red
    exit
}

# Run Disc Image Creator
Write-Host -Object "Dumping disc..."
if( $Platorm -eq 'PSX' )
{
    DiscImageCreator cd $DriveLetter $dumpFolderPath\$Game.bin 8 /c2 /nl
}
else
{
    DiscImageCreator cd $DriveLetter $dumpFolderPath\$Game.bin 8 /c2
}

# If there were errors while dumping remove unused output files
if( $null -ne (Get-Content -Path "$dumpFolderPath\$Game`_mainError.txt") )
{
    Write-Host -Object "Errors found when dumping disc, see '$dumpFolderPath\$Game`_mainError.txt'. Exiting..." -ForegroundColor Red
    Write-Host -Object $_ -ForegroundColor Red
    exit
}
else
{
    Write-Host -Object "Successfully dumped disc to folder '$dumpFolderPath'." -ForegroundColor Green
}

# Get the volume creation time
try
{
    $volumeCreationDateTimeLine = Get-Content "$dumpFolderPath\$Game`_volDesc.txt" `
        | Where-Object -FilterScript {$_ -like '*Volume Creation Date and Time:*'} | Select-Object -First 1
    $volumeCreationDateTimeText = $volumeCreationDateTimeLine.Substring($volumeCreationDateTimeLine.Length-29)
    $volumeCreationDateTime = [System.DateTimeOffset]::ParseExact($volumeCreationDateTimeText, 'yyyy-MM-dd HH:mm:ss.ff zzz', $null)
    $volumeCreationDate = $volumeCreationDateTime.UtcDateTime.ToString('yyyy-MM-dd')
    Write-Host -Object "Volume creation date (UTC): $volumeCreationDate"
}
catch
{
    Write-Host -Object "Failed retrieving the volume creation time from '$dumpFolderPath\$Game`_volDesc.txt'. Exiting..." -ForegroundColor Red
    Write-Host -Object $_ -ForegroundColor Red
    exit
}

# Get CRC-32 of the disc image
try
{
    $hashLine = Get-Content "$dumpFolderPath\$Game`_disc.txt" | Where-Object -FilterScript {$_ -like "*<rom name=`"$Game.img`"*"}
    $discImageCrc = $hashLine.Substring($hashLine.IndexOf('crc="')+5,8).ToUpper()
    Write-Host -Object "Disc image CRC-32 hash: $discImageCrc"
}
catch
{
    Write-Host -Message "Failed retrieving CRC-32 hash from '$dumpFolderPath\$Game`_disc.txt'. Exiting..." -ForegroundColor Red
    Write-Host -Object $_ -ForegroundColor Red
    exit
}

# Build final dump folder name and path
$finalDumpFolderName = $Game + '.' + $Platorm + '.' + $Region + '.' + $volumeCreationDate + '.' + $discImageCrc
$finalDumpFolderPath = "$dumpFolderBasePath\$finalDumpFolderName"

# Check if another dump has the same CRC-32 hash
Write-Host -Object "Generated disc dump name: $finalDumpFolderName"
if( Test-Path -Path "$dumpFolderBasePath\*$discImageCrc" -PathType Container )
{
    $identicalDump = Get-ChildItem -Path "$dumpFolderBasePath\*$discImageCrc" | Select-Object -ExpandProperty Name

    $existingDiscImageChecksum = Get-FileHash -Path "$dumpFolderPath\$Game.bin"
    $discImageChecksum = Get-FileHash -Path "$dumpFolderBasePath\$identicalDump\$Game.bin"

    if( $existingDiscImageChecksum.Hash -eq $discImageChecksum.Hash )
    {
        Write-Warning -Message "Disc dump with same hash found: $identicalDump"
        Write-Warning -Message "Exiting..."
        exit
    }
}

# Create dump folder and move .bin + .cue in it
try
{
    New-Item -Path $finalDumpFolderPath -ItemType Directory | Out-Null
    Move-Item -Path "$dumpFolderPath\$Game.bin","$dumpFolderPath\$Game.cue" -Destination $finalDumpFolderPath
}
catch
{
    Write-Host -Object "Failed moving dump from '$dumpFolderPath' to '$finalDumpFolderPath'. Exiting..." -ForegroundColor Red
    Write-Host -Object $_ -ForegroundColor Red
    exit
}

Write-Host -Object "Disc dump moved successfully to '$finalDumpFolderPath'." -ForegroundColor Green    
