% RunExperiment.
%
% This is a running code for color assimilation project.
%
% See also:
%    DisplayImage, DisplayImageControl.

% History:
%    04/25/24  smo    - Started on it.

%% Initialize.
close all; clear;

%% Add repository to path.
testfiledir = '/home/gegenfurtner/Desktop/SEMIN/';
if isfolder(testfiledir)
    addpath(testfiledir);
    fprintf('Directory has been added to the path!: %s \n',testfiledir);
else
    fprintf('No such directory exist: %s \n',testfiledir);
end

%% Some parameters will be typed for convenience.
%
% 1) Subject name.
inputMessageName = 'Enter subject name: ';
subjectName = input(inputMessageName, 's');

% 2) Stripe color.
while 1
    inputMessageIdxStripeColor = 'Which color of stripes to test [1:red,2:green,3:blue]: ';
    idxStripeColor = input(inputMessageIdxStripeColor);
    idxStripeColorOptions = [1 2 3];

    if ismember(idxStripeColor, idxStripeColorOptions)
        break
    end

    disp('Choose among the options [1:red,2:green,3:blue]');
end

%% Starting from here to the end, if error occurs, we automatically close the PTB screen.
try
    %% Load the original face images.
    image = imread('SeminFace.png');

    %% Set image variables.
    sizeCanvas = [windowRect(3) windowRect(4)];
    testImageSize = 0.15;
    position_leftImage_x = 0.35;
    colorStripesOptions = {'red','green','blue'};
    centerImageOptions = {'stripes','color'};
    idxCenterImage = 1;
    stripe_height_pixel = 5;
    numColorCorrectChannelOptions = [1 3];
    numColorCorrectChannel = 1;

    ratioHorintalScreen = 0.5;
    ratioVerticalScreen = 0.5;

    % Set experimental variables.
    nTrials = 100;
    t_preIntervalSec = 0.5;
    t_postIntervalSec = 1;
    verbose = false;

    %% Make a null stimulus.
    nullStimulus = MakeImageCanvas([],'sizeCanvas',sizeCanvas,'testImageSize',testImageSize,...
        'position_leftImage_x',position_leftImage_x,'whichColorStripes',whichColorStripes,'whichCenterImage',whichCenterImage,...
        'stripe_height_pixel',stripe_height_pixel,'numColorCorrectChannel',numColorCorrectChannel,'verbose',verbose);

    % Make a PTB image texture.
    %
    % We make all PTB texture in advance so that we can minimize the frame
    % break-up because of the time spent making image texture.
    [nullImageTexture nullImageWindowRect rng] = MakeImageTexture(nullStimulus, window, windowRect, ...
        'ratioHorintalScreen',ratioHorintalScreen,'ratioVerticalScreen',ratioVerticalScreen,'verbose', false);

    %% Make test stimulus.
    %
    % Set the color of stripes and which image to put in the center.
    whichColorStripes = colorStripesOptions{idxStripeColor};
    whichCenterImage = centerImageOptions{idxCenterImage};

    % Here we generate an image canvas so that we can present thos whole
    % image as a stimulus.
    testStimulus = MakeImageCanvas(image,'sizeCanvas',sizeCanvas,'testImageSize',testImageSize,...
        'position_leftImage_x',position_leftImage_x,'whichColorStripes',whichColorStripes,'whichCenterImage',whichCenterImage,...
        'stripe_height_pixel',stripe_height_pixel,'numColorCorrectChannel',numColorCorrectChannel,'verbose',verbose);

    % Make PTB image texture.
    [testImageTexture testImageWindowRect rng] = MakeImageTexture(testStimulus, window, windowRect, ...
        'ratioHorintalScreen',ratioHorintalScreen,'ratioVerticalScreen',ratioVerticalScreen,'verbose', false);

    %% Save the null and test images.


    %% Get one evaluation. Later on, this part will be made as a function.
    %
    % Display a null image.
    FlipImageTexture(nullImageTexture, window, windowRect,'verbose',false);
    
    % Make a loop of the experiment until it hits the target number of trials.
    for tt = 1:nTrials
        % Press any button to display a test image. Here we used two
        % separate 'pause' functions. First one is to get a key press, the
        % other one makes a slight time delay before displaying a test
        % stimulus.
        disp('Press any key to display a test image');
        pause;
        pause(t_preIntervalSec);

        % Diplay a test image.
        FlipImageTexture(testImageTexture, window, windowRect,'verbose',false);
        fprintf('Test image is now displaying for (%.f s)...\n',t_postIntervalSec);

        % Make a time delay before bringing the null stimulus back again.
        pause(t_postIntervalSec);

        % Display a null image again after the presenation of the test stimulus.
        FlipImageTexture(nullImageTexture, window, windowRect,'verbose',false);

        % Wait for a key press. Subjects would press either left of right
        % arrow key.
        keyPressOptions = {'LeftArrow','RightArrow'};
        while true
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                keyPressed = KbName(keyCode);
                disp(['Key pressed: ' keyPressed]);

                % Break the loop if a valid key was pressed.
                if ismember(keyPressed,keyPressOptions)
                    fprintf('A key pressed = (%s) \n',keyPressed);
                    break;
                else
                    % Otherwise, the loop lasts until it receives a valid
                    % key.
                    fprintf('Press a key either (%s) or (%s) \n',keyPressOptions{1},keyPressOptions{2});
                end
            end
        end

        % Collect the key press info here.
        rawData.key = keyPressed;

        % Convert the response here.
        if  strcmp(keyPressed,'LeftArrow')
            rawData.data = 0;
        elseif strcmp(keyPressed,'RightArrow')
            rawData.data = 1;
        else
            % Close the screen for the other key press. This part will be
            % deleted or speify a key to close the screen.
            CloseScreen;
        end
    end

catch
    % If error occurs, close the screen.
    CloseScreen;
    tmpE = lasterror;

    % Display the error message.
    tmpE.message
end

%% Save the data.
SAVEDATA = false;
if (SAVEDATA)
end
