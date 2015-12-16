#include "networkdefs.inc"
#include "forcedefs.inc"
#include "mxrobotdefs.inc"
#include "genericdefs.inc"
#include "superpuckdefs.inc"

Real m_SP_Alpha(NUM_PUCKS)
Real m_SP_Puck_Radius(NUM_PUCKS)
Real m_SP_Puck_Thickness(NUM_PUCKS)
Real m_SP_PuckCenter_Height(NUM_PUCKS)
Real m_SP_Puck_RotationAngle(NUM_PUCKS)
Real m_SP_Ports_1_5_Circle_Radius
Real m_SP_Ports_6_16_Circle_Radius

'' m_adaptorAngleError is only used in this module, so it doesn't need to be a global variable!
'' it is declared as a global variable for debugging purposes only
'' adaptor angle error is with respect to PUCK_A
Global Real m_adaptorAngleError(NUM_CASSETTES, NUM_PUCKS)

Global Integer g_PuckStatus(NUM_CASSETTES, NUM_PUCKS)
Global Real g_SampleDistancefromPuckSurface(NUM_CASSETTES, NUM_PUCKS, NUM_PUCK_PORTS)
Global Integer g_SP_PortStatus(NUM_CASSETTES, NUM_PUCKS, NUM_PUCK_PORTS)

Function initSuperPuckConstants()
	m_SP_Alpha(PUCK_A) = 45.0
	m_SP_Alpha(PUCK_B) = 45.0
	m_SP_Alpha(PUCK_C) = -45.0
	m_SP_Alpha(PUCK_D) = -45.0

	m_SP_Puck_Radius(PUCK_A) = 32.5
	m_SP_Puck_Radius(PUCK_B) = 32.5
	m_SP_Puck_Radius(PUCK_C) = 32.5
	m_SP_Puck_Radius(PUCK_D) = 32.5
	
	m_SP_Puck_Thickness(PUCK_A) = 29.0
	m_SP_Puck_Thickness(PUCK_B) = 29.0
	m_SP_Puck_Thickness(PUCK_C) = -29.0
	m_SP_Puck_Thickness(PUCK_D) = -29.0
	
	m_SP_PuckCenter_Height(PUCK_A) = 102.5
	m_SP_PuckCenter_Height(PUCK_B) = 34.5
	m_SP_PuckCenter_Height(PUCK_C) = 102.5
	m_SP_PuckCenter_Height(PUCK_D) = 34.5
	
	m_SP_Puck_RotationAngle(PUCK_A) = 0.0
	m_SP_Puck_RotationAngle(PUCK_B) = 0.0
	m_SP_Puck_RotationAngle(PUCK_C) = 180.0
	m_SP_Puck_RotationAngle(PUCK_D) = 180.0
	
	m_SP_Ports_1_5_Circle_Radius = 12.12
	m_SP_Ports_6_16_Circle_Radius = 26.31
Fend

Function GTpuckName$(puckIndex As Integer)
	If puckIndex = PUCK_A Then
		GTpuckName$ = "PUCK_A"
	ElseIf puckIndex = PUCK_B Then
		GTpuckName$ = "PUCK_B"
	ElseIf puckIndex = PUCK_C Then
		GTpuckName$ = "PUCK_C"
	ElseIf puckIndex = PUCK_D Then
		GTpuckName$ = "PUCK_D"
	Else
		GTpuckName$ = "PUCK_NOT_DEFINED"
	EndIf
Fend

Function GTgetPuckIndex(puckChar$ As String, ByRef puckIndex As Integer) As Boolean
	puckChar$ = UCase$(puckChar$)
	Select puckChar$
		Case "A"
			puckIndex = PUCK_A
		Case "B"
			puckIndex = PUCK_B
		Case "C"
			puckIndex = PUCK_C
		Case "D"
			puckIndex = PUCK_D
		Default
			puckIndex = UNKNOWN_POSITION
			GTgetPuckIndex = False
			Exit Function
	Send
	GTgetPuckIndex = True
Fend

