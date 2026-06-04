-- =============================================
-- GYMDB - SCRIPT 07: Stored Procedures
-- =============================================
-- Descripcion: CRUDs completos para las entidades
--              principales del gym usando SPs con
--              manejo de errores y transacciones
-- Instancia:   DESKTOP-T4PEHDE (PRIMARY)
-- Autor:       GymDB Project
-- Fecha:       2026
-- =============================================

USE GymDB;
GO

-- =============================================
-- SECCIÓN 1: CRUD MIEMBROS
-- =============================================

-- SP: Insertar nuevo miembro
CREATE OR ALTER PROCEDURE Membresia.usp_InsertarMiembro
    @Cedula               VARCHAR(20),
    @Nombre               VARCHAR(100),
    @Apellido1            VARCHAR(100),
    @Apellido2            VARCHAR(100)    = NULL,
    @FechaNacimiento      DATE,
    @Genero               CHAR(1),
    @Telefono             VARCHAR(20),
    @TelefonoEmergencia   VARCHAR(20)     = NULL,
    @Email                VARCHAR(150),
    @Direccion            VARCHAR(300),
    @ContactoEmergencia   VARCHAR(150)    = NULL,
    @PesoKg               DECIMAL(5,2)    = NULL,
    @TallaM               DECIMAL(4,2)    = NULL,
    @ObservacionesMedicas VARCHAR(1000)   = NULL,
    @MiembroID            INT             OUTPUT  -- retorna ID creado
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

            -- Validar cédula única
            IF EXISTS (SELECT 1 FROM Membresia.Miembro WHERE Cedula = @Cedula)
                THROW 50001, 'Ya existe un miembro con esa cédula.', 1;

            -- Validar email único
            IF EXISTS (SELECT 1 FROM Membresia.Miembro WHERE Email = @Email)
                THROW 50002, 'Ya existe un miembro con ese email.', 1;

            INSERT INTO Membresia.Miembro
                (Cedula, Nombre, Apellido1, Apellido2,
                 FechaNacimiento, Genero, Telefono, TelefonoEmergencia,
                 Email, Direccion, ContactoEmergencia,
                 PesoKg, TallaM, ObservacionesMedicas)
            VALUES
                (@Cedula, @Nombre, @Apellido1, @Apellido2,
                 @FechaNacimiento, @Genero, @Telefono, @TelefonoEmergencia,
                 @Email, @Direccion, @ContactoEmergencia,
                 @PesoKg, @TallaM, @ObservacionesMedicas);

            SET @MiembroID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        -- Retornar el miembro creado
        SELECT * FROM Membresia.Miembro WHERE MiembroID = @MiembroID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP: Obtener miembro por ID o Cédula
CREATE OR ALTER PROCEDURE Membresia.usp_ObtenerMiembro
    @MiembroID  INT             = NULL,
    @Cedula     VARCHAR(20)     = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @MiembroID IS NULL AND @Cedula IS NULL
        THROW 50003, 'Debe indicar MiembroID o Cédula.', 1;

    SELECT
        m.MiembroID,
        m.Cedula,
        m.Nombre + ' ' + m.Apellido1 +
            ISNULL(' ' + m.Apellido2,'')    AS NombreCompleto,
        m.Genero,
        m.Telefono,
        m.Email,
        m.Direccion,
        m.PesoKg,
        m.TallaM,
        m.ObservacionesMedicas,
        m.FechaRegistro,
        m.UltimoAcceso,
        m.Activo,
        c.ContratoID,
        c.Estado                            AS EstadoContrato,
        tm.Nombre                           AS TipoMembresia,
        c.FechaInicio,
        c.FechaFin,
        DATEDIFF(DAY,GETDATE(),c.FechaFin)  AS DiasRestantes,
        c.ClasesRestantes,
        (SELECT COUNT(*) FROM Membresia.RegistroAcceso ra
         WHERE ra.MiembroID = m.MiembroID)  AS TotalAccesos,
        (SELECT COUNT(*) FROM Operaciones.ReservaClase rc
         WHERE rc.MiembroID = m.MiembroID
           AND rc.Asistio = 1)              AS ClasesTomadas
    FROM Membresia.Miembro m
    LEFT JOIN Membresia.MembresiaContrato c
        ON m.MiembroID = c.MiembroID AND c.Estado = 'Activo'
    LEFT JOIN Membresia.TipoMembresia tm
        ON c.TipoMembresiaID = tm.TipoMembresiaID
    WHERE (@MiembroID IS NULL OR m.MiembroID = @MiembroID)
      AND (@Cedula    IS NULL OR m.Cedula    = @Cedula);
