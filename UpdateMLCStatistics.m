function handles = UpdateMLCStatistics(handles, head)
% UpdateMLCStatistics is called by AnalyzeMLCProfiles to compute and update
% the statistics table for each head.  See below for more information on
% the statistics computed.  This function uses GUI handles data (passed in
% the first input variable).  This function also uses the input variable 
% head, which should be a string indicating the head number (h1, h2, or h3) 
% to determine which UI table to modify.  Upon successful completion, an
% updated GUI handles structure is returned.
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

% Run in try-catch to log error via Event.m
try
    
% Log start
Event(['Updating ', head, 'table statistics']);
tic;

% Initialize results arrays
X1offsets = [];
X2offsets = [];
FWHMdiffs = [];

% Load table data cell array
table = get(handles.([head, 'table']), 'Data');

%% Retrieve loaded data
% Initialize data counter
c = 0;

% Loop through each dataset
for i = 1:4
    
    % If file data exists
    if ~strcmp(get(handles.(sprintf('%sfile%i', head, i)), 'String'), '') ...
            && ~isempty(get(handles.(sprintf('%sfile%i', head, i)), 'String'))
        
        % Add this dataset's X1 offsets to array
        X1offsets(c*4+1:c*4+length(handles.(sprintf('%sX1%i', head, i)))) ...
            = handles.(sprintf('%sX1%i', head, i)) - ...
            handles.(sprintf('%srefX1%i', head, i));
        
        % Add this dataset's X2 offsets to array
        X2offsets(c*4+1:c*4+length(handles.(sprintf('%sX1%i', head, i)))) ...
            = handles.(sprintf('%sX2%i', head, i)) - ...
            handles.(sprintf('%srefX2%i', head, i));
        
        % Add this dataset's FWHM differences to array
        FWHMdiffs(c*4+1:c*4+length(handles.(sprintf('%sX1%i', head, i)))) ...
            = handles.(sprintf('%sFWHM%i', head, i)) - ...
            handles.(sprintf('%srefFWHM%i', head, i));
        
        % Increment counter
        c = c + 1;
    end
end

%% Compute statistics
% Initialize counter
c = 0;

% Compute minimum field edge offsets
c = c + 1;
table{c,1} = 'Min field edge offset (mm)';
table{c,2} = sprintf('%0.2f', min(X1offsets)*10);
table{c,3} = sprintf('%0.2f', min(X2offsets)*10);
table{c,4} = sprintf('%0.2f', min([X1offsets, X2offsets])*10);
Event(sprintf(['Minimum field edge offsets computed (X1 = %0.3f, X2 = ', ...
    '%0.3f, both = %0.3f)'], min(X1offsets)*10, min(X2offsets)*10, ...
    min([X1offsets, X2offsets])*10));

% Compute maximum field edge offsets
c = c + 1;
table{c,1} = 'Max field edge offset (mm)';
table{c,2} = sprintf('%0.2f', max(X1offsets)*10);
table{c,3} = sprintf('%0.2f', max(X2offsets)*10);
table{c,4} = sprintf('%0.2f', max([X1offsets, X2offsets])*10);
Event(sprintf(['Maximum field edge offsets computed (X1 = %0.3f, X2 = ', ...
    '%0.3f, both = %0.3f)'], max(X1offsets)*10, max(X2offsets)*10, ...
    max([X1offsets, X2offsets])*10));

% Compute average field edge offsets
c = c + 1;
table{c,1} = 'Avg field edge offset (mm)';
table{c,2} = sprintf('%0.2f', mean(X1offsets)*10);
table{c,3} = sprintf('%0.2f', mean(X2offsets)*10);
table{c,4} = sprintf('%0.2f', mean([X1offsets, X2offsets])*10);
Event(sprintf(['Average field edge offsets computed (X1 = %0.3f, X2 = ', ...
    '%0.3f, both = %0.3f)'], mean(X1offsets)*10, mean(X2offsets)*10, ...
    mean([X1offsets, X2offsets])*10));

% Compute % less than 1 mm
c = c + 1;
table{c,1} = 'Offets less than 1 mm';
table{c,2} = sprintf('%0.1f%%', sum(abs(X1offsets(:)) < 0.1) / ...
    length(X1offsets) * 100);
table{c,3} = sprintf('%0.1f%%', sum(abs(X2offsets(:)) < 0.1) / ...
    length(X2offsets) * 100);
