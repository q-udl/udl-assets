@echo off
setlocal
cd /d "%~dp0"
echo UDL Assets - UAT lokal terisolasi
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-uat.ps1"
if errorlevel 1 (
  echo.
  echo UAT tidak dapat dijalankan. Periksa pesan galat di atas.
  pause
)
endlocal
