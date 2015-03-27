function varargout = UnitTest(varargin)
% UnitTest executes the unit tests for this application, and can be called 
% either independently (when testing just the latest version) or via 
% UnitTestHarness (when testing for regressions between versions).  Either 
% two or three input arguments can be passed to UnitTest as described 
% below.
%
% The following variables are required for proper execution: 
%   varargin{1}: string containing the path to the main function
%   varargin{2}: string containing the path to the test data
%   varargin{3} (optional): structure containing reference data to be used
%       for comparison.  If not provided, it is assumed that this version
%       is the reference and therefore all comparison tests will "Pass".
%
% The following variables are returned upon succesful completion when input 
% arguments are provided:
%   varargout{1}: cell array of strings containing preamble text that
%       summarizes the test, where each cell is a line. This text will
%       precede the results table in the report.
%   varargout{2}: n x 3 cell array of strings containing the test ID in
%       the first column, name in the second, and result (Pass/Fail or 
%       numerical values typically) of the test in the third.
%   varargout{3}: cell array of strings containing footnotes referenced by
%       the tests, where each cell is a line.  This text will follow the
%       results table in the report.
%   varargout{4} (optional): structure containing reference data created by 
%       executing this version.  This structure can be passed back into 
%       subsequent executions of UnitTest as varargin{3} to compare results
%       between versions (or to a priori validated reference data).
%
% The following variables are returned when no input arguments are
% provided (required only if called by UnitTestHarness):
%   varargout{1}: string containing the application name (with .m 
%       extension)
%   varargout{2}: string containing the path to the version application 
%       whose results will be used as reference
%   varargout{3}: 1 x n cell array of strings containing paths to the other 
%       applications which will be tested
%   varargout{4}: 2 x m cell array of strings containing the name of each 
%       test suite (first column) and path to the test data (second column)
%   varargout{5}: string containing the path and name of report file (will 
%       be appended by _R201XX.md based on the MATLAB version)
%
% Below is an example of how this function is used:
%
%   % Declare path to application and test suite
%   app = '/path/to/application';
%   test = '/path/to/test/data/';
%
%   % Load reference data from .mat file
%   load('referencedata.mat', '-mat', reference);
%
%   % Execute unit test, printing the test results to stdout
%   UnitTest(app, test, reference);
%
%   % Execute unit test, storing the test results
%   [preamble, table, footnotes] = UnitTest(app, test, reference);
%
%   % Execute unit test again but without reference data, this time storing 
%   % the output from UnitTest as a new reference file
%   [preamble, table, footnotes, newreference] = UnitTest(app, test);
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

%% Return Application Information
% If UnitTest was executed without input arguments
if nargin == 0
    
    % Declare the application filename
    varargout{1} = 'AnalyzeMLCProfiles.m';

    % Declare current version directory
    varargout{2} = './';

    % Declare prior version directories
    varargout{3} = {
        '../viewray_mlc-1.0'
%       '../viewray_mlc-1.1'
        '../viewray_mlc-1.1.1'
    };

    % Declare location of test data. Column 1 is the name of the 
    % test suite, column 2 is the absolute path to the file(s)
    varargout{4} = {
        'AP'                '../test_data/Head1_G90.txt'
        'PA (thru couch)'   '../test_data/Head2_G180.txt'
        'PA (no couch)'     '../test_data/Head3_G270_through_back_of_ICP.txt'
    };

    % Declare name of report file (will be appended by _R201XX.md based on 
    % the MATLAB version)
    varargout{5} = '../test_reports/unit_test';
    
    % Return to invoking function
    return;
end

%% Initialize Unit Testing
% Initialize static test result text variables
pass = 'Pass';
fail = 'Fail';
unk = 'N/A';

% Initialize preamble text
preamble = {
    '| Input Data | Value |'
    '|------------|-------|'
};

% Initialize results cell array
results = cell(0,3);

% Initialize footnotes cell array
footnotes = cell(0,1);

% Initialize reference structure
if nargin == 3
    reference = varargin{3};
else
    reference = struct;
end

% Add snc_extract/gamma submodule to search path
addpath('./snc_extract/gamma');

% Check if MATLAB can find CalcGamma (used by the unit tests later)
if exist('CalcGamma', 'file') ~= 2
    
    % If not, throw an error
    Event('The CalcGamma submodule does not exist in the path.', ...
        'ERROR');
