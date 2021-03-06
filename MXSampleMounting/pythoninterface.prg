#include "networkdefs.inc"
#include "jsondefs.inc"
#include "genericdefs.inc"
#include "mountingdefs.inc"

Global String g_PortsRequestString$(NUM_CASSETTES)

''Python interface for GTJumpHomeToCoolingPointAndWait
Function PrepareForMountDismount As Boolean
	g_CurrentOperation$ = "PrepareForMountDismount"
	
	g_RunResult$ = ""
	
	If Not GTPositionCheckBeforeMotion Then
		UpdateClient(TASK_MSG, "error PrepareForMountDismount: GTPositionCheckBeforeMotion Failed!", ERROR_LEVEL)
		Exit Function
	EndIf
	
	If Not GTJumpHomeToCoolingPointAndWait Then
		Exit Function
	EndIf
	g_RunResult$ = "OK"
	
	g_CurrentOperation$ = "idle"
Fend

Function ResetCassettes
	g_CurrentOperation$ = "ResetCassettes"
	
	''init result
	g_RunResult$ = ""
	
	''Parsing g_RunArgs$
	String RequestTokens$(0)
	Integer RequestArgC
    
    ''parse argument from global
    ParseStr g_RunArgs$, RequestTokens$(), " "
    ''check argument
    RequestArgC = UBound(RequestTokens$) + 1

	String cassetteChar$
	Integer cassetteIndex, cassette_position, cassette_string_len

    If RequestArgC = 1 Then
    	For cassetteIndex = 0 To Len(g_RunArgs$) - 1
			cassetteChar$ = Mid$(g_RunArgs$, cassetteIndex + 1, 1)
			If Not GTParseCassettePosition(cassetteChar$, ByRef cassette_position) Then
				cassette_position = UNKNOWN_CASSETTE
				UpdateClient(TASK_MSG, "ResetCassettes: Invalid Cassette Position supplied in g_RunArgs$", ERROR_LEVEL)
			EndIf
		Next
		GTResetCassette(cassette_position)
	Else
		g_RunResult$ = "error ResetCassettes: Invalid number of arguments in g_RunArgs$!"
		UpdateClient(TASK_MSG, g_RunResult$, ERROR_LEVEL)
		Exit Function
    EndIf
    
   	g_CurrentOperation$ = "idle"
Fend

Function ResetCassettePorts
	''This function resets the ports as below, corresponding to 1's in g_PortsRequestString$ for all cassettes
	''If cassette type is unknown, then it resets all the ports as below
	''	g_<>SampleDistanceError = 0.0
	''	g_<>_PortStatus = PORT_UNKNOWN
	''  g_<>_TriggerPortForce = 0.0
	''  g_<>_FinalPortForce = 0.0
	g_CurrentOperation$ = "ResetCassettePorts"
		
	''init result
    g_RunResult$ = ""
    
	Integer cassette_position
	For cassette_position = LEFT_CASSETTE To RIGHT_CASSETTE
		GTResetSpecificPorts(cassette_position)
		GTsendCassetteData(PORT_STATES, cassette_position)
	Next
	
	g_RunResult$ = "OK"
	g_CurrentOperation$ = "idle"
Fend

