# Guia paso a paso para la pestaña de Autorizacion de Pagos

Esta guia complementa `docs/wlanguage_flow.md` y describe el proceso completo que debes seguir en WinDev/WebDev, desde la base de datos hasta las pruebas finales.

## 1. Preparar la base de datos
1. Abre SQL Server Management Studio (SSMS) y selecciona la base que contiene `coop.Autorizacion_Pago`.
2. Ejecuta `sql/00_prerequisites.sql` (ya apunta a la base `joso`; solo cambia el `USE` si trabajas en otra base).
   - Verifica en el explorador de objetos que `coop.Autorizacion_Pago.dBaja` acepta valores nulos.
   - Confirma que existe el `DEFAULT` en `dAlta` consultando `sys.default_constraints` o inspeccionando la columna.
3. Ejecuta `sql/20_usp_autorizar_pago_registrar.sql` para crear el procedimiento almacenado.
4. Opcional: ejecuta consultas de `sql/10_lookup_queries.sql` para validar que retornan datos correctos para una persona real.
5. Si necesitas una version resumida, practica primero con `sql/12_basic_queries.sql` (solo SELECT/INSERT) y luego migra al procedimiento completo.

## 2. Configurar la conexion en WinDev/WebDev
1. En el editor, abre el panel *Analysis* o crea una nueva conexion en *HFSQL/External Databases*.
2. Define una conexion OLE DB / Native SQL Server con los parametros:
   - Servidor
   - Base de datos
   - Usuario/Password (o seguridad integrada)
3. Guarda la conexion como `cnPagosSQL` (o el nombre que prefieras) para reutilizarla.
4. Crea un *Data Source* (`dsLabel`, `dsHistorial`, etc.) apuntando a la conexion externa para ejecutar tus queries.

## 3. Diseñar la pagina/ventana
1. Agrega los controles descritos en `docs/wlanguage_flow.md` (`EST_Busqueda`, `TABLE_Personas`, `TABLE_Pagos`, `STC_Mensaje`, `EDT_NumSocio`, `EDT_Monto`, `BTN_Guardar`, `BTN_Limpiar`).
2. Inserta una variable de clase o global `nPersonaIDSeleccionada` para recordar el registro activo.
3. En `TABLE_Personas`, asegúrate de tener columnas `NumSocio`, `Nombre`, `PersonaID` ya cargadas con tu consulta de búsqueda existente.

## 4. Programar los eventos
1. **Evento Enter de `EST_Busqueda` / selección de fila**
   - Ejecuta el bloque 0 de `sql/10_lookup_queries.sql` enviando el contenido de `EDT_Buscar` para obtener `nNoSocio`, `Clave` y `NombreCompleto`.
   - Refresca `TABLE_Personas` con los resultados (limpia la selección previa).
   - Cuando el usuario selecciona una fila, asigna `nPersonaIDSeleccionada`.
   - Ejecuta el primer bloque de `sql/10_lookup_queries.sql` con `HExecuteSQLQuery` para actualizar `STC_Mensaje` y `EDT_NumSocio`.
   - Ejecuta el segundo bloque para rellenar `TABLE_Pagos` con el historial.
2. **Evento clic de `BTN_Guardar`**
   - Valida que `nPersonaIDSeleccionada` > 0 y que `EDT_Monto` > 0.
   - Usa `YesNo` para confirmar la operacion.
   - Construye la llamada al procedimiento: 
     ```wlanguage
     HExecuteSQLQuery(dsResultado, hQueryWithoutCorrection, \
         "EXEC coop.usp_AutorizarPagoRegistrar @nPersonaID=%1, @nNumSocio=%2, @mMonto=%3, @nPersonaIDModifica=%4", \
         nPersonaIDSeleccionada, EDT_NumSocio, EDT_Monto, gnUsuarioSesion)
     ```
   - Si hay error, muestra `Error()` y refiere a `cat.Errores`.
   - Si es exitoso, refresca mensaje/historial ejecutando nuevamente las consultas de apoyo.
3. **Evento clic de `BTN_Limpiar`**
   - Limpia tablas, controles y variable `nPersonaIDSeleccionada` como se detalla en `wlanguage_flow.md`.

## 5. Pruebas sugeridas
1. Caso sin pagos previos: busca una persona nueva, verifica que el label muestre el mensaje "no tiene pagos" y guarda un registro.
2. Caso con pago activo: repite el guardado y confirma que el registro anterior recibe fecha en `dBaja` y que el nuevo queda con `dBaja = NULL`.
3. Caso con error: simula una falla (por ejemplo, desconectar la red) y verifica que `cat.Errores` reciba un registro y que el mensaje mostrado al usuario sea el esperado.
4. Verifica que el boton limpiar restaura los controles.

## 6. Buenas practicas
- Asegura que `gnUsuarioSesion` contenga el ID de la persona logueada para completar `nPersonaIDModifica`.
- Centraliza los mensajes en constantes o recursos si necesitas soporte multi-idioma.
- Considera encapsular las ejecuciones SQL en procedimientos WLanguage reutilizables para mantener el codigo de la ventana mas limpio.

Con estos pasos deberias poder replicar el comportamiento completo y entender que parte corresponde a SQL y cual a la capa de interfaz.
