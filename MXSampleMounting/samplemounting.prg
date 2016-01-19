#include "mxrobotdefs.inc"
#include "networkdefs.inc"
#include "genericdefs.inc"
#include "mountingdefs.inc"

Global Preserve Integer g_InterestedCassettePosition
Global Preserve Integer g_InterestedPuckColumnIndex
Global Preserve Integer g_InterestedRowPuckPortIndex
Global Preserve Integer g_InterestedSampleStatus

Function GTGonioReachable() As Boolean
	'' Check if robot can reach goniometer
	GTGonioReachable = True
Fend

Function GTSetGoniometerPoints(dx As Real, dy As Real, dz As Real, du As Real) As Boolean

	'' P21 is the real goniometer point which will be used for robot movement
	P21 = P20 +X(dx) +Y(dy) +Z(dz) +U(du)

	'' P24 is the point	to move to detach goniometer head along gonio orientation
	Real detachDX, detachDY
	detachDX = GONIO_MOUNT_STANDBY_DISTANCE * g_goniometer_cosValue
	detachDY = GONIO_MOUNT_STANDBY_DISTANCE * g_goniometer_sinValue
	P24 = P21 +X(detachDX) +Y(detachDY)

	'' P23 downstream shift from P21. P23 is the dismount standby point
	Real sideStepDX, sideStepDY
	sideStepDX = GONIO_DISMOUNT_SIDEMOVE_DISTANCE * g_goniometer_cosValue
	sideStepDY = GONIO_DISMOUNT_SIDEMOVE_DISTANCE * g_goniometer_sinValue
	P23 = P21 +X(sideStepDX) +Y(sideStepDY)
	
	'' X,Y coordinates of P22 is the corner of the rectangle P24-P21-P23
	'' P22 is the Mount/Dismount point on Gonio
	P23 = P21 +X(detachDX + sideStepDX) +Y(detachDY + sideStepDY) :Z(-1)
	
	If Not GTGonioReachable Then
		String msg$
		msg$ = "GTSetGoniometerPoints: GTGonioReachable returned false!"
		UpdateClient(TASK_MSG, msg$, ERROR_LEVEL)
		GTSetGoniometerPoints = False
		Exit Function
	EndIf
	
	'' Setup P28 and P38 so that we can move smoothly from P18 to P22 using ARC
	'' i.e. ARC P18-P28-P38, then move to P22
	Real ArcToGonioDX, ArcToGonioDY
	ArcToGonioDX = Abs(CX(P22) - CX(P18))
	ArcToGonioDY = Abs(CY(P22) - CY(P18))
	
	'' we will move along axes and will move the shorter distance first
	Real arcMidX, arcMidY, arcMidZ, arcMidU
	Real arcEndX, arcEndY, arcEndZ, arcEndU
	Real sin45
	sin45 = Sin(DegToRad(45))
	
	If (ArcToGonioDX > ArcToGonioDY) Then
		If (CX(P18) > CX(P22)) And (CY(P18) > CY(P22)) Then
			arcMidX = CX(P18) - (1.0 - sin45) * (CY(P18) - CY(P22))
			arcEndX = CX(P18) - (CY(P18) - CY(P22))
		ElseIf (CX(P18) > CX(P22)) And (CY(P18) < CY(P22)) Then
			arcMidX = CX(P18) + (1.0 - sin45) * (CY(P18) - CY(P22))
			arcEndX = CX(P18) + (CY(P18) - CY(P22)) ''check
		ElseIf (CX(P18) < CX(P22)) And (CY(P18) > CY(P22)) Then
			arcMidX = CX(P18) + (1.0 - sin45) * (CY(P18) - CY(P22))
			arcEndX = CX(P18) + (CY(P18) - CY(P22))
		ElseIf (CX(P18) < CX(P22)) And (CY(P18) < CY(P22)) Then
			arcMidX = CX(P18) - (1.0 - sin45) * (CY(P18) - CY(P22))
			arcEndX = CX(P18) - (CY(P18) - CY(P22))
		EndIf

		arcMidY = CY(P18) - sin45 * (CY(P18) - CY(P22))
		arcEndY = CY(P22)
 	Else
		If (CX(P18) > CX(P22)) And (CY(P18) > CY(P22)) Then
			arcMidY = CY(P18) - (1.0 - sin45) * (CX(P18) - CX(P22))
			arcEndY = CY(P18) - (CX(P18) - CX(P22))
		ElseIf (CX(P18) > CX(P22)) And (CY(P18) < CY(P22)) Then
			arcMidY = CY(P18) + (1.0 - sin45) * (CX(P18) - CX(P22))
			arcEndY = CY(P18) + (CX(P18) - CX(P22))
		ElseIf (CX(P18) < CX(P22)) And (CY(P18) > CY(P22)) Then
			arcMidY = CY(P18) + (1.0 - sin45) * (CX(P18) - CX(P22))
			arcEndY = CY(P18) + (CX(P18) - CX(P22))
		ElseIf (CX(P18) < CX(P22)) And (CY(P18) < CY(P22)) Then
			arcMidY = CY(P18) - (1.0 - sin45) * (CX(P18) - CX(P22))
			arcEndY = CY(P18) - (CX(P18) - CX(P22))
		EndIf

		arcMidX = CX(P18) - sin45 * (CX(P18) - CX(P22))
		arcEndX = CX(P22)
	EndIf
	
	arcMidZ = CZ(P18)
	arcMidU = (CU(P18) + CU(P22)) / 2.0
	arcEndZ = CZ(P18)
	arcEndU = CU(P22)

	'' Assign the values to P28 and P38
	P28 = XY(arcMidX, arcMidY, arcMidZ, arcMidU)
	P38 = XY(arcEndX, arcEndY, arcEndZ, arcEndU)

	GTSetGoniometerPoints = True
