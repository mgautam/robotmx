'' Cassette Position
#define LEFT_CASSETTE 0
#define MIDDLE_CASSETTE 1
#define RIGHT_CASSETTE 2
#define NUM_CASSETTES 3

'' Cassette Type
#define UNKNOWN_CASSETTE 0	'' Unknown cassette, Cassette Absent, Cassette Problem
#define CALIBRATION_CASSETTE 1
#define NORMAL_CASSETTE 2
#define SUPERPUCK_CASSETTE 3

'' Acceptable error in cassette height in mm
#define ACCPT_ERROR_IN_CASSETTE_HEIGHT 0.4
'' Retry Threshold for height in mm
#define MAX_ERR_FOR_SCAN_CAS_TYPE_RTRY 1.4

'' Normal and Calibration Cassette Properties
#define NUM_ROWS 8
#define NUM_COLUMNS 12

#define CASSETTE_ROW_HEIGHT -15

#define OVERPRESS_DISTANCE_FOR_CAS 1.0
#define PIN_DEEP_IN_CAS_DISTANCE 3.2
#define PROBE_DISTANCE_FOR_CAS_PORT 4.2

'' SuperPuck/PuckAdaptor Properties
#define SUPERPUCK_WIDTH 72.0
#define SUPERPUCK_HEIGHT 137.0

#define PUCK_A 0
#define PUCK_B 1
#define PUCK_C 2
#define PUCK_D 3
#define NUM_PUCKS 4

#define NUM_PUCK_PORTS 16

#define PUCK_ABSENT False
#define PUCK_PRESENT True

#define PROBE_STANDBY_DISTANCE 5.0
#define PROBE_ADAPTOR_DISTANCE 3.0

#define OVERPRESS_DISTANCE_FOR_PUCK 0.8
#define PIN_DEEP_IN_PUCK_DISTANCE 2.5
#define PROBE_DISTANCE_FOR_PUCK_PORT 3.3

#define PROBE_DISTANCE_TOLERANCE 0.1

'' Toolset Names
#define UNIVERSAL_TOOL 0
#define PICKER_TOOL 1
#define PLACER_TOOL 2

'' PORT Properties
#define SAMPLE_ABSENT False
#define SAMPLE_PRESENT True
