#include "forcedefs.inc"
#include "mxrobotdefs.inc"
#include "GTCassettedefs.inc"
#include "GTReporterdefs.inc"

Global Integer g_CassetteType(NUM_CASSETTES)


Function GTCassetteType$(cassetteType As Integer) As String
	If cassetteType = CALIBRATION_CASSETTE Then
		GTCassetteType$ = "calibration_cassette"
	ElseIf cassetteType = NORMAL_CASSETTE Then
		GTCassetteType$ = "normal_cassette"
	ElseIf cassetteType = SUPERPUCK_CASSETTE Then
		GTCassetteType$ = "superpuck_cassette"
	Else
		GTCassetteType$ = "unknown_cassette"
	EndIf
Fend


Function GTSetScanCassetteTopStandbyPoint(cassette_position As Integer, pointNum As Integer, uOffset As Real, ByRef scanZdistance As Real)
	Real radiusToCircleCassette, standbyPointU, standbyZoffsetFromCassetteBottom
	
	radiusToCircleCassette = CASSETTE_RADIUS * CASSETTE_SHRINK_IN_LN2 - 3.0
	
	Real Uangle
	Uangle = g_AngleOfFirstColumn(cassette_position) + uOffset
	standbyPointU = g_UForNormalStandby(cassette_position) + GTBoundAngle(-180, 180, (Uangle - g_UForNormalStandby(cassette_position)))
	
	'' 15mm above Maximum Cassette Height = SUPERPUCK_HEIGHT
	standbyZoffsetFromCassetteBottom = CASSETTE_SHRINK_IN_LN2 * SUPERPUCK_HEIGHT + 15.0

	'' Internally sets P(pointNum) to CircumferencePointFromU
	GTSetCircumferencePointFromU(cassette_position, standbyPointU, radiusToCircleCassette, standbyZoffsetFromCassetteBottom, pointNum)

	'' Rotate 30 degrees to give cavity some space
	P(pointNum) = P(pointNum) +U(30.0)
	
	'' Maximum distance in Z-axis to scan for Cassette using TouchCassetteTop = 30mm
	scanZdistance = 30.0
Fend


Function GTScanCassetteTop(standbyPointNum As Integer, maxZdistanceToScan As Real, ByRef cassetteTopZvalue As Real) As Boolean
	GTUpdateClient(TASK_ENTERED_REPORT, MID_LEVEL_FUNCTION, "GTScanCassetteTop(standbyPoint=P" + Str$(standbyPointNum) + ", maxZdistanceToScan=" + Str$(maxZdistanceToScan) + ")")
	
	LimZ g_Jump_LimZ_LN2
	Jump P(standbyPointNum)

	InitForceConstants
	ForceCalibrateAndCheck(LOW_SENSITIVITY, LOW_SENSITIVITY)
	
	If Not (ForceTouch(-FORCE_ZFORCE, maxZdistanceToScan, False)) Then
		GTUpdateClient(TASK_FAILURE_REPORT, MID_LEVEL_FUNCTION, "GTScanCassetteTop: ForceTouch failed to detect Cassette!")
		GTScanCassetteTop = False
		Exit Function
	EndIf
	
	cassetteTopZvalue = CZ(RealPos) - MAGNET_HEAD_RADIUS
	
	SetVerySlowSpeed
	Move P(standbyPointNum)
	
	GTUpdateClient(TASK_DONE_REPORT, MID_LEVEL_FUNCTION, "GTScanCassetteTop completed. cassetteTopZvalue=" + Str$(cassetteTopZvalue))
	GTScanCassetteTop = True
Fend


