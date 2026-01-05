// ================================================================
// Página WebDev: PAG_AutorizacionPagos
// Detalle completo de los fragmentos WLanguage solicitados.
// ================================================================

// ----------------------------------------------------------------
// 1. Declaraciones globales de la página
// ----------------------------------------------------------------
GLOBAL
    // Conexión a SQL Server (base joso)
    gclConexion is Connection

    // Identificador del usuario conectado (asignar en la lógica de login)
    gnUsuarioSesion is int = 0

    // Persona seleccionada en la tabla
    gnPersonaIDSeleccionada is int = 0

    // Data sources usados para consultas dinámicas (SQL embebido)
    dsPersonas is Data Source
    dsLabel is Data Source
    dsPagos is Data Source
    dsGuardar is Data Source

    // Referencias a consultas creadas con el editor (opcional)
    qryBuscarSocios is Query  // requiere parámetro ParamTextoBusqueda (tipo string)
    qryEstadoPersona is Query // requiere parámetro ParamPersonaID (tipo int)
    qryHistorialPagos is Query // parámetro ParamPersonaID
END

// ----------------------------------------------------------------
// 2. Procedimientos auxiliares
// ----------------------------------------------------------------
PROCEDURE AbrirConexionSQL()
IF gclConexion = Null THEN gclConexion = Connection

// Ajusta los valores a tu servidor/instancia
gclConexion..Provider = hNativeSQLServer
gclConexion..Server = "SERVIDOR\\INSTANCIA"  // ejemplo: "DESKTOP\\SQLEXPRESS"
gclConexion..Database = "joso"
gclConexion..User = "usuario_sql"            // usa autenticación integrada si aplica
gclConexion..Password = "password_seguro"

IF NOT HOpenConnection(gclConexion) THEN
    Error("No se pudo abrir la conexión a SQL Server:", HErrorInfo(hErrMessage))
    RETURN False
END

// Vincula los data sources a la conexión
FOR EACH oDS OF [dsPersonas, dsLabel, dsPagos, dsGuardar]
    oDS..Connection = gclConexion
END

RESULT True

// ---------------------------------------------------------------
// 2.1. Procedimientos usando SQL embebido
// ---------------------------------------------------------------
PROCEDURE EjecutarBusquedaPersonas(cFiltro is string)
LOCAL cSQL is ANSI string = [
    DECLARE @TextoBusqueda NVARCHAR(120) = %1;
    DECLARE @NumeroSocio BIGINT = TRY_CONVERT(BIGINT, NULLIF(@TextoBusqueda, N''));
    SELECT TOP (200)
        s.nNoSocio,
        ISNULL(NULLIF(s.sClave, ''), 'SIN CLAVE') AS ClaveSocio,
        p.nPersonaID,
        LTRIM(RTRIM(CONCAT(p.sApellido1, ' ', ISNULL(p.sApellido2, ''), ' ', p.sNombres))) AS NombreCompleto
    FROM soc.Socio s
    INNER JOIN per.Persona p ON p.nPersonaID = s.nPersonaID
    WHERE (
        @TextoBusqueda = N''
        OR (
            (@NumeroSocio IS NOT NULL AND s.nNoSocio = @NumeroSocio)
            OR p.sApellido1 LIKE '%' + @TextoBusqueda + '%'
            OR p.sApellido2 LIKE '%' + @TextoBusqueda + '%'
            OR p.sNombres LIKE '%' + @TextoBusqueda + '%'
            OR LTRIM(RTRIM(CONCAT(p.sApellido1, ' ', ISNULL(p.sApellido2, ''), ' ', p.sNombres))) LIKE '%' + @TextoBusqueda + '%'
        )
    )
    ORDER BY s.nNoSocio DESC, NombreCompleto;
]

IF NOT HExecuteSQLQuery(dsPersonas, gclConexion, hQueryWithoutCorrection, cSQL, cFiltro) THEN
    Error("No se pudo ejecutar la búsqueda:", HErrorInfo(hErrMessage))
    RESULT False
END

TABLE_Personas..Source = dsPersonas
TableDisplay(TABLE_Personas, taInit)
TableSelectPlus(TABLE_Personas, 0)
RESULT True

// ---------------------------------------------------------------
PROCEDURE ActualizarContextoPersona()
IF gnPersonaIDSeleccionada = 0 THEN RETURN

