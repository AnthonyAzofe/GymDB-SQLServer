-- =============================================
-- GYMDB - SCRIPT 09: Jobs del SQL Server Agent
-- =============================================
-- Descripcion: 4 jobs automatizados para el gym:
--              1. Backup diario a las 11PM
--              2. Vencer contratos a las 12:01AM
--              3. Limpieza de auditoria domingos 1AM
--              4. Reporte de metricas a las 6AM
-- Base:        msdb (sistema de jobs)
-- Requisito:   SQL Server Agent debe estar corriendo
-- Autor:       GymDB Project
-- Fecha:       2026
-- =============================================

USE msdb;
GO

-- =============================================
-- JOB 1: Backup diario completo
-- Todos los dias a las 11:00 PM
-- =============================================
EXEC sp_add_job
    @job_name              = N'GymDB - Backup Diario',
    @description           = N'Realiza backup completo de GymDB al disco externo D:\GymDB\Backup\Full\',
    @enabled               = 1,
    @notify_level_eventlog = 2;  -- loguea si falla

EXEC sp_add_jobstep
    @job_name      = N'GymDB - Backup Diario',
    @step_name     = N'Ejecutar Backup Full',
    @command       = N'
-- Backup completo con compresion y verificacion de integridad
DECLARE @Ruta VARCHAR(500);
DECLARE @Fecha VARCHAR(20);

SET @Fecha = CONVERT(VARCHAR, GETDATE(), 112); -- formato YYYYMMDD
SET @Ruta  = ''D:\GymDB\Backup\Full\GymDB_'' + @Fecha + ''.bak'';

BACKUP DATABASE GymDB
TO DISK = @Ruta
WITH
    COMPRESSION,     -- comprime para ahorrar espacio en disco
    STATS = 10,      -- muestra progreso cada 10%
    CHECKSUM,        -- verifica integridad del backup
    NAME = ''GymDB Backup Completo'';

PRINT ''Backup completado exitosamente: '' + @Ruta;
',
    @database_name     = N'master',
    @on_success_action = 1,   -- continuar al siguiente paso
    @on_fail_action    = 2;   -- salir reportando falla

-- Horario: todos los dias a las 11:00 PM
EXEC sp_add_schedule
    @schedule_name     = N'Diario_11PM',
    @freq_type         = 4,       -- diario
    @freq_interval     = 1,       -- cada 1 dia
    @active_start_time = 230000;  -- 23:00:00

EXEC sp_attach_schedule
    @job_name      = N'GymDB - Backup Diario',
    @schedule_name = N'Diario_11PM';

EXEC sp_add_jobserver
    @job_name = N'GymDB - Backup Diario';
GO

-- =============================================
-- JOB 2: Vencimiento automatico de contratos
-- Todos los dias a las 12:01 AM
-- =============================================
EXEC sp_add_job
    @job_name              = N'GymDB - Vencer Contratos',
    @description           = N'Marca como vencidos los contratos cuya fecha fin ya pasó',
    @enabled               = 1,
    @notify_level_eventlog = 2;

EXEC sp_add_jobstep
    @job_name      = N'GymDB - Vencer Contratos',
    @step_name     = N'Actualizar contratos vencidos',
    @command       = N'
USE GymDB;

DECLARE @Afectados INT;

-- Marcar como Vencido todos los contratos cuya fecha fin ya paso
UPDATE Membresia.MembresiaContrato
SET Estado = ''Vencido''
WHERE Estado   = ''Activo''
  AND FechaFin < CAST(GETDATE() AS DATE);

SET @Afectados = @@ROWCOUNT;

-- Registrar en auditoria cuantos contratos se vencieron
IF @Afectados > 0
BEGIN
    INSERT INTO Auditoria.LogCambios
        (Tabla, Operacion, RegistroID, ValorNuevo, Usuario)
    VALUES
        (''Membresia.MembresiaContrato'', ''U'',
         ''BATCH_VENCIMIENTO'',
         ''{"ContratosVencidos":'' + CAST(@Afectados AS VARCHAR) +
         '',  "Fecha":"'' + CAST(GETDATE() AS VARCHAR) + ''"}'' ,
         ''SQL_AGENT_JOB'');