Fend

Function GTsetInterestPoint(cassette_position As Integer, puckColumnIndex As Integer, rowPuckPortIndex As Integer) As Boolean
	'' This function returns false if the port supplied is Invalid or if there is no sample in that port
	GTsetInterestPoint = False
	
	g_InterestedCassettePosition = cassette_position
	g_InterestedPuckColumnIndex = puckColumnIndex
	g_InterestedRowPuckPortIndex = rowPuckPortIndex
	g_InterestedSampleStatus = SAMPLE_STATUS_UNKNOWN
	
	If (g_CassetteType(cassette_position) = NORMAL_CASSETTE) Or (g_CassetteType(cassette_position) = CALIBRATION_CASSETTE) Then
		If g_CAS_PortStatus(cassette_position, rowPuckPortIndex, puckColumnIndex) = PORT_OCCUPIED Then
			g_InterestedSampleStatus = SAMPLE_IN_CASSETTE
			GTsetInterestPoint = True
		EndIf
	ElseIf g_CassetteType(cassette_position) = SUPERPUCK_CASSETTE Then
		If g_SP_PortStatus(cassette_position, puckColumnIndex, rowPuckPortIndex) = PORT_OCCUPIED Then
			g_InterestedSampleStatus = SAMPLE_IN_CASSETTE
			GTsetInterestPoint = True
		EndIf
	EndIf
	
	String msg$
	msg$ = "{'set':'sample_state', 'position':'" + GTCassettePosition$(g_InterestedCassettePosition) + "', 'start':" + Str$(GTgetPortIndexFromCassetteVars(g_InterestedCassettePosition, g_InterestedPuckColumnIndex, g_InterestedRowPuckPortIndex)) + ", 'value':" + Str$(g_InterestedSampleStatus) + "}"
	UpdateClient(CLIENT_UPDATE, msg$, INFO_LEVEL)
Fend

Function GTMoveToInterestPortStandbyPoint
	'' GTMoveTo<___>MountPortStandbyPoint sets the standby points and intermediate points
	If (g_CassetteType(g_InterestedCassettePosition) = NORMAL_CASSETTE) Or (g_CassetteType(g_InterestedCassettePosition) = CALIBRATION_CASSETTE) Then
		GTMoveToCASMountPortStandbyPoint(g_InterestedCassettePosition, g_InterestedRowPuckPortIndex, g_InterestedPuckColumnIndex)
	ElseIf g_CassetteType(g_InterestedCassettePosition) = SUPERPUCK_CASSETTE Then
		GTMoveToSPMountPortStandbyPoint(g_InterestedCassettePosition, g_InterestedPuckColumnIndex, g_InterestedRowPuckPortIndex)
	EndIf
