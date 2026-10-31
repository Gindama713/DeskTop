@echo off
rem Boot the desktop terminal layer: Alacritty + the bottom-pin watchdog.
start "" "E:\Apps\Alacritty\alacritty.exe"
start "" /min powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0pin-terminal.ps1"