end

%% TEST 1/2: Application Loads Successfully, Time
%
% DESCRIPTION: This unit test attempts to execute the main application
%   executable and times how long it takes.  This test also verifies that
%   errors are present if the required submodules do not exist and that the
%   print report button is initially disabled.
%
% RELEVANT REQUIREMENTS: U001, F001, F024, F030, P001
%
% INPUT DATA: No input data required
%
% CONDITION A (+): With the appropriate submodules present, opening the
%   application andloads without error in the required time
%
% CONDITION B (-): With the snc_extract submodule missing, opening the 
%   application throws an error
%
% CONDITION C (-): The print report button is disabled
%   following application load (the positive condition for this requirement
%   is tested during unit test 25).
%
% CONDITION D (+): Gamma criteria are set upon application load

% Change to directory of version being tested
cd(varargin{1});

% Start with fail
pf = fail;

% Attempt to open application without submodule
try
    AnalyzeMLCProfiles('unitParseSNCprm');

% If it fails to open, the test passed
catch
    pf = pass;
end

% Close all figures
close all force;

% Attempt to open application without statistics toolbox
try
    AnalyzeMLCProfiles('unitCorr');

% If it fails to open, the test passed
catch
    pf = pass;
end

% Close all figures
close all force;

% Open application again with submodule, this time storing figure handle
try
    t = tic;
    h = AnalyzeMLCProfiles;
    time = sprintf('%0.1f sec', toc(t));

% If it fails to open, the test failed  
catch
    pf = fail;
end

% Retrieve guidata
data = guidata(h);

% Set unit test flag to 1 (to avoid uigetfile/questdlg/user input)
data.unitflag = 1; 

% Compute numeric version (equal to major * 10000 + minor * 100 + bug)
c = regexp(data.version, '^([0-9]+)\.([0-9]+)\.*([0-9]*)', 'tokens');
version = str2double(c{1}{1})*10000 + str2double(c{1}{2})*100 + ...
    max(str2double(c{1}{3}),0);

% Add version to results
results{size(results,1)+1,1} = 'ID';
results{size(results,1),2} = 'Test Case';
results{size(results,1),3} = sprintf('Version&nbsp;%s', data.version);

% If version < 1.1.2, revert to pass (ParseSNCprm unit test was not
% available)
if version < 010102
    pf = pass;
end

% Update guidata
guidata(h, data);

% If version >= 1.1.0
if version >= 010100
    
    % Verify that the print button is disabled
    if ~strcmp(get(data.print_button, 'enable'), 'off')
        pf = fail;
    end
end

% Verify that Gamma criteria exist
if ~isfield(data, 'abs') || ~isfield(data, 'dta') || data.abs == 0 || ...
        data.dta == 0
    pf = fail;
end

% Add application load result
results{size(results,1)+1,1} = '1';
results{size(results,1),2} = 'Application Loads Successfully';
results{size(results,1),3} = pf;

% Add application load time
results{size(results,1)+1,1} = '2';
results{size(results,1),2} = 'Application Load Time';
results{size(results,1),3} = time;

%% TEST 3/4: Code Analyzer Messages, Cumulative Cyclomatic Complexity
%
% DESCRIPTION: This unit test uses the checkcode() MATLAB function to check
%   each function used by the application and return any Code Analyzer
%   messages that result.  The cumulative cyclomatic complexity is also
%   computed for each function and summed to determine the total
%   application complexity.  Although this test does not reference any
%   particular requirements, it is used during development to help identify
%   high risk code.
%
% RELEVANT REQUIREMENTS: none 
%
% INPUT DATA: No input data required
%
% CONDITION A (+): Report any code analyzer messages for all functions
%   called by FieldUniformity
%
% CONDITION B (+): Report the cumulative cyclomatic complexity for all
%   functions called by FieldUniformity

% Search for required functions
fList = matlab.codetools.requiredFilesAndProducts('AnalyzeMLCProfiles.m');

% Initialize complexity and messages counters
comp = 0;
mess = 0;

