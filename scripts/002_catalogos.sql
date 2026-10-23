USE EficienciaMinisterial;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT INTO catalogo.institucion(codigo, nombre, tipo)
SELECT codigo, nombre, tipo
FROM (VALUES
    ('SEDENA', N'Secretaría de la Defensa Nacional', 'CORPORACION'),
    ('SEMAR', N'Secretaría de Marina', 'CORPORACION'),
    ('GN', N'Guardia Nacional', 'CORPORACION'),
    ('SSPC', N'Secretaría de Seguridad y Protección Ciudadana', 'CORPORACION'),
    ('FGR', N'Fiscalía General de la República', 'FISCALIA')
) AS origen(codigo, nombre, tipo)
WHERE NOT EXISTS(SELECT 1 FROM catalogo.institucion destino WHERE destino.codigo = origen.codigo);

-- Fuente: gerardomelkart/SIIID2BD, catalogos/Catalogos_1.sql.
-- Referencia: 30311c04d0a2d49ad7e62b58398c0e3416e6dc2d.
-- Se conservan los identificadores, claves, nombres y siglas del SIIID.
INSERT INTO catalogo.entidad(id, clave, nombre, siglas, siglas_renapo)
SELECT id, clave, nombre, siglas, siglas_renapo FROM (VALUES
    (0, N'00', N'no aplica', N'n/a', N'n/a'),
    (1, N'01', N'Aguascalientes', N'Ags.', N'AS'),
    (2, N'02', N'Baja California', N'BC', N'BC'),
    (3, N'03', N'Baja California Sur', N'BCS', N'BS'),
    (4, N'04', N'Campeche', N'Camp.', N'CC'),
    (5, N'05', N'Coahuila de Zaragoza', N'Coah.', N'CL'),
    (6, N'06', N'Colima', N'Col.', N'CM'),
    (7, N'07', N'Chiapas', N'Chis.', N'CS'),
    (8, N'08', N'Chihuahua', N'Chih.', N'CH'),
    (9, N'09', N'Ciudad de México', N'CDMX', N'DF'),
    (10, N'10', N'Durango', N'Dgo.', N'DG'),
    (11, N'11', N'Guanajuato', N'Gto.', N'GT'),
    (12, N'12', N'Guerrero', N'Gro.', N'GR'),
    (13, N'13', N'Hidalgo', N'Hgo.', N'HG'),
    (14, N'14', N'Jalisco', N'Jal.', N'JC'),
    (15, N'15', N'México', N'Mex.', N'MC'),
    (16, N'16', N'Michoacán de Ocampo', N'Mich.', N'MN'),
    (17, N'17', N'Morelos', N'Mor.', N'MS'),
    (18, N'18', N'Nayarit', N'Nay.', N'NT'),
    (19, N'19', N'Nuevo León', N'NL', N'NL'),
    (20, N'20', N'Oaxaca', N'Oax.', N'OC'),
    (21, N'21', N'Puebla', N'Pue.', N'PL'),
    (22, N'22', N'Querétaro', N'Qro.', N'QT'),
    (23, N'23', N'Quintana Roo', N'Q. Roo', N'QR'),
    (24, N'24', N'San Luis Potosí', N'SLP', N'SP'),
    (25, N'25', N'Sinaloa', N'Sin.', N'SL'),
    (26, N'26', N'Sonora', N'Son.', N'SR'),
    (27, N'27', N'Tabasco', N'Tab.', N'TC'),
    (28, N'28', N'Tamaulipas', N'Tamps.', N'TS'),
    (29, N'29', N'Tlaxcala', N'Tlax.', N'TL'),
    (30, N'30', N'Veracruz de Ignacio de la Llave', N'Ver.', N'VZ'),
    (31, N'31', N'Yucatán', N'Yuc.', N'YN'),
    (32, N'32', N'Zacatecas', N'Zac.', N'ZS'),
    (33, N'33', N'Extranjero', N'Ext.', N'n/a')
) AS origen(id, clave, nombre, siglas, siglas_renapo)
WHERE NOT EXISTS(SELECT 1 FROM catalogo.entidad destino WHERE destino.id = origen.id);
COMMIT;
GO