END;
GO

-- SP: Actualizar datos del miembro
-- Solo actualiza los campos que vienen con valor (patron ISNULL)
CREATE OR ALTER PROCEDURE Membresia.usp_ActualizarMiembro
    @MiembroID            INT,
    @Telefono             VARCHAR(20)     = NULL,
    @TelefonoEmergencia   VARCHAR(20)     = NULL,
    @Email                VARCHAR(150)    = NULL,
    @Direccion            VARCHAR(300)    = NULL,
    @ContactoEmergencia   VARCHAR(150)    = NULL,
    @PesoKg               DECIMAL(5,2)    = NULL,
    @TallaM               DECIMAL(4,2)    = NULL,
    @ObservacionesMedicas VARCHAR(1000)   = NULL,
    @Activo               BIT             = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM Membresia.Miembro WHERE MiembroID = @MiembroID)
                THROW 50004, 'Miembro no encontrado.', 1;

            UPDATE Membresia.Miembro SET
                Telefono             = ISNULL(@Telefono,            Telefono),
                TelefonoEmergencia   = ISNULL(@TelefonoEmergencia,  TelefonoEmergencia),
                Email                = ISNULL(@Email,               Email),
                Direccion            = ISNULL(@Direccion,           Direccion),
                ContactoEmergencia   = ISNULL(@ContactoEmergencia,  ContactoEmergencia),
                PesoKg               = ISNULL(@PesoKg,              PesoKg),
                TallaM               = ISNULL(@TallaM,              TallaM),
                ObservacionesMedicas = ISNULL(@ObservacionesMedicas,ObservacionesMedicas),
                Activo               = ISNULL(@Activo,              Activo),
                FechaModificacion    = GETDATE()
            WHERE MiembroID = @MiembroID;

        COMMIT TRANSACTION;
        SELECT 'Miembro actualizado correctamente' AS Resultado;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP: Desactivar miembro (Soft Delete)
-- Nunca se borran registros fisicamente
CREATE OR ALTER PROCEDURE Membresia.usp_EliminarMiembro
    @MiembroID  INT,
    @Motivo     VARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM Membresia.Miembro WHERE MiembroID = @MiembroID)
                THROW 50004, 'Miembro no encontrado.', 1;

            -- Soft delete: desactivar en lugar de borrar
            UPDATE Membresia.Miembro SET
                Activo            = 0,
                FechaModificacion = GETDATE()
            WHERE MiembroID = @MiembroID;

            -- Cancelar contratos activos del miembro
            UPDATE Membresia.MembresiaContrato SET
                Estado = 'Cancelado'
            WHERE MiembroID = @MiembroID
              AND Estado    = 'Activo';

            -- Registrar en auditoría
            INSERT INTO Auditoria.LogCambios
                (Tabla, Operacion, RegistroID, ValorNuevo)
            VALUES
                ('Membresia.Miembro', 'D',
                 CAST(@MiembroID AS VARCHAR),
                 '{"motivo":"' + ISNULL(@Motivo,'Sin motivo') + '"}');

        COMMIT TRANSACTION;
        SELECT 'Miembro desactivado correctamente' AS Resultado;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- SECCIÓN 2: CRUD CONTRATOS
-- =============================================

