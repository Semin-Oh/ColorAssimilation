% DisplayImage.
%
% This displays an image on the DLP using the Psychtoolbox.

% History:
%    10/09/23  smo    - Modified it.
%    03/28/24  smo    - Modified it for color assimiliation project in
%                       Giessen.

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
    testImage = imread('Semin.png');

    %% Open the PTB screen.
    initialScreenSetting = [0.5 0.5 0.5]';
    [window windowRect] = OpenPlainScreen(initialScreenSetting);
   
    %% Make image canvas to present.
    %
    % Set variables.
    sizeCanvas = [1920 1080];
    position_leftImage_x = 0.3;
    whichColorStripes = 'red';
    whichCenterImage = 'stripes';
    stripe_height_pixel = 5;

    % Here we generate an image canvas so that we can present thos whole
    % image as a stimulus.
    imageCanvas = MakeImageCanvas(testImage,'sizeCanvas',sizeCanvas,...
        'position_leftImage_x',position_leftImage_x,'whichColorStripes','red','whichCenterImage',whichCenterImage,...
        'stripe_height_pixel',5);
    
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

    % Get a key stroke to close the screen.
    KbStrokeWait;
    CloseScreen;

catch
    % If error occurs, close the screen.
    CloseScreen;
    tmpE = lasterror;

    % Display the error message.
    tmpE.message
end
