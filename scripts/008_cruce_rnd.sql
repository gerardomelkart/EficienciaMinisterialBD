USE EficienciaMinisterial_DEV;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH('primer_respondiente.registro', 'rnd_tabla') IS NULL
BEGIN
    ALTER TABLE primer_respondiente.registro ADD
        rnd_tabla varchar(128) NULL,
        rnd_fecha_fuente date NULL,
        rnd_consultado_utc datetime2 NULL,
        rnd_coincidencias nvarchar(max) NULL,
        CONSTRAINT CK_registro_rnd_json CHECK(rnd_coincidencias IS NULL OR ISJSON(rnd_coincidencias) = 1);
END;
COMMIT;
GO
