function varargout = UpdateDisplay(varargin)
% UpdateDisplay is called by AnalyzeMLCProfiles when initializing or
% updating a plot display.  When called with no input arguments, this
% function returns a string cell array of available plots that the user can
% choose from.  When called with two input arguments, the first being a GUI
% handles structure and the second a string indicating the head number (h1,
% h2, or h3), this function will look for measured and reference data
% (loaded by ParseSNCProfiles and LoadReferenceProfiles, respectively) and
% update the display based on the display menu UI component.
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
    
% Specify plot options and order
plotoptions = {
    ''
    'Field Edge Offsets'
    'Field Width Differences'
    'Angle 1 Profiles'
    'Angle 2 Profiles'
    'Angle 3 Profiles'
    'Angle 4 Profiles'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the plot options
    varargout{1} = plotoptions;
    
    % Stop execution
    return;
    
% Otherwise, if 2, set the input variables and update the plot
elseif nargin == 2
    
    % Set input variables
    handles = varargin{1};
    head = varargin{2};
    
    % Log start
    Event('Updating plot display');
    tic;
    
% Otherwise, throw an error
else 
    Event('Incorrect number of inputs to UpdateDisplay', 'ERROR');
end

% Clear and set reference to axis
cla(handles.([head, 'axes']), 'reset');
axes(handles.([head, 'axes']));
Event(['Current plot set to ', head, 'axes']);

% Turn off the display while building
set(allchild(handles.([head, 'axes'])), 'visible', 'off'); 
set(handles.([head, 'axes']), 'visible', 'off');

% Define a color map for displaying multiple datasets and initialize
% counter
cmap = lines(16);
c = 0;

% Execute code block based on display GUI item value
switch get(handles.([head, 'display']),'Value')
    
    % If the user selected Field Edge Offsets
    case 2
        % Log selection
        Event('Field Edge Offset selected for display');
        
        % Initialize empty cell array for legend entries
        names = cell(0);
        
        % Hold rendering for overlapping plots
        hold on;
        
        % Loop through each dataset
        for i = 1:4
            
            % If the dataset exists
            if ~strcmp(get(handles.(sprintf('%sfile%i', head, i)), 'String'), '') ...
                    && ~isempty(get(handles.(sprintf('%sfile%i', head, i)), 'String'))
                
                % Display the axes
                set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
                set(handles.([head, 'axes']), 'visible', 'on'); 
                
                % Increment the counter
                c = c + 1;
                
                % Plot the X1 field edge difference from reference
                plot(handles.(sprintf('%srefX1%i', head, i)), ...
                    handles.(sprintf('%sX1%i', head, i)) - ...
                    handles.(sprintf('%srefX1%i', head, i)), '-o', ...
                    'Color', cmap(c,:));

                % Add legend entry for X1
                names{c} = sprintf('%i X1', ...
                    (get(handles.(sprintf('%sangle%i', head, i)), ...
                    'Value') - 2) * 90);
                
                % Increment the counter
                c = c + 1;
                
                % Plot the X2 field edge difference from reference
                plot(handles.(sprintf('%srefX2%i', head, i)), ...
                    handles.(sprintf('%sX2%i', head, i)) - ...
                    handles.(sprintf('%srefX2%i', head, i)), '-o', ...
                    'Color', cmap(c,:));

                % Add legend entry for X2
                names{c} = sprintf('%i X2', ...
                    (get(handles.(sprintf('%sangle%i', head, i)), ...
                    'Value') - 2) * 90);

            end 
        end
        
        % Finish specifying plot
        hold off;
        xlabel('Field Edge (mm)');
        xlim([-125 125]);
        ylabel('Field Edge Difference (mm)');
        ylim([-3 3]);
        if c > 0
            legend(names);
        end
        grid on;
        
    % If the user selected FWHM differences
    case 3
        % Log selection
        Event('FWHM differences selected for display');
        
        % Initialize empty cell array for legend entries
        names = cell(0);
        
        % Hold rendering for overlapping plots
        hold on;
        
        % Loop through each dataset
        for i = 1:4
            
            % If the dataset exists
            if ~strcmp(get(handles.(sprintf('%sfile%i', head, i)), 'String'), '') ...
                    && ~isempty(get(handles.(sprintf('%sfile%i', head, i)), 'String'))
                
                % Display the axes
                set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
                set(handles.([head, 'axes']), 'visible', 'on'); 
                
                % Increment the counter
                c = c + 1;
                
                % Plot the FWHM difference from reference
                plot(handles.(sprintf('%sFWHM%i', head, i)) - ...
                    handles.(sprintf('%srefFWHM%i', head, i)), '-o', ...
                    'Color', cmap(c,:));

                 % Add legend entry
                names{c} = sprintf('%i', ...
                    (get(handles.(sprintf('%sangle%i', head, i)), ...
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
    
    % If the user chooses to view the dataset 1 profiles 
    case 4
        % Log selection
        Event('Angle 1 profiles selected for display');
        
        % If the dataset exists
        if ~strcmp(get(handles.([head, 'file1']), 'String'), '') ...
                && ~isempty(get(handles.([head, 'file1']), 'String'))
        
            % Hold rendering for overlapping plots
            hold on;
            
            % Loop through each reference profile
            for i = 1:length(handles.([head, 'refprofiles1']))
                
                % Plot normalized reference data
                plot(handles.([head, 'refprofiles1']){i}.profile(1,:), ...
                    handles.([head, 'refprofiles1']){i}.profile(2,:) / ...
                    max(handles.([head, 'refprofiles1']){i}.profile(2,:)), 'blue');
                
                % Plot normalized measured data
                plot(handles.([head, 'profiles1']){1}, ...
                    handles.([head, 'profiles1']){i+1} / ...
                    max(handles.([head, 'profiles1']){i+1}), 'red');
                
                % Plot gamma
                plot(handles.([head, 'gamma1']){1}, ...
                    handles.([head, 'gamma1']){i+1}, ...
                    'Color', [0 0.75 0.75]);
            end
            
            % Add legend
            legend('Reference', 'Measured', 'Gamma', 'location', 'SouthEast');
            
            % Finish specifying plot
            hold off; 
            ylabel('Normalized Dose');
            ylim([0 1.05]);
            xlabel('MLC X Position (mm)');
            xlim([-150 150]);
            grid on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
        end
        
    % If the user chooses to view the dataset 2 profiles 
    case 5
        % Log selection
        Event('Angle 2 profiles selected for display');
        
        % If the dataset exists
        if ~strcmp(get(handles.([head, 'file2']), 'String'), '') ...
                && ~isempty(get(handles.([head, 'file2']), 'String'))
        
            % Hold rendering for overlapping plots
            hold on;
            
            % Loop through each reference profile
            for i = 1:length(handles.([head, 'refprofiles2']))
                
                % Plot normalized reference data
                plot(handles.([head, 'refprofiles2']){i}.profile(1,:), ...
                    handles.([head, 'refprofiles2']){i}.profile(2,:) / ...
                    max(handles.([head, 'refprofiles2']){i}.profile(2,:)), 'blue');
                
                % Plot normalized measured data
                plot(handles.([head, 'profiles2']){1}, ...
                    handles.([head, 'profiles2']){i+1} / ...
                    max(handles.([head, 'profiles2']){i+1}), 'red');
                
                % Plot gamma
                plot(handles.([head, 'gamma2']){1}, ...
                    handles.([head, 'gamma2']){i+1}, ...
                    'Color', [0 0.75 0.75]);
            end
            
            % Add legend
            legend('Reference', 'Measured', 'Gamma', 'location', 'SouthEast');
            
            % Finish specifying plot
            hold off; 
            ylabel('Normalized Dose');
            ylim([0 1.05]);
            xlabel('MLC X Position (mm)');
            xlim([-150 150]);
            grid on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
        end
        
    % If the user chooses to view the dataset 3 profiles 
    case 6
        % Log selection
        Event('Angle 3 profiles selected for display');
        
        % If the dataset exists
        if ~strcmp(get(handles.([head, 'file3']), 'String'), '') ...
                && ~isempty(get(handles.([head, 'file3']), 'String'))

            % Hold rendering for overlapping plots
            hold on;
            
            % Loop through each reference profile
            for i = 1:length(handles.([head, 'refprofiles3']))
                
                % Plot normalized reference data
                plot(handles.([head, 'refprofiles3']){i}.profile(1,:), ...
                    handles.([head, 'refprofiles3']){i}.profile(2,:) / ...
                    max(handles.([head, 'refprofiles3']){i}.profile(2,:)), 'blue');
                
                % Plot normalized measured data
                plot(handles.([head, 'profiles3']){1}, ...
                    handles.([head, 'profiles3']){i+1} / ...
                    max(handles.([head, 'profiles3']){i+1}), 'red');
                
                % Plot gamma
                plot(handles.([head, 'gamma3']){1}, ...
                    handles.([head, 'gamma3']){i+1}, ...
                    'Color', [0 0.75 0.75]);
            end
            
            % Add legend
            legend('Reference', 'Measured', 'Gamma', 'location', 'SouthEast');
            
            % Finish specifying plot
            hold off; 
            ylabel('Normalized Dose');
            ylim([0 1.05]);
            xlabel('MLC X Position (mm)');
            xlim([-150 150]);
            grid on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
        end
        
    % If the user chooses to view the dataset 4 profiles     
    case 7
        % Log selection
        Event('Angle 4 profiles selected for display');
        
        % If the dataset exists
        if ~strcmp(get(handles.([head, 'file4']), 'String'), '') ...
                && ~isempty(get(handles.([head, 'file4']), 'String'))
        
            % Hold rendering for overlapping plots
            hold on;
            
            % Loop through each reference profile
            for i = 1:length(handles.([head, 'refprofiles4']))
                
                % Plot normalized reference data
                plot(handles.([head, 'refprofiles4']){i}.profile(1,:), ...
                    handles.([head, 'refprofiles4']){i}.profile(2,:) / ...
                    max(handles.([head, 'refprofiles4']){i}.profile(2,:)), 'blue');
                
                % Plot normalized measured data
                plot(handles.([head, 'profiles4']){1}, ...
                    handles.([head, 'profiles4']){i+1} / ...
                    max(handles.([head, 'profiles4']){i+1}), 'red');
                
                % Plot gamma
                plot(handles.([head, 'gamma4']){1}, ...
                    handles.([head, 'gamma4']){i+1}, ...
                    'Color', [0 0.75 0.75]);
            end
            
            % Add legend
            legend('Reference', 'Measured', 'Gamma', 'location', 'SouthEast');
            
            % Finish specifying plot
            hold off; 
            ylabel('Normalized Dose');
            ylim([0 1.05]);
            xlabel('MLC X Position (mm)');
            xlim([-150 150]);
            grid on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
        end
end

% Log completion
Event(sprintf('Plot updated successfully in %0.3f seconds', toc));

% Return the modified handles
varargout{1} = handles;

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end