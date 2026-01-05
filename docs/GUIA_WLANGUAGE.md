# Guia de uso de WLanguage para WebDev

## 1. Contexto general
- **WinDev/WebDev** proporcionan un analisis (modelado de datos) que define tablas, campos y relaciones. WLanguage opera sobre ese analisis a traves de las funciones `Hxx` (HFSQL) y de metodos de los objetos de pagina/proyecto.
- Las funciones de base de datos siguen el patron `HAccion` (ejemplo `HAdd`, `HModify`, `HDelete`). Las consultas y navegacion usan `HRead...`, `HExecuteQuery` y las funciones de iteracion como `HNext`.
- Los proyectos WebDev cargan automaticamente la conexion definida en el analisis. No es necesario abrir una conexion manualmente, pero se puede usar `HConnect` para conexiones adicionales.

## 2. Operaciones CRUD paso a paso

### 2.1 Preparar los registros
```wlanguage
// Definir un registro en memoria basado en la descripcion de la tabla Clientes
sCliente es Cliente // Estructura generada por el analisis
sCliente.IDCliente = 0
sCliente.Nombre = "Juan Perez"
sCliente.Correo = "juan.perez@ejemplo.com"
sCliente.FechaAlta = DateSys()
```
- Las estructuras como `Cliente` se crean automaticamente por el analisis. Use el autocompletado para ver sus campos.
- Cuando se usa un formulario, asigne los valores de los campos de la pagina directamente al registro antes de grabar.

### 2.2 Insertar (grabar) registros con `HAdd`
```wlanguage
HTransactionStart(hTransactionDefault)
SI HAdd(Cliente, sCliente) ENTONCES
    Info("Registro insertado correctamente")
    HTransactionEnd(hTransactionCommit)
SINO
    Error(HErrorInfo(hErrFullDetails))
    HTransactionEnd(hTransactionRollback)
FIN
```
- `HAdd` inserta el registro en la tabla indicada. Usa las claves definidas en el analisis (autonumerico, UUID, etc.).
- Rodear la insercion con una transaccion evita registros parciales si ocurre un error.

### 2.3 Modificar registros con `HModify`
```wlanguage
// Cargar registro existente por su clave primaria
SI HReadSeekFirst(Cliente, IDCliente, gnIDSeleccionado) ENTONCES
    Cliente.Nombre = EDT_Nombre
    Cliente.Correo = EDT_Correo

    HTransactionStart(hTransactionDefault)
    SI HModify(Cliente) ENTONCES
        HTransactionEnd(hTransactionCommit)
        Info("Registro actualizado")
    SINO
        HTransactionEnd(hTransactionRollback)
        Error(HErrorInfo(hErrFullDetails))
    FIN
SINO
    Error("No se encontro el registro solicitado")
FIN
```
- `HReadSeekFirst` localiza el primer registro que coincide con la clave dada.
- Una vez cargado el registro, se actualiza campo por campo y se llama a `HModify` sin parametros extra.

### 2.4 Eliminar registros con `HDelete`
```wlanguage
SI HReadSeekFirst(Cliente, IDCliente, gnIDSeleccionado) ENTONCES
    SI Confirm("Eliminar registro?", "Si", "No") = Yes ENTONCES
        SI HDelete(Cliente) ENTONCES
            Info("Registro eliminado")
        SINO
            Error(HErrorInfo(hErrFullDetails))
        FIN
    FIN
SINO
    Error("Registro no encontrado")
FIN
```
- Confirme con el usuario antes de eliminar registros.
- `HDelete` usa el registro actualmente cargado en memoria.

## 3. Metodos de consulta (SELECT)

### 3.1 Lectura secuencial con `HReadFirst` / `HNext`
```wlanguage
HReadFirst(Cliente)
MIENTRAS NO HOut()
    Trace(Cliente.IDCliente + ": " + Cliente.Nombre)
    HNext(Cliente)
FIN
```
- `HReadFirst` posiciona el cursor al primer registro de la tabla (segun el indice principal).
- `HNext` avanza al siguiente registro. `HOut()` indica si se alcanzo el final.

### 3.2 Busqueda por clave con `HReadSeekFirst`
```wlanguage
SI HReadSeekFirst(Cliente, Correo, "juan.perez@ejemplo.com") ENTONCES
    Info("Cliente encontrado: " + Cliente.Nombre)
SINO
    Info("No existe un cliente con ese correo")
FIN
```
- El segundo parametro es el nombre del indice declarado en el analisis (`Correo`).

### 3.3 Consultas complejas con `HExecuteQuery`
1. Diseñe la consulta en el editor (Query Editor) para generar un objeto `QRY_ClientesActivos`.
2. Ejecute la consulta desde codigo:
```wlanguage
SI HExecuteQuery(QRY_ClientesActivos) ENTONCES
    HReadFirst(QRY_ClientesActivos)
    MIENTRAS NO HOut()
        Trace(QRY_ClientesActivos.Nombre + " - " + QRY_ClientesActivos.Ciudad)
        HNext(QRY_ClientesActivos)
    FIN
SINO
    Error(HErrorInfo(hErrFullDetails))
FIN
```
- La consulta puede recibir parametros (`MyQuery.Parametro = valor`) antes de `HExecuteQuery`.

