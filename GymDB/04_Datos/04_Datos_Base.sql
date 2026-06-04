-- =============================================
-- GYMDB - SCRIPT 04: Datos Base
-- =============================================
-- Descripcion: Inserta los datos maestros del gym:
--              cargos, empleados, tipos de membresia,
--              salones, disciplinas, instructores,
--              clases, metodos de pago y equipos
-- Instancia:   DESKTOP-T4PEHDE (PRIMARY)
-- Autor:       GymDB Project
-- Fecha:       2026
-- =============================================

USE GymDB;
GO

-- =============================================
-- CARGOS (10 registros)
-- =============================================
INSERT INTO RRHH.Cargo (Nombre, Descripcion, NivelJerarquico, SalarioBase, SalarioMaximo)
VALUES
('Gerente General',      'Administra todas las operaciones del gym',         1, 2500000, 3500000),
('Gerente Operaciones',  'Supervisa operaciones diarias',                    1, 2000000, 2800000),
('Supervisor Recepcion', 'Coordina el equipo de recepcion',                  2, 1200000, 1600000),
('Instructor Senior',    'Instructor con mas de 5 anos de experiencia',      2, 1100000, 1500000),
('Instructor Junior',    'Instructor con menos de 5 anos de experiencia',    3,  800000, 1100000),
('Recepcionista',        'Atencion al cliente y control de acceso',          3,  700000,  900000),
('Nutricionista',        'Asesoria nutricional a los miembros',              2, 1200000, 1600000),
('Fisioterapeuta',       'Atencion fisioterapeutica y prevencion lesiones',  2, 1300000, 1700000),
('Personal Limpieza',    'Mantenimiento e higiene de instalaciones',         3,  500000,  650000),
('Mantenimiento',        'Mantenimiento de equipos e instalaciones',         3,  650000,  850000);
GO

-- =============================================
-- EMPLEADOS (30 registros)
-- =============================================
INSERT INTO RRHH.Empleado
    (CargoID, Cedula, Nombre, Apellido1, Apellido2, FechaNacimiento,
     Genero, Telefono, TelefonoEmergencia, Email, Direccion,
     FechaIngreso, Salario, IBAN)
