-- =============================================
-- GymDB - Poner BASE DE DATOS OFFLINE
-- =============================================
-- Ejecutar ANTES de desconectar disco D:
-- o antes de apagar la PC
-- =============================================

USE master;
GO

ALTER DATABASE GymDB SET OFFLINE WITH ROLLBACK IMMEDIATE;
GO

-- Verificar que quedó offline
SELECT name, state_desc
FROM sys.databases
WHERE name = 'GymDB';
-- Debe decir: OFFLINE