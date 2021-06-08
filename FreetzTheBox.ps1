<#
.SYNOPSIS
    Wrapper-Skript für PeterPawns EVA-Tools PowerShell-Skripte

.DESCRIPTION
    PowerShell-Skript zum flashen von FRITZ!Boxen über den Bootloader
    mittels der im freetz erstellten *.image-Datei. Liegt bereits ein in-memory-Image
    vor, so muss der Paramter "-isbootable" verwendet werden.
    Dieses Skript benötigt die EVA-Tools aus PeterPawns GitHup-Repository.

    Wichtig: vor dem Ausführen des Skripts sollte sichergestellt sein, dass entweder am LAN-Interface
    eine feste IP-Adresse eingestellt ist oder wenn die IP-Zuweisung per DHCP statt findet, dass der
    DhcpMediasense (https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=2ahUKEwjLw4jYgvvwAhUHmBQKHRulC8AQFjAAegQIAxAD&url=https%3A%2F%2Fdocs.microsoft.com%2Fde-de%2Ftroubleshoot%2Fwindows-server%2Fnetworking%2Fdisable-media-sensing-feature-for-tcpip&usg=AOvVaw0Gxeh5K_M2bfrhiHzUNnvO)
    deaktiviert wurde. 

    Hierzu öffnet man eine Powershell mit administrativen Rechten und führt "Set-NetIPv4Protocol -DhcpMediaSense Disabled" aus. Danach sollte
	überpüft werden, ob das LAN-Interface eine APIPA-Adresse bezogen hat. Wenn nicht, dann sollte ein "renew" des DHCP-Lease angestossen werden.
	Ansonsten führt man einfach dieses Skript aus (hierzu werden die administrativen Rechte nicht benötit).

	Nach erfolgreichem flashen der FRITZ!Box setzt man die Einstellung mittels "Set-NetIPv4Protocol -DhcpMediaSense Enabled" wieder zurück.
    

.NOTES
    Filename: FreetzTheBox.ps1

.EXAMPLE
    .\FreetzTheBox.ps1 -BoxType 3490 -ImageFile .\example.image [-isbootableImage]

.PARAMTER BoxType
    Der Name der Fritz!Box

.PARAMTER ImageFile
    Die Image-Datei, welche in den Bootloader der FRITZ!Box geschrieben werden soll. Vgl. hierzu "EXAMPLE"
    
.PARAMETER isbootableImage
    Der Schalter funktioniert nur bei NAND-Boxen. Wird der Schalter gesetzt, wird das übergebene Image als 
    RAM-Image behandelt und nicht mehr mit der Funktion "getbootableImage" behandelt.

.LINK
    https://github.com/PeterPawn/YourFritz

#>

#####################################################################
##
## Parameter-Definitionen

Param([Parameter(Mandatory = $True, HelpMessage = 'Fritz!Box-Type e.g. 3490')][int]$BoxType,
      [Parameter(Mandatory = $True, HelpMessage = 'The imagefile to load in the bootloader')][string]$ImageFile,
      [Parameter(Mandatory = $False, HelpMessage = 'The IP for searching the box while booting')][string]$BoxIP='169.254.1.1',
      [Parameter(Mandatory = $False, HelpMessage = 'Is it an in-memory image?')][switch]$isbootableImage=$false
    )


## Variablen-Definitonen
$SupportedBoxesArray = @{3390="NAND";3490="NAND";4020="NOR";4040="NOR";6820="NAND";6890="NAND";7590="NAND"};


## Überprüfung, ob die Paramterübergabe passt.
## Ist die angegebene Box im Array enthalten? Wenn nein, dann Skript-Abbruch!
Write-Verbose -Message "INFO: Wird die FRITZ!Box $BoxType unterstützt?";
if ( -not $SupportedBoxesArray.ContainsKey($BoxType) )
    {
        Write-Error -Message "FEHLER: Der angegebene Fritz!Box-Typ wird derzeit nicht unterstützt" -Category InvalidData -ErrorAction Stop;
        }

Write-Verbose -message "ERFOLG: Die angegebene FRITZ!Box $BoxType wird unterstützt. `n";


## Ist die Image-Datei angegeben worden und gibt es sie tatsächlich?
Write-Verbose -Message "INFO: Ist das ImageFile vorhanden?";
if (-not $(Test-Path $ImageFile))
    {
    Write-Error -Message "Dateiname $ImageFile nicht gefunden!" -Category ObjectNotFound -ErrorAction Stop;
    }
    
Write-Verbose -message "ERFOLG: Die Image-Datei wurde korrekt angeben und ist vorhanden. `n";