Function GTSPpositioningMove(cassette_position As Integer, puckIndex As Integer, jumpToStandbyPoint As Boolean) As Boolean
	Real angle_to_puck_center
	angle_to_puck_center = g_AngleOffset(cassette_position) + g_AngleOfFirstColumn(cassette_position) + m_SP_Alpha(puckIndex)
	
	Real perfectU
	If (puckIndex = PUCK_A Or puckIndex = PUCK_B) Then
		perfectU = g_UForNormalStandby(cassette_position) + GTBoundAngle(-180, 180, ((angle_to_puck_center - 90) - g_UForNormalStandby(cassette_position)))
	Else	''(puckIndex = PUCK_C Or puckIndex = PUCK_D) Then
		perfectU = g_UForNormalStandby(cassette_position) + GTBoundAngle(-180, 180, ((angle_to_puck_center + 90) - g_UForNormalStandby(cassette_position)))
	EndIf
	
	Real puck_edge_x, puck_edge_y, puck_edge_z
	Real positioningPoint_from_SPCenter
	positioningPoint_from_SPCenter = SUPERPUCK_WIDTH - 10
	puck_edge_x = positioningPoint_from_SPCenter * Cos(DegToRad(angle_to_puck_center))
	puck_edge_y = positioningPoint_from_SPCenter * Sin(DegToRad(angle_to_puck_center))
	puck_edge_z = SUPERPUCK_HEIGHT /2
	
	
	Real offsetFromPortDeepEnd, offsetXfromPortDeepEnd, offsetYfromPortDeepEnd
	offsetFromPortDeepEnd = m_SP_Puck_Thickness(puckIndex)
	offsetXfromPortDeepEnd = offsetFromPortDeepEnd * Cos(DegToRad(angle_to_puck_center + 90))
	offsetYfromPortDeepEnd = offsetFromPortDeepEnd * Sin(DegToRad(angle_to_puck_center + 90))
	
	Real dx, dy, dz
	dx = (puck_edge_x + offsetXfromPortDeepEnd) * CASSETTE_SHRINK_FACTOR
	dy = (puck_edge_y + offsetYfromPortDeepEnd) * CASSETTE_SHRINK_FACTOR
	dz = puck_edge_z * CASSETTE_SHRINK_FACTOR
	
	
	Integer standbyPoint, perfectPoint
	perfectPoint = 102
	standbyPoint = 52
	
	'' Set perfect point	
	Real ActualOffsets(3)
	Real perfectX, perfectY, perfectZ
	GTapplyTiltToOffsets(cassette_position, dx, dy, dz, ByRef ActualOffsets())
	perfectX = g_CenterX(cassette_position) + ActualOffsets(0)
	perfectY = g_CenterY(cassette_position) + ActualOffsets(1)
	perfectZ = g_BottomZ(cassette_position) + ActualOffsets(2)
	P(perfectPoint) = XY(perfectX, perfectY, perfectZ, perfectU) /R


	Real sinU, cosU
	sinU = Sin(DegToRad(perfectU)); cosU = Cos(DegToRad(perfectU))
	'' Set standby point
	Real standbyXoffset, standbyYoffset
	standbyXoffset = PROBE_STANDBY_DISTANCE * cosU
	standbyYoffset = PROBE_STANDBY_DISTANCE * sinU
	P(standbyPoint) = XY(perfectX - standbyXoffset, perfectY - standbyYoffset, perfectZ, perfectU) /R
	
	
	Tool PLACER_TOOL
	LimZ g_Jump_LimZ_LN2

	If jumpToStandbyPoint Then
		Jump P(standbyPoint)
	Else
		Move P(standbyPoint)
	EndIf
	
	Real scanDistance
	scanDistance = PROBE_STANDBY_DISTANCE + PROBE_ADAPTOR_DISTANCE
	
	GTsetRobotSpeedMode(PROBE_SPEED)
		
	ForceCalibrateAndCheck(LOW_SENSITIVITY, LOW_SENSITIVITY)
	If Not ForceTouch(DIRECTION_CAVITY_TAIL, scanDistance, True) Then
		UpdateClient(TASK_MSG, "GTSPpositioningMove failed: error in ForceTouch!", ERROR_LEVEL)
		GTSPpositioningMove = False
		Exit Function
	EndIf
	
	GTLoadPreviousRobotSpeedMode
	Move P(standbyPoint)
	GTSPpositioningMove = True
Fend




