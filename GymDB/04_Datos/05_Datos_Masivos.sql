-- =============================================
-- GYMDB - SCRIPT 05: Datos Masivos
-- =============================================
-- Descripcion: Genera datos masivos usando loops
--              y tablas temporales:
--              - 500 miembros
--              - 500 contratos
--              - 500 pagos
--              - ~5000 accesos
--              - ~2000 reservas de clases
-- Instancia:   DESKTOP-T4PEHDE (PRIMARY)
-- Autor:       GymDB Project
-- Fecha:       2026
-- NOTA: Este script puede tardar 1-2 minutos
-- =============================================

USE GymDB;
GO

-- =============================================
-- SECCIÓN 1: TABLAS TEMPORALES DE APOYO
-- Las # son locales a la sesion
-- =============================================

-- Nombres para combinar aleatoriamente
CREATE TABLE #Nombres   (ID INT IDENTITY(1,1), Nombre VARCHAR(50), Genero CHAR(1));
CREATE TABLE #Apellidos (ID INT IDENTITY(1,1), Apellido VARCHAR(50));
CREATE TABLE #Ciudades  (ID INT IDENTITY(1,1), Ciudad VARCHAR(100));

INSERT INTO #Nombres (Nombre, Genero) VALUES
('Carlos','M'),('Luis','M'),('Diego','M'),('Andres','M'),('Sebastian','M'),
('Gabriel','M'),('Daniel','M'),('Ricardo','M'),('Jorge','M'),('Marco','M'),
('Pablo','M'),('Esteban','M'),('Hector','M'),('Kevin','M'),('Manuel','M'),
('Maria','F'),('Ana','F'),('Sofia','F'),('Valeria','F'),('Camila','F'),
('Isabella','F'),('Lucia','F'),('Paula','F'),('Fernanda','F'),('Natalia','F'),
('Diana','F'),('Alejandra','F'),('Silvia','F'),('Adriana','F'),('Laura','F'),
('Jose','M'),('Miguel','M'),('David','M'),('Oscar','M'),('Ivan','M'),
('Priscilla','F'),('Gabriela','F'),('Monica','F'),('Patricia','F'),('Andrea','F');

INSERT INTO #Apellidos (Apellido) VALUES
('Ramirez'),('Gonzalez'),('Mora'),('Castro'),('Jimenez'),('Lopez'),('Herrera'),
('Rojas'),('Nunez'),('Quesada'),('Blanco'),('Araya'),('Vega'),('Soto'),('Chaves'),
('Monge'),('Arias'),('Ruiz'),('Picado'),('Leon'),('Fonseca'),('Gamboa'),('Salas'),
('Brenes'),('Varela'),('Cruz'),('Solano'),('Badilla'),('Obando'),('Mora'),
('Hernandez'),('Perez'),('Martinez'),('Rodriguez'),('Sanchez'),('Torres'),
('Flores'),('Rivera'),('Diaz'),('Reyes');

INSERT INTO #Ciudades (Ciudad) VALUES
('San Jose, Escazu'),('San Jose, Santa Ana'),('San Jose, Curridabat'),
('San Jose, Moravia'),('San Jose, Zapote'),('San Jose, Tibas'),
('San Jose, Desamparados'),('San Jose, Hatillo'),('San Jose, San Pedro'),
('San Jose, Coronado'),('Heredia, Belen'),('Heredia, Santo Domingo'),
('Heredia, San Pablo'),('Heredia, Flores'),('Heredia, San Isidro'),
('Alajuela, San Ramon'),('Alajuela, Grecia'),('Alajuela, Palmares'),
('Alajuela, Atenas'),('Alajuela, Ciudad Quesada'),
('Cartago, Tres Rios'),('Cartago, La Union'),('Cartago, Paraiso'),
('Cartago, Turrialba'),('Limon, Pococi'),('Puntarenas, Jaco');
GO