-- SP: Crear contrato de membresia
CREATE OR ALTER PROCEDURE Membresia.usp_CrearContrato
    @MiembroID          INT,
    @TipoMembresiaID    INT,
    @EmpleadoID         INT,
    @FechaInicio        DATE            = NULL,  -- default hoy
    @Descuento          DECIMAL(5,2)    = 0,
    @ContratoID         INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM Membresia.Miembro
                           WHERE MiembroID = @MiembroID AND Activo = 1)
                THROW 50005, 'Miembro no encontrado o inactivo.', 1;

            IF NOT EXISTS (SELECT 1 FROM Membresia.TipoMembresia
                           WHERE TipoMembresiaID = @TipoMembresiaID AND Activo = 1)
                THROW 50006, 'Tipo de membresía no válido.', 1;

            IF EXISTS (SELECT 1 FROM Membresia.MembresiaContrato
                       WHERE MiembroID = @MiembroID AND Estado = 'Activo')
                THROW 50007, 'El miembro ya tiene un contrato activo.', 1;

            SET @FechaInicio = ISNULL(@FechaInicio, CAST(GETDATE() AS DATE));

            DECLARE @Precio          DECIMAL(10,2);
            DECLARE @Duracion        INT;
            DECLARE @ClasesIncluidas INT;

            SELECT
                @Precio          = Precio,
                @Duracion        = DuracionDias,
                @ClasesIncluidas = ClasesIncluidas
            FROM Membresia.TipoMembresia
            WHERE TipoMembresiaID = @TipoMembresiaID;

            INSERT INTO Membresia.MembresiaContrato
                (MiembroID, TipoMembresiaID, EmpleadoID,
                 FechaInicio, FechaFin, PrecioPagado,
                 Descuento, Estado, ClasesRestantes)
            VALUES
                (@MiembroID, @TipoMembresiaID, @EmpleadoID,
                 @FechaInicio,
                 DATEADD(DAY, @Duracion, @FechaInicio),
                 @Precio, @Descuento, 'Activo',
                 @ClasesIncluidas);

            SET @ContratoID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT
            c.*,
            tm.Nombre AS TipoMembresia,
            m.Nombre + ' ' + m.Apellido1 AS NombreMiembro
        FROM Membresia.MembresiaContrato c
        JOIN Membresia.TipoMembresia tm ON c.TipoMembresiaID = tm.TipoMembresiaID
        JOIN Membresia.Miembro m        ON c.MiembroID       = m.MiembroID
        WHERE c.ContratoID = @ContratoID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- SECCIÓN 3: CRUD ACCESOS (torniquete)
-- =============================================

-- SP: Registrar entrada al gym
CREATE OR ALTER PROCEDURE Membresia.usp_RegistrarEntrada
    @Cedula     VARCHAR(20),
    @AccesoID   BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

            DECLARE @MiembroID  INT;
            DECLARE @ContratoID INT;

            SELECT @MiembroID = MiembroID
            FROM Membresia.Miembro
            WHERE Cedula = @Cedula AND Activo = 1;

            IF @MiembroID IS NULL
                THROW 50008, 'Miembro no encontrado o inactivo.', 1;

            -- Buscar contrato activo vigente
            SELECT @ContratoID = ContratoID
            FROM Membresia.MembresiaContrato
            WHERE MiembroID = @MiembroID
              AND Estado    = 'Activo'
              AND FechaFin >= CAST(GETDATE() AS DATE);

            IF @ContratoID IS NULL
                THROW 50009, 'El miembro no tiene membresía vigente.', 1;

            -- Verificar que no tenga entrada abierta sin salida
            IF EXISTS (SELECT 1 FROM Membresia.RegistroAcceso
                       WHERE MiembroID      = @MiembroID
                         AND FechaHoraSalida IS NULL)
                THROW 50010, 'El miembro ya tiene una entrada sin salida registrada.', 1;

            INSERT INTO Membresia.RegistroAcceso
                (MiembroID, ContratoID, FechaHoraEntrada)
            VALUES
                (@MiembroID, @ContratoID, GETDATE());

            SET @AccesoID = SCOPE_IDENTITY();

            -- Actualizar último acceso
            UPDATE Membresia.Miembro SET
                UltimoAcceso = GETDATE()
            WHERE MiembroID = @MiembroID;

        COMMIT TRANSACTION;

        SELECT
            a.AccesoID,
            m.Nombre + ' ' + m.Apellido1 AS NombreMiembro,
            a.FechaHoraEntrada,
            'Acceso permitido' AS Resultado
        FROM Membresia.RegistroAcceso a
        JOIN Membresia.Miembro m ON a.MiembroID = m.MiembroID
        WHERE a.AccesoID = @AccesoID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP: Registrar salida del gym
