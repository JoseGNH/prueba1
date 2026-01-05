PROCEDURE guard()
///////
///////
nIDPersona	is int		= EDT_PersonaID
nMonto		is currency	= EDT_Monto_Autorizado
nIDModif	is int		= EDT_PersonaIDModifica
dtNow		is DateTime	= DateSys() + TimeSys()



// 2. Search for existing active record
sCondition is string = StringBuild("nPersonaID = %1 AND dBaja IS NULL", nIDPersona)
HFilter(Autorizacion_Pago1, sCondition)
HReadFirst(Autorizacion_Pago1)

// 3. If found, update the PREVIOUS record with today's date
IF NOT HOut(Autorizacion_Pago1) THEN
	Autorizacion_Pago1.dBaja = DateSys() 
	HModify(Autorizacion_Pago1)
END

// 4. Clear context for the new insert
HDeactivateFilter(Autorizacion_Pago1)

// 5. Prepare the NEW record
HReset(Autorizacion_Pago1)

Autorizacion_Pago1.nPersonaID			= nIDPersona
Autorizacion_Pago1.nNumSocio			= 0 
Autorizacion_Pago1.mMonto				= nMonto
Autorizacion_Pago1.dAlta				= DateSys() 

// FIX: Instead of HSetNull, use this syntax to force NULL in SQL Server
Autorizacion_Pago1.dBaja..Null = True

Autorizacion_Pago1.nPersonaIDModifica	= nIDModif
Autorizacion_Pago1.dRegistro			= dtNow

// 6. Final Insert into SQL Server
IF HAdd(Autorizacion_Pago1) THEN
	STC_Mensaje				= "Record saved. New ID: " + Autorizacion_Pago1.nAutorizarPagoID
	
	// UI Reset
	EDT_PersonaID			= ""
	EDT_Monto_Autorizado	= 0
	EDT_PersonaIDModifica	= ""
	SetFocus(EDT_PersonaID)
ELSE
	Error("SQL Error: " + HErrorInfo(hErrFullDetails))
END
/////////////////////////////////
/////////////////////////////////