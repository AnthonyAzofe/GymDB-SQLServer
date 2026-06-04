-- =============================================
-- GYMDB - SCRIPT 03: Modelo de Datos
-- =============================================
-- Descripcion: Crea las 15 tablas del modelo
--              distribuidas en 6 esquemas de negocio
-- Instancia:   DESKTOP-T4PEHDE (PRIMARY)
-- Autor:       GymDB Project
-- Fecha:       2026
-- =============================================

USE GymDB;
GO

-- =============================================
-- ESQUEMA: RRHH
-- =============================================

-- Tabla de cargos y puestos del gym
CREATE TABLE RRHH.Cargo (
    CargoID         INT IDENTITY(1,1)   NOT NULL,
    Nombre          VARCHAR(100)        NOT NULL,
    Descripcion     VARCHAR(500)        NULL,
    NivelJerarquico TINYINT             NOT NULL,  -- 1=Gerente 2=Supervisor 3=Operativo
    SalarioBase     DECIMAL(10,2)       NOT NULL,
    SalarioMaximo   DECIMAL(10,2)       NOT NULL,
    Activo          BIT                 NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME2           NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Cargo          PRIMARY KEY (CargoID),
    CONSTRAINT CK_Cargo_Nivel    CHECK (NivelJerarquico BETWEEN 1 AND 5),
    CONSTRAINT CK_Cargo_Salario  CHECK (SalarioMaximo >= SalarioBase)
);

-- Tabla principal de empleados
CREATE TABLE RRHH.Empleado (
    EmpleadoID          INT IDENTITY(1,1)   NOT NULL,
    CargoID             INT                 NOT NULL,
    Cedula              VARCHAR(20)         NOT NULL,
    Nombre              VARCHAR(100)        NOT NULL,
    Apellido1           VARCHAR(100)        NOT NULL,
    Apellido2           VARCHAR(100)        NULL,
    FechaNacimiento     DATE                NOT NULL,
    Genero              CHAR(1)             NOT NULL,  -- M/F/O
    Telefono            VARCHAR(20)         NOT NULL,
    TelefonoEmergencia  VARCHAR(20)         NULL,
    Email               VARCHAR(150)        NOT NULL,
    Direccion           VARCHAR(300)        NOT NULL,
    FechaIngreso        DATE                NOT NULL,
    FechaEgreso         DATE                NULL,
    Salario             DECIMAL(10,2)       NOT NULL,
    IBAN                VARCHAR(30)         NULL,
    Activo              BIT                 NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME2           NOT NULL DEFAULT GETDATE(),
    FechaModificacion   DATETIME2           NULL,
    CreadoPor           VARCHAR(100)        NOT NULL DEFAULT SYSTEM_USER,
    CONSTRAINT PK_Empleado        PRIMARY KEY (EmpleadoID),
    CONSTRAINT UQ_Empleado_Cedula UNIQUE (Cedula),
    CONSTRAINT UQ_Empleado_Email  UNIQUE (Email),
    CONSTRAINT FK_Empleado_Cargo  FOREIGN KEY (CargoID)
        REFERENCES RRHH.Cargo(CargoID),
    CONSTRAINT CK_Empleado_Genero CHECK (Genero IN ('M','F','O')),
    CONSTRAINT CK_Empleado_Salario CHECK (Salario > 0)
);

-- =============================================
-- ESQUEMA: Membresia
-- =============================================

-- Tipos de membresia disponibles en el gym
CREATE TABLE Membresia.TipoMembresia (
    TipoMembresiaID INT IDENTITY(1,1)   NOT NULL,
    Nombre          VARCHAR(100)        NOT NULL,
    Descripcion     VARCHAR(500)        NULL,
    DuracionDias    INT                 NOT NULL,  -- 30, 90, 180, 365
    Precio          DECIMAL(10,2)       NOT NULL,
    AccesoClases    BIT                 NOT NULL DEFAULT 1,
    AccesoSauna     BIT                 NOT NULL DEFAULT 0,
    AccesoPiscina   BIT                 NOT NULL DEFAULT 0,
    ClasesIncluidas INT                 NOT NULL DEFAULT 0,
    Activo          BIT                 NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME2           NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_TipoMembresia         PRIMARY KEY (TipoMembresiaID),
    CONSTRAINT CK_TipoMembresia_Duracion CHECK (DuracionDias > 0),
    CONSTRAINT CK_TipoMembresia_Precio   CHECK (Precio >= 0)
);

