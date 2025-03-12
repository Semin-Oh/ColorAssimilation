%% CalibrateMonitor.
%
% Calibrate the monitor in 8 bits mode. It is a modified version to work on
% the Linux computer where the curved display is connected to.
%
% See also:
%    CALIBRATION_mt_calibrator_8bits.m.

% History:
%    01/31/25    smo    - Started working on it.
%    02/13/25    smo    - Cleaned up and needs to be tested if it's
%                         working.

%% Initialze.
clear; close all;

%% Set variables.
%
% Set measurement range. It'll be converted into the settings in 8-bit.
nMeasurePoints = 10;
targetScreenSettings = linspace(0,1,nMeasurePoints);

% Target measurement channels.
targetChannels = {'red','green','blue','gray'};
nChannels = length(targetChannels);

% Print out control.
verbose = false;

%% Get display info to measure.
%
% Get a key input here.
while 1
    inputMessageDisplay = 'Which display are you measuring [1:Curved Display,2:EIZO monitor]: ';
    numDisplay = input(inputMessageDisplay);
    numDisplayOptions = [1,2];

    if ismember(numDisplay, numDisplayOptions)
        break
    end

    disp('Choose one among the available options!');
end
displayOptions = {'CurvedDisplay','EIZO'};
displayMeasured = displayOptions(numDisplay);

% Set the port number to connect the spectroradiometer over different
% displays. Also, set the folder to save the results.

switch displayMeasured
    case 'CurvedDisplay'
        port_CS2000 = '/dev/ttyACM0';
        baseFiledir = '/home/gegenfurtner/Dropbox/JLU/2) Projects';
    case 'EIZO'
        port_CS2000 = 'COM5';
        baseFiledir = 'C:\Users\fulvous.uni-giessen\Dropbox\JLU\2) Projects';
    otherwise
        port_CS2000 = 'COM5';
end


%% Connect to the spectroradiometer.
CS2000_initConnection(port_CS2000);

%% Open PTB screen.
%
% We will open the mid gray screen as the initial screen.
initialScreenSettings = [0.5 0.5 0.5]';
[window windowRect] = OpenPlainScreen(initialScreenSettings);

%% Measurement happens here.
%
% Make a loop for all channels.
for cc = 1:nChannels
    targetChannel = targetChannels{cc};

    % Make a loop for a gamma table.
    for dd = 1:nMeasurePoints

        % Default format for the digital values.
        screenSettingsMeasure = zeros(3,1);

        % Set the screen settings differently over different channels.
        switch targetChannel
            case 'gray'
                screenSettingsMeasure(:) = targetScreenSettings(dd);
            otherwise
                % For the other single channels.
                screenSettingsMeasure(cc) = targetScreenSettings(dd);
        end

        % Screen the image to measure.
        SetPlainScreenSettings(screenSettingsMeasure,window,windowRect,'verbose',verbose);

        % Measurement happens here.
        rawData = CS2000_measure();

        % Read out the spectrum.
        spd_oneChannel(:,dd) = rawData.spectralData;
    end

    % Save out the spectra over different channels.
    spds{cc} = spd_oneChannel;
end

%% Save the spectra here.
dayTimestr = datestr(now,'yyyy-mm-dd_HH-MM-SS');
saveFiledir = fullfile(baseFiledir,'calibration');
saveFilename = fullfile(saveFiledir,sprintf('spd_%s_%d_%s',displayMeasured,nMeasurePoints,dayTimestr));
save(saveFilename,'spds');
disp('Data has been saved successfully!');