Fend

Function GetSampleFromInterestPort As Boolean
	Integer portStandbyPoint
	Integer portStatusBeforePickerCheck
	
	portStandbyPoint = 52

	If (g_CassetteType(g_InterestedCassettePosition) = NORMAL_CASSETTE) Or (g_CassetteType(g_InterestedCassettePosition) = CALIBRATION_CASSETTE) Then
		GTPickerCheckCASPortStatus(g_InterestedCassettePosition, g_InterestedRowPuckPortIndex, g_InterestedPuckColumnIndex, portStandbyPoint, ByRef portStatusBeforePickerCheck)
	ElseIf g_CassetteType(g_InterestedCassettePosition) = SUPERPUCK_CASSETTE Then
		GTPickerCheckSPPortStatus(g_InterestedCassettePosition, g_InterestedPuckColumnIndex, g_InterestedRowPuckPortIndex, portStandbyPoint, ByRef portStatusBeforePickerCheck)
	EndIf

	GetSampleFromInterestPort = False
	If portStatusBeforePickerCheck = PORT_OCCUPIED Then
		g_InterestedSampleStatus = SAMPLE_IN_PICKER
		GetSampleFromInterestPort = True
	ElseIf portStatusBeforePickerCheck = PORT_VACANT Then
		g_InterestedSampleStatus = SAMPLE_STATUS_UNKNOWN
	Else
		''If portStatusBeforePickerCheck = PORT_ERROR Then
		g_InterestedSampleStatus = SAMPLE_STATUS_UNKNOWN
	EndIf
	
	String msg$
	msg$ = "{'set':'sample_state', 'position':'" + GTCassettePosition$(g_InterestedCassettePosition) + "', 'start':" + Str$(GTgetPortIndexFromCassetteVars(g_InterestedCassettePosition, g_InterestedPuckColumnIndex, g_InterestedRowPuckPortIndex)) + ", 'value':" + Str$(g_InterestedSampleStatus) + "}"
	UpdateClient(CLIENT_UPDATE, msg$, INFO_LEVEL)
Fend

Function GTMoveBackToCassetteStandbyPoint
	'' GTMoveTo<___>MountPortStandbyPoint sets the standby points and intermediate points
	If (g_CassetteType(g_InterestedCassettePosition) = NORMAL_CASSETTE) Or (g_CassetteType(g_InterestedCassettePosition) = CALIBRATION_CASSETTE) Then
		GTMoveBackToCASStandbyPoint
	ElseIf g_CassetteType(g_InterestedCassettePosition) = SUPERPUCK_CASSETTE Then
		GTMoveBackToSPStandbyPoint
	EndIf
Fend

Function GTMoveCassetteStandbyToCradle
	Tool 0
	GTsetRobotSpeedMode(INSIDE_LN2_SPEED)
	
	Real desiredX, desiredY, desiredZ
	desiredX = (CX(P4) + CX(RealPos)) / 2.0
	desiredY = (CY(P4) + CY(RealPos)) / 2.0
	
	'' desiredZ = maximum of CZ(P4) and CZ(RealPos)
	If CZ(P4) > CZ(RealPos) Then
		desiredZ = CZ(P4)
	Else
		desiredZ = CZ(RealPos)
	EndIf
	
	LimZ desiredZ + 5.0
	
	P49 = XY(desiredX, desiredY, desiredZ, CU(RealPos)) /R
	
	Move P49
	Jump P4
	
	LimZ g_Jump_LimZ_LN2
Fend

