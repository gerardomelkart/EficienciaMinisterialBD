USE EficienciaMinisterial_DEV;
GO
SET XACT_ABORT ON;
IF COL_LENGTH('seguridad.usuario', 'eliminado') IS NULL
    ALTER TABLE seguridad.usuario ADD eliminado bit NOT NULL CONSTRAINT DF_usuario_eliminado DEFAULT 0;
GO
-- Borrado lógico: preserva cargas, accesos históricos y bitácora.
