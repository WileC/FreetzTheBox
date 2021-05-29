<#
.SYNOPSIS
    Wrapper-Skript f�r PeterPawns EVA-Tools PowerShell-Skripte

.DESCRIPTION
    PowerShell-Skript zum flashen von FRITZ!Boxen �ber den Bootloader
    mittels der im freetz erstellten *.image-Datei. Liegt bereits ein in-memory-Image
    vor, so muss der Paramter "-isbootable" verwendet werden.
    Dieses Skript ben�tigt die EVA-Tools aus PeterPawns GitHup-Repository

.NOTES
    Filename: FreetzTheBox.ps1

.EXAMPLE
    .\FreetzTheBox.ps1 -BoxType 3490 -ImageFile .\example.image [-isbootable]

.PARAMTER BoxType
    Der Name der Fritz!Box

.PARAMTER ImageFile
    Die Image-Datei, welche in den Bootloader der FRITZ!Box geschrieben werden soll. Vgl. hierzu "EXAMPLE"

.LINK
    https://github.com/PeterPawn/YourFritz

#>

#####################################################################
##
## Parameter-Definitionen

Param([Parameter(Mandatory = $True, HelpMessage = 'Fritz!Box-Type e.g. 3490')][int]$BoxType,
      [Parameter(Mandatory = $True, HelpMessage = 'The imagefile to load in the bootloader')][string]$ImageFile,
      [Parameter(Mandatory = $False, HelpMessage = 'Is it an in-memory image?')][bool]$bootableImage=$false
    )


## Variablen-Definitonen
$SupportedBoxesArray = @{3390="NAND";3490="NAND";4020="NOR";4040="NOR";6820="NAND";6890="NAND";7590="NAND"};
$Box_IP = '169.254.1.1';
$BoxMemory = $NULL;


# Ist die angegebene Box im Array enthalten? Wenn nein, dann Skript-Abbruch!
if ( -not $SupportedBoxesArray.ContainsKey($BoxType) )
    {
        Write-Error -Message "Der angegebene Fritz!Box-Typ wird derzeit nicht unterst�tzt" -Category InvalidData -ErrorAction Stop;
        }

Write-Verbose -message "ERFOLG: Die angegebene FRITZ!Box $BoxType wird unterst�tzt.";


# Ist die Image-Datei angegeben worden und gibt es sie tats�chlich?
if (-not $(Test-Path $ImageFile))
    {
    Write-Error -Message "Dateiname $ImageFile nicht gefunden!" -Category ObjectNotFound -ErrorAction Stop;
    }
    
Write-Verbose -message "ERFOLG: Die Image-Datei wurde korrekt angeben und ist vorhanden.";
Write-Verbose -message "";


#########################################################
#
# Image-Datei f�r's flashen vorbereiten
#

# Toolbox f�r die Image-Dateien von PeterPawn aufrufen
. $pwd\FirmwareImage.ps1


# Image-Dateien festlegen
$NORBootImageFile = "$pwd\Images\$((Get-Item $ImageFile).BaseName).NOR_bootable.image";
$NANDBootImageFile = "$pwd\Images\$((Get-Item $ImageFile).BaseName).NAND_bootable.image";

Write-Verbose -message "Variable NORBootImageFile: $NORBootImageFile";
Write-Verbose -message "Variable NANDBootImageFile: $NANDBootImageFile";


#########################################################
#
# Skript-Aufruf von .\EVA-Discover.ps1
#

Write-Output "Bitte die FRITZ!Box nun an den Strom anschlie�en...";

if (-not $(.\EVA-Discover.ps1 -maxWait 120 $Box_IP -Verbose -Debug))
    {
    Write-Error -Message "Keine FRITZ!Box gefunden!" -Category DeviceError -ErrorAction Stop
    }

Write-Verbose -message "ERFOLG: die FRITZ!Box $BoxType wurde im Bootloader angehalten.";


########################################################
#
# Skript-Aufruf von .\EVA-FTP-Client.ps1, je nach Speicherart
# und Flash-Vorgang
#

switch ($SupportedBoxesArray[$BoxType]) 
    {
        "NOR" { Write-Verbose -message "Starte Flash-Vorgang f�r NOR-Boxen...";
                Write-Verbose -message "";

                if ( $(Test-Path $NORBootImageFile) ) { Remove-Item $NORBootImageFile -Verbose; }
               
                [FirmwareImage]::new($ImageFile).extractMemberAndRemoveChecksum("./var/tmp/kernel.image", $NORBootImageFile);
             
                if (-not (.\EVA-FTP-Client.ps1 -Address $Box_IP -ScriptBlock { UploadFlashFile $NORBootImageFile mtd1 } -Verbose -Debug))
                    {
                    Write-Error -Message "Es ist ein Fehler beim upload der Image-Datei aufgetreten!" -Category InvalidOperation -ErrorAction Stop;
                    }

                if (-not (.\EVA-FTP-Client.ps1 -Address $Box_IP -ScriptBlock { RebootTheDevice } -Verbose -Debug))
                    {
                    Write-Error -Message "Es ist ein Fehler beim Reboot-Command aufgetreten!" -Category InvalidOperation -ErrorAction Stop;
                    }
                break;
              }

        "NAND" { Write-Verbose -message "Starte Flash-Vorgang f�r NAND-Boxen...";
                 Write-Verbose -message "";
                  
                 if ( $(Test-Path $NANDBootImageFile) ) { Remove-Item $NANDBootImageFile -Verbose; }

                 [FirmwareImage]::new($ImageFile).getBootableImage($NANDBootImageFile);
                 
                 if (-not (.\EVA-FTP-Client.ps1 -Address $Box_IP -ScriptBlock { SwitchSystem } -Verbose -Debug))
                    {
                    Write-Error -Message "Es ist ein Fehler beim �ndern der aktiven Partition aufgetreten!" -Category InvalidOperation -ErrorAction Stop;
                    }
 
                 if (-not (.\EVA-FTP-Client.ps1 -Address $Box_IP -ScriptBlock { BootDeviceFromImage $NANDBootImageFile 0 } -Verbose -Debug))
                    {
                    Write-Error -Message "Es ist ein Fehler beim Upload der Image-Datei aufgetreten!" -Category InvalidOperation -ErrorAction Stop;
                    }
                 break;
                }
    }


# Skript beenden
Exit 0;
