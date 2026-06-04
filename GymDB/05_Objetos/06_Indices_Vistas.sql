-- =============================================
-- GYMDB - SCRIPT 06: Índices y Vistas
-- =============================================
-- Descripcion: Crea índices para optimizar consultas
--              frecuentes y vistas para reportes
-- Instancia:   DESKTOP-T4PEHDE (PRIMARY)
-- Autor:       GymDB Project
-- Fecha:       2026
-- =============================================

USE GymDB;
GO

-- =============================================
-- SECCIÓN 1: ÍNDICES
-- Principio: índice por cada columna de búsqueda frecuente
-- =============================================

-- Miembros: búsqueda por cédula y email (operación más frecuente)
CREATE NONCLUSTERED INDEX IX_Miembro_Cedula
    ON Membresia.Miembro(Cedula)
    INCLUDE (Nombre, Apellido1, Activo);

CREATE NONCLUSTERED INDEX IX_Miembro_Email
    ON Membresia.Miembro(Email)
    INCLUDE (Nombre, Apellido1, MiembroID);

-- Contratos: búsqueda por estado y fechas
CREATE NONCLUSTERED INDEX IX_Contrato_Estado_Fechas
    ON Membresia.MembresiaContrato(Estado, FechaFin)
    INCLUDE (MiembroID, TipoMembresiaID, PrecioPagado);

CREATE NONCLUSTERED INDEX IX_Contrato_Miembro
    ON Membresia.MembresiaContrato(MiembroID)
    INCLUDE (Estado, FechaInicio, FechaFin);

-- Accesos: búsqueda por fecha (tabla de muy alto volumen)
CREATE NONCLUSTERED INDEX IX_Acceso_Fecha
    ON Membresia.RegistroAcceso(FechaHoraEntrada)
    INCLUDE (MiembroID, TipoAcceso);

CREATE NONCLUSTERED INDEX IX_Acceso_Miembro
    ON Membresia.RegistroAcceso(MiembroID, FechaHoraEntrada DESC);

-- Pagos: búsqueda por fecha y estado
CREATE NONCLUSTERED INDEX IX_Pago_Fecha
    ON Finanzas.Pago(FechaPago)
    INCLUDE (MiembroID, Monto, Descuento, Estado);

-- Reservas: búsqueda por clase y fecha
CREATE NONCLUSTERED INDEX IX_Reserva_Clase_Fecha
    ON Operaciones.ReservaClase(ClaseID, FechaClase)
    INCLUDE (MiembroID, Estado, Asistio);

-- Empleados: búsqueda por cédula
CREATE NONCLUSTERED INDEX IX_Empleado_Cedula
    ON RRHH.Empleado(Cedula)
    INCLUDE (Nombre, Apellido1, CargoID, Activo);

-- Log auditoría: búsqueda por tabla y fecha
CREATE NONCLUSTERED INDEX IX_Log_Tabla_Fecha
    ON Auditoria.LogCambios(Tabla, FechaHora DESC)
    INCLUDE (Operacion, Usuario);
GO

-- =============================================
-- SECCIÓN 2: VISTAS
-- =============================================

-- Vista: miembros con contrato activo y estadísticas
CREATE OR ALTER VIEW Membresia.vw_MiembrosActivos
AS
SELECT
    m.MiembroID,
    m.Cedula,
    m.Nombre + ' ' + m.Apellido1 +
        ISNULL(' ' + m.Apellido2,'')        AS NombreCompleto,
    m.Genero,
    m.Telefono,
    m.Email,
    m.PesoKg,
    m.TallaM,
    tm.Nombre                               AS TipoMembresia,
    c.FechaInicio,
    c.FechaFin,
    DATEDIFF(DAY, GETDATE(), c.FechaFin)    AS DiasRestantes,
    c.ClasesRestantes,
    c.PrecioPagado,
    c.Estado                                AS EstadoContrato,
    (SELECT MAX(FechaHoraEntrada)
     FROM Membresia.RegistroAcceso ra
     WHERE ra.MiembroID = m.MiembroID)      AS UltimoAcceso
FROM Membresia.Miembro m
JOIN Membresia.MembresiaContrato c  ON m.MiembroID       = c.MiembroID
JOIN Membresia.TipoMembresia tm     ON c.TipoMembresiaID = tm.TipoMembresiaID
WHERE c.Estado = 'Activo'
  AND m.Activo = 1;
GO

-- Vista: resumen financiero por mes y metodo de pago
CREATE OR ALTER VIEW Finanzas.vw_ResumenMensual
AS
SELECT
    YEAR(p.FechaPago)                       AS Anio,
    MONTH(p.FechaPago)                      AS Mes,
    DATENAME(MONTH, p.FechaPago)            AS NombreMes,
    COUNT(p.PagoID)                         AS TotalPagos,
    SUM(p.Monto)                            AS IngresosBrutos,
    SUM(p.Descuento)                        AS TotalDescuentos,
    SUM(p.Monto - p.Descuento)              AS IngresosNetos,
    AVG(p.Monto)                            AS TicketPromedio,
    COUNT(CASE WHEN p.Estado = 'Anulado' THEN 1 END) AS PagosAnulados,
    mp.Nombre                               AS MetodoPago
FROM Finanzas.Pago p
JOIN Finanzas.MetodoPago mp ON p.MetodoPagoID = mp.MetodoPagoID
WHERE p.Estado != 'Anulado'
GROUP BY
    YEAR(p.FechaPago), MONTH(p.FechaPago),
    DATENAME(MONTH, p.FechaPago), mp.Nombre;
