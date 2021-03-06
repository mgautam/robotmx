'' Copyright (c) 2012  Australian Synchrotron
''
'' This library is free software; you can redistribute it and/or
'' modify it under the terms of the GNU Lesser General Public
'' Licence as published by the Free Software Foundation; either
'' version 2.1 of the Licence, or (at your option) any later version.
''
'' This library is distributed in the hope that it will be useful,
'' but WITHOUT ANY WARRANTY; without even the implied warranty of
'' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
'' Lesser General Public Licence for more details.
''
'' You should have received a copy of the GNU Lesser General Public
'' Licence along with this library; if not, write to the Free Software
'' Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
''
'' Contact details:
'' mark.clift@synchrotron.org.au
'' 800 Blackburn Road, Clayton, Victoria 3168, Australia.

#include "networkdefs.inc"
#include "forcedefs.inc"

''globals
''===========================================================
''Australian Synchrotron force sensing
''Global location for storing forces measured via ATICombinedDAQFT.dll
''Store the forces that caused the last ForceTrigger
Global Double g_FSTriggeredForces(NUM_FORCES)
''Stop/start force measureloop as desired
Boolean m_ForceMeasureLoopSleep
''Average this many samples in ForceMeasureLoop
Global Integer g_FSAverage
''Global status of force sensing trigger
Global Integer g_FSForceTriggerStatus
''Global status of Australian Synchrotron force sensing
Global Boolean g_FSInitOK

''Force sensing external methods
Declare FSInit, ASFSDLL, "FSInit",(calibrationFile$ As String, deviceName$ As String) As Boolean
Declare FSIsServer, ASFSDLL, "FSIsServer", As Boolean
Declare FSStartAcquisition, ASFSDLL, "FSStartAcquisition",(sampleFrequency As Integer, samplestoaverage As Integer) As Boolean
Declare FSSetTrigger, ASFSDLL, "FSSetTrigger",(forceName As Integer, threshold As Double, compareType As Integer) As Boolean
Declare FSClearTrigger, ASFSDLL, "FSClearTrigger", As Boolean
Declare FSIsTriggered, ASFSDLL, "FSIsTriggered", As Integer
Declare FSCalibrate, ASFSDLL, "FSCalibrate",(samplestoaverage As Integer) As Boolean
Declare FSReadForces, ASFSDLL, "FSReadForces",(ByRef forces() As Double, samplestoaverage As Integer) As Boolean
Declare FSReadTriggeredForces, ASFSDLL, "FSReadTriggeredForces",(ByRef forces() As Double) As Boolean
Declare FSStopAcquisition, ASFSDLL, "FSStopAcquisition", As Boolean
Declare FSGetErrorDesc, ASFSDLL, "FSGetErrorDesc",(ByRef mesg$ As String) As Boolean
Declare FSIsAcquiring, ASFSDLL, "FSIsAcquiring", As Boolean

''Force sensing SPEL methods

''Start the force sensing system
Function ForceInit
	''error messaging
	String mesg$
	''Initialize Australian Synchrotron force sensing
	If FSInit(CALFILE, DEVICE) Then
		''force sensing intialize ok
		g_FSInitOK = True
		''Put forcemeasureloop to sleep
		m_ForceMeasureLoopSleep = True
		Print "Force sensing initialize ok"
	Else
		''force sensing intialize fail
		g_FSInitOK = False
		''Retrieve the error message from api
		FSGetErrorDesc(ByRef mesg$)
		''Print the error
		Print mesg$
		Print "Force sensing initialize failed"
		Print "Check CALFILE file/path specified in robotdefs.inc"
		Exit Function
	EndIf
	''Print Force sensing server/client status
	If FSIsServer Then
		Print "This application is force sensing server"
	Else
		Print "This application is force sensing client"
	EndIf
	''Start force sensing acquisition @28000KHz averaging 1000 samples
	''Takes around 1/25 sec to read single sample at this rate
	If FSStartAcquisition(28000, 1) Then
        Print "Force acquisition start ok"
    Else
    	''force sensing intialize fail
		g_FSInitOK = False
    	''Retrieve the error message from api
		FSGetErrorDesc(ByRef mesg$)
		''Print the error
		Print mesg$
		Print "Force acquisition start failed"
		Exit Function
	EndIf
