% RunExperiment.
%
% This is a running code for color assimilation project.
%
% See also:
%    DisplayImage, DisplayImageControl.

% History:
%    04/25/24  smo    - Started on it.
%    05/06/24  smo    - Updated to run a single trial. It needs to be
%                       tested.
%    05/07/24  smo    - Routine is working.

%% Initialize.
close all; clear;

%% Get computer info to recognize the path to add.
sysInfo = GetComputerInfo();

% Set the file dir differently depending on the computer.
switch sysInfo.userShortName
    case 'semin'
        % Office computer.
        baseFiledir = '~/Documents/MATLAB';

        % SET THE NAME OF THE LINUX COMPUTER HERE.
    case 'gegenfurtner'
        % Lap Linux computer.
        baseFiledir = '/home/gegenfurtner/Desktop/semin';
    otherwise
        % This is for Semin's laptop.
        baseFiledir = 'C:\Users\ohsem\Documents\MATLAB';
end

%% Set repository name.
projectName = 'ColorAssimilation';
testFiledir = fullfile(baseFiledir,projectName);

%% Add repository to path.
if isfolder(testFiledir)
    addpath(testFiledir);
    fprintf('Directory has been added to the path!: %s \n',testFiledir);
else
    fprintf('No such directory exist: %s \n',testFiledir);
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
    imageFilename = 'RawImage_1.png';
    rawImageFiledir = fullfile(testFiledir,'image','RawImages');
    image = imread(fullfile(rawImageFiledir,imageFilename));

    %% Open the PTB screen.
    initialScreenSetting = [0.5 0.5 0.5]';
    [window windowRect] = OpenPlainScreen(initialScreenSetting);

    %% Set variables.
    %
    % Screen variables. The physical lengths of the monitor were measured
    % manually considering the curvature.
    screenParams.screen_x_pixel = 5120;
    screenParams.screen_y_pixel = 1440;
    screenParams.screen_x_cm  = 119.2;
    screenParams.screen_y_cm  = 33.5;
    % From the chinrest to the center screen.
    screenParams.screenDistance_cm = 100;
    % Gap between the screens. It was measured manually.
    screenParams.screenGap_cm = 2.5; 

    % Image variables.
    imageParams.sizeCanvans = [windowRect(3) windowRect(4)];
    imageParams.testImageSize = 0.15;
    imageParams.position_leftImage_x = 0.35;
    imageParams.stripeHeightPixel = 5;
    imageParams.nChannelsColorCorrectOptions = [1 3];
    imageParams.nChannelsColorCorrect = 1;
    imageParams.colorStripesOptions = {'red','green','blue'};
    imageParams.whichColorStripes = imageParams.colorStripesOptions{idxStripeColor};

    imageParams.centerImageOptions = {'stripes','color','none'};
    imageParams.idxCenterImage = 1;
    whichCenterImage = imageParams.centerImageOptions{imageParams.idxCenterImage};

    % Experimental variables.
    expParams.nTrials = 3;
    expParams.preIntervalDelaySec = 0.5;
    expParams.postIntervalDelaySec = 1;
    expParams.subjectName = subjectName;

    % etc.
    MAKENEWTESTIMAGE = false;
    SAVETHERESULTS = true;
    verbose = false;

    %% Make the test images. 
    %
    % Get the directory where the test images are saved.
    testImageFiledir = fullfile(testFiledir,'image','TestImages',...
        imageParams.colorStripesOptions{idxStripeColor});

    if (MAKENEWTESTIMAGE)
        % a) Make a null stimulus.
        nullImage = MakeImageCanvas([],'sizeCanvas',imageParams.sizeCanvans,'testImageSize',imageParams.testImageSize,...
            'position_leftImage_x',imageParams.position_leftImage_x,'whichColorStripes',imageParams.whichColorStripes,'whichCenterImage',whichCenterImage,...
            'stripeHeightPixel',imageParams.stripeHeightPixel,'nChannelsColorCorrect',imageParams.nChannelsColorCorrect,'verbose',verbose);

        % b) Make test stimulus.
        testImage = MakeImageCanvas(image,'sizeCanvas',imageParams.sizeCanvans,'testImageSize',imageParams.testImageSize,...
            'position_leftImage_x',imageParams.position_leftImage_x,'whichColorStripes',imageParams.whichColorStripes,'whichCenterImage',whichCenterImage,...
            'stripeHeightPixel',imageParams.stripeHeightPixel,'nChannelsColorCorrect',imageParams.nChannelsColorCorrect,'verbose',verbose);

        % c) Save the images. Make a new folder if the directory does not exist.
        if ~exist(testImageFiledir, 'dir')
            mkdir(testImageFiledir);
            fprintf('Folder has been successfully created: \n (%s) \n',testImageFiledir);
        end

        % Set the file name and save the images.
        dayTimestr = datestr(now,'yyyy-mm-dd_HH-MM-SS');
        saveFilename = fullfile(testImageFiledir,...
            sprintf('TestImages_%s_%s',imageParams.colorStripesOptions{idxStripeColor},dayTimestr));
        save(saveFilename,'nullImage','testImage');
        disp('Test images have been saved successfully!');

    else
        % Load the images if they exist.
        testImageFilename = GetMostRecentFileName(testImageFiledir,'TestImages_');
        load(testImageFilename);
        disp('Test images have been loaded successfully!');
    end

    %% Make the PTB textures of the null and test images.
    %
    % We make all PTB texture in advance so that we can minimize the frame
    % break-up because of the time spent making image texture.
    %
    % Null image.
    [nullImageTexture nullImageWindowRect rng] = MakeImageTexture(nullImage, window, windowRect, 'verbose', false);

    % Test images.
    [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImage, window, windowRect, 'verbose', false);

    %% Set the initial screen for instruction.
    imageSize = size(nullImage);
    messageInitialImage_1stLine = 'Press any button';
    messageInitialImage_2ndLine = 'To start the experiment';
    ratioMessageInitialHorz = 0.4;
    ratioMessageInitialVert = 0.03;
    initialInstructionImage = insertText(nullImage,[imageSize(2)*ratioMessageInitialHorz imageSize(1)/2-imageSize(1)*ratioMessageInitialVert; imageSize(2)*ratioMessageInitialHorz imageSize(1)/2+imageSize(1)*ratioMessageInitialVert],...
        {messageInitialImage_1stLine messageInitialImage_2ndLine},...
        'fontsize',40,'Font','Arial','BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','black','AnchorPoint','LeftCenter');

    % Make an image texture of the initial image.
    [initialInstructionImageTexture initialInstructionImageWindowRect rng] = MakeImageTexture(initialInstructionImage, window, windowRect,'verbose',false);

    % Display the initial screen.
    FlipImageTexture(initialInstructionImageTexture, window, windowRect,'verbose',false);

    % Get any key press to proceed.
    while true
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            keyPressed = KbName(keyCode);
            disp(['Key pressed: ' keyPressed]);
            break;
        end
    end
    disp('Experiment is going to be started!');

    %% Get one evaluation. Later on, this part will be made as a function.
    %
    % Display a null image.
    FlipImageTexture(nullImageTexture, window, windowRect,'verbose',false);

    % Make a loop of the experiment until it hits the target number of trials.
    for tt = 1:expParams.nTrials
        % Get any key press to proceed. This is for the very first trial.
        % For the other trials,
        if tt == 1
            disp('Press any key to display a test image');
            while true
                [keyIsDown, ~, keyCode] = KbCheck;
                if keyIsDown
                    keyPressed = KbName(keyCode);
                    disp(['Key pressed: ' keyPressed]);
                    break;
                end
            end
        end

        % Make a tiny delay between the null and test test stimulus. We may
        % want to delete this part later on.
        pause(expParams.preIntervalDelaySec);

        % Diplay a test image.
        FlipImageTexture(testImageTexture, window, windowRect,'verbose',false);
        fprintf('Test image is now displaying for (%.f s)...\n',expParams.postIntervalDelaySec);

        % Make a time delay before bringing the null stimulus back again.
        pause(expParams.postIntervalDelaySec);

        % Display a null image again after the presenation of the test stimulus.
        FlipImageTexture(nullImageTexture, window, windowRect,'verbose',false);

        % Wait for a key press. Subjects would press either left of right
        % arrow key.
        keyPressOptions = {'LeftArrow','RightArrow'};
        while true
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                keyPressed = KbName(keyCode);

                % Break the loop if a valid key was pressed.
                if ismember(keyPressed,keyPressOptions)
                    fprintf('A key pressed = (%s) \n',keyPressed);
                    break;
                else
                    % Close the screen for the other key press. This part will be
                    % deleted or speify a key to close the screen.
                    CloseScreen;

                    % Otherwise, the loop lasts until it receives a valid
                    % key.
                    fprintf('Press a key either (%s) or (%s) \n',keyPressOptions{1},keyPressOptions{2});
                end
            end
        end

        % Collect the key press info here.
        rawData.key{tt} = keyPressed;

        % Convert the response here.
        if  strcmp(keyPressed,'LeftArrow')
            rawData.data(tt) = 0;
        elseif strcmp(keyPressed,'RightArrow')
            rawData.data(tt) = 1;
        end

        % Show the progress.
        fprintf('Experiment progress - (%d/%d) \n',tt,expParams.nTrials);
    end

catch
    % If error occurs, close the screen.
    CloseScreen;
    tmpE = lasterror;

    % Display the error message.
    tmpE.message
    tmpE.stack.name
    tmpE.stack.line
end

%% Close the PTB screen once the experiment is done.
CloseScreen;

%% Save the data.
if (SAVETHERESULTS)
    saveFiledir = fullfile(testFiledir,'data');

    % Make folder with subject name if it does not exist.
    saveFoldername = fullfile(saveFiledir,subjectName,imageParams.colorStripesOptions{idxStripeColor});
    if ~exist(saveFoldername, 'dir')
        mkdir(saveFoldername);
        fprintf('Folder has been successfully created: \n (%s) \n',saveFoldername);
    end

    % Set the file name and save. We will update the name of the folder
    % later once we set on the experimental settings.
    dayTimestr = datestr(now,'yyyy-mm-dd_HH-MM-SS');
    saveFilename = fullfile(saveFoldername,...
        sprintf('%s_%s_%s',subjectName,imageParams.colorStripesOptions{idxStripeColor},dayTimestr));
    save(saveFilename,'rawData','imageParams','expParams');
    disp('Data has been saved successfully!');
end
