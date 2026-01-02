# Flujo WebDev - Autorizacion de Pagos

## Controles involucrados
- `EST_Busqueda`: campo de entrada para buscar personas. Dispara la consulta al presionar Enter.
- `TABLE_Personas`: tabla ya poblada con Numero de Socio, Nombre y PersonaID.
- `STC_Mensaje`: etiqueta que muestra el mensaje dinamico.
- `EDT_NumSocio`: editable que mostrara el numero de socio (usar 0 cuando la persona no tenga).
- `EDT_Monto`: editable para capturar el monto.
- `BTN_Guardar`: boton para confirmar el registro.
- `BTN_Limpiar`: boton para limpiar controles y estado.

## Variables recomendadas
```wlanguage
nPersonaIDSeleccionada is int = 0
nUsuarioSesion is int // asignar al iniciar sesion
```

## Pseudocodigo de eventos
### 1. EST_Busqueda / EDT_Buscar (tecla Enter) y TableRowSelection
#### 1.1 Ejecutar motor de búsqueda
```wlanguage
// Permite buscar por numero de socio o por coincidencias en el nombre completo.
cBusqueda is string = EDT_Buscar

qsBusqueda is ANSI string = [
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

IF NOT HExecuteSQLQuery(dsPersonas, hQueryWithoutCorrection, qsBusqueda, cBusqueda) THEN
    Error("No fue posible obtener los socios. Consulte cat.Errores si persiste.")
    RETURN
END

TableDisplay(TABLE_Personas, taInit)
TableSelectPlus(TABLE_Personas, 0)
```

#### 1.2 Seleccionar una fila y cargar datos
```wlanguage
nPersonaIDSeleccionada = TABLE_Personas.PersonaID
IF nPersonaIDSeleccionada = 0 THEN RETURN

// Ejecutar sql/10_lookup_queries.sql (primer bloque) para mensaje y numero de socio
HExecuteSQLQuery(dsLabel, hQueryWithoutCorrection, \
    "EXEC sp_executesql N'SELECT ...', N'@nPersonaID BIGINT', %1", nPersonaIDSeleccionada)

IF HNbRec(dsLabel) = 1 THEN
    STC_Mensaje = dsLabel.MensajeLabel
    EDT_NumSocio = dsLabel.NumSocioSugerido
ELSE
    STC_Mensaje = "Esta persona no tiene pagos. ¿Desea registrar uno nuevo?"
    EDT_NumSocio = 0
END

// Ejecutar el segundo bloque de sql/10_lookup_queries.sql para llenar TABLE_Pagos
```

### 2. BTN_Guardar
```wlanguage
IF nPersonaIDSeleccionada = 0 THEN
    Error("Seleccione una persona antes de guardar.")
    RETURN
END
IF EDT_Monto <= 0 THEN
    Error("Capture un monto valido.")
    RETURN
END

IF YesNo("¿Esta seguro de querer registrar el pago?") = No THEN RETURN

// Ejecutar sql/20_usp_autorizar_pago_registrar.sql mediante HExecuteSQLQuery
qs is ANSI string = [
    EXEC coop.usp_AutorizarPagoRegistrar 
        @nPersonaID = %1,
        @nNumSocio = %2,
        @mMonto = %3,
        @nPersonaIDModifica = %4
]

IF NOT HExecuteSQLQuery(dsResultado, hQueryWithoutCorrection, qs, \
        nPersonaIDSeleccionada, EDT_NumSocio, EDT_Monto, nUsuarioSesion) THEN
    Error("Ocurrio un error. Favor de notificar a los desarrolladores. Revisar tabla cat.Errores.")
    RETURN
END

Info("Pago registrado correctamente.")

// Refrescar mensaje y tabla usando las consultas de sql/10_lookup_queries.sql
```

### 3. BTN_Limpiar
```wlanguage
TableDeleteAll(TABLE_Pagos)
EDT_Busqueda = ""
EDT_Monto = 0
EDT_NumSocio = 0
nPersonaIDSeleccionada = 0
STC_Mensaje = "Capture un criterio de busqueda"
TableSelectPlus(TABLE_Personas, 0)
```

## Manejo de errores
- Cada excepcion SQL queda registrada en `cat.Errores` con el codigo `SQL-<ErrorNumber>-<Linea>`.
- Mostrar siempre una leyenda al usuario indicando que notifique al area de desarrollo en caso de error.
- Para diagnostico, consultar `cat.Errores` ordenando por `nErrorID` descendente.