% Loop through each dependency
for i = 1:length(fList)
    
    % Execute checkcode
    inform = checkcode(fList{i}, '-cyc');
    
    % Loop through results
    for j = 1:length(inform)
       
        % Check for McCabe complexity output
        c = regexp(inform(j).message, ...
            '^The McCabe complexity .+ is ([0-9]+)\.$', 'tokens');
        
        % If regular expression was found
        if ~isempty(c)
            
            % Add complexity
            comp = comp + str2double(c{1});
            
        else
            
            % If not an invalid code message
            if ~strncmp(inform(j).message, 'Filename', 8)
                
                % Log message
                Event(sprintf('%s in %s', inform(j).message, fList{i}), ...
                    'CHCK');

                % Add as code analyzer message
                mess = mess + 1;
            end
        end
    end
end

% Add code analyzer messages counter to results
results{size(results,1)+1,1} = '3';
results{size(results,1),2} = 'Code Analyzer Messages';
results{size(results,1),3} = sprintf('%i', mess);

% Add complexity results
results{size(results,1)+1,1} = '4';
results{size(results,1),2} = 'Cumulative Cyclomatic Complexity';
results{size(results,1),3} = sprintf('%i', comp);

%% TEST 5: Reference Data Loads Successfully
%
% DESCRIPTION: This unit test verifies that the reference data load
% subfunction runs without error.
%
% RELEVANT REQUIREMENTS: F002
%
% INPUT DATA: file names of reference profiles.  In version 1.1.0 and
%   later, this is stored in handles.references.  In earlier versions the
%   file name is written into the function call.
%
% CONDITION A (+): Execute LoadProfilerReference (version 1.1.0 and later)
%   or LoadReferenceProfiles with a valid reference DICOM file and verify
%   that the application executes correctly.
%
% CONDITION B (-): Execute the same function with invalid inputs and verify
%   that the function fails.

% Retrieve guidata
data = guidata(h);
    
% If version >= 1.1.0
if version >= 010100

    % Execute LoadProfilerReference in try/catch statement
    try
        pf = pass;
        LoadProfilerDICOMReference(data.APfiles, '90');
        LoadProfilerDICOMReference(data.PANCfiles, '90');
        LoadProfilerDICOMReference(data.PATCfiles, '90');
    
    % If it errors, record fail
    catch
        pf = fail;
    end
  
    % Execute LoadProfilerReference with no inputs in try/catch statement
    try
        LoadProfilerDICOMReference();
        pf = fail;
    catch
        % If it fails, test passed
    end
    
    % Execute LoadProfilerReference with one incorrect input in try/catch 
    % statement
    try
        LoadProfilerDICOMReference({'asd'});
        pf = fail;
    catch
        % If it fails, test passed
    end
    
% If version < 1.1.0    
else
    
    % Execute LoadReferenceProfiles in try/catch statement
    try
        pf = pass;
        LoadReferenceProfiles(data);
    
    % If it errors, record fail
    catch
        pf = fail;
    end
end

% Add success message
results{size(results,1)+1,1} = '5';
results{size(results,1),2} = 'Reference Data Loads Successfully';
results{size(results,1),3} = pf;

%% TEST 6/7/8: Reference Data Identical
%
% DESCRIPTION: This unit test verifies that the MLC-X axis data extracted 
%   from the reference data is identical to its expected value.  For this 
%   test equivalency is defined as being within 1%/0.1mm using a Gamma 
%   analysis.
%
% RELEVANT REQUIREMENTS: F002, C014, C015, C016
%
% INPUT DATA: Validated expected AP (data.APreferences.ydata), PA no couch
%   (data.PANCreferences.panc.ydata), and PA thru couch 
%   (data.PANCreferences.patc.ydata) data
%
% CONDITION A (+): The extracted reference data matches expected MLC X data
%   exactly (version 1.1.0 and later) or within 1%/0.1 mm.
%
% CONDITION B (-): Modified reference data no longer matches expected MLC X
%   data.

% Retrieve guidata
data = guidata(h);
    
