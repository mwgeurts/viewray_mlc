ViewRay MLC Position Check
===========

Author: Mark Geurts, mark.w.geurts@gmail.com

Copyright (C) 2014 University of Wisconsin Board of Regents

AnalyzeMLCProfiles.m loads Monte Carlo treatment planning data from the ViewRay TPS and compares it to measured Sun Nuclear IC Profiler data.  To successfully process the data, six exposures must be acquired for a given head and gantry angle at the following MLC positions (in cm):

| Strip   |	X1 (cm) |	 X2 (cm) |  Y1 (cm) |	 Y2 (cm) |
----------|---------|----------|----------|----------|
| Strip 1	|  -12.5  |   -7.5 	 |  -13.65	|  +13.65  |
| Strip 2	|  -8.5	  |   -3.5	 |  -13.65	|  +13.65  |
| Strip 3	|  -4.5	  |   +0.5 	 |  -13.65  |	 +13.65  |
| Strip 4	|  -0.5   |	  +4.5   |	-13.65  |	 +13.65  |
| Strip 5 |	 +3.5   |	  +8.5	 |  -13.65  |	 +13.65  |
| Strip 6 |	 +7.5	  |  +12.5	 |  -13.65	|  +13.65  |

When measuring data with IC Profiler, it is assumed that the profiler will be positioned with the electronics pointing toward IEC-X for 0 and 180 degree gantry angles, toward IEC+Z for 90 and 270 degrees. Therefore, for 0 and 90 degree gantry angles, the Monte Carlo data calculated through the front of the IC Profiler is used.  For 180 degrees, the Monte Carlo data calculated through the couch and back of the profiler is used. For 270 degrees, the data calculated through the back of the profiler (but without the couch) is used.

The following steps illustrate how to acquire and process 90 and 270 degree measurements.  

## Set up the IC Profiler

1. Attach the SNC IC Profiler to the IC Profiler jig.
2. Connect the IC Profiler to the Physics Workstation using the designated cable.
3. Launch the SNC Profiler software on the Physics Workstation.
4. Select the most recent Dose calibration from the dropdown box.
5. Select the most recent array Calibration from the dropdown box.
6. Verify the mode is continuous by clicking the Control menu.

## Orient the IC Profiler in the Sagittal Position

1. Place the SNC Profiler jig on the couch at virtual isocenter and orient the jig in the Sagittal orientation, as shown.
  1. The top of the profiler will be facing the IEC+X axis.
  2. The electronics will be on the facing upwards (IEC+Y axis).
  3. Place an aluminum level on the front face of the IC Profiler as shown.
  4. Verify the profiler is parallel with the IEC Sagittal plane.
  5. Use the leveling feet on the jig to adjust if necessary.
  6. Laterally adjust the jig until the overhead IEC X laser is aligned to the front face of the IC Profiler.
  7. Record the current couch position.
  8. Use the Couch Control Panel to move the couch and IC Profiler +0.9 cm in the IEC+X direction.
  9. The detector plane of the IC Profiler should now be at isocenter.
  10. Vertically and Longitudinally align the IC Profiler to the crosshairs using the wall IEC Y and IEC Z laser.
  11. Press the ENABLE and ISO buttons on the Couch Control Panel to move the couch from virtual to mechanical isocenter.
