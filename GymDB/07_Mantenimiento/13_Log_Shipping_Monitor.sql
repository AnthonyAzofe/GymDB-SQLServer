-- =============================================
-- GYMDB - SCRIPT 13: Monitoreo Log Shipping
-- =============================================
-- Descripcion: Consultas para monitorear
--              el estado del Log Shipping
--              en tiempo real
--
-- Ejecutar en cualquier instancia
-- Autor: GymDB Project
-- Fecha: 2026
-- =============================================

-- =============================================
-- CONSULTA 1: Estado general del Log Shipping
-- Ejecutar en PRIMARY
-- =============================================
USE msdb;
GO

SELECT
    pd.primary_database         AS BaseDatos,
    pd.backup_directory         AS CarpetaBackup,
    pd.backup_retention_period  AS RetenciónMinutos,
    pd.last_backup_file         AS UltimoBackup,
    pd.last_backup_date         AS FechaUltimoBackup,
    DATEDIFF(MINUTE,
        pd.last_backup_date,
        GETDATE())              AS MinutosDesdeUltimoBackup
FROM msdb.dbo.log_shipping_primary_databases pd
WHERE pd.primary_database = 'GymDB';
GO

-- =============================================
-- CONSULTA 2: Estado del SECONDARY
-- Ejecutar en GYM2
-- =============================================
USE msdb;
GO

SELECT
    secondary_server            AS Secundario,
    secondary_database          AS BaseDatos,
    last_copied_file            AS UltimoArchivoCopado,
    last_copied_date            AS FechaCopia,
    last_restored_file          AS UltimoArchivoRestaurado,
    last_restored_date          AS FechaRestauración,
    DATEDIFF(MINUTE,
        last_restored_date,
        GETDATE())              AS MinutosDesdeUltimaRestauración
FROM msdb.dbo.log_shipping_monitor_secondary
WHERE secondary_database = 'GymDB';
GO

-- =============================================
-- CONSULTA 3: Historial de jobs
-- Ejecutar en cualquier instancia
-- =============================================
USE msdb;
GO

SELECT TOP 20
    j.name          AS Job,
    jh.run_date,
    jh.run_time,
    CASE jh.run_status
        WHEN 0 THEN 'Falló ❌'
        WHEN 1 THEN 'Exitoso ✅'
        WHEN 2 THEN 'Reintentando'
        WHEN 3 THEN 'Cancelado'
        WHEN 4 THEN 'En progreso'
    END             AS Estado,
    jh.run_duration AS DuraciónSegundos
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobhistory jh ON j.job_id = jh.job_id
WHERE j.name LIKE 'LS%'
  AND jh.step_id = 0  -- solo el paso final
ORDER BY jh.run_date DESC, jh.run_time DESC;
GO

-- =============================================
-- CONSULTA 4: Archivos .trn en carpeta
-- Ejecutar en PRIMARY
-- =============================================
USE master;
GO

EXEC xp_cmdshell 
    'dir D:\GymDB\LogShipping\Backup\*.trn /O-D';
GO