Real m_HorzDistancePuckCenterToSPEdge(NUM_PUCKS)
Function GTgetAdaptorAngleErrorProbePoint(cassette_position As Integer, puckIndex As Integer, perfectPointNum As Integer, standbyPointNum As Integer, destinationPointNum As Integer)
	Real angle_to_puck_center
	angle_to_puck_center = g_AngleOffset(cassette_position) + g_AngleOfFirstColumn(cassette_position) + m_SP_Alpha(puckIndex)
	
	Real perfectU
	If (puckIndex = PUCK_A Or puckIndex = PUCK_B) Then
		perfectU = g_UForNormalStandby(cassette_position) + GTBoundAngle(-180, 180, ((angle_to_puck_center - 90) - g_UForNormalStandby(cassette_position)))
	Else	''(puckIndex = PUCK_C Or puckIndex = PUCK_D) Then
		perfectU = g_UForNormalStandby(cassette_position) + GTBoundAngle(-180, 180, ((angle_to_puck_center + 90) - g_UForNormalStandby(cassette_position)))
	EndIf
	
	Real puck_center_x, puck_center_y, puck_center_z
	puck_center_x = m_SP_Puck_Radius(puckIndex) * Cos(DegToRad(angle_to_puck_center))
	puck_center_y = m_SP_Puck_Radius(puckIndex) * Sin(DegToRad(angle_to_puck_center))
	puck_center_z = m_SP_PuckCenter_Height(puckIndex)
	
	Real angleBetweenConsecutivePorts
	Real portIndex, portIndexInCircle
	If puckIndex = PUCK_A Or puckIndex = PUCK_D Then
		'' probe for adaptor angle correction inline with the line joining puck center to center of port12
		portIndex = 11
	Else ''If puckIndex = PUCK_B Or puckIndex = PUCK_C Then
		'' probe for adaptor angle correction inline with the line joining puck center to center of port11
		portIndex = 10
	EndIf
	
	If portIndex < 5 Then
		angleBetweenConsecutivePorts = 360.0 / 5
		portIndexInCircle = portIndex
	Else
		angleBetweenConsecutivePorts = 360.0 / 11
		portIndexInCircle = portIndex - 5
	EndIf
	'' Vertical angle of line joining Puck Center and Sample Port Center
	Real portAnglefromPuckCenter
	Real spEdgeRadius
	Real HorzDistancePuckCenterToSPEdge, VertDistancePuckCenterToSPEdge
	spEdgeRadius = m_SP_Puck_Radius(puckIndex) + SP_EDGE_THICKNESS
	portAnglefromPuckCenter = angleBetweenConsecutivePorts * portIndexInCircle + m_SP_Puck_RotationAngle(puckIndex)
	''If probe should be on the edge inline with dial set HorzDistancePuckCenterToSPEdge = spEdgeRadius
	HorzDistancePuckCenterToSPEdge = spEdgeRadius * Cos(DegToRad(portAnglefromPuckCenter))
	VertDistancePuckCenterToSPEdge = spEdgeRadius * Sin(DegToRad(portAnglefromPuckCenter))

	'' used in GTsetupAdaptorAngleCorrection
	m_HorzDistancePuckCenterToSPEdge(puckIndex) = HorzDistancePuckCenterToSPEdge

	'' Project to World Coordinates
	Real puckCenterToEdge_X, puckCenterToEdge_Y, puckCenterToEdge_Z
	If (puckIndex = PUCK_A Or puckIndex = PUCK_B) Then
		puckCenterToEdge_X = HorzDistancePuckCenterToSPEdge * Cos(DegToRad(angle_to_puck_center + 180))
		puckCenterToEdge_Y = HorzDistancePuckCenterToSPEdge * Sin(DegToRad(angle_to_puck_center + 180))
	Else	''(puckIndex = PUCK_C Or puckIndex = PUCK_D) Then
		puckCenterToEdge_X = HorzDistancePuckCenterToSPEdge * Cos(DegToRad(angle_to_puck_center))
		puckCenterToEdge_Y = HorzDistancePuckCenterToSPEdge * Sin(DegToRad(angle_to_puck_center))
	EndIf
	puckCenterToEdge_Z = VertDistancePuckCenterToSPEdge
	
	Real offsetFromPortDeepEnd, offsetXfromPortDeepEnd, offsetYfromPortDeepEnd
	offsetFromPortDeepEnd = m_SP_Puck_Thickness(puckIndex)
	offsetXfromPortDeepEnd = offsetFromPortDeepEnd * Cos(DegToRad(angle_to_puck_center + 90))
	offsetYfromPortDeepEnd = offsetFromPortDeepEnd * Sin(DegToRad(angle_to_puck_center + 90))
	
	Real dx, dy, dz
	dx = (puck_center_x + puckCenterToEdge_X + offsetXfromPortDeepEnd) * CASSETTE_SHRINK_FACTOR
	dy = (puck_center_y + puckCenterToEdge_Y + offsetYfromPortDeepEnd) * CASSETTE_SHRINK_FACTOR
	dz = (puck_center_z + puckCenterToEdge_Z) * CASSETTE_SHRINK_FACTOR
	
	'' Set perfect point	
	Real ActualOffsets(3)
	Real perfectX, perfectY, perfectZ
	GTapplyTiltToOffsets(cassette_position, dx, dy, dz, ByRef ActualOffsets())
	perfectX = g_CenterX(cassette_position) + ActualOffsets(0)
	perfectY = g_CenterY(cassette_position) + ActualOffsets(1)
	perfectZ = g_BottomZ(cassette_position) + ActualOffsets(2)
	P(perfectPointNum) = XY(perfectX, perfectY, perfectZ, perfectU) /R


	Real sinU, cosU
	sinU = Sin(DegToRad(perfectU)); cosU = Cos(DegToRad(perfectU))
	'' Set standby point
	Real standbyXoffset, standbyYoffset
	standbyXoffset = PROBE_STANDBY_DISTANCE * cosU
	standbyYoffset = PROBE_STANDBY_DISTANCE * sinU
	P(standbyPointNum) = XY(perfectX - standbyXoffset, perfectY - standbyYoffset, perfectZ, perfectU) /R
	
	'' Set destination point
	Real destinationXoffset, destinationYoffset
	destinationXoffset = PROBE_ADAPTOR_DISTANCE * cosU
	destinationYoffset = PROBE_ADAPTOR_DISTANCE * sinU
	P(destinationPointNum) = XY(perfectX + destinationXoffset, perfectY + destinationYoffset, perfectZ, perfectU) /R
Fend

