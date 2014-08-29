function [profiles, FWHM, X1, X2] = ParseSNCProfiles(file, angle)
% ParseProfiles extracts the MLC Strips from a SNC ASCII file export and
% computes the FWHM and FWHM-defined X1 and X2 field edges for each
% profile.  This function is called by AnalyzeMLCProfiles; see the readme
% for more information on data acquisition.
%
% This function requires two inputs, a string indicating the file to be
% opened and a number indicating the gantry angle (2 = 0, 3 = 90, 4 = 180,
% and 5 = 270 degrees).  The gantry angle is used to assume the profiler
% orientation and compute the FWHM and field edges along the correct
% profiler axis, assuming that the profiler Y axis is positioned along the
% MLC X axis.
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

%% Load measured data
% Open a file handle to the ured data
fid = fopen(file, 'r');

% While the end-of-file has not been reached
while ~feof(fid)
    % Retrieve the next line in the file
    tline = fgetl(fid);
    
    % Search for the X Axis data
    C = regexp(tline, 'Detector ID	X Axis Position');
    
    % If found
    if size(C,1) > 0 
        % Extract all X axis positions (detector position and 6 ured
        % profiles)
        measX = textscan(fid, '%f %f %f %f %f %f %f');
    end
    
    % Search for the Y Axis data
    C = regexp(tline, 'Detector ID	Y Axis Position');
    
    % If found
    if size(C,1) > 0 
        % Extract all X axis positions (detector position and 6 ured
        % profiles)
        measY = textscan(fid, '%f %f %f %f %f %f %f');
        
        % Stop loading the file, as the data was found
        break;
    end
end

% Close file handle
fclose(fid);

% Convert positions from cm to mm
measX{1} = measX{1} * 10;
measY{1} = measY{1} * 10;

% Convert dose from cGy to Gy
for i = 1:6
   measX{i+1} = measX{i+1} / 100;
   measY{i+1} = measY{i+1} / 100;
end

%% Process each measured profile
% Initialize ured profile data
X1 = zeros(1,6);
X2 = zeros(1,6);
FWHM = zeros(1,6);

% Loop through each profile
for i = 1:6   
    % Select X or Y data depending on angle
    switch angle
        % 0 degrees
        case 2
            x = measY{1};
            y = measY{i+1};
            profiles = measY;
        % 90 degrees
        case 3
            x = measY{1};
            y = measY{i+1};
            profiles = measY;
        % 180 degrees
        case 4
            x = -measY{1};
            y = measY{i+1};
            profiles = measY;
        % 270 degrees
        case 5
            x = -measY{1};
            y = measY{i+1};
            profiles = measY;
    end
    
    % Resort data ascending
    [x, I] = sort(x);
    y = y(I);
    
    % Determine location and value of maximum
    [C, I] = max(y);
    
    % Search left side for half-maximum value
    for j = 1:I-1
        if y(j) == C/2
            X1(i) = y(j);
            break;
        elseif y(j) < C/2 && y(j+1) > C/2
            X1(i) = interp1(y(j:j+1), x(j:j+1), C/2, 'linear');
            break;
        end
    end
    
    % Search right side for half-maximum value
    for j = I:size(y,1)-1
        if y(j) == C/2
            X2(i) = y(j);
            break;
        elseif y(j) > C/2 && y(j+1) < C/2
            X2(i) = interp1(y(j:j+1), x(j:j+1), C/2, 'linear');
            break;
        end
    end   
    
    % Compute width
    FWHM(i) = X2(i) - X1(i);
end

% Sort measured data
[X1, I] = sort(X1);
X2 = X2(I);
FWHM = FWHM(I);