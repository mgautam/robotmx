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
''
'' Modification Log
'' 04/12/12 Initial Release

''Australian Synchrotron force sensing

''Epson signals used
#define FORCEMEASURELOOP_ACQUIRING 7
#define FORCEMEASURELOOP_WAKE 8

''The calibration file to use
#define CALFILE "C:\\EpsonRC60\\force\\FT13559.cal"
''Force sensor device to use
#define DEVICE "dev1"

''Sensitivity in detecting LN2 boiling
''Lower is more sensitive, higher is less sensitive
#define HIGH_SENSITIVITY 0.012
#define MEDIUM_SENSITIVITY 0.02
#define LOW_SENSITIVITY 0.06
''TIMEOUT for LN2 boil detection
#define SENSE_TIMEOUT 120

''Number of joints
#define NUM_JOINTS 6
''Number of forces
#define NUM_FORCES NUM_JOINTS

''Dll file location.  Copy used by VB guide and SPEL must have exact same path
''#define ASFSDLL "C:\dcs\RobotDHS-6\src\Debug\ATICombinedDAQFT.dll"

''Dll file location.  Used for testing SPEL side only
#define ASFSDLL "C:\dcs\ATICombinedDAQFT\Debug\ATICombinedDAQFT.dll"


