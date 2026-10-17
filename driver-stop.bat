@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul

set "SYN=%SystemRoot%\System32"

"%SYN%\net.exe" session >nul 2>&1
if not "%errorlevel%"=="0" (
    "%SYN%\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

echo Останавливаю обход...
call :close_winws
echo Обход остановлен.
echo:

echo Останавливаю службу драйвера WinDivert...
"%SYN%\sc.exe" query WinDivert >nul 2>&1
if not "%errorlevel%"=="0" goto cleanup_other
"%SYN%\net.exe" stop WinDivert /y >nul 2>&1
set /a sw=0
:stop_wait
"%SYN%\ping.exe" -n 2 127.0.0.1 >nul
"%SYN%\sc.exe" query WinDivert | "%SYN%\findstr.exe" /i "STOPPED" >nul
if "%errorlevel%"=="0" goto drvstoped
set /a sw+=1
if %sw% LSS 8 goto stop_wait

:stuck
echo Служба не остановилась. Ищу другие сервисы, которые держат драйвер...
call :kill_conflict GoodbyeDPI
call :kill_conflict zapret
call :kill_conflict discryptor
"%SYN%\net.exe" stop WinDivert /y >nul 2>&1
set /a sw2=0
:stop_wait2
"%SYN%\ping.exe" -n 2 127.0.0.1 >nul
"%SYN%\sc.exe" query WinDivert | "%SYN%\findstr.exe" /i "STOPPED" >nul
if "%errorlevel%"=="0" goto drvstoped
set /a sw2+=1
if %sw2% LSS 5 goto stop_wait2
echo Удаляю службу, при следующем запуске Rematch.bat драйвер поднимется сам.
"%SYN%\sc.exe" delete WinDivert >nul 2>&1
echo Если Rematch.bat после этого не поднимется - нужен перезапуск компьютера.
goto cleanup_other

:drvstoped
echo Драйвер WinDivert остановлен.

:cleanup_other
"%SYN%\net.exe" stop WinDivert14 >nul 2>&1
"%SYN%\sc.exe" delete WinDivert14 >nul 2>&1
echo:
echo Готово.

:end
pause
exit /b

:close_winws
"%SYN%\tasklist.exe" /FI "IMAGENAME eq winws.exe" | "%SYN%\find.exe" /i "winws.exe" >nul
if not "%errorlevel%"=="0" exit /b
"%SYN%\taskkill.exe" /IM winws.exe >nul 2>&1
"%SYN%\ping.exe" -n 4 127.0.0.1 >nul
"%SYN%\tasklist.exe" /FI "IMAGENAME eq winws.exe" | "%SYN%\find.exe" /i "winws.exe" >nul
if not "%errorlevel%"=="0" exit /b
"%SYN%\taskkill.exe" /IM winws.exe /F >nul 2>&1
"%SYN%\ping.exe" -n 2 127.0.0.1 >nul
exit /b

:kill_conflict
"%SYN%\sc.exe" query %~1 >nul 2>&1
if not "%errorlevel%"=="0" exit /b
"%SYN%\net.exe" stop %~1 /y >nul 2>&1
"%SYN%\sc.exe" delete %~1 >nul 2>&1
echo Найден и закрыт конфликтующий сервис: %~1
exit /b
