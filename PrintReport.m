function varargout = PrintReport(varargin)
% PrintReport is called by AnalyzeMLCProfiles after SNC IC Profiler 
% profiles have been loaded and analyzed, and creates a "report" figure of
% the plots and statistics generated in AnalyzeMLCProfiles.  This report is 
% then saved to a temporary file in PDF format and opened using the default
% application.  Once the PDF is opened, this figure is deleted. The visual 
% layout of the report is defined in PrintReport.fig.
%
% When calling PrintReport, the GUI handles structure (or data structure
% containing the daily and patient specific variables) should be passed
% immediately following the string 'Data', as shown in the following
% example:
%
% PrintReport('Data', handles);
%
% For more information on the variables required in the data structure, see
% BrowseCallback, UpdateDisplay, UpdateMLCStatistics, and LoadVersionInfo.
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

% Last Modified by GUIDE v2.5 09-Nov-2014 20:08:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PrintReport_OpeningFcn, ...
                   'gui_OutputFcn',  @PrintReport_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PrintReport_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PrintReport (see VARARGIN)

% Choose default command line output for PrintReport
handles.output = hObject;

% Log start of printing and start timer
Event('Printing report');
tic;

% Load data structure from varargin
for i = 1:length(varargin)
    if strcmp(varargin{i}, 'Data')
        data = varargin{i+1}; 
        break; 
    end
end

% Set logo
axes(handles.logo);
rgb = imread('UWCrest_4c.png', 'BackgroundColor', [1 1 1]);
image(rgb);
axis equal;
axis off;
clear rgb;

% Set report date/time
set(handles.text12, 'String', datestr(now));

% Set user name
[s, cmdout] = system('whoami');
if s == 0
    set(handles.text7, 'String', cmdout);
else  
    % If run as an automated unit test, do not prompt
    if data.unitflag == 0
        cmdout = inputdlg('Enter your name:', 'Username', [1 50]);
    else
        cmdout{1} = 'Unit test';
    end
    set(handles.text7, 'String', cmdout{1});
end
clear s cmdout;

% Set version
set(handles.text8, 'String', sprintf('%s (%s)', data.version, ...
    data.versionInfo{6}));

% Set SNC software
set(handles.text44, 'String', data.sncversion);

% Set collector
set(handles.text41, 'String', data.collector);

% Set collector serial number:
set(handles.text42, 'String', data.serial);

% Define a color map for displaying multiple datasets
cmap = lines(16);

