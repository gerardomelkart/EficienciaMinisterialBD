USE EficienciaMinisterial_DEV;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
-- Fiscalía se autoriza por entidad o alcance nacional, sin catálogo de instituciones.
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE name = 'CK_acceso_institucion' AND parent_object_id = OBJECT_ID('seguridad.usuario_acceso'))
    ALTER TABLE seguridad.usuario_acceso DROP CONSTRAINT CK_acceso_institucion;
ALTER TABLE seguridad.usuario_acceso WITH CHECK ADD CONSTRAINT CK_acceso_institucion
    CHECK(rol <> 'PRIMER_RESPONDIENTE' OR institucion IS NOT NULL);
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE name = 'CK_usuario_institucion' AND parent_object_id = OBJECT_ID('seguridad.usuario'))
    ALTER TABLE seguridad.usuario DROP CONSTRAINT CK_usuario_institucion;
ALTER TABLE seguridad.usuario WITH CHECK ADD CONSTRAINT CK_usuario_institucion
    CHECK(rol <> 'PRIMER_RESPONDIENTE' OR institucion IS NOT NULL);
UPDATE catalogo.perfil SET requiere_institucion = 0, tipo_institucion = NULL, permite_estatal = 1 WHERE codigo = 'FISCALIA';
COMMIT;
GO
