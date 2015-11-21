#include "mxrobotdefs.inc"
#include "GTCassettedefs.inc"
#include "GTReporterdefs.inc"

Function GTCheckPoint(pointNum As Integer) As Boolean
	GTUpdateClient(TASK_ENTERED_REPORT, LOW_LEVEL_FUNCTION, "GTCheckPoint(P" + Str$(pointNum) + ")")
	If (Not PDef(P(pointNum))) Then
		GTUpdateClient(TASK_FAILURE_REPORT, LOW_LEVEL_FUNCTION, "GTCheckPoint: P" + Str$(pointNum) + " is not defined yet!")
		GTCheckPoint = False
	ElseIf CX(P(pointNum)) = 0 Or CY(P(pointNum)) = 0 Then
		GTUpdateClient(TASK_FAILURE_REPORT, LOW_LEVEL_FUNCTION, "GTCheckPoint: P" + Str$(pointNum) + " has X or Y coordinate set to 0(zero)!")
		GTCheckPoint = False
	Else
		GTUpdateClient(TASK_DONE_REPORT, LOW_LEVEL_FUNCTION, "GTCheckPoint: P" + Str$(pointNum) + " is Valid.")
		GTCheckPoint = True
	EndIf
Fend

Function GTCheckTool(toolNum As Integer) As Boolean
	GTUpdateClient(TASK_ENTERED_REPORT, LOW_LEVEL_FUNCTION, "GTCheckTool(Tool(" + Str$(toolNum) + "))")
	P51 = TLSet(toolNum)
	If CX(P51) = 0 Or CY(P51) = 0 Or CU(P51) = 0 Then
		GTUpdateClient(TASK_FAILURE_REPORT, LOW_LEVEL_FUNCTION, "GTCheckTool: Tool(" + Str$(toolNum) + ") is not defined yet!")
		GTCheckTool = False
	Else
		GTUpdateClient(TASK_DONE_REPORT, LOW_LEVEL_FUNCTION, "GTCheckTool: Tool(" + Str$(toolNum) + ") is Valid.")
		GTCheckTool = True
	EndIf
Fend

Function GTInitBasicPoints() As Boolean
	GTUpdateClient(TASK_ENTERED_REPORT, MID_LEVEL_FUNCTION, "GTInitBasicPoints")
 	'' Check Points P0, P1 and P18
	If GTCheckPoint(0) And GTCheckPoint(1) And GTCheckPoint(18) Then
		GTUpdateClient(TASK_DONE_REPORT, MID_LEVEL_FUNCTION, "GTInitBasicPoints completed.")
		GTInitBasicPoints = True
	Else
		GTUpdateClient(TASK_FAILURE_REPORT, MID_LEVEL_FUNCTION, "GTInitBasicPoints: error in GTCheckPoint!")
		GTInitBasicPoints = False
	EndIf
Fend