CREATE OR ALTER PROCEDURE Membresia.usp_RegistrarSalida
    @Cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

            DECLARE @MiembroID INT;
            DECLARE @AccesoID  BIGINT;

            SELECT @MiembroID = MiembroID
            FROM Membresia.Miembro
            WHERE Cedula = @Cedula AND Activo = 1;

            IF @MiembroID IS NULL
                THROW 50008, 'Miembro no encontrado.', 1;

            -- Buscar entrada abierta
            SELECT @AccesoID = AccesoID
            FROM Membresia.RegistroAcceso
            WHERE MiembroID      = @MiembroID
              AND FechaHoraSalida IS NULL;

            IF @AccesoID IS NULL
                THROW 50011, 'No se encontró entrada abierta para este miembro.', 1;

            UPDATE Membresia.RegistroAcceso SET
                FechaHoraSalida = GETDATE()
            WHERE AccesoID = @AccesoID;

        COMMIT TRANSACTION;

        SELECT
            a.AccesoID,
            m.Nombre + ' ' + m.Apellido1 AS NombreMiembro,
            a.FechaHoraEntrada,
            a.FechaHoraSalida,
            a.MinutosEstadia             AS MinutosEnGym,
            'Salida registrada'          AS Resultado
        FROM Membresia.RegistroAcceso a
        JOIN Membresia.Miembro m ON a.MiembroID = m.MiembroID
        WHERE a.AccesoID = @AccesoID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- SECCIÓN 4: CRUD PAGOS
-- =============================================

-- SP: Registrar pago de membresia
CREATE OR ALTER PROCEDURE Finanzas.usp_RegistrarPago
    @ContratoID     INT,
    @EmpleadoID     INT,
    @MetodoPagoID   INT,
    @Monto          DECIMAL(10,2),
    @Descuento      DECIMAL(10,2)   = 0,
    @Referencia     VARCHAR(100)    = NULL,
    @PagoID         BIGINT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM Membresia.MembresiaContrato
                           WHERE ContratoID = @ContratoID)
                THROW 50012, 'Contrato no encontrado.', 1;

            IF @Monto <= 0
                THROW 50013, 'El monto debe ser mayor a cero.', 1;

            DECLARE @MiembroID INT;
            SELECT @MiembroID = MiembroID
            FROM Membresia.MembresiaContrato
            WHERE ContratoID = @ContratoID;

            INSERT INTO Finanzas.Pago
                (ContratoID, MiembroID, EmpleadoID, MetodoPagoID,
                 Monto, Descuento, Referencia, Estado)
            VALUES
                (@ContratoID, @MiembroID, @EmpleadoID, @MetodoPagoID,
                 @Monto, @Descuento, @Referencia, 'Completado');

            SET @PagoID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT
            p.PagoID,
            m.Nombre + ' ' + m.Apellido1 AS NombreMiembro,
            p.Monto,
            p.Descuento,
            p.MontoFinal,
            mp.Nombre                    AS MetodoPago,
            p.FechaPago,
            p.Estado
        FROM Finanzas.Pago p
        JOIN Membresia.Miembro m    ON p.MiembroID    = m.MiembroID
        JOIN Finanzas.MetodoPago mp ON p.MetodoPagoID = mp.MetodoPagoID
        WHERE p.PagoID = @PagoID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- VERIFICACION FINAL
-- =============================================
SELECT
    s.name  AS Esquema,
    p.name  AS StoredProcedure,
    p.create_date,
    p.modify_date
FROM sys.procedures p
JOIN sys.schemas s ON p.schema_id = s.schema_id
WHERE s.name IN ('Membresia','Finanzas','Operaciones','RRHH')
ORDER BY s.name, p.name;
GO
