-- =============================================
-- GYMDB - SCRIPT 10: Seguridad Avanzada
-- =============================================
-- Descripcion: Roles por funcion de negocio,
--              usuarios concretos, Row Level Security
--              y buenas practicas sin Active Directory
-- Instancia:   DESKTOP-T4PEHDE (PRIMARY)
-- Autor:       GymDB Project
-- Fecha:       2026
-- =============================================

-- =============================================
-- PARTE A: Asegurar cuenta SA
-- Ejecutar en master
-- =============================================
USE master;
GO

-- Renombrar sa a nombre menos obvio
ALTER LOGIN [sa] WITH NAME = [gym_sa];

-- Asignar password robusta
ALTER LOGIN [gym_sa]
    WITH PASSWORD    = 'S@Admin_Gym2025_Secure!',
    DEFAULT_DATABASE = master,
    CHECK_POLICY     = ON,
    CHECK_EXPIRATION = OFF;

-- Habilitar (en lab la dejamos activa)
ALTER LOGIN [gym_sa] ENABLE;

-- Verificar
SELECT name, is_disabled, is_policy_checked
FROM sys.sql_logins
WHERE name = 'gym_sa';
GO

-- =============================================
-- PARTE B: Roles y usuarios en GymDB
-- =============================================
USE GymDB;
GO

-- ── Limpiar objetos RLS si existen ───────────
DROP SECURITY POLICY IF EXISTS Operaciones.pol_InstructorClases;
DROP FUNCTION  IF EXISTS Operaciones.fn_FiltroInstructor;
GO

-- =============================================
-- SECCIÓN 1: ROLES POR FUNCIÓN DE NEGOCIO
-- Principio: un rol por responsabilidad
-- =============================================

CREATE ROLE rol_SoloLectura;   -- lectura global sin finanzas ni RRHH
CREATE ROLE rol_Recepcion;     -- atencion al cliente y accesos
CREATE ROLE rol_Instructor;    -- ver clases propias y alumnos
CREATE ROLE rol_Contabilidad;  -- ver y registrar finanzas
CREATE ROLE rol_Gerencia;      -- ver todo sin poder borrar
CREATE ROLE rol_DBA;           -- administracion tecnica total
GO

-- =============================================
-- SECCIÓN 2: PERMISOS POR ROL
-- Principio: minimo privilegio necesario
-- =============================================

-- ── rol_SoloLectura ──────────────────────────
GRANT SELECT ON SCHEMA::Membresia   TO rol_SoloLectura;
GRANT SELECT ON SCHEMA::Operaciones TO rol_SoloLectura;
-- NO ve Finanzas ni RRHH por datos sensibles
GO

-- ── rol_Recepcion ─────────────────────────────
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Membresia   TO rol_Recepcion;
GRANT SELECT                 ON SCHEMA::Operaciones TO rol_Recepcion;
GRANT SELECT                 ON SCHEMA::Finanzas    TO rol_Recepcion;
-- Solo puede ejecutar SPs especificos (no acceso directo a tablas)
GRANT EXECUTE ON Membresia.usp_RegistrarEntrada TO rol_Recepcion;
GRANT EXECUTE ON Membresia.usp_RegistrarSalida  TO rol_Recepcion;
GRANT EXECUTE ON Membresia.usp_ObtenerMiembro   TO rol_Recepcion;
GRANT EXECUTE ON Membresia.usp_InsertarMiembro  TO rol_Recepcion;
-- Denegar acceso directo a datos sensibles
DENY SELECT ON Finanzas.Pago   TO rol_Recepcion;
DENY SELECT ON RRHH.Empleado   TO rol_Recepcion;
GO

-- ── rol_Instructor ────────────────────────────
GRANT SELECT ON SCHEMA::Operaciones  TO rol_Instructor;
GRANT SELECT ON Membresia.Miembro    TO rol_Instructor;
-- Puede actualizar asistencia de sus alumnos
GRANT UPDATE ON Operaciones.ReservaClase TO rol_Instructor;
-- No ve salarios ni datos de RRHH
DENY SELECT ON RRHH.Empleado TO rol_Instructor;
GO

