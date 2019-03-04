<#
.SYNOPSIS
    Wrapper-Skript f�r PeterPawns EVA-Tools PowerShell-Skripte

.DESCRIPTION
    PowerShell-Skript zum flashen von FRITZ!Boxen �ber den Bootloader
    mittels der im freetz erstellten *.image.in-memory. oder kernel.image
    Dieses Skript ben�tigt die EVA-Tools aus PeterPawns GitHup-Repository

.NOTES
    Filename: FreetzTheBox.ps1

.EXAMPLE
    NAND-Boxen
    .\FreetzTheBox.ps1 -BoxType 3490 -ImageFile .\example.image.in-memory

    NOR-Boxen
    .\FreetzTheBox.ps1 -BoxType 4040 -ImageFile .\kernel.image

.PARAMTER BoxType
    Der Name der Fritz!Box

.PARAMTER ImageFile
    Die image-Datei, welche in den Bootloader der FRITZ!Box geschrieben werden soll. Vgl. hierzu "EXAMPLE"

.LINK
    https://github.com/PeterPawn/YourFritz/tree/master/eva_tools

#>

#####################################################################


Param([Parameter(Mandatory = $True, Position = 0, HelpMessage = 'Fritz!Box-Type e.g. 3490')][int]$BoxType,
      [Parameter(Mandatory = $True, Position = 1, HelpMessage = 'The imagefile to load in the bootloader')][string]$ImageFile
    )

$NAND_Box = @(3390, 3490, 6820);
$NOR_Box = @(4040);
$Box_IP = '169.254.172.1';
$Flash_Type = '';

# Ist der Fritz!Box-Typ �bergeben worden?
if (-not $BoxType)
    {
    Write-Error -Message "Fritz!Box-Typ nicht angegeben, ggf. Hilfe/Readme lesen!" -Category NotSpecified;
    Exit 1;
    }

# ist die Variable BoxType in den Arrays zu finden?
if (-not ($NAND_Box -match $BoxType) -and -not ($NOR_Box -match $BoxType))
    {
    Write-Error -Message "Der angegebene Fritz!Box-Typ wird derzeit nicht unterst�tzt" -Category InvalidData;
    exit 1;
    }

# Ist die Image-Datei angegeben worden und gibt es sie tats�chlich?
if (-not (Test-Path $ImageFile))
    {
    Write-Error -Message "Dateiname $ImageFile nicht gefunden!" -Category ObjectNotFound;
    Exit 1;
    }

# �bergebene Image-Datei in einen absoluten Pfad umwandeln
$ImageFile = Resolve-Path $ImageFile;

#########################################################
#
# Skript-Aufruf von .\EVA-Discover.ps1
#

Write-Output "Bitte die FRITZ!Box nun an den Strom anschliessen...";

if (-not (.\EVA-Discover.ps1 -maxWait 60 $Box_IP -Debug -Verbose))
    {
    Write-Error -Message "Keine FRITZ!Box gefunden!" -Category DeviceError;
    Exit 1;
    }


#########################################################
#
# Skript-Aufruf von .\EVA-FTP-Client.ps1
# f�r NAND-Boxen:

if ($NAND_Box -match $BoxType)
    {
    if (-not (.\EVA-FTP-Client.ps1 $Box_IP -ScriptBlock { BootDeviceFromImage $ImageFile } -Debug -Verbose))
        {
        Write-Error -Message "Es ist ein Fehler beim flashen der NAND-Box $BoxType aufgetreten!" -Category InvalidOperation;
        Exit 1;
        }
    }

# f�r NOR-Boxen:

if ($NOR_Box -match $BoxType)
    {
    if (-not (.\EVA-FTP-Client.ps1 $Box_IP -ScriptBlock { UploadFlashFile $ImageFile mtd1 } -Debug -Verbose))
        {
        Write-Error -Message "Es ist ein Fehler beim flashen der NOR-Box $BoxType aufgetreten!" -Category InvalidOperation;
        exit 1;
        }
    .\EVA-FTP-Client.ps1 $Box_IP -ScriptBlock { RebootTheDevice } -Debug -Verbose;
    }

# Skript beenden
Exit 0;