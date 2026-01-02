/*
    Consultas simples para entender la logica de autorizacion de pagos.
    Base de datos: joso
*/
USE joso;
GO

/*
    1. Verificar el estado de pagos de una persona.
       Sustituye @PersonaID por el valor que tengas seleccionado en la pantalla.
*/
DECLARE @PersonaID BIGINT = 0; -- asignar desde WebDev

SELECT 
    p.nPersonaID,
    ISNULL(ap.nNumSocio, 0) AS NumSocio,
    CASE 
        WHEN ap.nAutorizarPagoID IS NULL THEN 'No tiene pagos'
        ELSE 'Tiene pagos previos'
    END AS EstadoPago
FROM per.Persona p
LEFT JOIN coop.Autorizacion_Pago ap
    ON p.nPersonaID = ap.nPersonaID
    AND ap.dBaja IS NULL
WHERE p.nPersonaID = @PersonaID;

/*
    2. Insertar un nuevo pago.
       Ajusta los parametros antes de ejecutar o llama al SP coop.usp_AutorizarPagoRegistrar.
*/
DECLARE @NuevoPersonaID BIGINT = 0;
DECLARE @NuevoNumSocio BIGINT = 0; -- mandar 0 si es nuevo
DECLARE @NuevoMonto MONEY = 0;
DECLARE @PersonaIDModifica BIGINT = 0; -- usuario logueado

INSERT INTO coop.Autorizacion_Pago
(
    nPersonaID,
    nNumSocio,
    mMonto,
    dAlta,
    dBaja,
    nPersonaIDModifica
)
VALUES
(
    @NuevoPersonaID,
    @NuevoNumSocio,
    @NuevoMonto,
    CAST(GETDATE() AS DATE),
    NULL,
    @PersonaIDModifica
);
GO
