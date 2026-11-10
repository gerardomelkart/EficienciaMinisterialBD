# Eficiencia Ministerial BD

Modelo y scripts SQL Server para persistir usuarios, catálogos, archivos y registros de captura de Eficiencia Ministerial. Este repositorio es la capa de datos; las operaciones se exponen mediante la API.

## Proyecto Eficiencia Ministerial

Eficiencia Ministerial es una plataforma en desarrollo para recibir información de detenciones y, en una etapa posterior, incorporar el seguimiento ministerial de las fiscalías. Su arquitectura contempla una API central y una base propia, con **Primer Respondiente** como primera interfaz de captura.

Esta versión incorpora las primeras reglas confirmadas del cuestionario: usuarios con múltiples accesos y validación básica de la captura. El seguimiento de fiscalías, el cruce con RND y los reportes productivos siguen en desarrollo.

## Repositorios relacionados

| Repositorio | Responsabilidad | Tecnología |
| --- | --- | --- |
| [PrimerRespondienteFront](https://github.com/gerardomelkart/PrimerRespondienteFront) | Interfaz de acceso, captura por Excel, navegación e informes provisionales. | Angular, TypeScript, Bootstrap |
| [EficienciaMinisterialApi](https://github.com/gerardomelkart/EficienciaMinisterialApi) | Autenticación, autorización, validaciones, recepción de archivos y acceso a datos. | C#, ASP.NET Core, .NET 10 |
| [EficienciaMinisterialBD](https://github.com/gerardomelkart/EficienciaMinisterialBD) | Esquemas, tablas, catálogos, índices y secuencia de folios. | SQL Server 2019 o superior |

El navegador se comunica por HTTP con la API; la API consulta y persiste en SQL Server. **El front no se conecta directamente a la base.** Para ejecutar el sistema completo se requieren los tres repositorios.

## Flujo y alcance

El flujo implementado para las corporaciones permite descargar una plantilla, cargar un Excel, revisar errores y observaciones y confirmar una entrega para obtener un folio y un acuse PDF institucional generado bajo demanda. Se conservan los registros y metadatos de la entrega; no se almacenan archivos Excel ni PDF en la base o en el disco de la API.

El flujo previsto para fiscalías consiste en descargar una plantilla con información de referencia y completar los campos de seguimiento ministerial. Esa segunda etapa todavía no está implementada.

- **Disponible:** autenticación JWT, selección de acceso, alta/edición/activación de usuarios, carga y validación de Excel, confirmación con folio, acuse y registros de operación.
- **Provisional:** pantallas de informes “Reporte primer respondiente” y “Reporte completo”, sin consultas ni indicadores definitivos.
- **Pendiente:** catálogo definitivo de fiscalías, plantilla de seguimiento, cruces automáticos, control de quincenas y reportes operativos.

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
3. `scripts/003_usuarios_y_validacion.sql`: agrega múltiples accesos por cuenta, conserva las cuentas previas, registra el objetivo de las ediciones y permite dejar fuero vacío. Los alcances FEDERAL anteriores se migran como NACIONAL en la tabla de accesos.
4. `scripts/004_catalogos_ministeriales.sql`: incorpora 75 opciones de los cinco catálogos del área, incluida MASC (id 14) en conclusión. Conserva los identificadores del Excel y no reemplaza opciones existentes.

5. `scripts/005_periodos_y_catalogos_captura.sql`: agrega el calendario de quincenas, perfiles, ámbitos, fueros y equivalencias de captura; las cargas nuevas utilizan id_periodo.
6. `scripts/006_archivos_bajo_demanda.sql`: elimina la columna binaria archivo y su contenido existente. Se conservan filas, folios y metadatos. Ejecutar antes de iniciar la API de esta entrega.

Aplicar las migraciones pendientes, en orden, antes de iniciar la API actualizada. La corrección de carga requiere el script 005. Usar una cuenta autorizada para migraciones.

Los scripts pueden repetirse: crean objetos ausentes e insertan claves de catálogo faltantes. Las migraciones numeradas posteriores actualizan los objetos indicados sin borrar datos. Las migraciones 003 y posteriores actualizan los objetos que indiquen; no se deben editar migraciones ya aplicadas. Se analizó su sintaxis con el parser T-SQL 2019 de Microsoft ScriptDom. No se conectaron ni ejecutaron estos scripts contra bases reales durante esta entrega.

## Modelo inicial

| Esquema / objeto | Contenido |
|---|---|
| `catalogo.institucion` | Corporaciones y fiscalías. Fiscalías estatales pendientes del catálogo autorizado. |
| `catalogo.entidad` | Catálogo del SIIID: id, clave, nombre, siglas, siglas RENAPO y activo. |
| `seguridad.usuario` | Cuenta, hash BCrypt, estado activo y asignación primaria de compatibilidad. |
| `seguridad.usuario_acceso` | Asignaciones completas de perfil, institución y alcance nacional o entidad. |
| `catalogo.opcion_ministerial` | Cinco catálogos del área, con grupo, id, descripción y estado activo. |
| `seguridad.bitacora` | Inicios de sesión exitosos, altas y operaciones de carga. |
| `primer_respondiente.carga` | Nombre y SHA-256 del archivo, periodo, propietario, estado, folio y fechas UTC. Sin binarios. |
| `primer_respondiente.registro` | Los siete datos de captura y estado de cruce pendiente. |
| `primer_respondiente.folio_seq` | Consecutivo para folios de entrega; admite huecos por rollback. |

Una carga VALIDADA aún no es una entrega. La API confirma con bloqueo de fila, asigna folio y registra bitácora dentro de la misma transacción. Los identificadores internos no dependen del folio RND. No se aplica restricción única al folio RND: un folio puede tener varias personas y corporaciones. El cruce consolidado y la bandera de duplicados están pendientes de implementación.

El primer superusuario se crea mediante el comando local de la API documentado en su README. No insertar contraseñas en texto plano. La cuenta de aplicación necesita SELECT sobre catálogos; SELECT/INSERT/UPDATE en seguridad.usuario; SELECT/INSERT/DELETE en seguridad.usuario_acceso; INSERT en seguridad.bitacora; SELECT/INSERT/UPDATE en cargas; SELECT/INSERT en registros y UPDATE sobre la secuencia de folios. La administración usa `sys.sp_getapplock` con propietario Transaction y el principal predeterminado public. No requiere db_owner. Usar otra cuenta para instalar migraciones.

## Decisiones pendientes

Catálogo definitivo de fiscalías; asignación y reasignación; adolescentes/identidad reservada; conteo cuando un folio tiene varias personas con resultados distintos; denominadores de indicadores; agrupación temporal de gráficas y corte de respuestas de fiscalías.

El cruce con RND, el control de quincenas y el seguimiento ministerial aún no están implementados. La información de la corporación no se sobrescribirá con RND ni con fiscalías. `homologar_a_diccionario` queda excluida. RND_FA no se utiliza para el seguimiento: las faltas administrativas quedan excluidas.

## Referencia del catálogo de entidades

Se tomó de `gerardomelkart/SIIID2BD`, archivo `catalogos/Catalogos_1.sql`, commit `30311c04d0a2d49ad7e62b58398c0e3416e6dc2d`. Se conservan exactamente las 34 filas de referencia, incluidos `no aplica` y `Extranjero`. Los campos nuevos son adicionales al `id` y `nombre` utilizados por la API, por lo que no cambian las relaciones existentes en el código.

Los registros especiales se conservan como parte de la referencia del SIIID; no representan entidades federativas adicionales. Su uso permitido en cada operación está pendiente de definición. En bases existentes, revisar su versión antes de aplicar cambios; no borrar ni recrear una base para actualizar el proyecto.

## Entornos

La base actual de desarrollo se llama `EficienciaMinisterial_DEV` y usa el servidor SQL remoto asignado al proyecto. El responsable la crea y ejecuta los scripts iniciales en ella. No utiliza LocalDB ni la base SIIID2_QA.

La base productiva `EficienciaMinisterial` se creará al publicar a producción; no se crea en esta entrega. Entonces deberán prepararse los scripts con ese destino. La API mantiene la clave de configuración `ConnectionStrings:EficienciaMinisterial` para ambos entornos; el valor determina la base. Ver la [guía de configuración de la API](https://github.com/gerardomelkart/EficienciaMinisterialApi/blob/main/docs/configuracion-entornos.md) para configurar User Secrets o entorno del servicio.

Un login existente en SQL requiere mapeo y permisos sobre la nueva BD. Los permisos en SIIID2_QA no se heredan. No guardar usuarios reales, contraseñas ni cadenas completas en este repositorio público.

## 005 — Periodos quincenales y catálogos de captura

Ejecutar scripts/005_periodos_y_catalogos_captura.sql después de 004. Agrega perfiles, ámbitos, equivalencias de corporaciones/entidades, fueros y un calendario de quincenas. La instalación utiliza junio de 2025 como origen histórico, conforme al cuestionario. No modifica las fechas de las cargas existentes.

La API llama primer_respondiente.GenerarPeriodos para completar el calendario hasta la fecha actual de México. El procedimiento es transaccional e idempotente. La cuenta de API necesita EXECUTE sobre ese procedimiento, SELECT sobre primer_respondiente.periodo y SELECT sobre los catálogos nuevos. La cadena de propiedad permite generar los periodos sin otorgarle permisos generales de instalación.

Las quincenas disponibles cumplen habilitado = 1 y cerrado = 0. Estas columnas permiten administrar la recepción desde SQL. Todavía no se implementa el cierre automático por recepción de todas las corporaciones, ni el reemplazo de entregas.

Las cargas nuevas guardan id_periodo y las fechas resueltas en SQL; el front no puede imponer fechas arbitrarias. Los borradores anteriores sin id_periodo deben validarse nuevamente. Se preservan los acuses y las cargas confirmadas anteriores.

## Sin almacenamiento de archivos

Los Excel de entrada se leen en memoria. La base conserva registros, nombre del archivo y SHA-256; no almacena Excel ni PDF. Las descargas se reconstruyen desde los datos persistidos. La migración 006 retira los binarios históricos sin eliminar registros ni entregas.


### Primer inicio de sesión

Aplicar `EficienciaMinisterialBD/scripts/007_primer_login.sql` antes de iniciar la API actualizada.
Las cuentas existentes y nuevas deben cambiar su contraseña antes de acceder a los módulos.
Las cuentas con cualquier acceso `SUPER_USUARIO` quedan exentas. El cambio exige contraseña actual,
nueva diferente de al menos 12 caracteres y confirmación; se registra en bitácora.
La API bloquea las operaciones hasta completar el cambio. El indicador se desactiva al guardarlo.
La confirmación rechaza el mismo SHA-256 para una corporación y periodo ya confirmados,
incluso en solicitudes concurrentes; no se guardan archivos originales.


### Cruce diario RND y control de entregas

Aplicar las migraciones 007, 008 y 009 de EficienciaMinisterialBD; configurar en la API
`ConnectionStrings:RndDestino` fuera del repositorio. La validación consulta la última tabla diaria
completa del destino DBBridge y conserva referencias RND, fuente y fecha sin guardar el Excel.
Los no localizados requieren consentimiento expreso. La última carga de una corporación/quincena
es la vigente y se preservan las anteriores; la quincena cierra al completar las corporaciones esperadas.
El cruce de validación está implementado; plantillas y seguimiento de fiscalías e informes finales
siguen pendientes. Ver docs/revision-carga-y-catalogos.md en el repositorio de API.
