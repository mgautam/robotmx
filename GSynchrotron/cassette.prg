#include "networkdefs.inc"
#include "mxrobotdefs.inc"
#include "forcedefs.inc"

''================================
'' module variable
''================================
Boolean m_IsCalibrationCassette

''LOCAL variables
''cassette XY
Real CXYTouch(4, 2)
Real CXYDirection
Real CXYNewX
Real CXYNewY
Integer CXYIndex
Integer CXYTouchDirection
Integer CXYStepStart
Integer CXYStepTotal
Real CXYRadius
String CCName$

''cassette Z
Real CCZTouch(4)
Real CCZPlacerZ
Real CCZCassetteHeight
Integer CCZIndex
Integer CCZStepStart
Integer CCZStepTotal

''cassette angle
Real CCATouch(4, 2) ''4 points (X, Y)
Real AFromYEdge
Real AFromXEdge
Integer CCAIndex

Integer CCAStepStart
Integer CCAStepTotal


''normal cassette angle
Real CCAInDeg
Real CCAInRad
Real CCACos
Real CCASin
Real CCAOldZ
Real CCANewZ

''cassette calibration
Real CenterX
Real CenterY
Real BottomZ
Real Angle
Real desiredZ
Integer CCXYIndex
Integer cassette
Integer CSTIndex
Integer CCTotalCAS
String OneCassette$
Real CCTempX(3)
Real CCTempY(3)
Real CCDeltaCenter
Integer TopPoint
Integer BottomPoint
Boolean AngleResult
Real CCTilt
String Cassette_Warning$

Integer CassetteOrientation

''VB_CassetteCAL
Boolean VBCCInit
String VBCCTokens$(0)
Integer VBCCArgC

''temp
Real tmp_Real
Real tmp_Real2
Real tmp_DX
Real tmp_DY
Real tmp_DZ

''we will touch from 4 sides, along x and y axes, so orientation does not matter
Function CassetteXY() As Boolean
	String msg$

    CassetteXY = False
    CXYStepStart = g_CurrentSteps
    CXYStepTotal = g_Steps

    ''touch the cassette from all 4 direction
    Print "CentreX = ", CenterX
    Print "CentreY = ", CenterY
    Print "DesiredZ = ", desiredZ
    P51 = XY((CenterX - CASSETTE_STANDBY_DISTANCE), CenterY, desiredZ, 0)

    ''use picker head
    If Tool = 0 Then
        Tool 1
    EndIf

    If Tool = 1 Then
        CXYTouchDirection = DIRECTION_CAVITY_HEAD
    Else
        CXYTouchDirection = DIRECTION_CAVITY_TAIL
    EndIf
    
    SetFastSpeed
    
    ''ensure LimZ high enough to clear the cassette
    If (BottomZ + 142) > g_Jump_LimZ_LN2 Then
    	Print "g_Jump_LimZ_LN2 is set lower than cassette top height.  Please increase g_Jump_LimZ_LN2"
    	Print "g_Jump_LimZ_LN2 is:", g_Jump_LimZ_LN2
    	Print "Cassette Top is:", BottomZ + 142
    	Exit Function
    EndIf
    
    LimZ g_Jump_LimZ_LN2
    ''Print "CassetteOrientation needs to be 1 (Righty) and it is =", CassetteOrientation
   	''Hand P51, CassetteOrientation
 	Jump P51
    
    For CXYIndex = 1 To 4
        g_CurrentSteps = CXYStepStart + (CXYIndex - 1) * CXYStepTotal / 4
        g_Steps = CXYStepTotal /4
        
        If CXYIndex > 1 Then
        	''update interested clients
        	msg$ = Str$(g_CurrentSteps) + " of 100"
        	UpdateClient(EVTNO_CAL_STEP, msg$)
        EndIf
        
        SetVerySlowSpeed
        Wait TIME_WAIT_BEFORE_RESET
		If Not ForceCalibrateAndCheck(LOW_SENSITIVITY, LOW_SENSITIVITY) Then
			g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_CASSETTE
			g_RunResult$ = "force sensor reset failed at CassetteXY"
			Print g_RunResult$
			''update interested clients
			UpdateClient(EVTNO_CAL_MSG, g_RunResult$)
			''SPELCom_Return 1
			Exit Function
		EndIf
        If Not ForceTouch(CXYTouchDirection, CASSETTE_STANDBY_DISTANCE / 2, True) Then
            Print "Failed to touch cassette in XY"
            Print "Maybe there is no cassette"
            Exit Function
        EndIf
        CXYTouch(CXYIndex, 1) = CX(Here)
        CXYTouch(CXYIndex, 2) = CY(Here)
        
        SetFastSpeed
        Move P51

        ''arc to next point        
        If CXYIndex < 4 Then
            CXYDirection = DegToRad(90 * (CXYIndex + 2))
            P51 = XY((CenterX + CASSETTE_STANDBY_DISTANCE * Cos(CXYDirection)), (CenterY + CASSETTE_STANDBY_DISTANCE * Sin(CXYDirection)), desiredZ, (CU(Here) + 90))

            CXYDirection = DegToRad(90 * (CXYIndex + 1.5))
            P52 = XY((CenterX + CASSETTE_STANDBY_DISTANCE * Cos(CXYDirection)), (CenterY + CASSETTE_STANDBY_DISTANCE * Sin(CXYDirection)), desiredZ, (CU(Here) + 45))
            Hand P51, CassetteOrientation
            Hand P52, CassetteOrientation
            Arc P52, P51
        Else
        	''arc back to standby position to avoid jam the cables on robot top
        	''this P51 is the same at the beginning of this function.
		    P51 = XY((CenterX - CASSETTE_STANDBY_DISTANCE), CenterY, desiredZ, 0)

            CXYDirection = DegToRad(90 * 3.5)
            P52 = XY((CenterX + CASSETTE_STANDBY_DISTANCE * Cos(CXYDirection)), (CenterY + CASSETTE_STANDBY_DISTANCE * Sin(CXYDirection)), desiredZ, (CU(Here) - 135))
            Hand P51, CassetteOrientation
            Hand P52, CassetteOrientation
            Arc P52, P51
        EndIf
    Next
    ''calculate
    CXYNewX = (CXYTouch(1, 1) + CXYTouch(3, 1)) /2
    CXYNewY = (CXYTouch(2, 2) + CXYTouch(4, 2)) /2
    
    Print "center moved from (", CenterX, ", ", CenterY, ") to (", CXYNewX, ", ", CXYNewY, ")"
    CenterX = CXYNewX
    CenterY = CXYNewY
    
    If g_LN2LevelHigh Then
        CXYRadius = CASSETTE_RADIUS * CASSETTE_SHRINK_IN_LN2
    Else
        CXYRadius = CASSETTE_RADIUS
    EndIf
    
    For CXYIndex = 1 To 4
        CXYNewX = CXYTouch(CXYIndex, 1) - CenterX
        CXYNewY = CXYTouch(CXYIndex, 2) - CenterY
        CXYNewX = Sqr(CXYNewX * CXYNewX + CXYNewY * CXYNewY)
        Print "touch point[", CXYIndex, "] to center distance=", CXYNewX
        If Abs(CXYNewX - CXYRadius) > 1 Then
            g_RunResult$ = "cassette cal: failed, toolset calibration is way too off"
            ''update client
            UpdateClient(EVTNO_CAL_MSG, g_RunResult$)
            UpdateClient(EVTNO_LOG_ERROR, g_RunResult$)
            Print g_RunResult$
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_MAGNET
            g_RobotStatus = g_RobotStatus Or FLAG_REASON_TOLERANCE
            CassetteXY = False
            Exit Function
        EndIf
    Next
    
    CassetteXY = True
