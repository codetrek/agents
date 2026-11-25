@echo off
setlocal
if not "%~1"=="" (
  >&2 echo Usage: setup.cmd
  exit /b 1
)
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
exit /b %errorlevel%
