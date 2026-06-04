-- =============================================
-- GYMDB - SCRIPT 01: Crear Base de Datos
-- =============================================
-- Descripcion: Crea la base de datos GymDB en el
--              disco externo D:\GymDB\
-- Instancia:   DESKTOP-T4PEHDE (PRIMARY)
-- Autor:       GymDB Project
-- Fecha:       2026
-- =============================================

USE master;
GO

-- ── Paso 1: Crear carpetas en disco externo ──
-- Habilitamos xp_cmdshell temporalmente para crear directorios
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

-- Estructura de carpetas en D:
EXEC xp_cmdshell 'mkdir D:\GymDB';
EXEC xp_cmdshell 'mkdir D:\GymDB\Data';        -- archivos .mdf y .ndf
EXEC xp_cmdshell 'mkdir D:\GymDB\Log';          -- archivos .ldf
EXEC xp_cmdshell 'mkdir D:\GymDB\Backup';       -- backups
EXEC xp_cmdshell 'mkdir D:\GymDB\Backup\Full';  -- backups completos
EXEC xp_cmdshell 'mkdir D:\GymDB\Backup\Log';   -- backups de log

-- Deshabilitamos xp_cmdshell por seguridad
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;
GO

-- ── Paso 2: Crear la base de datos ──
-- Los archivos van al disco externo D:
-- Los tamanos van en KB (1MB = 1024KB)
CREATE DATABASE GymDB
ON PRIMARY (
    NAME        = 'GymDB_Data',
    FILENAME    = 'D:\GymDB\Data\GymDB.mdf',   -- archivo principal
    SIZE        = 512000KB,                      -- 500MB inicial
    MAXSIZE     = 52428800KB,                    -- 50GB maximo
    FILEGROWTH  = 262144KB                       -- crece de 256MB en 256MB
),
-- Filegroup secundario para tablas de alto volumen (accesos, pagos, logs)
FILEGROUP FG_Historico (
    NAME        = 'GymDB_Historico',
    FILENAME    = 'D:\GymDB\Data\GymDB_Historico.ndf',
    SIZE        = 204800KB,                      -- 200MB inicial
    MAXSIZE     = 20971520KB,                    -- 20GB maximo
    FILEGROWTH  = 131072KB                       -- crece de 128MB en 128MB
)
LOG ON (
    NAME        = 'GymDB_Log',
    FILENAME    = 'D:\GymDB\Log\GymDB.ldf',     -- log de transacciones
    SIZE        = 102400KB,                      -- 100MB inicial
    MAXSIZE     = 5242880KB,                     -- 5GB maximo
    FILEGROWTH  = 65536KB                        -- crece de 64MB en 64MB
);
GO

-- ── Paso 3: Configurar Recovery Model ──
-- FULL es requerido para Log Shipping y backups de log
ALTER DATABASE GymDB SET RECOVERY FULL;
GO

-- ── Paso 4: Verificacion ──
-- Debe mostrar 3 filas apuntando a D:\GymDB\
SELECT
    name            AS Archivo,
    physical_name   AS RutaFisica,
    size * 8 / 1024 AS TamanoMB,
    state_desc      AS Estado
FROM sys.master_files
WHERE database_id = DB_ID('GymDB');
GO
