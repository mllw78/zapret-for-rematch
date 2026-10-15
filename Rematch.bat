@echo off
chcp 65001 > nul

set "SYN=%SystemRoot%\System32"

"%SYN%\net.exe" session >nul 2>&1
if not "%errorlevel%"=="0" (
    "%SYN%\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

"%SYN%\sc.exe" query WinDivert >nul 2>&1
if not "%errorlevel%"=="0" goto drv_skip
"%SYN%\sc.exe" config WinDivert binPath= "\"%~dp0bin\WinDivert64.sys\"" >nul 2>&1
:drv_skip

"%SYN%\netsh.exe" interface tcp show global | "%SYN%\findstr.exe" /i "timestamps" | "%SYN%\findstr.exe" /i "enabled" >nul
if "%errorlevel%"=="0" goto ts_ok
"%SYN%\netsh.exe" interface tcp set global timestamps=enabled >nul 2>&1
:ts_ok

start "zapret: Rematch" /min "%~dp0bin\winws.exe" --wf-udp=1024-65535 ^
--filter-udp=1024-65535 --ipset-exclude="%~dp0lists\ipset-exclude.txt" --dpi-desync=fake --dpi-desync-any-protocol=1 --dpi-desync-cutoff=n4 --dpi-desync-ttl=4 --dpi-desync-repeats=10 --dpi-desync-fake-unknown-udp="%~dp0bin\stun.bin" --dpi-desync-fake-stun="%~dp0bin\stun.bin"

"%SYN%\ping.exe" -n 5 127.0.0.1 >nul
"%SYN%\tasklist.exe" /FI "IMAGENAME eq winws.exe" | "%SYN%\find.exe" /i "winws.exe" >nul
if "%errorlevel%"=="0" (
    echo Обход запущен.
    echo Чтобы полностью закрыть драйвер запусти Rematch-stop.bat
) else (
    echo Обход НЕ запустился. Скорее всего это зависший WinDivert -
    echo запусти Rematch-stop.bat: он перезапустит службу фильтрации, чтобы тебе не перезагружать полностью ПК.
)
pause
