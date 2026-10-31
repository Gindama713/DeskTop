@echo off
start "" "E:\Apps\WezTerm\WezTerm-windows-20240203-110809-5046fc22\wezterm-gui.exe"
start "" /min powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0pin-terminal.ps1"
