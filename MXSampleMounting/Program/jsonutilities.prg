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

	portsPerJSONPacket = 24
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
			columnIndex = portIndex / NUM_ROWS
			rowIndex = portIndex - (columnIndex * NUM_ROWS)
			
			If dataToSend = Cassette_PORTs_STATUS Then
				JSONResponse$ = JSONResponse$ + GTPortStatusString$(g_CAS_PortStatus(cassette_position, rowIndex, columnIndex)) + ","
			ElseIf dataToSend = Cassette_DISTANCE_ERRORs Then
				JSONResponse$ = JSONResponse$ + FmtStr$(g_CASSampleDistanceError(cassette_position, rowIndex, columnIndex), "0.00") + ","
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
		
		JSONResponse$ = JSONResponse$ + ",'position':" + GTCassettePosition$(cassette_position)
		JSONResponse$ = JSONResponse$ + ",'type':" + GTCassetteType$(g_CassetteType(cassette_position))
		JSONResponse$ = JSONResponse$ + ",'start':" + Str$(startPortIndex) + ",'end':" + Str$(endPortIndex) + ",'value':["
		puckIndex = responseJSONPacketIndex
		For puckPortIndex = 0 To NUM_PUCK_PORTS - 1
			If dataToSend = Cassette_PORTs_STATUS Then
				JSONResponse$ = JSONResponse$ + GTPortStatusString$(g_SP_PortStatus(cassette_position, puckIndex, puckPortIndex)) + ","
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
	JSONResponse$ = JSONResponse$ + ",'position':" + GTCassettePosition$(cassette_position)
	JSONResponse$ = JSONResponse$ + ",'type':" + GTCassetteType$(g_CassetteType(cassette_position))
	JSONResponse$ = JSONResponse$ + ",'value':["
	For puckIndex = 0 To NUM_PUCKS - 1
		JSONResponse$ = JSONResponse$ + GTPuckStatusString$(g_PuckStatus(cassette_position, puckIndex)) + ","
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
	EndIf
Fend

