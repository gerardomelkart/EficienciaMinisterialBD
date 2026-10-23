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

INSERT INTO catalogo.entidad(id, nombre)
SELECT id, nombre FROM (VALUES
    (1, N'Aguascalientes'), (2, N'Baja California'), (3, N'Baja California Sur'),
    (4, N'Campeche'), (5, N'Coahuila de Zaragoza'), (6, N'Colima'), (7, N'Chiapas'),
    (8, N'Chihuahua'), (9, N'Ciudad de México'), (10, N'Durango'), (11, N'Guanajuato'),
    (12, N'Guerrero'), (13, N'Hidalgo'), (14, N'Jalisco'), (15, N'México'),
    (16, N'Michoacán de Ocampo'), (17, N'Morelos'), (18, N'Nayarit'), (19, N'Nuevo León'),
    (20, N'Oaxaca'), (21, N'Puebla'), (22, N'Querétaro'), (23, N'Quintana Roo'),
    (24, N'San Luis Potosí'), (25, N'Sinaloa'), (26, N'Sonora'), (27, N'Tabasco'),
    (28, N'Tamaulipas'), (29, N'Tlaxcala'), (30, N'Veracruz de Ignacio de la Llave'),
    (31, N'Yucatán'), (32, N'Zacatecas')
) AS origen(id, nombre)
WHERE NOT EXISTS(SELECT 1 FROM catalogo.entidad destino WHERE destino.id = origen.id);
COMMIT;
GO
