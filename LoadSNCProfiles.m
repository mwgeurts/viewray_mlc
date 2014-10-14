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

% Run in try-catch to log error via Event.m
try
    
% Request the user to select the SNC IC Profiler measurements
Event('UI window opened to select file');
[name, path] = uigetfile('*.txt', ...
    'Select an SNC Exported MLC Check Measurement Set', handles.path);

% If a file was selected
if ~name == 0
    % Log start
    Event(['SNC file selected, beginning load of ', name]);
    tic;
    
    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % Update text box
    set(handles.([head,'file',file]), 'String', fullfile(path, name));
    
    % Check if an angle was selected
    if get(handles.([head,'angle',file]), 'Value') == 1
        % Log action
        Event('No angle was selected, prompting user via UI');
        
        % If not set, ask the user to select a gantry angle
        gantry = menu('Select the Gantry Angle:', '0', '90', '180', '270');
        
        % Update the gantry angle
        set(handles.([head,'angle',file]), 'Value', gantry + 1);
        
        % Clear temporary variable
        clear gantry;
    end
    Event(sprintf('Gantry angle set to %i (%i degrees)', ...
        get(handles.([head,'angle',file]), 'Value'), ...
            90*(get(handles.([head,'angle',file]), 'Value') - 2)));
    
    % Extract profiles
    [handles.([head,'profiles',file]), handles.([head,'FWHM',file]), ...
        handles.([head,'X1',file]), handles.([head,'X2',file])] ...
        = ParseSNCProfiles(fullfile(path, name), ...
        get(handles.([head,'angle',file]), 'Value'));
    
    % Select Reference Profile
    switch get(handles.([head,'angle',file]), 'Value')
        % 0 degrees
        case 2
            Event('Reference profiles set to AP');
            handles.([head,'refprofiles',file]) = handles.MCap;
            handles.([head,'refFWHM',file]) = handles.MCapFWHM;
            handles.([head,'refX1',file]) = handles.MCapX1;
            handles.([head,'refX2',file]) = handles.MCapX2;
            
        % 90 degrees
        case 3
            Event('Reference profiles set to AP');
            handles.([head,'refprofiles',file]) = handles.MCap;
            handles.([head,'refFWHM',file]) = handles.MCapFWHM;
            handles.([head,'refX1',file]) = handles.MCapX1;
            handles.([head,'refX2',file]) = handles.MCapX2;
          
        % 180 degrees
        case 4
            Event('Reference profiles set to PA (thru couch)');
            handles.([head,'refprofiles',file]) = handles.MCpatc;
            handles.([head,'refFWHM',file]) = handles.MCpatcFWHM;
            handles.([head,'refX1',file]) = handles.MCpatcX1;
            handles.([head,'refX2',file]) = handles.MCpatcX2;
           
        % 270 degrees
        case 5
            Event('Reference profiles set to PA (no couch)');
            handles.([head,'refprofiles',file]) = handles.MCpanc;
            handles.([head,'refFWHM',file]) = handles.MCpancFWHM;
            handles.([head,'refX1',file]) = handles.MCpancX1;
            handles.([head,'refX2',file]) = handles.MCpancX2;
    end
    
    % Initialize gamma structure
    handles.([head,'gamma',file]){1} = handles.([head,'profiles',file]){1};
    
    % Loop through each profile
    Event('Computing Gamma for each profile');
    for i = 1:length(handles.([head,'profiles',file])) - 1
        
        % Prepare CalcGamma inputs (which uses start/width/data format)
        target.start = handles.([head,'profiles',file]){1}(1);
        target.width = handles.([head,'profiles',file]){1}(2) - ...
            handles.([head,'profiles',file]){1}(1);
        target.data = squeeze(handles.([head,'profiles',file]){i+1}) / ...
            max(squeeze(handles.([head,'profiles',file]){i+1}));
        Event(sprintf(['Preparing Gamma target profile inputs (start', ...
            '= %0.3f mm, width = %0.3f mm)'], target.start, target.width));

        reference.start = ...
            handles.([head,'refprofiles',file]){i}.profile(1,1);
        reference.width = ...
            handles.([head,'refprofiles',file]){i}.profile(1,2) - ...
            handles.([head,'refprofiles',file]){i}.profile(1,1);
        reference.data = ...
            squeeze(handles.([head,'refprofiles',file]){i}.profile(2,:)) / ...
            max(squeeze(handles.([head,'refprofiles',file]){i}.profile(2,:)));
        Event(sprintf(['Preparing Gamma reference profile inputs (start', ...
            '= %0.3f mm, width = %0.3f mm)'], reference.start, reference.width));
        
        % Calculate 1-D GLOBAL gamma
        handles.([head,'gamma',file]){i+1} = ...
            CalcGamma(reference, target, handles.abs, handles.dta, 1);
        
        % Null gamma values < 80% max signal
        handles.([head,'gamma',file]){i+1} = ...
            handles.([head,'gamma',file]){i+1} .* ...
            ceil(target.data/max(target.data) - 0.8)';
        Event('Gamma values below 80% target profile threshold ignored');
    end
    
    % Clear temporary variables
    clear target reference;
    
    % Update statistics
    handles = UpdateMLCStatistics(handles, head);
end

% Clear temporary variables
clear name path;

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end