LOCAL cLabelSQL is ANSI string = [
    SELECT 
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM coop.Autorizacion_Pago
                WHERE nPersonaID = %1
                  AND dBaja IS NULL
            ) THEN 'La persona ya cuenta con un pago vigente. ¿Registrar uno nuevo?'
            WHEN EXISTS (
                SELECT 1 FROM coop.Autorizacion_Pago
                WHERE nPersonaID = %1
            ) THEN 'La persona tiene pagos históricos. Se dará de alta uno nuevo.'
            ELSE 'Esta persona no tiene pagos. ¿Desea registrar uno nuevo?'
        END AS MensajeLabel,
        ISNULL(NULLIF(MAX(nNumSocio),0),0) AS NumSocioSugerido
    FROM coop.Autorizacion_Pago
    WHERE nPersonaID = %1;
]

IF NOT HExecuteSQLQuery(dsLabel, gclConexion, hQueryWithoutCorrection, cLabelSQL, gnPersonaIDSeleccionada) THEN
    Error("Error al obtener el mensaje:", HErrorInfo(hErrMessage))
    RETURN
END

IF HNbRec(dsLabel) = 1 THEN
    STC_Mensaje = dsLabel.MensajeLabel
    EDT_NumSocio = dsLabel.NumSocioSugerido
ELSE
    STC_Mensaje = "Esta persona no tiene pagos. ¿Desea registrar uno nuevo?"
    EDT_NumSocio = 0
END

LOCAL cHistorialSQL is ANSI string = [
    SELECT 
        nAutorizarPagoID,
        nPersonaID,
        nNumSocio,
        mMonto,
        dAlta,
        dBaja,
        CASE WHEN dBaja IS NULL THEN 'ACTIVO' ELSE 'HISTORICO' END AS Estatus
    FROM coop.Autorizacion_Pago
    WHERE nPersonaID = %1
    ORDER BY dAlta DESC, nAutorizarPagoID DESC;
]

IF NOT HExecuteSQLQuery(dsPagos, gclConexion, hQueryWithoutCorrection, cHistorialSQL, gnPersonaIDSeleccionada) THEN
    Error("No se pudo cargar el historial de pagos:", HErrorInfo(hErrMessage))
    RETURN
END

TABLE_Pagos..Source = dsPagos
TableDisplay(TABLE_Pagos, taInit)

// ---------------------------------------------------------------
// 2.2. Procedimientos usando consultas diseñadas (opcional)
// ---------------------------------------------------------------
PROCEDURE EjecutarBusquedaPersonas_Query(cFiltro is string)
qryBuscarSocios.ParamTextoBusqueda = cFiltro
IF NOT HExecuteQuery(qryBuscarSocios, hQueryDefault) THEN
    Error("No se pudo ejecutar qryBuscarSocios:", HErrorInfo(hErrMessage))
    RESULT False
END

TABLE_Personas..Source = qryBuscarSocios
TableDisplay(TABLE_Personas, taInit)
TableSelectPlus(TABLE_Personas, 0)
RESULT True

// ---------------------------------------------------------------
PROCEDURE ActualizarContextoPersona_Query()
IF gnPersonaIDSeleccionada = 0 THEN RETURN

qryEstadoPersona.ParamPersonaID = gnPersonaIDSeleccionada
IF NOT HExecuteQuery(qryEstadoPersona, hQueryDefault) THEN
    Error("Error al ejecutar qryEstadoPersona:", HErrorInfo(hErrMessage))
    RETURN
END

IF HNbRec(qryEstadoPersona) = 1 THEN
    STC_Mensaje = qryEstadoPersona.MensajeLabel
    EDT_NumSocio = qryEstadoPersona.NumSocioSugerido
ELSE
    STC_Mensaje = "Esta persona no tiene pagos. ¿Desea registrar uno nuevo?"
    EDT_NumSocio = 0
END

qryHistorialPagos.ParamPersonaID = gnPersonaIDSeleccionada
IF NOT HExecuteQuery(qryHistorialPagos, hQueryDefault) THEN
    Error("Error al ejecutar qryHistorialPagos:", HErrorInfo(hErrMessage))
    RETURN
END

TABLE_Pagos..Source = qryHistorialPagos
TableDisplay(TABLE_Pagos, taInit)

// ---------------------------------------------------------------
PROCEDURE LimpiarPantalla()
EDT_Buscar = ""
EDT_NumSocio = 0
EDT_Monto = 0
STC_Mensaje = "Capture un criterio de busqueda"
TableDeleteAll(TABLE_Personas)
TableDeleteAll(TABLE_Pagos)
TableSelectPlus(TABLE_Personas, 0)
TableSelectPlus(TABLE_Pagos, 0)

gnPersonaIDSeleccionada = 0

// ---------------------------------------------------------------
PROCEDURE RegistrarPagoManual(nPersonaID is int, nNumSocio is int, mMonto is currency)
IF nPersonaID <= 0 THEN RESULT False

LOCAL nNumSocioNormalizado is int = nNumSocio
IF nNumSocioNormalizado <= 0 THEN nNumSocioNormalizado = 0

