SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH('primer_respondiente.carga','reabierta') IS NULL
    ALTER TABLE primer_respondiente.carga ADD reabierta bit NOT NULL DEFAULT 0;
IF COL_LENGTH('fiscalia.entrega','reabierta') IS NULL
    ALTER TABLE fiscalia.entrega ADD reabierta bit NOT NULL DEFAULT 0;
IF COL_LENGTH('fiscalia.entrega','vigente') IS NULL
    ALTER TABLE fiscalia.entrega ADD vigente bit NOT NULL DEFAULT 1;
DECLARE @restriccion sysname;
SELECT @restriccion=k.name FROM sys.key_constraints k
WHERE k.parent_object_id=OBJECT_ID('fiscalia.entrega') AND k.type='UQ'
AND (SELECT COUNT(*) FROM sys.index_columns c WHERE c.object_id=k.parent_object_id AND c.index_id=k.unique_index_id AND key_ordinal>0)=3
AND NOT EXISTS(SELECT 1 FROM sys.index_columns c WHERE c.object_id=k.parent_object_id AND c.index_id=k.unique_index_id AND key_ordinal>0 AND COL_NAME(c.object_id,c.column_id) NOT IN ('inicio','fin','entidad'));
IF @restriccion IS NOT NULL EXEC(N'ALTER TABLE fiscalia.entrega DROP CONSTRAINT '+QUOTENAME(@restriccion));
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('fiscalia.entrega') AND name='UX_entrega_vigente')
    EXEC(N'CREATE UNIQUE INDEX UX_entrega_vigente ON fiscalia.entrega(inicio,fin,entidad) WHERE vigente=1');
IF OBJECT_ID('seguridad.reapertura','U') IS NULL
CREATE TABLE seguridad.reapertura(
    id bigint IDENTITY PRIMARY KEY, modulo varchar(20) NOT NULL, folio varchar(80) NOT NULL,
    usuario int NOT NULL REFERENCES seguridad.usuario(id), fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME()
);
COMMIT;
