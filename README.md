# Eficiencia Ministerial BD

Modelo y scripts SQL Server para persistir usuarios, catálogos, archivos y registros de captura de Eficiencia Ministerial. Este repositorio es la capa de datos; las operaciones se exponen mediante la API.

## Proyecto Eficiencia Ministerial

Eficiencia Ministerial es una plataforma en desarrollo para recibir información de detenciones y, en una etapa posterior, incorporar el seguimiento ministerial de las fiscalías. Su arquitectura contempla una API central y una base propia, con **Primer Respondiente** como primera interfaz de captura.

Esta versión reúne la base técnica y el diseño inicial. Las reglas operativas definitivas están pendientes de respuesta del área responsable; las funcionalidades provisionales no deben interpretarse como un proceso productivo terminado.

## Repositorios relacionados

| Repositorio | Responsabilidad | Tecnología |
| --- | --- | --- |
| [PrimerRespondienteFront](https://github.com/gerardomelkart/PrimerRespondienteFront) | Interfaz de acceso, captura por Excel, navegación e informes provisionales. | Angular, TypeScript, Bootstrap |
| [EficienciaMinisterialApi](https://github.com/gerardomelkart/EficienciaMinisterialApi) | Autenticación, autorización, validaciones, recepción de archivos y acceso a datos. | C#, ASP.NET Core, .NET 10 |
| [EficienciaMinisterialBD](https://github.com/gerardomelkart/EficienciaMinisterialBD) | Esquemas, tablas, catálogos, índices y secuencia de folios. | SQL Server 2019 o superior |

El navegador se comunica por HTTP con la API; la API consulta y persiste en SQL Server. **El front no se conecta directamente a la base.** Para ejecutar el sistema completo se requieren los tres repositorios.

## Flujo y alcance

El flujo implementado para las corporaciones permite descargar una plantilla, cargar un Excel, revisar errores y observaciones y confirmar una entrega para obtener un folio y un acuse HTML imprimible. El archivo original se conserva junto con los registros aceptados.

El flujo previsto para fiscalías consiste en descargar una plantilla con información de referencia y completar los campos de seguimiento ministerial. Esa segunda etapa todavía no está implementada.

- **Disponible:** autenticación JWT, perfiles iniciales, alta y listado de usuarios, carga y validación de Excel, confirmación con folio, acuse y registros de operación.
- **Provisional:** pantallas de informes “Reporte primer respondiente” y “Reporte completo”, sin consultas ni indicadores definitivos.
- **Pendiente:** catálogos y reglas definitivas, fiscalías estatales, plantilla de seguimiento, cruces automáticos, edición/baja de usuarios y reportes operativos.

Las futuras conexiones con SIIID e Ingesta de Datos no están implementadas. El cruce con RND/RND_FA, a partir de las copias generadas por DBBridge, también está pendiente. No existe actualmente un integrador entre estos sistemas.

## Puesta en marcha del conjunto

1. Preparar una instancia SQL Server de pruebas y ejecutar los scripts del repositorio de BD.
2. Configurar la conexión y la clave JWT fuera del código, crear el superusuario e iniciar la API.
3. Instalar las dependencias del front e iniciar Angular con su proxy local.

Cada repositorio detalla sus pasos más abajo. No se incluyen credenciales predeterminadas ni datos personales de ejemplo; las demostraciones deben utilizar datos ficticios.

## Instalación

Ejecutar con SSMS o sqlcmd en este orden, en una instancia de pruebas SQL Server 2019 o superior:

1. `scripts/001_base.sql`: crea `EficienciaMinisterial_DEV` si no existe, esquemas, tablas, índices y secuencia de folios.
2. `scripts/002_catalogos.sql`: agrega las cuatro corporaciones, FGR y el catálogo de entidades del SIIID (32 entidades, 0 = no aplica y 33 = Extranjero). No crea usuarios ni contraseñas.

Los scripts pueden repetirse: crean objetos ausentes e insertan claves de catálogo faltantes. No actualizan ni reemplazan objetos existentes. Los cambios futuros se agregarán como migraciones numeradas; no se deben editar migraciones ya aplicadas. Se analizó su sintaxis con el parser T-SQL 2019 de Microsoft ScriptDom. No se conectaron ni ejecutaron estos scripts contra bases reales durante esta entrega.

## Modelo inicial

| Esquema / objeto | Contenido |
|---|---|
| `catalogo.institucion` | Corporaciones y fiscalías. Fiscalías estatales pendientes del catálogo autorizado. |
| `catalogo.entidad` | Catálogo del SIIID: id, clave, nombre, siglas, siglas RENAPO y activo. |
| `seguridad.usuario` | Hash BCrypt, perfil, institución, ámbito, entidad y estado activo. |
| `seguridad.bitacora` | Inicios de sesión exitosos, altas y operaciones de carga. |
| `primer_respondiente.carga` | Archivo original, SHA-256, periodo, propietario, estado, folio y fechas UTC. |
| `primer_respondiente.registro` | Los siete datos de captura y estado de cruce pendiente. |
| `primer_respondiente.folio_seq` | Consecutivo para folios de entrega; admite huecos por rollback. |

Una carga VALIDADA aún no es una entrega. La API confirma con bloqueo de fila, asigna folio y registra bitácora dentro de la misma transacción. Los identificadores internos no dependen del folio RND. No se aplica restricción única al folio RND porque la política de repetidos/operaciones conjuntas está pendiente.

El primer superusuario se crea mediante el comando local de la API documentado en su README. No insertar contraseñas en texto plano. La cuenta de aplicación necesita SELECT sobre catálogos; SELECT/INSERT en usuarios; INSERT en bitácora; SELECT/INSERT/UPDATE en cargas; SELECT/INSERT en registros y UPDATE sobre la secuencia de folios. Usar otra cuenta para instalar migraciones. Los permisos de edición/baja se definirán con sus operaciones futuras.

## Decisiones pendientes

Catálogo de autoridades/fiscalías estatales, alcance definitivo de usuarios, periodos, duplicados, asignación de fiscalía, cruce con RND, seguimiento ministerial, cierres e indicadores. La información de la corporación no se sobrescribirá con RND ni con fiscalías. `homologar_a_diccionario` queda excluida.

La base RND de DBBridge es una fuente separada: no se crean ni modifican sus tablas aquí. Sus tablas diarias son `tablero_rnd_yyyyMMdd` y `tablero_rnd_yyyyMMdd_fa`. La selección del corte y el tratamiento de RND_FA quedan pendientes de confirmación.

## Referencia del catálogo de entidades

Se tomó de `gerardomelkart/SIIID2BD`, archivo `catalogos/Catalogos_1.sql`, commit `30311c04d0a2d49ad7e62b58398c0e3416e6dc2d`. Se conservan exactamente las 34 filas de referencia, incluidos `no aplica` y `Extranjero`. Los campos nuevos son adicionales al `id` y `nombre` utilizados por la API, por lo que no cambian las relaciones existentes en el código.

Los registros especiales se conservan como parte de la referencia del SIIID; no representan entidades federativas adicionales. Su uso permitido en cada operación está pendiente de definición. En bases existentes, revisar su versión antes de aplicar cambios; no borrar ni recrear una base para actualizar el proyecto.

## Entornos

La base actual de desarrollo se llama `EficienciaMinisterial_DEV` y usa el servidor SQL remoto asignado al proyecto. El responsable la crea y ejecuta los scripts iniciales en ella. No utiliza LocalDB ni la base SIIID2_QA.

La base productiva `EficienciaMinisterial` se creará al publicar a producción; no se crea en esta entrega. Entonces deberán prepararse los scripts con ese destino. La API mantiene la clave de configuración `ConnectionStrings:EficienciaMinisterial` para ambos entornos; el valor determina la base. Ver la [guía de configuración de la API](https://github.com/gerardomelkart/EficienciaMinisterialApi/blob/main/docs/configuracion-entornos.md) para configurar User Secrets o entorno del servicio.

Un login existente en SQL requiere mapeo y permisos sobre la nueva BD. Los permisos en SIIID2_QA no se heredan. No guardar usuarios reales, contraseñas ni cadenas completas en este repositorio público.
