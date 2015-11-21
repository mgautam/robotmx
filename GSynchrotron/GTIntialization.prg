#include "GTReporterdefs.inc"

#define CLOSE_DISTANCE 10

Function GTInitialize() As Boolean

	InitForceConstants
	
	initSuperPuckConstants
	initGTReporter
	
	g_RunResult$ = "progress GTInitialize->GTInitAllPoints"
	If Not GTInitAllPoints Then
		GTUpdateClient(TASK_FAILURE_REPORT, HIGH_LEVEL_FUNCTION, "GTInitAllPoints failed")
		g_RunResult$ = "error GTInitAllPoints"
		GTInitialize = False
		Exit Function
	EndIf
	
	Motor On
	Tool 0
	
	g_RunResult$ = "progress GTInitialize: Grabbing Magnet from Cradle routine"
	If Dist(RealPos, P0) < CLOSE_DISTANCE Then
		Jump P1
	EndIf
	

	If Sw(IN_GRIP_CLOSE) = 1 And Sw(IN_GRIP_OPEN) = 0 Then
		'' If Tong is closed, then assume magnet not in tong	
		GTUpdateClient(TASK_MESSAGE_REPORT, HIGH_LEVEL_FUNCTION, "GTInitialize:Assumed magnet is in tong because gripper is closed.")
	Else
		Jump P3
		Move P6
		If Not Close_Gripper Then
			GTUpdateClient(TASK_FAILURE_REPORT, HIGH_LEVEL_FUNCTION, "GTInitialize:Close_Gripper failed")
			GTInitialize = False
			Exit Function
		EndIf
		Jump P3
	EndIf
	
	g_RunResult$ = "success GTInitialize"
	GTInitialize = True
Fend