GO

-- Vista: ocupacion y estadísticas de clases
CREATE OR ALTER VIEW Operaciones.vw_OcupacionClases
AS
SELECT
    cl.ClaseID,
    cl.Nombre                               AS NombreClase,
    d.Nombre                                AS Disciplina,
    d.Intensidad,
    e.Nombre + ' ' + e.Apellido1            AS Instructor,
    s.Nombre                                AS Salon,
    CASE cl.DiaSemana
        WHEN 1 THEN 'Lunes'     WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miercoles' WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'   WHEN 6 THEN 'Sabado'
        ELSE 'Domingo'
    END                                     AS DiaSemana,
    cl.HoraInicio,
    cl.HoraFin,
    cl.Capacidad,
    cl.CupoDisponible,
    cl.Capacidad - cl.CupoDisponible        AS CuposOcupados,
    CAST((cl.Capacidad - cl.CupoDisponible) * 100.0
        / cl.Capacidad AS DECIMAL(5,2))     AS PorcentajeOcupacion,
    COUNT(r.ReservaID)                      AS TotalReservasHistoricas,
    SUM(CASE WHEN r.Asistio = 1 THEN 1 ELSE 0 END) AS TotalAsistencias,
    AVG(CAST(r.Calificacion AS DECIMAL(3,2))) AS CalificacionPromedio
FROM Operaciones.Clase cl
JOIN Operaciones.Disciplina d   ON cl.DisciplinaID  = d.DisciplinaID
JOIN Operaciones.Instructor i   ON cl.InstructorID  = i.InstructorID
JOIN RRHH.Empleado e            ON i.EmpleadoID     = e.EmpleadoID
JOIN Operaciones.Salon s        ON cl.SalonID       = s.SalonID
LEFT JOIN Operaciones.ReservaClase r ON cl.ClaseID  = r.ClaseID
GROUP BY
    cl.ClaseID, cl.Nombre, d.Nombre, d.Intensidad,
    e.Nombre, e.Apellido1, s.Nombre, cl.DiaSemana,
    cl.HoraInicio, cl.HoraFin, cl.Capacidad, cl.CupoDisponible;
GO

-- Vista: dashboard por instructor
CREATE OR ALTER VIEW Operaciones.vw_DashboardInstructor
AS
SELECT
    i.InstructorID,
    e.Nombre + ' ' + e.Apellido1            AS NombreInstructor,
    i.Especialidad,
    i.Calificacion,
    i.AniosExperiencia,
    COUNT(DISTINCT cl.ClaseID)              AS TotalClases,
    COUNT(DISTINCT r.ReservaID)             AS TotalReservas,
    SUM(CASE WHEN r.Asistio = 1 THEN 1 ELSE 0 END) AS TotalAsistencias,
    AVG(CAST(r.Calificacion AS DECIMAL(3,2))) AS CalificacionAlumnos
FROM Operaciones.Instructor i
JOIN RRHH.Empleado e            ON i.EmpleadoID   = e.EmpleadoID
LEFT JOIN Operaciones.Clase cl  ON i.InstructorID = cl.InstructorID
LEFT JOIN Operaciones.ReservaClase r ON cl.ClaseID = r.ClaseID
GROUP BY
    i.InstructorID, e.Nombre, e.Apellido1,
    i.Especialidad, i.Calificacion, i.AniosExperiencia;
GO

-- =============================================
-- SECCIÓN 3: TABLA TEMPORAL GLOBAL (##)
-- Disponible para todas las sesiones
-- Simula cache de membresias activas para la app
-- =============================================
IF OBJECT_ID('tempdb..##MembresiasActivas') IS NOT NULL
    DROP TABLE ##MembresiasActivas;

SELECT
    m.MiembroID,
    m.Nombre + ' ' + m.Apellido1            AS NombreCompleto,
    m.Email,
    m.Telefono,
    c.ContratoID,
    c.TipoMembresiaID,
    c.FechaFin,
    DATEDIFF(DAY, GETDATE(), c.FechaFin)    AS DiasRestantes,
    c.ClasesRestantes,
    GETDATE()                               AS CargadoEn
INTO ##MembresiasActivas
FROM Membresia.Miembro m
JOIN Membresia.MembresiaContrato c ON m.MiembroID = c.MiembroID
WHERE c.Estado = 'Activo'
  AND m.Activo = 1;

-- Índice en tabla temporal para performance
CREATE INDEX IX_TempActivas_Miembro
    ON ##MembresiasActivas(MiembroID);
GO

-- =============================================
-- VERIFICACION FINAL
-- =============================================
SELECT 'Índices creados' AS Objeto, COUNT(*) AS Total
FROM sys.indexes i
JOIN sys.tables t  ON i.object_id  = t.object_id
JOIN sys.schemas s ON t.schema_id  = s.schema_id
WHERE s.name IN ('Membresia','Operaciones','Finanzas','RRHH','Auditoria')
  AND i.name LIKE 'IX_%'

UNION ALL

SELECT 'Vistas creadas', COUNT(*)
FROM sys.views v
JOIN sys.schemas s ON v.schema_id = s.schema_id
WHERE s.name IN ('Membresia','Operaciones','Finanzas')

UNION ALL

SELECT 'Registros en ##MembresiasActivas', COUNT(*)
FROM ##MembresiasActivas;
GO