-- =============================================
-- SECCIÓN 2: GENERAR 500 MIEMBROS
-- Usa WHILE loop con datos aleatorios
-- =============================================
DECLARE @i INT = 1;
DECLARE @NombreID INT, @Apellido1ID INT, @Apellido2ID INT, @CiudadID INT;
DECLARE @Nombre VARCHAR(50), @Apellido1 VARCHAR(50), @Apellido2 VARCHAR(50);
DECLARE @Genero CHAR(1), @Ciudad VARCHAR(100);
DECLARE @FechaNac DATE, @FechaReg DATETIME2;
DECLARE @Cedula VARCHAR(20), @Email VARCHAR(150);
DECLARE @Peso DECIMAL(6,2), @Talla DECIMAL(4,2);

WHILE @i <= 500
BEGIN
    -- Seleccionar datos aleatorios usando NEWID()
    SET @NombreID    = (ABS(CHECKSUM(NEWID())) % 40) + 1;
    SET @Apellido1ID = (ABS(CHECKSUM(NEWID())) % 40) + 1;
    SET @Apellido2ID = (ABS(CHECKSUM(NEWID())) % 40) + 1;
    SET @CiudadID    = (ABS(CHECKSUM(NEWID())) % 26) + 1;

    SELECT @Nombre  = Nombre, @Genero = Genero FROM #Nombres   WHERE ID = @NombreID;
    SELECT @Apellido1 = Apellido               FROM #Apellidos WHERE ID = @Apellido1ID;
    SELECT @Apellido2 = Apellido               FROM #Apellidos WHERE ID = @Apellido2ID;
    SELECT @Ciudad    = Ciudad                 FROM #Ciudades  WHERE ID = @CiudadID;

    -- Fecha nacimiento entre 1960 y 2005
    SET @FechaNac = DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 16000 + 6000), GETDATE());
    -- Fecha registro entre 2020 y hoy
    SET @FechaReg = DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 1800), GETDATE());

    SET @Cedula = '10200' + RIGHT('00000' + CAST(@i AS VARCHAR), 5);
    SET @Email  = LOWER(@Nombre) + '.' + LOWER(@Apellido1) +
                  CAST(@i AS VARCHAR) + '@gmail.com';

    -- Peso entre 45 y 115 kg
    SET @Peso  = CAST((ABS(CHECKSUM(NEWID())) % 70) + 45 AS DECIMAL(6,2))
               + CAST((ABS(CHECKSUM(NEWID())) % 10) AS DECIMAL(6,2)) / 10;
    -- Talla entre 1.50 y 2.00 m
    SET @Talla = CAST(((ABS(CHECKSUM(NEWID())) % 50) + 150) AS DECIMAL(5,2)) / 100;

    INSERT INTO Membresia.Miembro
        (Cedula, Nombre, Apellido1, Apellido2, FechaNacimiento, Genero,
         Telefono, TelefonoEmergencia, Email, Direccion,
         ContactoEmergencia, PesoKg, TallaM, FechaRegistro)
    VALUES
        (@Cedula, @Nombre, @Apellido1, @Apellido2,
         @FechaNac, @Genero,
         '8' + RIGHT('0000000' + CAST(@i * 7 AS VARCHAR), 7),
         '7' + RIGHT('0000000' + CAST(@i * 3 AS VARCHAR), 7),
         @Email, @Ciudad,
         @Nombre + ' ' + @Apellido2 + ' (Familiar)',
         @Peso, @Talla, @FechaReg);

    SET @i = @i + 1;
END;
GO

-- =============================================
-- SECCIÓN 3: CONTRATOS (uno por miembro)
-- =============================================
INSERT INTO Membresia.MembresiaContrato
    (MiembroID, TipoMembresiaID, EmpleadoID, FechaInicio, FechaFin,
     PrecioPagado, Descuento, Estado, ClasesRestantes, Renovacion)
