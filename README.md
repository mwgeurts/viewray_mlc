ViewRay MLC Position Check
===========

Author: Mark Geurts, mark.w.geurts@gmail.com

Copyright (C) 2014 University of Wisconsin Board of Regents

AnalyzeMLCProfiles loads Monte Carlo treatment planning data from the ViewRay TPS and compares it to measured Sun Nuclear IC Profiler data.  To successfully process the data, six exposures must be acquired for a given head and gantry angle at the following MLC X1 and X2 positions (in cm):

X1: -12.5, -8.5, -4.5, -0.5, 3.5, 7.5

X2: -7.5, -3.5, 0.5, 4.5, 8.5, 12.5

When measuring data with IC Profiler, it is assumed that the profiler will be positioned with the electronics pointing toward IEC-X for 0 and 180 degree gantry angles, toward IEC+Z for 90 and 270 degrees. Therefore, for 0 and 90 degree gantry angles, the Monte Carlo data calculated through the front of the IC Profiler is used.  For 180 degrees, the Monte Carlo data calculated through the couch and back of the profiler is used. For 270 degrees, the data calculated through the back of the profiler (but without the couch) is used.
