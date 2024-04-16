% DisplayImageControl.
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

%% Initialize.
close all; clear;

%% Add repository to path.
testfiledir = '/home/gegenfurtn er/Desktop/SEMIN/SpatioSpectralStimulator_copy';
if isfolder(testfiledir)
    addpath(testfiledir);
    fprintf('Directory has been added to the path!: %s \n',testfiledir);
else
    fprintf('No such directory exist: %s \n',testfiledir);
end

%% Start here, if error occurs, we automatically close the PTB screen.
try
    %% Load the image data.
    testImage = imread('SeminFace.png');

    %% Open the PTB screen.
    initialScreenSetting = [0.5 0.5 0.5]';
    [window windowRect] = OpenPlainScreen(initialScreenSetting);

    %% Make image canvas to present.
    %
    % Set variables.
    sizeCanvas = [windowRect(3) windowRect(4)];
    testImageSize = 0.15;
    position_leftImage_x = 0.35;
    colorStripesOptions = {'red','green','blue'};
    idxColorStripes = 1;
    centerImageOptions = {'stripes','color'};
    idxCenterImage = 1;
    stripe_height_pixel = 5;
    numColorCorrectChannelOptions = [1 3];
    numColorCorrectChannel = 1;
    verbose = false;

    % More variables to control the image canvas in real time.
    unit_imagePosition = 0.05;
    unit_testImage_size = 0.05;
    unit_height_pixel = 5;

    % Make a loop here to update the canvas in real time.
    while 1
        % Set the color of stripes and which image to put in the center.
        whichColorStripes = colorStripesOptions{idxColorStripes};
        whichCenterImage = centerImageOptions{idxCenterImage};

        % Here we generate an image canvas so that we can present thos whole
        % image as a stimulus.
        imageCanvas = MakeImageCanvas(testImage,'sizeCanvas',sizeCanvas,'testImageSize',testImageSize,...
            'position_leftImage_x',position_leftImage_x,'whichColorStripes',whichColorStripes,'whichCenterImage',whichCenterImage,...
            'stripe_height_pixel',stripe_height_pixel,'numColorCorrectChannel',numColorCorrectChannel,'verbose',verbose);

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
        [imageTexture imageWindowRect rng] = MakeImageTexture(imageCanvas, window, windowRect, ...
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
            stripe_height_pixel = stripe_height_pixel+unit_height_pixel;
            % Decrease the stripe height.
        elseif strcmp(keyPressed,'DownArrow')
            stripe_height_pixel = stripe_height_pixel-unit_height_pixel;
            % Increase the gap between the left and the right images.
        elseif strcmp(keyPressed,'LeftArrow')
            position_leftImage_x = position_leftImage_x-unit_imagePosition;
            % Decrease the gap between the left and the right images.
        elseif strcmp(keyPressed,'RightArrow')
            position_leftImage_x = position_leftImage_x+unit_imagePosition;
            % Change the color of the stripes to place on the test image.
        elseif strcmp(keyPressed,'c')
            idxColorStripes = idxColorStripes+1;
            if idxColorStripes > length(colorStripesOptions)
                idxColorStripes = 1;
            end
            % Switch the centered image either the stripes or color corrected.
        elseif strcmp(keyPressed,'v')
            idxCenterImage = idxCenterImage+1;
            if idxCenterImage > length(centerImageOptions)
                idxCenterImage = 1;
            end
            % Switch the number of the channels to be corrected.
        elseif strcmp(keyPressed,'n')
            numColorCorrectChannel = setdiff(numColorCorrectChannelOptions,numColorCorrectChannel);
            % Make the test image larger.
        elseif strcmp(keyPressed,']}')
            testImageSize = testImageSize + unit_testImage_size;
            % Make the test images smaller.
        elseif strcmp(keyPressed,'[{')
            testImageSize = testImageSize - unit_testImage_size;
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
end