% If head 1 data was loaded
if (isfield(data, 'h1profiles1') && ~isempty(data.h1profiles1) > 0) || ...
         (isfield(data, 'h1profiles2') && ~isempty(data.h1profiles2) > 0) || ...
         (isfield(data, 'h1profiles3') && ~isempty(data.h1profiles3) > 0) || ...
         (isfield(data, 'h1profiles4') && ~isempty(data.h1profiles4) > 0)
    
    % Initialize empty cell array for files
    files = cell(0);
    c = 0;

    % Set files
    for i = 1:4
        
        % If a file was loaded
        if ~isempty(get(data.(sprintf('h1file%i', i)), 'String'))
            
            % Increment the counter
            c = c + 1;
            
            % Store the file name
            files{c} = get(data.(sprintf('h1file%i', i)), 'String');
        end
    end
    
    set(handles.text14, 'String', strjoin(files, ', '));
    
    % Log event
    Event('Plotting head 1 field edge offsets');

    % Set axes
    axes(handles.axes1);

    % Initialize empty cell array for legend entries
    names = cell(0);
    c = 0;

    % Hold rendering for overlapping plots
    hold on;

    % Loop through each dataset
    for i = 1:4

        % If the dataset exists
        if ~strcmp(get(data.(sprintf('h1file%i', i)), 'String'), '') ...
                && ~isempty(get(data.(sprintf('h1file%i', i)), 'String'))

            % Increment the counter
            c = c + 1;

            % Plot the X1 field edge difference from reference
            plot(data.(sprintf('h1refX1%i', i))*10, ...
                (data.(sprintf('h1X1%i', i)) - ...
                data.(sprintf('h1refX1%i', i)))*10, '-o', ...
                'Color', cmap(c,:));

            % Add legend entry for X1
            names{c} = sprintf('%i X1', ...
                (get(data.(sprintf('h1angle%i', i)), ...
                'Value') - 2) * 90);

            % Increment the counter
            c = c + 1;

            % Plot the X2 field edge difference from reference
            plot(data.(sprintf('h1refX2%i', i))*10, ...
                (data.(sprintf('h1X2%i', i)) - ...
                data.(sprintf('h1refX2%i', i)))*10, '-o', ...
                'Color', cmap(c,:));

            % Add legend entry for X2
            names{c} = sprintf('%i X2', ...
                (get(data.(sprintf('h1angle%i', i)), ...
                'Value') - 2) * 90);

        end 
    end

    % Finish specifying plot
    hold off;
    xlabel('Field Edge (mm)');
    xlim([-150 150]);
    ylabel('Field Edge Difference (mm)');
    ylim([-3 3]);
    if c > 0
        legend(names);
    end
    grid on;
    box on;

    % Log event
    Event('Plotting head 1 FWHM differences');

    % Set axes
    axes(handles.axes2);
    
    % Initialize empty cell array for legend entries
    names = cell(0);
    c = 0;

    % Hold rendering for overlapping plots
    hold on;

    % Loop through each dataset
    for i = 1:4

        % If the dataset exists
        if ~strcmp(get(data.(sprintf('h1file%i', i)), ...
                'String'), '') && ~isempty(get(data.(sprintf(...
                'h1file%i', i)), 'String'))
            
            % Increment the counter
            c = c + 1;

            % Plot the FWHM difference from reference
            plot((data.(sprintf('h1FWHM%i', i)) - ...
                data.(sprintf('h1refFWHM%i', i)))*10, '-o', ...
                'Color', cmap(c,:));

             % Add legend entry
            names{c} = sprintf('%i', ...
                (get(data.(sprintf('h1angle%i', i)), ...
                'Value') - 2) * 90);
        end 
    end

    % Finish specifying plot
    hold off;
    xlabel('Profile');
    set(gca,'XTick', 1:1:6);
    ylabel('FWHM Difference (mm)');
    ylim([-3 3]);
    if c > 0
        legend(names);
    end
    grid on;
    box on;
    
    % Log start
    Event('Updating head 1 table statistics');
    
    % Add statistics table
    table = get(data.h1table, 'Data');
    set(handles.text19, 'String', sprintf('%s\n\n', table{1:7,1}));
    set(handles.text20, 'String', sprintf('%s\n\n', table{1:7,4}));
    
    % Clear temporary variables
    clear table h i names c;

else
    
    % Hide input file
    set(handles.text13, 'visible', 'off'); 
    set(handles.text14, 'visible', 'off'); 
    
    % Hide displays
    set(allchild(handles.axes1), 'visible', 'off'); 
    set(handles.axes1, 'visible', 'off'); 
    set(allchild(handles.axes2), 'visible', 'off'); 
    set(handles.axes2, 'visible', 'off'); 
    
    % Hide statistics table
    set(handles.text17, 'visible', 'off'); 
    set(handles.text18, 'visible', 'off'); 
    set(handles.text19, 'visible', 'off'); 
    set(handles.text20, 'visible', 'off'); 
end

