/* Ejecutar después de 001 y 002, sobre la base seleccionada en SSMS.
   Migración aditiva e idempotente: conserva cuentas, cargas y parámetros existentes. */
IF OBJECT_ID(N'seguridad.usuario', N'U') IS NULL
    THROW 50001, 'Seleccione la base del proyecto y ejecute 001 y 002 antes de 003.', 1;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF SCHEMA_ID(N'configuracion') IS NULL EXEC(N'CREATE SCHEMA configuracion');
IF OBJECT_ID(N'configuracion.migracion', N'U') IS NULL
    CREATE TABLE configuracion.migracion(codigo varchar(100) NOT NULL PRIMARY KEY, aplicado_utc datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
IF OBJECT_ID(N'configuracion.parametro', N'U') IS NULL
    CREATE TABLE configuracion.parametro(clave varchar(100) NOT NULL PRIMARY KEY, valor nvarchar(max) NOT NULL CHECK(ISJSON(N'[' + valor + N']') = 1));
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.MaxBytes') INSERT configuracion.parametro VALUES('Carga.MaxBytes', N'10000000');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.MaxFilas') INSERT configuracion.parametro VALUES('Carga.MaxFilas', N'20000');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.MaxDescomprimido') INSERT configuracion.parametro VALUES('Carga.MaxDescomprimido', N'100000000');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.MaxEntradasZip') INSERT configuracion.parametro VALUES('Carga.MaxEntradasZip', N'2000');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.AnioMinimo') INSERT configuracion.parametro VALUES('Carga.AnioMinimo', N'2000');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.AnioMaximo') INSERT configuracion.parametro VALUES('Carga.AnioMaximo', N'2100');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.LimiteConsulta') INSERT configuracion.parametro VALUES('Carga.LimiteConsulta', N'200');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.PrefijoFolio') INSERT configuracion.parametro VALUES('Carga.PrefijoFolio', N'"EM-PR-"');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.Extension') INSERT configuracion.parametro VALUES('Carga.Extension', N'".xlsx"');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.PatronFolio') INSERT configuracion.parametro VALUES('Carga.PatronFolio', N'"^[A-Z]{2}/(FC|FF)/[0-9]{3}/[0-9]{8}/[0-9]{4}$"');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.FormatoFechaFolio') INSERT configuracion.parametro VALUES('Carga.FormatoFechaFolio', N'"ddMMyyyy"');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.AvisarDuplicados') INSERT configuracion.parametro VALUES('Carga.AvisarDuplicados', N'true');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.AvisarDiferencias') INSERT configuracion.parametro VALUES('Carga.AvisarDiferencias', N'true');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Carga.PermitirFormulas') INSERT configuracion.parametro VALUES('Carga.PermitirFormulas', N'false');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Usuarios.PasswordMinimo') INSERT configuracion.parametro VALUES('Usuarios.PasswordMinimo', N'12');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Usuarios.PorPagina') INSERT configuracion.parametro VALUES('Usuarios.PorPagina', N'15');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Seguridad.TokenMinutos') INSERT configuracion.parametro VALUES('Seguridad.TokenMinutos', N'60');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Seguridad.IntentosLogin') INSERT configuracion.parametro VALUES('Seguridad.IntentosLogin', N'10');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Seguridad.VentanaLoginSegundos') INSERT configuracion.parametro VALUES('Seguridad.VentanaLoginSegundos', N'60');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Seguridad.CostoHash') INSERT configuracion.parametro VALUES('Seguridad.CostoHash', N'12');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Seguridad.RolInicial') INSERT configuracion.parametro VALUES('Seguridad.RolInicial', N'"SUPER_USUARIO"');
IF NOT EXISTS(SELECT 1 FROM configuracion.parametro WHERE clave = 'Seguridad.AmbitoInicial') INSERT configuracion.parametro VALUES('Seguridad.AmbitoInicial', N'"NACIONAL"');

IF OBJECT_ID(N'catalogo.rol', N'U') IS NULL
    CREATE TABLE catalogo.rol(codigo varchar(30) NOT NULL PRIMARY KEY, nombre nvarchar(80) NOT NULL, tipo_institucion varchar(20) NULL, alcance_total bit NOT NULL, activo bit NOT NULL DEFAULT 1);
