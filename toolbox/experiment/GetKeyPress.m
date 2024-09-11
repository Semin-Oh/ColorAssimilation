function [keyPress] = GetKeyPress(options)
% This gets a keyboard response.
%
% Syntax:
%    [keyPress] = GetKeyPress()
%
% Description:
%    This gets a single key press from the keyboard.
%
% Inputs:
%    N/A
%
% Outputs:
%    keyPress                   - String that shows which button was
%                                 pressed on the keyboard.
%
% Optional key/value pairs:
%    verbose                    - Boolean. Default true. Controls
%                                 printout.
%
% See also:
%    N/A

% History:
%   09/11/24 smo                - Wrote it.

%% Set variables.
arguments
    options.verbose = true;
end

%% Get a key press.
while true
    % Get a key press.
    [keyIsDown, ~, keyCode] = KbCheck;
    
    % Check which key was pressed.
    if keyIsDown
        keyPressed = KbName(keyCode);
    end
    
    % If the key pressed is one of the preset options, break the loop.
    if ismember(keyPressed,keyOptions)
        if (options.verbose)
            fprintf('A key pressed = (%s) \n',keyPressed);
        end
        break;
    end
end

end