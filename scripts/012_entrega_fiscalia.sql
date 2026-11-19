SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF SCHEMA_ID('fiscalia') IS NULL EXEC('CREATE SCHEMA fiscalia');
IF OBJECT_ID('fiscalia.entrega','U') IS NULL
CREATE TABLE fiscalia.entrega(
    id bigint IDENTITY PRIMARY KEY,
    inicio date NOT NULL, fin date NOT NULL,
    entidad tinyint NULL REFERENCES catalogo.entidad(id),
    usuario int NOT NULL REFERENCES seguridad.usuario(id),
    fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
    recibidos int NOT NULL, no_recibidos int NOT NULL,
    huella binary(32) NOT NULL,
    UNIQUE(inicio,fin,entidad)
);
IF OBJECT_ID('fiscalia.respuesta','U') IS NULL
CREATE TABLE fiscalia.respuesta(
    entrega bigint NOT NULL REFERENCES fiscalia.entrega(id),
    registro bigint NOT NULL REFERENCES primer_respondiente.registro(id),
    datos nvarchar(max) NOT NULL,
    PRIMARY KEY(entrega,registro)
);
COMMIT;
