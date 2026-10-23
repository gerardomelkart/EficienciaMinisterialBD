# Eficiencia Ministerial BD

Base SQL Server del proyecto Eficiencia Ministerial. Primera entrega para usuarios y recepción de archivos del módulo Primer Respondiente.

## Instalación

Ejecutar con SSMS o sqlcmd en este orden, en una instancia de pruebas SQL Server 2019 o superior:

1. `scripts/001_base.sql`: crea `EficienciaMinisterial` si no existe, esquemas, tablas, índices y secuencia de folios.
2. `scripts/002_catalogos.sql`: agrega las cuatro corporaciones, FGR y las 32 entidades. No crea usuarios ni contraseñas.

Los scripts pueden repetirse: crean objetos ausentes e insertan claves de catálogo faltantes. No actualizan ni reemplazan objetos existentes. Los cambios futuros se agregarán como migraciones numeradas; no se deben editar migraciones ya aplicadas. Se analizó su sintaxis con el parser T-SQL 2019 de Microsoft ScriptDom. No se conectaron ni ejecutaron estos scripts contra bases reales durante esta entrega.

## Modelo inicial

| Esquema / objeto | Contenido |
|---|---|
| `catalogo.institucion` | Corporaciones y fiscalías. Fiscalías estatales pendientes del catálogo autorizado. |
| `catalogo.entidad` | Entidades, claves 01–32. |
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
