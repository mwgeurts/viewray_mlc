function varargout = AnalyzeMLCProfiles(varargin)
% AnalyzeMLCProfiles loads Monte Carlo treatment planning data from the
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

% Last Modified by GUIDE v2.5 11-Feb-2015 14:29:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AnalyzeMLCProfiles_OpeningFcn, ...
                   'gui_OutputFcn',  @AnalyzeMLCProfiles_OutputFcn, ...
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
function AnalyzeMLCProfiles_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AnalyzeMLCProfiles (see VARARGIN)

% Choose default command line output for AnalyzeMLCProfiles
handles.output = hObject;

% Set version handle
handles.version = '1.1.2';

% Determine path of current application
[path, ~, ~] = fileparts(mfilename('fullpath'));

% Set current directory to location of this application
cd(path);

% Clear temporary variable
clear path;

% Set version information.  See LoadVersionInfo for more details.
handles.versionInfo = LoadVersionInfo;

% Store program and MATLAB/etc version information as a string cell array
string = {'ViewRay MLC Position Check'
    sprintf('Version: %s (%s)', handles.version, handles.versionInfo{6});
    sprintf('Author: Mark Geurts <mark.w.geurts@gmail.com>');
    sprintf('MATLAB Version: %s', handles.versionInfo{2});
    sprintf('MATLAB License Number: %s', handles.versionInfo{3});
    sprintf('Operating System: %s', handles.versionInfo{1});
    sprintf('CUDA: %s', handles.versionInfo{4});
    sprintf('Java Version: %s', handles.versionInfo{5})
};

% Add dashed line separators      
separator = repmat('-', 1,  size(char(string), 2));
string = sprintf('%s\n', separator, string{:}, separator);

% Log information
Event(string, 'INIT');

%% Initialize UI
% Set version UI text
set(handles.version_text, 'String', sprintf('Version %s', handles.version));

% Disable print button
set(handles.print_button, 'enable', 'off');

% Turn off images
set(allchild(handles.h1axes), 'visible', 'off'); 
set(handles.h1axes, 'visible', 'off'); 
set(allchild(handles.h2axes), 'visible', 'off'); 
set(handles.h2axes, 'visible', 'off'); 
set(allchild(handles.h3axes), 'visible', 'off'); 
set(handles.h3axes, 'visible', 'off'); 

% Set plot options
handles.plotoptions = UpdateDisplay();
set(handles.h1display, 'String', handles.plotoptions);
set(handles.h2display, 'String', handles.plotoptions);
set(handles.h3display, 'String', handles.plotoptions);

% Initialize tables
set(handles.h1table, 'Data', cell(8,4));
set(handles.h2table, 'Data', cell(8,4));
set(handles.h3table, 'Data', cell(8,4));

%% Initialize global variables
% Declare the initial path to search when browsing for input files.  This
% path will automatically be set to the location of the most recent loaded
% file during application execution.
handles.path = userpath;
Event(['Default file path set to ', handles.path]);

% Declare Gamma analysis criteria
handles.abs = 2.0; % percent
handles.dta = 0.1; % cm
Event(sprintf('Gamma criteria set to %0.1f%%/%0.1f mm', ...
    [handles.abs handles.dta*10]));

% Declaure Gamma threshold. Reducing the range over which Gamma is reported
% (to 80% for example) improves visualization of the different Gamma index
% profiles when multiple profiles are plotted on the same axes.
handles.thresh = 0.8;
Event(sprintf('Gamma threshold set to %0.1f%%', handles.thresh * 100));

% Declare the Profiler rotation. This factor will adjust how reference data
% (computed by the TPS) is extracted for the Profiler axes. If the Profiler 
% is aligned along the TPS axes, set to zero.  If the profiler is rotated
% 90 degrees such that the Profiler Y axis is aligned to the TPS X axis,
% set to 90.
handles.rot = 90;
Event(sprintf('Profiler rotation set to %0.1f degrees', handles.rot));

% Declare the Profiler axis to use for analysis. This can be set to either
% 'x', 'y', 'p', or 'n'.
handles.axis = 'y';
Event(sprintf('Analysis will be performed on Profiler %s axis', ...
    handles.axis));

% Unit test flag. This will be set to 1 if the application is being run as
% part of unit testing (see UnitTest for more information)
handles.unitflag = 0;

%% Load submodules and toolboxes
% Add snc_extract submodule to search path
addpath('./snc_extract');

% Check if MATLAB can find ParseSNCprm
if exist('ParseSNCprm', 'file') ~= 2 || (~isempty(varargin) && ...
        strcmp(varargin{1}, 'unitParseSNCprm'))
    
    % If not, throw an error
    Event(['The snc_extract submodule does not exist in the search path. ', ...
        'Use git clone --recursive or git submodule init followed by git ', ...
        'submodule update to fetch all submodules'], 'ERROR');
end

% Check if Statistics Toolbox is installed
if (exist('corr', 'file') ~= 6 && exist('corr', 'file') ~= 2) || ...
    (~isempty(varargin) && strcmp(varargin{1}, 'unitCorr'))
    
    % If not, throw an error
    Event(['The MATLAB Statistics Toolbox is not installed and is ', ...
        'required for proper execution.'], 'ERROR');
