# Veeam Health Check Scripts

Este conjunto de scripts de PowerShell está diseñado para generar informes de salud de Veeam Backup & Replication, extrayendo información importante sobre la licencia, trabajos de respaldo, repositorios y proxies.

## Requisitos previos

- Veeam Backup & Replication instalado
- Módulos de PowerShell de Veeam instalados:
  - Veeam.Backup.PowerShell
  - Veeam.Backup.Common.PowerShell
- Permisos de administrador para ejecutar los scripts

## Estructura de los scripts

El proyecto contiene los siguientes scripts:

1. **Start-VeeamHealthCheckReport.ps1**: Script principal que ejecuta todos los demás scripts y genera un informe HTML completo.
2. **VeeamHealthCheck.ps1**: Verifica los módulos de PowerShell de Veeam y extrae información de licencia.
3. **VeeamBackupJobsCheck.ps1**: Extrae información sobre trabajos de respaldo, repositorios y proxies.
4. **VeeamBackupSessionsCheck.ps1**: Extrae información sobre las sesiones de respaldo y su estado en los últimos días.

## Cómo usar los scripts

### Método 1: Ejecutar el script principal

Para ejecutar una verificación de salud completa y generar un informe HTML:

```powershell
.\Start-VeeamHealthCheckReport.ps1
```

Por defecto, los resultados se guardarán en una carpeta con el formato `VeeamHealthCheck_YYYYMMDD_HHMMSS` en el directorio actual.

### Método 2: Especificar una carpeta de salida personalizada

```powershell
.\Start-VeeamHealthCheckReport.ps1 -OutputFolder "C:\Informes\VeeamHealthCheck"
```

### Método 3: Ejecutar sin generar informe HTML

```powershell
.\Start-VeeamHealthCheckReport.ps1 -NoHTMLReport
```

### Método 4: Especificar el número de días para el análisis de sesiones de respaldo

```powershell
.\Start-VeeamHealthCheckReport.ps1 -SessionDays 14
```

## Información recopilada

Los scripts recopilan la siguiente información:

### Verificación básica
- Módulos de PowerShell de Veeam instalados
- Información de licencia (estado, tipo, edición, fecha de vencimiento, días restantes, etc.)

### Componentes de respaldo
- Trabajos de respaldo (nombre, tipo, programación, último resultado, etc.)
- Repositorios (nombre, tipo, espacio libre, espacio total, etc.)
- Proxies (nombre, tipo, modo de transporte, estado, etc.)

### Sesiones de respaldo
- Información general de sesiones (nombre del trabajo, tipo, hora de inicio, resultado, etc.)
- Estadísticas de rendimiento (tamaño procesado, tamaño de respaldo, ratio de deduplicación, etc.)
- Detalles de sesiones fallidas (mensajes de error, advertencias, etc.)
- Resumen de sesiones (tasa de éxito, número de sesiones con advertencias, fallidas, etc.)

## Salida

Los scripts generan los siguientes archivos CSV:

- **VeeamModulesCheck.csv**: Lista de módulos de PowerShell de Veeam y su estado de instalación
- **VeeamLicenseInfo.csv**: Información detallada de la licencia de Veeam
- **VeeamBackupJobs.csv**: Información sobre trabajos de respaldo
- **VeeamRepositories.csv**: Información sobre repositorios de respaldo
- **VeeamProxies.csv**: Información sobre proxies de respaldo
- **VeeamBackupSessions.csv**: Información sobre sesiones de respaldo de los últimos días
- **VeeamBackupSessions_Summary.csv**: Resumen estadístico de las sesiones de respaldo
- **VeeamFailedSessions.csv**: Detalles de las sesiones fallidas o con advertencias

Además, se genera un informe HTML completo que muestra toda la información recopilada en un formato fácil de leer.

## Solución de problemas

Si encuentra errores al ejecutar los scripts, verifique lo siguiente:

1. Asegúrese de que Veeam Backup & Replication esté instalado y en ejecución
2. Verifique que los módulos de PowerShell de Veeam estén instalados
3. Ejecute PowerShell como administrador
4. Verifique la política de ejecución de PowerShell con `Get-ExecutionPolicy` y ajústela si es necesario con `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Personalización

Puede personalizar los scripts según sus necesidades específicas:

- Agregue más funciones para recopilar información adicional
- Modifique el formato del informe HTML
- Agregue más verificaciones de salud específicas para su entorno

## Notas

- Los scripts están diseñados para ejecutarse en el servidor de Veeam Backup & Replication
- Se recomienda ejecutar los scripts regularmente como parte de un proceso de mantenimiento programado