@echo off
chcp 65001 > nul

set "SYN=%SystemRoot%\System32"

"%SYN%\net.exe" session >nul 2>&1
if not "%errorlevel%"=="0" (
    "%SYN%\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

echo Останавливаю обход...
"%SYN%\taskkill.exe" /IM winws.exe >nul 2>&1
set /a waitgrace=0
:wait_loop
"%SYN%\ping.exe" -n 2 127.0.0.1 >nul
"%SYN%\tasklist.exe" /FI "IMAGENAME eq winws.exe" | "%SYN%\find.exe" /i "winws.exe" >nul
if not "%errorlevel%"=="0" goto stopped
set /a waitgrace+=1
if %waitgrace% LSS 12 goto wait_loop
echo Процесс не закрылся штатно - закрываем принудительно.
"%SYN%\taskkill.exe" /IM winws.exe /F >nul 2>&1
"%SYN%\ping.exe" -n 3 127.0.0.1 >nul
:stopped
echo Обход остановлен.
echo:

echo Проверяю драйвер WinDivert...
set /a tries=0
:test_round
set /a tries+=1
call :probe
if "%PROBE_OK%"=="1" (
    echo Драйвер свободен, перезагрузка не нужна.
    goto end
)
if %tries% LSS 3 (
    "%SYN%\ping.exe" -n 5 127.0.0.1 >nul
    goto test_round
)

echo:
echo Драйвер завис. Перезапускаю службу базовой фильтрации (BFE)...
"%SYN%\net.exe" stop BFE >nul 2>&1
"%SYN%\ping.exe" -n 4 127.0.0.1 >nul
"%SYN%\net.exe" start BFE >nul 2>&1
"%SYN%\ping.exe" -n 6 127.0.0.1 >nul
set /a tries=0
:test_round2
set /a tries+=1
call :probe
if "%PROBE_OK%"=="1" (
    echo Драйвер свободен, перезагрузка не нужна.
    goto end
)
if %tries% LSS 3 (
    "%SYN%\ping.exe" -n 6 127.0.0.1 >nul
    goto test_round2
)
echo Драйвер не снимается - нужен перезапуск компьютера.

:end
echo:
pause
exit /b

:probe
set "PROBE_OK=0"
start "zapret: probe" /min "%~dp0bin\winws.exe" --wf-raw=false --filter-udp=9 --dpi-desync=fake --dpi-desync-cutoff=n1
"%SYN%\ping.exe" -n 5 127.0.0.1 >nul
"%SYN%\tasklist.exe" /FI "IMAGENAME eq winws.exe" | "%SYN%\find.exe" /i "winws.exe" >nul
if "%errorlevel%"=="0" (
    set "PROBE_OK=1"
    "%SYN%\taskkill.exe" /IM winws.exe >nul 2>&1
    "%SYN%\ping.exe" -n 3 127.0.0.1 >nul
)
exit /b
