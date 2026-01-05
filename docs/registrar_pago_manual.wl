// ================================================================
// WLanguage: RegistrarPagoAutorizacion
// ------------------------------------------------
// Secuencia completa para actualizar el pago activo (dBaja NULL)
// y crear un nuevo registro con dBaja = NULL y dAlta = fecha actual.
// ================================================================

// Requisitos previos (ajusta los nombres si tu proyecto usa otros):
// - gclConexion      : Connection ya abierta contra SQL Server.
// - gnPersonaIDSeleccionada : Persona seleccionada (nPersonaID).
// - gnUsuarioSesion  : Usuario que modifica (nPersonaIDModifica).
// - EDT_NumSocio     : Control con el número de socio capturado (puede ser vacío).
// - EDT_Monto        : Control con el monto a registrar.
// Las tres columnas clave de coop.Autorizacion_Pago (nPersonaID, nNumSocio,
// nPersonaIDModifica) ya están disponibles en variables globales o controles.

PROCEDURE RegistrarPagoAutorizacion()
// Validaciones básicas
IF gnPersonaIDSeleccionada <= 0 THEN
    Error("Seleccione una persona válida antes de guardar.")
    RETURN False
END

IF EDT_Monto <= 0 THEN
    Error("Capture un monto mayor a 0.")
    RETURN False
END

IF gclConexion = Null THEN
    Error("La conexión SQL no está inicializada.")
    RETURN False
END

// Normalizar número de socio (usar 0 cuando no aplique)
LOCAL nNumSocioNormalizado is int = EDT_NumSocio
IF nNumSocioNormalizado <= 0 THEN nNumSocioNormalizado = 0

// Fecha de trabajo (hoy) expresada en formato WLanguage (YYYYMMDD)
LOCAL dHoy is Date = DateSys()

// Data Source temporal para ejecutar la transacción
LOCAL dsTransaccion is Data Source

// Sentencia: cierra el pago actual (dBaja NULL) y crea el nuevo registro
// Todo ocurre dentro de una transacción SQL para garantizar atomicidad.
LOCAL cTransaccion is ANSI string = [
    BEGIN TRY
        BEGIN TRAN;

        -- Paso 1: colocar fecha de hoy a cualquier pago activo de la persona
        UPDATE coop.Autorizacion_Pago
        SET dBaja = %3,
            nPersonaIDModifica = %2
        WHERE nPersonaID = %1
          AND dBaja IS NULL;

        -- Paso 2: insertar el nuevo pago con dBaja = NULL y dAlta = hoy
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
            %4,
            %5,
            NULL,
            %3,
            %2
        );

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH;
]

// Ejecutar la transacción con parámetros (persona, usuario, fecha, socio, monto)
IF NOT HExecuteSQLQuery(dsTransaccion, gclConexion, hQueryWithoutCorrection, cTransaccion,
    gnPersonaIDSeleccionada,
        gnUsuarioSesion,
        dHoy,
        nNumSocioNormalizado,
        EDT_Monto) THEN
    Error("No se pudo registrar el pago. Revise cat.Errores para más detalle.", HErrorInfo(hErrMessage))
    RETURN False
END

Info("Pago registrado correctamente.")
RETURN True