% If version >= 1.1.0
if version >= 010100
    
    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.APreferences.ydata, reference.APreferences.ydata)
            appf = pass;

        % Otherwise, it failed
        else
            appf = fail;
        end
        
        % Modify refdata
        data.APreferences.ydata(1,1) = 0;
        
        % Verify current value now fails
        if isequal(data.APreferences.ydata, ...
                reference.APreferences.ydata)
            appf = fail;
        end
        
        % If current value equals the reference
        if isequal(data.PANCreferences.ydata, ...
                reference.PANCreferences.ydata)
            pancpf = pass;

        % Otherwise, it failed
        else
            pancpf = fail;
        end
        
        % Modify refdata
        data.PANCreferences.ydata(1,1) = 0;
        
        % Verify current value now fails
        if isequal(data.PANCreferences.ydata, ...
                reference.PANCreferences.ydata)
            pancpf = fail;
        end
        
        % If current value equals the reference
        if isequal(data.PATCreferences.ydata, ...
                reference.PATCreferences.ydata)
            patcpf = pass;

        % Otherwise, it failed
        else
            patcpf = fail;
        end
        
        % Modify refdata
        data.PATCreferences.ydata(1,1) = 0;
        
        % Verify current value now fails
        if isequal(data.PATCreferences.ydata, ...
                reference.PATCreferences.ydata)
            patcpf = fail;
        end
        
    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.APreferences = data.APreferences;
        reference.PANCreferences = data.PANCreferences;
        reference.PATCreferences = data.PATCreferences;

        % Assume pass
        appf = pass;
        pancpf = pass;
        patcpf = pass;

        % Add reference profiles to preamble
%         preamble{length(preamble)+1} = ['| AP Reference&nbsp;Data | ', ...
%             data.APfiles{1}, '<br>', strjoin(data.APfiles(2:end), ...
%             '<br>'), ' |'];
%         preamble{length(preamble)+1} = ['| PANC Reference&nbsp;Data | ', ...
%             data.PANCfiles{1}, '<br>', strjoin(data.PANCfiles(2:end), ...
%             '<br>'), ' |'];
%         preamble{length(preamble)+1} = ['| PATC Reference&nbsp;Data | ', ...
%             data.PATCfiles{1}, '<br>', strjoin(data.PATCfiles(2:end), ...
%             '<br>'), ' |'];
    end

% If version < 1.1.0    
else
    
    % If reference data exists
    if nargin == 3
        
        appf = unk;
        pancpf = unk;
        patcpf = unk;
        
    % Otherwise, no reference data exists
    else
        appf = unk;
        pancpf = unk;
        patcpf = unk;
    end
end
       
% Add result
results{size(results,1)+1,1} = '6';
results{size(results,1),2} = 'AP Reference Data within 1%/0.1 mm';
results{size(results,1),3} = appf;

% Add result
results{size(results,1)+1,1} = '7';
results{size(results,1),2} = 'PANC Reference Data within 1%/0.1 mm';
results{size(results,1),3} = pancpf;

% Add result
results{size(results,1)+1,1} = '8';
results{size(results,1),2} = 'PATC Reference Data within 1%/0.1 mm';
results{size(results,1),3} = patcpf;

%% TEST 9/10: H1 Browse Loads Data Successfully/Load Time
%
% DESCRIPTION: This unit test verifies a callback exists for the H1 browse
%   button and executes it under unit test conditions (such that a file 
%   selection dialog box is skipped), simulating the process of a user
%   selecting input data.  The time necessary to load the file is also
%   checked.
%
% RELEVANT REQUIREMENTS: U002, U003, U005, U006, F003, F004, F006, F010, 
%   P002, C012
%
% INPUT DATA: ASCII file to be loaded (varargin{2})
%
% CONDITION A (+): The callback for the H1 browse button can be executed
%   without error when a valid filename is provided
%
% CONDITION B (-): The callback will throw an error if an invalid filename
%   is provided
%
% CONDITION C (+): The callback will return without error when no filename
%   is provided
%
% CONDITION D (+): Upon receiving a valid filename, the ASCII data will be
%   automatically processed, storing a structure to data.h1results
%
% CONDITION E (+): Upon receiving a valid filename, the filename will be
%   displayed on the user interface
%
% CONDITION F (+): Report the time taken to execute the browse callback and 
%   parse the data
%
% CONDITION G (-): If measured data is provided where the FWHM is too close
%   to the edge, the application will return a FWHM of 0. 
%
% CONDITION H (+): Correlation data will exist in data.h1results.corr

% Retrieve guidata
data = guidata(h);
    
% Retrieve callback to H1 browse button
callback = get(data.h1browse1, 'Callback');

% Set empty unit path/name
data.unitpath = '';
data.unitname = '';

% Force specific gamma criteria (3%/1mm)
data.abs = 3;

% If version >= 1.1.0
if version >= 010100
    
    % Store DTA in cm
    data.dta = 0.1;
else
    
    % Store DTA in mm
    data.dta = 1;
end

