# Procedimiento "Prototipo" 


## Requisitos previos
- El análisis define la tabla `Autorizacion_Pago1` con los campos: `nAutorizarPagoID`, `nPersonaID`, `nNumSocio`, `mMonto`, `dAlta`, `dBaja`, `nPersonaIDModifica`, `dRegistro`.
- Campo `dBaja` configurado para aceptar valores nulos.
- Página con campos de entrada: `EDT_PersonaID`, `EDT_Monto_Autorizado`, `EDT_PersonaIDModifica` y un control estático `STC_Mensaje`.
- Conexión ya abierta al iniciar el proyecto.

## Código del procedimiento servidor
```wlanguage
PROCEDURE Prototipo()

// --- Captura de datos desde la página ---
IF PageParameter(PageParameterCount()) = "AJAX" THEN
    // El procedimiento se invoca mediante un botón AJAX
END

nIDPersona  is int      = EDT_PersonaID
nMonto      is currency = EDT_Monto_Autorizado
nIDModif    is int      = EDT_PersonaIDModifica

IF nIDPersona = 0 OR nMonto <= 0 THEN
    RESULT PrototipoResultado(False, "Datos incompletos.")
END

// --- Inicio de transacción ---
HTransactionStart(hTransactionDefault)

// --- Paso 1: desactivar filtros anteriores ---
HDeactivateFilter(Autorizacion_Pago1)

// --- Paso 2: localizar registro activo de la persona ---
sCondition is string = StringBuild("nPersonaID = %1 AND dBaja IS NULL", nIDPersona)
HFilter(Autorizacion_Pago1, sCondition)
HReadFirst(Autorizacion_Pago1)

// --- Paso 3: cerrar registro activo si existe ---
IF NOT HOut(Autorizacion_Pago1) THEN
    Autorizacion_Pago1.dBaja = DateSys()
    IF NOT HModify(Autorizacion_Pago1) THEN
        HTransactionEnd(hTransactionRollback)
        RESULT PrototipoResultado(False, HErrorInfo(hErrFullDetails))
    END
END

// --- Paso 4: limpiar contexto para nuevo registro ---
HDeactivateFilter(Autorizacion_Pago1)
HReset(Autorizacion_Pago1)

// --- Paso 5: preparar nuevo registro ---
Autorizacion_Pago1.nPersonaID           = nIDPersona
Autorizacion_Pago1.nNumSocio            = 0
Autorizacion_Pago1.mMonto               = nMonto
Autorizacion_Pago1.dAlta                = DateSys()
Autorizacion_Pago1.dBaja..Null          = True
Autorizacion_Pago1.nPersonaIDModifica   = nIDModif
Autorizacion_Pago1.dRegistro            = DateTimeSys()

// --- Paso 6: insertar ---
IF NOT HAdd(Autorizacion_Pago1) THEN
    HTransactionEnd(hTransactionRollback)
    RESULT PrototipoResultado(False, HErrorInfo(hErrFullDetails))
END

HTransactionEnd(hTransactionCommit)

RESULT PrototipoResultado(True, "Registro guardado. ID: " + Autorizacion_Pago1.nAutorizarPagoID)
```

## Función de retorno estructurado
```wlanguage
PROCEDURE PrototipoResultado(pbExito is boolean, psMensaje is string)
Resultado is Structure
    Exito   is boolean
    Mensaje is string
END
Resultado.Exito   = pbExito
Resultado.Mensaje = psMensaje
RESULT Resultado
```

## Integración en la página
1. Botón servidor con modo AJAX:
   - Código servidor: `tpResultado is PrototipoResultado = Prototipo()`.
   - Código navegador (post-back):
     ```wlanguage
     tpResultado is PrototipoResultado = AJAXExecuteResult()
     STC_Mensaje = tpResultado.Mensaje
     IF tpResultado.Exito THEN
         EDT_PersonaID = ""
         EDT_Monto_Autorizado = 0
         EDT_PersonaIDModifica = ""
         SetFocus(EDT_PersonaID)
     END
     ```
2. Si no se usa AJAX, el procedimiento puede invocarse desde el evento Page Init o un botón clásico; el mensaje se coloca en `STC_Mensaje` después de la llamada.