Function GTprobeAdaptorAngleCorrection(cassette_position As Integer, puckIndex As Integer, jumpToStandbyPoint As Boolean) As Boolean
	String msg$
	
	msg$ = "GTprobeAdaptorAngleCorrection(" + GTCassetteName$(cassette_position) + ":" + GTpuckName$(puckIndex) + ")"
	UpdateClient(TASK_MSG, msg$, INFO_LEVEL)

	Tool PLACER_TOOL
	LimZ g_Jump_LimZ_LN2

	'' Initial Positioning move before every puck adaptor correction probe
	GTSPpositioningMove(cassette_position, puckIndex, jumpToStandbyPoint)

	Integer standbyPoint, perfectPoint, destinationPoint
	perfectPoint = 102
	standbyPoint = 52
	destinationPoint = 53
	
	GTgetAdaptorAngleErrorProbePoint(cassette_position, puckIndex, perfectPoint, standbyPoint, destinationPoint)
	
	'' Set to Jump, if GTSPpositioningMove is not used
	Move P(standbyPoint)
	
	Real scanDistance
	scanDistance = PROBE_STANDBY_DISTANCE + PROBE_ADAPTOR_DISTANCE
	
	GTsetRobotSpeedMode(PROBE_SPEED)

	ForceCalibrateAndCheck(LOW_SENSITIVITY, LOW_SENSITIVITY)
	If Not ForceTouch(DIRECTION_CAVITY_TAIL, scanDistance, True) Then
		UpdateClient(TASK_MSG, "GTprobeAdaptorAngleCorrection failed: error in ForceTouch!", ERROR_LEVEL)
		GTprobeAdaptorAngleCorrection = False
		Exit Function
	EndIf
		
	GTLoadPreviousRobotSpeedMode
	
	Real error_from_perfectPoint_in_mm
	error_from_perfectPoint_in_mm = Dist(RealPos, P(perfectPoint))
	
	'' Determine sign of error_from_perfectPoint_in_mm
	'' If cassette is touched before reaching perfectPoint, then -(minus) sign
	'' ElseIf cassette is touched only going further after perfectPoint, then +(plus) sign
	Real distance_here_to_destination, distance_perfect_to_destination
	distance_here_to_destination = Dist(RealPos, P(destinationPoint))
	distance_perfect_to_destination = Dist(P(perfectPoint), P(destinationPoint))
	If (distance_here_to_destination > distance_perfect_to_destination) Then
		error_from_perfectPoint_in_mm = -error_from_perfectPoint_in_mm
	EndIf
	
	msg$ = "GTprobeAdaptorAngleCorrection: " + GTpuckName$(puckIndex) + " error_from_perfectPoint_in_mm=" + Str$(error_from_perfectPoint_in_mm)
	UpdateClient(TASK_MSG, msg$, ERROR_LEVEL)

	Move P(standbyPoint)

	If Not GTsetupAdaptorAngleCorrection(cassette_position, puckIndex, error_from_perfectPoint_in_mm) Then
		UpdateClient(TASK_MSG, "GTprobeAdaptorAngleCorrection failed: error in GTsetupPuckAngleCorrection!", ERROR_LEVEL)
		GTprobeAdaptorAngleCorrection = False
		Exit Function
	EndIf
	
	msg$ = "GTprobeAdaptorAngleCorrection:(" + GTCassetteName$(cassette_position) + ":" + GTpuckName$(puckIndex) + ") completed."
	UpdateClient(TASK_MSG, msg$, INFO_LEVEL)
	GTprobeAdaptorAngleCorrection = True
Fend

Function GTsetupAdaptorAngleCorrection(cassette_position As Integer, puckIndex As Integer, error_from_perfectPoint_in_mm As Real) As Boolean
	String msg$
	''because error is very small, for error_from_perfectPoint_in_mm < 0.8mm
	''the error between accurate calculation and estimation is about 0.4%
	''so we will go with estimation
	''the accurate formula is in the document adaptor_error.xls

	m_adaptorAngleError(cassette_position, puckIndex) = 0

	Real adaptorAngleError
	'' Horizontal distance between Probe point and the vertical line through SuperPuck Center 
	Real HorzDistSPCenterToProbePoint
	HorzDistSPCenterToProbePoint = SP_CENTER_TO_PUCK_CENTER_LENGTH + Abs(m_HorzDistancePuckCenterToSPEdge(puckIndex))
	If (error_from_perfectPoint_in_mm >= 0) Then
		'' magnet edge is pushing adaptor edge, (-) minus sign is to project the angle in global coordinates
		adaptorAngleError = RadToDeg(-error_from_perfectPoint_in_mm / (HorzDistSPCenterToProbePoint - MAGNET_HEAD_RADIUS))
	Else
		'' magnet center is pushing adaptor edge, (-) minus sign is to project the angle in global coordinates
		adaptorAngleError = RadToDeg(-error_from_perfectPoint_in_mm / HorzDistSPCenterToProbePoint)
	EndIf
		
	'' Because PUCK_C and PUCK_D are probed from the opposite direction, the angle error is in the opposite direction
	If (puckIndex = PUCK_C) Or (puckIndex = PUCK_D) Then
		adaptorAngleError = -adaptorAngleError
	EndIf
	
    msg$ = "GTsetupAdaptorAngleCorrection: For Superpuck " + GTCassetteName$(cassette_position) + ":" + GTpuckName$(puckIndex) + " adaptorAngleError=" + Str$(adaptorAngleError)
	UpdateClient(TASK_MSG, msg$, INFO_LEVEL)
	'' adaptor Angle Error should be less than 1.02 degrees
	If Abs(adaptorAngleError) > 1.02 Then
	    msg$ = "GTsetupAdaptorAngleCorrection: For Superpuck " + GTCassetteName$(cassette_position) + ":" + GTpuckName$(puckIndex) + " puckAngleError=" + Str$(adaptorAngleError) + "> 1.02 degrees"
		UpdateClient(TASK_MSG, msg$, ERROR_LEVEL)
		GTsetupAdaptorAngleCorrection = False
		Exit Function
	EndIf
	
	m_adaptorAngleError(cassette_position, puckIndex) = adaptorAngleError
	msg$ = "GTsetupAdaptorAngleCorrection: For Superpuck " + GTCassetteName$(cassette_position) + ":" + GTpuckName$(puckIndex)
	UpdateClient(TASK_MSG, msg$, INFO_LEVEL)
	GTsetupAdaptorAngleCorrection = True
Fend