Function GTInitMagnetPoints() As Boolean
	GTUpdateClient(TASK_ENTERED_REPORT, MID_LEVEL_FUNCTION, "GTInitMagnetPoints")
	
 	'' Check Points P6, P16 and P26
	If Not (GTCheckPoint(6) Or GTCheckPoint(16) Or GTCheckPoint(26)) Then
		GTUpdateClient(TASK_FAILURE_REPORT, MID_LEVEL_FUNCTION, "GTInitMagnetPoints: error in GTCheckPoint!")
		GTInitMagnetPoints = False
		Exit Function
	EndIf
	
	'' Check Points P10, P11 and P12
	If Not (GTCheckPoint(10) Or GTCheckPoint(11) Or GTCheckPoint(12)) Then
		GTUpdateClient(TASK_FAILURE_REPORT, MID_LEVEL_FUNCTION, "GTInitMagnetPoints: error in GTCheckPoint!")
		GTInitMagnetPoints = False
		Exit Function
	EndIf
	
	'' Check Tool 1 (pickerTool) and Tool 2 (placerTool)
	If Not (GTCheckTool(PICKER_TOOL) Or GTCheckTool(PLACER_TOOL)) Then
		GTUpdateClient(TASK_FAILURE_REPORT, MID_LEVEL_FUNCTION, "GTInitMagnetPoints: error in GTCheckTool!")
		GTInitMagnetPoints = False
		Exit Function
	EndIf
	
	
	'' Above required Points and Tools are defined. Start deriving magnet points
	'' dumbbell Orientation in World Coordinates when dumbbell is on cradle
	g_dumbbell_Perfect_Angle = GTAngleToPerfectOrientationAngle(CU(P6))
	g_dumbbell_Perfect_cosValue = Cos(DegToRad(g_dumbbell_Perfect_Angle))
	g_dumbbell_Perfect_sinValue = Sin(DegToRad(g_dumbbell_Perfect_Angle))
	
	'' Cooling Point: 20mm in the perpendicular direction from center of dumbbell
	P3 = P6 +X(20.0 * -g_dumbbell_Perfect_sinValue) +Y(20.0 * g_dumbbell_Perfect_cosValue)

	'' High Above CoolPoint, get the tong out of LN2
	P2 = P3 :Z(-2)
		
	'' Above Center of dumbbell, middle of cassette height
	P4 = P6 +Z(30.0)
	
	'' Picker Ready Position: 10mm in front of picker
	P17 = P16 +X(10.0 * g_dumbbell_Perfect_cosValue) +Y(10.0 * g_dumbbell_Perfect_sinValue)
	'' Placer Ready Position: 10mm in front of placer
	P27 = P26 -X(10.0 * g_dumbbell_Perfect_cosValue) -Y(10.0 * g_dumbbell_Perfect_sinValue)
	
	'' 35mm in the perpendicular direction from center of picker magnet when dumbbell on cradle
	P93 = P16 +X(35.0 * -g_dumbbell_Perfect_sinValue) +Y(35.0 * g_dumbbell_Perfect_cosValue)
	'' 35mm in the perpendicular direction from center of placer magnet when dumbbell on cradle
	P94 = P26 +X(35.0 * -g_dumbbell_Perfect_sinValue) +Y(35.0 * g_dumbbell_Perfect_cosValue)
	
	
	Real dumbbell_cos_plus_sin, dumbbell_cos_minus_sin
	dumbbell_cos_plus_sin = g_dumbbell_Perfect_cosValue + g_dumbbell_Perfect_sinValue
	dumbbell_cos_minus_sin = g_dumbbell_Perfect_cosValue - g_dumbbell_Perfect_sinValue
	'' Middle point of Arc from cooling point to picker magnet
	P15 = P16 +X(17.5 * dumbbell_cos_minus_sin) +Y(17.5 * dumbbell_cos_plus_sin)
	'' Middle point of Arc from cooling point to placer magnet
	P25 = P26 +X(17.5 * -dumbbell_cos_plus_sin) +Y(17.5 * dumbbell_cos_minus_sin)
	
	
	'' To avoid Tong touching dumbbell head (with 0.5 as additional buffer offset)
	Real tong_dumbbell_gap
	tong_dumbbell_gap = MAGNET_HEAD_RADIUS + CAVITY_RADIUS + 0.5
	P5 = P16 +X(tong_dumbbell_gap * -g_dumbbell_Perfect_sinValue) +Y(tong_dumbbell_gap * g_dumbbell_Perfect_cosValue)
	
	GTUpdateClient(TASK_DONE_REPORT, MID_LEVEL_FUNCTION, "GTInitMagnetPoints completed.")
	GTInitMagnetPoints = True
Fend