Function GTCheckSampleInCradle As Boolean
	'' Starts from P3
	
	GTCheckSampleInCradle = False
	String msg$
	If g_InterestedSampleStatus = SAMPLE_IN_CRADLE Then
	
		'' use cavity to side touch the dumbbell to determine whether sample is on the dumbbell
		
		If Not Close_Gripper Then
			UpdateClient(TASK_MSG, "GTCheckSampleInCradle:Close_Gripper failed", INFO_LEVEL)
			Exit Function
		EndIf
	
		Move P93 +U(90)
		Go P93
		
		Real maxDistanceToScan
		maxDistanceToScan = Dist(P93, P5)
		
		If ForceTouch(DIRECTION_MAGNET_TO_CAVITY, maxDistanceToScan, False) Then
			Real distanceP93toHere
			distanceP93toHere = Dist(P93, RealPos)
			
			'' Distance error from perfect sample position
			Real distErrorFromP5
			distErrorFromP5 = maxDistanceToScan - distanceP93toHere ''maxDistanceToScan = Dist(P93, P5)
			
			If distErrorFromP5 < TOLERANCE_FOR_SAMPLE_IN_PICKER Then
				''This condition means ForceTouch could not find sample in dumbbell
				'' Whether the picker got the sample from cassette port or not is unknown
				g_InterestedSampleStatus = SAMPLE_STATUS_UNKNOWN
				msg$ = "GTCheckSampleInCradle: ForceTouch on sample in cradle moved " + Str$(distErrorFromP5) + "mm beyond expected sample surface."
				UpdateClient(TASK_MSG, msg$, WARNING_LEVEL)
			Else
				'' Sample still on picker (on cradle)
				g_InterestedSampleStatus = SAMPLE_IN_CRADLE
				msg$ = "GTCheckSampleInCradle: ForceTouch detected sample in cradle with distance error =" + Str$(distErrorFromP5) + "."
				UpdateClient(TASK_MSG, msg$, INFO_LEVEL)
				GTCheckSampleInCradle = True
			EndIf
		Else
			''There is no sample (or ForceTouch failure)
			g_InterestedSampleStatus = SAMPLE_STATUS_UNKNOWN
			msg$ = "GTCheckSampleInCradle: ForceTouch failed to detect sample in cradle even after travelling maximum scan distance!"
			UpdateClient(TASK_MSG, msg$, INFO_LEVEL)
		EndIf
		
		Move P93
	Else
		msg$ = "GTCheckSampleInCradle: g_InterestedSampleStatus is not SAMPLE_IN_CRADLE! This function is called before sample is brought to cradle."
		UpdateClient(TASK_MSG, msg$, INFO_LEVEL)
	EndIf
Fend

Function GTCavityGripSampleFromPicker As Boolean
	''GripSample in Cavity From Picker of dumbbell in cradle
	''Starts from P3

	GTCavityGripSampleFromPicker = False
	
	''GTCheckSampleInCradle closes gripper before checking
	If GTCheckSampleInCradle Then
		If Not Open_Gripper Then
			UpdateClient(TASK_MSG, "GTCavityGripSampleFromPicker:Open_Gripper failed", ERROR_LEVEL)
			Exit Function
		EndIf
		
		Arc P15, P16

		If Not Close_Gripper Then
			UpdateClient(TASK_MSG, "GTCavityGripSampleFromPicker:Close_Gripper failed", ERROR_LEVEL)
			Exit Function
		EndIf
		
		GTTwistOffMagnet
		
		g_InterestedSampleStatus = SAMPLE_IN_CAVITY
		String msg$
		msg$ = "{'set':'sample_state', 'position':'" + GTCassettePosition$(g_InterestedCassettePosition) + "', 'start':" + Str$(GTgetPortIndexFromCassetteVars(g_InterestedCassettePosition, g_InterestedPuckColumnIndex, g_InterestedRowPuckPortIndex)) + ", 'value':" + Str$(g_InterestedSampleStatus) + "}"
		UpdateClient(CLIENT_UPDATE, msg$, INFO_LEVEL)
		GTCavityGripSampleFromPicker = True
	EndIf
Fend

Function GTMoveToGoniometer As Boolean

	If Not Close_Gripper Then
		UpdateClient(TASK_MSG, "GTMoveToGoniometer:Close_Gripper failed", ERROR_LEVEL)
		GTMoveToGoniometer = False
		Exit Function
	EndIf
	
	GTsetRobotSpeedMode(OUTSIDE_LN2_SPEED)
	Move P2 CP
	Move P18 CP
	Arc P28, P38 CP
	Move P22

	GTMoveToGoniometer = True
Fend