'' distanceFromPuckSurface > 0 is the offset away from the puck
'' distanceFromPuckSurface < 0 is the offset into the puck (port)
Function GTperfectSPPortOffset(cassette_position As Integer, portIndex As Integer, puckIndex As Integer, distanceFromPuckSurface As Real, ByRef dx As Real, ByRef dy As Real, ByRef dz As Real, ByRef u As Real)
	'' Horizontal angle from Cassette Center to Puck Center
	Real angle_to_puck_center
	angle_to_puck_center = g_AngleOffset(cassette_position) + g_AngleOfFirstColumn(cassette_position) + m_SP_Alpha(puckIndex) + m_adaptorAngleError(cassette_position, puckIndex)
	
	If (puckIndex = PUCK_A Or puckIndex = PUCK_B) Then
		u = g_UForNormalStandby(cassette_position) + GTBoundAngle(-180, 180, ((angle_to_puck_center - 90) - g_UForNormalStandby(cassette_position)))
	Else	''(puckIndex = PUCK_C Or puckIndex = PUCK_D) Then
		u = g_UForNormalStandby(cassette_position) + GTBoundAngle(-180, 180, ((angle_to_puck_center + 90) - g_UForNormalStandby(cassette_position)))
	EndIf
	
	Real puck_center_x, puck_center_y, puck_center_z
	puck_center_x = m_SP_Puck_Radius(puckIndex) * Cos(DegToRad(angle_to_puck_center))
	puck_center_y = m_SP_Puck_Radius(puckIndex) * Sin(DegToRad(angle_to_puck_center))
	puck_center_z = m_SP_PuckCenter_Height(puckIndex)
	
	Real portCircleRadius, angleBetweenConsecutivePorts
	Real portIndexInCircle
	If portIndex < 5 Then
		portCircleRadius = m_SP_Ports_1_5_Circle_Radius
		angleBetweenConsecutivePorts = 360.0 / 5
		portIndexInCircle = portIndex
	Else
		portCircleRadius = m_SP_Ports_6_16_Circle_Radius
		angleBetweenConsecutivePorts = 360.0 / 11
		portIndexInCircle = portIndex - 5
	EndIf

	'' Vertical angle from Puck Center to Sample Port Center
	Real portAnglefromPuckCenter
	Real HorzDistancePuckCenterToPort, VerticalDistancePuckCenterToPort
	portAnglefromPuckCenter = angleBetweenConsecutivePorts * portIndexInCircle + m_SP_Puck_RotationAngle(puckIndex)
	HorzDistancePuckCenterToPort = portCircleRadius * Cos(DegToRad(portAnglefromPuckCenter))
	VerticalDistancePuckCenterToPort = portCircleRadius * Sin(DegToRad(portAnglefromPuckCenter))
	
	'' Project to World Coordinates
	Real puckCenterToPortCenter_X, puckCenterToPortCenter_Y, puckCenterToPortCenter_Z
	If (puckIndex = PUCK_A Or puckIndex = PUCK_B) Then
		puckCenterToPortCenter_X = HorzDistancePuckCenterToPort * Cos(DegToRad(angle_to_puck_center + 180))
		puckCenterToPortCenter_Y = HorzDistancePuckCenterToPort * Sin(DegToRad(angle_to_puck_center + 180))
	Else	''(puckIndex = PUCK_C Or puckIndex = PUCK_D) Then
		puckCenterToPortCenter_X = HorzDistancePuckCenterToPort * Cos(DegToRad(angle_to_puck_center))
		puckCenterToPortCenter_Y = HorzDistancePuckCenterToPort * Sin(DegToRad(angle_to_puck_center))
	EndIf
	puckCenterToPortCenter_Z = VerticalDistancePuckCenterToPort

	Real offsetFromPortDeepEnd, offsetXfromPortDeepEnd, offsetYfromPortDeepEnd
	If (puckIndex = PUCK_A Or puckIndex = PUCK_B) Then
		offsetFromPortDeepEnd = m_SP_Puck_Thickness(puckIndex) + distanceFromPuckSurface
	Else	''(puckIndex = PUCK_C Or puckIndex = PUCK_D) Then
		offsetFromPortDeepEnd = m_SP_Puck_Thickness(puckIndex) - distanceFromPuckSurface
	EndIf
	offsetXfromPortDeepEnd = offsetFromPortDeepEnd * Cos(DegToRad(angle_to_puck_center + 90))
	offsetYfromPortDeepEnd = offsetFromPortDeepEnd * Sin(DegToRad(angle_to_puck_center + 90))
	
	dx = puck_center_x + puckCenterToPortCenter_X + offsetXfromPortDeepEnd
	dy = puck_center_y + puckCenterToPortCenter_Y + offsetYfromPortDeepEnd
	dz = puck_center_z + puckCenterToPortCenter_Z
Fend

'' distanceFromPuckSurface > 0 is the offset away from the puck
'' distanceFromPuckSurface < 0 is the offset into the puck (port)
Function GTsetSPPortPoint(cassette_position As Integer, portIndex As Integer, puckIndex As Integer, distanceFromPuckSurface As Real, pointNum As Integer)
	Real U
	Real PerfectXoffsetFromCassetteCenter, PerfectYoffsetFromCassetteCenter, PerfectZoffsetFromBottom
	Real AbsoluteXafterTiltAjdust, AbsoluteYafterTiltAjdust, AbsoluteZafterTiltAjdust
	
	GTperfectSPPortOffset(cassette_position, portIndex, puckIndex, distanceFromPuckSurface, ByRef PerfectXoffsetFromCassetteCenter, ByRef PerfectYoffsetFromCassetteCenter, ByRef PerfectZoffsetFromBottom, ByRef U)

	Real ActualOffsetsFromCassetteCenter(3)
	GTapplyTiltToOffsets(cassette_position, PerfectXoffsetFromCassetteCenter, PerfectYoffsetFromCassetteCenter, PerfectZoffsetFromBottom, ByRef ActualOffsetsFromCassetteCenter())
	'' Set Absolute X,Y,Z Coordinates after GTapplyTiltToOffsets
	AbsoluteXafterTiltAjdust = g_CenterX(cassette_position) + ActualOffsetsFromCassetteCenter(0)
	AbsoluteYafterTiltAjdust = g_CenterY(cassette_position) + ActualOffsetsFromCassetteCenter(1)
	AbsoluteZafterTiltAjdust = g_BottomZ(cassette_position) + ActualOffsetsFromCassetteCenter(2)

	P(pointNum) = XY(AbsoluteXafterTiltAjdust, AbsoluteYafterTiltAjdust, AbsoluteZafterTiltAjdust, U) /R
