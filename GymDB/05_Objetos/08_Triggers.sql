-- =============================================
-- GYMDB - SCRIPT 08: Triggers
-- =============================================
-- Descripcion: Triggers de auditoría y control
--              de negocio en tablas críticas
-- Instancia:   DESKTOP-T4PEHDE (PRIMARY)
-- Autor:       GymDB Project
-- Fecha:       2026
-- =============================================

USE GymDB;
GO

-- =============================================
-- TRIGGER 1: Auditoría en tabla Miembro
-- Se dispara en INSERT, UPDATE y DELETE
-- Registra todos los cambios en Auditoria.LogCambios
-- =============================================
CREATE OR ALTER TRIGGER Membresia.trg_Miembro_Auditoria
ON Membresia.Miembro
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT: nuevo miembro creado
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria.LogCambios
            (Tabla, Operacion, RegistroID, ValorNuevo, Usuario)
        SELECT
            'Membresia.Miembro', 'I',
            CAST(i.MiembroID AS VARCHAR),
            '{"Cedula":"'  + i.Cedula  + '",' +
            '"Nombre":"'   + i.Nombre  + ' ' + i.Apellido1 + '",' +
            '"Email":"'    + i.Email   + '",' +
            '"Activo":'    + CAST(i.Activo AS VARCHAR) + '}',
            SYSTEM_USER
        FROM inserted i;
    END

    -- UPDATE: miembro modificado
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria.LogCambios
            (Tabla, Operacion, RegistroID, ValorAnterior, ValorNuevo, Usuario)
        SELECT
            'Membresia.Miembro', 'U',
            CAST(i.MiembroID AS VARCHAR),
            '{"Email":"'  + d.Email + '","Activo":' + CAST(d.Activo AS VARCHAR) +
            ',"PesoKg":'  + ISNULL(CAST(d.PesoKg AS VARCHAR),'null') + '}',
            '{"Email":"'  + i.Email + '","Activo":' + CAST(i.Activo AS VARCHAR) +
            ',"PesoKg":'  + ISNULL(CAST(i.PesoKg AS VARCHAR),'null') + '}',
            SYSTEM_USER
        FROM inserted i
        JOIN deleted  d ON i.MiembroID = d.MiembroID;
    END

    -- DELETE: miembro eliminado físicamente
    IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria.LogCambios
            (Tabla, Operacion, RegistroID, ValorAnterior, Usuario)
        SELECT
            'Membresia.Miembro', 'D',
            CAST(d.MiembroID AS VARCHAR),
            '{"Cedula":"' + d.Cedula + '","Nombre":"' +
             d.Nombre + ' ' + d.Apellido1 + '"}',
            SYSTEM_USER
        FROM deleted d;
    END
END;
GO

-- =============================================
-- TRIGGER 2: Control de cupos en clases
-- Se dispara al insertar o modificar reservas
-- Mantiene el conteo de cupos disponibles
-- =============================================
CREATE OR ALTER TRIGGER Operaciones.trg_Reserva_ControlCupos
ON Operaciones.ReservaClase
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Al confirmar reserva: reducir cupo disponible
    IF EXISTS (SELECT 1 FROM inserted i WHERE i.Estado = 'Confirmada')
    BEGIN
        UPDATE Operaciones.Clase SET
            CupoDisponible = CupoDisponible - 1
        WHERE ClaseID IN (
            SELECT ClaseID FROM inserted WHERE Estado = 'Confirmada'
        )
        AND CupoDisponible > 0;  -- nunca bajar de 0
    END

    -- Al cancelar o marcar NoShow: devolver cupo
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.ReservaID = d.ReservaID
        WHERE d.Estado = 'Confirmada'
          AND i.Estado IN ('Cancelada','NoShow'))
    BEGIN
        UPDATE Operaciones.Clase SET
            CupoDisponible = CupoDisponible + 1
        WHERE ClaseID IN (
            SELECT i.ClaseID
            FROM inserted i
            JOIN deleted  d ON i.ReservaID = d.ReservaID
            WHERE d.Estado = 'Confirmada'
              AND i.Estado IN ('Cancelada','NoShow')
        );
    END
END;
GO

-- =============================================
-- TRIGGER 3: Auditoría de cambios en contratos
-- Se dispara al modificar un contrato
-- Registra cambios de estado especialmente
-- =============================================
CREATE OR ALTER TRIGGER Membresia.trg_Contrato_Vencimiento
ON Membresia.MembresiaContrato
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Registrar en auditoría solo cuando cambia el estado
    INSERT INTO Auditoria.LogCambios
        (Tabla, Operacion, RegistroID, ValorAnterior, ValorNuevo, Usuario)
    SELECT
        'Membresia.MembresiaContrato', 'U',
        CAST(i.ContratoID AS VARCHAR),
        '{"Estado":"' + d.Estado + '"}',
        '{"Estado":"' + i.Estado + '","FechaFin":"' +
         CAST(i.FechaFin AS VARCHAR) + '"}',
        SYSTEM_USER
    FROM inserted i
    JOIN deleted  d ON i.ContratoID = d.ContratoID
    WHERE d.Estado != i.Estado;  -- solo cuando cambia el estado
END;
GO

-- =============================================
-- VERIFICACION FINAL
-- =============================================
SELECT
    s.name          AS Esquema,
    t.name          AS Tabla,
    tr.name         AS Trigger_Nombre,
    tr.is_disabled  AS Deshabilitado,
    tr.create_date
FROM sys.triggers tr
JOIN sys.tables  t ON tr.parent_id  = t.object_id
JOIN sys.schemas s ON t.schema_id   = s.schema_id
WHERE s.name IN ('Membresia','Operaciones','Finanzas')
ORDER BY s.name;
GO
