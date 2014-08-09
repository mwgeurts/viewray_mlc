% AnalyzeMLCprofiles loads Monte Carlo treatment planning data from the
% ViewRay TPS and compares it to measured Sun Nuclear IC Profiler data.  To
% successfully process the data, six exposures must be acquired for a given
% head and gantry angle at the following MLC X1 and X2 positions (in cm):
%
%   X1  |   X2
% --------------
% -12.5 | -7.5
% -8.5  | -3.5
% -4.5  | +0.5
% -0.5  | +4.5
% +3.5  | +8.5
% +7.5  | +12.5
%
% When measuring data with IC Profiler, it is assumed that the profiler
% will be positioned with the electronics pointing toward IEC-X for 0 and
% 180 degree gantry angles, toward IEC+Z for 90 and 270 degrees. Therefore,
% for 0 and 90 degree gantry angles, the Monte Carlo data calculated
% through the front of the IC Profiler is used.  For 180 degrees, the Monte
% Carlo data calculated through the couch and back of the profiler is used.
% For 270 degrees, the data calculated through the back of the profiler
% (but without the couch) is used.
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2014 University of Wisconsin Board of Regents
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.

% Clear all data
clear;

% Request the user to select the SNC IC Profiler measurements
[name, path] = uigetfile('*.txt', ...
    'Select an SNC Exported MLC Check Measurement Set');
if name == 0
    error('No file was selected.');
end
measfile = fullfile(path, name);

% Request the user to note the head
head = menu('Select the Head:', 'Head 1', 'Head 2', 'Head 3');

% Request the user to note the gantry angle
gantry = menu('Select the Gantry Angle:', '0', '90', '180', '270');

% Declare the nominal X1/X2 values (in mm) for each exposure
nomX1 = [-125 -85 -45 -5 35 75];
nomX2 = [-75 -35 5 45 85 125];

%% Load AP Monte Carlo Files
% Declare the AP (through the front of the IC Profiler) Monte Carlo planar
% data files exported from the TPS
MCapfiles = {
    './Reference/AP-10_PlaneDose_Vertical_Point1.dcm'
    './Reference/AP-6_PlaneDose_Vertical_Point2.dcm'
    './Reference/AP-2_PlaneDose_Vertical_Point3.dcm'
    './Reference/AP+2_PlaneDose_Vertical_Point4.dcm'
    './Reference/AP+6_PlaneDose_Vertical_Point5.dcm'
    './Reference/AP+10_PlaneDose_Vertical_Point6.dcm'
};

% Initialize variables to store AP data
MCap = cell(length(MCapfiles),1);
MCapFWHM = zeros(1,length(MCapfiles));
MCapX1 = zeros(1,length(MCapfiles));
MCapX2 = zeros(1,length(MCapfiles));

% Loop through each reference file
for i = 1:length(MCapfiles)
    % Load DICOM data
    MCap{i}.info = dicominfo(MCapfiles{i});
    MCap{i}.width = MCap{i}.info.PixelSpacing;
    MCap{i}.start = [MCap{i}.info.ImagePositionPatient(3); ...
        MCap{i}.info.ImagePositionPatient(1)];
    MCap{i}.data = single(dicomread(MCapfiles{i}))*MCap{i}.info.DoseGridScaling;
    
    % Generate mesh
    [MCap{i}.meshX, MCap{i}.meshY]  = meshgrid(MCap{i}.start(2):MCap{i}.width(2):...
        MCap{i}.start(2)+MCap{i}.width(2)*(size(MCap{i}.data,2)-1), ...
        MCap{i}.start(1):MCap{i}.width(1):...
        MCap{i}.start(1)+MCap{i}.width(1)*(size(MCap{i}.data,1)-1));
    
    % Extract IEC-x axis data
    MCap{i}.profile(1,:) = MCap{i}.meshY(:,1);
    MCap{i}.profile(2,:) = interp2(MCap{i}.meshX, MCap{i}.meshY, ...
        single(MCap{i}.data), MCap{i}.profile(1,:), ...
        zeros(1,size(MCap{i}.profile,2)), '*linear');
    
    % Determine location and value of maximum
    [C, I] = max(MCap{i}.profile(2,:));
    
    % Search left side for half-maximum value
    for x = 1:I-1
        if MCap{i}.profile(2,x) == C/2
            MCapX1(i) = MCap{i}.profile(1,x);
            break;
        elseif MCap{i}.profile(2,x) < C/2 && MCap{i}.profile(2,x+1) > C/2
            MCapX1(i) = interp1(MCap{i}.profile(2,x:x+1), ...
                MCap{i}.profile(1,x:x+1), C/2, 'linear');
            break;
        end
    end
    
    % Search right side for half-maximum value
    for x = I:size(MCap{i}.profile,2)-1
        if MCap{i}.profile(2,x) == C/2
            MCapX2(i) = MCap{i}.profile(1,x);
            break;
        elseif MCap{i}.profile(2,x) > C/2 && MCap{i}.profile(2,x+1) < C/2
            MCapX2(i) = interp1(MCap{i}.profile(2,x:x+1), ...
                MCap{i}.profile(1,x:x+1), C/2, 'linear');
            break;
        end
    end   
    
    % Compute width
    MCapFWHM(i) = MCapX2(i) - MCapX1(i);