Function ProbeCassettes
	g_CurrentOperation$ = "ProbeCassettes"

	Cls
    Print "GTProbeCassettes entered at ", Date$, " ", Time$
    
    ''Ensure moves are not restricted to XY plane for probe
    g_OnlyAlongAxis = False

	''init result
    g_RunResult$ = ""
    
	'' Initialize all constants
	If Not GTInitialize Then
		''Problem detected
		Exit Function
	EndIf
	
	If Not GTPositionCheckBeforeMotion Then
		UpdateClient(TASK_MSG, "error ProbeCassettes: GTPositionCheckBeforeMotion Failed!", ERROR_LEVEL)
		Exit Function
	EndIf
	
	If Not GTJumpHomeToCoolingPointAndWait Then
		''Problem detected
		Exit Function
	EndIf

	If Not GTCheckAndPickMagnet Then
		''Problem detected
		Exit Function
	EndIf
		
	Integer cassette_position
	Integer probeStringLengthToCheck
	String PortProbeRequestChar$
	Integer portIndex
	Boolean probeThisCassette
	
	For cassette_position = 0 To NUM_CASSETTES - 1
		probeThisCassette = False
	
		'' Here probeStingLengthToCheck is also the number of ports to probe
		probeStringLengthToCheck = Len(g_PortsRequestString$(cassette_position))
		If MAXIMUM_NUM_PORTS < probeStringLengthToCheck Then probeStringLengthToCheck = MAXIMUM_NUM_PORTS
		For portIndex = 0 To probeStringLengthToCheck - 1
			PortProbeRequestChar$ = Mid$(g_PortsRequestString$(cassette_position), portIndex + 1, 1)
			If PortProbeRequestChar$ = "1" Then
				''If even 1 port has to be probed, set probeThisCassette to True
				probeThisCassette = True
				Exit For
			EndIf
		Next
		
		If probeThisCassette Then
			g_CurrentOperation$ = "ProbeCassettes: " + GTCassetteName$(cassette_position)
			If GTProbeCassetteType(cassette_position) Then
				'' Only if the cassette type is known at cassette_position start probing inside the cassette
            	''only the ports that are to be probed are reset to unknown before probing.
            	''GTResetSpecificPorts is only called here because the user might forget to call it before probing
				GTResetSpecificPorts(cassette_position)
				If Not GTProbeSpecificPorts(cassette_position) Then
					UpdateClient(TASK_MSG, "GTProbeSpecificPorts Failed", ERROR_LEVEL)
					Exit Function
				EndIf
			EndIf
		EndIf

	Next
	
	'' Return Magnet To Cradle And Go to Home Position
	If Not GTReturnMagnetAndGoHome Then
		UpdateClient(TASK_MSG, "GTReturnMagnetAndGoHome failed", ERROR_LEVEL)
		Exit Function
	EndIf
	
	g_RunResult$ = "OK GTProbeCassettes"
    Print "GTProbeCassettes finished at ", Date$, " ", Time$
    g_CurrentOperation$ = "idle"
Fend

Function JSONDataRequest
	''Parsing g_RunArgs$
	String RequestTokens$(0)
	Integer RequestArgC
    
    ''parse argument from global
    ParseStr g_RunArgs$, RequestTokens$(), " "
    ''check argument
    RequestArgC = UBound(RequestTokens$) + 1

	Integer strIndex
	String cassetteChar$
	Integer cassette_position

	Integer jsonDataToSend, jsonDataToSendStrIndex
    If RequestArgC > 0 Then
    	For jsonDataToSendStrIndex = 1 To Len(RequestTokens$(0))
			Select UCase$(Mid$(RequestTokens$(0), jsonDataToSendStrIndex, 1))
				Case "C"
					jsonDataToSend = CASSETTE_TYPE
				Case "A"
					jsonDataToSend = PUCK_STATES
				Case "P"
					jsonDataToSend = PORT_STATES
				Case "D"
					jsonDataToSend = SAMPLE_DISTANCES
				Case "T"
					jsonDataToSend = TRIGGER_PORT_FORCES
				Case "F"
					jsonDataToSend = FINAL_PORT_FORCES
				Case "S"
					jsonDataToSend = SAMPLE_STATE
					GTsendSampleStateJSON
					GoTo endOfThisForLoop
				Case "M"
					jsonDataToSend = MAGNET_STATE
					GTsendMagnetStateJSON
					GoTo endOfThisForLoop
				Default
					Exit Function
			Send
			
			For strIndex = 1 To Len(RequestTokens$(1))
				cassetteChar$ = Mid$(RequestTokens$(1), strIndex, 1)
				
				If Not GTParseCassettePosition(cassetteChar$, ByRef cassette_position) Then
					cassette_position = UNKNOWN_CASSETTE
					UpdateClient(TASK_MSG, "Invalid cassette position in g_RunArgs$!", ERROR_LEVEL)
					''Exit Function '' Donot exit function because python doesn't know the error unless we send JSON data for error
				EndIf
				GTsendCassetteData(jsonDataToSend, cassette_position)
			Next

			endOfThisForLoop:
		Next
    EndIf
Fend
Function MountSamplePortAndGoHome
	MountSamplePort
	GTGoHome