-- ── rol_Contabilidad ──────────────────────────
GRANT SELECT ON SCHEMA::Finanzas  TO rol_Contabilidad;
GRANT SELECT ON SCHEMA::Membresia TO rol_Contabilidad;
-- Puede registrar pagos via SP
GRANT EXECUTE ON Finanzas.usp_RegistrarPago TO rol_Contabilidad;
GO

-- ── rol_Gerencia ──────────────────────────────
-- Lee todo, no puede borrar nada
GRANT SELECT ON SCHEMA::Membresia   TO rol_Gerencia;
GRANT SELECT ON SCHEMA::Operaciones TO rol_Gerencia;
GRANT SELECT ON SCHEMA::Finanzas    TO rol_Gerencia;
GRANT SELECT ON SCHEMA::RRHH        TO rol_Gerencia;
GRANT SELECT ON SCHEMA::Inventario  TO rol_Gerencia;
GRANT SELECT ON SCHEMA::Auditoria   TO rol_Gerencia;
GRANT EXECUTE ON Membresia.usp_ObtenerMiembro TO rol_Gerencia;
GO

-- ── rol_DBA ───────────────────────────────────
-- Control total sobre GymDB
GRANT CONTROL ON DATABASE::GymDB TO rol_DBA;
GO

-- =============================================
-- SECCIÓN 3: LOGINS Y USUARIOS CONCRETOS
-- Un usuario por persona real
-- =============================================

-- Logins a nivel de servidor
CREATE LOGIN usr_recepcion1
    WITH PASSWORD    = 'Rec3pcion@Gym1!',
    DEFAULT_DATABASE = GymDB,
    CHECK_POLICY     = ON,
    CHECK_EXPIRATION = ON;   -- password expira, buena practica

CREATE LOGIN usr_recepcion2
    WITH PASSWORD    = 'Rec3pcion@Gym2!',
    DEFAULT_DATABASE = GymDB,
    CHECK_POLICY     = ON,
    CHECK_EXPIRATION = ON;

CREATE LOGIN usr_instructor1
    WITH PASSWORD    = 'Instr@Gym2025_1',
    DEFAULT_DATABASE = GymDB,
    CHECK_POLICY     = ON,
    CHECK_EXPIRATION = ON;

CREATE LOGIN usr_instructor2
    WITH PASSWORD    = 'Instr@Gym2025_2',
    DEFAULT_DATABASE = GymDB,
    CHECK_POLICY     = ON,
    CHECK_EXPIRATION = ON;

CREATE LOGIN usr_contador
    WITH PASSWORD    = 'C0nt@bilidad2025!',
    DEFAULT_DATABASE = GymDB,
    CHECK_POLICY     = ON,
    CHECK_EXPIRATION = ON;

CREATE LOGIN usr_gerente
    WITH PASSWORD    = 'G3r3ncia@Gym2025!',
    DEFAULT_DATABASE = GymDB,
    CHECK_POLICY     = ON,
    CHECK_EXPIRATION = ON;

CREATE LOGIN usr_dba
    WITH PASSWORD    = 'DB@Admin2025_Gym!',
    DEFAULT_DATABASE = GymDB,
    CHECK_POLICY     = ON,
    CHECK_EXPIRATION = ON;

-- Usuario de reportes: no expira, es para herramientas BI
CREATE LOGIN usr_reportes
    WITH PASSWORD    = 'Rep0rtes@2025!',
    DEFAULT_DATABASE = GymDB,
    CHECK_POLICY     = ON,
    CHECK_EXPIRATION = OFF;
GO

-- Crear usuarios en GymDB vinculados a los logins
CREATE USER usr_recepcion1  FOR LOGIN usr_recepcion1;
CREATE USER usr_recepcion2  FOR LOGIN usr_recepcion2;
CREATE USER usr_instructor1 FOR LOGIN usr_instructor1;
CREATE USER usr_instructor2 FOR LOGIN usr_instructor2;
CREATE USER usr_contador    FOR LOGIN usr_contador;
CREATE USER usr_gerente     FOR LOGIN usr_gerente;
CREATE USER usr_dba         FOR LOGIN usr_dba;
CREATE USER usr_reportes    FOR LOGIN usr_reportes;
GO

