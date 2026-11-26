@echo off
setlocal
if not "%~2"=="" (
    >&2 echo Usage: install.cmd [checkout-directory]
    exit /b 2
)

set "AGENTS_CHECKOUT=%USERPROFILE%\.agents"
if not "%~1"=="" set "AGENTS_CHECKOUT=%~f1"
if exist "%AGENTS_CHECKOUT%" (
    >&2 echo Checkout path already exists: "%AGENTS_CHECKOUT%"
    exit /b 1
)

git clone -- https://github.com/codetrek/agents.git "%AGENTS_CHECKOUT%" || exit /b 1
call "%AGENTS_CHECKOUT%\setup.cmd"
exit /b %errorlevel%