2. On the ViewRay TPDS, select Tools > QA Procedure and select the Calibration tab.
3. Select an arbitrary phantom and click Load Phantom.
4. Under Beam Setup and Controls, select Head 3.
5. Set Delivery Angle to 90 degrees.
6. Under MLC Setup, set the following MLC positions: X1/Y1 = -5.25 cm, X2/Y2 = +5.25 cm.
7. Click Set Shape to apply the MLC positions.
8. Enter 30 seconds as the Beam-On Time.
9. Click Prepare Beam Setup.
10. Click Enable Beam On.
11. Press Beam On on the Treatment Control Panel.
12. In the SNC Profiler software, click Start.
13. When asked if the new measurement is continuous, click Yes.
14. Wait for the beam to be delivered.
15. Click Stop on the Profiler Software.
16. Enter the Delivery Parameters and Save the File.
  1. Click on the Setup tab.
  2. Enter the gantry angle.
  3. Set the SSD to 100 cm.
  4. Check Symmetric Collimators.
  5. Enter the field size as 10.5 cm x 10.5 cm.
  6. Click on the General tab.
  7. Under Description, type Head #, where # is the head number (3 in this instance).
  8. Click OK.
  9. When asked to save the file, choose Multi-Frame type and save the results to _H3 G90 10p5.prm_.
17. Move the Gantry to 270 degrees and repeat the exposure, saving the results to _H3G270 10p5.prm_.
18. Review the 90 degree and 270 degree Profiler Y-Axis.
  1. Calculate the average Beam Center for both gantry angles.
  2. Verify the average of the two values is within +/- 0.02 cm.
  3. If not, add the average value to the couch position IEC-Z value and repeat the measurements.
19. Review the 90 degree and 270 degree Profiler X-Axis.
  1. Verify the average of the two values is within +/- 0.2 cm.
  2. If not, add the average value to the couch position IEC-Y value and repeat the measurements.
20. Once both axes are within specification, continue below to deliver the six MLC fields.
21. Record the final couch positions. If the system must be restarted, the couch should be verified before continuing.

## Collect MLC Data

1.	On the ViewRay TPDS, select Head 1 under Beam Setup and Controls.
2.	Set Delivery Angle to 90 degrees.
3.	Under MLC Setup, set the following Strip 1 MLC positions: X1 = -12.5 cm, X2 = -7.5 cm, Y1 = -13.65 cm, Y2 = +13.65 cm.
4.	Click Set Shape to apply the MLC positions.
5.	Enter 30 seconds as the Beam-On Time. A screenshot of all Calibration settings is provided.
6.	Click Prepare Beam Setup.
7.	Click Enable Beam On.
8.	Press Beam On on the Treatment Control Panel.
9.	In the SNC Profiler software, click Start.
10.	When asked if the new measurement is continuous, click Yes.
11.	Wait for the beam to be delivered.
12.	Click Stop on the Profiler Software.
13.	Enter the Delivery Parameters and Save the File.
  1.	Click on the Setup tab.
  2.	Gantry Angle in the window that appears (Setup Tab), and
  3.	Set the SSD to 100 cm.
  4.	Uncheck Symmetric Collimators.
  5.	Enter the field size based on the X1/X2 and Y1/Y2 parameters above.
  6.	Click on the General tab.
  7.	Under Description, type Head #, where # is the head number (1 in this instance).
  8.	Click OK.
  9.	When asked to save the file, choose Multi-Frame type and save the results to _H1 G90 Strip1.prm_.
14.	Repeat measurements at the same head and gantry angle for the remaining strips, using the field sizes below.
15.	In the SNC IC Profiler software, After completing all six exposures, export the data to ASCII format by selecting Export > SNC ASCII.
  1.	In the message box that appears, verify the default settings are selected and specify a destination file.
16. Repeat the steps above for Head 2 and Head 3, both at 270 degrees.

## Analyze MLC Data

1. Execute the AnalyzeMLCProfiles.m MATLAB script.
2. Under Head 1, click Browse to load the SNC IC Profiler ASCII export for the first gantry angle.
3. When requested, select the Gantry angle.
4. Continue to load the remaining angles and heads.
5. Review the resulting profile comparisons and edge offset plots, as shown in the example.
  1. Verify that each profile looks as expected and that no data points (particularly those around the FWHM limits) appear distorted due to noise or measurement error.
  2. Verify that each X1 and X2 field edge differences are within +/- 2 mm for all six positions. The minimum and maximum deviations are listed in the statistics table at the bottom.