Fend
''EPS loop
Function EPSLoop
	Double xpos
	Integer lid_closed
	String err$
	
	OnErr GoTo errhandler
	
	Do While 1
		xpos = CX(RealPos)
		lid_closed = Sw(11)
		If xpos < -165 And lid_closed = On And Not InPos Then
			AbortMotion Robot
		EndIf
		Wait 0.01
	Loop
	
errhandler:
	''construct the error string
	err$ = "EPSLoop !!Error:" + " " + Str$(Err) + " " + ErrMsg$(Err) + " " + "Line: " + Str$(Erl)
	Wait 0.1
	EResume Next
Fend
Function ForceTest
	Double forces(7)
	Integer i
	String mesg$
	''FSCalibrate()
	Do While True
		''Read forces direct from DLL for testing purposes
		If FSReadForces(ByRef forces(), 100) Then
			''Success, print result
			''Print result
			Print FmtStr$(forces(1), "00.000") + " " + FmtStr$(forces(2), "00.000") + " " + FmtStr$(forces(3), "00.000") + " " + FmtStr$(forces(4), "00.000") + " " + FmtStr$(forces(5), "00.000") + " " + FmtStr$(forces(6), "00.000")
			Wait 3
		Else
			Print "error"
			''Print error from api
			FSGetErrorDesc(ByRef mesg$)
			Print mesg$
			Wait .5
		EndIf
	Loop
Fend
''Test performance of force system
Function ForcesTest()
	Double fvalues(NUM_FORCES)
	''We keep an eye on the time
	Long entryTime
	Long startTime
	Long nowTime
	Integer i
	i = 0
	''Wait for second tick
	startTime = Time(2)
	nowTime = startTime
	Do While (nowTime = startTime)
		Wait .001
		nowTime = Time(2)
	Loop
	Print Time$
	''Wait for second tick
	startTime = Time(2)
	nowTime = startTime
	Do While (nowTime = startTime)
		ReadForces(ByRef fvalues())
		nowTime = Time(2)
		i = i + 1
	Loop

	Print "In 1 second obtained " + Str$(i) + " samples"
	''ReadForces(ByRef fvalues())
	''Print Str$(fvalues(1)) + " " + Str$(fvalues(2)) + " " + Str$(fvalues(3))
	Print Time$
Fend
Function ForceMeasureLoopSleep
	''Set ForceMeasureLoopSleep to true
	m_ForceMeasureLoopSleep = True
	''Wait .01 ''Wait to Stop ForceMeasureLoop to allow ReadForces to be called
Fend
Function ForceMeasureLoopWake
	''Set ForceMeasureLoopSleep to false
	m_ForceMeasureLoopSleep = False
	''Signal ForceMeasureLoop to wake
	Signal FORCEMEASURELOOP_WAKE
	''Wait till ForceMeasureLoop is acquiring
	WaitSig FORCEMEASURELOOP_ACQUIRING
	''Wait .01 ''start ForceMeasureLoop and wait to read few force samples before GenericMove
Fend
''Background force measurement loop
Function ForceMeasureLoop
	''Uses Epson force numbering of 1-6
	Double forces(NUM_FORCES)
	Integer FSForceTriggerStatus_old
	Integer i
	''continuously update measured force variables
	Do While 1
		FSForceTriggerStatus_old = g_FSForceTriggerStatus
		If m_ForceMeasureLoopSleep = False Then
			''Acquire force data
			FSReadForces(ByRef forces(), g_FSAverage)
			''Update the force trigger status
			g_FSForceTriggerStatus = FSIsTriggered()
		    ''Print "Force measure loop alive and with new samples"
			''Trigger occurred, make backup of force values
			''so caller can check force that caused trigger
			If (g_FSForceTriggerStatus <> 0 And FSForceTriggerStatus_old = 0) Then
				For i = 1 To NUM_FORCES Step 1
					g_FSTriggeredForces(i) = forces(i)
				Next
			EndIf
			''Signal function setting g_StopForceMeasureLoop flag
			''That ForceMeasureLoop is acquiring force data
			Signal FORCEMEASURELOOP_ACQUIRING
		Else
            WaitSig FORCEMEASURELOOP_WAKE
			''Wait .001 ''Not acquiring
		EndIf
	Loop
