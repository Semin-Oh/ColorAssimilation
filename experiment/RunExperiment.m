% RunExperiment.
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

%% Initialize.
close all; clear;

%% Add the repository to the path.
sysInfo = GetComputerInfo();

% Set the file dir differently depending on the computer.
switch sysInfo.userShortName
    case 'semin'
        % Office computer.
        baseFiledir = '~/Documents/MATLAB';

        % SET THE NAME OF THE LINUX COMPUTER HERE.
    case 'gegenfurtner'
        % Lap Linux computer.
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
    % From the chinrest to the center screen.
    screenParams.screenDistance_cm = 100;
    % Gap between the screens. It was measured manually.
    screenParams.screenGap_cm = 2.5;

    % Experimental variables.
    expParams.nRepeat = 5;
    expParams.postIntervalDelaySec = 1;
    expParams.postColorCorrectDelaySec = 0.1;
    expParams.subjectName = subjectName;
    % expParams.beepSound = true;
    % expParams.expKeyType = 'keyboard';

    % etc.
    SAVETHERESULTS = false;
    verbose = false;

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

    %% Display the initial screen on the null image.
    %
    % Set the initial screen with written instruction.
    imageSize = size(images.nullImage);
    messageInitialImage_1stLine = 'Press any button';
    messageInitialImage_2ndLine = 'To start the experiment';
    ratioMessageInitialHorz = 0.4;
    ratioMessageInitialVert = 0.03;
    initialInstructionImage = insertText(images.nullImage,[imageSize(2)*ratioMessageInitialHorz imageSize(1)/2-imageSize(1)*ratioMessageInitialVert; imageSize(2)*ratioMessageInitialHorz imageSize(1)/2+imageSize(1)*ratioMessageInitialVert],...
        {messageInitialImage_1stLine messageInitialImage_2ndLine},...
        'fontsize',40,'Font','DejaVuSans-Bold','BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','white','AnchorPoint','LeftCenter');

    % Display an image texture of the initial image.
    [initialInstructionImageTexture initialInstructionImageWindowRect rng] = MakeImageTexture(initialInstructionImage, window, windowRect,'verbose',false);
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

    %% Color matching experiment happens here.
    %
    % Display a null image.
    [nullImageTexture nullImageWindowRect rng] = MakeImageTexture(images.nullImage, window, windowRect, 'verbose', false);
    FlipImageTexture(nullImageTexture, window, windowRect,'verbose',false);

    % First loop for the number of trials.
    for rr = 1:expParams.nRepeat

        % Second loop for different test images. We will display them
        % together in randomized order.
        for ii = 1:expParams.nTestImages
            idxImage = expParams.randOrder(ii,rr);
            idxColorCorrectImage = expParams.idxRandOrderInitial(ii,rr);
            testImage = images.testImage{idxImage,idxColorCorrectImage};

            % Display the test image.
            [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImage, window, windowRect,'addFixationPointImage','crossbar','verbose', false);
            FlipImageTexture(testImageTexture, window, windowRect,'verbose',false);
            fprintf('Test image is now displaying: Color correct level (%d/%d) \n',idxColorCorrectImage,images.imageParams.nTestPoints);

            % This block completes a one evaluation. Get a key press.
            keyPressOptions = {'DownArrow','UpArrow','RightArrow'};
            while true
                [keyIsDown, ~, keyCode] = KbCheck;
                if keyIsDown
                    keyPressed = KbName(keyCode);

                    % Break the loop if the key for decision ('RightArrow') was
                    % pressed.
                    if strcmp(keyPressed,'RightArrow')
                        fprintf('A key pressed = (%s) \n',keyPressed);
                        break;

                        % Update the test image with less color correction.
                    elseif strcmp(keyPressed,'DownArrow')
                        idxColorCorrectImage = idxColorCorrectImage - 1;

                        % Set the index within the feasible range.
                        if idxColorCorrectImage < 1
                            idxColorCorrectImage = 1;
                        elseif idxColorCorrectImage > images.imageParams.nTestPoints;
                            idxColorCorrectImage = images.imageParams.nTestPoints;
                        end

                        % Update the image here.
                        testImage = images.testImage{idxImage,idxColorCorrectImage};
                        [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImage, window, windowRect,'addFixationPointImage','crossbar','verbose', false);
                        FlipImageTexture(testImageTexture, window, windowRect,'verbose',false);
                        fprintf('Test image is now displaying: Color correct level (%d/%d) \n',idxColorCorrectImage,images.imageParams.nTestPoints);

                        % Update the test image with stronger color correction.
                    elseif strcmp(keyPressed,'UpArrow')
                        idxColorCorrectImage = idxColorCorrectImage + 1;

                        % Set the index within the feasible range.
                        if idxColorCorrectImage < 1
                            idxColorCorrectImage = 1;
                        elseif idxColorCorrectImage > images.imageParams.nTestPoints;
                            idxColorCorrectImage = images.imageParams.nTestPoints;
                        end

                        % Update the image here.
                        testImage = images.testImage{idxImage,idxColorCorrectImage};
                        [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImage, window, windowRect,'addFixationPointImage','crossbar','verbose', false);
                        FlipImageTexture(testImageTexture, window, windowRect,'verbose',false);
                        fprintf('Test image is now displaying: Color correct level (%d/%d) \n',idxColorCorrectImage,images.imageParams.nTestPoints);

                        % Close the PTB. This part is temporary and maybe
                        % be removed later on.
                    elseif strcmp(keyPressed,'q')
                        CloseScreen;
                        break;

                    else
                        % Show a message to press a valid key press.
                        fprintf('Press a key either (%s) or (%s) or (%s) \n',keyPressOptions{1},keyPressOptions{2},keyPressOptions{3});
                    end
                end

                % Make a tiny time delay here so that we make sure we color
                % match in a unit step size. Without time delay, the color
                % matching would be executed in more than one step size if
                % we press the button too long.
                pause(expParams.postColorCorrectDelaySec);
            end

            % Collect the key press data here.
            data.matchingIntensityColorCorrect(ii,rr) = images.imageParams.intensityColorCorrect(idxColorCorrectImage);

            % Display a null image again and pause for a second before
            % displaying the next test image.
            [nullImageTexture nullImageWindowRect rng] = MakeImageTexture(images.nullImage, window, windowRect,'addFixationPointImage','crossbar','verbose', false);
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
    saveFiledir = fullfile(testFiledir,'data');

    % Make folder with subject name if it does not exist.
    saveFoldername = fullfile(saveFiledir,subjectName);
    if ~exist(saveFoldername, 'dir')
        mkdir(saveFoldername);
        fprintf('Folder has been successfully created: (%s)\n',saveFoldername);
    end

    % Save out the image and experiment params in the structure.
    data.imageParams = images.imageParams;
    data.expParams = expParams;

    % Set the file name and save.
    dayTimestr = datestr(now,'yyyy-mm-dd_HH-MM-SS');
    saveFilename = fullfile(saveFoldername,...
        sprintf('%s_%s_%s',subjectName,stripeColorToTest,dayTimestr));
    save(saveFilename,'data');
    disp('Data has been saved successfully!');
end
