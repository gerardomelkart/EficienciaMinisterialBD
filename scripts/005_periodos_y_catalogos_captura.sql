/* Datos de referencia y periodos de entrega; ejecutar después de 004.
   El inicio histórico de junio de 2025 proviene de la pregunta 5 del cuestionario.
   No modifica fechas de detención ni elimina cargas anteriores. */
USE EficienciaMinisterial_DEV;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH(N'catalogo.entidad', N'permite_captura') IS NULL
BEGIN
    ALTER TABLE catalogo.entidad ADD permite_captura bit NOT NULL CONSTRAINT DF_entidad_captura DEFAULT 1;
END;
GO
UPDATE catalogo.entidad SET permite_captura = 0 WHERE id IN (0, 33);
IF OBJECT_ID(N'catalogo.perfil', N'U') IS NULL
BEGIN
    CREATE TABLE catalogo.perfil
    (
        codigo varchar(30) NOT NULL PRIMARY KEY,
        nombre nvarchar(80) NOT NULL,
        tipo_institucion varchar(20) NULL,
        requiere_institucion bit NOT NULL,
        permite_estatal bit NOT NULL,
        activo bit NOT NULL DEFAULT 1
    );
END;
INSERT catalogo.perfil(codigo, nombre, tipo_institucion, requiere_institucion, permite_estatal)
SELECT codigo, nombre, tipo, requiere, estatal FROM (VALUES
    ('PRIMER_RESPONDIENTE', N'Primer respondiente', 'CORPORACION', 1, 1),
    ('FISCALIA', N'Fiscalía', 'FISCALIA', 1, 1),
    ('SUPER_USUARIO', N'Superusuario', NULL, 0, 0),
    ('CONSULTA', N'Consulta', NULL, 0, 1)
) o(codigo, nombre, tipo, requiere, estatal)
WHERE NOT EXISTS(SELECT 1 FROM catalogo.perfil d WHERE d.codigo = o.codigo);
IF OBJECT_ID(N'catalogo.ambito', N'U') IS NULL
BEGIN
    CREATE TABLE catalogo.ambito
    (
        codigo varchar(10) NOT NULL PRIMARY KEY,
        nombre nvarchar(80) NOT NULL,
        requiere_entidad bit NOT NULL,
        activo bit NOT NULL DEFAULT 1
    );
END;
INSERT catalogo.ambito(codigo, nombre, requiere_entidad)
SELECT codigo, nombre, requiere FROM (VALUES
    ('NACIONAL', N'Nacional', 0), ('ESTATAL', N'Por entidad', 1)
) o(codigo, nombre, requiere)
WHERE NOT EXISTS(SELECT 1 FROM catalogo.ambito d WHERE d.codigo = o.codigo);
IF OBJECT_ID(N'catalogo.institucion_alias', N'U') IS NULL
BEGIN
    CREATE TABLE catalogo.institucion_alias
    (
        valor nvarchar(200) NOT NULL PRIMARY KEY,
        codigo varchar(20) NOT NULL REFERENCES catalogo.institucion(codigo)
    );
END;
INSERT catalogo.institucion_alias(valor, codigo)
SELECT valor, codigo FROM (VALUES
    (N'MARINA', 'SEMAR'), (N'SECRETARIA DE MARINA', 'SEMAR'),
    (N'GUARDIA NACIONAL', 'GN'), (N'SECRETARIA DE LA DEFENSA NACIONAL', 'SEDENA'),
    (N'SECRETARIA DE SEGURIDAD Y PROTECCION CIUDADANA', 'SSPC')
) o(valor, codigo)
WHERE NOT EXISTS(SELECT 1 FROM catalogo.institucion_alias d WHERE d.valor = o.valor);
IF OBJECT_ID(N'catalogo.entidad_alias', N'U') IS NULL
BEGIN
    CREATE TABLE catalogo.entidad_alias
    (
        valor nvarchar(80) NOT NULL PRIMARY KEY,
        id_entidad tinyint NOT NULL REFERENCES catalogo.entidad(id)
    );
END;
INSERT catalogo.entidad_alias(valor, id_entidad)
SELECT valor, id FROM (VALUES
    (N'ESTADO DE MEXICO', 15), (N'COAHUILA', 5), (N'MICHOACAN', 16),
    (N'VERACRUZ', 30), (N'DISTRITO FEDERAL', 9), (N'CDMX', 9)
) o(valor, id)
WHERE NOT EXISTS(SELECT 1 FROM catalogo.entidad_alias d WHERE d.valor = o.valor);
IF OBJECT_ID(N'catalogo.fuero', N'U') IS NULL
BEGIN
    CREATE TABLE catalogo.fuero(codigo varchar(2) NOT NULL PRIMARY KEY, nombre nvarchar(80) NOT NULL, activo bit NOT NULL DEFAULT 1);
END;
INSERT catalogo.fuero(codigo, nombre)
SELECT codigo, nombre FROM (VALUES ('FC', N'Fuero común'), ('FF', N'Fuero federal')) o(codigo, nombre)
WHERE NOT EXISTS(SELECT 1 FROM catalogo.fuero d WHERE d.codigo = o.codigo);
IF OBJECT_ID(N'primer_respondiente.periodo', N'U') IS NULL
BEGIN
    CREATE TABLE primer_respondiente.periodo
    (
        id int IDENTITY NOT NULL PRIMARY KEY,
        inicio date NOT NULL UNIQUE,
        fin date NOT NULL,
        habilitado bit NOT NULL DEFAULT 1,
        cerrado bit NOT NULL DEFAULT 0,
        CONSTRAINT CK_periodo_quincenal CHECK(
            (DAY(inicio) = 1 AND fin = DATEADD(day, 14, inicio))
            OR (DAY(inicio) = 16 AND fin = EOMONTH(inicio)))
    );
    INSERT primer_respondiente.periodo(inicio, fin) VALUES('20250601', '20250615');
END;
IF COL_LENGTH(N'primer_respondiente.carga', N'id_periodo') IS NULL
BEGIN
    ALTER TABLE primer_respondiente.carga ADD id_periodo int NULL REFERENCES primer_respondiente.periodo(id);
END;
COMMIT;
GO
CREATE OR ALTER PROCEDURE primer_respondiente.GenerarPeriodos
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    DECLARE @inicio date, @fin date;
    DECLARE @hoy date = CONVERT(date, SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time (Mexico)');
    SELECT @inicio = DATEADD(day, 1, MAX(fin)) FROM primer_respondiente.periodo WITH(UPDLOCK, HOLDLOCK);
    IF @inicio IS NULL THROW 50001, 'Configure el periodo inicial en la base.', 1;
    WHILE @inicio <= @hoy
    BEGIN
        SET @fin = CASE WHEN DAY(@inicio) = 1 THEN DATEADD(day, 14, @inicio) ELSE EOMONTH(@inicio) END;
        INSERT primer_respondiente.periodo(inicio, fin) VALUES(@inicio, @fin);
        SET @inicio = DATEADD(day, 1, @fin);
    END;
    COMMIT;
END;
GO
EXEC primer_respondiente.GenerarPeriodos;
GO