Fend

Function GTsetSPPuckProbeStandbyPoint(cassette_position As Integer, puckIndex As Integer, standbyPointNum As Integer, ByRef scanDistance As Real)
	Integer port4Index, port14Index
	port4Index = 3;	port14Index = 13
	
	Integer temporaryPort4StandbyPoint, temporaryPort14StandbyPoint, temporaryPuckStandbyPoint
	temporaryPort4StandbyPoint = 105; temporaryPort14StandbyPoint = 106; temporaryPuckStandbyPoint = 107
	
	GTsetSPPortPoint(cassette_position, port4Index, puckIndex, PROBE_STANDBY_DISTANCE, temporaryPort4StandbyPoint)
	GTsetSPPortPoint(cassette_position, port14Index, puckIndex, PROBE_STANDBY_DISTANCE, temporaryPort14StandbyPoint)
	
	P(temporaryPuckStandbyPoint) = P(temporaryPort4StandbyPoint) + P(temporaryPort14StandbyPoint)
	
	Real standbyX, standbyY, standbyZ, standbyU
	standbyX = CX(P(temporaryPuckStandbyPoint)) / 2.0
	standbyY = CY(P(temporaryPuckStandbyPoint)) / 2.0
	standbyZ = CZ(P(temporaryPuckStandbyPoint)) / 2.0
	standbyU = CU(P(temporaryPuckStandbyPoint)) / 2.0

	P(standbyPointNum) = XY(standbyX, standbyY, standbyZ, standbyU) /R
	
	scanDistance = PROBE_STANDBY_DISTANCE + OVERPRESS_DISTANCE_FOR_PUCK
Fend

Function GTprobeSPPuck(cassette_position As Integer, puckIndex As Integer, jumpToStandbyPoint As Boolean)
	String msg$
	Tool PLACER_TOOL
	LimZ g_Jump_LimZ_LN2
	
	Integer standbyPoint
	standbyPoint = 52
	
	Real maxDistanceToScan

	GTsetSPPuckProbeStandbyPoint(cassette_position, puckIndex, standbyPoint, ByRef maxDistanceToScan)
	
	If jumpToStandbyPoint Then
		Jump P(standbyPoint)
	Else
		Move P(standbyPoint)
	EndIf
	
	GTsetRobotSpeedMode(PROBE_SPEED)
	
	ForceCalibrateAndCheck(LOW_SENSITIVITY, LOW_SENSITIVITY)
	
	g_PuckStatus(cassette_position, puckIndex) = PUCK_UNKNOWN
	If ForceTouch(DIRECTION_CAVITY_TAIL, maxDistanceToScan, False) Then
		'' Distance error from perfect sample position
		Real distErrorFromPerfectPuckSurface
		distErrorFromPerfectPuckSurface = Dist(P(standbyPoint), RealPos) - PROBE_STANDBY_DISTANCE
		
		If distErrorFromPerfectPuckSurface < UNDERPRESS_DISTANCE_FOR_PUCK Then
			g_PuckStatus(cassette_position, puckIndex) = PUCK_JAM
			msg$ = "GTprobeSPPuck: ForceTouch (" + GTpuckName$(puckIndex) + ") stopped " + Str$(distErrorFromPerfectPuckSurface) + "mm before reaching theoretical puck surface."
			UpdateClient(TASK_MSG, msg$, WARNING_LEVEL)
		ElseIf distErrorFromPerfectPuckSurface < OVERPRESS_DISTANCE_FOR_PUCK Then
			g_PuckStatus(cassette_position, puckIndex) = PUCK_PRESENT
			msg$ = "GTprobeSPPuck: ForceTouch dectected " + GTpuckName$(puckIndex) + " with distance error = " + Str$(distErrorFromPerfectPuckSurface) + "mm from theoretical puck surface."
			UpdateClient(TASK_MSG, msg$, WARNING_LEVEL)
		Else
			g_PuckStatus(cassette_position, puckIndex) = PUCK_ABSENT
			msg$ = "GTprobeSPPuck: ForceTouch (" + GTpuckName$(puckIndex) + ") moved " + Str$(distErrorFromPerfectPuckSurface) + "mm beyond theoretical puck surface."
			UpdateClient(TASK_MSG, msg$, WARNING_LEVEL)
		EndIf
	Else
		g_PuckStatus(cassette_position, puckIndex) = PUCK_ABSENT
		msg$ = "GTprobeSPPuck: ForceTouch failed to detect " + GTpuckName$(puckIndex) + " even after travelling maximum scan distance!"
		UpdateClient(TASK_MSG, msg$, WARNING_LEVEL)
	EndIf
	
	Move P(standbyPoint)
	GTLoadPreviousRobotSpeedMode
Fend

