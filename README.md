# Diablo 1 &amp; Hellfire Disc Dumps

This project aims to inventory all existing versions of Diablo and Hellfire, including PSX versions.  
The idea is to do a raw disc image of each disc build the associated metadata files containing information about the disc.

The process relies on two PowerShell scripts:
1. `d1-dump.ps1` used to create the raw disc image (`.bin` and `.cue` files).
2. `d1-dump-metadata.ps1` used to create the associated JSON metadata file.

## 1. Dumping a disc
### 1.1 Prerequisites

The dump process is largely based on the http://redump.org project.  
The PowerShell script (`d1-dump.ps1`) used to dump a disc relies on [Disc Image Creator](https://github.com/saramibreak/DiscImageCreator) thus it needs to be downloaded and unzipped on your machine.  
This program only works with specific CD-ROM drives listed [here](http://wiki.redump.org/index.php?title=DiscImageCreator:_Optical_Disc_Drive_Compatibility). I'm using a Plextor PX-712A drive.

Then the Disc Image Creator release folder (e.g. `C:\Program Files\DiscImageCreator\Release_ANSI`) needs to be added to the `PATH` to allow the `DiscImageCreator` command to be called by `d1-dump.ps1`.

__NOTE:__ Raw disc image can also be created with IsoBuster or CloneCD but those software are not supported by `d1-dump.ps1`.  
Dumps can be verified by dumping the same disc with one of those two software and a different drive. 

### 1.2 Calling the PowerShell script

Below two example command lines that can be used to dump a disc.

```powershell
# Dump a Diablo hybrid PC-Mac CD-ROM from North America which is inserted in drive D:
.\d1-dump.ps1 -DriveLetter D -Game Diablo -Platorm PC-Mac -Region NA

# Dump a Hellfire PC CD-ROM from Europe which is inserted in drive D:
.\d1-dump.ps1 -DriveLetter D -Game Hellfire -Platorm PC -Region EU

# Dump a Hellfire PC CD-ROM from Japan which is inserted in drive E:
.\d1-dump.ps1 -DriveLetter E -Game Diablo -Platorm PSX -Region NTSC-J
```

__NOTE:__ The script has been tested with PowerShell 5.1 (Default version included in Windows 10).

### 1.3 Folder structure

When calling the script Disc Image Creator is run to dump the disc as `.bin` + `.cue` in the `temp` folder.  
Then the checksum of the `.bin` file is calculated.  
If this checksum is unique then a folder is created with the following naming convention and the disc image is moved into it.

`<GAME>.<PLATFORM>.[<PC-REGION>|<PSX-REGION>].<VOLUME_CREATION_DATE>.<BIN_CRC32_CHECKSUM>`.

- `<GAME>` The game name.
    - `Diablo`
    - `Hellfire`
- `<PLATFORM>`
    - `PC`
    - `PC-Mac` Hybrid PC/Mac.
    - `PSX` PlayStation.
- `<PC-REGION>` The PC region of the game.
    - `NA` North America
    - `EU` Europe
- `<PSX-REGION>` The PlayStation region of the game.
    - `PAL` Europe. 
    - `NTSC-UC` NTSC-U/C, United States and Canada.
    - `NTSC-J` Japan.
- `<VOLUME_CREATION_DATE>` The volume creation date (from the disc image ISO 9660 primary volume descriptor).
- `<BIN_CRC32_CHECKSUM>` The .bin disc image file checksum (CRC-32).

Examples:

- `Diablo.PC.EU.1996-12-27.A84479A3`
- `Diablo.PC-Mac.NA.2000-10-06.142408EA`
- `Hellfire.PC.NA.1997-09-16.E52E3E85`
- `Diablo.PSX.NTSC-UC.1998-03-04.BDFCCDC3`

## 2. Generating the associated metadata file
### 2.1 Prerequisites

Before calling `d1-dump-metadata.ps1` a proper dump performed with `d1-dump.ps1` is needed.

### 2.2 Calling the PowerShell script

Below one example command line that can be used to generate a JSON metadata file for a disc dump.

```powershell
.\d1-dump-metadata.ps1 -DumpPath .\Diablo.PC.EU.1996-12-27.A84479A3
```

When launching this command the script does the following:
1. Retrieves general information about the dump from the dump folder name.
2. Ask the user to input additional information including
    - The country of the disc
    - CD-ROM ring codes (please see http://wiki.redump.org/index.php?title=Ring_Code_Guide).
3. Compute the `.bin` and `.cue` file checksums.
4. Export everything in a JSON file.

__NOTE:__ One disc image dump folder can contain mutiple JSON metadata files, one for each dump that resulted in a disc image with the same checksum.

### 2.3 JSON metadata file structure

Example JSON metadata file (Diablo PC):
```json
{
    "Game":  "Diablo",
    "Platform":  "PC-Mac",
    "Region":  "NA",
    "CountryCodeIsoAlpha2":  "US",
    "SerialNumber": null,
    "RingCodes":  {
                      "MasteringCode":  "MFG BY CREST NATIONAL - CA 33982 59 S7118810 Diablo JCPK M/W CD CN/CA",
                      "IfpiMasteringSidCode":  "IFPI LR68",
                      "EngravedStampedMasteringCode":  null,
                      "IfpiMouldSidCode":  "IFPI U8B4"
                  },
    "Checksums":  [
                      {
                          "FileName":  "Diablo.bin",
                          "Algorithm":  "SHA256",
                          "Hash":  "0136115BD45DCFC98F7DA169D6B0AC3C6F61CD7D1234D796AA5EFD038AA6C180"
                      },
                      {
                          "FileName":  "Diablo.cue",
                          "Algorithm":  "SHA256",
                          "Hash":  "9B7FF382401FC5A9E5E7AF0F4963B2B51334CE14250E40BD1A041138BF793399"
                      }
                  ],
    "DumpDateTime":  "2019-12-31T17:50:36+01:00"
}
```

Example JSON metadata file (Diablo PlayStation):
```json
{
    "Game":  "Diablo",
    "Platform":  "PSX",
    "Region":  "NTSC-UC",
    "CountryCodeIsoAlpha2":  null,
    "SerialNumber":  "SLUS-00619",
    "RingCodes":  {
                      "MasteringCode":  null,
                      "IfpiMasteringSidCode":  null,
                      "EngravedStampedMasteringCode":  null,
                      "IfpiMouldSidCode":  "IFPI 5008"
                  },
    "Checksums":  [
                      {
                          "FileName":  "Diablo.bin",
                          "Algorithm":  "SHA256",
                          "Hash":  "A68BF47E0D0E070B69E6E8864807D2CD2F94AEEB5F23D2508594ADEA4E4EE53F"
                      },
                      {
                          "FileName":  "Diablo.cue",
                          "Algorithm":  "SHA256",
                          "Hash":  "F4B4A9FA31BD98659D161E2F980EC7BB16F5E4262D225CB249909568769C990F"
                      }
                  ],
    "DumpDateTime":  "2020-01-02T23:25:51+01:00"
}
```
