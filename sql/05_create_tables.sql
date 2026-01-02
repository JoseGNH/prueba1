/*
    Script para crear las tablas base utilizadas por la pestaña de Autorizacion de Pagos.
    Ajusta el valor de <NOMBRE_BASE_DATOS> antes de ejecutarlo.
*/
--create database joso
USE joso
GO

/* Crear esquemas si no existen */
IF SCHEMA_ID('cat') IS NULL EXEC ('CREATE SCHEMA cat;');
IF SCHEMA_ID('per') IS NULL EXEC ('CREATE SCHEMA per;');
IF SCHEMA_ID('soc') IS NULL EXEC ('CREATE SCHEMA soc;');
IF SCHEMA_ID('coop') IS NULL EXEC ('CREATE SCHEMA coop;');
GO

/* Tabla cat.Errores */
IF OBJECT_ID('cat.Errores', 'U') IS NOT NULL
    DROP TABLE cat.Errores;
GO

CREATE TABLE cat.Errores
(
    nErrorID              BIGINT IDENTITY(1,1) CONSTRAINT PK_Errores PRIMARY KEY,
    eSistema              INT NOT NULL,
    sCodigoError          VARCHAR(50) NOT NULL,
    sMensajeError         VARCHAR(MAX) NOT NULL,
    sSoluciones           VARCHAR(MAX) NULL,
    sSolucionesProgramador VARCHAR(MAX) NULL,
    dRegistro             DATETIME2(0) NOT NULL CONSTRAINT DF_Errores_dRegistro DEFAULT SYSDATETIME()
);
GO

/* Tabla per.Persona */
IF OBJECT_ID('per.Persona', 'U') IS NOT NULL
    DROP TABLE per.Persona;
GO

CREATE TABLE per.Persona
(
    nPersonaID BIGINT IDENTITY(1,1) CONSTRAINT PK_Persona PRIMARY KEY,
    sApellido1 VARCHAR(100) NOT NULL,
    sApellido2 VARCHAR(100) NULL,
    sNombres   VARCHAR(150) NOT NULL,
    dRegistro  DATETIME2(0) NOT NULL CONSTRAINT DF_Persona_dRegistro DEFAULT SYSDATETIME()
);
GO

/* Tabla soc.Socio */
IF OBJECT_ID('soc.Socio', 'U') IS NOT NULL
    DROP TABLE soc.Socio;
GO

CREATE TABLE soc.Socio
(
    nNoSocio  BIGINT IDENTITY(1,1) CONSTRAINT PK_Socio PRIMARY KEY,
    sClave    VARCHAR(50) NOT NULL,
    nPersonaID BIGINT NOT NULL,
    dRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_Socio_dRegistro DEFAULT SYSDATETIME(),
    CONSTRAINT UQ_Socio_sClave UNIQUE (sClave),
    CONSTRAINT FK_Socio_Persona FOREIGN KEY (nPersonaID) REFERENCES per.Persona(nPersonaID)
);
GO

/* Tabla coop.Autorizacion_Pago */
IF OBJECT_ID('coop.Autorizacion_Pago', 'U') IS NOT NULL
    DROP TABLE coop.Autorizacion_Pago;
GO

CREATE TABLE coop.Autorizacion_Pago
(
    nAutorizarPagoID    BIGINT IDENTITY(1,1) CONSTRAINT PK_AutorizacionPago PRIMARY KEY,
    nPersonaID          BIGINT NOT NULL,
    nNumSocio           BIGINT NOT NULL,
    mMonto              MONEY NOT NULL,
    dBaja               DATE NULL,
    dAlta               DATE NOT NULL CONSTRAINT DF_AutorizacionPago_dAlta DEFAULT (CAST(GETDATE() AS DATE)),
    nPersonaIDModifica  BIGINT NOT NULL,
    dRegistro           DATETIME2(0) NOT NULL CONSTRAINT DF_AutorizacionPago_dRegistro DEFAULT SYSDATETIME(),
    CONSTRAINT FK_AutorizacionPago_Persona FOREIGN KEY (nPersonaID) REFERENCES per.Persona(nPersonaID)
);
GO

CREATE NONCLUSTERED INDEX IX_AutorizacionPago_PersonaActiva
    ON coop.Autorizacion_Pago (nPersonaID)
    INCLUDE (dBaja, dAlta);
GO

PRINT 'Tablas cat.Errores, per.Persona, soc.Socio y coop.Autorizacion_Pago creadas correctamente.';