end

%% Load PA (no couch) Monte Carlo Files
% Declare the PA (through the back of the IC Profiler and jig but without
% the couch) Monte Carlo planar data files exported from the TPS
MCpancfiles = {
    './Reference/PA-10_NOCOUCH_PlaneDose_Vertical_Point1.dcm'
    './Reference/PA-6_NOCOUCH_PlaneDose_Vertical_Point2.dcm'
    './Reference/PA-2_NOCOUCH_PlaneDose_Vertical_Point3.dcm'
    './Reference/PA+2_NOCOUCH_PlaneDose_Vertical_Point4.dcm'
    './Reference/PA+6_NOCOUCH_PlaneDose_Vertical_Point5.dcm'
    './Reference/PA+10_NOCOUCH_PlaneDose_Vertical_Point6.dcm'
};

% Initialize variables to store PA no couch data
MCpanc = cell(length(MCpancfiles),1);
MCpancFWHM = zeros(1,length(MCpancfiles));
MCpancX1 = zeros(1,length(MCpancfiles));
MCpancX2 = zeros(1,length(MCpancfiles));

% Loop through each reference file
for i = 1:length(MCpancfiles)
    % Load DICOM data
    MCpanc{i}.info = dicominfo(MCpancfiles{i});
    MCpanc{i}.width = MCpanc{i}.info.PixelSpacing;
    MCpanc{i}.start = [MCpanc{i}.info.ImagePositionPatient(3); ...
        MCpanc{i}.info.ImagePositionPatient(1)];
    MCpanc{i}.data = single(dicomread(MCpancfiles{i}))*MCpanc{i}.info.DoseGridScaling;
    
    % Generate mesh
    [MCpanc{i}.meshX, MCpanc{i}.meshY]  = meshgrid(MCpanc{i}.start(2):MCpanc{i}.width(2):...
        MCpanc{i}.start(2)+MCpanc{i}.width(2)*(size(MCpanc{i}.data,2)-1), ...
        MCpanc{i}.start(1):MCpanc{i}.width(1):...
        MCpanc{i}.start(1)+MCpanc{i}.width(1)*(size(MCpanc{i}.data,1)-1));
    
    % Extract IEC-x axis data
    MCpanc{i}.profile(1,:) = MCpanc{i}.meshY(:,1);
    MCpanc{i}.profile(2,:) = interp2(MCpanc{i}.meshX, MCpanc{i}.meshY, ...
        single(MCpanc{i}.data), MCpanc{i}.profile(1,:), ...
        zeros(1,size(MCpanc{i}.profile,2)), '*linear');
    
    % Determine location and value of maximum
    [C, I] = max(MCpanc{i}.profile(2,:));
    
    % Search left side for half-maximum value
    for x = 1:I-1
        if MCpanc{i}.profile(2,x) == C/2
            MCpancX1(i) = MCpanc{i}.profile(1,x);
            break;
        elseif MCpanc{i}.profile(2,x) < C/2 && MCpanc{i}.profile(2,x+1) > C/2
            MCpancX1(i) = interp1(MCpanc{i}.profile(2,x:x+1), ...
                MCpanc{i}.profile(1,x:x+1), C/2, 'linear');
            break;
        end
    end
    
    % Search right side for half-maximum value
    for x = I:size(MCpanc{i}.profile,2)-1
        if MCpanc{i}.profile(2,x) == C/2
            MCpancX2(i) = MCpanc{i}.profile(1,x);
            break;
        elseif MCpanc{i}.profile(2,x) > C/2 && MCpanc{i}.profile(2,x+1) < C/2
            MCpancX2(i) = interp1(MCpanc{i}.profile(2,x:x+1), ...
                MCpanc{i}.profile(1,x:x+1), C/2, 'linear');
            break;
        end
    end   
    
    % Compute width
    MCpancFWHM(i) = MCpancX2(i) - MCpancX1(i);
end

