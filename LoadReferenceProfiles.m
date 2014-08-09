function handles = LoadReferenceProfiles(handles)
% LoadReferenceProfiles is called by AnalyzeMLCProfiles to read in the TPS
% calculated data and extract IEC X profiles for comparison to SNC IC 
% Profiler profiles.  The GUI structure handles (acquired using guidata) is
% passed as an input variable, is appended with the reference profiles, and
% is returned by this function.
%
% There are three sets of profiles returned: AP profiles, which have been
% computed as if the profiler was irradiated through the front face of the
% detector; PA (no couch) profiles, which have been calculated through the
% back of the Profiler and jig but without couch attenuation, and PA (thru
% couch) profiles, which have been computed considering couch attenuation.
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

%% Load AP Monte Carlo Files
% Declare the AP (through the front of the IC Profiler) Monte Carlo planar
% data files exported from the TPS
handles.MCapfiles = {
    './Reference/AP-10_PlaneDose_Vertical_Point1.dcm'
    './Reference/AP-6_PlaneDose_Vertical_Point2.dcm'
    './Reference/AP-2_PlaneDose_Vertical_Point3.dcm'
    './Reference/AP+2_PlaneDose_Vertical_Point4.dcm'
    './Reference/AP+6_PlaneDose_Vertical_Point5.dcm'
    './Reference/AP+10_PlaneDose_Vertical_Point6.dcm'
};

% Initialize variables to store AP data
handles.MCap = cell(length(handles.MCapfiles),1);
handles.MCapFWHM = zeros(1,length(handles.MCapfiles));
handles.MCapX1 = zeros(1,length(handles.MCapfiles));
handles.MCapX2 = zeros(1,length(handles.MCapfiles));

% Loop through each reference file
for i = 1:length(handles.MCapfiles)
    % Load DICOM data
    handles.MCap{i}.info = dicominfo(handles.MCapfiles{i});
    handles.MCap{i}.width = handles.MCap{i}.info.PixelSpacing;
    handles.MCap{i}.start = [handles.MCap{i}.info.ImagePositionPatient(3); ...
        handles.MCap{i}.info.ImagePositionPatient(1)];
    handles.MCap{i}.data = single(dicomread(handles.MCapfiles{i}))*handles.MCap{i}.info.DoseGridScaling;
    
    % Generate mesh
    [handles.MCap{i}.meshX, handles.MCap{i}.meshY]  = ...
        meshgrid(handles.MCap{i}.start(2):handles.MCap{i}.width(2):...
        handles.MCap{i}.start(2)+handles.MCap{i}.width(2)*(size(handles.MCap{i}.data,2)-1), ...
        handles.MCap{i}.start(1):handles.MCap{i}.width(1):...
        handles.MCap{i}.start(1)+handles.MCap{i}.width(1)*(size(handles.MCap{i}.data,1)-1));
    
    % Extract IEC-x axis data
    handles.MCap{i}.profile(1,:) = handles.MCap{i}.meshY(:,1);
    handles.MCap{i}.profile(2,:) = interp2(handles.MCap{i}.meshX, handles.MCap{i}.meshY, ...
        single(handles.MCap{i}.data), handles.MCap{i}.profile(1,:), ...
        zeros(1,size(handles.MCap{i}.profile,2)), '*linear');
    
    % Determine location and value of maximum
    [C, I] = max(handles.MCap{i}.profile(2,:));
    
    % Search left side for half-maximum value
    for x = 1:I-1
        if handles.MCap{i}.profile(2,x) == C/2
            handles.MCapX1(i) = handles.MCap{i}.profile(1,x);
            break;
        elseif handles.MCap{i}.profile(2,x) < C/2 && handles.MCap{i}.profile(2,x+1) > C/2
            handles.MCapX1(i) = interp1(handles.MCap{i}.profile(2,x:x+1), ...
                handles.MCap{i}.profile(1,x:x+1), C/2, 'linear');
            break;
        end
    end
    
    % Search right side for half-maximum value
    for x = I:size(handles.MCap{i}.profile,2)-1
        if handles.MCap{i}.profile(2,x) == C/2
            handles.MCapX2(i) = handles.MCap{i}.profile(1,x);
            break;
        elseif handles.MCap{i}.profile(2,x) > C/2 && handles.MCap{i}.profile(2,x+1) < C/2
            handles.MCapX2(i) = interp1(handles.MCap{i}.profile(2,x:x+1), ...
                handles.MCap{i}.profile(1,x:x+1), C/2, 'linear');
            break;
        end
    end   
    
    % Compute width
    handles.MCapFWHM(i) = handles.MCapX2(i) - handles.MCapX1(i);
