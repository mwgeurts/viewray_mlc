ViewRay MLC Position Check
===========

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2014, University of Wisconsin Board of Regents

The ViewRay MLC Position Check loads Monte Carlo treatment planning data from the ViewRay&trade; Treatment Planning System and compares it to measured Sun Nuclear IC Profiler&trade; data to evaluate the positioning accuracy of each MLC bank.  To successfully process the data, six exposures must be acquired for a given head and gantry angle at the following MLC positions (in cm):

| Strip   |	X1 (cm) |	 X2 (cm) |  Y1 (cm) |	 Y2 (cm) |
----------|---------|----------|----------|----------|
| Strip 1	|  -12.5  |   -7.5 	 |  -13.65	|  +13.65  |
| Strip 2	|  -8.5	  |   -3.5	 |  -13.65	|  +13.65  |
| Strip 3	|  -4.5	  |   +0.5 	 |  -13.65  |	 +13.65  |
| Strip 4	|  -0.5   |	  +4.5   |	-13.65  |	 +13.65  |
| Strip 5 |	 +3.5   |	  +8.5	 |  -13.65  |	 +13.65  |
| Strip 6 |	 +7.5	  |  +12.5	 |  -13.65	|  +13.65  |

When measuring data with IC Profiler, it is assumed that the profiler will be positioned with the electronics pointing toward IEC-X for 0 and 180 degree gantry angles, toward IEC+Z for 90 and 270 degrees. Therefore, for 0 and 90 degree gantry angles, the Monte Carlo data calculated through the front of the IC Profiler is used.  For 180 degrees, the Monte Carlo data calculated through the couch and back of the profiler is used. For 270 degrees, the data calculated through the back of the profiler (but without the couch) is used.

## Contents

