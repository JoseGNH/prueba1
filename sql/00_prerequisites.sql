/*
    Pre-requisites for the Autorización de Pagos module.
    - Ensures the dBaja column accepts NULL so active records can be tracked.
    - Creates a default constraint to store today's date on dAlta when not provided.
    Base de datos objetivo: joso.
*/
USE joso;
GO

DECLARE @dBajaEsNulo VARCHAR(3);

SELECT @dBajaEsNulo = IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'coop'
  AND TABLE_NAME = 'Autorizacion_Pago'
  AND COLUMN_NAME = 'dBaja';

IF @dBajaEsNulo = 'NO'
BEGIN
    PRINT 'Actualizando dBaja para permitir NULL...';
    ALTER TABLE coop.Autorizacion_Pago
        ALTER COLUMN dBaja DATE NULL;
END;
ELSE
BEGIN
    PRINT 'dBaja ya permite NULL. Sin cambios.';
END;
GO

DECLARE @TieneDefaultAlta BIT = 0;

IF EXISTS (
    SELECT 1
    FROM sys.default_constraints
    WHERE parent_object_id = OBJECT_ID('coop.Autorizacion_Pago')
      AND name = 'DF_AutorizacionPago_dAlta'
)
BEGIN
    SET @TieneDefaultAlta = 1;
END;

IF @TieneDefaultAlta = 0
BEGIN
    PRINT 'Agregando default DF_AutorizacionPago_dAlta...';
    ALTER TABLE coop.Autorizacion_Pago
        ADD CONSTRAINT DF_AutorizacionPago_dAlta DEFAULT (CAST(GETDATE() AS DATE)) FOR dAlta;
END;
ELSE
BEGIN
    PRINT 'DF_AutorizacionPago_dAlta ya existe. Sin cambios.';
END;
GO