Fend

''we need to touch top as following A, D, G, J
Function CassetteZ() As Boolean
	String msg$
    CassetteZ = False
    CCZStepStart = g_CurrentSteps
    CCZStepTotal = g_Steps
        
    Tool 1
    For CCZIndex = 1 To 4
        ''update progress bar
        g_CurrentSteps = CCZStepStart + (CCZIndex - 1) * CCZStepTotal / 4
        g_Steps = CCZStepTotal /4
        If CCZIndex > 1 Then
        	msg$ = Str$(g_CurrentSteps) + " of 100"
        	UpdateClient(EVTNO_CAL_STEP, msg$)
        EndIf
        
        ''define where we will go
        ''first point is around column A, second column D, then G, last J
        tmp_Real = DegToRad(g_Perfect_Cassette_Angle + 90 * (CCZIndex - 1))
        tmp_Real2 = CASSETTE_RADIUS - OVER_LAP_FOR_Z_TOUCH
        tmp_DX = tmp_Real2 * Cos(tmp_Real)
        tmp_DY = tmp_Real2 * Sin(tmp_Real)
        
        ''now tmp_Real is for U, here +45 is for make more clearance for the dumbbell head
        tmp_Real = g_Perfect_Cassette_Angle - 180 + 45 + 90 * (CCZIndex - 1)
       	P60 = XY((CenterX + tmp_DX), (CenterY + tmp_DY), (BottomZ + CASSETTE_HEIGHT / 2), tmp_Real)
        Hand P60, CassetteOrientation

        ''go above
        SetFastSpeed
        If CCZIndex = 1 Then
            ''first one, big buffer 20 mm
            Jump P60 :Z(BottomZ + CASSETTE_CAL_HEIGHT + MAGNET_HEAD_RADIUS + 20)
        Else
            LimZ CCZTouch(1) + 20
   	        Jump P60 :Z(CCZTouch(1) + 5)
        EndIf

        ''touch
        SetVerySlowSpeed
        Wait TIME_WAIT_BEFORE_RESET
		If Not ForceCalibrateAndCheck(LOW_SENSITIVITY, LOW_SENSITIVITY) Then
			g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_CASSETTE
			g_RunResult$ = "force sensor reset failed at CassetteZ"
			Print g_RunResult$

			UpdateClient(EVTNO_CAL_MSG, g_RunResult$)
			''SPELCom_Return 1
			Exit Function
		EndIf

        If Not ForceTouch(-FORCE_ZFORCE, CASSETTE_HEIGHT / 2 + MAGNET_HEAD_RADIUS + 20, True) Then
            Print "Failed to touch cassette top by picker at i =", CCZIndex
            Exit Function
        EndIf
        
        CCZTouch(CCZIndex) = CZ(Here)
        Print "picker touch at Z=", CZ(Here)
        Print #LOG_FILE_NO, "picker touched at (", CX(Here), ", ", CY(Here), ", ", CZ(Here), ")"
    Next
    CassetteZ = True
    
    Print "Z touched at ", CCZTouch(1), ", ", CCZTouch(2), ", ", CCZTouch(3), ", ", CCZTouch(4)
    Print #LOG_FILE_NO, "Z touched at ", CCZTouch(1), ", ", CCZTouch(2), ", ", CCZTouch(3), ", ", CCZTouch(4)

    ''check whether this is a calibration cassette
    If Abs(CCZTouch(2) - CCZTouch(1)) > (CASSETTE_EDGE_HEIGHT / 2) Then
        If g_LN2LevelHigh Then
            BottomZ = (CCZTouch(1) + CCZTouch(2) + CCZTouch(3) + CCZTouch(4) + 2 * CASSETTE_SHRINK_IN_LN2 * CASSETTE_EDGE_HEIGHT) / 4
        Else
            BottomZ = (CCZTouch(1) + CCZTouch(2) + CCZTouch(3) + CCZTouch(4) + 2 * CASSETTE_EDGE_HEIGHT) / 4
        EndIf
        CCZCassetteHeight = CASSETTE_CAL_HEIGHT
        m_IsCalibrationCassette = True
        Print #LOG_FILE_NO, "calibration cassette"
    Else
        BottomZ = (CCZTouch(1) + CCZTouch(2) + CCZTouch(3) + CCZTouch(4)) /4
        CCZCassetteHeight = CASSETTE_HEIGHT
        m_IsCalibrationCassette = False
        Print #LOG_FILE_NO, "normal cassette"
    EndIf
    Print #LOG_FILE_NO, "average=", BottomZ
    Print "average=", BottomZ
    
    If g_LN2LevelHigh Then
        BottomZ = BottomZ - CASSETTE_SHRINK_IN_LN2 * CCZCassetteHeight - MAGNET_HEAD_RADIUS
    Else
        BottomZ = BottomZ - CCZCassetteHeight - MAGNET_HEAD_RADIUS
    EndIf
