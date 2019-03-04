@echo off

REM 	Skript:				uninstall.cmd
REM 	Author:				WileC
REM 	Web:				http://www.djwilec.de
REM		Infos:				getestet mit Windows 10;
REM							automatisierte Deinstallation der Skripte
REM		Unterstützte Boxen:	3490, 4040, 6820

REM PowerShell-Skripte zurücksetzen
powershell -command {Set-ExecutionPolicy -ExecutionPolicy Default -Scope CurrentUser -Force}

REM Verzeichnis und Dateien entfernen
rmdir /S /Q .\FreetzTheBox
del install.cmd
del uninstall.cmd

pause