USE EficienciaMinisterial_DEV;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH('primer_respondiente.carga', 'vigente') IS NULL
    ALTER TABLE primer_respondiente.carga ADD vigente bit NOT NULL CONSTRAINT DF_carga_vigente DEFAULT 1;
IF COL_LENGTH('primer_respondiente.registro', 'duplicado') IS NULL
    ALTER TABLE primer_respondiente.registro ADD duplicado bit NOT NULL CONSTRAINT DF_registro_duplicado DEFAULT 0;
IF OBJECT_ID('primer_respondiente.periodo_corporacion', 'U') IS NULL
BEGIN
    CREATE TABLE primer_respondiente.periodo_corporacion(
        id_periodo int NOT NULL REFERENCES primer_respondiente.periodo(id),
        institucion varchar(20) NOT NULL REFERENCES catalogo.institucion(codigo),
        PRIMARY KEY(id_periodo, institucion));
END;
INSERT primer_respondiente.periodo_corporacion(id_periodo, institucion)
SELECT p.id, i.codigo FROM primer_respondiente.periodo p CROSS JOIN catalogo.institucion i
WHERE i.tipo = 'CORPORACION' AND i.activo = 1
    AND NOT EXISTS(SELECT 1 FROM primer_respondiente.periodo_corporacion d WHERE d.id_periodo = p.id AND d.institucion = i.codigo);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('primer_respondiente.carga') AND name = 'IX_carga_periodo_vigente')
    CREATE INDEX IX_carga_periodo_vigente ON primer_respondiente.carga(id_periodo, institucion, estado, vigente);
-- Se preserva el histórico; sólo la última entrega de cada corporación/quincena es vigente.
;WITH orden AS (
    SELECT vigente, ROW_NUMBER() OVER(PARTITION BY id_periodo, institucion ORDER BY confirmado_utc DESC, folio DESC, id DESC) AS numero
    FROM primer_respondiente.carga WHERE estado = 'CONFIRMADA' AND id_periodo IS NOT NULL
)
UPDATE orden SET vigente = CASE WHEN numero = 1 THEN 1 ELSE 0 END;
COMMIT;
GO

CREATE OR ALTER TRIGGER primer_respondiente.tr_periodo_corporaciones
ON primer_respondiente.periodo AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT primer_respondiente.periodo_corporacion(id_periodo, institucion)
    SELECT p.id, i.codigo FROM inserted p CROSS JOIN catalogo.institucion i
    WHERE i.tipo = 'CORPORACION' AND i.activo = 1;
END;
GO