END

PRINT CAST(@Afectados AS VARCHAR) + '' contratos marcados como vencidos.'';
',
    @database_name     = N'GymDB',
    @on_success_action = 1,
    @on_fail_action    = 2;

EXEC sp_add_schedule
    @schedule_name     = N'Diario_1201AM',
    @freq_type         = 4,
    @freq_interval     = 1,
    @active_start_time = 000100;  -- 00:01:00

EXEC sp_attach_schedule
    @job_name      = N'GymDB - Vencer Contratos',
    @schedule_name = N'Diario_1201AM';

EXEC sp_add_jobserver
    @job_name = N'GymDB - Vencer Contratos';
GO

-- =============================================
-- JOB 3: Limpieza del log de auditoria
-- Domingos a la 1:00 AM
-- Borra registros de mas de 90 dias
-- =============================================
EXEC sp_add_job
    @job_name              = N'GymDB - Limpieza Auditoria',
    @description           = N'Elimina logs de auditoría con más de 90 días para liberar espacio',
    @enabled               = 1,
    @notify_level_eventlog = 2;

EXEC sp_add_jobstep
    @job_name      = N'GymDB - Limpieza Auditoria',
    @step_name     = N'Borrar logs antiguos en lotes',
    @command       = N'
USE GymDB;

DECLARE @FechaCorte DATETIME2;
DECLARE @Eliminados INT;
DECLARE @TotalEliminados INT = 0;

-- Corte: registros de mas de 90 dias
SET @FechaCorte = DATEADD(DAY, -90, GETDATE());

-- Borrar en lotes de 1000 para no bloquear la tabla
WHILE 1 = 1
BEGIN
    DELETE TOP (1000) FROM Auditoria.LogCambios
    WHERE FechaHora < @FechaCorte;

    SET @Eliminados = @@ROWCOUNT;
    SET @TotalEliminados = @TotalEliminados + @Eliminados;

    IF @Eliminados = 0 BREAK;  -- ya no quedan registros antiguos

    -- Pausa de 1 segundo entre lotes para no saturar el sistema
    WAITFOR DELAY ''00:00:01'';
END

PRINT ''Limpieza completada. Total eliminados: '' + CAST(@TotalEliminados AS VARCHAR);
',
    @database_name     = N'GymDB',
    @on_success_action = 1,
    @on_fail_action    = 2;

-- Horario: todos los domingos a la 1:00 AM
EXEC sp_add_schedule
    @schedule_name          = N'Semanal_Domingo_1AM',
    @freq_type              = 8,   -- semanal
    @freq_interval          = 1,   -- domingo
    @freq_recurrence_factor = 1,
    @active_start_time      = 010000;  -- 01:00:00

EXEC sp_attach_schedule
    @job_name      = N'GymDB - Limpieza Auditoria',
    @schedule_name = N'Semanal_Domingo_1AM';

EXEC sp_add_jobserver
    @job_name = N'GymDB - Limpieza Auditoria';
GO

-- =============================================
-- JOB 4: Reporte diario de metricas del gym
-- Todos los dias a las 6:00 AM
-- Calcula KPIs del dia anterior y los guarda
-- =============================================
EXEC sp_add_job
    @job_name              = N'GymDB - Reporte Diario Metricas',
    @description           = N'Genera métricas diarias del gym y las registra en auditoría para reportes',
    @enabled               = 1,
    @notify_level_eventlog = 2;

EXEC sp_add_jobstep
    @job_name      = N'GymDB - Reporte Diario Metricas',
    @step_name     = N'Calcular y guardar metricas del dia anterior',
    @command       = N'
USE GymDB;

-- Calcular metricas del dia anterior
DECLARE @Ayer DATE = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));