IF OBJECT_ID(N'catalogo.ambito', N'U') IS NULL
    CREATE TABLE catalogo.ambito(codigo varchar(10) NOT NULL PRIMARY KEY, nombre nvarchar(80) NOT NULL, requiere_entidad bit NOT NULL, fuero varchar(2) NULL, activo bit NOT NULL DEFAULT 1);
IF OBJECT_ID(N'catalogo.rol_ambito', N'U') IS NULL
    CREATE TABLE catalogo.rol_ambito(rol varchar(30) NOT NULL REFERENCES catalogo.rol(codigo), ambito varchar(10) NOT NULL REFERENCES catalogo.ambito(codigo), PRIMARY KEY(rol, ambito));
IF OBJECT_ID(N'seguridad.rol_permiso', N'U') IS NULL
    CREATE TABLE seguridad.rol_permiso(rol varchar(30) NOT NULL REFERENCES catalogo.rol(codigo), permiso varchar(50) NOT NULL, PRIMARY KEY(rol, permiso));
IF OBJECT_ID(N'catalogo.fuero', N'U') IS NULL
    CREATE TABLE catalogo.fuero(codigo varchar(2) NOT NULL PRIMARY KEY, nombre nvarchar(80) NOT NULL, activo bit NOT NULL DEFAULT 1);
IF OBJECT_ID(N'catalogo.alias', N'U') IS NULL
    CREATE TABLE catalogo.alias(tipo varchar(20) NOT NULL, nombre nvarchar(200) NOT NULL, codigo varchar(30) NOT NULL, PRIMARY KEY(tipo, nombre));
IF OBJECT_ID(N'configuracion.campo_carga', N'U') IS NULL
    CREATE TABLE configuracion.campo_carga(codigo varchar(80) NOT NULL PRIMARY KEY, posicion int NOT NULL UNIQUE CHECK(posicion > 0), encabezado nvarchar(100) NOT NULL, requerido bit NOT NULL, max_longitud int NULL, regla nvarchar(1000) NOT NULL);
IF COL_LENGTH('catalogo.entidad', 'asignable') IS NULL
BEGIN
    ALTER TABLE catalogo.entidad ADD asignable bit NOT NULL CONSTRAINT DF_entidad_asignable DEFAULT 0;
    EXEC('UPDATE catalogo.entidad SET asignable = 1 WHERE id BETWEEN 1 AND 32');