Fend
Function MountSamplePort
	g_CurrentOperation$ = "MountSamplePort"
	
    Print "MountSamplePort entered at ", Date$, " ", Time$
    
    String msg$
     
    ''Ensure moves are not restricted to XY plane for probe
    g_OnlyAlongAxis = False

	''init result
    g_RunResult$ = ""
       
	'' Initialize all constants
	If Not GTInitialize Then
		UpdateClient(TASK_MSG, "GTInitialize failed", ERROR_LEVEL)
		Exit Function
	EndIf
	
	''Parsing g_RunArgs$
	String RequestTokens$(0)
	Integer RequestArgC
    
    ''parse argument from global
    ParseStr g_RunArgs$, RequestTokens$(), " "
    ''check argument
    RequestArgC = UBound(RequestTokens$) + 1

	String cassetteChar$, columnOrPuckChar$, rowOrPuckPortChar$
	Integer cassette_position, columnPuckIndex, rowPuckPortIndex

    If RequestArgC = 3 Then
		cassetteChar$ = Mid$(RequestTokens$(0), 1, 1)
		If Not GTParseCassettePosition(cassetteChar$, ByRef cassette_position) Then
			cassette_position = UNKNOWN_CASSETTE
			UpdateClient(TASK_MSG, "MountSamplePort: Invalid Cassette Position supplied in g_RunArgs$", ERROR_LEVEL)
			Exit Function
		EndIf

		columnOrPuckChar$ = Mid$(RequestTokens$(1), 1, 1)
		rowOrPuckPortChar$ = RequestTokens$(2)
		
		If Not GTParsePortIndex(cassette_position, columnOrPuckChar$, rowOrPuckPortChar$, ByRef columnPuckIndex, ByRef rowPuckPortIndex) Then
			UpdateClient(TASK_MSG, "MountSamplePort: GTParsePortIndex failed! Please check log for further details", ERROR_LEVEL)
			Exit Function
		EndIf
	Else
		g_RunResult$ = "error MountSamplePort: Invalid number of arguments in g_RunArgs$!"
		UpdateClient(TASK_MSG, g_RunResult$, ERROR_LEVEL)
		Exit Function
	EndIf
	
	If Not GTPositionCheckBeforeMotion Then
		UpdateClient(TASK_MSG, "MountSamplePort: GTPositionCheckBeforeMotion Failed!", ERROR_LEVEL)
		Exit Function
	EndIf
	
	''Check whether the port to be mounted is occupied. If not exit this function
	If Not GTcheckMountPort(cassette_position, columnPuckIndex, rowPuckPortIndex) Then
		''In stress testing, this just skips an empty port
		UpdateClient(TASK_MSG, "MountSamplePort: GTcheckMountPort Failed!", ERROR_LEVEL)
		Exit Function
	EndIf
	
	''Before you start mounting the sample requested by g_RunArgs$, 
	''check the gonio to see whether there is already a sample mounted
	''If mounted, then dismount it first then mount the new sample
	If g_InterestedSampleStatus = SAMPLE_IN_GONIO Then
		g_CurrentOperation$ = "MountSamplePort: Dismounting Sample on Gonio first."
		If Not GTDismountWithoutParsingRunArgs Then
			UpdateClient(TASK_MSG, "MountSamplePort->GTDismountWithoutParsingRunArgs Failed!", ERROR_LEVEL);
			Exit Function
		EndIf
		''Notice that the input parameters are the global variables which are already set. Only recheck is done here.
	EndIf
	
	
	''Actual mounting process starts here 
	g_CurrentOperation$ = "MountSamplePort: " + g_RunArgs$
	'' Here we check whether the port is filled and only then it sets the interested ports
	If Not GTsetMountPort(cassette_position, columnPuckIndex, rowPuckPortIndex) Then
		Exit Function
	EndIf
	
	If Not GTJumpHomeToCoolingPointAndWait Then
		Exit Function
	EndIf

	If Not GTCheckAndPickMagnet Then
		Exit Function
	EndIf
	
	If Not GTMountInterestedPort Then
		UpdateClient(TASK_MSG, "Error in MountSamplePort->GTMountInterestedPort: Check log for further details", ERROR_LEVEL)
		Exit Function
	EndIf
	
	g_RunResult$ = "OK MountSamplePort"
    Print "MountSamplePort finished at ", Date$, " ", Time$
    g_CurrentOperation$ = "idle"
Fend

