@echo off

REM     Skript:                 uninstall.cmd
REM     Author:                 WileC
REM     DL-Source:              https://github.com/WileC/FreetzTheBox
REM     Web:                    http://www.djwilec.de

REM PowerShell-Skripte zurücksetzen
powershell -command {Set-ExecutionPolicy -ExecutionPolicy Default -Scope CurrentUser -Force}

REM Verzeichnis und Dateien entfernen
rmdir /S /Q .\FreetzTheBox
del install.cmd
del uninstall.cmd

pause
