/* Ejecutar después de 001 y 002 en la base de desarrollo. Migración aditiva. */
USE EficienciaMinisterial_DEV;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID(N'seguridad.usuario_acceso', N'U') IS NULL
BEGIN
    CREATE TABLE seguridad.usuario_acceso
    (
        id int IDENTITY NOT NULL CONSTRAINT PK_usuario_acceso PRIMARY KEY,
        id_usuario int NOT NULL REFERENCES seguridad.usuario(id),
        rol varchar(30) NOT NULL CHECK(rol IN ('SUPER_USUARIO', 'PRIMER_RESPONDIENTE', 'FISCALIA', 'CONSULTA')),
        institucion varchar(20) NULL REFERENCES catalogo.institucion(codigo),
        ambito varchar(10) NOT NULL CHECK(ambito IN ('NACIONAL', 'ESTATAL')),
        entidad tinyint NULL REFERENCES catalogo.entidad(id),
        CONSTRAINT CK_acceso_entidad CHECK((ambito = 'ESTATAL' AND entidad IS NOT NULL AND entidad BETWEEN 1 AND 32)
            OR (ambito = 'NACIONAL' AND entidad IS NULL)),
        CONSTRAINT CK_acceso_institucion CHECK(rol NOT IN ('PRIMER_RESPONDIENTE', 'FISCALIA') OR institucion IS NOT NULL),
        CONSTRAINT CK_acceso_super CHECK(rol <> 'SUPER_USUARIO' OR (ambito = 'NACIONAL' AND institucion IS NULL))
    );
    CREATE UNIQUE INDEX UX_usuario_acceso ON seguridad.usuario_acceso(id_usuario, rol, institucion, ambito, entidad);
    INSERT seguridad.usuario_acceso(id_usuario, rol, institucion, ambito, entidad)
    SELECT id, rol, CASE WHEN rol = 'SUPER_USUARIO' THEN NULL ELSE institucion END,
        CASE WHEN ambito = 'ESTATAL' THEN 'ESTATAL' ELSE 'NACIONAL' END,
        CASE WHEN ambito = 'ESTATAL' THEN entidad ELSE NULL END
    FROM seguridad.usuario;
END;
IF COL_LENGTH(N'seguridad.bitacora', N'id_usuario_objetivo') IS NULL
BEGIN
    ALTER TABLE seguridad.bitacora ADD id_usuario_objetivo int NULL REFERENCES seguridad.usuario(id);
END;
-- Un valor vacío representa un fuero no proporcionado. Se conservan las filas existentes.
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'primer_respondiente.registro') AND name = N'CK_registro_fuero_opcional')
BEGIN
    DECLARE @checks nvarchar(max) = N'';
    SELECT @checks = @checks + N'ALTER TABLE primer_respondiente.registro DROP CONSTRAINT ' + QUOTENAME(name) + N';'
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'primer_respondiente.registro') AND definition LIKE N'%tipo_fuero%';
    EXEC sys.sp_executesql @checks;
    ALTER TABLE primer_respondiente.registro ADD CONSTRAINT CK_registro_fuero_opcional CHECK(tipo_fuero IN ('', 'FC', 'FF'));
END;
COMMIT;
GO
