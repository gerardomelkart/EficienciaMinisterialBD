# Catálogos y parámetros

## Aplicar la entrega

En una base existente, seleccionar `EficienciaMinisterial_DEV` en SSMS y ejecutar `scripts/003_configuracion.sql`. No borrar ni volver a crear la base. Para una instalación nueva ejecutar 001, 002 y 003, en ese orden. La migración conserva usuarios, cargas y valores ya configurados; al repetirse conserva los permisos y catálogos modificados tras la primera aplicación. La tabla `configuracion.migracion` registra la siembra inicial para evitar que una repetición restituya permisos retirados.

Aplicar primero BD, después API y front. El login requiere que la API pueda leer la configuración. Otorgar al login de la API SELECT sobre los esquemas `catalogo` y `configuracion`, y sobre `seguridad.rol_permiso`, además de sus permisos operativos anteriores. El script requiere permisos de DDL y debe ejecutarlo el responsable de BD.

## Fuentes de configuración

| Tabla | Uso |
| --- | --- |
| catalogo.institucion | Instituciones activas y tipo; no hay listas de instituciones en Angular. |
| catalogo.entidad | Entidades; `asignable` identifica las disponibles para asignar usuarios. |
| catalogo.rol | Nombre, tipo de institución requerida y alcance total del perfil. |
| catalogo.ambito | Nombre, exigencia de entidad y fuero de restricción. |
| catalogo.rol_ambito | Combinaciones permitidas al crear cuentas. |
| seguridad.rol_permiso | Acciones autorizadas: `usuarios`, `cargar`, `consultar_cargas`. |
| catalogo.fuero | Fueros y denominaciones aceptadas en Excel. |
| catalogo.alias | Equivalencias de instituciones y entidades. Los alias de entidad apuntan al ID expresado como texto. |
| configuracion.campo_carga | Encabezados, orden, obligatoriedad, longitud y diccionario del formato. |
| configuracion.parametro | Valores JSON escalares de límites, validación, folio y seguridad. |

Los códigos son identificadores estables: para cambiar la denominación se modifica `nombre`, no el código relacionado con datos existentes. Las siete claves de campo representan el modelo persistido; sus encabezados y orden se pueden cambiar. Agregar un tipo de dato o campo nuevo requiere ampliar el modelo, no solamente insertar una fila.

Los límites físicos de SQL, el formato XLSX admitido por el lector, las cotas de seguridad de BCrypt y los estados transaccionales son contratos técnicos. No son catálogos alternativos. Colores, textos de interfaz, rutas y estructura de componentes permanecen como código de presentación; las dos vistas de informes siguen siendo dummy.

## Modificar parámetros

`valor` contiene JSON: números sin comillas, booleanos `true`/`false` y textos entre comillas dobles. Ejemplo:

```sql
BEGIN TRANSACTION;
UPDATE configuracion.parametro SET valor=N'15000' WHERE clave='Carga.MaxFilas';
UPDATE configuracion.parametro SET valor=N'"EM-PR-"' WHERE clave='Carga.PrefijoFolio';
COMMIT;
```

No se publican credenciales en estas tablas. Conexión SQL, clave JWT, puertos, certificados y rutas de infraestructura se configuran fuera de la base mediante el entorno o User Secrets.

Los catálogos, columnas y límites de validación se leen en cada solicitud. El front toma una instantánea al iniciar sesión: cerrar y volver a entrar para actualizar formularios y permisos visuales. La API verifica siempre el permiso actual y no confía en el navegador. Los parámetros de ventana de login y límite multipart se leen al arrancar: reiniciar la API tras modificarlos.

No hay valores alternativos en memoria si faltan catálogos o parámetros: la API rechaza la configuración incompleta. El endpoint autenticado `GET /api/configuracion` entrega opciones y parámetros de uso del cliente; excluye los de seguridad.

Los datos iniciales conservan el comportamiento de la entrega anterior, pendiente del cuestionario. La generación de nuevos criterios operativos, edición/baja de cuentas y administración gráfica de catálogos quedan fuera de esta entrega. Administrar estos valores en SQL implica permisos sensibles y debe realizarse con control de cambios.

## Verificación

La entrega se valida con compilación de API y front, pruebas del lector con catálogos y límites alternativos y análisis de sintaxis SQL Server 2019. La migración debe probarse sobre una copia de la base antes de aplicarla: el análisis de sintaxis no reemplaza la ejecución ni comprueba permisos o datos existentes.