Fend

''Read a single force and return value to caller
Function ReadForce(ByVal forceName As Integer) As Double
    ''Uses Epson force numbering of 1-6
	Double forces(NUM_FORCES)
    Integer ForceIndex
    ''Default return value
    ReadForce = 0
    ''ensure requested forceName is valid    
    ForceIndex = Abs(forceName)
    If ForceIndex <= 0 Or ForceIndex > 6 Then
        Exit Function
    EndIf
	''Read the forces
	FSReadForces(ByRef forces(), 1000)
	''Pass force to caller
	ReadForce = forces(ForceIndex)
Fend
''Read all forces and return value to caller
Function ReadForces(ByRef returnForces() As Double)
	FSReadForces(ByRef returnForces(), 1000)
Fend
''Setup move until force trigger value
Function SetupForceTrigger(ByVal forceName As Integer, ByVal threshold As Real)
	''Clear previous trigger setting
    FSClearTrigger()
    ''Decide how much to average given forceName
    Select Abs(forceName)
    	Case FORCE_ZFORCE
    		''More noise in Z, so average more
    		g_FSAverage = 70
    	Case FORCE_ZTORQUE
    		''More noise in Z, so average more
    		g_FSAverage = 70
   		Default
   			''Less noise in XY
   		    ''Averaging for XY
   			g_FSAverage = 80
    Send
    
    ''for torque, "less" is "greater". Will be changed if vendor fix this bug
#ifdef FORCE_TORQUE_WRONG_DIRECTION
    Select forceName
    Case FORCE_XFORCE
        FSSetTrigger forceName, threshold, FORCE_GREATER
    Case FORCE_YFORCE
        FSSetTrigger forceName, threshold, FORCE_GREATER
    Case FORCE_ZFORCE
        FSSetTrigger forceName, threshold, FORCE_GREATER
    Case FORCE_XTORQUE
        FSSetTrigger forceName, threshold, FORCE_LESS
    Case FORCE_YTORQUE
        FSSetTrigger forceName, threshold, FORCE_LESS
    Case FORCE_ZTORQUE
        FSSetTrigger forceName, threshold, FORCE_LESS
    Case -FORCE_XFORCE
        FSSetTrigger -forceName, threshold, FORCE_LESS
    Case -FORCE_YFORCE
        FSSetTrigger -forceName, threshold, FORCE_LESS
    Case -FORCE_ZFORCE
        FSSetTrigger -forceName, threshold, FORCE_LESS
    Case -FORCE_XTORQUE
        FSSetTrigger -forceName, threshold, FORCE_GREATER
    Case -FORCE_YTORQUE
        FSSetTrigger -forceName, threshold, FORCE_GREATER
    Case -FORCE_ZTORQUE
        FSSetTrigger -forceName, threshold, FORCE_GREATER
    Send
#else
	If forceName > 0 Then
		FSSetTrigger forceName, threshold, FORCE_GREATER
	Else
		FSSetTrigger -forceName, threshold, FORCE_LESS
	EndIf