SELECT
    m.MiembroID,
    CASE (ABS(CHECKSUM(NEWID())) % 10)
        WHEN 0 THEN 1  WHEN 1 THEN 2  WHEN 2 THEN 2
        WHEN 3 THEN 3  WHEN 4 THEN 4  WHEN 5 THEN 5
        WHEN 6 THEN 6  WHEN 7 THEN 7  WHEN 8 THEN 8
        ELSE 9
    END AS TipoMembresiaID,
    CASE (ABS(CHECKSUM(NEWID())) % 6)
        WHEN 0 THEN 11 WHEN 1 THEN 12 WHEN 2 THEN 13
        WHEN 3 THEN 14 WHEN 4 THEN 21 ELSE 22
    END AS EmpleadoID,
    CAST(DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 30, m.FechaRegistro) AS DATE),
    CAST(DATEADD(DAY,
        CASE (ABS(CHECKSUM(NEWID())) % 10)
            WHEN 0 THEN 30  WHEN 1 THEN 30  WHEN 2 THEN 30
            WHEN 3 THEN 30  WHEN 4 THEN 90  WHEN 5 THEN 90
            WHEN 6 THEN 180 WHEN 7 THEN 365 WHEN 8 THEN 30
            ELSE 30
        END,
        CAST(DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 30,
             m.FechaRegistro) AS DATE)) AS DATE),
    CASE (ABS(CHECKSUM(NEWID())) % 10)
        WHEN 0 THEN 25000  WHEN 1 THEN 35000  WHEN 2 THEN 35000
        WHEN 3 THEN 50000  WHEN 4 THEN 65000  WHEN 5 THEN 90000
        WHEN 6 THEN 160000 WHEN 7 THEN 280000 WHEN 8 THEN 18000
        ELSE 20000
    END,
    CASE (ABS(CHECKSUM(NEWID())) % 5) WHEN 0 THEN 10 ELSE 0 END,
    CASE
        WHEN DATEADD(DAY,30,CAST(m.FechaRegistro AS DATE)) < CAST(GETDATE() AS DATE)
             AND ABS(CHECKSUM(NEWID())) % 3 = 0 THEN 'Vencido'
        WHEN ABS(CHECKSUM(NEWID())) % 20 = 0 THEN 'Cancelado'
        ELSE 'Activo'
    END,
    CASE (ABS(CHECKSUM(NEWID())) % 10)
        WHEN 0 THEN 0  WHEN 1 THEN 4  WHEN 2 THEN 8
        WHEN 3 THEN 8  WHEN 4 THEN 24 WHEN 5 THEN 24
        WHEN 6 THEN 48 WHEN 7 THEN 99 WHEN 8 THEN 4
        ELSE 6
    END,
    0
FROM Membresia.Miembro m;
GO

-- =============================================
-- SECCIÓN 4: PAGOS (uno por contrato)
-- =============================================
INSERT INTO Finanzas.Pago
    (ContratoID, MiembroID, EmpleadoID, MetodoPagoID,
     Monto, Descuento, Referencia, FechaPago, Estado)
SELECT
    c.ContratoID,
    c.MiembroID,
    c.EmpleadoID,
    (ABS(CHECKSUM(NEWID())) % 6) + 1,
    c.PrecioPagado,
    c.Descuento,
    CASE (ABS(CHECKSUM(NEWID())) % 3)
        WHEN 0 THEN NULL
        WHEN 1 THEN 'SINPE-' + CAST(ABS(CHECKSUM(NEWID())) % 9000000 + 1000000 AS VARCHAR)
        ELSE        'REF-'   + CAST(ABS(CHECKSUM(NEWID())) % 9000000 + 1000000 AS VARCHAR)
    END,
    DATEADD(HOUR, ABS(CHECKSUM(NEWID())) % 12 + 7,
            CAST(c.FechaInicio AS DATETIME2)),
    CASE c.Estado WHEN 'Cancelado' THEN 'Anulado' ELSE 'Completado' END
FROM Membresia.MembresiaContrato c;
GO

-- =============================================
-- SECCIÓN 5: REGISTROS DE ACCESO (~5000)
-- Simula el torniquete del gym
-- =============================================
INSERT INTO Membresia.RegistroAcceso
    (MiembroID, ContratoID, FechaHoraEntrada, FechaHoraSalida, TipoAcceso)
