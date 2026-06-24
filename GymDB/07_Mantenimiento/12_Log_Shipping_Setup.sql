-- =============================================
-- GYMDB - SCRIPT 12: Configuración Log Shipping
-- =============================================
-- Descripcion: Configura replicación de GymDB
--              desde PRIMARY a SECONDARY via
--              Log Shipping automático
--
-- PRIMARY:   DESKTOP-T4PEHDE (MSSQLSERVER)
-- SECONDARY: DESKTOP-T4PEHDE\GYM2
-- Carpeta:   D:\GymDB\LogShipping\
--
-- ORDEN DE EJECUCIÓN:
-- PASO 1 → Ejecutar en PRIMARY
-- PASO 2 → Ejecutar en SECONDARY (GYM2)
-- PASO 3A → Ejecutar en PRIMARY
-- PASO 3B → Ejecutar en SECONDARY (GYM2)
-- PASO 4 → Activar jobs en ambas instancias
--
-- Autor: GymDB Project
-- Fecha: 2026
-- =============================================

-- =============================================
-- PASO 1: BACKUP INICIAL
-- Ejecutar en: DESKTOP-T4PEHDE (PRIMARY)
-- =============================================
USE master;
GO

-- Crear carpetas para Log Shipping
-- Ejecutar primero en CMD como administrador:
-- mkdir D:\GymDB\LogShipping\Backup
-- mkdir D:\GymDB\LogShipping\Copy

-- Backup completo inicial
BACKUP DATABASE GymDB
TO DISK = 'D:\GymDB\LogShipping\GymDB_LS_Init.bak'
WITH
    INIT,
    COMPRESSION,
    STATS       = 10,
    CHECKSUM,
    NAME        = 'GymDB - Backup Inicial Log Shipping';
GO

-- Backup del log inicial
BACKUP LOG GymDB
TO DISK = 'D:\GymDB\LogShipping\GymDB_LS_Log_Init.bak'
WITH
    INIT,
    COMPRESSION,
    STATS       = 10,
    NAME        = 'GymDB - Log Backup Inicial';
GO

-- Verificar integridad
RESTORE VERIFYONLY
FROM DISK = 'D:\GymDB\LogShipping\GymDB_LS_Init.bak';
GO

-- Verificar backups creados
SELECT
    bmf.physical_device_name        AS Archivo,
    CASE bs.type
        WHEN 'D' THEN 'Completo'
        WHEN 'L' THEN 'Log'
        WHEN 'I' THEN 'Diferencial'
    END                             AS TipoBackup,
    bs.backup_size / 1024 / 1024    AS TamanoMB,
    bs.backup_start_date            AS Inicio,
    bs.backup_finish_date           AS Fin
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'GymDB'
  AND bs.backup_start_date >= DATEADD(HOUR, -1, GETDATE())
ORDER BY bs.backup_start_date DESC;
GO

-- =============================================
-- PASO 2: RESTAURAR EN SECONDARY
-- Ejecutar en: DESKTOP-T4PEHDE\GYM2
-- =============================================

/*
USE master;
GO

-- Crear carpetas en GYM2
-- Ejecutar en CMD:
-- mkdir D:\GymDB\GYM2\Data
-- mkdir D:\GymDB\GYM2\Log
-- mkdir D:\GymDB\GYM2\Backup

-- Restaurar en modo NORECOVERY
-- NORECOVERY = queda esperando más logs
RESTORE DATABASE GymDB
FROM DISK = 'D:\GymDB\LogShipping\GymDB_LS_Init.bak'
WITH
    NORECOVERY,
    STATS       = 10,
    MOVE 'GymDB_Data'      TO 'D:\GymDB\GYM2\Data\GymDB.mdf',
    MOVE 'GymDB_Log'       TO 'D:\GymDB\GYM2\Log\GymDB.ldf',
    MOVE 'GymDB_Historico' TO 'D:\GymDB\GYM2\Data\GymDB_Historico.ndf';
GO

-- Restaurar log inicial
RESTORE LOG GymDB
FROM DISK = 'D:\GymDB\LogShipping\GymDB_LS_Log_Init.bak'
WITH
    NORECOVERY,
    STATS = 10;
GO

-- Verificar estado RESTORING
SELECT name, state_desc, recovery_model_desc
FROM sys.databases
WHERE name = 'GymDB';
-- Debe decir: RESTORING ✅
*/