-- Tabla principal de miembros del gym
CREATE TABLE Membresia.Miembro (
    MiembroID           INT IDENTITY(1,1)   NOT NULL,
    Cedula              VARCHAR(20)         NOT NULL,
    Nombre              VARCHAR(100)        NOT NULL,
    Apellido1           VARCHAR(100)        NOT NULL,
    Apellido2           VARCHAR(100)        NULL,
    FechaNacimiento     DATE                NOT NULL,
    Genero              CHAR(1)             NOT NULL,
    Telefono            VARCHAR(20)         NOT NULL,
    TelefonoEmergencia  VARCHAR(20)         NULL,
    Email               VARCHAR(150)        NOT NULL,
    Direccion           VARCHAR(300)        NOT NULL,
    ContactoEmergencia  VARCHAR(150)        NULL,
    PesoKg              DECIMAL(5,2)        NULL,
    TallaM              DECIMAL(4,2)        NULL,
    ObservacionesMedicas VARCHAR(1000)      NULL,
    FechaRegistro       DATETIME2           NOT NULL DEFAULT GETDATE(),
    FechaModificacion   DATETIME2           NULL,
    UltimoAcceso        DATETIME2           NULL,
    Activo              BIT                 NOT NULL DEFAULT 1,
    FotoURL             VARCHAR(500)        NULL,
    CreadoPor           VARCHAR(100)        NOT NULL DEFAULT SYSTEM_USER,
    CONSTRAINT PK_Miembro        PRIMARY KEY (MiembroID),
    CONSTRAINT UQ_Miembro_Cedula UNIQUE (Cedula),
    CONSTRAINT UQ_Miembro_Email  UNIQUE (Email),
    CONSTRAINT CK_Miembro_Genero CHECK (Genero IN ('M','F','O'))
);

-- Contratos de membresia por miembro
CREATE TABLE Membresia.MembresiaContrato (
    ContratoID      INT IDENTITY(1,1)   NOT NULL,
    MiembroID       INT                 NOT NULL,
    TipoMembresiaID INT                 NOT NULL,
    EmpleadoID      INT                 NOT NULL,  -- quien vendio
    FechaInicio     DATE                NOT NULL,
    FechaFin        DATE                NOT NULL,
    PrecioPagado    DECIMAL(10,2)       NOT NULL,
    Descuento       DECIMAL(5,2)        NOT NULL DEFAULT 0,
    Estado          VARCHAR(20)         NOT NULL DEFAULT 'Activo',
    MotivoCongelado VARCHAR(500)        NULL,
    FechaCongelado  DATE                NULL,
    DiasCongelados  INT                 NOT NULL DEFAULT 0,
    ClasesRestantes INT                 NOT NULL DEFAULT 0,
    Renovacion      BIT                 NOT NULL DEFAULT 0,
    ContratoAnterior INT                NULL,
    FechaCreacion   DATETIME2           NOT NULL DEFAULT GETDATE(),
    CreadoPor       VARCHAR(100)        NOT NULL DEFAULT SYSTEM_USER,
    CONSTRAINT PK_MembresiaContrato  PRIMARY KEY (ContratoID),
    CONSTRAINT FK_Contrato_Miembro   FOREIGN KEY (MiembroID)
        REFERENCES Membresia.Miembro(MiembroID),
    CONSTRAINT FK_Contrato_Tipo      FOREIGN KEY (TipoMembresiaID)
        REFERENCES Membresia.TipoMembresia(TipoMembresiaID),
    CONSTRAINT FK_Contrato_Empleado  FOREIGN KEY (EmpleadoID)
        REFERENCES RRHH.Empleado(EmpleadoID),
    CONSTRAINT CK_Contrato_Fechas   CHECK (FechaFin > FechaInicio),
    CONSTRAINT CK_Contrato_Estado   CHECK (Estado IN
        ('Activo','Vencido','Cancelado','Congelado'))
);