VALUES
(1,'101110001','Carlos',    'Ramirez',  'Mora',    '1980-03-15','M','88001001','72001001','carlos.ramirez@gym.cr',    'San Jose, Escazu',        '2018-01-15',3000000,'CR21015201001026284066'),
(2,'101110002','Ana',       'Gonzalez', 'Vargas',  '1985-07-22','F','88001002','72001002','ana.gonzalez@gym.cr',      'San Jose, Santa Ana',     '2018-02-01',2200000,'CR21015201001026284067'),
(3,'101110003','Luis',      'Mora',     'Castro',  '1990-11-08','M','88001003','72001003','luis.mora@gym.cr',         'Heredia, Belen',          '2019-03-10',1300000,'CR21015201001026284068'),
(4,'101110004','Maria',     'Castro',   'Jimenez', '1988-05-30','F','88001004','72001004','maria.castro@gym.cr',     'Alajuela, San Ramon',     '2019-04-01',1200000,'CR21015201001026284069'),
(4,'101110005','Diego',     'Jimenez',  'Lopez',   '1992-09-14','M','88001005','72001005','diego.jimenez@gym.cr',    'San Jose, Curridabat',    '2019-05-15',1150000,'CR21015201001026284070'),
(5,'101110006','Sofia',     'Lopez',    'Herrera', '1995-02-28','F','88001006','72001006','sofia.lopez@gym.cr',      'Cartago, Tres Rios',      '2020-01-10',850000, 'CR21015201001026284071'),
(5,'101110007','Andres',    'Herrera',  'Rojas',   '1993-06-17','M','88001007','72001007','andres.herrera@gym.cr',   'San Jose, Moravia',       '2020-02-01',900000, 'CR21015201001026284072'),
(5,'101110008','Valeria',   'Rojas',    'Nunez',   '1997-10-05','F','88001008','72001008','valeria.rojas@gym.cr',    'Heredia, Santo Domingo',  '2020-03-15',850000, 'CR21015201001026284073'),
(5,'101110009','Sebastian', 'Nunez',    'Quesada', '1994-12-20','M','88001009','72001009','sebastian.nunez@gym.cr',  'San Jose, Zapote',        '2020-06-01',875000, 'CR21015201001026284074'),
(5,'101110010','Camila',    'Quesada',  'Blanco',  '1996-04-11','F','88001010','72001010','camila.quesada@gym.cr',   'Alajuela, Grecia',        '2021-01-10',825000, 'CR21015201001026284075'),
(6,'101110011','Daniel',    'Blanco',   'Araya',   '1998-08-25','M','88001011','72001011','daniel.blanco@gym.cr',    'San Jose, Tibas',         '2021-02-01',720000, 'CR21015201001026284076'),
(6,'101110012','Isabella',  'Araya',    'Vega',    '1999-01-14','F','88001012','72001012','isabella.araya@gym.cr',   'Cartago, La Union',       '2021-03-10',710000, 'CR21015201001026284077'),
(6,'101110013','Gabriel',   'Vega',     'Soto',    '1997-05-30','M','88001013','72001013','gabriel.vega@gym.cr',     'San Jose, Desamparados',  '2021-04-15',730000, 'CR21015201001026284078'),
(6,'101110014','Lucia',     'Soto',     'Chaves',  '2000-09-18','F','88001014','72001014','lucia.soto@gym.cr',       'Heredia, Flores',         '2022-01-05',700000, 'CR21015201001026284079'),
(7,'101110015','Marco',     'Chaves',   'Monge',   '1987-03-07','M','88001015','72001015','marco.chaves@gym.cr',     'San Jose, Escazu',        '2019-07-01',1350000,'CR21015201001026284080'),
(7,'101110016','Paula',     'Monge',    'Arias',   '1989-11-23','F','88001016','72001016','paula.monge@gym.cr',      'San Jose, Santa Ana',     '2020-08-01',1300000,'CR21015201001026284081'),
(8,'101110017','Ricardo',   'Arias',    'Mora',    '1986-07-12','M','88001017','72001017','ricardo.arias@gym.cr',    'Alajuela, Palmares',      '2019-09-01',1400000,'CR21015201001026284082'),
(5,'101110018','Fernanda',  'Mora',     'Ruiz',    '1994-02-28','F','88001018','72001018','fernanda.mora@gym.cr',    'San Jose, San Pedro',     '2021-05-10',880000, 'CR21015201001026284083'),
(5,'101110019','Esteban',   'Ruiz',     'Picado',  '1992-08-15','M','88001019','72001019','esteban.ruiz@gym.cr',     'Cartago, Paraiso',        '2021-06-01',860000, 'CR21015201001026284084'),
(5,'101110020','Natalia',   'Picado',   'Leon',    '1996-12-03','F','88001020','72001020','natalia.picado@gym.cr',   'Heredia, San Pablo',      '2022-02-14',840000, 'CR21015201001026284085'),
(6,'101110021','Hector',    'Leon',     'Fonseca', '1998-04-19','M','88001021','72001021','hector.leon@gym.cr',      'San Jose, Alajuelita',    '2022-03-01',715000, 'CR21015201001026284086'),
(6,'101110022','Diana',     'Fonseca',  'Gamboa',  '1999-10-07','F','88001022','72001022','diana.fonseca@gym.cr',    'San Jose, Perez Zeledon', '2022-04-15',705000, 'CR21015201001026284087'),
(9,'101110023','Jorge',     'Gamboa',   'Salas',   '1975-06-25','M','88001023','72001023','jorge.gamboa@gym.cr',     'San Jose, Hatillo',       '2018-05-01',520000, 'CR21015201001026284088'),
(9,'101110024','Rosa',      'Salas',    'Brenes',  '1978-02-14','F','88001024','72001024','rosa.salas@gym.cr',       'Alajuela, Ciudad Quesada','2018-06-01',510000, 'CR21015201001026284089'),
(10,'101110025','Manuel',   'Brenes',   'Varela',  '1980-09-30','M','88001025','72001025','manuel.brenes@gym.cr',    'Heredia, San Isidro',     '2018-07-01',680000, 'CR21015201001026284090'),
(5,'101110026','Alejandra', 'Varela',   'Cruz',    '1995-01-16','F','88001026','72001026','alejandra.varela@gym.cr', 'Cartago, Turrialba',      '2022-05-10',855000, 'CR21015201001026284091'),
(5,'101110027','Pablo',     'Cruz',     'Solano',  '1993-07-04','M','88001027','72001027','pablo.cruz@gym.cr',       'San Jose, Coronado',      '2022-06-01',870000, 'CR21015201001026284092'),
(6,'101110028','Silvia',    'Solano',   'Badilla', '2001-03-22','F','88001028','72001028','silvia.solano@gym.cr',    'San Jose, Goicoechea',    '2023-01-09',700000, 'CR21015201001026284093'),
(6,'101110029','Kevin',     'Badilla',  'Obando',  '2000-11-11','M','88001029','72001029','kevin.badilla@gym.cr',    'Alajuela, Atenas',        '2023-02-01',710000, 'CR21015201001026284094'),
(4,'101110030','Adriana',   'Obando',   'Quiros',  '1991-05-08','F','88001030','72001030','adriana.obando@gym.cr',   'San Jose, Escazu',        '2023-03-15',1180000,'CR21015201001026284095');
GO