Fend

Function CalCassetteAngle(ByVal cutOutZ As Real) As Boolean
    String msg$
    CalCassetteAngle = False

    CCAStepStart = g_CurrentSteps
    CCAStepTotal = g_Steps

    Tool 1
    For CCAIndex = 1 To 4
        ''update progress bar
        g_CurrentSteps = CCAStepStart + (CCAIndex - 1) * CCAStepTotal / 4
        g_Steps = CCAStepTotal /4
        If CCAIndex > 1 Then
        	msg$ = Str$(g_CurrentSteps) + " of 100"
        	UpdateClient(EVTNO_CAL_STEP, msg$)
        EndIf

        ''move to standby point
        ''35 here is something bigger than CASSETTE_EDGE_DISTANCE = 23.5
        SetFastSpeed

        Select CCAIndex
        Case 1
        	tmp_Real = DegToRad(g_Perfect_Cassette_Angle + 180)
        	tmp_DX = 35 * Cos(tmp_Real)
        	tmp_DY = 35 * Sin(tmp_Real)
        	tmp_Real2 = DegToRad(g_Perfect_Cassette_Angle - 90)
        	tmp_DX = tmp_DX + 15 * Cos(tmp_Real2)
        	tmp_DY = tmp_DY + 15 * Sin(tmp_Real2)
        	
        	''U
        	tmp_Real = g_Perfect_Cassette_Angle
        	P60 = XY((CenterX + tmp_DX), (CenterY + tmp_DY), cutOutZ, tmp_Real)
			Hand P60, CassetteOrientation
			
            Jump P60
        Case 2
        	tmp_Real = DegToRad(g_Perfect_Cassette_Angle + 180)
        	tmp_DX = 30 * Cos(tmp_Real)
        	tmp_DY = 30 * Sin(tmp_Real)
        	tmp_Real2 = DegToRad(g_Perfect_Cassette_Angle + 90)
        	tmp_DX = tmp_DX + 15 * Cos(tmp_Real2)
        	tmp_DY = tmp_DY + 15 * Sin(tmp_Real2)
        	
        	''U
        	tmp_Real = g_Perfect_Cassette_Angle
        	P60 = XY((CenterX + tmp_DX), (CenterY + tmp_DY), cutOutZ, tmp_Real)
			Hand P60, CassetteOrientation

            Move P60
        Case 3
        	tmp_Real = DegToRad(g_Perfect_Cassette_Angle + 90)
        	tmp_DX = 35 * Cos(tmp_Real)
        	tmp_DY = 35 * Sin(tmp_Real)
        	tmp_Real2 = DegToRad(g_Perfect_Cassette_Angle + 180)
        	tmp_DX = tmp_DX + 15 * Cos(tmp_Real2)
        	tmp_DY = tmp_DY + 15 * Sin(tmp_Real2)
        	
        	''U
        	tmp_Real = g_Perfect_Cassette_Angle - 90
        	P60 = XY((CenterX + tmp_DX), (CenterY + tmp_DY), cutOutZ, tmp_Real)
			Hand P60, CassetteOrientation
            LimZ (cutOutZ + 30)

            Jump P60
            LimZ g_Jump_LimZ_LN2
        Case 4
        	tmp_Real = DegToRad(g_Perfect_Cassette_Angle + 90)
        	tmp_DX = 35 * Cos(tmp_Real)
        	tmp_DY = 35 * Sin(tmp_Real)
        	tmp_Real2 = DegToRad(g_Perfect_Cassette_Angle)
        	tmp_DX = tmp_DX + 15 * Cos(tmp_Real2)
        	tmp_DY = tmp_DY + 15 * Sin(tmp_Real2)
        	
        	''U
        	tmp_Real = g_Perfect_Cassette_Angle - 90
        	P60 = XY((CenterX + tmp_DX), (CenterY + tmp_DY), cutOutZ, tmp_Real)
			Hand P60, CassetteOrientation
            Move P60
        Send
        
        ''touch it
        SetVerySlowSpeed
        Wait TIME_WAIT_BEFORE_RESET
		If Not ForceCalibrateAndCheck(LOW_SENSITIVITY, LOW_SENSITIVITY) Then
			g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_CASSETTE
			g_RunResult$ = "force sensor reset failed at CassetteAngle"
			Print g_RunResult$
			UpdateClient(EVTNO_CAL_MSG, g_RunResult$)
			Exit Function
		EndIf

        If Not ForceTouch(DIRECTION_CAVITY_HEAD, 20, True) Then
            Print "failed to touch edge at ", CCAIndex
            Exit Function
        EndIf
        
        Print "Touched edge at (", CX(Here), ", ", CY(Here), ")"
        Print #LOG_FILE_NO, "Touched edge at (", CX(Here), ", ", CY(Here), ")"
        CCATouch(CCAIndex, 1) = CX(Here)
        CCATouch(CCAIndex, 2) = CY(Here)
        
        ''move back to standby point
        SetFastSpeed
        Move P60
    Next
    CalCassetteAngle = True
    
    CCAIndex = Int(Abs(g_Perfect_Cassette_Angle)) Mod 180
    
    If CCAIndex = 90 Then
    	AFromYEdge = (CCATouch(2, 2) - CCATouch(1, 2)) /(CCATouch(2, 1) - CCATouch(1, 1))
    	AFromYEdge = Atan(AFromYEdge)
    	AFromYEdge = RadToDeg(AFromYEdge)
    	
	    AFromXEdge = (CCATouch(4, 1) - CCATouch(3, 1)) /(CCATouch(4, 2) - CCATouch(3, 2))
    	AFromXEdge = Atan(AFromXEdge)
    	AFromXEdge = 0 - RadToDeg(AFromXEdge)
    ElseIf CCAIndex = 0 Then
	    AFromYEdge = (CCATouch(2, 1) - CCATouch(1, 1)) /(CCATouch(2, 2) - CCATouch(1, 2))
    	AFromYEdge = Atan(AFromYEdge)
    	AFromYEdge = 0 - RadToDeg(AFromYEdge)
    
    	AFromXEdge = (CCATouch(4, 2) - CCATouch(3, 2)) /(CCATouch(4, 1) - CCATouch(3, 1))
    	AFromXEdge = Atan(AFromXEdge)
    	AFromXEdge = RadToDeg(AFromXEdge)
    Else
        g_RunResult$ = "cassette cal: failed, cassette must be along one of axes"
        UpdateClient(EVTNO_CAL_MSG, g_RunResult$)
        Print g_RunResult$
        Print #LOG_FILE_NO, g_RunResult$
        Close #LOG_FILE_NO
        Quit All
    EndIf
        
    Print "angle from horizontal edge =", AFromYEdge
    Print "angle from vertical edge =", AFromXEdge
    Print #LOG_FILE_NO, "angle from horizontal edge =", AFromYEdge
    Print #LOG_FILE_NO, "angle from vertical edge =", AFromXEdge

    Angle = (AFromXEdge + AFromYEdge) /2
    Print "final Angle =", angle
    Print #LOG_FILE_NO, "final Angle =", angle
