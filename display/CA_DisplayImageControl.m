% CA_DisplayImageControl.
%
% This displays an image on the DLP using the Psychtoolbox. This is a
% modified version to control the canvas real time. It is possible to
% control the image elements on the canvas while displaying images.
%
% See also:
%    DisplayImage.

% History:
%    10/09/23  smo    - Modified it.
%    03/28/24  smo    - Modified it for color assimiliation project in
%                       Giessen.
%    04/10/24  smo    - Made it to be able to control image elements in
%                       real time.
%    06/19/24  smo    - Added one more variable to control: Level of color
%                       correction.q
%    06/20/24  smo    - Corrected directory and variable names.
%    11/21/24  smo    - Changed the script name.

%% Initialize.
close all; clear;

%% Start here, if error occurs, we automatically close the PTB screen.
try
    %% Load the image data.
    testFiledir = '/home/gegenfurtner/Dropbox/JLU/2) Projects/ColorAssimilation/image/RawImages';
    testFilename = 'rudolf.png';
    testImage = imread(fullfile(testFiledir,testFilename));

    %% Open the PTB screen.
    initialScreenSetting = [0.5 0.5 0.5]';
    [window windowRect] = OpenPlainScreen(initialScreenSetting);

    %% Make image canvas to present.
    %
    % Set variables.
    sizeCanvas = [windowRect(3) windowRect(4)];
    whichDisplay = 'curvedDisplay';
    testImageSize = 0.65;
    position_leftImage_x = 0.36;
    colorStripesOptions = {'red','green','blue'};
    idxColorStripes = 1;
    stripe_height_pixel = 5;
    numColorCorrectChannelOptions = [1 3];
    numColorCorrectChannel = 1;
    intensityColorCorrect = 0.1;
    addFixationPointImage = 'filled-circle';
    verbose = false;

    % More variables to control the image canvas in real time.
    stepsize_imagePosition = 0.02;
    stepsize_testImage_size = 0.1;
    stepsize_height_pixel = 5;
    stepsize_intensityColorCorrect = 0.1;

    % Make a loop here to update the canvas in real time.
    while 1
        % Set the color of stripes and which image to put in the center.
        whichColorStripes = colorStripesOptions{idxColorStripes};

        % Here we generate an image canvas so that we can present thos whole
        % image as a stimulus.
        imageCanvas = MakeImageCanvas(testImage,'whichDisplay',whichDisplay,'sizeCanvas',sizeCanvas,'testImageSize',testImageSize,...
            'position_leftImage_x',position_leftImage_x,'whichColorStripes',whichColorStripes,...
            'stripeHeightPixel',stripe_height_pixel,'nChannelsColorCorrect',numColorCorrectChannel,'intensityColorCorrect',intensityColorCorrect,...
            'verbose',verbose);

        %% Make PTB image texture.
        %
        % Here, we make the PTB texture first, then  we will flip the image in the
        % next section. For making multiple images, we may want to make all the
        % image textures in advance, then flip the images. This way, we can
        % guarantte to have the same flip time between the image presentations.
        %
        % Also, we will choose which location on the screen to present the image.
        ratioHorintalScreen = 0.5;
        ratioVerticalScreen = 0.5;
        [imageTexture imageWindowRect rng] = MakeImageTexture(imageCanvas, window, windowRect,'addFixationPointImage',addFixationPointImage, ...
            'ratioHorintalScreen',ratioHorintalScreen,'ratioVerticalScreen',ratioVerticalScreen,'verbose', false);

        %% Flip the PTB texture to display the image on the projector.
        FlipImageTexture(imageTexture, window, windowRect,'verbose',false);
        disp('Image is now displaying...\n');

        % Wait for a key press
        while true
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                keyPressed = KbName(keyCode);
                disp(['Key pressed: ' keyPressed]);
                break;
            end
        end

        % Update the canvas based on the above key press.
        %
        % Increase the stripe height.
        if strcmp(keyPressed,'UpArrow')
            stripe_height_pixel = stripe_height_pixel+stepsize_height_pixel;
            % Decrease the stripe height.
        elseif strcmp(keyPressed,'DownArrow')
            stripe_height_pixel = stripe_height_pixel-stepsize_height_pixel;
            % Increase the gap between the left and the right images.
        elseif strcmp(keyPressed,'LeftArrow')
            position_leftImage_x = position_leftImage_x-stepsize_imagePosition;
            % Decrease the gap between the left and the right images.
        elseif strcmp(keyPressed,'RightArrow')
            position_leftImage_x = position_leftImage_x+stepsize_imagePosition;
            % Change the color of the stripes to place on the test image.
        elseif strcmp(keyPressed,'c')
            idxColorStripes = idxColorStripes+1;
            if idxColorStripes > length(colorStripesOptions)
                idxColorStripes = 1;
            end
            % Switch the number of the channels to be corrected.
        elseif strcmp(keyPressed,'n')
            numColorCorrectChannel = setdiff(numColorCorrectChannelOptions,numColorCorrectChannel);
            % Make the test image larger.
        elseif strcmp(keyPressed,']}')
            testImageSize = testImageSize + stepsize_testImage_size;
            % Make the test images smaller.
        elseif strcmp(keyPressed,'[{')
            testImageSize = testImageSize - stepsize_testImage_size;
            % Make the test image more saturated.
        elseif strcmp(keyPressed,'p')
            intensityColorCorrect = intensityColorCorrect + stepsize_intensityColorCorrect;
            % Make the test image less saturated.
        elseif strcmp(keyPressed,'o')
            intensityColorCorrect = intensityColorCorrect - stepsize_intensityColorCorrect;
        else
            % Close the screen for the other key press.
            CloseScreen;

            % Display the last setting.
            fprintf('Current canvas setting: Stripe height = (%d), Image position = (%.2f), Image size = (%.2f) \n', ...
                stripe_height_pixel, position_leftImage_x, testImageSize);
        end
    end

catch
    % If error occurs, close the screen.
    CloseScreen;
    tmpE = lasterror;

    % Display the error message.
    tmpE.message

    % Display the error code.
    for ee = 1:length(tmpE.stack)
        fprintf('Error code = (%s), line = (%d) \n',tmpE.stack(ee).name,tmpE.stack(ee).line);
    end
end
