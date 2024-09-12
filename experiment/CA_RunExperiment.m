% CA_RunExperiment.
%
% This is an experiment running code for color assimilation project.
%
% See also:
%    DisplayImage, DisplayImageControl, MakeTestImages.

% History:
%    04/25/24  smo    - Started on it.
%    05/06/24  smo    - Updated to run a single trial. It needs to be
%                       tested.
%    05/07/24  smo    - Routine is working.
%    08/29/24  smo    - Deleted the part making images. We will make images
%                       in the separate routine.
%    08/30/24  smo    - First draft of doing color matching task with
%                       multiple test images and repeatitions. Needs to be
%                       tested.
%    09/03/24  smo    - Made it work on the curved display.
%    09/09/24  smo    - Fixation point has been updated to a circle. Also,
%                       file name changed.
%    09/12/24  smo    - Routine is working with the gamepad.

%% Initialize.
close all; clear;

%% Add the repository to the path.
sysInfo = GetComputerInfo();

% Set the file dir differently depending on the computer.
switch sysInfo.userShortName
    case 'semin'
        % Office computer.
        baseFiledir = '~/Documents/MATLAB';
    case 'gegenfurtner'
        % Lab Linux computer.
        baseFiledir = '/home/gegenfurtner/Desktop/SEMIN';
    otherwise
        % This is for Semin's laptop.
        baseFiledir = 'C:\Users\ohsem\Documents\MATLAB';
end

% Set repository name.
projectName = 'ColorAssimilation';
testFiledir = fullfile(baseFiledir,projectName);

% Add to the path here.
if isfolder(testFiledir)
    addpath(testFiledir);
    fprintf('Directory has been added to the path!: %s \n',testFiledir);
else
    fprintf('No such directory exist: %s \n',testFiledir);
end

%% Get some input to initiate.
%
% We will get the subject and test image (red, green, or blue) info.
%
% Subject name.
inputMessageName = 'Enter subject name: ';
subjectName = input(inputMessageName, 's');

% Decide which stripe color to test.
while 1
    inputMessageIdxStripeColor = 'Which color of stripes to test [1:red,2:green,3:blue]: ';
    idxStripeColor = input(inputMessageIdxStripeColor);
    idxStripeColorOptions = [1 2 3];

    if ismember(idxStripeColor, idxStripeColorOptions)
        break
    end

    disp('Choose among the options [1:red,2:green,3:blue]');
end
stripeColorOptions = {'red','green','blue'};
stripeColorToTest = stripeColorOptions{idxStripeColor};

% Practice trials.
while 1
    inputMessagePracticeTrials = 'Practice trials before main experiment? [Y, N]: ';
    ansPracticeTrials = input(inputMessagePracticeTrials, 's');
    ansOptions = {'Y' 'N'};

    if ismember(ansPracticeTrials, ansOptions)
        break
    end

    disp('Type either Y or N!');
end

if (strcmp(ansPracticeTrials,'Y'))
    PRACTICETRIALS = true;
elseif (strcmp(ansPracticeTrials,'N'))
    PRACTICETRIALS = false;
end