Function GTprobeSPPort(cassette_position As Integer, puckIndex As Integer, portIndex As Integer, jumpToStandbyPoint As Boolean)
	String msg$
	Tool PLACER_TOOL
	LimZ g_Jump_LimZ_LN2

	Integer standbyPoint
	standbyPoint = 52
	
	GTsetSPPortPoint(cassette_position, portIndex, puckIndex, PROBE_STANDBY_DISTANCE, standbyPoint)

	Real maxDistanceToScan
	maxDistanceToScan = PROBE_STANDBY_DISTANCE + SAMPLE_DIST_PIN_DEEP_IN_PUCK + TOLERANCE_FROM_PIN_DEEP_IN_PUCK
	
	If jumpToStandbyPoint Then
		Jump P(standbyPoint)
		ForceCalibrateAndCheck(LOW_SENSITIVITY, LOW_SENSITIVITY)
	Else
		Move P(standbyPoint)
	EndIf
		
	GTsetRobotSpeedMode(PROBE_SPEED)

	If ForceTouch(DIRECTION_CAVITY_TAIL, maxDistanceToScan, False) Then
		
		Real distancePuckSurfacetoHere
		distancePuckSurfacetoHere = Dist(P(standbyPoint), RealPos) - PROBE_STANDBY_DISTANCE
		
		g_SampleDistancefromPuckSurface(cassette_position, puckIndex, portIndex) = distancePuckSurfacetoHere
		msg$ = "{\set\:\g_SampleDistance\, \position\:\" + Str$(cassette_position) + "\, \puck\:\" + GTpuckName$(puckIndex) + "\, \port\:\" + Str$(portIndex + 1) + "\, \value\:\" + Str$(distancePuckSurfacetoHere) + "\}"
		UpdateClient(CLIENT_UPDATE, msg$, INFO_LEVEL)

		'' Distance error from perfect sample position
		Real distErrorFromPerfectSamplePos
		distErrorFromPerfectSamplePos = distancePuckSurfacetoHere - SAMPLE_DIST_PIN_DEEP_IN_PUCK
		
		If distErrorFromPerfectSamplePos < -TOLERANCE_FROM_PIN_DEEP_IN_PUCK Then
			''This condition means port jam or the sample is sticking out which is considered PORT_ERROR
			g_SP_PortStatus(cassette_position, puckIndex, portIndex) = PORT_ERROR
			msg$ = "GTprobeSPPort: ForceTouch on " + GTpuckName$(puckIndex) + ":" + Str$(portIndex + 1) + " stopped " + Str$(distErrorFromPerfectSamplePos) + "mm before reaching theoretical sample surface."
			UpdateClient(TASK_MSG, msg$, WARNING_LEVEL)
		ElseIf distErrorFromPerfectSamplePos < TOLERANCE_FROM_PIN_DEEP_IN_PUCK Then
			g_SP_PortStatus(cassette_position, puckIndex, portIndex) = PORT_OCCUPIED
			msg$ = "GTprobeSPPort: ForceTouch detected Sample at " + GTpuckName$(puckIndex) + ":" + Str$(portIndex + 1) + " with distance error =" + Str$(distErrorFromPerfectSamplePos) + "."
			UpdateClient(TASK_MSG, msg$, INFO_LEVEL)
		Else
			''This condition is never reached because ForceTouch stops when maxDistanceToScan is reached	
			''This condition is only to complete the If..Else Statement if an error occurs then we reach here
			g_SP_PortStatus(cassette_position, puckIndex, portIndex) = PORT_VACANT
			msg$ = "GTprobeSPPort: ForceTouch on " + GTpuckName$(puckIndex) + ":" + Str$(portIndex + 1) + " moved " + Str$(distErrorFromPerfectSamplePos) + "mm beyond theoretical sample surface."
			UpdateClient(TASK_MSG, msg$, INFO_LEVEL)
		EndIf

		GTTwistOffMagnet
	Else
		g_SP_PortStatus(cassette_position, puckIndex, portIndex) = PORT_VACANT
		''In reality g_SampleDistancefromPuckSurface is greater than maxDistanceToScan because there is no sample (or ForceTouch failure)
		g_SampleDistancefromPuckSurface(cassette_position, puckIndex, portIndex) = maxDistanceToScan
		msg$ = "GTprobeSPPort: ForceTouch failed to detect " + GTpuckName$(puckIndex) + ":" + Str$(portIndex + 1) + " even after travelling maximum scan distance!"
		UpdateClient(TASK_MSG, msg$, INFO_LEVEL)

		Move P(standbyPoint)
	EndIf
	
	'' The following code just realigns the dumbbell from twistoffmagnet position so not required if sample present in port
	'' Move P(standbyPoint) '' This is commented to reduce the time for probing
	'' we have to move to standbyPoint only for the last port probe to avoid hitting the cassette when jump is called

	'' previous robot speed is restored only after coming back to standby point, otherwise sample might stick to placer magnet
	GTLoadPreviousRobotSpeedMode
Fend

