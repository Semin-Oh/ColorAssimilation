function [keyPress] = GetKeyPress(options)

%% Set variables.
arguments
    options.verbose = true;
end

%% Get a key press.
%
% We will get a key press until we get one within the preset key options.
keyPressOptions = {'DownArrow','LeftArrow','RightArrow'};
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