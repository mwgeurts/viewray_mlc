function handles = BrowseCallback(handles, head, file)
% BrowseCallback is called by AnalyzeMLCProfiles when the user selects a
% Browse button to read SNC IC Profiler data.  The files themselves are 
% parsed using the snc_extract submodule. The first input argument is the 
% guidata handles structure, while the second and third are strings 
% indicating which head and file number to load. This function returns a 
% modified handles structure upon successful completion.
%
% This function sets the selected file, checks if the user has selected a 
% gantry angle, and if not, asks them to specify the gantry angle.  Based 
% on the gantry angle chosen, this function assigns a reference data set.
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2015 University of Wisconsin Board of Regents
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

% Log event
Event([head, ' angle ', file, ' browse button selected']);

% Request the user to select the SNC Profiler ASCII or PRM file
Event('UI window opened to select file');
[name, path] = uigetfile({'*.txt', 'ASCII file export'; '*.prm', ...
    'Profiler Movie File'}, 'Select SNC Profiler data', handles.path, ...
    'MultiSelect', 'on');

% If a file was selected
if iscell(name) || sum(name ~= 0)
    
    % Start timer
    t = tic;

    % If not cell array, cast as one
    if ~iscell(name)
    
        % Update text box with file name
        set(handles.([head,'file',file]), 'String', fullfile(path, name));
        
        % Store filenames
        handles.([head,'names',file]) = cell(1);
        handles.([head,'names',file]){1} = name;
    else
    
        % Update text box with first file
        set(handles.([head,'file',file]), 'String', ...
            'Multiple files selected');
        
        % Store filenames
        handles.([head,'names',file]) = name;
    end
    
    % Log names
    Event([strjoin(handles.([head,'names',file]), ' selected\n'), ...
        ' selected']);
    
    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
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
    
    % Log gantry angle
    Event(sprintf('Gantry angle set to %i (%i degrees)', ...
        get(handles.([head,'angle',file]), 'Value'), ...
        90*(get(handles.([head,'angle',file]), 'Value') - 2)));
  
    % If the user selected ASCII data
    if ~isempty(regexpi(handles.([head,'names',file]){1}, '.txt$'))

        % If multiple profiles were selected, throw an error
        if length(handles.([head,'names',file])) > 1
            Event('Only one ASCII file can be processed at once. Load ', ...
                'all files and export as a single file before proceeding.', ...
                'ERROR');
        end
        
        % Load Profiler ASCII data
        data = ParseSNCtxt(handles.path, handles.([head,'names',file]){1});
        handles.sncversion = data.version{1};
        handles.collector = data.dmodel{1};
        handles.serial = data.dserial{1};
        
    % Otherwise, assume files are PRM
    elseif ~isempty(regexpi(handles.([head,'names',file]){1}, '.prm$'))
        
        % Loop through input files
        for i = 1:length(handles.([head,'names',file]))
            
            % If file is not a PRM file
            if isempty(regexpi(handles.([head,'names',file]){i}, '.prm$'))
                Event('All input files must be the same type', 'ERROR');
            end
        end
        
        % Load Profiler PRM data
        data = ParseSNCprm(handles.path, handles.([head,'names',file]));
        handles.sncversion = data.version;
        handles.collector = data.dmodel;
        handles.serial = data.dserial;
    
    % Otherwise, unknown data was passed to function
    else
        
        % Throw an error
        Event('An unknown file format was selected', 'ERROR');
    end
    
    % Select reference data
    switch get(handles.([head,'angle',file]), 'Value')
        
        % 0 degrees
        case 2
            Event('Reference profiles set to AP');
            refdata = handles.APreferences;
            
        % 90 degrees
        case 3
            Event('Reference profiles set to AP');
            refdata = handles.APreferences;
          
        % 180 degrees
        case 4
            Event('Reference profiles set to PA (thru couch)');
            refdata = handles.PATCreferences;
           
        % 270 degrees
        case 5
            Event('Reference profiles set to PA (no couch)');
            refdata = handles.PANCreferences;
    end
    
    % Apply gamma criteria
    refdata.abs = handles.abs;
    refdata.dta = handles.dta;
    
    % Process profiles, comparing to reference data (normalized to max)
    [results, refresults] = AnalyzeProfilerFields(data, refdata, 'max');
    
    % Set application specific data
    if strcmp(handles.axis, 'x') || strcmp(handles.axis, 'y')
        handles.([head,'profiles',file]) = results.([handles.axis,'data']);
        handles.([head,'refprofiles',file]) = ...
            refresults.([handles.axis,'data']);
    else
        handles.([head,'profiles',file]) = results.([handles.axis,'diag']);
        handles.([head,'refprofiles',file]) = ...
            refresults.([handles.axis,'diag']);
    end
    handles.([head,'FWHM',file]) = results.([handles.axis,'fwhm']);
    handles.([head,'X1',file]) = results.([handles.axis,'edges'])(:,1);
    handles.([head,'X2',file]) = results.([handles.axis,'edges'])(:,2);
    handles.([head,'gamma',file]) = results.([handles.axis,'gamma']);
    handles.([head,'refFWHM',file]) = refresults.([handles.axis,'fwhm']);
    handles.([head,'refX1',file]) = ...
        refresults.([handles.axis,'edges'])(:,1);
    handles.([head,'refX2',file]) = ...
        refresults.([handles.axis,'edges'])(:,2);
    
    % Loop through each gamma profile
    for i = 2:size(handles.([head,'gamma',file]),1)
    
        % Null gamma values < 80% max signal (helps improve visualization)
        handles.([head,'gamma',file])(i,:) = ...
            handles.([head,'gamma',file])(i,:) .* ...
            floor(handles.([head,'profiles',file])(i,:) / ...
            (max(handles.([head,'profiles',file])(i,:) * handles.thresh)));
    end
    Event(sprintf(['Gamma values below %0.1f%% target profile ', ...
        'threshold ignored'], handles.thresh*100));
    
    % Update MLC statistics
    handles = UpdateMLCStatistics(handles, head);
    
    % Update plot to show profiles
    set(handles.([head,'display']), 'Value', 2);
    handles = UpdateDisplay(handles, head);

    % Enable print button
    set(handles.print_button, 'enable', 'on');
    
    % Log event
    Event(sprintf('%s angle %s data loaded successfully in %0.3f seconds', ...
        head, file, toc(t)));
    
    % Clear temporary variables
    clear i t data refdata results refresults;
end

% Clear temporary variables
clear name path;