% Add gamma criteria to preamble
preamble{length(preamble)+1} = '| Gamma Criteria | 3%/1mm |';

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement
try
    pf = pass;
    callback(data.h1browse1, data);

% If it errors, record fail
catch
    pf = fail;
end

% Set invalid unit path/name
data.unitpath = '/';
data.unitname = 'asd';

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement (this should fail)
try
    callback(data.h1browse1, data);
    pf = fail;
    
% If it errors
catch
	% The test passed
end

% Set unit path/name
[path, name, ext] = fileparts(varargin{2});
data.unitpath = path;
data.unitname = [name, ext];

% Add file name to preamble
preamble{length(preamble)+1} = ...
    ['| Input&nbsp;Data | ', data.unitname, ' | '];

% Search for the gantry angle in the name 
tokens = regexp(name, 'G([0-9]+)', 'tokens');
if ~isempty(tokens)
    
    % Set gantry angle based on file name specifier
    data.unitgantry = floor(str2double(tokens{1})/90) + 1;

% Otherwise assume angle is 90
else
    data.unitgantry = 2;
end

% Add file name to preamble
preamble{length(preamble)+1} = ...
    sprintf('| Gantry Angle | %i | ', 90*(data.unitgantry - 1));

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement
try
    t = tic;
    callback(data.h1browse1, data);

% If it errors, record fail
catch
    pf = fail;
end

% Record completion time
time = sprintf('%0.1f sec', toc(t));

% Retrieve guidata
data = guidata(h);

% Verify that the file name matches the input data
if strcmp(pf, pass) && strcmp(data.h1file1.String, fullfile(varargin{2}))
    pf = pass;
else
    pf = fail;
end

% If version >= 1.1.0, execute SRS-F010 test
if version >= 010100
    
    % Load the SNC profiler data
    txt = ParseSNCtxt(data.unitpath, data.unitname);

    % Adjust the data such that the X axis profile is uniform (no edges)
    txt.ydata(:, 2) = ones(size(txt.ydata,1), 1);

    % Run AnalyzeProfilerFields with bad X axis data
    result = AnalyzeProfilerFields(txt);

    % Verify FWHM is zero
    if result.yfwhm(1) ~= 0
        pf = fail;
    end

    % Adjust the data such that the X axis profile is uniform (no edges)
    txt.ydata(2:end, 2) = ones(size(txt.ydata,1)-1, 1) * 3;

    % Run AnalyzeProfilerFields with bad X axis data
    result = AnalyzeProfilerFields(txt);

    % Verify FWHM is zero
    if result.yfwhm ~= 0
        pf = fail;
    end

    % Clear temporary variables
    clear txt result;
end

% Add result
results{size(results,1)+1,1} = '9';
results{size(results,1),2} = 'H1 Browse 1 Loads Data Successfully';
results{size(results,1),3} = pf;

% Add result
results{size(results,1)+1,1} = '10';
results{size(results,1),2} = 'Browse Callback Load Time';
results{size(results,1),3} = time;

%% TEST 11/12: MLC X field edges/FWHM/differences correct
%
% DESCRIPTION: This unit test verifies that the field edges and FWHM for
%   the measured and reference profiles, and resulting differences, are
%   computed correctly.
%
% RELEVANT REQUIREMENTS: F007, F008, F009, F011, F012, F013
%
% INPUT DATA: reference.h1X11, reference.h1X21, reference.h1refX11, 
%   reference.h1refX21, reference.h1FWHM1, reference.h1refFWHM1
%
% CONDITION A (+): Computed reference field edges are within 0.1 mm
%
% CONDITION B (+): Computed measured field edges are within 0.1 mm
%
% CONDITION C (+): Computed reference field widths are within 0.1 mm
%
% CONDITION D (+): Computed measured field widths are within 0.1 mm

% Retrieve guidata
data = guidata(h);

% In version >= 1.1.0, values are stored in cm
if version >= 010100
    
    % If reference data exists
    if nargin == 3

        % If the values are within 0.1 mm of the reference
        if max(abs(data.h1X11 - reference.h1X11)) < 0.01 && ...
                max(abs(data.h1X21 - reference.h1X21)) < 0.01 && ...
                max(abs(data.h1refX11 - reference.h1refX11)) < 0.01 && ...
                max(abs(data.h1refX21 - reference.h1refX21)) < 0.01
            
            % The test passes
            pf = pass;
        
        % Otherwise, the test fails
        else
            pf = fail;
        end
        
    % Otherwise, set reference data    
    else
        
        % Store current values as reference
        reference.h1X11 = data.h1X11;
        reference.h1X21 = data.h1X21;
        reference.h1refX11 = data.h1refX11;
        reference.h1refX21 = data.h1refX21;
        pf = pass;
    end
   
