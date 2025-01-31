%% CalibrateMonitor.
%
% Calibrate the monitor in 8 bits mode. It is a modified version to work on
% the Linux computer where the curved display is connected to.
%
% See also:
%    CALIBRATION_mt_calibrator_8bits.m.

% History:
%    01/31/25    smo    - Started working on it.

%% Initialze.
clear; close all;

%% Set variables.
%
% Measurement place.
room = 'CurvedDisplay';

% Set measurement range. It's based on 8-bit settings.
dRGB_target_min = 0;
dRGB_target_max = 255;
nTargetPoints = 10;
dRGB_target = round(linspace(dRGB_target_min,dRGB_target_max,nTargetPoints));

spd = nan(401,length(dRGB_target),4);

%% Connect to the spectroradiometer.
%
% The port number for the curved display is '/dev/ttyACM0', which should be
% updated based on which computer that connected to the spectroradiometer.
switch room
    case 'CurvedDisplay'
        port_CS2000 = '/dev/ttyACM0';
    otherwise
        port_CS2000 = 'COM5';
end

% Connection happens here. Check the status message.
CS2000_initConnection(port_CS2000);

%% Open PTB screen.
initialScreenSettings = [0.5 0.5 0.5];
[window windowRect] = OpenPlainScreen(initialScreenSettings);

%% try measuring zero
intercept = CS2000_measure();
Screen('FillRect',window,0);
Screen('Flip',window);

%% Make a loop to measure the desired range.
%
% Channel. Red, Green, Blue, and Gray, in an order.
nChannels = 4;

for cc = 1:nChannels

    % Different points for a gamma table per each channel.
    for dd = 1:length(dRGB_target)


        dRGB_measure_temp = zeros(1,3);
        if cc < 4
            dRGB_measure_temp(cc) = dRGB_target(dd);
        else
            dRGB_measure_temp=dRGB_measure_temp + dRGB_target(dd);
        end

        % Screen the image to measure.
        Screen('FillRect',window,uint8(dRGB_measure_temp));
        Screen('Flip',window);

        % Measurement happens here.
        rawData = CS2000_measure();
        spd(:,dd,cc) = rawData.spectralData;

        % Save the spectra here.
        date = datetime("now");
        fileName = sprintf('spd_%s_',room,)
        save(['spd_' room '_' date],'spd','intercept','time')
    end
end