%% Load PA (thru couch) Monte Carlo Files
% Declare the PA (through the back of the IC Profiler, jig, and couch) 
% Monte Carlo planar data files exported from the TPS
MCpatcfiles = {
    './Reference/PA-10_THRUCOUCH_PlaneDose_Vertical_Point1.dcm'
    './Reference/PA-6_THRUCOUCH_PlaneDose_Vertical_Point2.dcm'
    './Reference/PA-2_THRUCOUCH_PlaneDose_Vertical_Point3.dcm'
    './Reference/PA+2_THRUCOUCH_PlaneDose_Vertical_Point4.dcm'
    './Reference/PA+6_THRUCOUCH_PlaneDose_Vertical_Point5.dcm'
    './Reference/PA+10_THRUCOUCH_PlaneDose_Vertical_Point6.dcm'
};

% Initialize variables to store PA thru couch data
MCpatc = cell(length(MCpatcfiles),1);
MCpatcFWHM = zeros(1,length(MCpatcfiles));
MCpatcX1 = zeros(1,length(MCpatcfiles));
MCpatcX2 = zeros(1,length(MCpatcfiles));

% Loop through each reference file
for i = 1:length(MCpatcfiles)
    % Load DICOM data
    MCpatc{i}.info = dicominfo(MCpatcfiles{i});
    MCpatc{i}.width = MCpatc{i}.info.PixelSpacing;
    MCpatc{i}.start = [MCpatc{i}.info.ImagePositionPatient(3); ...
        MCpatc{i}.info.ImagePositionPatient(1)];
    MCpatc{i}.data = single(dicomread(MCpatcfiles{i}))*MCpatc{i}.info.DoseGridScaling;
    
    % Generate mesh
    [MCpatc{i}.meshX, MCpatc{i}.meshY]  = meshgrid(MCpatc{i}.start(2):MCpatc{i}.width(2):...
        MCpatc{i}.start(2)+MCpatc{i}.width(2)*(size(MCpatc{i}.data,2)-1), ...
        MCpatc{i}.start(1):MCpatc{i}.width(1):...
        MCpatc{i}.start(1)+MCpatc{i}.width(1)*(size(MCpatc{i}.data,1)-1));
    
    % Extract IEC-x axis data
    MCpatc{i}.profile(1,:) = MCpatc{i}.meshY(:,1);
    MCpatc{i}.profile(2,:) = interp2(MCpatc{i}.meshX, MCpatc{i}.meshY, ...
        single(MCpatc{i}.data), MCpatc{i}.profile(1,:), ...
        zeros(1,size(MCpatc{i}.profile,2)), '*linear');
    
    % Determine location and value of maximum
    [C, I] = max(MCpatc{i}.profile(2,:));
    
    % Search left side for half-maximum value
    for x = 1:I-1
        if MCpatc{i}.profile(2,x) == C/2
            MCpatcX1(i) = MCpatc{i}.profile(1,x);
            break;
        elseif MCpatc{i}.profile(2,x) < C/2 && MCpatc{i}.profile(2,x+1) > C/2
            MCpatcX1(i) = interp1(MCpatc{i}.profile(2,x:x+1), ...
                MCpatc{i}.profile(1,x:x+1), C/2, 'linear');
            break;
        end
    end
    
    % Search right side for half-maximum value
    for x = I:size(MCpatc{i}.profile,2)-1
        if MCpatc{i}.profile(2,x) == C/2
            MCpatcX2(i) = MCpatc{i}.profile(1,x);
            break;
        elseif MCpatc{i}.profile(2,x) > C/2 && MCpatc{i}.profile(2,x+1) < C/2
            MCpatcX2(i) = interp1(MCpatc{i}.profile(2,x:x+1), ...
                MCpatc{i}.profile(1,x:x+1), C/2, 'linear');
            break;
        end
    end   
    
    % Compute width
    MCpatcFWHM(i) = MCpatcX2(i) - MCpatcX1(i);
end

%% Load measured data
% Open a file handle to the measured data
fid = fopen(measfile, 'r');

% While the end-of-file has not been reached
while ~feof(fid)
    % Retrieve the next line in the file
    tline = fgetl(fid);
    
    % Search for the X Axis data
    C = regexp(tline, 'Detector ID	X Axis Position');
    
    % If found
    if size(C,1) > 0 
        % Extract all X axis positions (detector position and 6 measured
        % profiles)
        measX = textscan(fid, '%f %f %f %f %f %f %f');
    end
    
    % Search for the Y Axis data
    C = regexp(tline, 'Detector ID	Y Axis Position');
    
    % If found
    if size(C,1) > 0 
        % Extract all X axis positions (detector position and 6 measured
        % profiles)
        measY = textscan(fid, '%f %f %f %f %f %f %f');
        
        % Stop loading the file, as the data was found
        break;
    end
end