% Otherwise, values are in mm
else
    
    % If reference data exists
    if nargin == 3
    
        % If the values are within 0.1 mm of the reference
        if max(abs(data.h1X11/10 - reference.h1X11')) < 0.01 && ...
                max(abs(data.h1X21/10 - reference.h1X21')) < 0.01 && ...
                max(abs(data.h1refX11/10 - reference.h1refX11')) < 0.01 && ...
                max(abs(data.h1refX21/10 - reference.h1refX21')) < 0.01
            
            % The test passes
            pf = pass;
        
        % Otherwise, the test fails
        else
            pf = fail;
        end
            
    % Otherwise, set reference data
    else
        
        % Store current values in cm as reference
        reference.h1X11 = data.h1X11'/10;
        reference.h1X21 = data.h1X21'/10;
        reference.h1refX11 = data.h1refX11'/10;
        reference.h1refX21 = data.h1refX21'/10;
        pf = pass;
    end
end

% Add result
results{size(results,1)+1,1} = '11';
results{size(results,1),2} = 'Field Edges within 0.1 mm';
results{size(results,1),3} = pf;

% In version >= 1.1.0, values are stored in cm
if version >= 010100
    
    % If reference data exists
    if nargin == 3

        % If the values are within 0.1 mm of the reference
        if max(abs(data.h1FWHM1 - reference.h1FWHM1)) < 0.01 && ...
                max(abs(data.h1refFWHM1 - reference.h1refFWHM1)) < 0.01
            
            % The test passes
            pf = pass;
        
        % Otherwise, the test fails
        else
            pf = fail;
        end
      
    % Otherwise, set reference data
    else
        
        % Store current values as reference
        reference.h1FWHM1 = data.h1FWHM1;
        reference.h1refFWHM1 = data.h1refFWHM1;
        pf = pass;
    end
   
% Otherwise, values are in mm
else
    
    % If reference data exists
    if nargin == 3
        
        % If the values are within 0.1 mm of the reference
        if max(abs(data.h1FWHM1/10 - reference.h1FWHM1')) < 0.01 && ...
                max(abs(data.h1refFWHM1/10 - reference.h1refFWHM1')) < 0.01

            % The test passes
            pf = pass;

        % Otherwise, the test fails
        else
            pf = fail;
        end

    % Otherwise, set reference data
    else
        
        % Store current values in cm as reference
        reference.h1FWHM1 = data.h1FWHM1'/10;
        reference.h1refFWHM1 = data.h1refFWHM1'/10;
        pf = pass;
    end
end

% Add result
results{size(results,1)+1,1} = '12';
results{size(results,1),2} = 'Field Widths within 0.1 mm';
results{size(results,1),3} = pf;

%% TEST 13: MLC X Gamma Identical
%
% DESCRIPTION: This unit test compares the Gamma profile computed for the
%   SNC IC Profiler Y-axis to an expected value, using a consistent set of
%   Gamma criteria (3%/1mm) defined in unit test 9/10.  As such, this test
%   verifies that the combination of reference extraction, measured
%   extraction, and Gamma computation all function correctly.
%
% RELEVANT REQUIREMENTS: F025
%
% INPUT DATA: reference.gamma
%
% CONDITION A (+): Computed Y-axis Gamma profile is within 0.1

% Retrieve guidata
data = guidata(h);

% In version >= 1.1.0, gamma is stored a a 2D array
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value is within 0.1 for all profiles
        if max(max(abs(data.h1gamma1(2:end,:) - ...
                reference.gamma(2:end,:)))) < 0.1
            pf = pass;

        % Otherwise the test fails
        else
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.gamma = data.h1gamma1;
        pf = pass;
    end

% Otherwise, values are stored as a cell array
else
    
    % Start with pass
    pf = pass;
    
    % Analyze each cell individually
    for i = 2:length(data.h1gamma1)
       
        % If current value is within 0.1
        if max(abs(data.h1gamma1{i} - reference.gamma(i,:))) >= 0.1
            pf = fail;
        end
    end
end

% Add result
results{size(results,1)+1,1} = '13';
results{size(results,1),2} = 'Gamma within 0.1';
results{size(results,1),3} = pf;

%% TEST 14: Statistics Identical
%
% DESCRIPTION: This unit test compares the statistics displayed on the user
%   interface to a set of expected values.  The statistics compared are the
%   min field edge offsets, max field edge offsets, average field edge 
%   offsets, offsets less than 1 mm, min field width difference, maximum
%   field width differences, average field width differences, and maximum
%   gamma value.  In this manner both the presence of and accuracy of the 
%   statistics are verified.
%
% RELEVANT REQUIREMENTS: U008, U009, U014, F009, F013, F029
%
% INPUT DATA: reference.minX1offsets, reference.maxX1offsets, 
%   reference.avgX1offsets, reference.minX2offsets, reference.maxX2offsets, 
%   reference.avgX2offsets, reference.minbothoffsets, 
%   reference.maxbothoffsets, reference.avgbothoffsets, 
%   reference.minFWHMdiffs, reference.maxFWHMdiffs,
%   reference.avgFWHMdiffs, reference.X1less1, reference.X2less1,
%   reference.bothless1, reference.maxgamma
%
% CONDITION A (+): The minimum X1 offset differences are within 0.1 mm
%
% CONDITION B (-): The minimum X1 offset differences does not equal 0
%
% CONDITION C (+): The maximum X1 offset differences are within 0.1 mm
%
% CONDITION D (-): The maximum X1 offset differences does not equal 0
%
% CONDITION E (+): The average X1 offset differences are within 0.1 mm
%
% CONDITION F (-): The average X1 offset differences does not equal 0
%
% CONDITION G (+): The minimum X2 offset differences are within 0.1 mm
%
% CONDITION H (-): The minimum X2 offset differences does not equal 0
%
% CONDITION I (+): The maximum X2 offset differences are within 0.1 mm
%
% CONDITION J (-): The maximum X2 offset differences does not equal 0
%
% CONDITION K (+): The average X2 offset differences are within 0.1 mm
%
% CONDITION L (-): The average X2 offset differences does not equal 0
%
% CONDITION M (+): The minimum of both offset differences are within 0.1 mm
%
% CONDITION N (-): The minimum of both offset differences does not equal 0
%
% CONDITION O (+): The maximum of both offset differences are within 0.1 mm
%
% CONDITION P (-): The maximum of both offset differences does not equal 0
%
% CONDITION Q (+): The average of both offset differences are within 0.1 mm
%
% CONDITION R (-): The average of both offset differences does not equal 0
%
% CONDITION S (+): The minimum FWHM differences are within 0.1 mm
%
% CONDITION T (-): The minimum FWHM differences does not equal 0
%
% CONDITION U (+): The maximum FWHM differences are within 0.1 mm
%
% CONDITION V (-): The maximum FWHM differences does not equal 0
%
% CONDITION W (+): The average FWHM differences are within 0.1 mm
%
% CONDITION X (-): The average FWHM differences does not equal 0
%
% CONDITION Y (+): The X1 percent less than 1 mm are within 0.1 mm
%
% CONDITION Z (-): The X1 percent less than 1 mm does not equal 0
%
% CONDITION AA (+): The X2 percent less than 1 mm are within 0.1 mm
%
% CONDITION AB (-): The X2 percent less than 1 mm does not equal 0
%
% CONDITION AC (+): The X1 & X2 percent less than 1 mm are within 0.1 mm
%
% CONDITION AD (-): The X1 & X2 percent less than 1 mm does not equal 0
%
% CONDITION AE (+): The max gamma index is within 0.1 mm
%
% CONDITION AF (-): The max gamma index does not equal 0

% Retrieve guidata
data = guidata(h);

% If reference data exists
if nargin == 3

    % If current value equals the reference (within 0.1 mm)
    if abs(cell2mat(textscan(data.h1table.Data{1,2}, '%f')) - ...
            cell2mat(reference.minX1offsets)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{1,3}, '%f')) - ...
            cell2mat(reference.minX2offsets)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{1,4}, '%f')) - ...
            cell2mat(reference.minbothoffsets)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{2,2}, '%f')) - ...
            cell2mat(reference.maxX1offsets)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{2,3}, '%f')) - ...
            cell2mat(reference.maxX2offsets)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{2,4}, '%f')) - ...
            cell2mat(reference.maxbothoffsets)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{3,2}, '%f')) - ...
            cell2mat(reference.avgX1offsets)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{3,3}, '%f')) - ...
            cell2mat(reference.avgX2offsets)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{3,4}, '%f')) - ...
            cell2mat(reference.avgbothoffsets)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{4,2}, '%f')) - ...
            cell2mat(reference.X1less1)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{4,3}, '%f')) - ...
            cell2mat(reference.X2less1)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{4,4}, '%f')) - ...
            cell2mat(reference.bothless1)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{5,4}, '%f')) - ...
            cell2mat(reference.minFWHMdiffs)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{6,4}, '%f')) - ...
            cell2mat(reference.maxFWHMdiffs)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{7,4}, '%f')) - ...
            cell2mat(reference.avgFWHMdiffs)) < 0.1 && ...
            abs(cell2mat(textscan(data.h1table.Data{9,4}, '%f')) - ...
            cell2mat(reference.maxgamma)) < 0.1
        pf = pass;

    % Otherwise, the test fails
    else
        pf = fail;
    end

    % If current value equals 0, the test fails
    z{1} = 0;
    if isequal(textscan(data.h1table.Data{1,2}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{1,3}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{1,4}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{2,2}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{2,3}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{2,4}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{3,2}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{3,3}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{3,4}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{4,2}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{4,3}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{4,4}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{5,4}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{6,4}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{7,4}, '%f'), z) || ...
            isequal(textscan(data.h1table.Data{9,4}, '%f'), z)
        pf = fail;
    end
    clear z;