SELECT TOP 5000
    c.MiembroID,
    c.ContratoID,
    DATEADD(MINUTE,
        ABS(CHECKSUM(NEWID())) % 840 + 360,
        CAST(DATEADD(DAY,
            ABS(CHECKSUM(NEWID())) %
            DATEDIFF(DAY, c.FechaInicio,
                CASE WHEN c.FechaFin > GETDATE()
                     THEN GETDATE() ELSE c.FechaFin END),
            c.FechaInicio) AS DATETIME2)),
    DATEADD(MINUTE,
        ABS(CHECKSUM(NEWID())) % 840 + 360 +
        ABS(CHECKSUM(NEWID())) % 90 + 30,
        CAST(DATEADD(DAY,
            ABS(CHECKSUM(NEWID())) %
            DATEDIFF(DAY, c.FechaInicio,
                CASE WHEN c.FechaFin > GETDATE()
                     THEN GETDATE() ELSE c.FechaFin END),
            c.FechaInicio) AS DATETIME2)),
    CASE (ABS(CHECKSUM(NEWID())) % 3)
        WHEN 0 THEN 'Clase'
        ELSE        'Normal'
    END
FROM Membresia.MembresiaContrato c
CROSS JOIN (SELECT TOP 10 1 AS x FROM sys.objects) x
WHERE c.Estado IN ('Activo','Vencido')
  AND DATEDIFF(DAY, c.FechaInicio,
      CASE WHEN c.FechaFin > GETDATE()
           THEN GETDATE() ELSE c.FechaFin END) > 0;
GO

-- =============================================
-- SECCIÓN 6: RESERVAS DE CLASES (~2000)
-- =============================================
INSERT INTO Operaciones.ReservaClase
    (ClaseID, MiembroID, ContratoID, FechaClase, Estado, Asistio, Calificacion)
SELECT TOP 2000
    (ABS(CHECKSUM(NEWID())) % 44) + 1,
    c.MiembroID,
    c.ContratoID,
    CAST(DATEADD(DAY,
        ABS(CHECKSUM(NEWID())) %
        DATEDIFF(DAY, c.FechaInicio,
            CASE WHEN c.FechaFin > GETDATE()
                 THEN GETDATE() ELSE c.FechaFin END),
        c.FechaInicio) AS DATE),
    CASE (ABS(CHECKSUM(NEWID())) % 10)
        WHEN 0 THEN 'Cancelada'
        WHEN 1 THEN 'NoShow'
        ELSE        'Confirmada'
    END,
    CASE (ABS(CHECKSUM(NEWID())) % 5)
        WHEN 0 THEN 0
        WHEN 1 THEN NULL
        ELSE        1
    END,
    CASE (ABS(CHECKSUM(NEWID())) % 5)
        WHEN 0 THEN NULL
        ELSE (ABS(CHECKSUM(NEWID())) % 3) + 3
    END
FROM Membresia.MembresiaContrato c
CROSS JOIN (SELECT TOP 4 1 AS x FROM sys.objects) x
WHERE c.Estado IN ('Activo','Vencido')
  AND DATEDIFF(DAY, c.FechaInicio,
      CASE WHEN c.FechaFin > GETDATE()
           THEN GETDATE() ELSE c.FechaFin END) > 0;
GO

-- Limpiar tablas temporales
DROP TABLE #Nombres;
DROP TABLE #Apellidos;
DROP TABLE #Ciudades;
GO

-- =============================================
-- VERIFICACION FINAL
-- =============================================
SELECT 'Miembros'  AS Tabla, COUNT(*) AS Registros FROM Membresia.Miembro          UNION ALL
SELECT 'Contratos',           COUNT(*)              FROM Membresia.MembresiaContrato UNION ALL
SELECT 'Pagos',               COUNT(*)              FROM Finanzas.Pago               UNION ALL
SELECT 'Accesos',             COUNT(*)              FROM Membresia.RegistroAcceso     UNION ALL
SELECT 'Reservas',            COUNT(*)              FROM Operaciones.ReservaClase;
GO