end

%% Load PA (no couch) Monte Carlo Files
% Declare the PA (through the back of the IC Profiler and jig but without
% the couch) Monte Carlo planar data files exported from the TPS
handles.MCpancfiles = {
    './Reference/PA-10_NOCOUCH_PlaneDose_Vertical_Point1.dcm'
    './Reference/PA-6_NOCOUCH_PlaneDose_Vertical_Point2.dcm'
    './Reference/PA-2_NOCOUCH_PlaneDose_Vertical_Point3.dcm'
    './Reference/PA+2_NOCOUCH_PlaneDose_Vertical_Point4.dcm'
    './Reference/PA+6_NOCOUCH_PlaneDose_Vertical_Point5.dcm'
    './Reference/PA+10_NOCOUCH_PlaneDose_Vertical_Point6.dcm'
};

% Initialize variables to store PA no couch data
handles.MCpanc = cell(length(handles.MCpancfiles),1);
handles.MCpancFWHM = zeros(1,length(handles.MCpancfiles));
handles.MCpancX1 = zeros(1,length(handles.MCpancfiles));
handles.MCpancX2 = zeros(1,length(handles.MCpancfiles));

% Loop through each reference file
for i = 1:length(handles.MCpancfiles)
    % Load DICOM data
    handles.MCpanc{i}.info = dicominfo(handles.MCpancfiles{i});
    handles.MCpanc{i}.width = handles.MCpanc{i}.info.PixelSpacing;
    handles.MCpanc{i}.start = [handles.MCpanc{i}.info.ImagePositionPatient(3); ...
        handles.MCpanc{i}.info.ImagePositionPatient(1)];
    handles.MCpanc{i}.data = single(dicomread(handles.MCpancfiles{i}))*handles.MCpanc{i}.info.DoseGridScaling;
    
    % Generate mesh
    [handles.MCpanc{i}.meshX, handles.MCpanc{i}.meshY]  = meshgrid(handles.MCpanc{i}.start(2):handles.MCpanc{i}.width(2):...
        handles.MCpanc{i}.start(2)+handles.MCpanc{i}.width(2)*(size(handles.MCpanc{i}.data,2)-1), ...
        handles.MCpanc{i}.start(1):handles.MCpanc{i}.width(1):...
        handles.MCpanc{i}.start(1)+handles.MCpanc{i}.width(1)*(size(handles.MCpanc{i}.data,1)-1));
    
    % Extract IEC-x axis data
    handles.MCpanc{i}.profile(1,:) = handles.MCpanc{i}.meshY(:,1);
    handles.MCpanc{i}.profile(2,:) = interp2(handles.MCpanc{i}.meshX, handles.MCpanc{i}.meshY, ...
        single(handles.MCpanc{i}.data), handles.MCpanc{i}.profile(1,:), ...
        zeros(1,size(handles.MCpanc{i}.profile,2)), '*linear');
    
    % Determine location and value of maximum
    [C, I] = max(handles.MCpanc{i}.profile(2,:));
    
    % Search left side for half-maximum value
    for x = 1:I-1
        if handles.MCpanc{i}.profile(2,x) == C/2
            handles.MCpancX1(i) = handles.MCpanc{i}.profile(1,x);
            break;
        elseif handles.MCpanc{i}.profile(2,x) < C/2 && handles.MCpanc{i}.profile(2,x+1) > C/2
            handles.MCpancX1(i) = interp1(handles.MCpanc{i}.profile(2,x:x+1), ...
                handles.MCpanc{i}.profile(1,x:x+1), C/2, 'linear');
            break;
        end
    end
    
    % Search right side for half-maximum value
    for x = I:size(handles.MCpanc{i}.profile,2)-1
        if handles.MCpanc{i}.profile(2,x) == C/2
            handles.MCpancX2(i) = handles.MCpanc{i}.profile(1,x);
            break;
        elseif handles.MCpanc{i}.profile(2,x) > C/2 && handles.MCpanc{i}.profile(2,x+1) < C/2
            handles.MCpancX2(i) = interp1(handles.MCpanc{i}.profile(2,x:x+1), ...
                handles.MCpanc{i}.profile(1,x:x+1), C/2, 'linear');
            break;
        end
    end   
    
    % Compute width
    handles.MCpancFWHM(i) = handles.MCpancX2(i) - handles.MCpancX1(i);