% Otherwise, no reference data exists
else
    reference.minX1offsets = textscan(data.h1table.Data{1,2}, '%f');
    reference.minX2offsets = textscan(data.h1table.Data{1,3}, '%f');
    reference.minbothoffsets = textscan(data.h1table.Data{1,4}, '%f');
    reference.maxX1offsets = textscan(data.h1table.Data{2,2}, '%f');
    reference.maxX2offsets = textscan(data.h1table.Data{2,3}, '%f');
    reference.maxbothoffsets = textscan(data.h1table.Data{2,4}, '%f');
    reference.avgX1offsets = textscan(data.h1table.Data{3,2}, '%f');
    reference.avgX2offsets = textscan(data.h1table.Data{3,3}, '%f');
    reference.avgbothoffsets = textscan(data.h1table.Data{3,4}, '%f');
    reference.X1less1 = textscan(data.h1table.Data{4,2}, '%f');
    reference.X2less1 = textscan(data.h1table.Data{4,3}, '%f');
    reference.bothless1 = textscan(data.h1table.Data{4,4}, '%f');
    reference.minFWHMdiffs = textscan(data.h1table.Data{5,4}, '%f');
    reference.maxFWHMdiffs = textscan(data.h1table.Data{6,4}, '%f');
    reference.avgFWHMdiffs = textscan(data.h1table.Data{7,4}, '%f');
    reference.maxgamma = textscan(data.h1table.Data{9,4}, '%f');
    pf = pass;
end

% Add result with footnote
results{size(results,1)+1,1} = '14';
results{size(results,1),2} = 'Statistics within 0.1 mm';
results{size(results,1),3} = pf;

%% Finish up
% Close all figures
close all force;

% If no return variables are present, print the results
if nargout == 0
    
    % Print preamble
    for j = 1:length(preamble)
        fprintf('%s\n', preamble{j});
    end
    fprintf('\n');
    
    % Loop through each table row
    for j = 1:size(results,1)
        
        % Print table row
        fprintf('| %s |\n', strjoin(results(j,:), ' | '));
       
        % If this is the first column
        if j == 1
            
            % Also print a separator row
            fprintf('|%s\n', repmat('----|', 1, size(results,2)));
        end

    end
    fprintf('\n');
    
    % Print footnotes
    for j = 1:length(footnotes) 
        fprintf('%s<br>\n', footnotes{j});
    end
    
% Otherwise, return the results as variables    
else

    % Store return variables
    if nargout >= 1; varargout{1} = preamble; end
    if nargout >= 2; varargout{2} = results; end
    if nargout >= 3; varargout{3} = footnotes; end
    if nargout >= 4; varargout{4} = reference; end
end
