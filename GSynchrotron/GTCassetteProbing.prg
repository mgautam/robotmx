#include "GTCassettedefs.inc"
#include "GTReporterdefs.inc"

Function GTProbeOneCassette(cassette_position As Integer)
	Integer standbyPointNum
	Real scanZdistance
	Real cassette_top_Z_value, scanned_cassette_height
	Integer guessedCassetteType
	Real guessedCassetteType_height_error
	
	standbyPointNum = 52
	
	Tool PICKER_TOOL
	
	g_RunResult$ = "progress GTProbeOneCassette->GTSetScanCassetteTopStandbyPoint"
	GTSetScanCassetteTopStandbyPoint(cassette_position, standbyPointNum, 0, ByRef scanZdistance)
	
	g_RunResult$ = "progress GTProbeOneCassette->GTScanCassetteTop"
	If GTScanCassetteTop(standbyPointNum, scanZdistance, ByRef cassette_top_Z_value) Then
		scanned_cassette_height = cassette_top_Z_value - g_BottomZ(cassette_position)
		GTUpdateClient(TASK_MESSAGE_REPORT, HIGH_LEVEL_FUNCTION, "GTScanCassetteTop completed.  Detected Cassette Height = " + Str$(scanned_cassette_height))
	Else
		GTUpdateClient(TASK_FAILURE_REPORT, HIGH_LEVEL_FUNCTION, "GTScanCassetteTop failed: error in GTScanCassetteTop!")
		g_RunResult$ = "error GTProbeOneCassette->GTScanCassetteTop"
		Exit Function
	EndIf

	g_RunResult$ = "progress GTProbeOneCassette->GTCassetteTypeFromHeight"
	If Not GTCassetteTypeFromHeight(cassette_position, scanned_cassette_height, ByRef guessedCassetteType, ByRef guessedCassetteType_height_error) Then
		If guessedCassetteType_height_error > MAX_ERR_FOR_SCAN_CAS_TYPE_RTRY Then
			GTUpdateClient(TASK_FAILURE_REPORT, HIGH_LEVEL_FUNCTION, "GTProbeOneCassette->GTCassetteTypeFromHeight failed: guessedCassetteType_height_error > MAX_ERR_FOR_SCAN_CAS_TYPE_RTRY!")
			g_RunResult$ = "error GTProbeOneCassette->GTCassetteTypeFromHeight: guessedCassetteType_height_error > MAX_ERR_FOR_SCAN_CAS_TYPE_RTRY"
			Exit Function
		Else
			GTUpdateClient(TASK_MESSAGE_REPORT, HIGH_LEVEL_FUNCTION, "GTProbeOneCassette->GTCassetteTypeFromHeight: guessedCassetteType_height_error < MAX_ERR_FOR_SCAN_CAS_TYPE_RTRY. Starting comprehensive scan for Cassette Type")

			g_RunResult$ = "progress GTProbeOneCassette->GTfindAverageCassetteHeight"
			Real averageCassetteHeight
			If GTfindAverageCassetteHeight(cassette_position, scanned_cassette_height, guessedCassetteType, ByRef averageCassetteHeight) Then
				If Not GTCassetteTypeFromHeight(cassette_position, averageCassetteHeight, ByRef guessedCassetteType, ByRef guessedCassetteType_height_error) Then
					g_RunResult$ = "error GTCassetteTypeFromHeight: averageHeight > ACCPT_ERROR_IN_CASSETTE_HEIGHT"
					GTUpdateClient(TASK_FAILURE_REPORT, HIGH_LEVEL_FUNCTION, "GTProbeOneCassette->GTCassetteTypeFromHeight failed: guessedCassetteType_height_error=" + Str$(guessedCassetteType_height_error) + " for averageCassetteHeight=" + Str$(averageCassetteHeight))
					Exit Function
				EndIf
			Else
				g_RunResult$ = "error GTProbeOneCassette->GTfindAverageCassetteHeight!"
				GTUpdateClient(TASK_FAILURE_REPORT, HIGH_LEVEL_FUNCTION, "GTProbeOneCassette failed: error in GTfindAverageCassetteHeight!")
				Exit Function
			EndIf
		EndIf
	EndIf
	
	If g_CassetteType(cassette_position) = SUPERPUCK_CASSETTE Then
		g_RunResult$ = "progress GTProbeOneCassette->GTprobeAdaptorAngleCorrection"
		If Not GTprobeAdaptorAngleCorrection(cassette_position) Then
			g_RunResult$ = "error GTProbeOneCassette->GTprobeAdaptorAngleCorrection!"
			GTUpdateClient(TASK_FAILURE_REPORT, HIGH_LEVEL_FUNCTION, "GTProbeOneCassette failed: error in GTprobeAdaptorAngleCorrection!")
			Exit Function
		EndIf
	EndIf
	
	SetVerySlowSpeed
	g_RunResult$ = "success GTProbeOneCassette"
Fend

Function ProbeAllPorts(cassette_position As Integer)
	Integer rowIndex, columnIndex

	Select g_CassetteType(cassette_position)
		Case CALIBRATION_CASSETTE
			rowIndex = 0
			For columnIndex = 0 To NUM_COLUMNS - 1
				GTprobeCassettePort(cassette_position, rowIndex, columnIndex)
			Next
			rowIndex = NUM_ROWS - 1
			For columnIndex = 0 To NUM_COLUMNS - 1
				GTprobeCassettePort(cassette_position, rowIndex, columnIndex)
			Next
			
		Case NORMAL_CASSETTE
			For rowIndex = 0 To NUM_ROWS - 1
				For columnIndex = 0 To NUM_COLUMNS - 1
					GTprobeCassettePort(cassette_position, rowIndex, columnIndex)
				Next
			Next
			
		Case SUPERPUCK_CASSETTE
			Integer puckIndex, portIndex
			For puckIndex = 0 To NUM_PUCKS - 1
				GTprobeSPPuck(cassette_position, puckIndex)
			
				If g_PuckPresent(cassette_position, puckIndex) Then
					For portIndex = 0 To NUM_PUCK_PORTS - 1
						GTprobeSPPort(cassette_position, puckIndex, portIndex)
					Next
				EndIf
			Next
			
	Send
Fend

Function GTtestCassetteScan()

	Integer cassette_position
	cassette_position = LEFT_CASSETTE
	
	GTInitialize
	
	g_RunResult$ = "progress GTtestCassetteScan->GTInitAllPoints"
	If Not GTInitAllPoints Then
		GTUpdateClient(TASK_FAILURE_REPORT, HIGH_LEVEL_FUNCTION, "GTInitAllPoints failed")
		g_RunResult$ = "error GTInitAllPoints"
		Exit Function
	EndIf
	
	g_RunResult$ = "progress GTtestCassetteScan->GTProbeOneCassette"
	GTProbeOneCassette(cassette_position)
Fend