LOCAL cTransaccionSQL is ANSI string = [
    BEGIN TRY
        BEGIN TRAN;

        UPDATE coop.Autorizacion_Pago
        SET dBaja = CAST(GETDATE() AS DATE),
            nPersonaIDModifica = %2
        WHERE nPersonaID = %1
          AND dBaja IS NULL;

        INSERT INTO coop.Autorizacion_Pago
        (
            nPersonaID,
            nNumSocio,
            mMonto,
            dBaja,
            dAlta,
            nPersonaIDModifica
        )
        VALUES
        (
            %1,
            %3,
            %4,
            NULL,
            CAST(GETDATE() AS DATE),
            %2
        );

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH;
]

IF NOT HExecuteSQLQuery(dsGuardar, gclConexion, hQueryWithoutCorrection, cTransaccionSQL, \
        nPersonaID, gnUsuarioSesion, nNumSocioNormalizado, mMonto) THEN
    Error("Ocurrió un error al registrar el pago. Consulta cat.Errores para más detalle.", HErrorInfo(hErrMessage))
    RESULT False
END

RESULT True

// ----------------------------------------------------------------
// 3. Eventos de la página/control (copiar-pegar directamente en WebDev)
// ----------------------------------------------------------------

// ===============================================================
// Evento: Página -> Initialization
// ===============================================================
IF NOT AbrirConexionSQL() THEN RETURN

// Asignar el usuario activo (reemplaza con tu lógica real)
IF gnUsuarioSesion = 0 THEN
    gnUsuarioSesion = PageParameter(1) // ejemplo: id que llega en el parámetro 1
END

LimpiarPantalla()

// ===============================================================
// Evento: EDT_Buscar -> Exit (validación con Enter) o Botón Buscar
// ===============================================================
IF NOT EjecutarBusquedaPersonas(EDT_Buscar) THEN RETURN
// Si deseas usar la query visual, comenta la línea anterior y descomenta:
// IF NOT EjecutarBusquedaPersonas_Query(EDT_Buscar) THEN RETURN

IF TableCount(TABLE_Personas) = 0 THEN
    STC_Mensaje = "No se encontraron registros con ese criterio."
END

// ===============================================================
// Evento: TABLE_Personas -> Row selection
// ===============================================================
IF TABLE_Personas..Occurrence = 0 THEN RETURN

gnPersonaIDSeleccionada = TABLE_Personas.PersonaID
EDT_NumSocio = TABLE_Personas.nNoSocio

ActualizarContextoPersona()
// O bien: ActualizarContextoPersona_Query()

// ===============================================================
// Evento: BTN_Guardar -> Click
// ===============================================================
IF gnPersonaIDSeleccionada = 0 THEN
    Error("Seleccione una persona antes de guardar.")
    RETURN
END

IF EDT_Monto <= 0 THEN
    Error("Capture un monto mayor a 0.")
    RETURN
END

IF YesNo("¿Está seguro de registrar el pago?") = No THEN RETURN

IF NOT RegistrarPagoManual(gnPersonaIDSeleccionada, EDT_NumSocio, EDT_Monto) THEN RETURN

Info("Pago registrado correctamente.")
ActualizarContextoPersona()

// ===============================================================
// Evento: BTN_Limpiar (Cancelar) -> Click
// ===============================================================
LimpiarPantalla()

// ----------------------------------------------------------------
// 4. Conectar las consultas creadas en el editor de WinDev
// ----------------------------------------------------------------
// En el editor de queries crea los siguientes objetos con los parámetros indicados:
//  - qryBuscarSocios (param: ParamTextoBusqueda, tipo string)
//  - qryEstadoPersona (param: ParamPersonaID, tipo int)
//  - qryHistorialPagos (param: ParamPersonaID, tipo int)
// Cada query debe usar la conexión gclConexion (configúrala en la Analysis).
// Si optas por las queries visuales, utiliza las funciones *_Query() en lugar de las que ejecutan SQL embebido.

// ----------------------------------------------------------------
// 5. Estructura recomendada de las tablas en la página
// ----------------------------------------------------------------
// TABLE_Personas:
//  - Columna 1: nNoSocio (tipo numérico, enlazar a dsPersonas.nNoSocio)
//  - Columna 2: ClaveSocio (texto)
//  - Columna 3: NombreCompleto (texto)
//  - Columna oculta: PersonaID (numérico) para asignar gnPersonaIDSeleccionada
// TABLE_Pagos:
//  - nAutorizarPagoID, mMonto, dAlta, dBaja, Estatus (texto calculado)
//  - Marca como “solo lectura” para evitar ediciones directas.
