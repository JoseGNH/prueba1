/*
    Consultas de apoyo para la página WebDev.
    Las secciones están pensadas para ejecutarse de forma independiente desde WinDev/WebDev.
*/

/*
    0. Motor de búsqueda para poblar TABLE_Personas a partir de EDT_Buscar/EST_Busqueda.
       - Busca por número de socio exacto o por coincidencia en el nombre completo.
       - Cuando el texto está vacío, devuelve todos los socios (limitar TOP según necesidad).
*/
DECLARE @TextoBusqueda NVARCHAR(120) = N''; -- reemplazar con el contenido de EDT_Buscar
DECLARE @NumeroSocio BIGINT = TRY_CONVERT(BIGINT, NULLIF(@TextoBusqueda, N''));

SELECT TOP (200)
    s.nNoSocio,
    ISNULL(NULLIF(s.sClave, ''), 'SIN CLAVE') AS ClaveSocio,
    p.nPersonaID,
    LTRIM(RTRIM(CONCAT(p.sApellido1, ' ', ISNULL(p.sApellido2, ''), ' ', p.sNombres))) AS NombreCompleto
FROM soc.Socio s
INNER JOIN per.Persona p ON p.nPersonaID = s.nPersonaID
WHERE
    (
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

/*
    Ajusta el valor de @nPersonaID antes de ejecutar los bloques siguientes.
*/
DECLARE @nPersonaID BIGINT = 0; -- asignar el ID seleccionado en la tabla de búsqueda

/*
    1. Mensaje dinámico para la etiqueta y sugerencia de número de socio.
*/
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM coop.Autorizacion_Pago
            WHERE nPersonaID = @nPersonaID
              AND dBaja IS NULL
        ) THEN 'La persona ya cuenta con un pago vigente. ¿Registrar uno nuevo?'
        WHEN EXISTS (
            SELECT 1 FROM coop.Autorizacion_Pago
            WHERE nPersonaID = @nPersonaID
        ) THEN 'La persona tiene pagos históricos. Se dará de alta uno nuevo.'
        ELSE 'Esta persona no tiene pagos. ¿Desea registrar uno nuevo?'
    END AS MensajeLabel,
    ISNULL(NULLIF(MAX(nNumSocio),0),0) AS NumSocioSugerido,
    COUNT(*) AS PagosRegistrados
FROM coop.Autorizacion_Pago
WHERE nPersonaID = @nPersonaID;

/*
    2. Historial para llenar la tabla de la página.
*/
SELECT 
    nAutorizarPagoID,
    nPersonaID,
    nNumSocio,
    mMonto,
    dAlta,
    dBaja,
    CASE WHEN dBaja IS NULL THEN 'ACTIVO' ELSE 'HISTORICO' END AS Estatus
FROM coop.Autorizacion_Pago
WHERE nPersonaID = @nPersonaID
ORDER BY dAlta DESC, nAutorizarPagoID DESC;

/*
    3. Consulta puntual del registro recién agregado.
       Sustituye el valor devuelto por el SP en @NuevoAutorizarPagoID.
*/
DECLARE @NuevoAutorizarPagoID BIGINT = NULL; -- reemplazar después de insertar

IF @NuevoAutorizarPagoID IS NOT NULL
BEGIN
    SELECT 
        nAutorizarPagoID,
        nPersonaID,
        nNumSocio,
        mMonto,
        dAlta,
        dBaja
    FROM coop.Autorizacion_Pago
    WHERE nAutorizarPagoID = @NuevoAutorizarPagoID;
END;