%% Starting from here to the end, if error occurs, we automatically close the PTB screen.
try
    %% Set variables.
    %
    % Screen variables. The physical lengths of the monitor were measured
    % manually considering the curvature.
    screenParams.screen_x_pixel = 5120;
    screenParams.screen_y_pixel = 1440;
    screenParams.screen_x_cm  = 119.2;
    screenParams.screen_y_cm  = 33.5;
    screenParams.screenDistance_cm = 100;
    screenParams.screenGap_cm = 2.5;

    % Experimental variables.
    expParams.nRepeat = 5;
    expParams.postIntervalDelaySec = 1;
    expParams.postColorCorrectDelaySec = 0.1;
    expParams.subjectName = subjectName;
    expParams.expKeyType = 'gamepad';

    % etc.
    SAVETHERESULTS = true;

    %% Load test images.
    %
    % Get the directory where the test images are saved.
    testImageFiledir = fullfile(testFiledir,'image','TestImages');

    % Load the images here. We will load the corresponding test images
    % according to stripe color input received at the beginning.
    testImageFilename = GetMostRecentFileName(testImageFiledir,append('TestImages_',stripeColorToTest));
    images = load(testImageFilename);

    %% Set the randomization order of displaying the test images.
    %
    % Get the info of the number of different test images.
    expParams.nTestImages = size(images.testImage,1);

    % Set the random order of displaying the test images. For now, we will
    % display the different test images randomly mixed with faces and eggs.
    %
    % The array should look like the number of test images x the number of
    % repeatitions per each test image. For example, if there are 5 test
    % images and repeat each test image for 10 times, the array should look
    % like 5x10.
    for rr = 1:expParams.nRepeat
        expParams.randOrder(:,rr) = randperm(expParams.nTestImages)';
    end

    % Sanity check.
    if any(or(size(expParams.randOrder,1) ~= expParams.nTestImages,...
            size(expParams.randOrder,2) ~= expParams.nRepeat))
        error('The random order array size does not match!');
    end

    % Get the random order of initial test images to display. When doing
    % color matching, we will display either raw (no color correction) or
    % the maximum corrected image on the right.
    %
    % Here, we set 1 for the raw image and 2 for the max corrected image.
    initialImageRaw = 1;
    initialImageMax = 2;
    expParams.idxRandOrderInitial = randi([initialImageRaw initialImageMax], size(expParams.randOrder));
    expParams.idxRandOrderInitial(expParams.idxRandOrderInitial == initialImageMax) = images.imageParams.nTestPoints;

    %% Open the PTB screen.
    initialScreenSetting = [0.5 0.5 0.5]';
    [window windowRect] = OpenPlainScreen(initialScreenSetting);
    
    %% Practice trials if you want.
    if (PRACTICETRIALS)
    
    end
    
    %% Display the initial screen on the null image.
    %
    % Set the initial screen with written instruction.
    imageSize = size(images.nullImage);
    messageInitialImage_1stLine = 'Press any button';
    messageInitialImage_2ndLine = 'To start the experiment';
    ratioMessageInitialHorz = 0.49;
    ratioMessageInitialVert = 0.03;

    % Set the font.
    switch sysInfo.userShortName
        case 'gegenfurtner'
            instructionImageFont = 'DejaVuSans';
        otherwise
            instructionImageFont = 'Arial';
    end
    initialImageBg = ones(size(images.nullImage))*0.5;
    initialInstructionImage = insertText(initialImageBg,[imageSize(2)*ratioMessageInitialHorz imageSize(1)/2-imageSize(1)*ratioMessageInitialVert; imageSize(2)*ratioMessageInitialHorz imageSize(1)/2+imageSize(1)*ratioMessageInitialVert],...
        {messageInitialImage_1stLine messageInitialImage_2ndLine},...
        'fontsize',40,'Font',instructionImageFont,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','black','AnchorPoint','LeftCenter');

    % Display an image texture of the initial image.
    [initialInstructionImageTexture initialInstructionImageWindowRect rng] = MakeImageTexture(initialInstructionImage, window, windowRect,'verbose',false);
    FlipImageTexture(initialInstructionImageTexture, window, windowRect,'verbose',false);

    % Get the PTB texture info in an array.
    activeTextures = [];
    activeTextures(end+1) = initialInstructionImageTexture;

    % Get any key press to proceed.
    switch (expParams.expKeyType)
        case 'gamepad'
            GetJSResp;
        case 'keyboard'
            GetKeyPress;
    end
    disp('Experiment is going to be started!');

    %% Color matching experiment happens here.
    %
    % Display a null image. We will not include the null image texture in
    % the 'activeTextures' as we will recall it every after test image
    % display.
    [nullImageTexture nullImageWindowRect rng] = MakeImageTexture(images.nullImage, window, windowRect, 'verbose', false);
    FlipImageTexture(nullImageTexture, window, windowRect,'verbose',false);

    % First loop for the number of trials.
    for rr = 1:expParams.nRepeat

        % Second loop for different test images. We will display them
        % together in randomized order.
        for ii = 1:expParams.nTestImages
            idxImage = expParams.randOrder(ii,rr);
            idxColorCorrectImage = expParams.idxRandOrderInitial(ii,rr);

            % Color matching happens within this routine.
            data.matchingIntensityColorCorrect(ii,rr) = GetOneRespColorMatching(images.testImage,idxImage,idxColorCorrectImage,...
                images.imageParams.intensityColorCorrect,window,windowRect,...
                'expKeyType',expParams.expKeyType,'postColorCorrectDelaySec',expParams.postColorCorrectDelaySec,...
                'verbose',true);

            % Display a null image again and pause for a second before
            % displaying the next test image.
            [nullImageTexture nullImageWindowRect rng] = MakeImageTexture(images.nullImage, window, windowRect, 'verbose', false);
            FlipImageTexture(nullImageTexture, window, windowRect,'verbose',false);
            pause(expParams.postIntervalDelaySec);

            % Show the progress.
            fprintf('Experiment progress - (%d/%d) \n',rr,expParams.nRepeat);
        end
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
    % Save out the data only if we reached the desired number of trials.
    nTargetTrials = expParams.nTestImages * expParams.nRepeat;
    nTrialsDone = ii * rr;
    if (nTrialsDone == nTargetTrials)
        saveFiledir = fullfile(testFiledir,'data');

        % Make folder with subject name if it does not exist.
        saveFoldername = fullfile(saveFiledir,subjectName);
        if ~exist(saveFoldername, 'dir')
            mkdir(saveFoldername);
            fprintf('Folder has been successfully created: (%s)\n',saveFoldername);
        end

        % Save out the image and experiment params in the structure.
        data.imageParams = images.imageParams;
        [~, testImageFilename, ~] = fileparts(testImageFilename);
        data.imageParams.testImageFilename = testImageFilename;
        data.expParams = expParams;

        % Set the file name and save.
        dayTimestr = datestr(now,'yyyy-mm-dd_HH-MM-SS');
        saveFilename = fullfile(saveFoldername,...
            sprintf('%s_%s_%s',subjectName,stripeColorToTest,dayTimestr));
        save(saveFilename,'data');
        disp('Data has been saved successfully!');
    end
end
