# GymDB - Base de Datos SQL Server para Gestión de Gym

## Descripción
Base de datos completa para la administración de un gimnasio, 
implementada en SQL Server 2025 Enterprise Developer con 
arquitectura de alta disponibilidad via Log Shipping.

---

## Arquitectura

```
PRIMARY:    DESKTOP-T4PEHDE (Enterprise Developer)
            └── GymDB en D:\GymDB\ (disco externo)

SECONDARY:  DESKTOP-T4PEHDE\SQLEXPRESS
            └── GymDB_Secondary en C:\GymDB_Secondary\

REPLICA:    Log Shipping cada 15 minutos
```

---

## Estructura del Repositorio

```
GymDB/
├── 01_Infraestructura/
│   ├── 01_Crear_GymDB.sql          -- Crear BD en disco externo
│   └── 02_Esquemas_Seguridad_Base.sql -- Esquemas y roles base
│
├── 02_Tablas/
│   └── 03_Crear_Tablas.sql         -- 15 tablas en 6 esquemas
│
├── 03_Seguridad/
│   └── 10_Roles_Usuarios_Seguridad.sql -- Roles, usuarios y RLS
│
├── 04_Datos/
│   ├── 04_Datos_Base.sql           -- Datos maestros del gym
│   └── 05_Datos_Masivos.sql        -- 500 miembros y ~8700 registros
│
├── 05_Objetos/
│   ├── 06_Indices_Vistas.sql       -- 10 índices y 4 vistas
│   ├── 07_Stored_Procedures.sql    -- 8 SPs con CRUDs completos
│   └── 08_Triggers.sql             -- 3 triggers de auditoría
│
├── 06_Jobs/
│   └── 09_Jobs_Agent.sql           -- 4 jobs automatizados
│
└── 07_Mantenimiento/
    └── 11_Log_Shipping.sql         -- Configuración de réplica
```

---

## Orden de Ejecución

Ejecutar los scripts en este orden exacto:

| # | Script | Descripción |
|---|--------|-------------|
| 1 | 01_Crear_GymDB.sql | Crear base de datos |
| 2 | 02_Esquemas_Seguridad_Base.sql | Esquemas y roles base |
| 3 | 03_Crear_Tablas.sql | Modelo de datos |
| 4 | 04_Datos_Base.sql | Datos maestros |
| 5 | 05_Datos_Masivos.sql | Datos de prueba masivos |
| 6 | 06_Indices_Vistas.sql | Optimización y vistas |
| 7 | 07_Stored_Procedures.sql | Lógica de negocio |
| 8 | 08_Triggers.sql | Auditoría automática |
| 9 | 09_Jobs_Agent.sql | Automatización |
| 10 | 10_Roles_Usuarios_Seguridad.sql | Seguridad avanzada |
| 11 | 11_Log_Shipping.sql | Alta disponibilidad |

---

## Modelo de Datos

### Esquemas
- **RRHH**: Cargos y Empleados
- **Membresia**: Miembros, Contratos, Accesos
- **Operaciones**: Disciplinas, Instructores, Salones, Clases, Reservas
- **Finanzas**: Métodos de pago, Pagos
- **Inventario**: Equipos
- **Auditoria**: Log de cambios

### Estadísticas
| Objeto | Cantidad |
|--------|----------|
| Tablas | 15 |
| Índices | 10 |
| Vistas | 4 |
| Stored Procedures | 8 |
| Triggers | 3 |
| Jobs Agent | 4 |
| Roles | 9 |
| Usuarios | 8 |
| Registros de prueba | ~8,700 |

---

## Jobs Automatizados

| Job | Horario | Función |
|-----|---------|---------|
| GymDB - Backup Diario | 11:00 PM diario | Backup completo a D:\ |
| GymDB - Vencer Contratos | 12:01 AM diario | Marcar contratos vencidos |
| GymDB - Limpieza Auditoria | 1:00 AM domingos | Borrar logs >90 días |
| GymDB - Reporte Diario Metricas | 6:00 AM diario | KPIs del día anterior |

---

## Roles de Seguridad

| Rol | Permisos |
|-----|----------|
| rol_GymAdmin | Control total |
| rol_DBA | Control técnico total |
| rol_Gerencia | Lectura de todo |
| rol_Recepcion | Miembros y accesos |
| rol_Instructor | Sus clases y alumnos |
| rol_Contabilidad | Finanzas y pagos |
| rol_Reporter | Solo lectura operativo |
| rol_SoloLectura | Lectura básica |
| rol_AppWeb | CRUD para app web |

---

## Requisitos

- SQL Server 2022+ Developer o Enterprise Edition
- Windows 10/11 Pro o Windows Server
- Disco externo para archivos de datos (recomendado USB 3.0+)
- SQL Server Agent habilitado y corriendo
- SSMS 19+

---

## Buenas Prácticas Implementadas

- Soft Delete en lugar de borrado físico
- Auditoría completa con triggers
- Row Level Security (RLS) por instructor
- Principio de mínimo privilegio por rol
- Columnas calculadas para MinutosEstadia y MontoFinal
- Filegroup separado para tablas de alto volumen
- Índices INCLUDE para consultas frecuentes
- Manejo de errores con TRY/CATCH en todos los SPs
- Transacciones explícitas en operaciones críticas

---

## Conexión desde Aplicaciones

Los connection strings se configuran en variables
de entorno o en el gestor de secretos del servidor.
No se almacenan en el repositorio por seguridad.

Contactar al DBA para obtener acceso.


---

## Autor
Proyecto de laboratorio para aprendizaje de SQL Server
administración, alta disponibilidad y desarrollo de BD empresarial.
