-- =============================================
-- GYMDB - SCRIPT 02: Esquemas y Seguridad Base
-- =============================================
-- Descripcion: Crea los esquemas de negocio,
--              logins iniciales y roles base
-- Instancia:   DESKTOP-T4PEHDE (PRIMARY)
-- Autor:       GymDB Project
-- Fecha:       2026
-- =============================================

USE GymDB;
GO

-- =============================================
-- SECCIÓN 1: ESQUEMAS
-- Organizamos las tablas por dominio de negocio
-- =============================================

CREATE SCHEMA Membresia;    -- miembros, contratos, accesos
GO
CREATE SCHEMA Operaciones;  -- clases, instructores, horarios
GO
CREATE SCHEMA Finanzas;     -- pagos, facturas, caja
GO
CREATE SCHEMA RRHH;         -- empleados, contratos, nomina
GO
CREATE SCHEMA Inventario;   -- equipos, mantenimiento
GO
CREATE SCHEMA Auditoria;    -- logs, cambios, trazabilidad
GO

-- =============================================
-- SECCIÓN 2: LOGINS A NIVEL DE SERVIDOR
-- =============================================

-- Login administrador del gym
CREATE LOGIN GymAdmin
    WITH PASSWORD    = 'Gym@Admin2025!',
    DEFAULT_DATABASE = GymDB,
    CHECK_POLICY     = ON,
    CHECK_EXPIRATION = OFF;

-- Login para la aplicacion web (IIS)
CREATE LOGIN GymAppUser
    WITH PASSWORD    = 'GymApp@2025!',
    DEFAULT_DATABASE = GymDB,
    CHECK_POLICY     = ON,
    CHECK_EXPIRATION = OFF;

-- Login solo lectura para reportes
CREATE LOGIN GymReporter
    WITH PASSWORD    = 'GymReport@2025!',
    DEFAULT_DATABASE = GymDB,
    CHECK_POLICY     = ON,
    CHECK_EXPIRATION = OFF;

-- Login para el Job de Log Shipping
CREATE LOGIN GymLogShipping
    WITH PASSWORD    = 'GymLS@2025!',
    DEFAULT_DATABASE = master,
    CHECK_POLICY     = ON,
    CHECK_EXPIRATION = OFF;
GO

-- =============================================
-- SECCIÓN 3: USUARIOS EN GymDB
-- =============================================

CREATE USER GymAdmin       FOR LOGIN GymAdmin;
CREATE USER GymAppUser     FOR LOGIN GymAppUser;
CREATE USER GymReporter    FOR LOGIN GymReporter;
CREATE USER GymLogShipping FOR LOGIN GymLogShipping;
GO

-- =============================================
-- SECCIÓN 4: ROLES BASE
-- =============================================

CREATE ROLE rol_GymAdmin;    -- control total
CREATE ROLE rol_Operaciones; -- operaciones diarias
CREATE ROLE rol_Reporter;    -- solo lectura
CREATE ROLE rol_AppWeb;      -- aplicacion web IIS
GO

-- =============================================
-- SECCIÓN 5: PERMISOS POR ROL
-- =============================================

-- rol_GymAdmin: control total
GRANT CONTROL ON SCHEMA::Membresia   TO rol_GymAdmin;
GRANT CONTROL ON SCHEMA::Operaciones TO rol_GymAdmin;
GRANT CONTROL ON SCHEMA::Finanzas    TO rol_GymAdmin;
GRANT CONTROL ON SCHEMA::RRHH        TO rol_GymAdmin;
GRANT CONTROL ON SCHEMA::Inventario  TO rol_GymAdmin;
GRANT CONTROL ON SCHEMA::Auditoria   TO rol_GymAdmin;

-- rol_Operaciones: lectura y escritura en operaciones
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Membresia   TO rol_Operaciones;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Operaciones TO rol_Operaciones;
GRANT SELECT                 ON SCHEMA::Finanzas    TO rol_Operaciones;

-- rol_Reporter: solo lectura
GRANT SELECT ON SCHEMA::Membresia   TO rol_Reporter;
GRANT SELECT ON SCHEMA::Operaciones TO rol_Reporter;
GRANT SELECT ON SCHEMA::Finanzas    TO rol_Reporter;
GRANT SELECT ON SCHEMA::RRHH        TO rol_Reporter;
GRANT SELECT ON SCHEMA::Inventario  TO rol_Reporter;

-- rol_AppWeb: CRUD en operaciones del dia
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Membresia   TO rol_AppWeb;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Operaciones TO rol_AppWeb;
GRANT SELECT, INSERT                 ON SCHEMA::Finanzas    TO rol_AppWeb;
GRANT SELECT                         ON SCHEMA::Inventario  TO rol_AppWeb;
GO

-- =============================================
-- SECCIÓN 6: ASIGNAR USUARIOS A ROLES
-- =============================================

ALTER ROLE rol_GymAdmin      ADD MEMBER GymAdmin;
ALTER ROLE rol_AppWeb        ADD MEMBER GymAppUser;
ALTER ROLE rol_Reporter      ADD MEMBER GymReporter;
ALTER ROLE db_backupoperator ADD MEMBER GymLogShipping; -- rol built-in para backups
GO

-- =============================================
-- VERIFICACION FINAL
-- =============================================
SELECT
    r.name  AS Rol,
    m.name  AS Usuario,
    m.type_desc AS Tipo
FROM sys.database_role_members rm
JOIN sys.database_principals r ON rm.role_principal_id   = r.principal_id
JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
WHERE r.name LIKE 'rol_%' OR r.name = 'db_backupoperator'
ORDER BY r.name;
GO