Function GTReleaseSampleToGonio As Boolean
	''Releases sample from cavity to Goniometer
	''starts from P22
	GTReleaseSampleToGonio = False

	Move P24
	Move P21
	
	If Not Open_Gripper Then
		UpdateClient(TASK_MSG, "GTReleaseSampleToGonio:Open_Gripper failed", ERROR_LEVEL)
		Exit Function
	EndIf
		
	g_InterestedSampleStatus = SAMPLE_IN_GONIO
	String msg$
	msg$ = "{'set':'sample_state', 'position':'" + GTCassettePosition$(g_InterestedCassettePosition) + "', 'start':" + Str$(GTgetPortIndexFromCassetteVars(g_InterestedCassettePosition, g_InterestedPuckColumnIndex, g_InterestedRowPuckPortIndex)) + ", 'value':" + Str$(g_InterestedSampleStatus) + "}"
	UpdateClient(CLIENT_UPDATE, msg$, INFO_LEVEL)
	'' if tongConflict code not included here
	
	Move P23

	'' move closer to robot to avoid directly above sample and disturbing the air
	'' move away from goniometer by 40mm while raising to P22
	Move P22 +X(40.0 * g_goniometer_cosValue) +Y(40.0 * g_goniometer_sinValue)
	
	'' Close_Gripper check is not required because it is moving to heater after this step anyway
	Close_Gripper
	
	GTReleaseSampleToGonio = True
Fend

Function GTMoveGoniometerToDewarSide As Boolean

	If Not Close_Gripper Then
		UpdateClient(TASK_MSG, "GTMoveGoniometerToDewarSide:Close_Gripper failed", ERROR_LEVEL)
		GTMoveGoniometerToDewarSide = False
		Exit Function
	EndIf
	
	GTsetRobotSpeedMode(OUTSIDE_LN2_SPEED)
	Move P38 CP
	Arc P28, P18

	GTMoveGoniometerToDewarSide = True
Fend


Function GTMountInterestedPort As Boolean
	'' GTMountInterestedPort should start with dumbbell in gripper usually from P4
	
	GTMountInterestedPort = False

	'' GTMoveToInterestPortStandbyPoint sets the standby points and intermediate points
	GTMoveToInterestPortStandbyPoint
	
	If Not GetSampleFromInterestPort Then
		g_RunResult$ = "GetSampleFromInterestPort failed"
		UpdateClient(TASK_MSG, g_RunResult$, ERROR_LEVEL)
		Exit Function
	EndIf
		
	GTMoveBackToCassetteStandbyPoint
	GTMoveCassetteStandbyToCradle
	
	String msg$

	'' Put dumbbell in Cradle
	If GTReturnMagnet Then
		g_InterestedSampleStatus = SAMPLE_IN_CRADLE
		msg$ = "{'set':'sample_state', 'position':'" + GTCassettePosition$(g_InterestedCassettePosition) + "', 'start':" + Str$(GTgetPortIndexFromCassetteVars(g_InterestedCassettePosition, g_InterestedPuckColumnIndex, g_InterestedRowPuckPortIndex)) + ", 'value':" + Str$(g_InterestedSampleStatus) + "}"
		UpdateClient(CLIENT_UPDATE, msg$, INFO_LEVEL)
	Else
		g_RunResult$ = "GTReturnMagnet failed"
		UpdateClient(TASK_MSG, g_RunResult$, ERROR_LEVEL)
		Exit Function
	EndIf
	
	''GripSample in Cavity From Picker of dumbbell in cradle
	If Not GTCavityGripSampleFromPicker Then
		g_RunResult$ = "GTCavityGripSampleFromPicker failed"
		UpdateClient(TASK_MSG, g_RunResult$, ERROR_LEVEL)
		Exit Function
	EndIf
	
	If Not GTMoveToGoniometer Then
		g_RunResult$ = "GTMoveToGoniometer failed"
		UpdateClient(TASK_MSG, g_RunResult$, ERROR_LEVEL)
		Exit Function
	EndIf
	
	If Not GTReleaseSampleToGonio Then
		g_RunResult$ = "GTReleaseSampleToGonio failed"
		UpdateClient(TASK_MSG, g_RunResult$, ERROR_LEVEL)
		Exit Function
	EndIf
	
	If Not GTMoveGoniometerToDewarSide Then
		g_RunResult$ = "GTMoveGoniometerToDewarSide failed"
		UpdateClient(TASK_MSG, g_RunResult$, ERROR_LEVEL)
		Exit Function
	EndIf
	
	GTMountInterestedPort = True
Fend

