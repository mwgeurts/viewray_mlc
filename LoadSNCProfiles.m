function handles = LoadSNCProfiles(handles, head, file)
% LoadSNCProfiles is called by AnalyzeMLCProfiles when the user selects a
% Browse button to read SNC IC Profiler ASCII exported data.  The files
% themselves are parsed using ParseSNCProfiles.  This function sets the
% selected file, checks if the user has selected a gantry angle, and if
% not, asks them to specify the gantry angle.  Based on the gantry angle
% chosen, the function assigns a reference data set (see
% LoadReferenceProfiles for more information).
%
% This function requires the GUI handles structure, a string indicating the
% head number (h1, h2, or h3), and a string indicating the file number 
% (1,2,3,4).  It returns a modified GUI handles structure.
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

% Request the user to select the SNC IC Profiler measurements
[name, path] = uigetfile('*.txt', ...
    'Select an SNC Exported MLC Check Measurement Set', handles.path);

% If a file was selected
if ~name == 0
    % Update default path
    handles.path = path;
    
    % Update text box
    set(handles.([head,'file',file]), 'String', fullfile(path, name));
    
    % Check if an angle was selected
    if get(handles.([head,'angle',file]), 'Value') == 1
        % If not set, ask the user to select a gantry angle
        gantry = menu('Select the Gantry Angle:', '0', '90', '180', '270');
        
        % Update the gantry angle
        set(handles.([head,'angle',file]), 'Value', gantry + 1);
        
        % Clear temporary variable
        clear gantry;
    end
    
    % Extract profiles
    [handles.([head,'profiles',file]), handles.([head,'FWHM',file]), ...
        handles.([head,'X1',file]), handles.([head,'X2',file])] ...
        = ParseSNCProfiles(fullfile(path, name), ...
        get(handles.([head,'angle',file]), 'Value'));
    
    % Select Reference Profile
    switch get(handles.h1angle1, 'Value')
        % 0 degrees
        case 2
            handles.([head,'refprofiles',file]) = handles.MCap;
            handles.([head,'refFWHM',file]) = handles.MCapFWHM;
            handles.([head,'refX1',file]) = handles.MCapX1;
            handles.([head,'refX2',file]) = handles.MCapX2;
            
        % 90 degrees
        case 3
            handles.([head,'refprofiles',file]) = handles.MCap;
            handles.([head,'refFWHM',file]) = handles.MCapFWHM;
            handles.([head,'refX1',file]) = handles.MCapX1;
            handles.([head,'refX2',file]) = handles.MCapX2;
          
        % 180 degrees
        case 4
            handles.([head,'refprofiles',file]) = handles.MCpatc;
            handles.([head,'refFWHM',file]) = handles.MCpatcFWHM;
            handles.([head,'refX1',file]) = handles.MCpatcX1;
            handles.([head,'refX2',file]) = handles.MCpatcX2;
           
        % 270 degrees
        case 5
            handles.([head,'refprofiles',file]) = handles.MCpanc;
            handles.([head,'refFWHM',file]) = handles.MCpancFWHM;
            handles.([head,'refX1',file]) = handles.MCpancX1;
            handles.([head,'refX2',file]) = handles.MCpancX2;
    end
    
    % Compute gamma (placeholder for future releases)
    %handles.h1gamma1 = ...
    %    CalcGamma(handles.h1profiles1, handles.h1refprofiles1);
    
    % Update statistics
    handles = UpdateMLCStatistics(handles, head);
end

% Clear temporary variables
clear name path;