Function GTProbeSpecificPortsInSuperPuck(cassette_position As Integer) As Boolean
	'' Check whether it is really a superpuck adaptor
	If g_CassetteType(cassette_position) = SUPERPUCK_CASSETTE Then
		Integer probeStringLengthToCheck
		Integer puckIndex, puckPortIndex
		String PortProbeRequestChar$
		Boolean probeThisPuck
		For puckIndex = 0 To NUM_PUCKS - 1
			'' probeStringLengthToCheck is also the number of ports in this puck to check
			probeStringLengthToCheck = Len(g_PortsRequestString$(cassette_position)) - puckIndex * NUM_PUCK_PORTS
			If NUM_PUCK_PORTS < probeStringLengthToCheck Then probeStringLengthToCheck = NUM_PUCK_PORTS

			'' Initial check through probe request string to check whether there is a request by user, to probe any port in this puck
			probeThisPuck = False
			For puckPortIndex = 0 To probeStringLengthToCheck - 1
				PortProbeRequestChar$ = Mid$(g_PortsRequestString$(cassette_position), puckIndex * NUM_PUCK_PORTS + puckPortIndex + 1, 1)
				If PortProbeRequestChar$ = "1" Then
					probeThisPuck = True
					'' If a port is requested to probe, we don't have to check further, just exit for this for loop and start probing
					Exit For
				EndIf
			Next
			
			'' If there is a request to probe a port in this puck
			If probeThisPuck Then
				UpdateClient(TASK_MSG, "GTProbeSpecificPortsInSuperPuck->GTprobeSPPuck(" + GTCassetteName$(cassette_position) + "," + GTpuckName$(puckIndex) + ")", INFO_LEVEL)
				GTprobeSPPuck(cassette_position, puckIndex, True)
			
				If g_PuckStatus(cassette_position, puckIndex) = PUCK_PRESENT Then
					''Run adaptor angle correction for this puck only if puck is present, this reduces time to finish probing
					UpdateClient(TASK_MSG, "GTProbeSpecificPortsInSuperPuck->GTprobePuckAngleCorrection(" + GTCassetteName$(cassette_position) + "," + GTpuckName$(puckIndex) + ")", INFO_LEVEL)
					If Not GTprobeAdaptorAngleCorrection(cassette_position, puckIndex, False) Then
						g_RunResult$ = "error GTProbeSpecificPortsInSuperPuck->GTprobeAdaptorAngleCorrection!"
						UpdateClient(TASK_MSG, "GTProbeSpecificPortsInSuperPuck failed: error in GTprobeAdaptorAngleCorrection!", ERROR_LEVEL)
						GTProbeSpecificPortsInSuperPuck = False
						Exit Function
					EndIf
			
					For puckPortIndex = 0 To probeStringLengthToCheck - 1
						'' Probe the superpuck ports corresponding to 1's in probeRequestString
						PortProbeRequestChar$ = Mid$(g_PortsRequestString$(cassette_position), puckIndex * NUM_PUCK_PORTS + puckPortIndex + 1, 1)
						If PortProbeRequestChar$ = "1" Then
							''UpdateClient(TASK_MSG, "GTProbeSpecificPortsInSuperPuck->GTprobeSPPort(" + GTCassetteName$(cassette_position) + "," + GTpuckName$(puckIndex) + "," + Str$(puckPortIndex + 1) + ")", INFO_LEVEL)
							GTprobeSPPort(cassette_position, puckIndex, puckPortIndex, False)
						EndIf
					Next
					'' we have to move to standbyPoint only for the last port probe to avoid hitting the cassette when jump is called
					Move P52 '' P52 is used as standbyPoint throughout GT domain
					
				EndIf
			EndIf
		Next
	Else
		UpdateClient(TASK_MSG, "GTProbeSpecificPortsInSuperPuck failed: " + GTCassetteName$(cassette_position) + " is not SuperPuck Adaptor!", ERROR_LEVEL)
		GTProbeSpecificPortsInSuperPuck = False
		Exit Function
	EndIf

	GTProbeSpecificPortsInSuperPuck = True
Fend

Function GTResetSpecificPortsInSuperPuck(cassette_position As Integer)
	Integer resetStringLengthToCheck
	Integer puckIndex, puckPortIndex
	String PortResetRequestChar$

	If g_CassetteType(cassette_position) = SUPERPUCK_CASSETTE Then
		For puckIndex = 0 To NUM_PUCKS - 1
			'' resetStringLengthToCheck is also the number of ports in this puck to reset
			resetStringLengthToCheck = Len(g_PortsRequestString$(cassette_position)) - puckIndex * NUM_PUCK_PORTS
			If NUM_PUCK_PORTS < resetStringLengthToCheck Then resetStringLengthToCheck = NUM_PUCK_PORTS
			
			For puckPortIndex = 0 To resetStringLengthToCheck - 1
				'' Reset the superpuck ports corresponding to 1's in probeRequestString
				PortResetRequestChar$ = Mid$(g_PortsRequestString$(cassette_position), puckIndex * NUM_PUCK_PORTS + puckPortIndex + 1, 1)
				If PortResetRequestChar$ = "1" Then
					g_SampleDistancefromPuckSurface(cassette_position, puckIndex, puckPortIndex) = 0.0
					g_SP_PortStatus(cassette_position, puckIndex, puckPortIndex) = PORT_UNKNOWN
				EndIf
			Next
		Next
	Else
		'' This condition is reached only if the cassette is not a superpuck cassette
		'' Or this function (GTResetSpecificPortsInSuperPuck) is called before probing CassetteType
		'' So reset all the ports to unknown
		For puckIndex = 0 To NUM_PUCKS - 1
			g_PuckStatus(cassette_position, puckIndex) = PUCK_UNKNOWN
			For puckPortIndex = 0 To NUM_PUCK_PORTS - 1
				g_SampleDistancefromPuckSurface(cassette_position, puckIndex, puckPortIndex) = 0.0
				g_SP_PortStatus(cassette_position, puckIndex, puckPortIndex) = PORT_UNKNOWN
			Next
		Next
	EndIf
Fend

