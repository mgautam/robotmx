#include "networkdefs.inc"
#include "genericdefs.inc"

Boolean m_GTInitialized

Function GTInitialize() As Boolean
	If m_GTInitialized Then
		GTInitialize = True
		Exit Function
	Else
		'' This is the first call of GTInitialize() function
		GTInitialize = False
		m_GTInitialized = False
	EndIf

	InitForceConstants
	
	initSuperPuckConstants
	GTInitPrintLevel
	
	If Not GTInitAllPoints Then
		UpdateClient(TASK_MSG, "GTInitialize:GTInitAllPoints failed", ERROR_LEVEL)
		Exit Function
	EndIf
	
	GTInitialize = True
	m_GTInitialized = True
Fend

Function GTStartRobot
	'' This is the only function in GT domain which starts the motors and sets the power   	
	
   	If Not CheckEnvironment Then
   		Motor Off
		UpdateClient(TASK_MSG, "GTStartRobot:CheckEnvironment failed. So the robot motors are stopped, it can't move.", ERROR_LEVEL)
        Exit Function
   	EndIf
   	
	If Motor = Off Then
		Motor On

		''Set dumbbell status to unknown whenever motors are started from off state
		GTsetDumbbellStatus(DUMBBELL_STATUS_UNKNOWN)
	EndIf
   	
   	Power High ''For debugging use low power mode
   		   	
	Tool 0
	GTsetRobotSpeedMode(OUTSIDE_LN2_SPEED)
Fend

