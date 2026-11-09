-- Ejecutar después de 005 y antes de iniciar la API de esta entrega.
-- Retira los binarios de los Excel ya cargados. Conserva registros, folios y metadatos.
SET XACT_ABORT ON;
GO
IF COL_LENGTH(N'primer_respondiente.carga', N'archivo') IS NOT NULL
BEGIN
    ALTER TABLE primer_respondiente.carga DROP COLUMN archivo;
END;
GO