% If head 2 data was loaded
if (isfield(data, 'h2profiles1') && ~isempty(data.h2profiles1) > 0) || ...
         (isfield(data, 'h2profiles2') && ~isempty(data.h2profiles2) > 0) || ...
         (isfield(data, 'h2profiles3') && ~isempty(data.h2profiles3) > 0) || ...
         (isfield(data, 'h2profiles4') && ~isempty(data.h2profiles4) > 0)
    
    % Initialize empty cell array for files
    files = cell(0);
    c = 0;

    % Set files
    for i = 1:4
        
        % If a file was loaded
        if ~isempty(get(data.(sprintf('h2file%i', i)), 'String'))
            
            % Increment the counter
            c = c + 1;
            
            % Store the file name
            files{c} = get(data.(sprintf('h2file%i', i)), 'String');
        end
    end
    
    set(handles.text28, 'String', strjoin(files, ', '));
    
    % Log event
    Event('Plotting head 2 field edge offsets');

    % Set axes
    axes(handles.axes3);

    % Initialize empty cell array for legend entries
    names = cell(0);
    c = 0;

    % Hold rendering for overlapping plots
    hold on;

    % Loop through each dataset
    for i = 1:4

        % If the dataset exists
        if ~strcmp(get(data.(sprintf('h2file%i', i)), 'String'), '') ...
                && ~isempty(get(data.(sprintf('h2file%i', i)), 'String'))

            % Increment the counter
            c = c + 1;

            % Plot the X1 field edge difference from reference
            plot(data.(sprintf('h2refX1%i', i))*10, ...
                (data.(sprintf('h2X1%i', i)) - ...
                data.(sprintf('h2refX1%i', i)))*10, '-o', ...
                'Color', cmap(c,:));

            % Add legend entry for X1
            names{c} = sprintf('%i X1', ...
                (get(data.(sprintf('h2angle%i', i)), ...
                'Value') - 2) * 90);

            % Increment the counter
            c = c + 1;

            % Plot the X2 field edge difference from reference
            plot(data.(sprintf('h2refX2%i', i))*10, ...
                (data.(sprintf('h2X2%i', i)) - ...
                data.(sprintf('h2refX2%i', i)))*10, '-o', ...
                'Color', cmap(c,:));

            % Add legend entry for X2
            names{c} = sprintf('%i X2', ...
                (get(data.(sprintf('h2angle%i', i)), ...
                'Value') - 2) * 90);

        end 
    end

    % Finish specifying plot
    hold off;
    xlabel('Field Edge (mm)');
    xlim([-150 150]);
    ylabel('Field Edge Difference (mm)');
    ylim([-3 3]);
    if c > 0
        legend(names);
    end
    grid on;
    box on;

    % Log event
    Event('Plotting head 2 FWHM differences');

    % Set axes
    axes(handles.axes4);
    
    % Initialize empty cell array for legend entries
    names = cell(0);
    c = 0;

    % Hold rendering for overlapping plots
    hold on;

    % Loop through each dataset
    for i = 1:4

        % If the dataset exists
        if ~strcmp(get(data.(sprintf('h2file%i', i)), ...
                'String'), '') && ~isempty(get(data.(sprintf(...
                'h2file%i', i)), 'String'))
            
            % Increment the counter
            c = c + 1;

            % Plot the FWHM difference from reference
            plot((data.(sprintf('h2FWHM%i', i)) - ...
                data.(sprintf('h2refFWHM%i', i)))*10, '-o', ...
                'Color', cmap(c,:));

             % Add legend entry
            names{c} = sprintf('%i', ...
                (get(data.(sprintf('h2angle%i', i)), ...
                'Value') - 2) * 90);
        end 
    end

    % Finish specifying plot
    hold off;
    xlabel('Profile');
    set(gca,'XTick', 1:1:6);
    ylabel('FWHM Difference (mm)');
    ylim([-3 3]);
    if c > 0
        legend(names);
    end
    grid on;
    box on;
    
    % Log start
    Event('Updating head 2 table statistics');
    
    % Add statistics table
    table = get(data.h2table, 'Data');
    set(handles.text31, 'String', sprintf('%s\n\n', table{1:7,1}));
    set(handles.text32, 'String', sprintf('%s\n\n', table{1:7,4}));
    
    % Clear temporary variables
    clear table h i names c;

else
    
    % Hide input file
    set(handles.text27, 'visible', 'off'); 
    set(handles.text28, 'visible', 'off'); 
    
    % Hide displays
    set(allchild(handles.axes3), 'visible', 'off'); 
    set(handles.axes3, 'visible', 'off'); 
    set(allchild(handles.axes4), 'visible', 'off'); 
    set(handles.axes4, 'visible', 'off'); 
    
    % Hide statistics table
    set(handles.text29, 'visible', 'off'); 
    set(handles.text30, 'visible', 'off'); 
    set(handles.text31, 'visible', 'off'); 
    set(handles.text32, 'visible', 'off'); 
end