end

%% Load reference profiles
% Declare the AP (through the front of the IC Profiler) Monte Carlo planar
% data files exported from the TPS
handles.APfiles = {
    './reference/AP-10_PlaneDose_Vertical_Point1.dcm'
    './reference/AP-6_PlaneDose_Vertical_Point2.dcm'
    './reference/AP-2_PlaneDose_Vertical_Point3.dcm'
    './reference/AP+2_PlaneDose_Vertical_Point4.dcm'
    './reference/AP+6_PlaneDose_Vertical_Point5.dcm'
    './reference/AP+10_PlaneDose_Vertical_Point6.dcm'
};

% Load and extract reference profiles, rotated by 90 deg
handles.APreferences = ...
    LoadProfilerDICOMReference(handles.APfiles, handles.rot);

% Declare the PA (through the back of the IC Profiler and jig but without
% the couch) Monte Carlo planar data files exported from the TPS
handles.PANCfiles = {
    './reference/PA-10_NOCOUCH_PlaneDose_Vertical_Point1.dcm'
    './reference/PA-6_NOCOUCH_PlaneDose_Vertical_Point2.dcm'
    './reference/PA-2_NOCOUCH_PlaneDose_Vertical_Point3.dcm'
    './reference/PA+2_NOCOUCH_PlaneDose_Vertical_Point4.dcm'
    './reference/PA+6_NOCOUCH_PlaneDose_Vertical_Point5.dcm'
    './reference/PA+10_NOCOUCH_PlaneDose_Vertical_Point6.dcm'
};

% Load and extract reference profiles, rotated by 90 deg
handles.PANCreferences = ...
    LoadProfilerDICOMReference(handles.PANCfiles, handles.rot);

% Declare the PA (through the back of the IC Profiler, jig, and couch) 
% Monte Carlo planar data files exported from the TPS
handles.PATCfiles = {
    './reference/PA-10_THRUCOUCH_PlaneDose_Vertical_Point1.dcm'
    './reference/PA-6_THRUCOUCH_PlaneDose_Vertical_Point2.dcm'
    './reference/PA-2_THRUCOUCH_PlaneDose_Vertical_Point3.dcm'
    './reference/PA+2_THRUCOUCH_PlaneDose_Vertical_Point4.dcm'
    './reference/PA+6_THRUCOUCH_PlaneDose_Vertical_Point5.dcm'
    './reference/PA+10_THRUCOUCH_PlaneDose_Vertical_Point6.dcm'
};

% Load and extract reference profiles, rotated by 90 deg
handles.PATCreferences = ...
    LoadProfilerDICOMReference(handles.PATCfiles, handles.rot);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = AnalyzeMLCProfiles_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1file1_Callback(~, ~, ~) %#ok<*DEFNU>
% hObject    handle to h1file1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1file1_CreateFcn(hObject, ~, ~)
% hObject    handle to h1file1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1browse1_Callback(hObject, ~, handles)
% hObject    handle to h1browse1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h1', '1');
    
% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1angle1_Callback(~, ~, ~)
% hObject    handle to h1angle1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1angle1_CreateFcn(hObject, ~, ~)
% hObject    handle to h1angle1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1file2_Callback(~, ~, ~)
% hObject    handle to h1file2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1file2_CreateFcn(hObject, ~, ~)
% hObject    handle to h1file2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1browse2_Callback(hObject, ~, handles)
% hObject    handle to h1browse2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h1', '2');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1angle2_Callback(~, ~, ~)
% hObject    handle to h1angle2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1angle2_CreateFcn(hObject, ~, ~)
% hObject    handle to h1angle2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1file3_Callback(~, ~, ~)
% hObject    handle to h1file3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1file3_CreateFcn(hObject, ~, ~)
% hObject    handle to h1file3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1browse3_Callback(hObject, ~, handles)
% hObject    handle to h1browse3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h1', '3');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1angle3_Callback(~, ~, ~)
% hObject    handle to h1angle3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1angle3_CreateFcn(hObject, ~, ~)
% hObject    handle to h1angle3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1file4_Callback(~, ~, ~)
% hObject    handle to h1file4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1file4_CreateFcn(hObject, ~, ~)
% hObject    handle to h1file4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1browse4_Callback(hObject, ~, handles)
% hObject    handle to h1browse4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h1', '4');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1angle4_Callback(~, ~, ~)
% hObject    handle to h1angle4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1angle4_CreateFcn(hObject, ~, ~)
% hObject    handle to h1angle4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1display_Callback(hObject, ~, handles)
% hObject    handle to h1display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('H1 display dropdown changed');

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h1');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1display_CreateFcn(hObject, ~, ~)
% hObject    handle to h1display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1clear_Callback(hObject, ~, handles)
% hObject    handle to h1clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute ClearCallback
handles = ClearCallback(handles, 'h1');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3file1_Callback(~, ~, ~)
% hObject    handle to h3file1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3file1_CreateFcn(hObject, ~, ~)
% hObject    handle to h3file1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3browse1_Callback(hObject, ~, handles)
% hObject    handle to h3browse1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h3', '1');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3angle1_Callback(~, ~, ~)
% hObject    handle to h3angle1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3angle1_CreateFcn(hObject, ~, ~)
% hObject    handle to h3angle1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3browse2_Callback(hObject, ~, handles)
% hObject    handle to h3browse2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h3', '2');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3angle2_Callback(~, ~, ~)
% hObject    handle to h3angle2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3angle2_CreateFcn(hObject, ~, ~)
% hObject    handle to h3angle2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3browse3_Callback(hObject, ~, handles)
% hObject    handle to h3browse3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h3', '3');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3angle3_Callback(~, ~, ~)
% hObject    handle to h3angle3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3angle3_CreateFcn(hObject, ~, ~)
% hObject    handle to h3angle3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3file4_Callback(~, ~, ~)
% hObject    handle to h3file4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3file4_CreateFcn(hObject, ~, ~)
% hObject    handle to h3file4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3browse4_Callback(hObject, ~, handles)
% hObject    handle to h3browse4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h3', '4');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3angle4_Callback(~, ~, ~)
% hObject    handle to h3angle4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3angle4_CreateFcn(hObject, ~, ~)
% hObject    handle to h3angle4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3display_Callback(hObject, ~, handles)
% hObject    handle to h3display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('H3 display dropdown changed');

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h3');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3display_CreateFcn(hObject, ~, ~)
% hObject    handle to h3display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3clear_Callback(hObject, ~, handles)
% hObject    handle to h3clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute ClearCallback
handles = ClearCallback(handles, 'h3');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3file3_Callback(~, ~, ~)
% hObject    handle to h3file3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3file3_CreateFcn(hObject, ~, ~)
% hObject    handle to h3file3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3file2_Callback(~, ~, ~)
% hObject    handle to h3file2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3file2_CreateFcn(hObject, ~, ~)
% hObject    handle to h3file2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2file1_Callback(~, ~, ~)
% hObject    handle to h2file1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2file1_CreateFcn(hObject, ~, ~)
% hObject    handle to h2file1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2browse1_Callback(hObject, ~, handles)
% hObject    handle to h2browse1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h2', '1');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2angle1_Callback(~, ~, ~)
% hObject    handle to h2angle1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2angle1_CreateFcn(hObject, ~, ~)
% hObject    handle to h2angle1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2browse2_Callback(hObject, ~, handles)
% hObject    handle to h2browse2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h2', '2');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2angle2_Callback(~, ~, ~)
% hObject    handle to h2angle2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2angle2_CreateFcn(hObject, ~, ~)
% hObject    handle to h2angle2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2browse3_Callback(hObject, ~, handles)
% hObject    handle to h2browse3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h2', '3');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2angle3_Callback(~, ~, ~)
% hObject    handle to h2angle3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2angle3_CreateFcn(hObject, ~, ~)
% hObject    handle to h2angle3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2file4_Callback(~, ~, ~)
% hObject    handle to h2file4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2file4_CreateFcn(hObject, ~, ~)
% hObject    handle to h2file4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2browse4_Callback(hObject, ~, handles)
% hObject    handle to h2browse4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h2', '4');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2angle4_Callback(~, ~, ~)
% hObject    handle to h2angle4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2angle4_CreateFcn(hObject, ~, ~)
% hObject    handle to h2angle4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2display_Callback(hObject, ~, handles)
% hObject    handle to h2display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('H2 display dropdown changed');

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h2');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2display_CreateFcn(hObject, ~, ~)
% hObject    handle to h2display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2clear_Callback(hObject, ~, handles)
% hObject    handle to h2clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute ClearCallback
handles = ClearCallback(handles, 'h2');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2file3_Callback(~, ~, ~)
% hObject    handle to h2file3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2file3_CreateFcn(hObject, ~, ~)
% hObject    handle to h2file3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2file2_Callback(~, ~, ~)
% hObject    handle to h2file2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2file2_CreateFcn(hObject, ~, ~)
% hObject    handle to h2file2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function figure1_ResizeFcn(hObject, ~, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set units to pixels
set(hObject,'Units','pixels') 

% Loop through each head statistics table
for i = 1:3
    
    % Get table width
    pos = get(handles.(sprintf('h%itable', i)), 'Position') .* ...
        get(handles.(sprintf('uipanel%i', i)), 'Position') .* ...
        get(hObject, 'Position');
    
    % Update column widths to scale to new table size
    set(handles.(sprintf('h%itable', i)), 'ColumnWidth', ...
        {floor(0.50*pos(3)) - 24 floor(0.15*pos(3)) ...
        floor(0.15*pos(3)) floor(0.2*pos(3))});
end

% Clear temporary variables
clear pos;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function print_button_Callback(~, ~, handles)
% hObject    handle to print_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('Print button selected');

% Execute PrintReport, passing current handles structure as data
PrintReport('Data', handles);