Fend

''normal cassette used in calibration, we will probe port A1 to find the angle
Function NorCassetteAngle(ByVal XCenter As Real, ByVal YCentre As Real) As Boolean
	String msg$
	
    CCAStepStart = g_CurrentSteps
    CCAStepTotal = g_Steps

    NorCassetteAngle = False
    ''got standby position for port A1
    CCAInDeg = g_Perfect_Cassette_Angle + angle
    CCAInRad = DegToRad(CCAInDeg)
    CCACos = Cos(CCAInRad)
    CCASin = Sin(CCAInRad)
    If g_LN2LevelHigh Then
        CCAOldZ = BottomZ + CASSETTE_SHRINK_IN_LN2 * CASSETTE_A1_HEIGHT
    Else
        CCAOldZ = BottomZ + CASSETTE_A1_HEIGHT
    EndIf
    
    ''magnet points into center not from center
    CCAInDeg = CCAInDeg + 180
   
    P52 = XY((XCenter + (CASSETTE_RADIUS + SAFE_BUFFER_FOR_DETACH) * CCACos), (YCentre + (CASSETTE_RADIUS + SAFE_BUFFER_FOR_DETACH) * CCASin), CCAOldZ, CCAInDeg)
    P53 = XY((XCenter + (CASSETTE_RADIUS - 4) * CCACos), (YCentre + (CASSETTE_RADIUS - 4) * CCASin), CCAOldZ, CCAInDeg)
	Hand P52, CassetteOrientation
	Hand P53, CassetteOrientation
	
    ''setup new parameters for cut middle
    For CCAIndex = 1 To 2
        ''update progress bar
        g_CurrentSteps = CCAStepStart + (CCAIndex - 1) * CCAStepTotal / 2
        g_Steps = CCAStepTotal /2
        If CCAIndex > 1 Then
        	msg$ = Str$(g_CurrentSteps) + " of 100"
        	UpdateClient(EVTNO_CAL_STEP, msg$)
        EndIf

        SetFastSpeed
        Tool CCAIndex
        Jump P52
        SetVerySlowSpeed
        Wait TIME_WAIT_BEFORE_RESET
		If Not ForceCalibrateAndCheck(LOW_SENSITIVITY, LOW_SENSITIVITY) Then
			g_RobotStatus = g_RobotStatus Or FLAG_NEED_CAL_CASSETTE
			g_RunResult$ = "force sensor reset failed at normal Cassette Angle"
			Print g_RunResult$
			UpdateClient(EVTNO_CAL_MSG, g_RunResult$)
			
			''SPELCom_Return 1
			Exit Function
		EndIf
        Move P53
        Print #LOG_FILE_NO, "start at A1:(", CX(Here), ", ", CY(Here), ", ", CZ(Here), ", ", CU(Here), ")"
    
        ''find Y    
        If Not g_FlagAbort Then
            CutMiddleWithArguments FORCE_YTORQUE, 0, GetForceThreshold(FORCE_YTORQUE), 6, 12
            Print #LOG_FILE_NO, "after cut middle for Y (", CX(Here), ", ", CY(Here), ", ", CZ(Here), ", ", CU(Here), ")"
    
            ''calculate new angle and adjust our U
            CCAInRad = Atan((CY(Here) - YCentre) / (CX(Here) - XCenter))
            Select CCAIndex
            Case 1
                AFromYEdge = RadToDeg(CCAInRad)
                Print #LOG_FILE_NO, "new angle from picker:", AFromYEdge
            Case 2
                AFromXEdge = RadToDeg(CCAInRad)
                Print #LOG_FILE_NO, "new angle from placer:", AFromXEdge
            Send
        EndIf
        SetFastSpeed
        Move P52
    Next
    Angle = (AFromYEdge + AFromXEdge) /2
    NorCassetteAngle = True
Fend
Function CassetteCalibration(ByVal cassettes$ As String, Init As Boolean) As Boolean
	String msg$

    CassetteCalibration = False
    g_SafeToGoHome = False

    InitForceConstants
    
    ''are the global variables setup for Australian Synchrotron
	''Did the force sensor initialize ok 
	If Not CheckEnvironment Then
		''it is not safe to proceed
		Exit Function
	EndIf
    
    g_OnlyAlongAxis = True
	
	msg$ = "Cassette calibration at " + Date$ + " " + Time$
	UpdateClient(EVTNO_PRINT_EVENT, msg$)
	
    ''log file
    g_FCntCassette = g_FCntCassette + 1
    WOpen "CassetteCal" + Str$(g_FCntCassette) + ".Txt" As #LOG_FILE_NO
    Print #LOG_FILE_NO, "======================================================="
    Print #LOG_FILE_NO, "Cassette calibration at ", Date$, " ", Time$

    cassettes$ = LTrim$(cassettes$)
    cassettes$ = RTrim$(cassettes$)
    CCTotalCAS = Len(cassettes$)

    If (CCTotalCAS < 1) Or (CCTotalCAS > 3) Then
        g_RunResult$ = "Bad first arg, string length is not [1-3]"
        Print g_RunResult$
        Print #LOG_FILE_NO, g_RunResult$
        Print #LOG_FILE_NO, "arg[1]=[", cassettes$, "]"
        Close #LOG_FILE_NO
        
        ''SPELCom_Return 1
        Exit Function
    EndIf

    If (CCTotalCAS > 1) And Init Then
        g_RunResult$ = "Bad input, Init=true only apply with 1 cassette"
        Print g_RunResult$
        Print #LOG_FILE_NO, g_RunResult$
        Close #LOG_FILE_NO
        
        ''SPELCom_Return 2
        Exit Function
    EndIf
    
    ''check input
    For CSTIndex = 1 To CCTotalCAS
        OneCassette$ = Mid$(cassettes$, CSTIndex, 1)
        Select OneCassette$
#ifndef LEFT_CASSETTE_NOT_EXIST
			Case "l"
;
#endif
#ifndef MIDDLE_CASSETTE_NOT_EXIST
			Case "m"
;
#endif
#ifndef RIGHT_CASSETTE_NOT_EXIST
			Case "r"
;
#endif
			Default
				g_RunResult$ = "Bad input for one cassette, should be one of rlm"
				Print g_RunResult$
				Print #LOG_FILE_NO, g_RunResult$
				Print #LOG_FILE_NO, "index=", CSTIndex, ", cassette letter=", OneCassette$
				Close #LOG_FILE_NO
	            
				''SPELCom_Return 3
				Exit Function
        Send
    Next
    
    UpdateClient(EVTNO_CAL_STEP, "0 of 100")
    
    If Motor = Off Then
        Motor On
    EndIf
    If Power = 1 Then
        Power Low
    EndIf


    ''do it
    If Not Init Then
        UpdateClient(EVTNO_CAL_MSG, "cassette cal: take magnet")
        g_SafeToGoHome = True
        If Not FromHomeToTakeMagnet Then
        
            g_RunResult$ = "FromHomeToTakeMagnet failed " + g_RunResult$
            Print g_RunResult$
            Print #LOG_FILE_NO, g_RunResult$
            Close #LOG_FILE_NO
            
            ''SPELCom_Return 4
            Exit Function
        EndIf

        If g_FlagAbort Then
            UpdateClient(EVTNO_CAL_MSG, "cassette cal: user abort")
            g_RunResult$ = "user abort"
            Print g_RunResult$
            Print #LOG_FILE_NO, g_RunResult$
            Close #LOG_FILE_NO
            
            ''SPELCom_Return 4
            Exit Function
        EndIf
    Else
        ''we are sitting at the center top of the cassette
        g_HoldMagnet = True
        Tool 1
        CenterX = CX(Here)
        CenterY = CY(Here)
        BottomZ = CZ(Here) - 142
        angle = 0
    EndIf

    LimZ -100

    Cassette_Warning$ = ""
    For CSTIndex = 1 To CCTotalCAS
        OneCassette$ = Mid$(cassettes$, CSTIndex, 1)
        Select OneCassette$
        Case "l"
			CCName$ = "left cassette"
        Case "m"
			CCName$ = "middle cassette"
        Case "r"
			CCName$ = "right cassette"
        Send

        If Init Then
	        Print #LOG_FILE_NO, CCName$, "inital calibration"
        Else
	        Print #LOG_FILE_NO, CCName$, "calibration"
        EndIf
    
        CheckToolSet 1
        P51 = TLSet(1)
        If CX(P51) = 0 Or CY(P51) = 0 Then
            Print "Must calibrate toolset before cassette calibration"
            Print #LOG_FILE_NO, "Must calibrate toolset before cassette calibration"
            Close #LOG_FILE_NO
            
            Exit Function
        EndIf
            
        Select OneCassette$
        Case "l"
            BottomPoint = 41
            TopPoint = 44
            g_Perfect_Cassette_Angle = g_Perfect_LeftCassette_Angle
        Case "m"
            BottomPoint = 42
            TopPoint = 45
            g_Perfect_Cassette_Angle = g_Perfect_MiddleCassette_Angle
        Case "r"
            BottomPoint = 43
            TopPoint = 46
            g_Perfect_Cassette_Angle = g_Perfect_RightCassette_Angle
        Send
        
        ''when init set to righty as default, when not init we override anyhow
        CassetteOrientation = Righty

        If Not Init Then
            Select OneCassette$
            Case "l"
                CheckPoint 34
                CheckPoint 41
                CheckPoint 44
                
                CenterX = CX(P34)
                CenterY = CY(P34)
                BottomZ = CZ(P34)
                angle = CU(P34)
                CassetteOrientation = Hand(P34)
            Case "m"
                CheckPoint 35
                CheckPoint 42
                CheckPoint 45
                CenterX = CX(P35)
                CenterY = CY(P35)
                BottomZ = CZ(P35)
                angle = CU(P35)
                CassetteOrientation = Hand(P35)
            Case "r"
                CheckPoint 36
                CheckPoint 43
                CheckPoint 46
                CenterX = CX(P36)
                CenterY = CY(P36)
                BottomZ = CZ(P36)
                angle = CU(P36)
                CassetteOrientation = Hand(P36)
            Default
                Close #LOG_FILE_NO
                
                ''SPELCom_Return 22
                Exit Function
            Send

            Print "Old position (", CenterX, ", ", CenterY, ", ", BottomZ, ", ", angle, ")"
            Print #LOG_FILE_NO, "Old position (", CenterX, ", ", CenterY, ", ", BottomZ, ", ", angle, ")"

			msg$ = "Old position (" + Str$(CenterX) + ", " + Str$(CenterY) + ", " + Str$(BottomZ) + ", " + Str$(angle) + ")"
			UpdateClient(EVTNO_UPDATE, msg$)
            Print "old Bottom (", CX(P(BottomPoint)), ", ", CY(P(BottomPoint)), ", ", CZ(P(BottomPoint)), ")"
            Print "old Top (", CX(P(TopPoint)), ", ", CY(P(TopPoint)), ", ", CZ(P(TopPoint)), ")"
            Print #LOG_FILE_NO, "Old Bottom (", CX(P(BottomPoint)), ", ", CY(P(BottomPoint)), ", ", CZ(P(BottomPoint)), ")"
            Print #LOG_FILE_NO, "old Top (", CX(P(TopPoint)), ", ", CY(P(TopPoint)), ", ", CZ(P(TopPoint)), ")"
        EndIf


        g_Steps = 60 / CCTotalCAS
        g_CurrentSteps = (100 * CSTIndex - 100) / CCTotalCAS
        msg$ = Str$(g_CurrentSteps) + " of 100"
        UpdateClient(EVTNO_CAL_STEP, msg$)
        For CCXYIndex = 1 To 3
            g_Steps = 20 / CCTotalCAS
            g_CurrentSteps = (100 * CSTIndex + CCXYIndex * 20 - 120) / CCTotalCAS
            msg$ = Str$(g_CurrentSteps) + " of 100"
            UpdateClient(EVTNO_CAL_STEP, msg$)
            Select CCXYIndex
                Case 1
                    msg$ = "cassette cal: touch bottom center of " + CCName$
                    UpdateClient(EVTNO_CAL_MSG, msg$)
                    desiredZ = BottomZ + 12 + 15 / 2
                    Tool 2
                Case 2
                    msg$ = "cassette cal: touch top center of " + CCName$
                    UpdateClient(EVTNO_CAL_MSG, msg$)
                    desiredZ = BottomZ + CASSETTE_A1_HEIGHT + 15 / 2
                    Tool 2
                Case 3
                    msg$ = "cassette cal: touch middle center of " + CCName$
                    UpdateClient(EVTNO_CAL_MSG, msg$)
                    desiredZ = BottomZ + CASSETTE_HEIGHT /2
                    Tool 2
            Send
            If Not CassetteXY() Then
                g_RunResult$ = "Failed: maybe there is no cassette"
                Print g_RunResult$
                Print #LOG_FILE_NO, g_RunResult$
                Close #LOG_FILE_NO
                
                ''SPELCom_Return 4
                Exit Function
            EndIf
            CCTempX(CCXYIndex) = CenterX
            CCTempY(CCXYIndex) = CenterY
            Print "Center (Z=", desiredZ, ") XY position (", CenterX, ", ", CenterY, ")"
            Print #LOG_FILE_NO, "Center (Z=", desiredZ, ") XY position (", CenterX, ", ", CenterY, ")"
            msg$ = "Center (Z=" + Str$(desiredZ) + ") XY position (" + Str$(CenterX) + ", " + Str$(CenterY) + ")"
            UpdateClient(EVTNO_UPDATE, msg$)
            Select CCXYIndex
                Case 1
                    If BottomPoint > 0 Then
                        P(BottomPoint) = XY(CenterX, CenterY, desiredZ, 0)
                        Print "CassetteCal BottomPoint"
                        Print "CentreX=", CenterX
                        Print "CentreY=", CenterY
                        Print "desiredZ=", desiredZ
                        Print P(BottomPoint)
                        Print "Tool=", Tool
                        SavePointHistory BottomPoint, g_FCntCassette
                    EndIf
                Case 2
                    If TopPoint > 0 Then
                        P(TopPoint) = XY(CenterX, CenterY, desiredZ, 0)
                        Print "CassetteCal TopPoint"
                        Print "CentreX=", CenterX
                        Print "CentreY=", CenterY
                        Print "desiredZ=", desiredZ
                        Print P(TopPoint)
                        Print "Tool=", Tool
                        SavePointHistory TopPoint, g_FCntCassette
                    EndIf
                    ''calculate the distance between bottom center and top center
                    CCTempX(1) = CCTempX(1) - CCTempX(2)
                    CCTempY(1) = CCTempY(1) - CCTempY(2)
                    CCDeltaCenter = Sqr(CCTempX(1) * CCTempX(1) + CCTempY(1) * CCTempY(1))
                    Print "distance between center of top row and bottomt row: ", CCDeltaCenter
                    Print #LOG_FILE_NO, "distance between center of top row and bottomt row: ", CCDeltaCenter
                    msg$ = "distance between center of top row and bottomt row: " + Str$(CCDeltaCenter)
                    UpdateClient(EVTNO_UPDATE, msg$)
                    CCTilt = CCDeltaCenter /(CASSETTE_A1_HEIGHT - 12)
                    CCTilt = Atan(CCTilt)
                    CCTilt = RadToDeg(CCTilt)
                    If CCTilt >= ACCPT_THRHLD_CASSETTE_TILT Then
                        Print "casstte ", OneCassette$, " tilt ", Str$(CCTilt), " exceed threshold ", ACCPT_THRHLD_CASSETTE_TILT, "degree"
                        Print #LOG_FILE_NO, "casstte ", OneCassette$, " tilt exceed threshold ", ACCPT_THRHLD_CASSETTE_TILT, "degree"
                        Cassette_Warning$ = Cassette_Warning$ + "cassette " + OneCassette$ + " exceeded tilt threshold "
                        UpdateClient(EVTNO_WARNING, Cassette_Warning$)
                    EndIf
            Send
        Next

        g_Steps = 20 / CCTotalCAS
        g_CurrentSteps = (100 * CSTIndex - 40) / CCTotalCAS
        msg$ = Str$(g_CurrentSteps) + " of 100"
        UpdateClient(EVTNO_CAL_STEP, msg$)
        msg$ = "cassette cal: touching Z of" + CCName$
        UpdateClient(EVTNO_CAL_MSG, msg$)
        
        If Not CassetteZ() Then
            g_RunResult$ = "Z failed"
            Print g_RunResult$
            Print #LOG_FILE_NO, g_RunResult$
            Close #LOG_FILE_NO
            
            ''SPELCom_Return 5
            Exit Function
        EndIf
        
        Print "BottomZ = ", BottomZ
        Print #LOG_FILE_NO, "BottomZ = ", BottomZ
        msg$ = "BottomZ = " + Str$(BottomZ)
        UpdateClient(EVTNO_UPDATE, msg$)

        g_Steps = 20 / CCTotalCAS
        g_CurrentSteps = (100 * CSTIndex - 20) / CCTotalCAS
        msg$ = Str$(g_CurrentSteps) + " of 100"
        UpdateClient(EVTNO_CAL_STEP, msg$)
        msg$ = "cassette cal: touching angle offset of" + CCName$
        UpdateClient(EVTNO_CAL_MSG, msg$)
        
        If m_IsCalibrationCassette Then
        	''Get angle correction using calibration cassette
            AngleResult = CalCassetteAngle(BottomZ + CASSETTE_CAL_HEIGHT)
        Else
        	''Get angle correction using normal cassette
            AngleResult = NorCassetteAngle(CCTempX(2), CCTempY(2))
        EndIf
        
        If Not AngleResult Then
            g_RunResult$ = "angle failed"
            Print g_RunResult$
            Print #LOG_FILE_NO, g_RunResult$
            Close #LOG_FILE_NO
            
            ''SPELCom_Return 6
            Exit Function
        EndIf

        Print "new position (", CenterX, ", ", CenterY, ", ", BottomZ, ", ", angle, ")"
        Print #LOG_FILE_NO, "new position (", CenterX, ", ", CenterY, ", ", BottomZ, ", ", angle, ")"
        msg$ = "new position (" + Str$(CenterX) + ", " + Str$(CenterY) + ", " + Str$(BottomZ) + ", " + Str$(angle) + ")"
        UpdateClient(EVTNO_UPDATE, msg$)
        ''save data
        Select OneCassette$
        Case "l"
            P34 = XY(CenterX, CenterY, BottomZ, angle)
			Hand P34, Hand(P6)
            SavePointHistory 34, g_FCntCassette
			Print "saving points to file.....",
			SavePoints "robot1.pts"
			g_TS_Left_Cassette$ = Date$ + " " + Time$
        Case "m"
            P35 = XY(CenterX, CenterY, BottomZ, angle)
			Hand P35, Hand(P6)
            SavePointHistory 35, g_FCntCassette
			Print "saving points to file.....",
			SavePoints "robot1.pts"
			g_TS_Middle_Cassette$ = Date$ + " " + Time$
        Case "r"
            P36 = XY(CenterX, CenterY, BottomZ, angle)
			Hand P36, Hand(P6)
            SavePointHistory 36, g_FCntCassette
			Print "saving points to file.....",
			SavePoints "robot1.pts"
			g_TS_Right_Cassette$ = Date$ + " " + Time$
        Send
    Next
    
    Print "done!!"

    CassetteCalibration = True
    
    Print "Cassette calibration OK at ", Date$, " ", Time$
    Print #LOG_FILE_NO, "Cassette calibration OK at ", Date$, " ", Time$
    
    Close #LOG_FILE_NO
    UpdateClient(EVTNO_CAL_STEP, "100 of 100")

    If Not Init Then
        ''put back magnet
        UpdateClient(EVTNO_CAL_MSG, "cassette cal: put back magnet and go home")
        
        Tool 0
        LimZ g_Jump_LimZ_LN2
        Jump P6
        
        If Not Open_Gripper Then
            g_RunResult$ = "cassette cal: Open_Gripper Failed, holding magnet, need Reset"
            UpdateClient(EVTNO_CAL_MSG, g_RunResult$)
            UpdateClient(EVTNO_HARDWARE_LOG_SEVERE, g_RunResult$)
            Print g_RunResult$
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
            g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
            Motor Off
            Quit All
        EndIf

        Move P3
        g_HoldMagnet = False

        SetFastSpeed
        MoveTongHome
    EndIf
    
    UpdateClient(EVTNO_CAL_MSG, "cassette cal: Done")
	
    g_RunResult$ = "normal OK"
    ''SPELCom_Return 0
    Tool 0
Fend
Function VB_CassetteCal
    ''init result
    g_RunResult$ = ""
    
    ''parse argument from global
    ParseStr g_RunArgs$, VBCCTokens$(), " "
    ''check argument
    VBCCArgC = UBound(VBCCTokens$) + 1
    If VBCCArgC < 1 Or VBCCArgC > 2 Then
        g_RunResult$ = "bad argument.  should be lrm or l TRUE"
        ''SPELCom_Return 1
        Exit Function
    EndIf
    
    VBCCInit = False
    If VBCCArgC = 2 Then
        Select VBCCTokens$(1)
        Case "1"
            VBCCInit = True
        Case "TRUE"
            VBCCInit = True
        Case "true"
            VBCCInit = True
        Case "True"
            VBCCInit = True
        Send
    EndIf

    If Motor = Off Then
        Motor On
    EndIf
    If Power = 1 Then
        Power Low
    EndIf
    
    ''call function
    If Not CassetteCalibration(VBCCTokens$(0), VBCCInit) Then
        If g_FlagAbort Then
            g_RunResult$ = "User Abort"
        EndIf
        Recovery
        ''SPELCom_Return 2
        Exit Function
    EndIf
    ''SPELCom_Return 0
Fend

