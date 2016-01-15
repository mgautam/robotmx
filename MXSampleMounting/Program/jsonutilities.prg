#include "networkdefs.inc"
#include "genericdefs.inc"
#include "cassettedefs.inc"
#include "superpuckdefs.inc"
#include "jsondefs.inc"

Function GTPortStatusString$(PortStatus As Integer) As String
	Select PortStatus
		Case PORT_OCCUPIED
			GTPortStatusString$ = "'OCC'"
		Case PORT_VACANT
			GTPortStatusString$ = "'VAC'"
		Case PORT_ERROR
			GTPortStatusString$ = "'ERR'"
		Default
			GTPortStatusString$ = "'UNK'"
	Send
Fend

Function GTPuckStatusString$(PuckStatus As Integer) As String
	Select PuckStatus
		Case PUCK_PRESENT
			GTPuckStatusString$ = "'OCC'"
		Case PUCK_ABSENT
			GTPuckStatusString$ = "'VAC'"
		Case PUCK_JAM
			GTPuckStatusString$ = "'ERR'"
		Default
			GTPuckStatusString$ = "'UNK'"
	Send
Fend

Function GTsendNormalCassetteData(dataToSend As Integer, cassette_position As Integer)
	'' This function also sends Calibration Cassette data
	
	String JSONResponse$
	Integer portsPerJSONPacket, numJSONPackets, responseJSONPacketIndex
	Integer startPortIndex, endPortIndex, portIndex
	Integer columnIndex, rowIndex
	Integer puckIndex, puckPortIndex

	portsPerJSONPacket = 16
	numJSONPackets = (NUM_ROWS * NUM_COLUMNS) / portsPerJSONPacket
	
	For responseJSONPacketIndex = 0 To numJSONPackets - 1
		startPortIndex = responseJSONPacketIndex * portsPerJSONPacket
		endPortIndex = (responseJSONPacketIndex + 1) * portsPerJSONPacket - 1
		
		If dataToSend = Cassette_PORTs_STATUS Then
			JSONResponse$ = "{'set':'cassette_ports_status'"
		ElseIf dataToSend = Cassette_DISTANCE_ERRORs Then
			JSONResponse$ = "{'set':'cassette_distance_errors'"
		Else
			UpdateClient(TASK_MSG, "Invalid dataToSend Request!", ERROR_LEVEL)
			Exit Function
		EndIf

		JSONResponse$ = JSONResponse$ + ",'position':'" + GTCassettePosition$(cassette_position) + "'"
		JSONResponse$ = JSONResponse$ + ",'type':'" + GTCassetteType$(g_CassetteType(cassette_position)) + "'"
		JSONResponse$ = JSONResponse$ + ",'start':" + Str$(startPortIndex) + ",'end':" + Str$(endPortIndex) + ",'value':["
		For portIndex = startPortIndex To endPortIndex
			ColumnIndex = portIndex / NUM_ROWS
			rowIndex = portIndex - (ColumnIndex * NUM_ROWS)
			
			If dataToSend = Cassette_PORTs_STATUS Then
				JSONResponse$ = JSONResponse$ + Str$(g_CAS_PortStatus(cassette_position, rowIndex, ColumnIndex)) + "," ''GTPortStatusString$
			ElseIf dataToSend = Cassette_DISTANCE_ERRORs Then
				JSONResponse$ = JSONResponse$ + FmtStr$(g_CASSampleDistanceError(cassette_position, rowIndex, ColumnIndex), "0.00") + ","
			EndIf
		Next
		JSONResponse$ = JSONResponse$ + "]}"

		UpdateClient(CLIENT_UPDATE, JSONResponse$, INFO_LEVEL)
	Next

Fend