-- =============================================
-- TIPOS DE MEMBRESIA (10 registros)
-- =============================================
INSERT INTO Membresia.TipoMembresia
    (Nombre, Descripcion, DuracionDias, Precio, AccesoClases, AccesoSauna, AccesoPiscina, ClasesIncluidas)
VALUES
('Mensual Basico',      'Acceso a sala de pesas y cardio',                     30,  25000, 0, 0, 0,  0),
('Mensual Completo',    'Acceso completo incluyendo clases grupales',          30,  35000, 1, 0, 0,  8),
('Mensual Premium',     'Acceso total con sauna y clases ilimitadas',          30,  50000, 1, 1, 0, 99),
('Trimestral Basico',   'Tres meses acceso sala pesas y cardio',               90,  65000, 0, 0, 0,  0),
('Trimestral Completo', 'Tres meses acceso completo con clases',               90,  90000, 1, 0, 0, 24),
('Semestral Completo',  'Seis meses acceso completo',                         180, 160000, 1, 0, 0, 48),
('Anual Completo',      'Un ano acceso completo mejor precio por mes',        365, 280000, 1, 1, 1, 99),
('Estudiante',          'Tarifa especial para estudiantes con carnet',         30,  18000, 1, 0, 0,  4),
('Adulto Mayor',        'Tarifa especial mayores de 60 anos',                  30,  15000, 1, 0, 0,  4),
('Corporativo',         'Convenio empresarial minimo 10 personas',             30,  20000, 1, 0, 0,  6);
GO

-- =============================================
-- SALONES (8 registros)
-- =============================================
INSERT INTO Operaciones.Salon
    (Nombre, Descripcion, Capacidad, TieneEspejo, TieneAire, TieneSonido, Piso)
VALUES
('Salon Principal',  'Sala principal multiusos para clases grupales',   30, 1, 1, 1, 1),
('Sala Spinning',    'Sala exclusiva para clases de spinning',          25, 0, 1, 1, 1),
('Sala Yoga',        'Sala tranquila para yoga y meditacion',           20, 1, 1, 0, 2),
('Sala Funcional',   'Sala equipada para entrenamiento funcional',      15, 1, 1, 1, 1),
('Sala Boxeo',       'Ring y equipo de boxeo y artes marciales',        12, 0, 1, 1, 2),
('Sala Pesas',       'Sala de pesas libre y maquinas',                  40, 1, 1, 1, 1),
('Sala Cardio',      'Maquinas de cardio trotadoras y elipticas',       35, 0, 1, 1, 1),
('Terraza Exterior', 'Espacio al aire libre para clases outdoor',       25, 0, 0, 0, 3);
GO

-- =============================================
-- DISCIPLINAS (12 registros)
-- =============================================
INSERT INTO Operaciones.Disciplina
    (Nombre, Descripcion, Intensidad, CaloriasPromedio, RequiereEquipo)