Function GTCassetteTypeFromHeight(cassette_position As Integer, cassetteHeight As Real, ByRef guessedCassetteType As Integer, ByRef min_height_error As Real) As Boolean
	Real calib_highEdge_height_in_LN2, calib_lowEdge_height_in_LN2
	Real normal_height_in_LN2, superpuck_height_in_LN2
	
	calib_highEdge_height_in_LN2 = CASSETTE_CAL_HEIGHT * CASSETTE_SHRINK_IN_LN2
	calib_lowEdge_height_in_LN2 = (CASSETTE_CAL_HEIGHT - CASSETTE_EDGE_HEIGHT) * CASSETTE_SHRINK_IN_LN2
	normal_height_in_LN2 = CASSETTE_HEIGHT * CASSETTE_SHRINK_IN_LN2
	superpuck_height_in_LN2 = SUPERPUCK_HEIGHT * CASSETTE_SHRINK_IN_LN2
	
	Real calib_highEdge_height_difference, calib_lowEdge_height_difference
	calib_highEdge_height_difference = Abs(calib_highEdge_height_in_LN2 - cassetteHeight)
	calib_lowEdge_height_difference = Abs(calib_lowEdge_height_in_LN2 - cassetteHeight)

	''To store difference in top Zvalue of scanned cassette from calibration, normal and superpuck cassettes respectively
	Real calibration_height_difference, normal_height_difference, superpuck_height_difference
	
	If calib_highEdge_height_difference < calib_lowEdge_height_difference Then
		calibration_height_difference = calib_highEdge_height_difference
	Else
		calibration_height_difference = calib_lowEdge_height_difference
	EndIf
	
	normal_height_difference = Abs(normal_height_in_LN2 - cassetteHeight)
	superpuck_height_difference = Abs(superpuck_height_in_LN2 - cassetteHeight)

	'' Guess the cassette type with minimum height difference from the scanned cassette
	If (calibration_height_difference < normal_height_difference) And (calibration_height_difference < superpuck_height_difference) Then
		guessedCassetteType = CALIBRATION_CASSETTE
		min_height_error = calibration_height_difference
	ElseIf (normal_height_difference < calibration_height_difference) And (normal_height_difference < superpuck_height_difference) Then
		guessedCassetteType = NORMAL_CASSETTE
		min_height_error = normal_height_difference
	Else
		guessedCassetteType = SUPERPUCK_CASSETTE
		min_height_error = superpuck_height_difference
	EndIf
	
	If min_height_error < ACCPT_ERROR_IN_CASSETTE_HEIGHT Then
		g_CassetteType(cassette_position) = guessedCassetteType
		GTCassetteTypeFromHeight = True
		GTUpdateClient(TASK_DONE_REPORT, MID_LEVEL_FUNCTION, "GTfindCassetteType completed. " + GTCassetteName$(cassette_position) + " Type=" + GTCassetteType$(guessedCassetteType))
	Else
		g_CassetteType(cassette_position) = UNKNOWN_CASSETTE
		GTCassetteTypeFromHeight = False
		GTUpdateClient(TASK_WARNING_REPORT, MID_LEVEL_FUNCTION, "GTfindCassetteType for " + GTCassetteName$(cassette_position) + " found min_height_error=" + Str$(min_height_error) + ">ACCPT_ERROR_IN_CASSETTE_HEIGHT =" + Str$(ACCPT_ERROR_IN_CASSETTE_HEIGHT))
	EndIf
	
Fend

Function GTsetfindAvgHeightStandbyPoint(cassette_position As Integer, pointNum As Integer, index As Integer, guessedCassetteType As Integer, ByRef scanZdistance As Real)
	If guessedCassetteType = SUPERPUCK_CASSETTE Then
		Real standbyZ
		
		GTSetScanCassetteTopStandbyPoint(cassette_position, pointNum, 0, ByRef scanZdistance)
		standbyZ = CZ(P(pointNum))
		
		If index = 1 Then
			GTsetSPPortPoint(cassette_position, 13, PUCK_C, -3.0, pointNum)
			P(pointNum) = P(pointNum) +U(30) :Z(standbyZ)
		Else
			GTsetSPPortPoint(cassette_position, 8, PUCK_A, -3.0, pointNum)
			P(pointNum) = P(pointNum) +U(30) :Z(standbyZ)
		EndIf
	Else
		Real uOffset
		uOffset = 90.0 * index
		GTSetScanCassetteTopStandbyPoint(cassette_position, pointNum, uOffset, ByRef scanZdistance)
	EndIf
Fend


