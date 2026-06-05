-- =============================================
-- GymDB - Poner BASE DE DATOS ONLINE
-- =============================================
-- Ejecutar DESPUÉS de conectar disco D:
-- y arrancar SQL Server
-- =============================================

USE master;
GO

ALTER DATABASE GymDB SET ONLINE;
GO

-- Verificar que quedó online
SELECT 
    name, 
    state_desc,
    recovery_model_desc
FROM sys.databases
WHERE name = 'GymDB';
-- Debe decir: ONLINE