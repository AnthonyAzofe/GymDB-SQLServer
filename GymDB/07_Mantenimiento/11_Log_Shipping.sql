-- =============================================
-- GYMDB - SCRIPT 11: Log Shipping
-- =============================================
-- Descripcion: Configura replica de GymDB desde
--              instancia PRIMARY a SQLEXPRESS
--              usando Log Shipping (alternativa
--              a Always On sin Windows Cluster)
-- PRIMARY:     DESKTOP-T4PEHDE
-- SECONDARY:   DESKTOP-T4PEHDE\SQLEXPRESS
-- Autor:       GymDB Project
-- Fecha:       2026
-- IMPORTANTE:  Ejecutar primero en PRIMARY,
--              luego los pasos en SECONDARY
-- =============================================

-- =============================================
-- PASO 1: En PRIMARY - Crear carpeta compartida
-- Ejecutar en CMD como Administrador:
-- mkdir D:\GymDB\Backup\Log
-- net share GymDBLog=D:\GymDB\Backup\Log /GRANT:Everyone,FULL
-- =============================================

-- =============================================
-- PASO 2: En PRIMARY - Backup inicial
-- Este backup se restaura en SECONDARY
-- =============================================
USE master;
GO

-- Backup completo inicial para inicializar SECONDARY
BACKUP DATABASE GymDB
TO DISK = 'D:\GymDB\Backup\Full\GymDB_LogShipping_Init.bak'
WITH
    INIT,         -- sobreescribir si existe
    COMPRESSION,
    STATS = 10,
    NAME  = 'GymDB - Backup Inicial Log Shipping';
GO

-- =============================================
-- PASO 3: En SECONDARY (SQLEXPRESS)
-- Restaurar el backup en modo NORECOVERY
-- Abrir nueva ventana SSMS -> SQLEXPRESS
-- =============================================

/*
-- EJECUTAR EN SQLEXPRESS:

USE master;
GO

-- Restaurar en modo NORECOVERY para permitir logs futuros
RESTORE DATABASE GymDB
FROM DISK = 'D:\GymDB\Backup\Full\GymDB_LogShipping_Init.bak'
WITH
    NORECOVERY,   -- fundamental para Log Shipping
    MOVE 'GymDB_Data'      TO 'C:\GymDB_Secondary\GymDB.mdf',
    MOVE 'GymDB_Log'       TO 'C:\GymDB_Secondary\GymDB.ldf',
    MOVE 'GymDB_Historico' TO 'C:\GymDB_Secondary\GymDB_Historico.ndf',
    STATS = 10;
GO

-- Crear carpeta antes de ejecutar (en CMD):
-- mkdir C:\GymDB_Secondary
*/

-- =============================================
-- PASO 4: En PRIMARY - Configurar Log Shipping
-- =============================================
USE master;
GO

-- Habilitar el envio de logs desde PRIMARY
EXEC sp_add_log_shipping_primary_database
    @database                    = N'GymDB',
    @backup_directory            = N'D:\GymDB\Backup\Log',
    @backup_share                = N'\\DESKTOP-T4PEHDE\GymDBLog',
    @backup_job_name             = N'LSBackup_GymDB',
    @backup_retention_period     = 4320,   -- 3 dias en minutos
    @backup_threshold            = 60,     -- alerta si no hay backup en 60 min
    @threshold_alert_enabled     = 1,
    @history_retention_period    = 5760,   -- historial 4 dias
    @backup_compression          = 1;      -- comprimir backups de log

-- Agregar servidor secundario
EXEC sp_add_log_shipping_primary_secondary
    @primary_database  = N'GymDB',
    @secondary_server  = N'DESKTOP-T4PEHDE\SQLEXPRESS',
    @secondary_database = N'GymDB';
GO

-- =============================================
-- PASO 5: En SECONDARY (SQLEXPRESS)
-- Configurar la recepcion de logs
-- =============================================

/*
-- EJECUTAR EN SQLEXPRESS:

USE master;
GO

EXEC sp_add_log_shipping_secondary_primary
    @primary_server          = N'DESKTOP-T4PEHDE',
    @primary_database        = N'GymDB',
    @backup_source_directory = N'\\DESKTOP-T4PEHDE\GymDBLog',
    @backup_destination_directory = N'C:\GymDB_Secondary\Logs',
    @copy_job_name           = N'LSCopy_GymDB',
    @restore_job_name        = N'LSRestore_GymDB',
    @file_retention_period   = 4320,
    @monitor_server          = N'DESKTOP-T4PEHDE',
    @threshold_alert_enabled = 1;

EXEC sp_add_log_shipping_secondary_database
    @secondary_database      = N'GymDB',
    @primary_server          = N'DESKTOP-T4PEHDE',
    @primary_database        = N'GymDB',
    @restore_delay           = 0,
    @restore_mode            = 0,       -- 0=NORECOVERY, 1=STANDBY
    @disconnect_users        = 0,
    @restore_threshold       = 45,
    @threshold_alert_enabled = 1,
    @history_retention_period= 5760;
GO
*/

-- =============================================
-- VERIFICACION DE LOG SHIPPING
-- =============================================
-- Ejecutar en PRIMARY para ver estado:
SELECT
    primary_database    AS BaseDatos,
    last_backup_file    AS UltimoBackup,
    last_backup_date    AS FechaUltimoBackup,
    backup_threshold    AS UmbralMinutos,
    threshold_alert     AS AlertaActiva
FROM msdb.dbo.log_shipping_monitor_primary
WHERE primary_database = 'GymDB';
GO