### 3.4 Consulta SQL dinamica con `HExecuteSQLQuery`
```wlanguage
cSQL es string = "SELECT Nombre, Correo FROM Cliente WHERE FechaAlta >= {fechaInicio}"
SI HExecuteSQLQuery(QRY_Resultado, hQueryDefault, cSQL, fechaInicio) ENTONCES
    HReadFirst(QRY_Resultado)
    MIENTRAS NO HOut()
        Trace(QRY_Resultado.Nombre + " - " + QRY_Resultado.Correo)
        HNext(QRY_Resultado)
    FIN
SINO
    Error(HErrorInfo(hErrFullDetails))
FIN
```
- Use parametros `{}` para evitar inyeccion SQL. Los valores se pasan despues de la cadena.
- `QRY_Resultado` es una consulta libre (loopback) definida en el analisis o declarada como `Data Source`.

## 4. Inserciones adicionales (tablas del analisis)
- Cada tabla definida en el analisis genera una estructura de registro y constantes para indices.
- Para insertar en una tabla relacionada (ej. `FacturaDetalle`) primero inserte la cabecera (`Factura`) para obtener su clave.
```wlanguage
HTransactionStart(hTransactionDefault)
SI HAdd(FacturaCabecera, sCabecera) ENTONCES
    nIDFactura es int = FacturaCabecera.IDFactura
    PARA CADA sLinea DE arrLineas
        FacturaDetalle.IDFactura = nIDFactura
        FacturaDetalle.IDProducto = sLinea.IDProducto
        FacturaDetalle.Cantidad = sLinea.Cantidad
        FacturaDetalle.PrecioUnitario = sLinea.Precio
        SI NO HAdd(FacturaDetalle) ENTONCES
            HTransactionEnd(hTransactionRollback)
            Error("Error al insertar detalle: " + HErrorInfo(hErrFullDetails))
            REGRESA
        FIN
    FIN
    HTransactionEnd(hTransactionCommit)
SINO
    HTransactionEnd(hTransactionRollback)
    Error("No se pudo insertar la cabecera: " + HErrorInfo(hErrFullDetails))
FIN
```
- Mantenga toda la operacion en una transaccion para asegurar consistencia.

## 5. Actualizacion mediante formularios de WebDev
- Vincule los controles de la pagina con los campos de la tabla usando el asistente de pagina.
- Para guardar desde un boton:
```wlanguage
PROCEDURE BTN_Guardar_OnClick()
PageToFile(Cliente) // Copia los valores de la pagina al buffer Cliente
SI EDT_IDCliente = 0 ENTONCES
    Resultado es boolean = HAdd(Cliente)
SINO
    Resultado es boolean = HModify(Cliente)
FIN
SI Resultado ENTONCES
    Info("Cambios guardados")
SINO
    Error(HErrorInfo(hErrFullDetails))
FIN
```
- `PageToFile` y `FileToPage` sincronizan automaticamente los controles con el buffer de datos.

## 6. Manejo de errores y diagnostico
- `HErrorInfo(hErrFullDetails)` devuelve un mensaje completo del ultimo error. Use `Trace` en desarrollo.
- Active el log con `HErrorMode(Exception)` para interceptar fallos en tiempo de ejecucion.
- Registre excepciones personalizadas:
```wlanguage
TRY
    HAdd(Cliente)
CATCH e:Exception
    Error("Excepcion: " + e.Message)
END
```

## 7. Metodos comunes en WebDev/WLanguage
- `FileToPage()` / `PageToFile()`: sincronizan datos entre buffers y pagina.
- `HReset(<Archivo>)`: limpia el buffer antes de asignar valores.
- `HFilter()`: aplica filtros en memoria a un archivo o consulta.
- `TableAddLine()` / `TableModifyLine()`: actualizan controles tabla en la interfaz.
- `HBuildKeyValue()` y `HSeek()` ayudan a navegar por indices compuestos.
- `HNbRec()` devuelve el numero de registros en un archivo o resultado de consulta.

## 8. Buenas practicas
- Centralice funciones de acceso a datos en procedimientos globales para reutilizarlas.
- Valide datos antes de llamar a `HAdd` o `HModify`.
- Use constantes y enumeraciones generadas por el analisis para evitar valores "magicos".
- Documente cada procedimiento con comentarios (``PROCEDURE MiMetodo()`` seguido de descripcion).
- Pruebe consultas SQL parametrizadas en el editor antes de integrarlas al codigo.

## 9. Recursos adicionales
- Documentacion oficial: [https://doc.windev.com](https://doc.windev.com)
- Tutorial interactivo WebDev: modulos "Manipulacion de archivos de datos" y "Consultas".
- Foros de PC Soft: ejemplos practicos compartidos por la comunidad.