DECLARE @AccesosAyer     INT;
DECLARE @IngresosAyer    DECIMAL(10,2);
DECLARE @NuevosMiembros  INT;
DECLARE @ClasesAyer      INT;
DECLARE @ContratosNuevos INT;
DECLARE @ContratosVencidos INT;

-- Total de accesos del dia anterior
SELECT @AccesosAyer = COUNT(*)
FROM Membresia.RegistroAcceso
WHERE CAST(FechaHoraEntrada AS DATE) = @Ayer;

-- Ingresos del dia anterior (pagos completados)
SELECT @IngresosAyer = ISNULL(SUM(Monto - Descuento), 0)
FROM Finanzas.Pago
WHERE CAST(FechaPago AS DATE) = @Ayer
  AND Estado = ''Completado'';

-- Miembros nuevos registrados ayer
SELECT @NuevosMiembros = COUNT(*)
FROM Membresia.Miembro
WHERE CAST(FechaRegistro AS DATE) = @Ayer;

-- Asistencias a clases ayer
SELECT @ClasesAyer = COUNT(*)
FROM Operaciones.ReservaClase
WHERE FechaClase = @Ayer
  AND Asistio    = 1;

-- Contratos nuevos ayer
SELECT @ContratosNuevos = COUNT(*)
FROM Membresia.MembresiaContrato
WHERE CAST(FechaCreacion AS DATE) = @Ayer;

-- Contratos vencidos ayer
SELECT @ContratosVencidos = COUNT(*)
FROM Membresia.MembresiaContrato
WHERE Estado   = ''Vencido''
  AND FechaFin = @Ayer;

-- Guardar todas las metricas en el log de auditoria
INSERT INTO Auditoria.LogCambios
    (Tabla, Operacion, RegistroID, ValorNuevo, Usuario)
VALUES
    (''METRICAS_DIARIAS'', ''I'',
     CAST(@Ayer AS VARCHAR),
     ''{"fecha":"''           + CAST(@Ayer AS VARCHAR)              +
     ''","accesos":''         + CAST(@AccesosAyer AS VARCHAR)       +
     '',  "ingresos":''       + CAST(@IngresosAyer AS VARCHAR)      +
     '',  "nuevos_miembros":''+ CAST(@NuevosMiembros AS VARCHAR)    +
     '',  "clases_tomadas":'' + CAST(@ClasesAyer AS VARCHAR)        +
     '',  "contratos_nuevos":''+ CAST(@ContratosNuevos AS VARCHAR)  +
     '',  "contratos_vencidos":''+ CAST(@ContratosVencidos AS VARCHAR) + ''}'',
     ''SQL_AGENT_JOB'');

PRINT ''Metricas del '' + CAST(@Ayer AS VARCHAR) + '' guardadas correctamente.'';
',
    @database_name     = N'GymDB',
    @on_success_action = 1,
    @on_fail_action    = 2;

EXEC sp_add_schedule
    @schedule_name     = N'Diario_6AM',
    @freq_type         = 4,
    @freq_interval     = 1,
    @active_start_time = 060000;  -- 06:00:00

EXEC sp_attach_schedule
    @job_name      = N'GymDB - Reporte Diario Metricas',
    @schedule_name = N'Diario_6AM';

EXEC sp_add_jobserver
    @job_name = N'GymDB - Reporte Diario Metricas';
GO

-- =============================================
-- VERIFICACION FINAL
-- =============================================
SELECT
    j.name      AS Job,
    j.enabled   AS Activo,
    s.name      AS Horario,
    CASE s.freq_type
        WHEN 4 THEN 'Diario'
        WHEN 8 THEN 'Semanal'
    END         AS Frecuencia,
    CAST(s.active_start_time / 10000 AS VARCHAR) + ':' +
    RIGHT('00' + CAST((s.active_start_time / 100) % 100 AS VARCHAR), 2)
                AS HoraEjecucion,
    j.date_created
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobschedules js ON j.job_id      = js.job_id
JOIN msdb.dbo.sysschedules     s  ON js.schedule_id = s.schedule_id
WHERE j.name LIKE 'GymDB%'
ORDER BY j.name;
GO