-- Registro de accesos al gym (torniquete)
-- Va en FG_Historico por alto volumen de registros
CREATE TABLE Membresia.RegistroAcceso (
    AccesoID            BIGINT IDENTITY(1,1) NOT NULL,
    MiembroID           INT                  NOT NULL,
    ContratoID          INT                  NOT NULL,
    FechaHoraEntrada    DATETIME2            NOT NULL DEFAULT GETDATE(),
    FechaHoraSalida     DATETIME2            NULL,
    MinutosEstadia      AS DATEDIFF(MINUTE,
                            FechaHoraEntrada,
                            FechaHoraSalida),           -- columna calculada automaticamente
    TipoAcceso          VARCHAR(20)          NOT NULL DEFAULT 'Normal',
    Observacion         VARCHAR(300)         NULL,
    CONSTRAINT PK_RegistroAcceso  PRIMARY KEY (AccesoID),
    CONSTRAINT FK_Acceso_Miembro  FOREIGN KEY (MiembroID)
        REFERENCES Membresia.Miembro(MiembroID),
    CONSTRAINT FK_Acceso_Contrato FOREIGN KEY (ContratoID)
        REFERENCES Membresia.MembresiaContrato(ContratoID)
) ON FG_Historico;  -- filegroup de historico en disco externo
GO

-- =============================================
-- ESQUEMA: Operaciones
-- =============================================

-- Disciplinas que se imparten en el gym
CREATE TABLE Operaciones.Disciplina (
    DisciplinaID    INT IDENTITY(1,1)   NOT NULL,
    Nombre          VARCHAR(100)        NOT NULL,
    Descripcion     VARCHAR(500)        NULL,
    Intensidad      VARCHAR(20)         NOT NULL,  -- Baja/Media/Alta
    CaloriasPromedio INT                NULL,
    RequiereEquipo  BIT                 NOT NULL DEFAULT 0,
    Activo          BIT                 NOT NULL DEFAULT 1,
    CONSTRAINT PK_Disciplina            PRIMARY KEY (DisciplinaID),
    CONSTRAINT CK_Disciplina_Intensidad CHECK
        (Intensidad IN ('Baja','Media','Alta'))
);

-- Instructores del gym (extiende Empleado)
CREATE TABLE Operaciones.Instructor (
    InstructorID    INT IDENTITY(1,1)   NOT NULL,
    EmpleadoID      INT                 NOT NULL,
    Especialidad    VARCHAR(200)        NOT NULL,
    Certificaciones VARCHAR(500)        NULL,
    AniosExperiencia TINYINT            NOT NULL DEFAULT 0,
    Calificacion    DECIMAL(3,2)        NOT NULL DEFAULT 5.00,
    MaxAlumnos      TINYINT             NOT NULL DEFAULT 20,
    Activo          BIT                 NOT NULL DEFAULT 1,
    CONSTRAINT PK_Instructor              PRIMARY KEY (InstructorID),
    CONSTRAINT UQ_Instructor_Empleado     UNIQUE (EmpleadoID),
    CONSTRAINT FK_Instructor_Empleado     FOREIGN KEY (EmpleadoID)
        REFERENCES RRHH.Empleado(EmpleadoID),
    CONSTRAINT CK_Instructor_Calificacion CHECK
        (Calificacion BETWEEN 1.00 AND 5.00)
);

-- Salones y espacios del gym
CREATE TABLE Operaciones.Salon (
    SalonID         INT IDENTITY(1,1)   NOT NULL,
    Nombre          VARCHAR(100)        NOT NULL,
    Descripcion     VARCHAR(300)        NULL,
    Capacidad       TINYINT             NOT NULL,
    TieneEspejo     BIT                 NOT NULL DEFAULT 1,
    TieneAire       BIT                 NOT NULL DEFAULT 1,
    TieneSonido     BIT                 NOT NULL DEFAULT 1,
    Piso            TINYINT             NOT NULL DEFAULT 1,
    Activo          BIT                 NOT NULL DEFAULT 1,
    CONSTRAINT PK_Salon PRIMARY KEY (SalonID)
);