VALUES
('Spinning',   'Ciclismo indoor de alta intensidad',              'Alta',  600, 1),
('Yoga',       'Practica de posturas y meditacion',               'Baja',  200, 0),
('Pilates',    'Fortalecimiento del core y flexibilidad',         'Media', 300, 0),
('Zumba',      'Baile fitness de alta energia',                   'Alta',  500, 0),
('Crossfit',   'Entrenamiento funcional de alta intensidad',      'Alta',  700, 1),
('Boxeo',      'Tecnicas de boxeo y defensa personal',            'Alta',  650, 1),
('TRX',        'Entrenamiento en suspension con correas',         'Media', 400, 1),
('Body Pump',  'Entrenamiento con barras al ritmo musical',       'Alta',  550, 1),
('Stretching', 'Estiramientos y flexibilidad general',            'Baja',  150, 0),
('Funcional',  'Movimientos funcionales para vida diaria',        'Media', 450, 1),
('Meditacion', 'Tecnicas de mindfulness y relajacion',            'Baja',  100, 0),
('HIIT',       'Entrenamiento intervalado de alta intensidad',    'Alta',  750, 0);
GO

-- =============================================
-- INSTRUCTORES (13 registros)
-- =============================================
INSERT INTO Operaciones.Instructor
    (EmpleadoID, Especialidad, Certificaciones, AniosExperiencia, Calificacion, MaxAlumnos)
VALUES
(4,  'Spinning, Crossfit',       'ACE, NASM, CrossFit Level 2',       8, 4.90, 25),
(5,  'Yoga, Pilates, Stretching','RYT-200, STOTT Pilates',            6, 4.80, 20),
(6,  'Zumba, Body Pump',         'ZUMBA License, Les Mills BP',        3, 4.70, 30),
(7,  'Boxeo, Funcional',         'FPB Certificado, Funcional Coach',   5, 4.85, 15),
(8,  'TRX, HIIT, Funcional',     'TRX Certified, HIIT Specialist',     4, 4.75, 20),
(9,  'Spinning, HIIT',           'ACE Certified, Spinning Instructor', 7, 4.92, 25),
(10, 'Yoga, Meditacion',         'RYT-500, Mindfulness Coach',         5, 4.95, 20),
(18, 'Crossfit, Body Pump',      'CrossFit Level 1, Les Mills',        3, 4.60, 20),
(19, 'Zumba, Funcional',         'ZUMBA License, NSCA-CPT',            4, 4.70, 25),
(20, 'Pilates, Stretching',      'STOTT Pilates, FMS Certified',       2, 4.55, 18),
(26, 'HIIT, TRX',                'TRX Certified, NSCA-CPT',            2, 4.50, 20),
(27, 'Boxeo, Crossfit',          'FPB, CrossFit Level 1',              3, 4.65, 15),
(30, 'Spinning, Body Pump',      'ACE, Les Mills BP, Spinning Inst.',  5, 4.80, 25);
GO

-- =============================================
-- METODOS DE PAGO (6 registros)
-- =============================================
INSERT INTO Finanzas.MetodoPago (Nombre)
VALUES
('Efectivo'),('SINPE Movil'),('Tarjeta Debito'),
('Tarjeta Credito'),('Transferencia'),('Corporativo');
GO

-- =============================================
-- VERIFICACION FINAL
-- =============================================
SELECT 'Cargos'       AS Tabla, COUNT(*) AS Registros FROM RRHH.Cargo              UNION ALL
SELECT 'Empleados',            COUNT(*)               FROM RRHH.Empleado           UNION ALL
SELECT 'TiposMembresia',       COUNT(*)               FROM Membresia.TipoMembresia UNION ALL
SELECT 'Salones',              COUNT(*)               FROM Operaciones.Salon        UNION ALL
SELECT 'Disciplinas',          COUNT(*)               FROM Operaciones.Disciplina   UNION ALL
SELECT 'Instructores',         COUNT(*)               FROM Operaciones.Instructor   UNION ALL
SELECT 'MetodosPago',          COUNT(*)               FROM Finanzas.MetodoPago;
GO