-- =============================================
-- SECCIÓN 4: ASIGNAR USUARIOS A ROLES
-- =============================================
ALTER ROLE rol_Recepcion    ADD MEMBER usr_recepcion1;
ALTER ROLE rol_Recepcion    ADD MEMBER usr_recepcion2;
ALTER ROLE rol_Instructor   ADD MEMBER usr_instructor1;
ALTER ROLE rol_Instructor   ADD MEMBER usr_instructor2;
ALTER ROLE rol_Contabilidad ADD MEMBER usr_contador;
ALTER ROLE rol_Gerencia     ADD MEMBER usr_gerente;
ALTER ROLE rol_DBA          ADD MEMBER usr_dba;
ALTER ROLE rol_SoloLectura  ADD MEMBER usr_reportes;
GO

-- =============================================
-- SECCIÓN 5: ROW LEVEL SECURITY (RLS)
-- Cada instructor solo ve SUS propias clases
-- =============================================

-- Funcion que filtra por instructor logueado
CREATE FUNCTION Operaciones.fn_FiltroInstructor
    (@InstructorID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS Resultado
    WHERE
        -- DBA y gerencia ven todo sin restriccion
        IS_MEMBER('rol_DBA')       = 1 OR
        IS_MEMBER('rol_Gerencia')  = 1 OR
        IS_MEMBER('rol_Recepcion') = 1 OR
        -- Instructor solo ve sus propias clases
        @InstructorID IN (
            SELECT i.InstructorID
            FROM Operaciones.Instructor i
            JOIN RRHH.Empleado e ON i.EmpleadoID = e.EmpleadoID
            WHERE IS_MEMBER('rol_Instructor') = 0
        );
GO

-- Aplicar politica RLS a la tabla Clase
CREATE SECURITY POLICY Operaciones.pol_InstructorClases
    ADD FILTER PREDICATE
        Operaciones.fn_FiltroInstructor(InstructorID)
    ON Operaciones.Clase
    WITH (STATE = ON);
GO

-- =============================================
-- SECCIÓN 6: VISTA DE AUDITORIA PARA DBA
-- =============================================
CREATE OR ALTER VIEW Auditoria.vw_AccesosRecientes
AS
SELECT TOP 1000
    l.LogID,
    l.Tabla,
    l.Operacion,
    CASE l.Operacion
        WHEN 'I' THEN 'Insercion'
        WHEN 'U' THEN 'Actualizacion'
        WHEN 'D' THEN 'Eliminacion'
    END             AS TipoOperacion,
    l.RegistroID,
    l.Usuario,
    l.Aplicacion,
    l.HostName,
    l.FechaHora,
    l.ValorAnterior,
    l.ValorNuevo
FROM Auditoria.LogCambios l
ORDER BY l.FechaHora DESC;
GO

-- =============================================
-- VERIFICACION FINAL
-- =============================================

-- Roles y sus miembros
SELECT
    r.name      AS Rol,
    m.name      AS Usuario,
    m.type_desc AS Tipo,
    m.create_date AS Creado
FROM sys.database_role_members rm
JOIN sys.database_principals r ON rm.role_principal_id   = r.principal_id
JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
WHERE r.name LIKE 'rol_%'
ORDER BY r.name, m.name;
GO

-- Resumen de credenciales (GUARDAR EN LUGAR SEGURO)
SELECT '=== CREDENCIALES GYMDB ===' AS Info
UNION ALL SELECT 'SA Login    : gym_sa'
UNION ALL SELECT 'SA Password : S@Admin_Gym2025_Secure!'
UNION ALL SELECT '---'
UNION ALL SELECT 'GymAdmin    : Gym@Admin2025!'
UNION ALL SELECT 'AppUser     : GymApp@2025!'
UNION ALL SELECT 'Reporter    : GymReport@2025!'
UNION ALL SELECT '---'
UNION ALL SELECT 'Recepcion1  : Rec3pcion@Gym1!'
UNION ALL SELECT 'Recepcion2  : Rec3pcion@Gym2!'
UNION ALL SELECT 'Instructor1 : Instr@Gym2025_1'
UNION ALL SELECT 'Instructor2 : Instr@Gym2025_2'
UNION ALL SELECT 'Contador    : C0nt@bilidad2025!'
UNION ALL SELECT 'Gerente     : G3r3ncia@Gym2025!'
UNION ALL SELECT 'DBA         : DB@Admin2025_Gym!'
UNION ALL SELECT 'Reportes    : Rep0rtes@2025!';
GO
