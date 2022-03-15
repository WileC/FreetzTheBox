@echo off

REM     Skript:                 install_FreetzTheBox.cmd
REM     Author:                 WileC
REM     DL-Source:              https://github.com/WileC/FreetzTheBox
REM     Web:                    http://www.djwilec.de
REM     Infos:                  getestet mit Windows 10; automatisierte Installation zur einfachen (Erst-)Installation von Freetz auf den
REM                             FritzBoxen von AVM
REM     Unterstützte Boxen:     3390, 3490, 4020, 4040, 6820, 6890, 7590

REM Verzeichnisse anlegen
mkdir FreetzTheBox
mkdir FreetzTheBox\Images

REM PowerShell-Skripte von PeterPawns GitHub herunterladen
curl --insecure --location --output FreetzTheBox/EVA-Discover.ps1 "https://github.com/PeterPawn/YourFritz/raw/master/eva_tools/EVA-Discover.ps1"
curl --insecure --location --output FreetzTheBox/EVA-FTP-Client.ps1 "https://github.com/PeterPawn/YourFritz/raw/master/eva_tools/EVA-FTP-Client.ps1"
curl --insecure --location --output FreetzTheBox/FirmwareImage.ps1 "https://github.com/PeterPawn/YourFritz/raw/master/signimage/FirmwareImage.ps1"

REM Wrapper-Skript von WileC herunterladen
curl --insecure --location --output FreetzTheBox/FreetzTheBox.ps1 "https://github.com/WileC/FreetzTheBox/raw/master/FreetzTheBox.ps1"

REM Uninstall-Skript von WileC herunterladen
curl --insecure --location --output uninstall.cmd "https://github.com/WileC/FreetzTheBox/raw/master/uninstall_FreetzTheBox.cmd"

REM PowerShell-Skripte erlauben
powershell -command {Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force}

echo.
echo.
echo "Zur Deinstallation die UNINSTALL.CMD ausführen."
echo.

pause
