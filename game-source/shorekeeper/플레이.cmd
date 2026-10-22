@echo off
powershell.exe -NoProfile -File "%~dp0play.ps1"
if errorlevel 1 pause
