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
//EDT_PersonaID
// 1. Search for the active payment record (where dBaja IS NULL) in SQL Server
HReadSeekFirst(Persona1, nPersonaID, MySelf)

IF HFound(Persona1) THEN
	STC_Mensaje = Persona1.sNombres + " " + Persona1.sApellido1
	
	// 2. Search for the active payment record in Autorizacion_Pago1
	HFilter(Autorizacion_Pago1, "nPersonalID = " + MySelf + " AND dBaja IS NULL")
	HReadFirst(Autorizacion_Pago1)
	
	IF NOT HOut(Autorizacion_Pago1) THEN
		// Display current amount if an active record exists
		EDT_Monto_Autorizado = Autorizacion_Pago1.mMonto
		STC_Mensaje += " - Active record found."
	ELSE
		EDT_Monto_Autorizado = 0
		STC_Mensaje += " - No active authorized amount."
	END
	HDeactivateFilter(Autorizacion_Pago1)
ELSE
	STC_Mensaje				= "ID not found in Persona1 table."
	EDT_Monto_Autorizado	= 0
END

// Always deactivate the filter to keep the data engine clean
HDeactivateFilter(Autorizacion_Pago1)


/////////////////////////////////////////////////
/////////////////////////////////////////////////////////
BTN_Guardar
// 1. Call the procedure to process the logic in SQL Server
guard()

// 2. Clear the authorized amount field
EDT_Monto_Autorizado	= 0

// 3. Clear the Person ID field
EDT_PersonaID			= ""

// 4. Clear the modified by field
EDT_PersonaIDModifica	= ""

// 5. Reset the status message
STC_Mensaje				= "Ready for next entry."

// 6. Return focus to the ID field for the next scan/entry
SetFocus(EDT_PersonaID)

/////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////