Function GTInitCassettePoints() As Boolean
	GTUpdateClient(TASK_ENTERED_REPORT, MID_LEVEL_FUNCTION, "GTInitCassettePoints")
	
 	'' Check Point P6: dumbbell cradle needed to decided cassette orientation
	If Not GTCheckPoint(6) Then
		GTUpdateClient(TASK_FAILURE_REPORT, MID_LEVEL_FUNCTION, "GTInitCassettePoints: error in GTCheckPoint!")
		GTInitCassettePoints = False
		Exit Function
	EndIf
	
	'' Check Left Cassette Points P34, P41 and P44
	If Not (GTCheckPoint(34) Or GTCheckPoint(41) Or GTCheckPoint(44)) Then
		GTUpdateClient(TASK_FAILURE_REPORT, MID_LEVEL_FUNCTION, "GTInitCassettePoints: error in GTCheckPoint!")
		GTInitCassettePoints = False
		Exit Function
	EndIf
	
	'' Check Middle Cassette Points P35, P42 and P45
	If Not (GTCheckPoint(35) Or GTCheckPoint(42) Or GTCheckPoint(45)) Then
		GTUpdateClient(TASK_FAILURE_REPORT, MID_LEVEL_FUNCTION, "GTInitCassettePoints: error in GTCheckPoint!")
		GTInitCassettePoints = False
		Exit Function
	EndIf
	
	'' Check Right Cassette Points P36, P43 and P46
	If Not (GTCheckPoint(36) Or GTCheckPoint(43) Or GTCheckPoint(46)) Then
		GTUpdateClient(TASK_FAILURE_REPORT, MID_LEVEL_FUNCTION, "GTInitCassettePoints: error in GTCheckPoint!")
		GTInitCassettePoints = False
		Exit Function
	EndIf

	'' Setup location and required angles for each cassette
	If Not (GTSetupCassetteAllProperties(LEFT_CASSETTE) Or GTSetupCassetteAllProperties(MIDDLE_CASSETTE) Or GTSetupCassetteAllProperties(RIGHT_CASSETTE)) Then
		GTUpdateClient(TASK_FAILURE_REPORT, MID_LEVEL_FUNCTION, "GTInitCassettePoints: error in GTSetupCassetteAllProperties!")
		GTInitCassettePoints = False
		Exit Function
	EndIf
	
	GTUpdateClient(TASK_DONE_REPORT, MID_LEVEL_FUNCTION, "GTInitCassettePoints completed.")
	GTInitCassettePoints = True
Fend

Function GTInitAllPoints() As Boolean
	GTUpdateClient(TASK_ENTERED_REPORT, HIGH_LEVEL_FUNCTION, "GTInitAllPoints")

	g_RunResult$ = "Progress GTInitAllPoints->GTInitBasicPoints"
	If Not GTInitBasicPoints() Then
		g_RunResult$ = "Error GTInitBasicPoints"
		GTUpdateClient(TASK_FAILURE_REPORT, HIGH_LEVEL_FUNCTION, "GTInitAllPoints: error in GTInitBasicPoints!")
		GTInitAllPoints = False
		Exit Function
	EndIf
	
	g_RunResult$ = "Progress GTInitAllPoints->GTInitMagnetPoints"
	If Not GTInitMagnetPoints() Then
		g_RunResult$ = "Error GTInitMagnetPoints"
		GTUpdateClient(TASK_FAILURE_REPORT, HIGH_LEVEL_FUNCTION, "GTInitAllPoints: error in GTInitMagnetPoints!")
		GTInitAllPoints = False
		Exit Function
	EndIf
	
	g_RunResult$ = "Progress GTInitAllPoints->GTInitCassettePoints"
	If Not GTInitCassettePoints() Then
		g_RunResult$ = "Error GTInitCassettePoints"
		GTUpdateClient(TASK_FAILURE_REPORT, HIGH_LEVEL_FUNCTION, "GTInitAllPoints: error in GTInitCassettePoints!")
		GTInitAllPoints = False
		Exit Function
	EndIf
	
	g_RunResult$ = "Success GTInitAllPoints"
	GTUpdateClient(TASK_DONE_REPORT, HIGH_LEVEL_FUNCTION, "GTInitAllPoints completed.")
	GTInitAllPoints = True
Fend