## Überprüfung, ob Neztwerkkabel am LAN-Interface angeschlossen ist oder DhcpMediaSense deaktiviert wurde
Write-Verbose -Message "INFO: Überprüfung, ob Neztwerkkabel am LAN-Interface angeschlossen ist oder DhcpMediaSense deaktiviert wurde..";
if ( $(Get-NetIPInterface -AddressFamily IPv4 -InterfaceAlias Ethernet).ConnectionState )
    {
    Write-Verbose -Message "INFO: Die FRITZ!Box $BoxType wird mit der IP-Adresse $BoxIP angesprochen... `n"
    }
    else
        {
        Write-Error -Message "Entweder ist das Netzwerkkabel nicht verbunden oder der DhcpMediaSense ist aktiv.`
        Dies kann zu Problemen beim flashen der Firmware oder beim ansprechen der Box im Bootloader führen. `
        Weitere Informationen unter https://www.github.com/wilec/..." -Category ConnectionError -ErrorAction Stop;
        }


########################################
## Image-Datei für's flashen vorbereiten
##
## Toolbox für die Image-Dateien von PeterPawn aufrufen
. $pwd\FirmwareImage.ps1


#########################################################
##
## Skript-Aufruf von .\EVA-Discover.ps1
##

Write-Output "Bitte die FRITZ!Box nun an den Strom anschließen...";

if (-not $(.\EVA-Discover.ps1 -maxWait 120 -requested_address $BoxIP -Verbose -Debug))
    {
    Write-Error -Message "Keine FRITZ!Box gefunden!" -Category DeviceError -ErrorAction Stop
    }

Write-Verbose -message "ERFOLG: die FRITZ!Box $BoxType wurde im Bootloader angehalten. `n";
Read-Host -Prompt "Um fortzufahren ENTER drücken...";

########################################################
##
## Skript-Aufruf von .\EVA-FTP-Client.ps1, je nach Speicherart
## und Flash-Vorgang
##

switch ($SupportedBoxesArray[$BoxType]) 
    {
        "NOR" { Write-Verbose -message "Starte Flash-Vorgang für NOR-Boxen...";

                $NORBootImageFile = "$pwd\Images\$((Get-Item $ImageFile).BaseName).NOR_bootable.image";
                Write-Verbose -message "Variable NORBootImageFile: $NORBootImageFile";

                if ( $(Test-Path $NORBootImageFile) ) { Remove-Item $NORBootImageFile -Verbose; }
               
                [FirmwareImage]::new($ImageFile).extractMemberAndRemoveChecksum("./var/tmp/kernel.image", $NORBootImageFile);
             
                sleep -Seconds 2;
                Write-Verbose -Message "INFO: flashe Firmware ...";
                if (-not (.\EVA-FTP-Client.ps1 -ScriptBlock { UploadFlashFile $NORBootImageFile mtd1 } -Verbose -Debug))
                    {
                    Write-Error -Message "Es ist ein Fehler beim upload der Image-Datei aufgetreten!" -Category InvalidOperation -ErrorAction Stop;
                    }
                
                sleep -Seconds 2;
                Write-Verbose -Message "INFO: Starte die FRITZ!Box $BoxType neu ...";
                if (-not (.\EVA-FTP-Client.ps1 -Address $BoxIP -ScriptBlock { RebootTheDevice } -Verbose -Debug))
                    {
                    Write-Error -Message "Es ist ein Fehler beim Reboot-Command aufgetreten!" -Category InvalidOperation -ErrorAction Stop;
                    }
                Write-Output "Flashvorgang der FRITZ!Box $BoxType erfolgreich abgelossen `n";
                break;
              }

        "NAND" { Write-Verbose -message "Starte Flash-Vorgang für NAND-Boxen...";

                 $NANDBootImageFile = "$pwd\Images\$((Get-Item $ImageFile).BaseName).NAND_bootable.image";
                 Write-Verbose -message "Variable NANDBootImageFile: $NANDBootImageFile";
                  
                 if ( $(Test-Path $NANDBootImageFile) ) { Remove-Item $NANDBootImageFile -Verbose; }

                 if ( -not $isbootableImage) { [FirmwareImage]::new($ImageFile).getBootableImage($NANDBootImageFile) };
                 
                 sleep -Seconds 2;
                 Write-Verbose -Message "INFO: Wechsle Firmware-Partition der FRITZ!Box $BoxType...";
                 if (-not (.\EVA-FTP-Client.ps1 -Address $BoxIP -ScriptBlock { SwitchSystem } -Verbose -Debug))
                    {
                    Write-Error -Message "Es ist ein Fehler beim ändern der aktiven Partition aufgetreten!" -Category InvalidOperation -ErrorAction Stop;
                    }

                 sleep -Seconds 2;
                 Write-Verbose -Message "INFO: flashe Firmware...";
                 if (-not (.\EVA-FTP-Client.ps1 -Address $BoxIP -ScriptBlock { BootDeviceFromImage $NANDBootImageFile } -Verbose -Debug))
                    {
                    Write-Error -Message "Es ist ein Fehler beim Upload der Image-Datei aufgetreten!" -Category InvalidOperation -ErrorAction Stop;
                    }

                 Write-Output "Flashvorgang der FRITZ!Box $BoxType erfolgreich abgelossen `n";
                 break;
                }
    }


# Skript beenden
Exit 0;