-- Clases programadas en el horario semanal
CREATE TABLE Operaciones.Clase (
    ClaseID         INT IDENTITY(1,1)   NOT NULL,
    DisciplinaID    INT                 NOT NULL,
    InstructorID    INT                 NOT NULL,
    SalonID         INT                 NOT NULL,
    Nombre          VARCHAR(150)        NOT NULL,
    DiaSemana       TINYINT             NOT NULL,  -- 1=Lunes 7=Domingo
    HoraInicio      TIME                NOT NULL,
    HoraFin         TIME                NOT NULL,
    Capacidad       TINYINT             NOT NULL,
    CupoDisponible  TINYINT             NOT NULL,
    EsPresencial    BIT                 NOT NULL DEFAULT 1,
    URLStreaming     VARCHAR(300)        NULL,
    Activo          BIT                 NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME2           NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Clase             PRIMARY KEY (ClaseID),
    CONSTRAINT FK_Clase_Disciplina  FOREIGN KEY (DisciplinaID)
        REFERENCES Operaciones.Disciplina(DisciplinaID),
    CONSTRAINT FK_Clase_Instructor  FOREIGN KEY (InstructorID)
        REFERENCES Operaciones.Instructor(InstructorID),
    CONSTRAINT FK_Clase_Salon       FOREIGN KEY (SalonID)
        REFERENCES Operaciones.Salon(SalonID),
    CONSTRAINT CK_Clase_DiaSemana   CHECK (DiaSemana BETWEEN 1 AND 7),
    CONSTRAINT CK_Clase_Horas       CHECK (HoraFin > HoraInicio)
);

-- Reservas de clases por miembro
-- Va en FG_Historico por alto volumen
CREATE TABLE Operaciones.ReservaClase (
    ReservaID       BIGINT IDENTITY(1,1) NOT NULL,
    ClaseID         INT                  NOT NULL,
    MiembroID       INT                  NOT NULL,
    ContratoID      INT                  NOT NULL,
    FechaReserva    DATETIME2            NOT NULL DEFAULT GETDATE(),
    FechaClase      DATE                 NOT NULL,
    Estado          VARCHAR(20)          NOT NULL DEFAULT 'Confirmada',
    Asistio         BIT                  NULL,
    Calificacion    TINYINT              NULL,   -- calificacion del miembro 1-5
    Comentario      VARCHAR(500)         NULL,
    CONSTRAINT PK_ReservaClase        PRIMARY KEY (ReservaID),
    CONSTRAINT FK_Reserva_Clase       FOREIGN KEY (ClaseID)
        REFERENCES Operaciones.Clase(ClaseID),
    CONSTRAINT FK_Reserva_Miembro     FOREIGN KEY (MiembroID)
        REFERENCES Membresia.Miembro(MiembroID),
    CONSTRAINT FK_Reserva_Contrato    FOREIGN KEY (ContratoID)
        REFERENCES Membresia.MembresiaContrato(ContratoID),
    CONSTRAINT CK_Reserva_Estado      CHECK (Estado IN
        ('Confirmada','Cancelada','EnEspera','NoShow')),
    CONSTRAINT CK_Reserva_Calificacion CHECK
        (Calificacion BETWEEN 1 AND 5 OR Calificacion IS NULL)
) ON FG_Historico;
GO

-- =============================================
-- ESQUEMA: Finanzas
-- =============================================

-- Metodos de pago aceptados
CREATE TABLE Finanzas.MetodoPago (
    MetodoPagoID    INT IDENTITY(1,1)   NOT NULL,
    Nombre          VARCHAR(50)         NOT NULL,  -- Efectivo/SINPE/Tarjeta
    Activo          BIT                 NOT NULL DEFAULT 1,
    CONSTRAINT PK_MetodoPago PRIMARY KEY (MetodoPagoID)
);

-- Registro de pagos y cobros
-- Va en FG_Historico por alto volumen
CREATE TABLE Finanzas.Pago (
    PagoID          BIGINT IDENTITY(1,1) NOT NULL,
    ContratoID      INT                  NOT NULL,
    MiembroID       INT                  NOT NULL,
    EmpleadoID      INT                  NOT NULL,  -- quien cobro
    MetodoPagoID    INT                  NOT NULL,
    Monto           DECIMAL(10,2)        NOT NULL,
    Descuento       DECIMAL(10,2)        NOT NULL DEFAULT 0,
    MontoFinal      AS (Monto - Descuento),           -- columna calculada
    Referencia      VARCHAR(100)         NULL,         -- numero de transaccion
    FechaPago       DATETIME2            NOT NULL DEFAULT GETDATE(),
    Estado          VARCHAR(20)          NOT NULL DEFAULT 'Completado',
    Observacion     VARCHAR(500)         NULL,
    CONSTRAINT PK_Pago          PRIMARY KEY (PagoID),
    CONSTRAINT FK_Pago_Contrato FOREIGN KEY (ContratoID)
        REFERENCES Membresia.MembresiaContrato(ContratoID),
    CONSTRAINT FK_Pago_Miembro  FOREIGN KEY (MiembroID)
        REFERENCES Membresia.Miembro(MiembroID),
    CONSTRAINT FK_Pago_Empleado FOREIGN KEY (EmpleadoID)
        REFERENCES RRHH.Empleado(EmpleadoID),
    CONSTRAINT FK_Pago_Metodo   FOREIGN KEY (MetodoPagoID)
        REFERENCES Finanzas.MetodoPago(MetodoPagoID),
    CONSTRAINT CK_Pago_Monto    CHECK (Monto > 0),
    CONSTRAINT CK_Pago_Estado   CHECK (Estado IN
        ('Completado','Anulado','Pendiente','Reembolsado'))
) ON FG_Historico;
GO