#endif
Fend
''Calibrate the force sensor and check noise levels
Function ForceCalibrateAndCheck(thresholdx As Double, thresholdy As Double) As Boolean
	''mesg to client
	String msg$
	Boolean calok
	''We keep an eye on the time
	Long startTime
	Long nowTime
	''Calibration attempt counter
    Integer i
    Boolean done
	Double forces(NUM_FORCES)
	''Used to calc peak to peak ripple on force sensor
	Double diffx, diffy
	Double minx, maxx
	Double miny, maxy
	''inform user what is going on
	UpdateClient(TASK_MSG, "Calibrating force sensor, and checking peak noise", INFO_LEVEL)
	''Defaults
    done = False
	ForceCalibrateAndCheck = False
	i = 1
	''Repeat upto 5 times
	Do While Not done And Not g_FlagAbort
		''Calibrate the force sensor
		calok = FSCalibrate(1000)
		''default peak to peak variables
		minx = 99999
		maxx = -99999
		miny = 99999
		maxy = -99999
		''Record controller uptime in secs at acquisition start
	    startTime = Time(2)
		nowTime = Time(2)
		''Sample over roughly 1 sec to obtain force min and max data for X, Y forces
		Do While (nowTime = startTime)
			ReadForces(ByRef forces())
			MinMax(forces(1), ByRef minx, ByRef maxx)
			MinMax(forces(2), ByRef miny, ByRef maxy)
			''need slight pause so ReadForces does not hog the FSSENSING_LOCK
			Wait .01
			''Read controller uptime in secs
			nowTime = Time(2)
		Loop
		''calculate peak to peak ripple
		diffx = maxx - minx
		diffy = maxy - miny
		''Compare ripple against requirements
		If (diffx < thresholdx And diffy < thresholdy And forces(3) < .2) Then
				done = True
				msg$ = "After " + Str$(i) + " calibration attempts"
				UpdateClient(TASK_MSG, msg$, INFO_LEVEL)
                UpdateClient(TASK_MSG, "Force sensor noise level OK", INFO_LEVEL)
				ForceCalibrateAndCheck = True
		EndIf
		''Only attempt 10 times
		i = i + 1
		If (i > 19) Then
 			msg$ = "After " + Str$(i) + " calibration attempts"
			UpdateClient(TASK_MSG, msg$, ERROR_LEVEL)
			UpdateClient(TASK_MSG, "Force sensor noise level too high", ERROR_LEVEL)
			msg$ = "ForceX p-p " + Str$(diffx)
			UpdateClient(TASK_MSG, msg$, ERROR_LEVEL)
			msg$ = "ForceY p-p " + Str$(diffy)
			UpdateClient(TASK_MSG, msg$, ERROR_LEVEL)
			''Fail to good
			ForceCalibrateAndCheck = True
			Exit Function
		EndIf
	Loop
Fend
''Conveniance function used to find min and max values
Function MinMax(value As Double, ByRef min As Double, ByRef max As Double)
	If value > max Then
		max = value
	EndIf
	If value < min Then
		min = value
	EndIf
Fend
''Use force sensor to detect LN2 boiling
''Return number of seconds waited before LN2 boiling stopped, or timeout
Function WaitLN2BoilingStop(timeout As Integer, thresholdx As Double, thresholdy As Double) As Integer
	''We keep an eye on the time
	Long entryTime
	Long startTime
	Long nowTime
	''Array to store the forces
	Double forces(NUM_FORCES)
	''Variables to look at force distribution over 1 sec 
	Double diffx, diffy
	Double maxx, maxy
	Double minx, miny
	''Record controller uptime in secs at function entry
	entryTime = Time(2)
	''Default value
	WaitLN2BoilingStop = -1
	''Wait till LN2 boiling stops, timeout or user presses abort
	Do While WaitLN2BoilingStop = -1 And Not g_FlagAbort
		''default max and min
		maxx = -99999
		maxy = -99999
		minx = 99999
		miny = 99999
		
		''Record controller uptime in secs at acquisition start
	    startTime = Time(2)
		nowTime = Time(2)
		
		''Sample over roughly 1 sec to obtain force min and max data for X, Y forces
		Do While (nowTime - startTime) < 1
			ReadForces(ByRef forces())
			MinMax(forces(1), ByRef minx, ByRef maxx)
			MinMax(forces(2), ByRef miny, ByRef maxy)
			''need slight pause so ReadForces does not hog the FSSENSING_LOCK
			Wait .01
			''Read controller uptime in secs
			nowTime = Time(2)
		Loop
		
		''Find diff values for X, Y forces
		diffx = maxx - minx
		diffy = maxy - miny
		
		''Print "diffx=", diffx
		''Print "diffy=", diffy

		''see if boiling stopped
		If (diffx < thresholdx And diffy < thresholdy) Then
			''Boiling stopped break from while loop
			''And return number of seconds we waited
			WaitLN2BoilingStop = nowTime - entryTime
		EndIf

		''Check for timeout before trying again
		If (nowTime - entryTime) > timeout Then
			''Timeout.  Set time waited
			WaitLN2BoilingStop = nowTime - entryTime
		EndIf
	Loop
Fend