%% Process and compare each measured profile
% Initialize measured profile data
measX1 = zeros(1,6);
measX2 = zeros(1,6);
measFWHM = zeros(1,6);

% Initialize figure to display profiles
figure;
hold on;

% Loop through each profile
for i = 1:6
    % Determine which dataset to load based on angle
    if gantry == 1 % 0 degrees
        % Convert detector position to mm
        x = measY{1}*10;
        y = measY{i+1}/100;
        MCrefX1 = MCapX1;
        MCrefX2 = MCapX2;
        
        % Plot normalized data
        plot(MCap{i}.profile(1,:), ...
            MCap{i}.profile(2,:)/max(MCap{i}.profile(2,:)), 'blue');
    elseif gantry == 2 % 90 degrees
        % Convert detector position to mm
        x = measY{1}*10;
        y = measY{i+1}/100;
        MCrefX1 = MCapX1;
        MCrefX2 = MCapX2;
        
         % Plot normalized data
        plot(MCap{i}.profile(1,:), ...
            MCap{i}.profile(2,:)/max(MCap{i}.profile(2,:)), 'blue');
    elseif gantry == 3 % 180 degrees
        % Convert detector position to mm
        x = measY{1}*10;
        y = measY{i+1}/100;
        MCrefX1 = MCpatcX1;
        MCrefX2 = MCpatcX2;
        
         % Plot normalized data
        plot(MCpatc{i}.profile(1,:), ...
            MCpatc{i}.profile(2,:)/max(MCpatc{i}.profile(2,:)), 'blue');
    elseif gantry == 4 % 270 degrees
        % Convert detector position to mm
        x = measY{1}*10;
        y = measY{i+1}/100;
        MCrefX1 = MCpancX1;
        MCrefX2 = MCpancX2;
        
         % Plot normalized data
        plot(MCpanc{i}.profile(1,:), ...
            MCpanc{i}.profile(2,:)/max(MCpanc{i}.profile(2,:)), 'blue');
    end
    
    % Determine location and value of maximum
    [C, I] = max(y);
    
    % Search left side for half-maximum value
    for j = 1:I-1
        if y(j) == C/2
            measX1(i) = y(j);
            break;
        elseif y(j) < C/2 && y(j+1) > C/2
            measX1(i) = interp1(y(j:j+1), x(j:j+1), C/2, 'linear');
            break;
        end
    end
    
    % Search right side for half-maximum value
    for j = I:size(y,1)-1
        if y(j) == C/2
            measX2(i) = y(j);
            break;
        elseif y(j) > C/2 && y(j+1) < C/2
            measX2(i) = interp1(y(j:j+1), x(j:j+1), C/2, 'linear');
            break;
        end
    end   
    
    % Compute width
    measFWHM(i) = measX2(i) - measX1(i);
    
    % Plot data
    plot(x, y/max(y), 'red');
end

hold off;

% Title and label profile plots
title(sprintf('Head %i Gantry %i Monte Carlo (Blue) vs. Measured (Red) MLC Profiles', head, (gantry-1)*90));
ylabel('Normalized Dose');
ylim([0 1.05]);
xlabel('MLC X Position (mm)');
xlim([-150 150]);
grid on;

% Sort measured profiles
measX1 = sort(measX1);
measX2 = sort(measX2);

% Compute differences
nomDiffX1 = measX1 - nomX1;
nomDiffX2 = measX2 - nomX2;

MCDiffX1 = measX1 - MCapX1;
MCDiffX2 = measX2 - MCapX2;

% Print average and standard deviations
fprintf('Average X1 Measured to MC difference = %0.2f mm +/- %0.2f mm\n', mean(MCDiffX1), std(MCDiffX1));
fprintf('Average X2 Measured to MC difference = %0.2f mm +/- %0.2f mm\n\n', mean(MCDiffX2), std(MCDiffX2));

fprintf('Average X1 Measured to Nominal difference = %0.2f mm +/- %0.2f mm\n', mean(nomDiffX1), std(nomDiffX1));
fprintf('Average X2 Measured to Nominal difference = %0.2f mm +/- %0.2f mm\n', mean(nomDiffX2), std(nomDiffX2));

% Plot Monte Carlo based errors
figure;
bar([MCDiffX1; MCDiffX2]', 'grouped');
legend('X1 (Measured to MC)', 'X2 (Measured to MC)');
xlabel('Profile');
set(gca,'XTickLabel',{'-10cm', '-6cm', '-2cm', '2cm', '6cm', '10cm'});
ylabel('Difference (mm)');
ylim([-3 3]);
title(sprintf('Head %i Gantry %i FWHM Field Edge Difference', head, (gantry-1)*90));
grid on;