Function DismountSample
	g_CurrentOperation$ = "DismountSample: " + g_RunArgs$
	
	Print "DismountSample entered at ", Date$, " ", Time$
    
	String msg$
     
    ''Ensure moves are not restricted to XY plane for probe
    g_OnlyAlongAxis = False

	''init result
    g_RunResult$ = ""
       
	'' Initialize all constants
	If Not GTInitialize Then
		UpdateClient(TASK_MSG, "GTInitialize failed", ERROR_LEVEL)
		Exit Function
	EndIf
	
	''Parsing g_RunArgs$
	String RequestTokens$(0)
	Integer RequestArgC
    
    ''parse argument from global
    ParseStr g_RunArgs$, RequestTokens$(), " "
    ''check argument
    RequestArgC = UBound(RequestTokens$) + 1

	String cassetteChar$, columnOrPuckChar$, rowOrPuckPortChar$
	Integer cassette_position, columnPuckIndex, rowPuckPortIndex

    If RequestArgC = 3 Then
		cassetteChar$ = Mid$(RequestTokens$(0), 1, 1)
		If Not GTParseCassettePosition(cassetteChar$, ByRef cassette_position) Then
			cassette_position = UNKNOWN_CASSETTE
			UpdateClient(TASK_MSG, "DismountSample: Invalid Cassette Position supplied in g_RunArgs$", ERROR_LEVEL)
			Exit Function
		EndIf

		columnOrPuckChar$ = Mid$(RequestTokens$(1), 1, 1)
		rowOrPuckPortChar$ = RequestTokens$(2)
		
		If Not GTParsePortIndex(cassette_position, columnOrPuckChar$, rowOrPuckPortChar$, ByRef columnPuckIndex, ByRef rowPuckPortIndex) Then
			UpdateClient(TASK_MSG, "DismountSample: GTParsePortIndex failed! Please check log for further details", ERROR_LEVEL)
			Exit Function
		EndIf
	Else
		g_RunResult$ = "error DismountSample: Invalid number of arguments in g_RunArgs$!"
		UpdateClient(TASK_MSG, g_RunResult$, ERROR_LEVEL)
		Exit Function
	EndIf
	
	If Not GTPositionCheckBeforeMotion Then
		UpdateClient(TASK_MSG, "DismountSample: GTPositionCheckBeforeMotion Failed!", ERROR_LEVEL)
		Exit Function
	EndIf
	
	''Actual dismounting process starts here 
	
	'' Here we check whether the port is empty and only then it sets the interested ports
	If Not GTsetDismountPort(cassette_position, columnPuckIndex, rowPuckPortIndex) Then
		Exit Function
	EndIf
	
	If Not GTDismountWithoutParsingRunArgs Then
		UpdateClient(TASK_MSG, "DismountSample->GTDismountWithoutParsingRunArgs Failed!", ERROR_LEVEL);
		Exit Function
	EndIf

	'' Put dumbbell in Cradle and go Home (P0)
	If Not GTReturnMagnetAndGoHome Then
		UpdateClient(TASK_MSG, "GTReturnMagnet failed", ERROR_LEVEL)
		Exit Function
	EndIf

	g_RunResult$ = "OK DismountSample"
    Print "DismountSample finished at ", Date$, " ", Time$
    g_CurrentOperation$ = "idle"
Fend

''Find Centers
Function FindPortCenters
	g_CurrentOperation$ = "FindPortCenters"
	Cls
    Print "FindPortCenters entered at ", Date$, " ", Time$
    
    ''Ensure moves are not restricted to XY plane for probe
    g_OnlyAlongAxis = False

	''init result
    g_RunResult$ = ""
    
	'' Initialize all constants
	If Not GTInitialize Then
		UpdateClient(TASK_MSG, "GTInitialize failed", ERROR_LEVEL)
		Exit Function
	EndIf
	
	If Not GTPositionCheckBeforeMotion Then
		UpdateClient(TASK_MSG, "error FindPortCenters: GTPositionCheckBeforeMotion Failed!", ERROR_LEVEL)
		Exit Function
	EndIf

	If Not GTJumpHomeToCoolingPointAndWait Then
		Exit Function
	EndIf

	If Not GTCheckAndPickMagnet Then
		Exit Function
	EndIf
		
	Integer cassette_position
	Integer probeStringLengthToCheck
	String PortProbeRequestChar$
	Integer portIndex
	Boolean probeThisCassette
	
	For cassette_position = 0 To NUM_CASSETTES - 1
		probeThisCassette = False
	
		'' Here probeStingLengthToCheck is also the number of ports to probe
		probeStringLengthToCheck = Len(g_PortsRequestString$(cassette_position))
		If MAXIMUM_NUM_PORTS < probeStringLengthToCheck Then probeStringLengthToCheck = MAXIMUM_NUM_PORTS
		For portIndex = 0 To probeStringLengthToCheck - 1
			PortProbeRequestChar$ = Mid$(g_PortsRequestString$(cassette_position), portIndex + 1, 1)
			If PortProbeRequestChar$ = "1" Then
				''If even 1 port has to be probed, set probeThisCassette to True
				probeThisCassette = True
				Exit For
			EndIf
		Next
		
		If probeThisCassette Then
			g_CurrentOperation$ = "FindPortCenters: " + GTCassetteName$(cassette_position)
			If GTProbeCassetteType(cassette_position) Then
				'' Only if the cassette type is known at cassette_position start probing inside the cassette
				If Not GTFindPortCentersInSuperPuck(cassette_position) Then
					UpdateClient(TASK_MSG, "GTFindPortCentersInSuperPuck Failed", ERROR_LEVEL)
					Exit Function
				EndIf
			EndIf
		EndIf

	Next
	
	'' Return Magnet To Cradle And Go to Home Position
	If Not GTReturnMagnetAndGoHome Then
		UpdateClient(TASK_MSG, "GTReturnMagnetAndGoHome failed", ERROR_LEVEL)
		Exit Function
	EndIf
	
	g_RunResult$ = "OK FindPortCenters"
    Print "FindPortCenters finished at ", Date$, " ", Time$
    g_CurrentOperation$ = "idle"