-- =============================================
-- ESQUEMA: Inventario
-- =============================================

-- Equipos del gym con control de mantenimiento
CREATE TABLE Inventario.Equipo (
    EquipoID            INT IDENTITY(1,1)   NOT NULL,
    SalonID             INT                 NULL,
    Nombre              VARCHAR(150)        NOT NULL,
    Marca               VARCHAR(100)        NULL,
    Modelo              VARCHAR(100)        NULL,
    NumeroSerie         VARCHAR(100)        NULL,
    FechaCompra         DATE                NULL,
    CostoCompra         DECIMAL(10,2)       NULL,
    VidaUtilAnios       TINYINT             NULL,
    Estado              VARCHAR(20)         NOT NULL DEFAULT 'Operativo',
    UltimoMantenimiento DATE                NULL,
    ProximoMantenimiento DATE               NULL,
    Observaciones       VARCHAR(500)        NULL,
    Activo              BIT                 NOT NULL DEFAULT 1,
    CONSTRAINT PK_Equipo        PRIMARY KEY (EquipoID),
    CONSTRAINT FK_Equipo_Salon  FOREIGN KEY (SalonID)
        REFERENCES Operaciones.Salon(SalonID),
    CONSTRAINT CK_Equipo_Estado CHECK (Estado IN
        ('Operativo','EnMantenimiento','Dañado','DadoDeBaja'))
);
GO

-- =============================================
-- ESQUEMA: Auditoria
-- =============================================

-- Log de todos los cambios en tablas criticas
-- Almacena datos anteriores y nuevos en formato JSON
CREATE TABLE Auditoria.LogCambios (
    LogID           BIGINT IDENTITY(1,1) NOT NULL,
    Tabla           VARCHAR(100)         NOT NULL,
    Operacion       CHAR(1)              NOT NULL,  -- I=Insert U=Update D=Delete
    RegistroID      VARCHAR(50)          NOT NULL,  -- PK del registro afectado
    ValorAnterior   NVARCHAR(MAX)        NULL,       -- datos antes del cambio en JSON
    ValorNuevo      NVARCHAR(MAX)        NULL,       -- datos despues del cambio en JSON
    Usuario         VARCHAR(100)         NOT NULL DEFAULT SYSTEM_USER,
    FechaHora       DATETIME2            NOT NULL DEFAULT GETDATE(),
    Aplicacion      VARCHAR(100)         NULL DEFAULT APP_NAME(),
    HostName        VARCHAR(100)         NULL DEFAULT HOST_NAME(),
    CONSTRAINT PK_LogCambios PRIMARY KEY (LogID)
) ON FG_Historico;
GO

-- =============================================
-- VERIFICACION FINAL
-- =============================================
SELECT
    s.name      AS Esquema,
    t.name      AS Tabla,
    p.rows      AS FilasActuales,
    fg.name     AS FileGroup
FROM sys.tables t
JOIN sys.schemas s      ON t.schema_id     = s.schema_id
JOIN sys.indexes i      ON t.object_id     = i.object_id AND i.index_id <= 1
JOIN sys.partitions p   ON i.object_id     = p.object_id AND i.index_id = p.index_id
JOIN sys.data_spaces fg ON i.data_space_id = fg.data_space_id
WHERE s.name IN ('RRHH','Membresia','Operaciones','Finanzas','Inventario','Auditoria')
ORDER BY s.name, t.name;
GO
