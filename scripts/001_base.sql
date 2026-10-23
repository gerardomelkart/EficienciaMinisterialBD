/* Ejecutar en SQL Server 2019 o superior. No elimina datos ni crea usuarios de prueba. */
USE master;
GO
IF DB_ID(N'EficienciaMinisterial') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE EficienciaMinisterial');
END;
GO
USE EficienciaMinisterial;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF SCHEMA_ID(N'seguridad') IS NULL EXEC(N'CREATE SCHEMA seguridad');
IF SCHEMA_ID(N'catalogo') IS NULL EXEC(N'CREATE SCHEMA catalogo');
IF SCHEMA_ID(N'primer_respondiente') IS NULL EXEC(N'CREATE SCHEMA primer_respondiente');

IF OBJECT_ID(N'catalogo.institucion', N'U') IS NULL
BEGIN
    CREATE TABLE catalogo.institucion
    (
        codigo varchar(20) NOT NULL CONSTRAINT PK_institucion PRIMARY KEY,
        nombre nvarchar(200) NOT NULL,
        tipo varchar(20) NOT NULL CHECK(tipo IN ('CORPORACION', 'FISCALIA')),
        activo bit NOT NULL DEFAULT 1
    );
END;
IF OBJECT_ID(N'catalogo.entidad', N'U') IS NULL
BEGIN
    CREATE TABLE catalogo.entidad
    (
        id tinyint NOT NULL CONSTRAINT PK_entidad PRIMARY KEY CHECK(id BETWEEN 0 AND 33),
        clave nvarchar(3) NOT NULL UNIQUE,
        nombre nvarchar(80) NOT NULL UNIQUE,
        siglas nvarchar(10) NOT NULL,
        siglas_renapo nvarchar(10) NOT NULL,
        activo bit NOT NULL DEFAULT 1
    );
END;
IF OBJECT_ID(N'seguridad.usuario', N'U') IS NULL
BEGIN
    CREATE TABLE seguridad.usuario
    (
        id int IDENTITY NOT NULL CONSTRAINT PK_usuario PRIMARY KEY,
        usuario nvarchar(80) NOT NULL UNIQUE,
        nombre nvarchar(200) NOT NULL,
        password_hash varchar(200) NOT NULL,
        rol varchar(30) NOT NULL CHECK(rol IN ('SUPER_USUARIO', 'PRIMER_RESPONDIENTE', 'FISCALIA', 'CONSULTA')),
        institucion varchar(20) NULL REFERENCES catalogo.institucion(codigo),
        ambito varchar(10) NOT NULL CHECK(ambito IN ('NACIONAL', 'ESTATAL', 'FEDERAL')),
        entidad tinyint NULL REFERENCES catalogo.entidad(id),
        activo bit NOT NULL DEFAULT 1,
        creado_utc datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_usuario_entidad CHECK(ambito <> 'ESTATAL' OR entidad IS NOT NULL),
        CONSTRAINT CK_usuario_institucion CHECK(rol NOT IN ('PRIMER_RESPONDIENTE', 'FISCALIA') OR institucion IS NOT NULL)
    );
END;
IF OBJECT_ID(N'primer_respondiente.carga', N'U') IS NULL
BEGIN
    CREATE TABLE primer_respondiente.carga
    (
        id uniqueidentifier NOT NULL CONSTRAINT PK_carga PRIMARY KEY,
        folio varchar(50) NULL,
        id_usuario int NOT NULL REFERENCES seguridad.usuario(id),
        institucion varchar(20) NOT NULL REFERENCES catalogo.institucion(codigo),
        nombre_archivo nvarchar(255) NOT NULL,
        archivo varbinary(max) NOT NULL,
        sha256 char(64) NOT NULL,
        periodo_inicio date NOT NULL,
        periodo_fin date NOT NULL,
        estado varchar(15) NOT NULL CHECK(estado IN ('VALIDADA', 'CONFIRMADA')),
        total_registros int NOT NULL CHECK(total_registros > 0),
        creado_utc datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        confirmado_utc datetime2 NULL,
        CONSTRAINT CK_carga_periodo CHECK(periodo_fin >= periodo_inicio),
        CONSTRAINT CK_carga_confirmacion CHECK((estado = 'VALIDADA' AND folio IS NULL AND confirmado_utc IS NULL) OR (estado = 'CONFIRMADA' AND folio IS NOT NULL AND confirmado_utc IS NOT NULL))
    );
    CREATE UNIQUE INDEX UX_carga_folio ON primer_respondiente.carga(folio) WHERE folio IS NOT NULL;
    CREATE INDEX IX_carga_institucion_fecha ON primer_respondiente.carga(institucion, creado_utc DESC);
END;
IF OBJECT_ID(N'primer_respondiente.registro', N'U') IS NULL
BEGIN
    CREATE TABLE primer_respondiente.registro
    (
        id bigint IDENTITY NOT NULL CONSTRAINT PK_registro PRIMARY KEY,
        id_carga uniqueidentifier NOT NULL REFERENCES primer_respondiente.carga(id),
        fila int NOT NULL,
        corporacion varchar(20) NOT NULL REFERENCES catalogo.institucion(codigo),
        folio_rnd varchar(40) NOT NULL,
        fecha_detencion date NOT NULL,
        autoridad_puesta nvarchar(500) NOT NULL,
        nombre_detenido nvarchar(300) NOT NULL,
        entidad tinyint NOT NULL REFERENCES catalogo.entidad(id),
        tipo_fuero varchar(2) NOT NULL CHECK(tipo_fuero IN ('FC', 'FF')),
        estado_cruce varchar(20) NOT NULL DEFAULT 'PENDIENTE',
        CONSTRAINT UQ_registro_fila UNIQUE(id_carga, fila)
    );
    CREATE INDEX IX_registro_folio ON primer_respondiente.registro(folio_rnd);
END;
IF OBJECT_ID(N'seguridad.bitacora', N'U') IS NULL
BEGIN
    CREATE TABLE seguridad.bitacora
    (
        id bigint IDENTITY NOT NULL CONSTRAINT PK_bitacora PRIMARY KEY,
        id_usuario int NOT NULL REFERENCES seguridad.usuario(id),
        accion varchar(50) NOT NULL,
        id_carga uniqueidentifier NULL REFERENCES primer_respondiente.carga(id),
        fecha_utc datetime2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
IF OBJECT_ID(N'primer_respondiente.folio_seq', N'SO') IS NULL
BEGIN
    EXEC(N'CREATE SEQUENCE primer_respondiente.folio_seq AS bigint START WITH 1 INCREMENT BY 1');
END;
COMMIT;
GO