Function GTfindAverageCassetteHeight(cassette_position As Integer, cassetteFirstHeight As Real, guessedCassetteType As Integer, ByRef average_height As Real) As Boolean
	GTUpdateClient(TASK_ENTERED_REPORT, MID_LEVEL_FUNCTION, "GTfindAverageCassetteHeight(cassette_position=" + GTCassetteName$(cassette_position) + ", cassetteFirstHeight=" + Str$(cassetteFirstHeight) + ", guessedCassetteType=" + GTCassetteType$(guessedCassetteType) + ")")

	Integer standbyPoint
	Integer NumberOfHeights, tryIndex
	Real scanZdistance, cassette_top_Z_value
	Real heights(4)
	
	standbyPoint = 52
	heights(0) = cassetteFirstHeight
	
	If guessedCassetteType = SUPERPUCK_CASSETTE Then
		NumberOfHeights = 3
		For tryIndex = 1 To NumberOfHeights - 1
			GTsetfindAvgHeightStandbyPoint(cassette_position, standbyPoint, tryIndex, guessedCassetteType, ByRef scanZdistance)
		
			If GTScanCassetteTop(standbyPoint, scanZdistance, ByRef cassette_top_Z_value) Then
				heights(tryIndex) = cassette_top_Z_value - g_BottomZ(cassette_position)
				GTUpdateClient(TASK_MESSAGE_REPORT, MID_LEVEL_FUNCTION, "GTfindAverageCassetteHeight: Detected Cassette Height = " + Str$(heights(tryIndex)))
			Else
				GTUpdateClient(TASK_FAILURE_REPORT, MID_LEVEL_FUNCTION, "GTfindAverageCassetteHeight failed: error in GTScanCassetteTop!")
				GTfindAverageCassetteHeight = False
				Exit Function
			EndIf
		Next
    Else
        NumberOfHeights = 4
		For tryIndex = 1 To NumberOfHeights - 1
        	GTsetfindAvgHeightStandbyPoint(cassette_position, standbyPoint, tryIndex, guessedCassetteType, ByRef scanZdistance)
		
			If GTScanCassetteTop(standbyPoint, scanZdistance, ByRef cassette_top_Z_value) Then
				heights(tryIndex) = cassette_top_Z_value - g_BottomZ(cassette_position)
				GTUpdateClient(TASK_MESSAGE_REPORT, MID_LEVEL_FUNCTION, "GTfindAverageCassetteHeight: Detected Cassette Height = " + Str$(heights(tryIndex)))
			Else
				GTUpdateClient(TASK_FAILURE_REPORT, MID_LEVEL_FUNCTION, "GTfindAverageCassetteHeight failed: error in GTScanCassetteTop!")
				GTfindAverageCassetteHeight = False
				Exit Function
			EndIf
		Next
	EndIf
	
	'' Compute Statistics from the scanned heights
	average_height = heights(0)
	Real minHeight, maxHeight
	minHeight = heights(0)
	maxHeight = heights(0)
	For tryIndex = 1 To NumberOfHeights - 1
		average_height = average_height + heights(tryIndex)
		
		If minHeight > heights(tryIndex) Then
			minHeight = heights(tryIndex)
		EndIf
		
		If maxHeight < heights(tryIndex) Then
			maxHeight = heights(tryIndex)
		EndIf
	Next
	average_height = average_height / NumberOfHeights
	
	'' Verify that maxHeight-minHeight is less than Calibration Cassette Edge Height
	If (maxHeight - minHeight) > (CASSETTE_EDGE_HEIGHT * CASSETTE_SHRINK_IN_LN2 + MAX_ERR_FOR_SCAN_CAS_TYPE_RTRY) Then
		GTUpdateClient(TASK_FAILURE_REPORT, MID_LEVEL_FUNCTION, "GTfindAverageCassetteHeight failed: maxHeight-minHeight > Calibration Cassette Edge Height!")
		GTfindAverageCassetteHeight = False
		Exit Function
	EndIf
    
    If (maxHeight - minHeight) > 0.5 * CASSETTE_EDGE_HEIGHT * CASSETTE_SHRINK_IN_LN2 Then
    	'' It can only be calibration cassette, so add edge height to low edge height in calculating average height
    	Real edgeThreshold
        edgeThreshold = maxHeight - 0.5 * CASSETTE_EDGE_HEIGHT * CASSETTE_SHRINK_IN_LN2
        For tryIndex = 0 To NumberOfHeights - 1
            If heights(tryIndex) < edgeThreshold Then
               average_height = average_height + (CASSETTE_EDGE_HEIGHT / NumberOfHeights) '' / NumberOfHeights because it is added to average
            EndIf
        Next
    EndIf
	
	GTUpdateClient(TASK_DONE_REPORT, MID_LEVEL_FUNCTION, "GTfindAverageCassetteHeight completed. averageHeight=" + Str$(average_height))
	GTfindAverageCassetteHeight = True
Fend