table{c,4} = sprintf('%0.1f%%', (sum(abs(X1offsets(:)) < 0.1) + ...
    sum(abs(X2offsets(:)) < 0.1)) / (length(X1offsets) + ...
    length(X2offsets)) * 100);
Event(sprintf('%i X1, %i X2 offsets less than 1 mm', ...
    sum(X1offsets(:) < 0.1), sum(X2offsets(:) < 0.1)));

% Compute minimum field width differences
c = c + 1;
table{c,1} = 'Min field width diff (mm)';
table{c,2} = '';
table{c,3} = '';
table{c,4} = sprintf('%0.2f', min(FWHMdiffs)*10);
Event(sprintf('Minimum FWHM difference computed as %0.3f', ...
    min(FWHMdiffs)*10));

% Compute maximum field width differences
c = c + 1;
table{c,1} = 'Max field width diff (mm)';
table{c,2} = '';
table{c,3} = '';
table{c,4} = sprintf('%0.2f', max(FWHMdiffs)*10);
Event(sprintf('Maximum FWHM difference computed as %0.3f', ...
    max(FWHMdiffs)*10));

% Compute average field width differences
c = c + 1;
table{c,1} = 'Avg field width diff (mm)';
table{c,2} = '';
table{c,3} = '';
table{c,4} = sprintf('%0.2f', mean(FWHMdiffs)*10);
Event(sprintf('Mean FWHM difference computed as %0.3f', ...
    mean(FWHMdiffs)*10));

% Display gamma criteria
c = c + 1;
table{c,1} = sprintf('Gamma criteria (>%0.0f%%)', handles.thresh*100);
table{c,2} = '';
table{c,3} = '';
table{c,4} = sprintf('%0.1f%%/%0.1f mm', handles.abs, handles.dta*10);

% Compute max gamma
c = c + 1;
table{c,1} = 'Angle 1 max gamma';
table{c,2} = '';
table{c,3} = '';
if isfield(handles, [head, 'gamma1'])
    m = 0;
    for i = 2:size(handles.([head, 'gamma1']),1)
        m = max(m, max(handles.([head, 'gamma1'])(i,:)));
    end
    table{c,4} = sprintf('%0.2f', m);
    Event(sprintf('Maximum %0.2f%%/%0.2f mm gamma from angle 1 = %0.3f', ...
        handles.abs, handles.dta*10, m));
    clear m;
end

% Compute max gamma
c = c + 1;
table{c,1} = 'Angle 2 max gamma';
table{c,2} = '';
table{c,3} = '';
if isfield(handles, [head, 'gamma2'])
    m = 0;
    for i = 2:size(handles.([head, 'gamma2']),1)
        m = max(m, max(handles.([head, 'gamma2'])(i,:)));
    end
    table{c,4} = sprintf('%0.2f', m);
    Event(sprintf('Maximum %0.2f%%/%0.2f mm gamma from angle 2 = %0.3f', ...
        handles.abs, handles.dta*10, m));
    clear m;
end

% Compute max gamma
c = c + 1;
table{c,1} = 'Angle 3 max gamma';
table{c,2} = '';
table{c,3} = '';
if isfield(handles, [head, 'gamma3'])
    m = 0;
    for i = 2:size(handles.([head, 'gamma3']),1)
        m = max(m, max(handles.([head, 'gamma3'])(i,:)));
    end
    table{c,4} = sprintf('%0.2f', m);
    Event(sprintf('Maximum %0.2f%%/%0.2f mm gamma from angle 3 = %0.3f', ...
        handles.abs, handles.dta*10, m));
    clear m;
end

% Compute max gamma
c = c + 1;
table{c,1} = 'Angle 4 max gamma';
table{c,2} = '';
table{c,3} = '';
if isfield(handles, [head, 'gamma4'])
    m = 0;
    for i = 2:size(handles.([head, 'gamma4']),1)
        m = max(m, max(handles.([head, 'gamma4'])(i,:)));
    end
    table{c,4} = sprintf('%0.2f', m);
    Event(sprintf('Maximum %0.2f%%/%0.2f mm gamma from angle 4 = %0.3f', ...
        handles.abs, handles.dta*10, m));
    clear m;
end

% Set table data
set(handles.([head, 'table']), 'Data', table);

% Log completion
Event(sprintf('Statistics table updated successfully in %0.3f seconds', toc));

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end