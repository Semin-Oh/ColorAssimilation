% GetJSResp.
%
% Open the joystick device file (js0 is typically the first joystick)
fid = fopen('/dev/input/js0', 'rb');

if fid == -1
    error('Unable to open joystick device.');
end

% Define constants for "down" button or axis event (depending on gamepad)
% In this case, assume the D-pad "down" is axis 1, and negative value
DOWN_AXIS = 1;  % Usually corresponds to the Y-axis (check with jstest-gtk)
DOWN_THRESHOLD = -32767;  % Maximum negative value for the axis

% Infinite loop to keep reading the joystick events
while true
    % Read 8 bytes from the joystick input stream
    data = fread(fid, 8);
    if isempty(data)
        break; % End of stream
    end

    % Parse joystick event data
    time = typecast(uint8(data(1:4)), 'uint32');  % Event time
    value = typecast(uint8(data(5:6)), 'int16');  % Value (axis/button)
    type = data(7);                               % Event type (axis/button)
    number = data(8);                             % Axis or button number

    % Display event details (for debugging purposes)
    fprintf('Time: %u, Value: %d, Type: %d, Number: %d\n', time, value, type, number);

    % Check if the event corresponds to an axis movement
    if type == 2  % Type 2 indicates axis movement
        % Check if it's the down axis (usually axis 1) and value is negative
        if number == DOWN_AXIS && value == DOWN_THRESHOLD
            disp('Down button pressed, ending routine.');
            break;
        end
    end

    % You can add other conditions for different buttons or axes here
    if
        break;
    end
end

% Close the device file
fclose(fid);
