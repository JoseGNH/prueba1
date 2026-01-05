# Autorizacion de Pagos - WebDev

Este repositorio contiene los artefactos necesarios para completar la pestaña de autorizacion de pagos en WebDev (WLanguage) usando SQL Server.

## Estructura
- `sql/00_prerequisites.sql`: asegura que la tabla `coop.Autorizacion_Pago` permita `NULL` en `dBaja` y agrega un default en `dAlta` (el script ya usa la base `joso`).
- `sql/05_create_tables.sql`: crea las tablas `cat.Errores`, `per.Persona`, `soc.Socio` y `coop.Autorizacion_Pago` junto con sus constraints.
- `sql/12_basic_queries.sql`: ejemplos sencillos (SELECT/INSERT) para entender el flujo antes de usar las consultas avanzadas.
- `sql/10_lookup_queries.sql`: consultas de apoyo para el motor de búsqueda, el mensaje dinamico, el historial y la validacion posterior al alta.
- `sql/20_usp_autorizar_pago_registrar.sql`: elimina el procedimiento legado y documenta las sentencias que debe ejecutar la aplicación para cerrar el pago previo e insertar el nuevo.
- `docs/wlanguage_flow.md`: guia paso a paso de como integrar los controles y eventos en WLanguage.
- `docs/paso_a_paso_windev.md`: instructivo extendido con pasos detallados desde la base de datos hasta las pruebas finales.
- `docs/webdev_page_code.wl`: código completo de eventos y procedimientos WLanguage para la página de autorización.

## Pasos recomendados
1. Verifica que la base `joso` exista (si necesitas otra base, sustituye `USE joso;` en los scripts).
2. Ejecuta `sql/00_prerequisites.sql` para habilitar nulos y defaults requeridos.
3. Ejecuta `sql/20_usp_autorizar_pago_registrar.sql` al menos una vez para asegurarte de que el procedimiento legado se elimina; la lógica ahora vive en la capa de aplicación.
4. Integra las consultas de `sql/10_lookup_queries.sql` dentro de los eventos de la ventana/pagina WebDev.
5. Sigue el flujo descrito en `docs/wlanguage_flow.md` para enlazar controles, validaciones y mensajes.

## Notas
- La actualización/inserción de pagos se controla desde WLanguage enviando sentencias `UPDATE` + `INSERT` dentro de una transacción.
- Cualquier error en la transaccion queda registrado en `cat.Errores` con un codigo `SQL-<Numero>-<Linea>` para facilitar el seguimiento.
- Antes de ejecutar en produccion, prueba en un ambiente de QA usando datos de ejemplo para validar que el mensaje dinamico y la tabla se refresquen correctamente.

## TODO
- [x] Migrar la lógica de pagos a la capa de aplicación (SQL + WLanguage).
- [x] Actualizar la documentación relacionada.
- [ ] Probar la transacción manual con escenarios de concurrencia (dos usuarios intentando registrar el mismo pago).
- [ ] Validar que el registro en `cat.Errores` capture excepciones cuando falle la transacción enviada desde la aplicación.
- [ ] Documentar un plan de pruebas automatizadas para la lógica de actualización desde WLanguage.