* [Installation and Use](README.md#installation-and-use)
* [Measurement Instructions](README.md#measurement-instructions)
  * [Set up the IC Profiler](README.md#set-up-the-ic-profiler)  
  * [Orient the IC Profiler in the Sagittal Position](README.md#orient-the-ic-profiler-in-the-sagittal-position)
  * [Collect MLC Data](README.md#Collect-mlc-data)
  * [Analyze MLC Data](README.md#Analyze-mlc-data)
* [Gamma Computation Methods](README.md#Gamma-computation-methods)
* [Compatibility and Requirements](README.md#compatibility-and-requirements)

## Installation and Use

To install this application, copy all MATLAB .m and .fig and the Reference folder contents into a directory with read/write access and then copy the [CalcGamma.m submodule from the gamma repository](https://github.com/mwgeurts/gamma) into the gamma subfolder.  If using git, execute `git clone --recursive https://github.com/mwgeurts/viewray_mlc`.

To run this application, navigate to the installation path and execute `AnalyzeMLCProfiles` in MATLAB. Global configuration variables such as the default brose path can be modified by changing the values in `AnalyzeMLCProfiles_OpeningFcn` prior to execution.  A log file will automatically be created in the same directory and can be used for troubleshooting.  For instructions on acquiring the input data, see [Measurement Instructions](README.md#measurement-instructions). For information about software version and configuration pre-requisities, see [Compatibility and Requirements](README.md#compatibility-and-requirements).

## Measurement Instructions

The following steps illustrate how to acquire and process 90 and 270 degree measurements.  

### Set up the IC Profiler

1. Attach the SNC IC Profiler to the IC Profiler jig
2. Connect the IC Profiler to the Physics Workstation using the designated cable
3. Launch the SNC Profiler software on the Physics Workstation
4. Select the most recent Dose calibration from the dropdown box
5. Select the most recent array Calibration from the dropdown box
6. Verify the mode is continuous by clicking the Control menu

### Orient the IC Profiler in the Sagittal Position

1. Place the SNC Profiler jig on the couch at virtual isocenter and orient the jig in the Sagittal orientation, as shown
  1. The top of the profiler will be facing the IEC+X axis
  2. The electronics will be on the facing upwards (IEC+Y axis)
  3. Place an aluminum level on the front face of the IC Profiler as shown
  4. Verify the profiler is parallel with the IEC Sagittal plane
  5. Use the leveling feet on the jig to adjust if necessary
  6. Laterally adjust the jig until the overhead IEC X laser is aligned to the front face of the IC Profiler
  7. Record the current couch position
  8. Use the Couch Control Panel to move the couch and IC Profiler +0.9 cm in the IEC+X direction
  9. The detector plane of the IC Profiler should now be at isocenter
  10. Vertically and Longitudinally align the IC Profiler to the crosshairs using the wall IEC Y and IEC Z laser
  11. Press the ENABLE and ISO buttons on the Couch Control Panel to move the couch from virtual to mechanical isocenter
2. On the ViewRay TPDS, select Tools > QA Procedure and select the Calibration tab
3. Select an arbitrary phantom and click Load Phantom
4. Under Beam Setup and Controls, select Head 3
5. Set Delivery Angle to 90 degrees
6. Under MLC Setup, set the following MLC positions: X1/Y1 = -5.25 cm, X2/Y2 = +5.25 cm
7. Click Set Shape to apply the MLC positions
8. Enter 30 seconds as the Beam-On Time
9. Click Prepare Beam Setup
10. Click Enable Beam On
11. Press Beam On on the Treatment Control Panel
12. In the SNC Profiler software, click Start
13. When asked if the new measurement is continuous, click Yes
14. Wait for the beam to be delivered
15. Click Stop on the Profiler Software
16. Enter the Delivery Parameters and Save the File
  1. Click on the Setup tab
  2. Enter the gantry angle
  3. Set the SSD to 100 cm
  4. Check Symmetric Collimators
  5. Enter the field size as 10.5 cm x 10.5 cm
  6. Click on the General tab
  7. Under Description, type Head #, where # is the head number (3 in this instance)
  8. Click OK
  9. When asked to save the file, choose Multi-Frame type and save the results to _H3 G90 10p5.prm_
17. Move the Gantry to 270 degrees and repeat the exposure, saving the results to _H3G270 10p5.prm_
18. Review the 90 degree and 270 degree Profiler Y-Axis
  1. Calculate the average Beam Center for both gantry angles
  2. Verify the average of the two values is within +/- 0.02 cm
  3. If not, add the average value to the couch position IEC-Z value and repeat the measurements
19. Review the 90 degree and 270 degree Profiler X-Axis
  1. Verify the average of the two values is within +/- 0.2 cm
  2. If not, add the average value to the couch position IEC-Y value and repeat the measurements
20. Once both axes are within specification, continue below to deliver the six MLC fields
21. Record the final couch positions. If the system must be restarted, the couch should be verified before continuing

### Collect MLC Data

1.	On the ViewRay TPDS, select Head 1 under Beam Setup and Controls
2.	Set Delivery Angle to 90 degrees
3.	Under MLC Setup, set the following Strip 1 MLC positions: X1 = -12.5 cm, X2 = -7.5 cm, Y1 = -13.65 cm, Y2 = +13.65 cm
4.	Click Set Shape to apply the MLC positions
5.	Enter 30 seconds as the Beam-On Time. A screenshot of all Calibration settings is provided
6.	Click Prepare Beam Setup
7.	Click Enable Beam On
8.	Press Beam On on the Treatment Control Panel
9.	In the SNC Profiler software, click Start
10.	When asked if the new measurement is continuous, click Yes
11.	Wait for the beam to be delivered
12.	Click Stop on the Profiler Software
13.	Enter the Delivery Parameters and Save the File
  1.	Click on the Setup tab
  2.	Gantry Angle in the window that appears (Setup Tab)
  3.	Set the SSD to 100 cm
  4.	Uncheck Symmetric Collimators
  5.	Enter the field size based on the X1/X2 and Y1/Y2 parameters above
  6.	Click on the General tab
  7.	Under Description, type Head #, where # is the head number (1 in this instance)
  8.	Click OK
  9.	When asked to save the file, choose Multi-Frame type and save the results to _H1 G90 Strip1.prm_
14.	Repeat measurements at the same head and gantry angle for the remaining strips, using the field sizes in the above table
15.	In the SNC IC Profiler software, after completing all six exposures, export the data to ASCII format by selecting Export > SNC ASCII
  1.	In the message box that appears, verify the default settings are selected and specify a destination file
16. Repeat the steps above for Head 2 and Head 3, both at 270 degrees

### Analyze MLC Data

1. Execute the AnalyzeMLCProfiles.m MATLAB script
2. Under Head 1, click Browse to load the SNC IC Profiler ASCII export for the first gantry angle
3. When requested, select the Gantry angle
4. Continue to load the remaining angles and heads
5. Review the resulting profile comparisons and edge offset plots, as shown in the example
  1. Verify that each profile looks as expected and that no data points (particularly those around the FWHM limits) appear distorted due to noise or measurement error
  2. Verify that each X1 and X2 field edge differences are within +/- 2 mm for all six positions
  3. The minimum and maximum deviations are listed in the statistics table at the bottom

## Gamma Computation Methods

The Gamma analysis is performed based on the formalism presented by D. A. Low et. al., [A technique for the quantitative evaluation of dose distributions.](http://www.ncbi.nlm.nih.gov/pubmed/9608475), Med Phys. 1998 May; 25(5): 656-61.  In this formalism, the Gamma quality index *&gamma;* is defined as follows for each point along the measured profile *Rm* given the reference profile *Rc*:

*&gamma; = min{&Gamma;(Rm,Rc}&forall;{Rc}*

where:

*&Gamma; = &radic; (r^2(Rm,Rc)/&Delta;dM^2 + &delta;^2(Rm,Rc)/&Delta;DM^2)*,

*r(Rm,Rc) = | Rc - Rm |*,

*&delta;(Rm,Rc) = Dc(Rc) - Dm(Rm)*,

*Dc(Rc)* and *Dm(Rm)* represent the reference and measured signal at each *Rc* and *Rm*, respectively, and

*&Delta;dM* and *&Delta;DM* represent the absolute and Distance To Agreement Gamma criterion (by default 2%/1mm), respectively.  

The absolute criterion is typically given in percent and can refer to a percent of the maximum dose (commonly called the global method) or a percentage of the voxel *Rm* being evaluated (commonly called the local method).  The application is capable of computing gamma using either approach, and can be set when calling CalcGamma.m by passing a boolean value of 1 (for local) or 0 (for global).  By default, the global method (0) is used.

The computation applied in the tool is the 1D algorithm, in that the distance to agreement criterion is evaluated only along the dimension of the reference profile when determining *min{&Gamma;(Rm,Rc}&forall;{Rc}*. To accomplish this, the reference profile is shifted relative to the measured profile using linear 1D CUDA (when available) interpolation.  For each shift, *&Gamma;(Rm,Rc}* is computed, and the minimum value *&gamma;* is determined.  To improve computation efficiency, the computation space *&forall;{Rc}* is limited to twice the distance to agreement parameter.  Thus, the maximum "real" Gamma index returned by the application is 2.


## Compatibility and Requirements

This tool has been tested with ViewRay version 3.5 treatment software and Sun Nuclear IC Profiler software version 3.3.1.31111 on MATLAB 8.3 and 8.4.  The Parallel Computing toolbox (version 6.4 and 6.5 tested) and a CUDA-compatible GPU are required to run GPU based interpolation (CPU interpolation is automatically supported if not present).
