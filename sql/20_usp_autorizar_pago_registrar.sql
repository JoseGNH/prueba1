/*
    La lógica de registro de pagos ahora se controla desde la capa de aplicación.
    Este script elimina el procedimiento almacenado previo y documenta las sentencias
    que debe invocar la interfaz para mantener la misma regla de negocio.
*/
USE joso;
GO

IF OBJECT_ID('coop.usp_AutorizarPagoRegistrar', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE coop.usp_AutorizarPagoRegistrar;
    PRINT 'Procedimiento coop.usp_AutorizarPagoRegistrar eliminado. La lógica vive en la aplicación.';
END
ELSE
BEGIN
    PRINT 'El procedimiento coop.usp_AutorizarPagoRegistrar no existe. Sin cambios.';
END;
GO

/*
    Secuencia sugerida para ejecutar desde la capa de aplicación (WebDev/WLanguage):

    BEGIN TRY
        BEGIN TRAN;

        -- 1) Marcar como histórico cualquier pago activo de la persona.
        UPDATE coop.Autorizacion_Pago
        SET dBaja = CAST(GETDATE() AS DATE),
            nPersonaIDModifica = @nUsuario
        WHERE nPersonaID = @nPersonaID
          AND dBaja IS NULL;

        -- 2) Insertar el nuevo pago con dBaja = NULL y dAlta = fecha actual.
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
            @nPersonaID,
            @nNumSocioNormalizado, -- usar 0 cuando la persona no tenga número de socio.
            @mMonto,
            NULL,
            CAST(GETDATE() AS DATE),
            @nUsuario
        );

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        DECLARE @Mensaje NVARCHAR(4000) = ERROR_MESSAGE();
        -- Registrar en cat.Errores si se requiere auditoría/reporte.
        THROW;
    END CATCH;

    Adapta los nombres de parámetros a tu código WLanguage.
*/