end

%% Load PA (thru couch) Monte Carlo Files
% Declare the PA (through the back of the IC Profiler, jig, and couch) 
% Monte Carlo planar data files exported from the TPS
handles.MCpatcfiles = {
    './Reference/PA-10_THRUCOUCH_PlaneDose_Vertical_Point1.dcm'
    './Reference/PA-6_THRUCOUCH_PlaneDose_Vertical_Point2.dcm'
    './Reference/PA-2_THRUCOUCH_PlaneDose_Vertical_Point3.dcm'
    './Reference/PA+2_THRUCOUCH_PlaneDose_Vertical_Point4.dcm'
    './Reference/PA+6_THRUCOUCH_PlaneDose_Vertical_Point5.dcm'
    './Reference/PA+10_THRUCOUCH_PlaneDose_Vertical_Point6.dcm'
};

% Initialize variables to store PA thru couch data
handles.MCpatc = cell(length(handles.MCpatcfiles),1);
handles.MCpatcFWHM = zeros(1,length(handles.MCpatcfiles));
handles.MCpatcX1 = zeros(1,length(handles.MCpatcfiles));
handles.MCpatcX2 = zeros(1,length(handles.MCpatcfiles));

% Loop through each reference file
for i = 1:length(handles.MCpatcfiles)
    % Load DICOM data
    handles.MCpatc{i}.info = dicominfo(handles.MCpatcfiles{i});
    handles.MCpatc{i}.width = handles.MCpatc{i}.info.PixelSpacing;
    handles.MCpatc{i}.start = [handles.MCpatc{i}.info.ImagePositionPatient(3); ...
        handles.MCpatc{i}.info.ImagePositionPatient(1)];
    handles.MCpatc{i}.data = single(dicomread(handles.MCpatcfiles{i}))*handles.MCpatc{i}.info.DoseGridScaling;
    
    % Generate mesh
    [handles.MCpatc{i}.meshX, handles.MCpatc{i}.meshY]  = meshgrid(handles.MCpatc{i}.start(2):handles.MCpatc{i}.width(2):...
        handles.MCpatc{i}.start(2)+handles.MCpatc{i}.width(2)*(size(handles.MCpatc{i}.data,2)-1), ...
        handles.MCpatc{i}.start(1):handles.MCpatc{i}.width(1):...
        handles.MCpatc{i}.start(1)+handles.MCpatc{i}.width(1)*(size(handles.MCpatc{i}.data,1)-1));
    
    % Extract IEC-x axis data
    handles.MCpatc{i}.profile(1,:) = handles.MCpatc{i}.meshY(:,1);
    handles.MCpatc{i}.profile(2,:) = interp2(handles.MCpatc{i}.meshX, handles.MCpatc{i}.meshY, ...
        single(handles.MCpatc{i}.data), handles.MCpatc{i}.profile(1,:), ...
        zeros(1,size(handles.MCpatc{i}.profile,2)), '*linear');
    
    % Determine location and value of maximum
    [C, I] = max(handles.MCpatc{i}.profile(2,:));
    
    % Search left side for half-maximum value
    for x = 1:I-1
        if handles.MCpatc{i}.profile(2,x) == C/2
            handles.MCpatcX1(i) = handles.MCpatc{i}.profile(1,x);
            break;
        elseif handles.MCpatc{i}.profile(2,x) < C/2 && handles.MCpatc{i}.profile(2,x+1) > C/2
            handles.MCpatcX1(i) = interp1(handles.MCpatc{i}.profile(2,x:x+1), ...
                handles.MCpatc{i}.profile(1,x:x+1), C/2, 'linear');
            break;
        end
    end
    
    % Search right side for half-maximum value
    for x = I:size(handles.MCpatc{i}.profile,2)-1
        if handles.MCpatc{i}.profile(2,x) == C/2
            handles.MCpatcX2(i) = handles.MCpatc{i}.profile(1,x);
            break;
        elseif handles.MCpatc{i}.profile(2,x) > C/2 && handles.MCpatc{i}.profile(2,x+1) < C/2
            handles.MCpatcX2(i) = interp1(handles.MCpatc{i}.profile(2,x:x+1), ...
                handles.MCpatc{i}.profile(1,x:x+1), C/2, 'linear');
            break;
        end
    end   
    
    % Compute width
    handles.MCpatcFWHM(i) = handles.MCpatcX2(i) - handles.MCpatcX1(i);
end
