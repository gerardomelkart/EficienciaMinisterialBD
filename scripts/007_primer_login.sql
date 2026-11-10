USE EficienciaMinisterial_DEV;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH('seguridad.usuario', 'debe_cambiar_password') IS NULL
BEGIN
    ALTER TABLE seguridad.usuario ADD debe_cambiar_password bit NOT NULL
        CONSTRAINT DF_usuario_debe_cambiar_password DEFAULT (1) WITH VALUES;
END;
IF COL_LENGTH('seguridad.usuario', 'version_credenciales') IS NULL
    ALTER TABLE seguridad.usuario ADD version_credenciales int NOT NULL
        CONSTRAINT DF_usuario_version_credenciales DEFAULT (0) WITH VALUES;
COMMIT;
-- Los superusuarios están exentos según sus accesos vigentes; no se modifica su contraseña.
