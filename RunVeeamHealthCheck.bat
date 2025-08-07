@echo off
echo Veeam Health Check
echo =====================================
echo.

set /p DAYS=Ingrese el numero de dias para analizar las sesiones de respaldo [7]: 
if "%DAYS%"=="" set DAYS=7

echo.
echo Ejecutando Veeam Health Check (analizando ultimos %DAYS% dias)...
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0Start-VeeamHealthCheckReport.ps1" -SessionDays %DAYS%

echo.
echo Presione cualquier tecla para salir...
pause > nul