Function GTsendSuperPuckData(dataToSend As Integer, cassette_position As Integer)
	String JSONResponse$
	Integer portsPerJSONPacket, numJSONPackets, responseJSONPacketIndex
	Integer startPortIndex, endPortIndex, portIndex
	Integer puckIndex, puckPortIndex
	
	portsPerJSONPacket = 16 '' One packet for each puck
	numJSONPackets = NUM_PUCKS
	
	For responseJSONPacketIndex = 0 To numJSONPackets - 1
		startPortIndex = responseJSONPacketIndex * portsPerJSONPacket
		endPortIndex = (responseJSONPacketIndex + 1) * portsPerJSONPacket - 1
		
		If dataToSend = Cassette_PORTs_STATUS Then
			JSONResponse$ = "{'set':'cassette_ports_status'"
		ElseIf dataToSend = Cassette_DISTANCE_ERRORs Then
			JSONResponse$ = "{'set':'cassette_distance_errors'"
		Else
			UpdateClient(TASK_MSG, "Invalid dataToSend Request!", ERROR_LEVEL)
			Exit Function
		EndIf
		
		JSONResponse$ = JSONResponse$ + ",'position':'" + GTCassettePosition$(cassette_position) + "'"
		JSONResponse$ = JSONResponse$ + ",'type':'" + GTCassetteType$(g_CassetteType(cassette_position)) + "'"
		JSONResponse$ = JSONResponse$ + ",'start':" + Str$(startPortIndex) + ",'end':" + Str$(endPortIndex) + ",'value':["
		puckIndex = responseJSONPacketIndex
		For puckPortIndex = 0 To NUM_PUCK_PORTS - 1
			If dataToSend = Cassette_PORTs_STATUS Then
				JSONResponse$ = JSONResponse$ + Str$(g_SP_PortStatus(cassette_position, puckIndex, puckPortIndex)) + "," ''GTPortStatusString$
			ElseIf dataToSend = Cassette_DISTANCE_ERRORs Then
				JSONResponse$ = JSONResponse$ + FmtStr$(g_SPSampleDistanceError(cassette_position, puckIndex, puckPortIndex), "0.00") + ","
			EndIf
		Next
		JSONResponse$ = JSONResponse$ + "]}"

		UpdateClient(CLIENT_UPDATE, JSONResponse$, INFO_LEVEL)
	Next

Fend

Function GTsendPuckData(cassette_position As Integer)
	String JSONResponse$
	Integer puckIndex
	
	JSONResponse$ = "{'set':'cassette_pucks_status'"
	JSONResponse$ = JSONResponse$ + ",'position':'" + GTCassettePosition$(cassette_position) + "'"
	JSONResponse$ = JSONResponse$ + ",'type':'" + GTCassetteType$(g_CassetteType(cassette_position)) + "'"
	JSONResponse$ = JSONResponse$ + ",'start':" + Str$(0) + ",'end':" + Str$(NUM_PUCKS - 1)
	JSONResponse$ = JSONResponse$ + ",'value':["
	For puckIndex = 0 To NUM_PUCKS - 1
		JSONResponse$ = JSONResponse$ + Str$(g_PuckStatus(cassette_position, puckIndex)) + "," ''GTPuckStatusString$
	Next
	JSONResponse$ = JSONResponse$ + "]}"

	UpdateClient(CLIENT_UPDATE, JSONResponse$, INFO_LEVEL)
Fend

Function GTsendCassetteData(dataToSend As Integer, cassette_position As Integer)
	If (g_CassetteType(cassette_position) = NORMAL_CASSETTE) Or (g_CassetteType(cassette_position) = CALIBRATION_CASSETTE) Then
		GTsendNormalCassetteData(dataToSend, cassette_position)
	ElseIf g_CassetteType(cassette_position) = SUPERPUCK_CASSETTE Then
		If dataToSend = CASSETTE_PUCKs_STATUS Then
			GTsendPuckData(cassette_position)
		Else
			GTsendSuperPuckData(dataToSend, cassette_position)
		EndIf
	Else
		'' Unknown Cassette
		String JSONResponse$
		
		If dataToSend = Cassette_PORTs_STATUS Then
			JSONResponse$ = "{'set':'cassette_ports_status'"
		ElseIf dataToSend = Cassette_DISTANCE_ERRORs Then
			JSONResponse$ = "{'set':'cassette_distance_errors'"
		ElseIf dataToSend = CASSETTE_PUCKs_STATUS Then
			JSONResponse$ = "{'set':'cassette_pucks_status'"
		Else
			UpdateClient(TASK_MSG, "Invalid dataToSend Request!", ERROR_LEVEL)
			Exit Function
		EndIf

		JSONResponse$ = JSONResponse$ + ",'position':'" + GTCassettePosition$(cassette_position) + "'"
		JSONResponse$ = JSONResponse$ + ",'type':'" + GTCassetteType$(g_CassetteType(cassette_position)) + "'"
		
		If dataToSend = Cassette_PORTs_STATUS Then
			JSONResponse$ = JSONResponse$ + ",'start':0,'end':0,'value':[]}"
		ElseIf dataToSend = Cassette_DISTANCE_ERRORs Then
			JSONResponse$ = JSONResponse$ + ",'start':0,'end':0,'value':[]}"
		ElseIf dataToSend = CASSETTE_PUCKs_STATUS Then
			JSONResponse$ = JSONResponse$ + ",'start':0,'end':0,'value':[]}"
		Else
			UpdateClient(TASK_MSG, "Invalid dataToSend Request!", ERROR_LEVEL)
			Exit Function
		EndIf

		UpdateClient(CLIENT_UPDATE, JSONResponse$, INFO_LEVEL)
	EndIf
Fend

