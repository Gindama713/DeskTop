@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0collect.ps1"
echo.
echo data refreshed. reopen index.html (or let the wallpaper reload) to see it.
pause
