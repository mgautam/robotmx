'' Cassette Position
#define UNKNOWN_POSITION -1
#define LEFT_CASSETTE 0
#define MIDDLE_CASSETTE 1
#define RIGHT_CASSETTE 2
#define NUM_CASSETTES 3

'' Cassette Type
#define UNKNOWN_CASSETTE 0	'' Unknown cassette, Cassette Absent, Cassette Problem
#define CALIBRATION_CASSETTE 1
#define NORMAL_CASSETTE 2
#define SUPERPUCK_CASSETTE 3

'' Maximum values among all types of cassettes
#define MAXIMUM_NUM_PORTS 96

'' Toolset Names
#define UNIVERSAL_TOOL 0
#define PICKER_TOOL 1
#define PLACER_TOOL 2

'' PORT Status
#define PORT_OCCUPIED -1
#define PORT_UNKNOWN 0
#define PORT_VACANT 1
#define PORT_ERROR 2

#define DISTANCE_P3_TO_P6 20.0 ''mm
#define MAGNET_AXIS_TO_CRADLE_EDGE 2.8 'mm
#define MAGNET_PROBE_DISTANCE_TOLERANCE (MAGNET_HEAD_RADIUS + 0.1)

'' Could be CASSETTE_SHRINK_IN_LN2 (0.9961126827)
#define CASSETTE_SHRINK_FACTOR (1.0 + g_LN2LevelHigh * (1.0 - CASSETTE_SHRINK_IN_LN2))

#define PROBE_STANDBY_DISTANCE 5.0
'' Acceptable error in cassette height in mm
#define ACCPT_ERROR_IN_CASSETTE_HEIGHT 0.4
'' Retry Threshold for height in mm
#define MAX_ERR_FOR_SCAN_CAS_TYPE_RTRY 1.4

''Robot Speed Modes
#define PROBE_SPEED 0
#define INSIDE_LN2_SPEED 1
#define OUTSIDE_LN2_SPEED 2

'' Go speed settings for Probing (Same as very slow speed)
#define PROBE_GO_ACCEL 30
#define PROBE_GO_DEACCEL 30
#define PROBE_GO_SPEED 60
'' Move speed settings for Probing (Same as very slow speed)
#define PROBE_MOVE_ACCEL 30
#define PROBE_MOVE_DEACCEL 30
#define PROBE_MOVE_SPEED 60

'' Go speed settings for INSIDE_LN2
#define INSIDE_LN2_GO_ACCEL 60
#define INSIDE_LN2_GO_DEACCEL 60
#define INSIDE_LN2_GO_SPEED 90
'' Move speed settings for INSIDE_LN2
#define INSIDE_LN2_MOVE_ACCEL 60
#define INSIDE_LN2_MOVE_DEACCEL 60
#define INSIDE_LN2_MOVE_SPEED 90

'' Go speed settings for OUTSIDE_LN2
#define OUTSIDE_LN2_GO_ACCEL 40
#define OUTSIDE_LN2_GO_DEACCEL 40
#define OUTSIDE_LN2_GO_SPEED 80
'' Move speed settings for OUTSIDE_LN2
#define OUTSIDE_LN2_MOVE_ACCEL 40
#define OUTSIDE_LN2_MOVE_DEACCEL 40
#define OUTSIDE_LN2_MOVE_SPEED 80