END;
IF NOT EXISTS(SELECT 1 FROM configuracion.migracion WHERE codigo='003_configuracion')
BEGIN
INSERT catalogo.rol(codigo, nombre, tipo_institucion, alcance_total)
SELECT * FROM (VALUES
    ('SUPER_USUARIO', N'Superusuario', NULL, 1),
    ('PRIMER_RESPONDIENTE', N'Primer respondiente', 'CORPORACION', 0),
    ('FISCALIA', N'Fiscalía', 'FISCALIA', 0),
    ('CONSULTA', N'Consulta', NULL, 0)
) s(codigo,nombre,tipo_institucion,alcance_total) WHERE NOT EXISTS(SELECT 1 FROM catalogo.rol d WHERE d.codigo=s.codigo);
INSERT catalogo.ambito(codigo,nombre,requiere_entidad,fuero)
SELECT * FROM (VALUES ('NACIONAL',N'Nacional',0,NULL),('ESTATAL',N'Estatal',1,NULL),('FEDERAL',N'Federal',0,'FF')) s(codigo,nombre,requiere_entidad,fuero)
WHERE NOT EXISTS(SELECT 1 FROM catalogo.ambito d WHERE d.codigo=s.codigo);
INSERT catalogo.rol_ambito SELECT r.codigo,a.codigo FROM catalogo.rol r CROSS JOIN catalogo.ambito a
WHERE (r.codigo <> 'SUPER_USUARIO' OR a.codigo='NACIONAL') AND NOT EXISTS(SELECT 1 FROM catalogo.rol_ambito d WHERE d.rol=r.codigo AND d.ambito=a.codigo);
INSERT seguridad.rol_permiso SELECT * FROM (VALUES
    ('SUPER_USUARIO','usuarios'),('SUPER_USUARIO','consultar_cargas'),
    ('PRIMER_RESPONDIENTE','cargar'),('PRIMER_RESPONDIENTE','consultar_cargas'),('CONSULTA','consultar_cargas')
) s(rol,permiso) WHERE NOT EXISTS(SELECT 1 FROM seguridad.rol_permiso d WHERE d.rol=s.rol AND d.permiso=s.permiso);
INSERT catalogo.fuero SELECT * FROM (VALUES ('FC',N'Fuero común'),('FF',N'Fuero federal')) s(codigo,nombre)
WHERE NOT EXISTS(SELECT 1 FROM catalogo.fuero d WHERE d.codigo=s.codigo);
INSERT catalogo.alias SELECT * FROM (VALUES
    ('INSTITUCION',N'MARINA','SEMAR'),('INSTITUCION',N'SECRETARIA DE MARINA','SEMAR'),
    ('INSTITUCION',N'GUARDIA NACIONAL','GN'),('INSTITUCION',N'SECRETARIA DE LA DEFENSA NACIONAL','SEDENA'),
    ('INSTITUCION',N'SECRETARIA DE SEGURIDAD Y PROTECCION CIUDADANA','SSPC'),
    ('ENTIDAD',N'ESTADO DE MEXICO','15'),('ENTIDAD',N'COAHUILA','5'),('ENTIDAD',N'MICHOACAN','16'),
    ('ENTIDAD',N'VERACRUZ','30'),('ENTIDAD',N'DISTRITO FEDERAL','9')
) s(tipo,nombre,codigo) WHERE NOT EXISTS(SELECT 1 FROM catalogo.alias d WHERE d.tipo=s.tipo AND d.nombre=s.nombre);
INSERT configuracion.campo_carga SELECT * FROM (VALUES
    ('CORPORACION',1,N'CORPORACION',1,NULL,N'Institución del catálogo que corresponda al usuario.'),
    ('FOLIO_RND',2,N'FOLIO_RND',1,40,N'Folio conforme al patrón configurado.'),
    ('FECHA_DETENCION',3,N'FECHA_DETENCION',1,NULL,N'Fecha real de Excel, no texto.'),
    ('AUTORIDAD_EN_DONDE_SE_HIZO_LA_PUESTA',4,N'AUTORIDAD_EN_DONDE_SE_HIZO_LA_PUESTA',1,500,N'Texto de la autoridad receptora.'),
    ('NOMBRE_DETENIDO',5,N'NOMBRE_DETENIDO',1,300,N'Nombre de la persona detenida.'),
    ('ENTIDAD_DETENCION',6,N'ENTIDAD_DETENCION',1,NULL,N'Entidad del catálogo nacional.'),
    ('TIPO_FUERO',7,N'TIPO_FUERO',1,NULL,N'Nombre del fuero en el catálogo.')
) s(codigo,posicion,encabezado,requerido,max_longitud,regla)
WHERE NOT EXISTS(SELECT 1 FROM configuracion.campo_carga d WHERE d.codigo=s.codigo);
    INSERT configuracion.migracion(codigo) VALUES('003_configuracion');
END;
-- Sustituir listas de valores en CHECK por relaciones a catálogos; no tocar otros CHECK.
DECLARE @ddl nvarchar(max) = N'';
SELECT @ddl += N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(parent_object_id)) + N' DROP CONSTRAINT ' + QUOTENAME(name) + N';'
FROM sys.check_constraints WHERE
    (parent_object_id=OBJECT_ID('seguridad.usuario') AND (definition LIKE '%[[]rol[]]%' OR definition LIKE '%[[]ambito[]]%'))
    OR (parent_object_id=OBJECT_ID('primer_respondiente.registro') AND definition LIKE '%[[]tipo_fuero[]]%');
EXEC sp_executesql @ddl;
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_usuario_rol_ambito')
    ALTER TABLE seguridad.usuario ADD CONSTRAINT FK_usuario_rol_ambito FOREIGN KEY(rol,ambito) REFERENCES catalogo.rol_ambito(rol,ambito);
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_registro_fuero')
    ALTER TABLE primer_respondiente.registro ADD CONSTRAINT FK_registro_fuero FOREIGN KEY(tipo_fuero) REFERENCES catalogo.fuero(codigo);
COMMIT;
