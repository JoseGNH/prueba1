/*
    Procedimiento que registra pagos en coop.Autorizacion_Pago
    y documenta cualquier error en cat.Errores.
*/
USE joso;
GO

IF OBJECT_ID('coop.usp_AutorizarPagoRegistrar', 'P') IS NOT NULL
    DROP PROCEDURE coop.usp_AutorizarPagoRegistrar;
GO

CREATE PROCEDURE coop.usp_AutorizarPagoRegistrar
    @nPersonaID          BIGINT,
    @nNumSocio           BIGINT = NULL,
    @mMonto              MONEY,
    @nPersonaIDModifica  BIGINT,
    @eSistema            INT = 1,
    @sSoluciones         VARCHAR(MAX) = NULL,
    @sSolucionesProgramador VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);
    DECLARE @NumSocio BIGINT = ISNULL(NULLIF(@nNumSocio,0), 0);

    BEGIN TRY
        BEGIN TRAN;

        UPDATE coop.Autorizacion_Pago
        SET dBaja = @Hoy,
            nPersonaIDModifica = @nPersonaIDModifica
        WHERE nPersonaID = @nPersonaID
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
            @nPersonaID,
            @NumSocio,
            @mMonto,
            NULL,
            @Hoy,
            @nPersonaIDModifica
        );

        DECLARE @NuevoAutorizarPagoID BIGINT = SCOPE_IDENTITY();

        COMMIT TRAN;

        SELECT @NuevoAutorizarPagoID AS NuevoAutorizarPagoID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        DECLARE 
            @ErrorNumber   INT = ERROR_NUMBER(),
            @ErrorSeverity INT = ERROR_SEVERITY(),
            @ErrorState    INT = ERROR_STATE(),
            @ErrorLine     INT = ERROR_LINE(),
            @ErrorMessage  NVARCHAR(4000) = ERROR_MESSAGE();

        INSERT INTO cat.Errores
        (
            eSistema,
            sCodigoError,
            sMensajeError,
            sSoluciones,
            sSolucionesProgramador
        )
        VALUES
        (
            @eSistema,
            CONCAT('SQL-', @ErrorNumber, '-', @ErrorLine),
            @ErrorMessage,
            @sSoluciones,
            ISNULL(@sSolucionesProgramador, 'Validar transaccion de pago y datos capturados.')
        );

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO
