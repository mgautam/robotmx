#include "mxrobotdefs.inc"
#include "networkdefs.inc"
#include "forcedefs.inc"

''===========================================================
''left arm or right arm system

Global Preserve Boolean g_LeftarmSystem

Global Preserve Boolean g_IncludeStrip
''=========================================
''we support more generic orientation now.
''so these should be configured by SITE,
''not initialized by left or right arm anymore.
''these should be 0 or 90 or -90 or 180.
Global Preserve Real g_Perfect_Cradle_Angle
Global Preserve Real g_Perfect_U4Holder
Global Preserve Real g_Perfect_DownStream_Angle

''for right arm system, normally 90, 180, -90
''for left arm system normally, -90, 0, 90
Global Preserve Real g_Perfect_LeftCassette_Angle
Global Preserve Real g_Perfect_MiddleCassette_Angle
Global Preserve Real g_Perfect_RightCassette_Angle

''=================================================
''g_Jump_LimZ_LN2 should be the Limz to keep dumbell and cavity in LN2 but clear all obstacles
''g_Jump_LimZ_Magnet should be the same or lower then g_Jump_LimZ_LN2.
''need only clear the dumbell cradle.
Global Preserve Real g_Jump_LimZ_LN2
Global Preserve Real g_Jump_LimZ_Magnet

''==============================================================
''will hold the perfect value for current cassette in calibration
Global Real g_Perfect_Cassette_Angle

''===================================================================
''g_MagnetTransportAngle: transport angle in robot coordinates.
''In ideal world, this should by 90 degree from the X axis of robot.
''This variable is set by PickerTouchSeat
''In angle tranform, If current U == g_U4MagnetHolder,
''the dumb bell is in direction of g_MagnetTransportAngle in robot coordinate system
Global Preserve Real g_MagnetTransportAngle ''angle of dumbbell in post
Global Preserve Real g_U4MagnetHolder       ''angle of U when dumbbell in post

''theory value should be (10-9.44)/2 = 0.28
Global Preserve Real g_PickerWallToHead
Global Preserve Real g_PlacerWallToHead

''========================================================================
''for log file names
Global Preserve Integer g_FCntPost
Global Preserve Integer g_FCntPicker
Global Preserve Integer g_FCntPlacer
Global Preserve Integer g_FCntToolRough
Global Preserve Integer g_FCntToolFine
Global Preserve Integer g_FCntCassette
Global Preserve Integer g_FCntGonio
Global Preserve Integer g_FCntBeamTool
Global Preserve Integer g_FCntStrip
''==========================================================
''for toolset calibration
Global Preserve Real g_Picker_X
Global Preserve Real g_Picker_Y
Global Preserve Real g_Placer_X
Global Preserve Real g_Placer_Y
Global Preserve Real g_ToolSet_A
Global Preserve Real g_ToolSet_B
Global Preserve Real g_ToolSet_C
Global Preserve Real g_ToolSet_Theta

''the sliding freedom for dumbbell in cradle
''It is used to correct picker and placer calibration
Global Preserve Real g_Dumbbell_Free_Y

''=========================================================
''main function cannot have parameters so
Global Preserve Boolean g_IncludeFindMagnet
Global Preserve Boolean g_Quick
Global Preserve Boolean g_AtLeastOnce

''==============================================================
''time stamp for calibrations
Global Preserve String g_TS_Toolset$
Global Preserve String g_TS_Left_Cassette$
Global Preserve String g_TS_Middle_Cassette$
Global Preserve String g_TS_Right_Cassette$
Global Preserve String g_TS_Goniometer$

''==========================================================================
''scale factor for port probing: torque to millimeter
Global Preserve Double g_TQScale_Picker
Global Preserve Double g_TQScale_Placer

''scale factor for port side probing
Global Preserve Double g_SideScale_Picker
Global Preserve Double g_SideScale_Placer

''================================================================
''if true, any move will be along X,Y Axis, no arbitory direction move.
Global Boolean g_OnlyAlongAxis

''============================================================

''tell lowlevel function to send +g_Steps to progress bar
''current step is g_CurrentSteps, you can increase by g_Steps in your function
Global Integer g_CurrentSteps
Global Integer g_Steps

''============================================================
''for recover action after abort:
''must make sure that it can jump P6 or jump P1
Global Boolean g_HoldMagnet
Global Boolean g_SafeToGoHome

''============================================================
''global constants for force sensor related functions
''============================================================
Boolean g_ConstantInited    ''to prevent repeated call for init constants

''====================================================
'' arm orientation
Global Integer g_ArmOrientation
''If not match with g_LeftarmSystem, nothing will run

''============================
''Touching, Moving with force trigger
'These values are obtained by experiment with robot and force sensor'
'Big threshold used in any move intended without force trigger'
Global Real g_MaxFX
Global Real g_MaxFY
Global Real g_MaxFZ
Global Real g_MaxTX
Global Real g_MaxTY
Global Real g_MaxTZ

''Threshold used in step-scan
Global Real g_ThresholdFX
Global Real g_ThresholdFY
Global Real g_ThresholdFZ
Global Real g_ThresholdTX
Global Real g_ThresholdTY
Global Real g_ThresholdTZ

''Bigger threshold for long distance moving,
'' the noise is about 0.2, so it has to be bigger
''they are intended to be used in safe move or safe go
Global Real g_BigThresholdFX
Global Real g_BigThresholdFY
Global Real g_BigThresholdFZ
Global Real g_BigThresholdTX
Global Real g_BigThresholdTY
Global Real g_BigThresholdTZ

''any force or torque will be considered as zero if below following values
''and ignored in post calibration
Global Real g_MinFX
Global Real g_MinFY
Global Real g_MinFZ
Global Real g_MinTX
Global Real g_MinTY
Global Real g_MinTZ

''in ForceTouch
''we move with force triger using threshold
''then move back until the force reduced to Min
Global Real g_XYTouchThreshold
Global Real g_ZTouchThreshold
Global Real g_UTouchThreshold
Global Real g_XYTouchMin
Global Real g_ZTouchMin
Global Real g_UTouchMin
''init touch step size, at the end step size reduced to init/10
Global Real g_XYTouchInitStepSize
Global Real g_ZTouchInitStepSize
Global Real g_UTouchInitStepSize

''after scan steps, how many binary crossing should try if fineTune
''It will cut step size in 1/(2**n)
Global Integer g_BinaryCrossTimes

''Max range we will scan in Cut Middle
''try to find the min force by moving within this range.
Global Real g_MaxRangeXY
Global Real g_MaxRangeZ
Global Real g_MaxRangeU
Global Integer g_XYNumSteps
Global Integer g_ZNumSteps
Global Integer g_UNumSteps

''ratio from experiment to check whether force sensor is working properly.
''This is the data about how much force should change when moves 1 mm 
Global Real g_RateFZ
Global Real g_RateTX
Global Real g_RateTY
Global Real g_RateTZ

''check magnet
Global Real g_FCheckMagnet

''flag for cut middle failed
Global Integer g_CutMiddleFailed

''global always reflect current situation.
Global Real g_CurrentP(4)
''Global Real g_CurrentF(6)  ''to use this one, need to make sure index is positive
Global Double g_CurrentSingleF

''for IOMonitor: VB program use this counter to make sure IOMonitor is running
Global Preserve Long g_IOMCounter
Global Preserve Long g_LidOpened

''temperarily for LN2 level
Global Preserve Boolean g_LN2LevelHigh
Global Preserve Integer g_LN2CoolingTime

''===============================================
''MODULE varible
''===============================================
'' any tmp_ prefix means this varible cannot cross function call
''they can be used by any function.
Integer tmp_PIndex

''==========================================================
'' LOCAL varibles: because it crashes system when there are
'' a lot of local variables, many local variables are moved here
''=========================================================
''read force
''ReadForces
Integer RFSRepeatIndex
Real RFSMaxValue(6)
Real RFSMinValue(6)
Real RFSCurrentValue(6)
Integer RFSForceIndex
Integer RFSNumValidSamples
'cannot pass element of array by ref'
Real minV
Real maxV
Real RFCurrentV

''AverageForce
Integer AFRepeatIndex
Integer AFNumValidSamples
Real currentValue

''CalculateStepSize
Real CSSAngleInRad
Real CSSDumbBellAngle
Real CSSForceName

''binary cross
Real BCStepSize(4)
Real BCPerfectPosition(4)
Integer BCStepIndex
Real BCCurrentPosition(4)
Double BCCurrentForce
Real BCTempDF
Real BCBestPosition(4)
Real BCBestDF

''force scan
Real FSOldPosition(4)
Double FSForce
Real FSPrePosition(4)
Double FSPreForce
Real FSDesiredPosition(4)
Real FSStepSize(4)
Real FSHypStepSize
Integer FSStepIndex

''ForceCross
Real FCDestPosition(4)

''ForceTouch
Real FTHInitP(4)
Real FTHDestP(4)
Real FTHMidP(4)     ''rough scan stopped position and fine tune starting position
Real FTHThreshold
Real FTHFineTuneDistance
Integer FTHNumSteps
Integer FTHRetryTimes

''TongMove
Real TMChange(4)   ''to store where to move according to the direction.

''CutMiddle
Real CMInitP(4)
Real CMPlusP(4)
Real CMMinusP(4)
Real CMFinalP(4)
Double CMInitForce
Double CMPlusForce
Double CMMinusForce
Double CMThreshold
Real CMScanRange
Integer CMNumSteps
Double CMMinForce
''for progress bar
Integer CMStepStart
Integer CMStepTotal



''LidMonitor
Long IOPreInputValue
Long IOCurInputValue
Long IOPreOutputValue
Long IOCurOutputValue

''SavePointHistory
String SPHFileName$

''FromHomeToTakeMagnet
Integer FHTTMWait

''isCloseToPoint
Real ICTPDX
Real ICTPDY
Real ICTPDZ
Real ICTPDU

''ForceResetAndCheck
Double FCheck(6)
Integer FCKIndex
Boolean FCKAgain

''ForceChangeCheck
Real FCCDF
Real FCCRate
Real FCCStandord

''CheckMagnet
Real CKMForce
Integer CKMGripperClosed

Function ForceTest
	Double forces(7)
	Integer i
	String mesg$
	FSCalibrate()
	Do While True
		''Read forces direct from DLL for testing purposes
		If FSReadForces(ByRef forces()) Then
			''Success, print result
			''Print result
			Print "Forces: ",
			For i = 1 To NUM_FORCES Step 1
				Print " ",
				Print FmtStr$(forces(i), "00.000"),
			Next
			''Add new line
			Print ""
			Wait .5
		Else
			''Print error from api
			FSGetErrorDesc(ByRef mesg$)
			Print mesg$
			Wait .5
		EndIf
	Loop
Fend
Function InitForceConstants

    If g_ConstantInited Then Exit Function

#ifndef MIXED_ARM_ORIENTAION
	''check arm orientation
	P30 = Here
	g_ArmOrientation = Hand(P30)

	''init perfect values for left or right arm systems
	If g_LeftarmSystem Then
		If g_ArmOrientation <> Lefty Then
			Print "SEVERE arm orientation conflict"
			Quit All
		EndIf
		''these are now SITE configurable
		''g_Perfect_Cradle_Angle = -90
		''g_Perfect_U4Holder = -90
		''g_Perfect_DownStream_Angle = 0
	Else
		If g_ArmOrientation = Lefty Then
			Print "SEVERE arm orientation conflict"
			Quit All
		EndIf
		''these are now SITE configurable
		''g_Perfect_Cradle_Angle = 90
		''g_Perfect_U4Holder = 90
		''g_Perfect_DownStream_Angle = 180
	EndIf
#endif

	''If (g_Perfect_LeftCassette_Angle = 0) And (g_Perfect_MiddleCassette_Angle = 0) And (g_Perfect_RightCassette_Angle = 0) Then
	''	If g_LeftarmSystem Then
	''		g_Perfect_LeftCassette_Angle = -90
	''		g_Perfect_MiddleCassette_Angle = 0
	''		g_Perfect_RightCassette_Angle = 90
	''	Else
	''		g_Perfect_LeftCassette_Angle = 90
	''		g_Perfect_MiddleCassette_Angle = 180
	''		g_Perfect_RightCassette_Angle = -90
	''	EndIf
	''EndIf

    Print "InitForceConstants"
    If g_MagnetTransportAngle = 0 Then
        g_MagnetTransportAngle = g_Perfect_Cradle_Angle
    EndIf

    g_MaxFX = 4
    g_MaxFY = 4
    g_MaxFZ = 8
    g_MaxTX = 4
    g_MaxTY = 4
    g_MaxTZ = 4

    ''REMEMBER to change scan ranges and steps if you change threshold
    ''these data are from experiement.  Force Units = Newton (N), Torque = Newton metres (Nm) 
    ''JinHu confirmed units by email on 02April 2014)
    g_ThresholdFX = 0.2
    g_ThresholdFY = 0.2
    g_ThresholdFZ = 0.5
    g_ThresholdTX = 0.5
    g_ThresholdTY = 0.2
    g_ThresholdTZ = 0.2
    
    ''These threshold can be used to move with force trigger.
    ''The noise is about 0.2-0.4, so they must be greater than that.
    g_BigThresholdFX = 5
    g_BigThresholdFY = 5
    g_BigThresholdFZ = 15           '' 0.1mm off is about 10
    g_BigThresholdTX = 5
    g_BigThresholdTY = 5
    g_BigThresholdTZ = 1.5

    g_MinFX = 0.02
    g_MinFY = 0.02
    g_MinFZ = 0.02
    g_MinTX = 0.1
    g_MinTY = 0.05
    g_MinTZ = 0.05

    ''g_XYTouchThreshold = 1.5
    g_XYTouchThreshold = 0.75	''0.5
    g_ZTouchThreshold = 0.1
    g_UTouchThreshold = 0.1
    
    g_XYTouchMin = 0.1
    g_ZTouchMin = 0.1
    g_UTouchMin = 0.05
    
    g_XYTouchInitStepSize = 1
    g_ZTouchInitStepSize = 0.25
    g_UTouchInitStepSize = 1

    g_BinaryCrossTimes = 6

    ''because the shape of the tong, XY have more flexible, Z and U are more rigid.
    g_MaxRangeXY = 2 'mm'
    g_MaxRangeZ = 0.5 'mm'
    g_MaxRangeU = 6 'degree'

    g_XYNumSteps = 40        ''step size is 0.05mm
    g_ZNumSteps = 20        ''step size is 0.025mm
    g_UNumSteps = 30        ''step size is 0.1 degree

    CheckPoint 6
    g_U4MagnetHolder = CU(P6)
    If g_U4MagnetHolder = 0 Then
        g_U4MagnetHolder = g_Perfect_U4Holder
    EndIf
    
    g_LN2CoolingTime = 45
    
    ''when tong is agaigst a solid wall and move 1 mm (or degree) in that direction
    g_RateFZ = 155
    g_RateTX = 3.0
    g_RateTY = 5.2
    g_RateTZ = 3.6
    
    g_FCheckMagnet = 0.2
    
    'default speeds'
    Power Low
    Accel VERY_SLOW_GO_ACCEL, VERY_SLOW_GO_DEACCEL
    Speed VERY_SLOW_GO_SPEED
    
    AccelS VERY_SLOW_MOVE_ACCEL, VERY_SLOW_MOVE_DEACCEL
    SpeedS VERY_SLOW_MOVE_SPEED
    
    g_ConstantInited = True
Fend
Function GetTouchThreshold(forceName As Integer) As Real
    Select Abs(forceName)
    Case FORCE_XFORCE
        GetTouchThreshold = g_XYTouchThreshold
    Case FORCE_YFORCE
        GetTouchThreshold = g_XYTouchThreshold
    Case FORCE_ZFORCE
        GetTouchThreshold = g_ZTouchThreshold
    Case FORCE_XTORQUE
        GetTouchThreshold = g_XYTouchThreshold
    Case FORCE_YTORQUE
        GetTouchThreshold = g_XYTouchThreshold
    Case FORCE_ZTORQUE
        GetTouchThreshold = g_UTouchThreshold
    Default
        GetTouchThreshold = 0
    Send
    
    If forceName < 0 Then
        GetTouchThreshold = -GetTouchThreshold;
    EndIf
Fend

Function GetTouchMin(forceName As Integer) As Real
    Select Abs(forceName)
    Case FORCE_XFORCE
        GetTouchMin = g_XYTouchMin
    Case FORCE_YFORCE
        GetTouchMin = g_XYTouchMin
    Case FORCE_ZFORCE
        GetTouchMin = g_ZTouchMin
    Case FORCE_XTORQUE
        GetTouchMin = g_XYTouchMin
    Case FORCE_YTORQUE
        GetTouchMin = g_XYTouchMin
    Case FORCE_ZTORQUE
        GetTouchMin = g_UTouchMin
    Default
        GetTouchMin = 0
    Send
    
    If forceName < 0 Then
        GetTouchMin = -GetTouchMin
    EndIf
Fend

Function GetTouchStepSize(forceName As Integer) As Real
    Select Abs(forceName)
    Case FORCE_XFORCE
        GetTouchStepSize = g_XYTouchInitStepSize
    Case FORCE_YFORCE
        GetTouchStepSize = g_XYTouchInitStepSize
    Case FORCE_ZFORCE
        GetTouchStepSize = g_ZTouchInitStepSize
    Case FORCE_XTORQUE
        GetTouchStepSize = g_XYTouchInitStepSize
    Case FORCE_YTORQUE
        GetTouchStepSize = g_XYTouchInitStepSize
    Case FORCE_ZTORQUE
        GetTouchStepSize = g_UTouchInitStepSize
    Default
        GetTouchStepSize = 1E20
    Send
Fend

Function GetForceThreshold(ByVal forceName As Integer) As Real
    Select Abs(forceName)
    Case FORCE_XFORCE
        GetForceThreshold = g_ThresholdFX
    Case FORCE_YFORCE
        GetForceThreshold = g_ThresholdFY
    Case FORCE_ZFORCE
        GetForceThreshold = g_ThresholdFZ
    Case FORCE_XTORQUE
        GetForceThreshold = g_ThresholdTX
    Case FORCE_YTORQUE
        GetForceThreshold = g_ThresholdTY
    Case FORCE_ZTORQUE
        GetForceThreshold = g_ThresholdTZ
    Default
        GetForceThreshold = 0
    Send
Fend

Function GetForceMin(ByVal forceName As Integer) As Real
    Select Abs(forceName)
    Case FORCE_XFORCE
        GetForceMin = g_MinFX
    Case FORCE_YFORCE
        GetForceMin = g_MinFY
    Case FORCE_ZFORCE
        GetForceMin = g_MinFZ
    Case FORCE_XTORQUE
        GetForceMin = g_MinTX
    Case FORCE_YTORQUE
        GetForceMin = g_MinTY
    Case FORCE_ZTORQUE
        GetForceMin = g_MinTZ
    Default
        GetForceMin = 0
    Send
Fend

Function GetForceBigThreshold(ByVal forceName As Integer) As Real
    Select Abs(forceName)
    Case FORCE_XFORCE
        GetForceBigThreshold = g_BigThresholdFX
    Case FORCE_YFORCE
        GetForceBigThreshold = g_BigThresholdFY
    Case FORCE_ZFORCE
        GetForceBigThreshold = g_BigThresholdFZ
    Case FORCE_XTORQUE
        GetForceBigThreshold = g_BigThresholdTX
    Case FORCE_YTORQUE
        GetForceBigThreshold = g_BigThresholdTY
    Case FORCE_ZTORQUE
        GetForceBigThreshold = g_BigThresholdTZ
    Default
        GetForceBigThreshold = 0
    Send
Fend

Function GetCutMiddleData(forceName As Integer, ByRef scanRange As Real, ByRef numSteps As Integer)
    Select Abs(forceName)
    Case FORCE_XFORCE
        scanRange = g_MaxRangeXY
        numSteps = g_XYNumSteps
    Case FORCE_YFORCE
        scanRange = g_MaxRangeXY
        numSteps = g_XYNumSteps
    Case FORCE_ZFORCE
        scanRange = g_MaxRangeZ
        numSteps = g_ZNumSteps
    Case FORCE_XTORQUE
        scanRange = g_MaxRangeXY
        numSteps = g_XYNumSteps
    Case FORCE_YTORQUE
        scanRange = g_MaxRangeXY
        numSteps = g_XYNumSteps
    Case FORCE_ZTORQUE
        scanRange = g_MaxRangeU
        numSteps = g_UNumSteps
    Send
Fend
Function GetDestination(ByVal forceName As Integer, ByVal stepDistance As Real, ByRef dest() As Real)
    CalculateStepSize(forceName, stepDistance, CU(Here), ByRef dest())
    dest(1) = dest(1) + CX(Here)
    dest(2) = dest(2) + CY(Here)
    dest(3) = dest(3) + CZ(Here)
    dest(4) = dest(4) + CU(Here)
Fend
Function CalculateStepSize(ByVal forceName As Integer, ByVal stepDistance As Real, ByVal currentU As Real, ByRef stepSize() As Real)

    stepDistance = Abs(stepDistance)
    CSSForceName = Abs(forceName)

    CSSDumbBellAngle = UToDumbBellAngle(currentU)

    'init to all 0'
    stepSize(1) = 0
    stepSize(2) = 0
    stepSize(3) = 0
    stepSize(4) = 0

    If stepDistance = 0 Then Exit Function
                            
    Select CSSForceName
    Case FORCE_XFORCE
        'move in force sensor's X direction
        CSSAngleInRad = DegToRad(CSSDumbBellAngle + FS_XAXIS_ANGLE)

        stepSize(1) = -stepDistance * Cos(CSSAngleInRad)
        stepSize(2) = -stepDistance * Sin(CSSAngleInRad)

    Case FORCE_YTORQUE
        'move in force sensor's X direction
        CSSAngleInRad = DegToRad(CSSDumbBellAngle + FS_XAXIS_ANGLE)

#ifdef FORCE_TORQUE_WRONG_DIRECTION
        stepSize(1) = stepDistance * Cos(CSSAngleInRad)
        stepSize(2) = stepDistance * Sin(CSSAngleInRad)
#else
        stepSize(1) = -stepDistance * Cos(CSSAngleInRad)
        stepSize(2) = -stepDistance * Sin(CSSAngleInRad)
#endif
        
    Case FORCE_YFORCE
        'move in force sensor's Y direction
        CSSAngleInRad = DegToRad(CSSDumbBellAngle + FS_YAXIS_ANGLE)

        stepSize(1) = -stepDistance * Cos(CSSAngleInRad)
        stepSize(2) = -stepDistance * Sin(CSSAngleInRad)

    Case FORCE_XTORQUE
        'move in force sensor's Y direction
        CSSAngleInRad = DegToRad(CSSDumbBellAngle + FS_YAXIS_ANGLE)

#ifdef FORCE_TORQUE_WRONG_DIRECTION
        stepSize(1) = -stepDistance * Cos(CSSAngleInRad)
        stepSize(2) = -stepDistance * Sin(CSSAngleInRad)
#else
        stepSize(1) = stepDistance * Cos(CSSAngleInRad)
        stepSize(2) = stepDistance * Sin(CSSAngleInRad)
#endif

    Case FORCE_ZFORCE
        stepSize(3) = stepDistance

    Case FORCE_ZTORQUE
#ifdef FORCE_TORQUE_WRONG_DIRECTION
        stepSize(4) = -stepDistance
#else
        stepSize(4) = stepDistance
#endif
    Send

    If forceName < 0 Then
        stepSize(1) = -stepSize(1)
        stepSize(2) = -stepSize(2)
        stepSize(3) = -stepSize(3)
        stepSize(4) = -stepSize(4)
    EndIf
Fend


''This function will scan in related direction to find the position
''where the force sensor cross the threshold in desired direction.
''At the end, the robot will stop at the cross position.
''If the direction is - -> +, then the final force will be a little
''bigger than threshold.  If the cross dirction is + -> -, 
''then the final force value will be a little smaller than threshold
''When it moves the robot, it combines steps and force trigger.
''Input:
''   forceName:
''               +-FORCE_XFORCE   (rarely use, use FORCE_YTORQUE instead)
''               +-FORCE_YFORCE   (rarely use, use FORCE_XTORQUE instead)
''               +-FORCE_ZFORCE
''               +-FORCE_XTORQUE
''               +-FORCE_YTORQUE
''               +-FORCE_ZTORQUE
''
''   crossDirection:
''               +: rising cross
''               -: falling cross
''
''
''   threshold:  the desired force Threshold to cross
''
''
''   scanDistance:  max scan Distance from current position
''
''   numSteps:      numSteps to scan the distance
''
''This function is a wrapper for ForceScan.
''It make sure the robot will move to right and most effective direction to cross the threshold
Function ForceCross(forceName As Integer, threshold As Real, scanDistance As Real, numSteps As Integer, fineTune As Boolean) As Boolean
    String msg$
    ''calculate where is the best destination,
    CalculateStepSize(forceName, scanDistance, CU(Here), ByRef FCDestPosition())
    FCDestPosition(1) = FCDestPosition(1) + CX(Here)
    FCDestPosition(2) = FCDestPosition(2) + CY(Here)
    FCDestPosition(3) = FCDestPosition(3) + CZ(Here)
    FCDestPosition(4) = FCDestPosition(4) + CU(Here)
    
    msg$ = "ForceCross forceName: " + Str$(forceName) + ", threshold: " + Str$(threshold) + " distance: " + Str$(scanDistance)
    UpdateClient(EVTNO_PRINT_EVENT, msg$)
    msg$ = "destination P "
    UpdateClient(EVTNO_PRINT_EVENT, msg$)
    PrintPosition(ByRef FCDestPosition())
    
    ''call ForceScan
    ForceCross = ForceScan(forceName, threshold, ByRef FCDestPosition(), numSteps, fineTune)
Fend
''touch. It must start from a neutral place for that force.
''the robot may come back to the starting place to do force sensor reset
Function ForceTouch(ByVal forceName As Integer, ByVal scanDistance As Real, ByVal fineTune As Boolean) As Boolean
	String msg$
    Boolean ForceTouchSatisfied
	''Force too big check
	Integer FTHThresHoldM
	
	msg$ = "+ForceTouch " + Str$(forceName) + ", " + Str$(scanDistance)
    UpdateClient(EVTNO_PRINT_EVENT, msg$)
	
    ForceTouch = False
    
    ''Set force too big threshold multiplier
    If (forceName <> -3) Then
    	FTHThresHoldM = 5
    Else
    	''Force increases much faster in z
    	FTHThresHoldM = 250
    	SetUltraSlowSpeed
    EndIf
    
    ForceTouchSatisfied = False
    
    GetCurrentPosition(ByRef FTHInitP())

    ''get destination position from the scan distance
    CalculateStepSize(forceName, scanDistance, CU(Here), ByRef FTHDestP())
    FTHDestP(1) = FTHDestP(1) + CX(Here)
    FTHDestP(2) = FTHDestP(2) + CY(Here)
    FTHDestP(3) = FTHDestP(3) + CZ(Here)
    FTHDestP(4) = FTHDestP(4) + CU(Here)
      
    ''try move with trigger first, if failed, we will scan with steps.
    FTHThreshold = GetTouchThreshold(forceName)
    
    ''Read force before doing a move till force
    g_CurrentSingleF = ReadForce(forceName)
    
    ''Exit if force too big before moving
    If ForcePassedThreshold(forceName, g_CurrentSingleF, (FTHThresHoldM * FTHThreshold)) Then
    	''Force too big before moving
        msg$ = "ForceTouch: Force too big before moving.  Exiting ForceTouch"
    	UpdateClient(EVTNO_PRINT_EVENT, msg$)
        Exit Function
	EndIf
	
	''Exit if force satisfies threshold before moving
    If ForcePassedThreshold(forceName, g_CurrentSingleF, FTHThreshold) Then
    	''Force beyond requested threshold before moving
        msg$ = "ForceTouch: Force beyond threshold before moving.  Exiting ForceTouch"
    	UpdateClient(EVTNO_PRINT_EVENT, msg$)
        Exit Function
	EndIf
    
    If g_FlagAbort Then
    	GenericMove(ByRef FTHInitP(), False)
        Exit Function
    EndIf

    ''set up trigger
    SetupForceTrigger(forceName, FTHThreshold)
    ''move  
    GenericMove(ByRef FTHDestP(), True)
    
    If (g_FSForceTriggerStatus <> 0) Then
       	''Trigger occured
    	''Read force that caused trigger
    	g_CurrentSingleF = g_FSTriggeredForces(Abs(forceName))
    	''Print "valid force=" + Str$(g_CurrentSingleF)
    Else
    	''Trigger did not occur
    	''Read current force
    	g_CurrentSingleF = ReadForce(forceName)
    	''Print "invalid force=" + Str$(g_CurrentSingleF)
    EndIf
    
    ''Read position after moving till force
    GetCurrentPosition(ByRef g_CurrentP())
    
    ''Check forces
    If ForcePassedThreshold(forceName, g_CurrentSingleF, (FTHThresHoldM * FTHThreshold)) Then
       	''Force too big
       	msg$ = "ForceTouch: Force too big at destination @ " + Str$(g_CurrentSingleF)
        UpdateClient(EVTNO_PRINT_EVENT, msg$)
        Exit Function
    ElseIf ForcePassedThreshold(forceName, g_CurrentSingleF, (FTHThreshold)) Then
       	''Force satisfies threshold, and is not too big
       	msg$ = "ForceTouch: Force satisfies threshold condition @ " + Str$(g_CurrentSingleF)
        UpdateClient(EVTNO_PRINT_EVENT, msg$)
        ForceTouchSatisfied = True
    ElseIf Not ForcePassedThreshold(forceName, g_CurrentSingleF, (FTHThreshold)) Then
       	''Force does not satisfy threshold
       	msg$ = "ForceTouch: Force does not satisfy threshold condition @ " + Str$(g_CurrentSingleF)
        UpdateClient(EVTNO_PRINT_EVENT, msg$)
        msg$ = "ForceTouch: Threshold is " + Str$(FTHThreshold)
        UpdateClient(EVTNO_PRINT_EVENT, msg$)
        msg$ = "ForceTouch: This indicates noisy force measurement and force read too late after forceTouch move"
        UpdateClient(EVTNO_PRINT_EVENT, msg$)
    EndIf
    
    ''check to see if we need to step-scan to it if moving with force trigger not work
    If Not ForceTouchSatisfied Then
        ''prepare to step-scan
        ''GetCurrentPosition(ByRef g_CurrentP())
        
        FTHNumSteps = HypDistance(ByRef g_CurrentP(), ByRef FTHDestP()) / GetTouchStepSize(forceName)
        FTHThreshold = GetTouchThreshold(forceName)
        msg$ = "ForceTouch: failed using move with trigger.  Trying step scan instead"
        UpdateClient(EVTNO_PRINT_EVENT, msg$)
        If Not ForceScan(forceName, FTHThreshold, ByRef FTHDestP(), FTHNumSteps, False) Then
        	UpdateClient(EVTNO_PRINT_EVENT, "not touched within the range")
		    If g_FlagAbort Then
		        GenericMove(ByRef FTHInitP(), False)
		    EndIf
            Exit Function
        EndIf
    EndIf
    
    If fineTune Then
    	''save fine tune start position: we will come back to this position after we reset
        ''the force sensor in case it needs to.
        GetCurrentPosition(ByRef FTHMidP())
    	msg$ = "ForceTouch FineTune"
    	UpdateClient(EVTNO_PRINT_EVENT, msg$)
        FTHThreshold = GetTouchMin(forceName)
        FTHFineTuneDistance = GetTouchStepSize(forceName) * 4
        If Not ForceCross(-forceName, FTHThreshold, FTHFineTuneDistance, 40, True) Then
        	''Failed.  Move to initial position and exit
            GenericMove(ByRef FTHInitP(), False)
            Exit Function
        EndIf
    EndIf
    
    ForceTouch = True
    ''OK, here it is
    GetCurrentPosition(ByRef g_CurrentP())
    g_CurrentSingleF = ReadForce(forceName)
	
	UpdateClient(EVTNO_PRINT_EVENT, "ForceTouched at P:")
	PrintPosition(ByRef g_CurrentP())
	msg$ = " force :" + Str$(g_CurrentSingleF)
	UpdateClient(EVTNO_PRINT_EVENT, msg$)

    If g_FlagAbort Then
        GenericMove(ByRef FTHInitP(), False)
    EndIf
Fend
Function SetUltraSlowSpeed
    Accel VERY_SLOW_GO_ACCEL, VERY_SLOW_GO_DEACCEL
    Speed ULTRA_SLOW_GO_SPEED
    
    AccelS VERY_SLOW_MOVE_ACCEL, VERY_SLOW_MOVE_DEACCEL
    SpeedS ULTRA_SLOW_MOVE_SPEED
Fend
Function SetVerySlowSpeed
    Accel VERY_SLOW_GO_ACCEL, VERY_SLOW_GO_DEACCEL
    Speed VERY_SLOW_GO_SPEED
    
    AccelS VERY_SLOW_MOVE_ACCEL, VERY_SLOW_MOVE_DEACCEL
    SpeedS VERY_SLOW_MOVE_SPEED
Fend
Function SetFastSpeed
    Accel FAST_GO_ACCEL, FAST_GO_DEACCEL
    Speed FAST_GO_SPEED
    
    AccelS FAST_MOVE_ACCEL, FAST_MOVE_DEACCEL
    SpeedS FAST_MOVE_SPEED
Fend
Function isCloseToPoint(Num As Integer) As Boolean

    isCloseToPoint = True
    
    ICTPDX = CX(Here) - CX(P(Num))
    ICTPDY = CY(Here) - CY(P(Num))
    ICTPDZ = CZ(Here) - CZ(P(Num))
    ICTPDU = CU(Here) - CU(P(Num))

    ''These two, must be close in all XYZU
    If Num = 6 Or Num = 21 Then
        If Abs(ICTPDU) > 2 Then
            isCloseToPoint = False
        EndIf

        If Abs(ICTPDZ) > 2 Then
            isCloseToPoint = False
        EndIf
    EndIf

    If Sqr(ICTPDX * ICTPDX + ICTPDY * ICTPDY) > 2 Then
        isCloseToPoint = False
    EndIf
Fend

''dumbbell direction is the strong end direction.
'' we also require that force sensor Y axis is the same direction
Function UToDumbBellAngle(ByVal currentU As Real) As Real
    Integer currentToolset
    
    currentToolset = Tool
    If Tool <> 0 Then
        P50 = TLSet(currentToolset)
        currentU = currentU - CU(P50)
    EndIf

    UToDumbBellAngle = currentU - g_U4MagnetHolder + g_MagnetTransportAngle
    If g_OnlyAlongAxis Then
        ''we use currentToolset as a temp integer
        UToDumbBellAngle = UToDumbBellAngle /90.0 + 0.5
        currentToolset = Int(UToDumbBellAngle)
        UToDumbBellAngle = 90 * currentToolset
    EndIf
Fend

''move by direction and distance
Function TongMove(ByVal direction As Integer, ByVal distance As Real, ByVal withTrigger As Boolean)

    CalculateStepSize(direction, distance, CU(Here), ByRef TMChange())
    ''move
    StepMove(ByRef TMChange(), withTrigger)
Fend

Function ResetForceSensor As Boolean
	ResetForceSensor = False

    Print "Resetting force sensor"
    
    SetFastSpeed
    
    ''move up 10 mm
    Move Here +Z(10.0)
    
    ''reset force sensor
    Wait TIME_WAIT_BEFORE_RESET
    If Not ForceCalibrateAndCheck(LOW_SENSITIVITY, LOW_SENSITIVITY) Then
		Exit Function
    EndIf

    ''move back
    Move Here -Z(8.0)
    
    SetVerySlowSpeed
    Move Here -Z(2.0)
    Print "force sensor resetted"
    
    ResetForceSensor = True
Fend
''twist cavity off picker to break magnetic field
Function TwistRelease
	Integer currTool
	Real currAngle, dx, dy
	''Setup variables	
	currTool = Tool()
	currAngle = DegToRad(CU(Here))
	dx = -10.0 * Cos(currAngle);
	dy = -10.0 * Sin(currAngle);
	''if not near gonio
	If (Not isCloseToPoint(21)) Then
		''If p12 defined then define toolset for cavity twistoff 
		If PDef(P12) Then
			''Setup the toolset
			TLSet 3, XY(CX(P12), CY(P12), CZ(P12), CU(P12))
			''do the move
			Tool 3
			Go (Here +U(45))
			Move (Here +X(dx) +Y(dy))
			''restore tool 
			Tool currTool
		EndIf
	EndIf
Fend
Function TurnOnHeater
    On OUT_DRY_AIR
    On OUT_HEATER
Fend

Function TurnOffHeater As Boolean
    TurnOffHeater = True
    Off OUT_HEATER
    Wait Sw(IN_HEATERHOT) = 0, 60
    If TW = 1 Then
        TurnOffHeater = False
    EndIf
    Off OUT_DRY_AIR
Fend

Function WaitHeaterHot(timeInSeconds As Integer) As Boolean
	On OUT_DRY_AIR
	On OUT_HEATER
    WaitHeaterHot = False
    Wait Sw(IN_HEATERHOT) = 1, timeInSeconds
    If TW = 1 Then
        WaitHeaterHot = False
    Else
        WaitHeaterHot = True
    EndIf
Fend

''get rid of water????
Function Dance
    Integer Dance_I
    
    Accel 10, 10
    
    Speed 1, 1, 1
    
    LimZ (CZ(P0) + 15)
    
    For Dance_I = 1 To 4
        Jump P0 +U(10)
        Jump P0 -U(10)
    Next
    
    Jump P0
    LimZ 0
Fend

Function MoveTongHome
    Tool 0

    InitForceConstants

    If g_LN2LevelHigh Then
        TurnOnHeater
    EndIf

    SetFastSpeed
    
    If isCloseToPoint(6) Then
        If Not Open_Gripper Then
            g_RunResult$ = "MoveTongHome: Open_Gripper Failed, may hold magnet, need Reset"
            UpdateClient(EVTNO_CAL_MSG, g_RunResult$)
            UpdateClient(EVTNO_HARDWARE_LOG_SEVERE, g_RunResult$)
            Print g_RunResult$
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
            g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
            Motor Off
            Quit All
        EndIf
        TongMove DIRECTION_MAGNET_TO_CAVITY, 20, False ''P3
    EndIf
    
    SetVeryFastSpeed
    
    If Dist(Here, P0) > 3 Then
        Go Here :Z(-2)
#ifdef MIXED_ARM_ORIENTATION
        Go P1
#else
        Move P1
#endif
        
        Close_Lid
        
        Move P0 :Z(-1)
        Move P0
    EndIf

    If g_LN2LevelHigh Then
        If Not WaitHeaterHot(40) Then
            g_RunResult$ = "MoveTongHome: HEATER failed to reach high temperature"
            UpdateClient(EVTNO_CAL_MSG, g_RunResult$)
            UpdateClient(EVTNO_HARDWARE_LOG_ERROR, g_RunResult$)
            Print g_RunResult$
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_CLEAR
            g_RobotStatus = g_RobotStatus Or FLAG_REASON_HEATER_FAIL
        EndIf
    EndIf

    If Sw(IN_HEATERHOT) = On Then
        ''wait
        Wait 60
        Dance
    EndIf
    TurnOffHeater
    LimZ 0
Fend

Function MoveTongOut
    Tool 0

    Move Here :Z(-1)
#ifdef MIXED_ARM_ORIENTATION
	Go P1
#else
    Move P1
#endif
Fend

Function GenericMove(ByRef position() As Real, tillForce As Boolean)
	Real diffx, diffy, diffz, diffu
	
	diffx = Abs(position(1) - CX(Here))
	diffy = Abs(position(2) - CY(Here))
	diffz = Abs(position(3) - CZ(Here))
	diffu = Abs(position(4) - CU(Here))
	
    If (diffx >= 0.0009) Or (diffy >= 0.0009) Or (diffz >= 0.0009) Then
    ''If (position(1) <> CX(Here)) Or (position(2) <> CY(Here)) Or (position(3) <> CZ(Here)) Then
        If tillForce Then
        		Move Here :X(position(1)) :Y(position(2)) :Z(position(3)) :U(position(4)) Till g_FSForceTriggerStatus <> 0
        Else
	        	Move Here :X(position(1)) :Y(position(2)) :Z(position(3)) :U(position(4))
        EndIf
    Else
        If tillForce Then
            Go Here :U(position(4)) Till g_FSForceTriggerStatus <> 0
        Else
            Go Here :U(position(4))
        EndIf
    EndIf
Fend

Function StepMove(ByRef stepSize() As Real, tillForce As Boolean)
		
	If (Abs(stepSize(1)) >= 0.0009) Or (Abs(stepSize(2)) >= 0.0009) Or (Abs(stepSize(3)) >= 0.0009) Then
    ''If (stepSize(1) <> 0) Or (stepSize(2) <> 0) Or (stepSize(3) <> 0) Then
        If tillForce Then
            Move Here + XY(stepSize(1), stepSize(2), stepSize(3), stepSize(4)) Till g_FSForceTriggerStatus <> 0
        Else
            Move Here + XY(stepSize(1), stepSize(2), stepSize(3), stepSize(4))
        EndIf
    Else
        If tillForce Then
            Go Here +U(stepSize(4)) Till g_FSForceTriggerStatus <> 0
        Else
            Go Here +U(stepSize(4)) Till g_FSForceTriggerStatus <> 0
        EndIf
    EndIf
Fend

Function GetCurrentPosition(ByRef position() As Real)
    position(1) = CX(Here)
    position(2) = CY(Here)
    position(3) = CZ(Here)
    position(4) = CU(Here)
Fend

Function HypStepSize(ByRef stepSize() As Real) As Real
    HypStepSize = Sqr(stepSize(1) * stepSize(1) + stepSize(2) * stepSize(2) + stepSize(3) * stepSize(3) + stepSize(4) * stepSize(4))
Fend

Function HypDistance(ByRef position1() As Real, ByRef position2() As Real) As Real
	Real tmp_Real
    HypDistance = 0
    For tmp_PIndex = 1 To 4
        tmp_Real = position1(tmp_PIndex) - position2(tmp_PIndex)
        HypDistance = HypDistance + tmp_Real * tmp_Real
    Next
    HypDistance = Sqr(HypDistance)
Fend


Function PositionCopy(ByRef dst() As Real, ByRef src() As Real)
    For tmp_PIndex = 1 To 4
        dst(tmp_PIndex) = src(tmp_PIndex)
    Next
Fend

Function PrintPosition(ByRef position() As Real)
	String msg$
	msg$ = "(" + Str$(position(1)) + ", " + Str$(position(2)) + ", " + Str$(position(3)) + ", " + Str$(position(4)) + ")"
	UpdateClient(EVTNO_PRINT_EVENT, msg$)
Fend

Function LogPosition(ByRef position() As Real)
    Print #LOG_FILE_NO, "(", position(1), ", ", position(2), ", ", position(3), ", ", position(4), ")",
Fend


Function BinaryCross(forceName As Integer, ByRef previousPosition() As Real, previousForce As Real, threshold As Real, numSteps As Integer)
	String msg$
	
	msg$ = "BinaryCross " + Str$(forceName) + ", " + Str$(threshold)
	UpdateClient(EVTNO_PRINT_EVENT, msg$)

    ''check current condition
    If Abs(previousForce - threshold) < 0.01 Then
    	msg$ = "previousForce = threshold, exit"
        UpdateClient(EVTNO_PRINT_EVENT, msg$)
        GenericMove(ByRef previousPosition(), False)
        Exit Function
    EndIf

    GetCurrentPosition(ByRef BCCurrentPosition())
    BCCurrentForce = ReadForce(forceName)
    If Abs(BCCurrentForce - threshold) < 0.01 Then
        msg$ = "BCCurrentForce = threshold, exit"
        UpdateClient(EVTNO_PRINT_EVENT, msg$)
        Exit Function
    EndIf

    For tmp_PIndex = 1 To 4
        BCStepSize(tmp_PIndex) = BCCurrentPosition(tmp_PIndex) - previousPosition(tmp_PIndex)
    Next
    
    If HypStepSize(ByRef BCStepSize()) < 0.001 Then
    	msg$ = "step size already very small < 0.001, exit"
    	UpdateClient(EVTNO_PRINT_EVENT, msg$)
        Exit Function
    EndIf

    ''save best point
    If Abs(BCCurrentForce - threshold) > Abs(previousForce - threshold) Then
        PositionCopy(ByRef BCBestPosition(), ByRef previousPosition())
        BCBestDF = Abs(previousForce - threshold)
    Else
        PositionCopy(ByRef BCBestPosition(), ByRef BCCurrentPosition())
        BCBestDF = Abs(BCCurrentForce - threshold)
    EndIf


    If (previousForce - threshold) * (BCCurrentForce - threshold) > 0 Then
        msg$ = "threshold must be in between previous force and current force"
        UpdateClient(EVTNO_PRINT_EVENT, msg$)
        Exit Function
    EndIf

    GenericMove(ByRef previousPosition(), False)
    For BCStepIndex = 1 To numSteps
        If g_FlagAbort Then
            Exit Function
        EndIf

        For tmp_PIndex = 1 To 4
            BCStepSize(tmp_PIndex) = BCStepSize(tmp_PIndex) / 2   ''reduce stepsize to half
        Next
        If HypStepSize(ByRef BCStepSize()) < 0.0001 Then
            msg$ = "step size already very small < 0.0001, exit"
            UpdateClient(EVTNO_PRINT_EVENT, msg$)
            Exit Function
        EndIf
        StepMove(ByRef BCStepSize(), False)
        GetCurrentPosition(ByRef g_CurrentP())
        g_CurrentSingleF = ReadForce(forceName)
        BCTempDF = Abs(g_CurrentSingleF - threshold)
        msg$ = "step " + Str$(BCStepIndex) + ", P: "
        UpdateClient(EVTNO_PRINT_EVENT, msg$)
        PrintPosition(ByRef g_CurrentP())
        msg$ = "force :" + Str$(g_CurrentSingleF)
        UpdateClient(EVTNO_PRINT_EVENT, msg$)
        ''save best
        If BCTempDF < BCBestDF Then
            PositionCopy(ByRef BCBestPosition(), ByRef g_CurrentP())
            BCBestDF = BCTempDF
        EndIf

        If Abs(g_CurrentSingleF - threshold) < 0.01 Then
        	msg$ = "found threshold at step " + Str$(BCStepIndex) + ", exit"
        	UpdateClient(EVTNO_PRINT_EVENT, msg$)
            Exit Function
        EndIf
        If (previousForce - threshold) * (g_CurrentSingleF - threshold) < 0 Then
            ''cross the threshold, so change current
            PositionCopy(ByRef BCCurrentPosition(), ByRef g_CurrentP())
            BCCurrentForce = g_CurrentSingleF
            GenericMove(ByRef previousPosition(), False)
        Else
            ''not reach threshold yet, change previous
            PositionCopy(ByRef previousPosition(), ByRef g_CurrentP())
            previousForce = g_CurrentSingleF
        EndIf
    Next

#ifdef CROSS_LINEAR_INTERPOLATE
    ''linear interpolation
    UpdateClient(EVTNO_PRINT_EVENT, "Linear interpolation")
    msg$ = "new previous: Force=" + Str$(previousForce) + ", P="
    UpdateClient(EVTNO_PRINT_EVENT, msg$)
    PrintPosition(ByRef previousPosition())
	msg$ = "new current:  Force=" + Str$(BCCurrentForce) + ", P="
	UpdateClient(EVTNO_PRINT_EVENT, msg$)
	PrintPosition(ByRef BCCurrentPosition())
	
	msg$ = " threshold Force=" + Str$(threshold)
	UpdateClient(EVTNO_PRINT_EVENT, msg$)
	
    If Abs(previousForce - BCCurrentForce) < 0.0001 Then
    	msg$ = "too close , return middle"
    	UpdateClient(EVTNO_PRINT_EVENT, msg$)
        For tmp_PIndex = 1 To 4
            BCPerfectPosition(tmp_PIndex) = (previousPosition(tmp_PIndex) + BCCurrentPosition(tmp_PIndex)) / 2
        Next
    Else
        For tmp_PIndex = 1 To 4
            BCPerfectPosition(tmp_PIndex) = previousPosition(tmp_PIndex) + (BCCurrentPosition(tmp_PIndex) - previousPosition(tmp_PIndex)) * (threshold - previousForce) / (BCCurrentForce - previousForce)
        Next
    EndIf
    GenericMove(ByRef BCPerfectPosition(), False)
    UpdateClient(EVTNO_PRINT_EVENT, "perfect P at ")
    PrintPosition(ByRef BCPerfectPosition())
#else
    GenericMove(ByRef BCCurrentPosition(), False)
    UpdateClient(EVTNO_PRINT_EVENT, "keep same direction as caller,we move to ")
    PrintPosition(ByRef BCCurrentPosition())
#endif
    g_CurrentSingleF = ReadForce(forceName)
    BCTempDF = Abs(g_CurrentSingleF - threshold)
    msg$ = " with force=" + Str$(g_CurrentSingleF)
    UpdateClient(EVTNO_PRINT_EVENT, msg$)
    ''check best
    If BCBestDF < BCTempDF Then
    	UpdateClient(EVTNO_PRINT_EVENT, "best has small DF than perfect, so we go best")
        GenericMove(ByRef BCBestPosition(), False)
        g_CurrentSingleF = ReadForce(forceName)
        UpdateClient(EVTNO_PRINT_EVENT, "best P at ")
        PrintPosition(ByRef BCBestPosition())
        msg$ = " with force=" + Str$(g_CurrentSingleF)
        UpdateClient(EVTNO_PRINT_EVENT, msg$)
    EndIf
Fend
Function ForcePassedThreshold(ByVal forceName As Integer, ByVal currentForce As Real, ByVal threshold As Real) As Boolean
    ForcePassedThreshold = False
    If forceName > 0 Then
        If currentForce >= threshold Then
            ForcePassedThreshold = True
        EndIf
    Else
        If currentForce <= threshold Then
            ForcePassedThreshold = True
        EndIf
    EndIf
Fend
''This function has no safety check to make sure that moving toward the destination will change the force
''in the correct way.  Caller should make sure it works.
Function ForceScan(forceName As Integer, threshold As Real, ByRef destPosition() As Real, numSteps As Integer, fineTune As Boolean) As Boolean
	String msg$
	
    ForceScan = False
    
    'Save old position'
    GetCurrentPosition(ByRef FSOldPosition())
    
    PositionCopy(ByRef FSPrePosition(), ByRef FSOldPosition())
    FSPreForce = ReadForce(forceName)
    FSForce = FSPreForce
    UpdateClient(EVTNO_PRINT_EVENT, "old P: ")
    PrintPosition(ByRef FSOldPosition())
    msg$ = "old Force: " + Str$(FSForce) + " Threshold: " + Str$(threshold)
    UpdateClient(EVTNO_PRINT_EVENT, msg$)

    ''check current force
    If ForcePassedThreshold(forceName, FSPreForce, threshold) Then
    	UpdateClient(EVTNO_PRINT_EVENT, "-ForceScan: OK, already pass the threshold:SHOULD NOT HAPPEND")
        ForceScan = True
#ifdef BINARY_CROSS
        If fineTune Then BinaryCross(forceName, ByRef FSPrePosition(), FSPreForce, threshold, g_BinaryCrossTimes)
#endif
        Exit Function
    EndIf
    
    ''check input parameter
    If numSteps <= 0 Then numSteps = 10
    
    If HypDistance(ByRef destPosition(), ByRef FSOldPosition()) < 0.001 Then
    	UpdateClient(EVTNO_PRINT_EVENT, "-ForceScan: not touched, already at the destination")
        Exit Function
    EndIf
    
    For tmp_PIndex = 1 To 4
        FSStepSize(tmp_PIndex) = (destPosition(tmp_PIndex) - FSOldPosition(tmp_PIndex)) / numSteps
    Next
        
    ''scan
    For FSStepIndex = 1 To numSteps
        If g_FlagAbort Then
            Exit Function
        EndIf

        For tmp_PIndex = 1 To 4
            FSDesiredPosition(tmp_PIndex) = FSOldPosition(tmp_PIndex) + FSStepSize(tmp_PIndex) * FSStepIndex
        Next
        
        ''safety re-check
        FSHypStepSize = HypStepSize(ByRef FSStepSize())
        If HypDistance(ByRef FSDesiredPosition(), ByRef FSPrePosition()) > 1.5 * FSHypStepSize Then
            UpdateClient(EVTNO_PRINT_EVENT, "BAD BAD happened")
            Exit Function
        EndIf
      
        ''set up trigger and go
        SetupForceTrigger forceName, (1.2 * threshold)
        GenericMove(ByRef FSDesiredPosition(), True)
        GetCurrentPosition(ByRef g_CurrentP())

        If (g_FSForceTriggerStatus <> 0) Then
        	''Trigger occured
    		''Read force that caused trigger
    		g_CurrentSingleF = g_FSTriggeredForces(Abs(forceName))
    	Else
    		''Trigger did not occur
    		''Read current force
    		g_CurrentSingleF = ReadForce(forceName)
    	EndIf
        
        ''force reading check
        ForceChangeCheck forceName, FSHypStepSize, FSPreForce, g_CurrentSingleF

        ''whether we crossed the threshold
        If ForcePassedThreshold(forceName, g_CurrentSingleF, threshold) Then
        	msg$ = "step=" + Str$(FSStepIndex) + ", P: "
			UpdateClient(EVTNO_PRINT_EVENT, msg$)
			PrintPosition(ByRef g_CurrentP())
			msg$ = "force: " + Str$(g_CurrentSingleF)
			UpdateClient(EVTNO_PRINT_EVENT, msg$)
			UpdateClient(EVTNO_PRINT_EVENT, "we got it here")
            ForceScan = True
            Exit For
        EndIf
        
        ''whether we moved at all: this do happen, do not know reason
        If HypDistance(ByRef g_CurrentP(), ByRef FSDesiredPosition()) > 0.0001 Then
            ''Move without force sensor
            GenericMove(ByRef FSDesiredPosition(), False)
            GetCurrentPosition(ByRef g_CurrentP())

            ''re-whether we crossed the threshold
            g_CurrentSingleF = ReadForce(forceName)
            msg$ = "step=" + Str$(FSStepIndex) + ", NO TRIGGER P: "
			UpdateClient(EVTNO_PRINT_EVENT, msg$)
			PrintPosition(ByRef g_CurrentP())
						
			msg$ = "force: " + Str$(g_CurrentSingleF)
			UpdateClient(EVTNO_PRINT_EVENT, msg$)

            If ForcePassedThreshold(forceName, g_CurrentSingleF, threshold) Then
            	UpdateClient(EVTNO_PRINT_EVENT, "we got it here")
                ForceScan = True
                Exit For
            EndIf
        Else
        	msg$ = "step=" + Str$(FSStepIndex) + ", P: "
        	UpdateClient(EVTNO_PRINT_EVENT, msg$)
        	PrintPosition(ByRef g_CurrentP())
			msg$ = "Force: " + Str$(g_CurrentSingleF)
			UpdateClient(EVTNO_PRINT_EVENT, msg$)
        EndIf
        PositionCopy(ByRef FSPrePosition(), ByRef g_CurrentP())
        FSPreForce = g_CurrentSingleF
    Next
    
#ifdef BINARY_CROSS
    If ForceScan Then
         If fineTune Then BinaryCross(forceName, ByRef FSPrePosition(), FSPreForce, threshold, g_BinaryCrossTimes)
    EndIf
#endif
Fend

Function PrintForces(ByRef forces() As Double)
	String msg$
	
	msg$ = "FX: " + Str$(forces(1))
	UpdateClient(EVTNO_PRINT_EVENT, msg$)
	
	msg$ = "FY: " + Str$(forces(2))
	UpdateClient(EVTNO_PRINT_EVENT, msg$)
	
	msg$ = "FZ: " + Str$(forces(3))
	UpdateClient(EVTNO_PRINT_EVENT, msg$)
	
	msg$ = "TX: " + Str$(forces(4))
	UpdateClient(EVTNO_PRINT_EVENT, msg$)
	
	msg$ = "TY: " + Str$(forces(5))
	UpdateClient(EVTNO_PRINT_EVENT, msg$)
	
	msg$ = "TZ: " + Str$(forces(6))
	UpdateClient(EVTNO_PRINT_EVENT, msg$)
Fend

Function LogForces(ByRef forces() As Double)
    Print #LOG_FILE_NO, "FX: ", forces(1)
    Print #LOG_FILE_NO, "FY: ", forces(2)
    Print #LOG_FILE_NO, "FZ: ", forces(3)
    Print #LOG_FILE_NO, "TX: ", forces(4)
    Print #LOG_FILE_NO, "TY: ", forces(5)
    Print #LOG_FILE_NO, "TZ: ", forces(6)
Fend

Function CutMiddle(ByVal forceName As Integer) As Real
    forceName = Abs(forceName)
    
    ''prepare for call with argument
    CMMinForce = GetForceMin(forceName)
    CMThreshold = GetForceThreshold(forceName)
    GetCutMiddleData(forceName, ByRef CMScanRange, ByRef CMNumSteps)
    
    CutMiddle = CutMiddleWithArguments(forceName, CMMinForce, CMThreshold, CMScanRange, CMNumSteps)
Fend

Function ForcedCutMiddle(forceName As Integer) As Real
    forceName = Abs(forceName)
    
    ''prepare for call with argument
    CMMinForce = 0 ''this will force the function to run
    CMThreshold = GetForceThreshold(forceName)
    GetCutMiddleData(forceName, ByRef CMScanRange, ByRef CMNumSteps)
    
    ForcedCutMiddle = CutMiddleWithArguments(forceName, CMMinForce, CMThreshold, CMScanRange, CMNumSteps)
Fend

Function CutMiddleWithArguments(forceName As Integer, minForce As Real, threshold As Real, scanRange As Real, numSteps As Integer) As Real
    String msg$
	g_CutMiddleFailed = 0
	CutMiddleWithArguments = 0

    CMStepStart = g_CurrentSteps
    CMStepTotal = g_Steps
    
    forceName = Abs(forceName)

    CMMinForce = minForce
    CMThreshold = threshold
    CMScanRange = scanRange
    CMNumSteps = numSteps

    'Save old position'
    GetCurrentPosition(ByRef CMInitP())

    'Find out current Force situation
    'It maybe out of our +-g_ThresholdTZ, may be within
    CMInitForce = ReadForce(forceName)
    UpdateClient(EVTNO_PRINT_EVENT, "Init position ")
    PrintPosition(ByRef CMInitP())
    msg$ = " force: " + Str$(CMInitForce)
	UpdateClient(EVTNO_PRINT_EVENT, msg$)
	
    'within min, ignore it'
    If Abs(CMInitForce) < CMMinForce Then
        Print #LOG_FILE_NO, "force too small, ignore"
        Exit Function
    EndIf

    If CMInitForce > CMThreshold Then
        g_Steps = CMStepTotal /3
        'get +Threshold'
        If Not ForceCross(-forceName, CMThreshold, CMScanRange, CMNumSteps, True) Then
        	msg$ = "FTXTFallingCross " + Str$(CMThreshold) + " failed, give up"
        	UpdateClient(EVTNO_PRINT_EVENT, msg$)
            Print #LOG_FILE_NO, "FTXTFallingCross ", CMThreshold, " failed, give up"
			g_CutMiddleFailed = 1
            Exit Function
        EndIf
        GetCurrentPosition(ByRef CMPlusP())
        CMPlusForce = ReadForce(forceName)

        g_Steps = CMStepTotal /3
        g_CurrentSteps = CMStepStart + CMStepTotal /3
        msg$ = Str$(g_CurrentSteps) + " of 100"
        UpdateClient(EVTNO_CAL_STEP, msg$)
        
        'continue move pass -Threshold, then reverse get the -Threshold'
        If Not ForceCross(-forceName, -CMThreshold, CMScanRange, CMNumSteps, False) Then
        	msg$ = "FTXTFallingCross " + Str$(-CMThreshold) + " failed, give up"
        	UpdateClient(EVTNO_PRINT_EVENT, msg$)
            Print #LOG_FILE_NO, "FTXTFallingCross ", -CMThreshold, " failed, give up"
			g_CutMiddleFailed = 1
            Exit Function
        EndIf

        g_Steps = CMStepTotal /3
        g_CurrentSteps = CMStepStart + 2 * CMStepTotal / 3
        msg$ = Str$(g_CurrentSteps) + " of 100"
        UpdateClient(EVTNO_CAL_STEP, msg$)

        If Not ForceCross(forceName, -CMThreshold, CMScanRange, CMNumSteps, True) Then
        	msg$ = "FTXTRisingCross " + Str$(-CMThreshold) + " failed, give up"
        	UpdateClient(EVTNO_PRINT_EVENT, msg$)
            Print #LOG_FILE_NO, "FTXTRisingCross ", -CMThreshold, " failed, give up"
			g_CutMiddleFailed = 1
            Exit Function
        EndIf
        GetCurrentPosition(ByRef CMMinusP())
        CMMinusForce = ReadForce(forceName)
    Else
        If CMInitForce < -CMThreshold Then
            g_Steps = CMStepTotal /3
            'get -Threshold'
            If Not ForceCross(forceName, -CMThreshold, CMScanRange, CMNumSteps, True) Then
            	msg$ = "FTXTRisingCross " + Str$(-CMThreshold) + " failed, give up"
            	UpdateClient(EVTNO_PRINT_EVENT, msg$)
                Print #LOG_FILE_NO, "FTXTRisingCross ", -CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf
            GetCurrentPosition(ByRef CMMinusP())
            CMMinusForce = ReadForce(forceName)

            g_Steps = CMStepTotal /3
            g_CurrentSteps = CMStepStart + CMStepTotal /3
            msg$ = Str$(g_CurrentSteps) + " of 100"
            UpdateClient(EVTNO_CAL_STEP, msg$)

            'continue move pass +Threshold, then reverse get the +Threshold'
            If Not ForceCross(forceName, CMThreshold, CMScanRange, CMNumSteps, False) Then
            	msg$ = "FTXTRisingCross " + Str$(CMThreshold) + " failed, give up"
            	UpdateClient(EVTNO_PRINT_EVENT, msg$)
                Print #LOG_FILE_NO, "FTXTRisingCross ", CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf

            g_Steps = CMStepTotal /3
            g_CurrentSteps = CMStepStart + 2 * CMStepTotal / 3
            msg$ = Str$(g_CurrentSteps) + " of 100"
            UpdateClient(EVTNO_CAL_STEP, msg$)

            If Not ForceCross(-forceName, CMThreshold, CMScanRange, CMNumSteps, True) Then
            	msg$ = "FTXTFallingCross " + Str$(CMThreshold) + " failed, give up"
            	UpdateClient(EVTNO_PRINT_EVENT, msg$)
                Print #LOG_FILE_NO, "FTXTFallingCross ", CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf
            GetCurrentPosition(ByRef CMPlusP())
            CMPlusForce = ReadForce(forceName)
        Else
            'OK we need to go both ways
            g_Steps = CMStepTotal /4
            'move pass -Threshold, then reverse get the -Threshold
            If Not ForceCross(-forceName, -CMThreshold, CMScanRange, CMNumSteps, False) Then
            	msg$ = "FTXTFallingCross " + Str$(-CMThreshold) + " failed, give up"
            	UpdateClient(EVTNO_PRINT_EVENT, msg$)
                Print #LOG_FILE_NO, "FTXTFallingCross ", -CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf

            g_Steps = CMStepTotal /4
            g_CurrentSteps = CMStepStart + CMStepTotal /4
            msg$ = Str$(g_CurrentSteps) + " of 100"
            UpdateClient(EVTNO_CAL_STEP, msg$)

            If Not ForceCross(forceName, -CMThreshold, CMScanRange, CMNumSteps, True) Then
            	msg$ = "FTXTRisingCross " + Str$(-CMThreshold) + " failed, give up"
            	UpdateClient(EVTNO_PRINT_EVENT, msg$)
                Print #LOG_FILE_NO, "FTXTRisingCross ", -CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf
            GetCurrentPosition(ByRef CMMinusP())
            CMMinusForce = ReadForce(forceName)


            g_Steps = CMStepTotal /4
            g_CurrentSteps = CMStepStart + CMStepTotal /2
            msg$ = Str$(g_CurrentSteps) + " of 100"
            UpdateClient(EVTNO_CAL_STEP, msg$)

            'continue move pass +g_ThresholdTZ, then reverse get the +g_ThresholdTZ'
            If Not ForceCross(forceName, CMThreshold, CMScanRange, CMNumSteps, False) Then
            	msg$ = "FTXTRisingCross " + Str$(CMThreshold) + " failed, give up"
            	UpdateClient(EVTNO_PRINT_EVENT, msg$)
                Print #LOG_FILE_NO, "FTXTRisingCross ", CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf

            g_Steps = CMStepTotal /4
            g_CurrentSteps = CMStepStart + 3 * CMStepTotal / 4
            msg$ = Str$(g_CurrentSteps) + " of 100"
            UpdateClient(EVTNO_CAL_STEP, msg$)

            If Not ForceCross(-forceName, CMThreshold, CMScanRange, CMNumSteps, True) Then
            	msg$ = "FTXTFallingCross " + Str$(CMThreshold) + " failed, give up"
            	UpdateClient(EVTNO_PRINT_EVENT, msg$)
                Print #LOG_FILE_NO, "FTXTFallingCross ", CMThreshold, " failed, give up"
				g_CutMiddleFailed = 1
                Exit Function
            EndIf
            GetCurrentPosition(ByRef CMPlusP())
            CMPlusForce = ReadForce(forceName)
        EndIf
    EndIf

    'calculate the perfect position'
    ''middle of the minus and plus is safer than linear interpolate
    For tmp_PIndex = 1 To 4
        CMFinalP(tmp_PIndex) = (CMMinusP(tmp_PIndex) + CMPlusP(tmp_PIndex)) / 2
    Next
    GenericMove(ByRef CMFinalP(), False)
    
    CMPlusForce = ReadForce(forceName)
    
    Select forceName
    Case FORCE_XFORCE
		CutMiddleWithArguments = Abs(CMMinusP(1) - CMPlusP(1))
    Case FORCE_YFORCE
		CutMiddleWithArguments = Abs(CMMinusP(2) - CMPlusP(2))
    Case FORCE_ZFORCE
		CutMiddleWithArguments = Abs(CMMinusP(3) - CMPlusP(3))
    Case FORCE_XTORQUE
		CutMiddleWithArguments = Abs(CMMinusP(2) - CMPlusP(2))
    Case FORCE_YTORQUE
		CutMiddleWithArguments = Abs(CMMinusP(1) - CMPlusP(1))
    Case FORCE_ZTORQUE
		CutMiddleWithArguments = Abs(CMMinusP(4) - CMPlusP(4))
	Send
	
	msg$ = "CutMiddle " + Str$(forceName)
	UpdateClient(EVTNO_PRINT_EVENT, msg$)
    UpdateClient(EVTNO_PRINT_EVENT, "position moved from")
    PrintPosition(ByRef CMInitP())
    UpdateClient(EVTNO_PRINT_EVENT, " to ")
    PrintPosition(ByRef CMFinalP())
    msg$ = ", force changed from " + Str$(CMInitForce) + " to " + Str$(CMPlusForce)
	UpdateClient(EVTNO_PRINT_EVENT, msg$)
    Print #LOG_FILE_NO, "CutMiddle ", forceName,
    Print #LOG_FILE_NO, "position moved from ",
    LogPosition(ByRef CMInitP())
    Print #LOG_FILE_NO, " to ",
    LogPosition(ByRef CMFinalP())
    Print #LOG_FILE_NO, ", force changed from ", CMInitForce, " to ", CMPlusForce
    
    msg$ = "Freedom: " + Str$(CutMiddleWithArguments)
    UpdateClient(EVTNO_PRINT_EVENT, msg$)
    Print #LOG_FILE_NO, "Freedom: ", CutMiddleWithArguments
Fend

Function LidMonitor
   	Double meforces(6)
    ''monitor IO bit and send VB event if desired bits are changed
    WOpen "LidMonitor.Txt" As #50
    Print #50, "LidMonitor at ", Date$, " ", Time$
    IOPreInputValue = InW(0)
    IOPreOutputValue = OutW(0)
    
    g_IOMCounter = 0
    g_LidOpened = 0
    
    Print "current IO input  Bit ", Hex$(IOPreInputValue)
    Print "current IO output Bit ", Hex$(IOPreOutputValue)
    Print #50, "current IO input  Bit ", Hex$(IOPreInputValue)
    Print #50, "current IO output Bit ", Hex$(IOPreOutputValue)
	
	''dont use UpdateClient here as messages are long type
	SPELCom_Event EVTNO_INPUT, IOPreInputValue
    SPELCom_Event EVTNO_OUTPUT, IOPreOutputValue
    
    Do While Not SafetyOn
        IOCurInputValue = InW(0)
        IOCurOutputValue = OutW(0)

#ifndef NO_DEWAR_LID
        ''check if lid opened by human
        If BTst(IOCurOutputValue, OUT_LID) = 0 And BTst(IOPreInputValue, IN_LID_CLOSE) = 1 And BTst(IOCurInputValue, IN_LID_CLOSE) = 0 Then
        	UpdateClient(EVTNO_LID_OPEN, "dewar lid is opened manually")
            Print #50, "dewar lid is opened at", Date$, " ", Time$
            Print "dewar lid is opened at", Date$, " ", Time$
            g_LidOpened = g_LidOpened + 1
        EndIf
#endif
        
        If IOCurInputValue <> IOPreInputValue Then
            Print #50, "IO input changed, new value: ", Hex$(IOCurInputValue)
            Print "IO input changed, new value: ", Hex$(IOCurInputValue)
            IOPreInputValue = IOCurInputValue
        EndIf

        ''alway send out the input bits
        SPELCom_Event EVTNO_INPUT, IOPreInputValue

		''only send out output bit if it is changed
        If IOCurOutputValue <> IOPreOutputValue Then
            Print #50, "IO output changed, new value: ", Hex$(IOCurOutputValue)
            Print "IO output changed, new value: ", Hex$(IOCurOutputValue)
            IOPreOutputValue = IOCurOutputValue
		    SPELCom_Event EVTNO_OUTPUT, IOPreOutputValue
        EndIf

        Wait 1
        g_IOMCounter = g_IOMCounter + 1
    Loop
    
    Close #50
Fend

Function CheckPoint(Number As Integer)
    Real x;
    OnErr GoTo PointNotExist
    x = CX(P(Number))
    Exit Function
PointNotExist:
    ''EClr no longer necessary in version 6.2.0
    Print "Point ", Number, " not exist, init to all 0"
    P(Number) = XY(0, 0, 0, 0)
    OnErr GoTo 0
Fend
Function CheckToolSet(Number As Integer)
    OnErr GoTo ToolSetNotExit
    P51 = TLSet(Number)
    Exit Function
ToolSetNotExit:
    ''EClr no longer necessary in version 6.2.0
    TLSet Number, XY(0, 0, 0, 0)
    OnErr GoTo 0
    Exit Function
Fend
Function FromHomeToTakeMagnet As Boolean
	String msg$
    FromHomeToTakeMagnet = False
    
    ''Calibrate the force sensor and check its readback health
	If Not ForceCalibrateAndCheck(HIGH_SENSITIVITY, HIGH_SENSITIVITY) Then
		UpdateClient(EVTNO_PRINT_EVENT, "Stopping FromHomeToTakeMagnet..")
		''problem with force sensor so exit
		Exit Function
	EndIf
    
    If Not Check_Gripper Then
    	UpdateClient(EVTNO_CAL_MSG, "FromHomeToTakeMagnet: abort: check gripper failed at home")
    	UpdateClient(EVTNO_HARDWARE_LOG_ERROR, "FromHomeToTakeMagnet: abort: check gripper failed at home")
        Print "Check_Gripper failed at home, aborted"
        Exit Function
    EndIf
    If Not Open_Lid Then
    	UpdateClient(EVTNO_CAL_MSG, "FromHomeToTakeMagnet: abort: open lid failed")
    	UpdateClient(EVTNO_HARDWARE_LOG_ERROR, "FromHomeToTakeMagnet: abort: open lid failed")
        Print "FromHomeToTakeMagnet: abort: open lid failed"
        Exit Function
    EndIf

    SetFastSpeed
    LimZ 0
    Tool 0
    Jump P1

    If g_FlagAbort Then
		Close_Lid
		Jump P0
        Exit Function
    EndIf

    ''take magnet
    Jump P3
    If g_LN2LevelHigh Then
    	UpdateClient(EVTNO_CAL_MSG, "FromHomeToTakeMagnet: cooling tongs until LN2 boiling is undetectable")
    	UpdateClient(EVTNO_PRINT_EVENT, "FromHomeToTakeMagnet: cooling tongs until LN2 boiling is undetectable")
    	msg$ = "Cooled tong for " + Str$(WaitLN2BoilingStop(SENSE_TIMEOUT, HIGH_SENSITIVITY, HIGH_SENSITIVITY)) + " seconds"
    	UpdateClient(EVTNO_CAL_MSG, msg$)
    	UpdateClient(EVTNO_PRINT_EVENT, msg$)
        If g_IncludeStrip Then
			Move Here -Z(STRIP_PLACER_Z_OFFSET)
        EndIf
        Move P3
        ''check gripper again after cooling down
        If Not Check_Gripper Then
            Print "Check_Gripper failed after cooling down, aborting"
            UpdateClient(EVTNO_CAL_MSG, "FromHomeToTakeMagnet: abort: check gripper failed at cooling point")
            UpdateClient(EVTNO_HARDWARE_LOG_ERROR, "FromHomeToTakeMagnet: abort: check gripper failed at cooling point")
            Jump P1
            Close_Lid
            Jump P0
            MoveTongHome
            Exit Function
        EndIf
    EndIf

    If Not Open_Gripper Then
        Print "open gripper failed after cooling down, aborting"
        UpdateClient(EVTNO_CAL_MSG, "FromHomeToTakeMagnet: abort: open gripper failed at cooling point")
        UpdateClient(EVTNO_HARDWARE_LOG_ERROR, "FromHomeToTakeMagnet: abort: open gripper failed at cooling point")
        Jump P1
        Close_Lid
        Jump P0
        MoveTongHome
        Exit Function
    EndIf

    If g_FlagAbort Then
        Exit Function
    EndIf

    Move P6
    
    If Not CheckMagnet Then
		Exit Function
    EndIf

    Move Here +Z(20)

    If Not Close_Gripper Then
        Print "close gripper failed at holding magnet, aborting"
        UpdateClient(EVTNO_CAL_MSG, "FromHomeToTakeMagnet: abort: close gripper failed at magnet")
        UpdateClient(EVTNO_HARDWARE_LOG_ERROR, "FromHomeToTakeMagnet: abort: close gripper failed at magnet")
        Move P6
        If Not Open_Gripper Then
            Print "open gripper failed at aborting from magnet, need Reset"
            UpdateClient(EVTNO_CAL_MSG, "open gripper failed at aborting from magnet, need Reset")
            UpdateClient(EVTNO_HARDWARE_LOG_SEVERE, "open gripper failed at aborting from magnet, need Reset")
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
            g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
            Motor Off
            Quit All
        EndIf
        Move P3
        Jump P1
        Close_Lid
        Jump P0
        MoveTongHome
        Exit Function
    EndIf
    g_HoldMagnet = True
    FromHomeToTakeMagnet = True
Fend

Function DisplayToolSet(Tl As Integer)
    P51 = TLSet(Tl)
    Print #LOG_FILE_NO, "ToolSet[", Tl, "]=(", CX(P51), ", ", CY(P51), ", ", CZ(P51), ", ", CU(P51), ")"
    Print "ToolSet[", Tl, "]=(", CX(P51), ", ", CY(P51), ", ", CZ(P51), ", ", CU(P51), ")"
Fend

Function Recovery
    Tool 0
    LimZ 0
    SetFastSpeed
	
    If isCloseToPoint(0) Or isCloseToPoint(1) Then
        Jump P0
        Close_Lid
        Exit Function
    EndIf

    If Not g_SafeToGoHome Then
        g_RunResult$ = "not safe to go home"
        ''SPELCom_Return 1
        Exit Function
    EndIf
    If g_HoldMagnet Then
        Move Here :Z(g_Jump_LimZ_LN2)
        Move P6 :Z(g_Jump_LimZ_LN2)
        Move P6 +Z(20)
        ''if we cannot open gripper, we will stop right here, not go home
        g_SafeToGoHome = False
        If Not Open_Gripper Then
            g_RunResult$ = "Recovery: Open_Gripper Failed, holding magnet, need Reset"
            UpdateClient(EVTNO_CAL_MSG, g_RunResult$)
            UpdateClient(EVTNO_HARDWARE_LOG_SEVERE, g_RunResult$)
            Print g_RunResult$
            g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
            g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
            Motor Off
            Quit All
        EndIf
        Move P6
        Move P3
    EndIf
    MoveTongHome
    ''SPELCom_Return 0
Fend



''only used when it is in free space at beginning
Function QuickCutMiddle(ByVal forceName As Integer)
    forceName = Abs(forceName)

    'Save old position'
    GetCurrentPosition(ByRef CMInitP())

    'Find out current Force situation
    'It maybe out of our +-g_ThresholdTZ, may be within
    CMInitForce = ReadForce(forceName)
    Print "Init position ",
    PrintPosition(ByRef CMInitP())
    Print " force: ", CMInitForce

    CMThreshold = GetForceThreshold(forceName)
    ''CMThreshold = Abs(CMThreshold) ''no need, we already Abs(forceName)
    GetCutMiddleData(forceName, ByRef CMScanRange, ByRef CMNumSteps)
    If Not ForceTouch(forceName, CMScanRange, True) Then
        Print "ForceTouch failed, give up"
        Print #LOG_FILE_NO, "ForceTouch failed, give up"
        GenericMove(ByRef CMInitP(), False)
        Exit Function
    EndIf
    GetCurrentPosition(ByRef CMPlusP())

    GenericMove(ByRef CMInitP(), False)

    If Not ForceTouch(-forceName, CMScanRange, True) Then
        Print "ForceTouch failed, give up"
        Print #LOG_FILE_NO, "ForceTouch failed, give up"
        GenericMove(ByRef CMInitP(), False)
        Exit Function
    EndIf
    GetCurrentPosition(ByRef CMMinusP())

    'calculate the perfect position'
    ''middle of the minus and plus is safer than linear interpolate
    For tmp_PIndex = 1 To 4
        CMFinalP(tmp_PIndex) = (CMMinusP(tmp_PIndex) + CMPlusP(tmp_PIndex)) / 2
    Next
    GenericMove(ByRef CMFinalP(), False)
    
    CMPlusForce = ReadForce(forceName)

    Print "CutMiddle ", forceName,
    Print "position moved from ",
    PrintPosition(ByRef CMInitP())
    Print " to ",
    PrintPosition(ByRef CMFinalP())
    Print ", force changed from ", CMInitForce, " to ", CMPlusForce

    Print #LOG_FILE_NO, "CutMiddle ", forceName,
    Print #LOG_FILE_NO, "position moved from ",
    LogPosition(ByRef CMInitP())
    Print #LOG_FILE_NO, " to ",
    LogPosition(ByRef CMFinalP())
    Print #LOG_FILE_NO, ", force changed from ", CMInitForce, " to ", CMPlusForce
Fend

Function SavePointHistory(ByVal Number As Integer, ByVal Cnt As Integer)
    
    SPHFileName$ = CurDrive$ + ":\EpsonRC60\projects\Try-6\PointHistory"
    If Not FolderExists(SPHFileName$) Then
        MkDir SPHFileName$
    EndIf
    
    SPHFileName$ = SPHFileName$ + "\P" + Str$(Number) + ".csv"
    
    If FileExists(SPHFileName$) Then
        AOpen SPHFileName$ As #POINT_FILE_NO
    Else
        WOpen SPHFileName$ As #POINT_FILE_NO
        Print #POINT_FILE_NO, "Name,X,Y,Z,U,CAL_COUNT,TimeStamp"
    EndIf
    Print #POINT_FILE_NO, "P" + Str$(Number), ",", CX(P(Number)), ",", CY(P(Number)), ",", CZ(P(Number)), ",", CU(P(Number)), ",", Cnt, ",", Date$, " ", Time$
    Close #POINT_FILE_NO
Fend

Function SaveToolSetHistory(ByVal Number As Integer, ByVal Cnt As Integer)
    
    SPHFileName$ = CurDrive$ + ":\EpsonRC\projects\try\PointHistory"
    If Not FolderExists(SPHFileName$) Then
        MkDir SPHFileName$
    EndIf
    
    SPHFileName$ = SPHFileName$ + "\TLSET" + Str$(Number) + ".csv"
    
    If FileExists(SPHFileName$) Then
        AOpen SPHFileName$ As #POINT_FILE_NO
    Else
        WOpen SPHFileName$ As #POINT_FILE_NO
        Print #POINT_FILE_NO, "Name,X,Y,Z,U,CAL_COUNT,TimeStamp"
    EndIf
    P51 = TLSet(Number)
    Print #POINT_FILE_NO, "TLSET" + Str$(Number), ",", CX(P51), ",", CY(P51), ",", CZ(P51), ",", CU(P51), ",", Cnt, ",", Date$, " ", Time$
    Close #POINT_FILE_NO
Fend

Function SetVeryFastSpeed
    Accel 30, 30, 30, 30, 30, 30
    Speed 5
    
    AccelS 200
    SpeedS 50
Fend

Function Open_Lid As Boolean
#ifdef NO_DEWAR_LID
   	Open_Lid = True
#else
    On OUT_LID
    Wait Sw(IN_LID_OPEN) = 1, 6
    If TW = 1 Then
    	Print "Open lid failed"
    	Open_Lid = False
    Else
    	Open_Lid = True
    EndIf
#endif
Fend

Function Close_Lid As Boolean
#ifdef NO_DEWAR_LID
   	Close_Lid = True
#else
    Off OUT_LID
    Wait Sw(IN_LID_CLOSE) = 1, 6
    If TW = 1 Then
    	Print "Close lid failed"
    	Close_Lid = False
    Else
    	Close_Lid = True
    EndIf
#endif
Fend

Function Open_Gripper As Boolean
    Off OUT_GRIP
    Wait Sw(IN_GRIP_OPEN) = 1, 2
    If TW = 1 Then
    	Print "Open gripper failed"
    	Open_Gripper = False
    Else
    	Open_Gripper = True
    EndIf
Fend

Function Close_Gripper As Boolean
    On OUT_GRIP
    Wait Sw(IN_GRIP_CLOSE) = 1, 2
    If TW = 1 Then
    	Print "Close gripper failed"
    	Close_Gripper = False
    Else
    	Close_Gripper = True
    EndIf
Fend

Function Check_Gripper As Boolean
    Check_Gripper = False

    ''Check_Gripper
    If Not Close_Gripper Then
    	UpdateClient(EVTNO_CAL_MSG, "abort: failed to close gripper")
    	UpdateClient(EVTNO_HARDWARE_LOG_ERROR, "abort: failed to close gripper")
    	Print "Check gripper: Failed to close gripper"
        Exit Function
    EndIf
    If Not Open_Gripper Then
    	UpdateClient(EVTNO_CAL_MSG, "abort: failed to open gripper")
    	UpdateClient(EVTNO_HARDWARE_LOG_ERROR, "abort: failed to open gripper")
    	Print "Check gripper: Failed to open gripper"
        Exit Function
    EndIf
    If Not Close_Gripper Then
    	UpdateClient(EVTNO_CAL_MSG, "abort: failed to close gripper")
    	UpdateClient(EVTNO_HARDWARE_LOG_ERROR, "abort: failed to close gripper")
     	Print "Check gripper: Failed to close gripper2"
        Exit Function
    EndIf
    
    Check_Gripper = True
Fend
Function ForceChangeCheck(forceName As Integer, distance As Real, prevForce As Real, curForce As Real) As Boolean
	String msg$
	ForceChangeCheck = False
    distance = Abs(distance)
    forceName = Abs(forceName)

    If distance <= 0.0001 Then
        distance = 1
    EndIf

    FCCRate = Abs(curForce - prevForce) / distance

    Select Abs(forceName)
    Case FORCE_ZFORCE
        FCCStandord = g_RateFZ
    Case FORCE_XTORQUE
        FCCStandord = g_RateTX
    Case FORCE_YTORQUE
        FCCStandord = g_RateTY
    Case FORCE_ZTORQUE
        FCCStandord = g_RateTZ
    Default
        Exit Function
    Send
    
    ''check whether the change is too big to be true
    If FCCRate > (10 * FCCStandord) Then
        g_RunResult$ = "force sensor reading bad, check cable"
        msg$ = "abort: force sensor bad: rate " + Str$(FCCRate) + " too big for" + Str$(forceName)
        UpdateClient(EVTNO_CAL_MSG, msg$)
        UpdateClient(EVTNO_HARDWARE_LOG_ERROR, msg$)
        Print g_RunResult$, " forcename=", forceName, " rate=", FCCRate, " exceed 10*", FCCStandord
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
        g_RobotStatus = g_RobotStatus Or FLAG_REASON_ABORT
        ''Motor Off
        ''Quit All
        Exit Function
    EndIf
    
    ''check force value
    If Abs(prevForce) > 100 Or Abs(curForce) > 100 Then
        g_RunResult$ = "too strong force, check cable"
        UpdateClient(EVTNO_CAL_MSG, "abort: force too strong, may be cable broken")
        UpdateClient(EVTNO_HARDWARE_LOG_ERROR, "abort: force too strong, may be cable broken")
        Print "too strong force, shutdown. prevF=", prevForce, " curF=", curForce
        g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
        g_RobotStatus = g_RobotStatus Or FLAG_REASON_ABORT
        ''Motor Off
        ''Quit All
        Exit Function
    EndIf
	ForceChangeCheck = True
Fend

''check if magnet is really there
''should be called only when holding magnet
Function CheckMagnet As Boolean
	String msg$
	CheckMagnet = False
	
	Print "+CheckMagnet"

	CKMGripperClosed = Oport(OUT_GRIP)

    If CKMGripperClosed = 0 Then
		If Not Close_Gripper Then
			UpdateClient(EVTNO_PRINT_EVENT, "close gripper failed at checking magnet, aborting")
			UpdateClient(EVTNO_CAL_MSG, "CheckMagnet: close gripper failed")
			UpdateClient(EVTNO_HARDWARE_LOG_ERROR, "CheckMagnet: close gripper failed")

			If Not Open_Gripper Then
				UpdateClient(EVTNO_PRINT_EVENT, "open gripper failed at aborting from magnet, need Reset")
				UpdateClient(EVTNO_CAL_MSG, "open gripper failed at aborting from magnet, need Reset")
				UpdateClient(EVTNO_HARDWARE_LOG_SEVERE, "open gripper failed at aborting from magnet, need Reset")
				g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
				g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
				Motor Off
				Quit All
			EndIf
			Move P3
			Jump P1
			Close_Lid
			Jump P0
			MoveTongHome
			Exit Function
		EndIf
	EndIf

    Wait TIME_WAIT_BEFORE_RESET
	If ForceCalibrateAndCheck(LOW_SENSITIVITY, LOW_SENSITIVITY) Then
		UpdateClient(EVTNO_PRINT_EVENT, "Force reset check done")
	    TongMove DIRECTION_MAGNET_TO_CAVITY, 0.5, False
		CKMForce = ReadForce(FORCE_YTORQUE)
	    TongMove DIRECTION_CAVITY_TO_MAGNET, 0.5, False
	    
		msg$ = "Abs CKMForce is " + Str$(Abs(CKMForce))
		UpdateClient(EVTNO_PRINT_EVENT, msg$)
		
		msg$ = "g_FCheckMagnet is " + Str$(g_FCheckMagnet)
		UpdateClient(EVTNO_PRINT_EVENT, msg$)
		
		If Abs(CKMForce) >= g_FCheckMagnet Then
			CheckMagnet = True
		Else
			g_RunResult$ = "maybe dumpbell not in cradle"
			UpdateClient(EVTNO_PRINT_EVENT, g_RunResult$)
			UpdateClient(EVTNO_CAL_MSG, g_RunResult$)
			UpdateClient(EVTNO_WARNING, g_RunResult$)
			UpdateClient(EVTNO_UPDATE, g_RunResult$)
		EndIf
	EndIf
	
    If CKMGripperClosed = 0 Then
		If Not Open_Gripper Then
			UpdateClient(EVTNO_PRINT_EVENT, "open gripper failed at end of checking magnet, need Reset")
			UpdateClient(EVTNO_CAL_MSG, "open gripper failed at end of checking magnet, need Reset")
			UpdateClient(EVTNO_HARDWARE_LOG_SEVERE, "open gripper failed at end of checking magnet, need Reset")
			g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
			g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
			Motor Off
			Quit All
		EndIf
	EndIf
	
	If Not CheckMagnet Then
		If Not Open_Gripper Then
			UpdateClient(EVTNO_PRINT_EVENT, "open gripper failed after check magnet failed, need Reset")
			UpdateClient(EVTNO_CAL_MSG, "open gripper failed after check magnet failed, need Reset")
			UpdateClient(EVTNO_HARDWARE_LOG_SEVERE, "open gripper failed after check magnet failed, need Reset")
			g_RobotStatus = g_RobotStatus Or FLAG_NEED_RESET
			g_RobotStatus = g_RobotStatus Or FLAG_REASON_GRIPPER_JAM
			Motor Off
			Quit All
		EndIf
		Move P3
		Jump P1
		Close_Lid
		Jump P0
		MoveTongHome
		Exit Function
	Else
		''success.  Prepare for postcalibration by closing grippers
		If Not Close_Gripper Then
			UpdateClient(EVTNO_PRINT_EVENT, "CheckMagnet: close gripper failed")
			UpdateClient(EVTNO_CAL_MSG, "CheckMagnet: close gripper failed")
			UpdateClient(EVTNO_HARDWARE_LOG_ERROR, "CheckMagnet: close gripper failed")
		EndIf
	EndIf
Fend
Function NarrowAngle(angle As Real) As Real
	NarrowAngle = angle
	Do While NarrowAngle <= -180.0
		NarrowAngle = NarrowAngle + 360.0
	Loop
	Do While NarrowAngle > 180.0
		NarrowAngle = NarrowAngle - 360.0
	Loop
Fend
''Use this function to set the site configurable global variables
Function SetGlobals
g_LeftarmSystem = 0
g_IncludeStrip = 0
g_Perfect_Cradle_Angle = 90
g_Perfect_U4Holder = 90
g_Perfect_DownStream_Angle = 180
g_Perfect_LeftCassette_Angle = 90
g_Perfect_MiddleCassette_Angle = 180
g_Perfect_RightCassette_Angle = -90
g_Jump_LimZ_LN2 = -5
g_Jump_LimZ_Magnet = -5
g_Perfect_Cassette_Angle = 0
g_MagnetTransportAngle = 94.9439
g_U4MagnetHolder = 94.638
g_PickerWallToHead = -0.676804
g_PlacerWallToHead = 1.26004
g_Picker_X = 193.221
g_Picker_Y = 407.535
g_Placer_X = 202.888
g_Placer_Y = 337.548
g_ToolSet_A = 13.779
g_ToolSet_B = 20.8719
g_ToolSet_C = 14.7281
g_ToolSet_Theta = 0.305809
g_Dumbbell_Free_Y = 1.18741
g_IncludeFindMagnet = -1
g_Quick = 0
g_AtLeastOnce = -1
g_TQScale_Picker = 1.3316067457199
g_TQScale_Placer = -1.3087668269873
g_SideScale_Picker = 1.1956003457308
g_SideScale_Placer = 1.2594241499901
g_OnlyAlongAxis = 0
g_LN2LevelHigh = 1
Fend
''check if global varables set correctly for Australian Synchrotron.
''Check if force sensor initialized ok
Function CheckEnvironment As Boolean
	''default is environment is ok
	CheckEnvironment = True
	''check critical global variables
	If g_Perfect_Cradle_Angle <> 90 Then
		UpdateClient(EVTNO_PRINT_EVENT, "Problem detected with global variable g_Perfect_Cradle_Angle")
		CheckEnvironment = False
	EndIf
	If g_Perfect_U4Holder <> 90 Then
		UpdateClient(EVTNO_PRINT_EVENT, "Problem detected with global variable g_Perfect_U4Holder")
		CheckEnvironment = False
	EndIf
	If g_Perfect_DownStream_Angle <> 180 Then
		UpdateClient(EVTNO_PRINT_EVENT, "Problem detected with global variable g_Perfect_DownStream_Angle")
		CheckEnvironment = False
	EndIf
	If g_Perfect_LeftCassette_Angle <> 90 Then
		UpdateClient(EVTNO_PRINT_EVENT, "Problem detected with global variable g_Perfect_LeftCassette_Angle")
		CheckEnvironment = False
	EndIf
	If g_Perfect_MiddleCassette_Angle <> 180 Then
		UpdateClient(EVTNO_PRINT_EVENT, "Problem detected with global variable g_Perfect_MiddleCassette_Angle")
		CheckEnvironment = False
	EndIf
	If g_Perfect_RightCassette_Angle <> -90 Then
		UpdateClient(EVTNO_PRINT_EVENT, "Problem detected with global variable g_Perfect_RightCassette_Angle")
		CheckEnvironment = False
	EndIf
	If g_MagnetTransportAngle < 80 Or g_MagnetTransportAngle > 100 Then
		UpdateClient(EVTNO_PRINT_EVENT, "Problem detected with global variable g_MagnetTransportAngle")
		CheckEnvironment = False
	EndIf
	If g_U4MagnetHolder < 80 Or g_U4MagnetHolder > 100 Then
		UpdateClient(EVTNO_PRINT_EVENT, "Problem detected with global variable g_U4MagnetHolder")
		CheckEnvironment = False
	EndIf
	If Not g_FSInitOK Then
		UpdateClient(EVTNO_PRINT_EVENT, "Problem detected with force sensor")
		CheckEnvironment = False
	EndIf
	If Not CheckEnvironment Then
		UpdateClient(EVTNO_PRINT_EVENT, "Problem with global variable values, or force sensor")
		UpdateClient(EVTNO_PRINT_EVENT, "Set global variables by running SetGlobals")
		UpdateClient(EVTNO_PRINT_EVENT, "Or correct force sensor problem")
	EndIf
Fend
Function PrintGlobals
	''globals
''===========================================================
''left arm or right arm system

Print "g_LeftarmSystem=", g_LeftarmSystem

Print "g_IncludeStrip=", g_IncludeStrip
''=========================================
''we support more generic orientation now.
''so these should be configured by SITE,
''not initialized by left or right arm anymore.
''these should be 0 or 90 or -90 or 180.
Print "g_Perfect_Cradle_Angle=", g_Perfect_Cradle_Angle
Print "g_Perfect_U4Holder=", g_Perfect_U4Holder
Print "g_Perfect_DownStream_Angle=", g_Perfect_DownStream_Angle

''for right arm system, normally 90, 180, -90
''for left arm system normally, -90, 0, 90
Print "g_Perfect_LeftCassette_Angle=", g_Perfect_LeftCassette_Angle
Print "g_Perfect_MiddleCassette_Angle=", g_Perfect_MiddleCassette_Angle
Print "g_Perfect_RightCassette_Angle=", g_Perfect_RightCassette_Angle

''=================================================
''g_Jump_LimZ_LN2 should be the Limz to keep dumbell and cavity in LN2 but clear all obstacles
''g_Jump_LimZ_Magnet should be the same or lower then g_Jump_LimZ_LN2.
''need only clear the dumbell cradle.
Print "g_Jump_LimZ_LN2=", g_Jump_LimZ_LN2
Print "g_Jump_LimZ_Magnet=", g_Jump_LimZ_Magnet

''==============================================================
''will hold the perfect value for current cassette in calibration
Print "g_Perfect_Cassette_Angle=", g_Perfect_Cassette_Angle

''===================================================================
''g_MagnetTransportAngle: transport angle in robot coordinates.
''In ideal world, this should by 90 degree from the X axis of robot.
''This variable is set by PickerTouchSeat
''In angle tranform, If current U == g_U4MagnetHolder,
''the dumb bell is in direction of g_MagnetTransportAngle in robot coordinate system
Print "g_MagnetTransportAngle=", g_MagnetTransportAngle ''angle of dumbbell in post
Print "g_U4MagnetHolder=", g_U4MagnetHolder      ''angle of U when dumbbell in post

''theory value should be (10-9.44)/2 = 0.28
Print "g_PickerWallToHead=", g_PickerWallToHead
Print "g_PlacerWallToHead=", g_PlacerWallToHead

''==========================================================
''for toolset calibration
Print "g_Picker_X=", g_Picker_X
Print "g_Picker_Y=", g_Picker_Y
Print "g_Placer_X=", g_Placer_X
Print "g_Placer_Y=", g_Placer_Y
Print "g_ToolSet_A=", g_ToolSet_A
Print "g_ToolSet_B=", g_ToolSet_B
Print "g_ToolSet_C=", g_ToolSet_C
Print "g_ToolSet_Theta=", g_ToolSet_Theta

''the sliding freedom for dumbbell in cradle
''It is used to correct picker and placer calibration
Print "g_Dumbbell_Free_Y=", g_Dumbbell_Free_Y

''=========================================================
''main function cannot have parameters so
Print "g_IncludeFindMagnet=", g_IncludeFindMagnet
Print "g_Quick=", g_Quick
Print "g_AtLeastOnce=", g_AtLeastOnce

''==========================================================================
''scale factor for port probing: torque to millimeter
Print "g_TQScale_Picker=", g_TQScale_Picker
Print "g_TQScale_Placer=", g_TQScale_Placer

''scale factor for port side probing
Print "g_SideScale_Picker=", g_SideScale_Picker
Print "g_SideScale_Placer=", g_SideScale_Placer

''================================================================
''if true, any move will be along X,Y Axis, no arbitory direction move.
Print "g_OnlyAlongAxis=", g_OnlyAlongAxis

Print "g_LN2LevelHigh=", g_LN2LevelHigh

Fend
''Only for SSRL sample mounting system
Function PutMagnetInCradleAndGoHome
	String error$
	''setup error handler to catch errors
	OnErr GoTo errHandler
	If Motor = Off Then
		Motor On
	EndIf
	Open_Lid
	LimZ 0
	Power Low
	Close_Gripper
	Tool 0
	Jump P6 +Z(15)
	Move P6
	Open_Gripper
	Move P3
	Close_Gripper
	Jump P1
	Close_Lid
	Jump P0

SkipTask:
	Exit Function

errHandler:
	''construct error string to send back to host
	error$ = "PutMagnetInCradleAndGoHome !!Error: " + Str$(Err) + " " + ErrMsg$(Err) + Str$(Erl)
	''indicate error occured
	g_foreretval = Err
	''inform client about error
	UpdateClient(EVTNO_FOREGROUND_ERR, error$)
    EResume SkipTask
Fend
''Only for SSRL sample mounting system
''Retrieve dumbell from cradle and bring to p1
Function DumbellFromLN2
	String error$
	''setup error handler to catch errors
	OnErr GoTo errHandler
	''We want toolset 0
	Tool 0
	SetVeryFastSpeed
	''Clear frame on home side
	If isCloseToPoint(0) Then
		Jump P1
	EndIf
	Open_Lid()
	''Jump to cooling point
	Jump P3
	Open_Gripper()
	''move to dumbell
	Move P6
	Close_Gripper()
	Jump P1
	Close_Lid()
	
SkipTask:
	Exit Function

errHandler:
	''construct error string to send back to host
	error$ = "DumbellFromLN2 !!Error: " + Str$(Err) + " " + ErrMsg$(Err) + Str$(Erl)
	''indicate error occured
	g_foreretval = Err
	''inform client about error
	UpdateClient(EVTNO_FOREGROUND_ERR, error$)
    EResume SkipTask
Fend
''Only for SSRL sample mounting system
Function FromHomeGetPickerSample
	String error$
	String msg$
	''setup error handler to catch errors
	OnErr GoTo errHandler
	''We want toolset 0
	Tool 0
	''Clear frame on home side
	If isCloseToPoint(0) Then
		Jump P1
	EndIf
	''ensure lid is open
	Open_Lid
	''Proceed into dewar
	''Jump to Picker position but 20mm X off
	Jump P16 -X(20)
	''Cool tongs
	If g_LN2LevelHigh Then
		UpdateClient(EVTNO_CAL_MSG, "FromHomeGetPickerSample: Cooling tongs until LN2 boiling becomes undetectable")
        msg$ = "Cooled tong for " + Str$(WaitLN2BoilingStop(SENSE_TIMEOUT, HIGH_SENSITIVITY, HIGH_SENSITIVITY)) + " seconds"
        UpdateClient(EVTNO_CAL_MSG, msg$)
	EndIf
	Open_Gripper
	''Move to picker position
	Move P16
	Close_Gripper
	''back away from picker holding sample
	TwistRelease()
SkipTask:
	Exit Function

errHandler:
	''construct error string to send back to host
	error$ = "FromHomeGetPickerSample !!Error: " + Str$(Err) + " " + ErrMsg$(Err)
	''indicate error occured
	g_foreretval = Err
	''inform client about error
	UpdateClient(EVTNO_FOREGROUND_ERR, error$)
    EResume SkipTask
Fend
Function SampleFromDewarToGonio
	String error$
	''setup error handler to catch errors
	OnErr GoTo errHandler
	''Clear frame on gonio side	
	Jump P18
	''Move to midway point
	Arc P28, P38 CP
	''move to mount standby
	Move P24
	''Move to gonio
	Move P20
	Open_Gripper
	''Move to dismount standby
	Move P23
	Close_Gripper
	''Move to midway point
	Move P38
	''Clear frame on gonio side
	Arc P28, P18 CP
	''Clear frame on home side
	Jump P1
	Close_Lid
SkipTask:
	Exit Function

errHandler:
	''construct error string to send back to host
	error$ = "SampleFromDewarToGonio !!Error: " + Str$(Err) + " " + ErrMsg$(Err)
	''indicate error occured
	g_foreretval = Err
	''inform client about error
	UpdateClient(EVTNO_FOREGROUND_ERR, error$)
    EResume SkipTask
Fend
''Only for SSRL sample mounting system
Function SampleFromPickerToGonio
	String error$
	''setup error handler to catch errors
	OnErr GoTo errHandler
	SetVeryFastSpeed
	''Collect sample off picker
	FromHomeGetPickerSample()
	''Put sample on gonio, and go home
	SampleFromDewarToGonio()
SkipTask:
	Exit Function

errHandler:
	''construct error string to send back to host
	error$ = "FromPickerToGonio !!Error: " + Str$(Err) + " " + ErrMsg$(Err)
	''indicate error occured
	g_foreretval = Err
	''inform client about error
	UpdateClient(EVTNO_FOREGROUND_ERR, error$)
    EResume SkipTask
Fend
''Only for SSRL sample mounting system
Function GoP1
	String error$
	Integer closestp
	Real diff
	Integer safegohome
	''setup error handler to catch errors
	OnErr GoTo errHandler
	''Backup g_SafeToGoHome status
	safegohome = g_SafeToGoHome
	''Force safe to go home
	g_SafeToGoHome = True
	''Determine closest point to current position
	closestp = GetClosestPoint(ByRef diff)
	''current position is near gonio
    If (closestp = 21 Or closestp = 22 Or closestp = 24) Then
   		GoHomeFromGonio()
   		Jump P1
   	Else
   		If (closestp <> 1 Or (closestp = 1 And diff > 0.001)) Then
   			Jump P1
   		EndIf
	EndIf
	''Restore g_SafeToGoHome status
	g_SafeToGoHome = safegohome
	Open_Gripper
	
SkipTask:
	Exit Function

errHandler:
	''construct error string to send back to host
	error$ = "GoP1 !!Error: " + Str$(Err) + " " + ErrMsg$(Err)
	''indicate error occured
	g_foreretval = Err
	''inform client about error
	UpdateClient(EVTNO_FOREGROUND_ERR, error$)
    EResume SkipTask
Fend
''Only for SSRL sample mounting system
Function GoHome
	String error$
	Integer closestp
	Real diff
	Integer safegohome
	''setup error handler to catch errors
	OnErr GoTo errHandler
	''Backup g_SafeToGoHome status
	safegohome = g_SafeToGoHome
	''Force safe to go home
	g_SafeToGoHome = True
	If Not AtHome Then
		''Determine closest point to current position
	    closestp = GetClosestPoint(ByRef diff)
	    ''current position is near gonio
	    If (closestp = 21 Or closestp = 22 Or closestp = 24) Then
    		GoHomeFromGonio()
    		MoveTongHome()
    	Else
    		MoveTongHome()
		EndIf
	EndIf
	''Restore g_SafeToGoHome status
	g_SafeToGoHome = safegohome
	
SkipTask:
	Exit Function

errHandler:
	''construct error string to send back to host
	error$ = "GoHome !!Error: " + Str$(Err) + " " + ErrMsg$(Err)
	''indicate error occured
	g_foreretval = Err
	''inform client about error
	UpdateClient(EVTNO_FOREGROUND_ERR, error$)
    EResume SkipTask
Fend