Fend

Function SetPortState
	g_RunResult$ = ""
	
	''Parsing g_RunArgs$
	String RequestTokens$(0)
	Integer RequestArgC
    
    ''parse argument from global
    ParseStr g_RunArgs$, RequestTokens$(), " "
    ''check argument
    RequestArgC = UBound(RequestTokens$) + 1

	String cassetteChar$, columnOrPuckChar$, rowOrPuckPortChar$
	Integer cassette_position, columnPuckIndex, rowPuckPortIndex
	Integer requestedPortStatus
	
	String msg$
	
    If RequestArgC = 4 Then
		cassetteChar$ = Mid$(RequestTokens$(0), 1, 1)
		If Not GTParseCassettePosition(cassetteChar$, ByRef cassette_position) Then
			cassette_position = UNKNOWN_CASSETTE
			UpdateClient(TASK_MSG, "SetPortState: Invalid Cassette Position supplied in g_RunArgs$", ERROR_LEVEL)
			Exit Function
		EndIf

		columnOrPuckChar$ = Mid$(RequestTokens$(1), 1, 1)
		rowOrPuckPortChar$ = RequestTokens$(2)
		
		If Not GTParsePortIndex(cassette_position, columnOrPuckChar$, rowOrPuckPortChar$, ByRef columnPuckIndex, ByRef rowPuckPortIndex) Then
			UpdateClient(TASK_MSG, "SetPortState: GTParsePortIndex failed! Please check log for further details", ERROR_LEVEL)
			Exit Function
		EndIf
		
		requestedPortStatus = Val(RequestTokens$(3))
		''This function lets you set only PORT_ERROR or PORT_UNKNOWN
		If requestedPortStatus <> PORT_ERROR And requestedPortStatus <> PORT_UNKNOWN Then
			g_RunResult$ = "error SetPortState: Port Status supplied neither PORT_ERROR nor PORT_UNKNOWN!"
			UpdateClient(TASK_MSG, g_RunResult$, ERROR_LEVEL)
			Exit Function
		EndIf
		
		''Only after all the above checks have passed, set the status
		If (g_CassetteType(cassette_position) = NORMAL_CASSETTE) Or (g_CassetteType(cassette_position) = CALIBRATION_CASSETTE) Then
			g_CAS_PortStatus(cassette_position, rowPuckPortIndex, columnPuckIndex) = requestedPortStatus
			msg$ = "{'set':'port_states', 'position':'" + GTCassettePosition$(cassette_position) + "', 'start':" + Str$(GTgetPortIndexFromCassetteVars(cassette_position, columnPuckIndex, rowPuckPortIndex)) + ", 'value':[" + Str$(g_CAS_PortStatus(cassette_position, columnPuckIndex, rowPuckPortIndex)) + ",]}"
			UpdateClient(CLIENT_UPDATE, msg$, INFO_LEVEL)
		ElseIf g_CassetteType(cassette_position) = SUPERPUCK_CASSETTE Then
			g_SP_PortStatus(cassette_position, columnPuckIndex, rowPuckPortIndex) = requestedPortStatus
			msg$ = "{'set':'port_states', 'position':'" + GTCassettePosition$(cassette_position) + "', 'start':" + Str$(GTgetPortIndexFromCassetteVars(cassette_position, columnPuckIndex, rowPuckPortIndex)) + ", 'value':[" + Str$(g_SP_PortStatus(cassette_position, columnPuckIndex, rowPuckPortIndex)) + ",]}"
			UpdateClient(CLIENT_UPDATE, msg$, INFO_LEVEL)
		Else
			g_RunResult$ = "error SetPortState: Invalid Cassette Type found at cassette_position supplied in g_RunArgs$"
			UpdateClient(TASK_MSG, g_RunResult$, ERROR_LEVEL)
		EndIf
		g_RunResult$ = "OK SetPortState"
	Else
		g_RunResult$ = "error SetPortState: Invalid number of arguments in g_RunArgs$!"
		UpdateClient(TASK_MSG, g_RunResult$, ERROR_LEVEL)
		Exit Function
	EndIf
Fend