-- =============================================
-- PASO 3A: CONFIGURAR PRIMARY PARA LOG SHIPPING
-- Ejecutar en: DESKTOP-T4PEHDE (PRIMARY)
-- =============================================

/*
USE master;
GO

EXEC sp_add_log_shipping_primary_database
    @database                   = N'GymDB',
    @backup_directory           = N'D:\GymDB\LogShipping\Backup',
    @backup_share               = N'D:\GymDB\LogShipping\Backup',
    @backup_job_name            = N'LSBackup_GymDB',
    @backup_retention_period    = 4320,
    @backup_threshold           = 60,
    @threshold_alert_enabled    = 1,
    @history_retention_period   = 5760,
    @backup_compression         = 1,
    @overwrite                  = 1;
GO

EXEC sp_add_log_shipping_primary_secondary
    @primary_database   = N'GymDB',
    @secondary_server   = N'DESKTOP-T4PEHDE\GYM2',
    @secondary_database = N'GymDB';
GO

-- Verificar PRIMARY
SELECT
    primary_database        AS BaseDatos,
    backup_directory        AS CarpetaBackup,
    backup_retention_period AS RetenciónMinutos,
    backup_compression      AS Compresion
FROM msdb.dbo.log_shipping_primary_databases
WHERE primary_database = 'GymDB';
*/

-- =============================================
-- PASO 3B: CONFIGURAR SECONDARY (GYM2)
-- Ejecutar en: DESKTOP-T4PEHDE\GYM2
-- =============================================

/*
USE master;
GO

EXEC sp_add_log_shipping_secondary_primary
    @primary_server                 = N'DESKTOP-T4PEHDE',
    @primary_database               = N'GymDB',
    @backup_source_directory        = N'D:\GymDB\LogShipping\Backup',
    @backup_destination_directory   = N'D:\GymDB\LogShipping\Copy',
    @copy_job_name                  = N'LSCopy_GymDB',
    @restore_job_name               = N'LSRestore_GymDB',
    @file_retention_period          = 4320,
    @overwrite                      = 1;
GO

EXEC sp_add_log_shipping_secondary_database
    @secondary_database         = N'GymDB',
    @primary_server             = N'DESKTOP-T4PEHDE',
    @primary_database           = N'GymDB',
    @restore_delay              = 0,
    @restore_mode               = 0,
    @disconnect_users           = 0,
    @restore_threshold          = 45,
    @threshold_alert_enabled    = 1,
    @history_retention_period   = 5760,
    @overwrite                  = 1;
GO
*/

-- =============================================
-- PASO 4: ACTIVAR JOBS
-- =============================================

-- En PRIMARY (DESKTOP-T4PEHDE):
/*
USE msdb;
GO
EXEC sp_update_job @job_name = N'LSBackup_GymDB', @enabled = 1;
*/

-- En SECONDARY (DESKTOP-T4PEHDE\GYM2):
/*
USE msdb;
GO
EXEC sp_update_job @job_name = N'LSCopy_GymDB',    @enabled = 1;
EXEC sp_update_job @job_name = N'LSRestore_GymDB', @enabled = 1;
*/

-- =============================================
-- VERIFICACIÓN FINAL
-- Ejecutar en: DESKTOP-T4PEHDE\GYM2
-- =============================================
USE msdb;
GO

-- Estado del Log Shipping
SELECT
    secondary_server            AS Secundario,
    secondary_database          AS BaseDatos,
    last_copied_file            AS UltimoArchivoCopado,
    last_copied_date            AS FechaCopia,
    last_restored_file          AS UltimoArchivoRestaurado,
    last_restored_date          AS FechaRestauración
FROM msdb.dbo.log_shipping_monitor_secondary
WHERE secondary_database = 'GymDB';
GO

-- Jobs activos
SELECT
    name        AS Job,
    enabled     AS Activo,
    date_created AS Creado
FROM msdb.dbo.sysjobs
WHERE name LIKE 'LS%'
ORDER BY name;
GO