% If head 3 data was loaded
if (isfield(data, 'h3profiles1') && ~isempty(data.h3profiles1) > 0) || ...
         (isfield(data, 'h3profiles2') && ~isempty(data.h3profiles2) > 0) || ...
         (isfield(data, 'h3profiles3') && ~isempty(data.h3profiles3) > 0) || ...
         (isfield(data, 'h3profiles4') && ~isempty(data.h3profiles4) > 0)
    
    % Initialize empty cell array for files
    files = cell(0);
    c = 0;

    % Set files
    for i = 1:4
        
        % If a file was loaded
        if ~isempty(get(data.(sprintf('h3file%i', i)), 'String'))
            
            % Increment the counter
            c = c + 1;
            
            % Store the file name
            files{c} = get(data.(sprintf('h3file%i', i)), 'String');
        end
    end
    
    set(handles.text34, 'String', strjoin(files, ', '));
    
    % Log event
    Event('Plotting head 3 field edge offsets');

    % Set axes
    axes(handles.axes5);

    % Initialize empty cell array for legend entries
    names = cell(0);
    c = 0;

    % Hold rendering for overlapping plots
    hold on;

    % Loop through each dataset
    for i = 1:4

        % If the dataset exists
        if ~strcmp(get(data.(sprintf('h3file%i', i)), 'String'), '') ...
                && ~isempty(get(data.(sprintf('h3file%i', i)), 'String'))

            % Increment the counter
            c = c + 1;

            % Plot the X1 field edge difference from reference
            plot(data.(sprintf('h3refX1%i', i))*10, ...
                (data.(sprintf('h3X1%i', i)) - ...
                data.(sprintf('h3refX1%i', i)))*10, '-o', ...
                'Color', cmap(c,:));

            % Add legend entry for X1
            names{c} = sprintf('%i X1', ...
                (get(data.(sprintf('h3angle%i', i)), ...
                'Value') - 2) * 90);

            % Increment the counter
            c = c + 1;

            % Plot the X2 field edge difference from reference
            plot(data.(sprintf('h3refX2%i', i))*10, ...
                (data.(sprintf('h3X2%i', i)) - ...
                data.(sprintf('h3refX2%i', i)))*10, '-o', ...
                'Color', cmap(c,:));

            % Add legend entry for X2
            names{c} = sprintf('%i X2', ...
                (get(data.(sprintf('h3angle%i', i)), ...
                'Value') - 2) * 90);

        end 
    end

    % Finish specifying plot
    hold off;
    xlabel('Field Edge (mm)');
    xlim([-150 150]);
    ylabel('Field Edge Difference (mm)');
    ylim([-3 3]);
    if c > 0
        legend(names);
    end
    grid on;
    box on;

    % Log event
    Event('Plotting head 3 FWHM differences');

    % Set axes
    axes(handles.axes6);
    
    % Initialize empty cell array for legend entries
    names = cell(0);
    c = 0;

    % Hold rendering for overlapping plots
    hold on;

    % Loop through each dataset
    for i = 1:4

        % If the dataset exists
        if ~strcmp(get(data.(sprintf('h3file%i', i)), ...
                'String'), '') && ~isempty(get(data.(sprintf(...
                'h3file%i', i)), 'String'))
            
            % Increment the counter
            c = c + 1;

            % Plot the FWHM difference from reference
            plot((data.(sprintf('h3FWHM%i', i)) - ...
                data.(sprintf('h3refFWHM%i', i)))*10, '-o', ...
                'Color', cmap(c,:));

             % Add legend entry
            names{c} = sprintf('%i', ...
                (get(data.(sprintf('h3angle%i', i)), ...
                'Value') - 2) * 90);
        end 
    end

    % Finish specifying plot
    hold off;
    xlabel('Profile');
    set(gca,'XTick', 1:1:6);
    ylabel('FWHM Difference (mm)');
    ylim([-3 3]);
    if c > 0
        legend(names);
    end
    grid on;
    box on;
    
    % Log start
    Event('Updating head 3 table statistics');
    
    % Add statistics table
    table = get(data.h3table, 'Data');
    set(handles.text37, 'String', sprintf('%s\n\n', table{1:7,1}));
    set(handles.text38, 'String', sprintf('%s\n\n', table{1:7,4}));
    
    % Clear temporary variables
    clear table h i names c;

else
    
    % Hide input file
    set(handles.text33, 'visible', 'off'); 
    set(handles.text34, 'visible', 'off'); 
    
    % Hide displays
    set(allchild(handles.axes5), 'visible', 'off'); 
    set(handles.axes5, 'visible', 'off'); 
    set(allchild(handles.axes6), 'visible', 'off'); 
    set(handles.axes6, 'visible', 'off'); 
    
    % Hide statistics table
    set(handles.text35, 'visible', 'off'); 
    set(handles.text36, 'visible', 'off'); 
    set(handles.text37, 'visible', 'off'); 
    set(handles.text38, 'visible', 'off'); 
end

% Update handles structure
guidata(hObject, handles);

% Get temporary file name
temp = [tempname, '.pdf'];

% Print report
Event(['Saving report to ', temp]);
saveas(hObject, temp);

% Open file (if not running as an automated unit test)
if data.unitflag == 0
    Event(['Opening file ', temp]);
    open(temp);
else
    Event('Skipping file open in unit test framework', 'UNIT');
end

% Clear temporary variable
clear data;

% Log completion
Event(sprintf('Report saved successfully in %0.3f seconds', toc));

% Close figure
close(hObject);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PrintReport_OutputFcn(~, ~, ~) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
