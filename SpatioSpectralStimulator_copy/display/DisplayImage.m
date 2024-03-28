% DisplayImage.
%
% This displays an image on the DLP using the Psychtoolbox.

% History:
%    10/09/23  smo    - Modified it.
%    03/28/24  smo    - Modified it for color assimiliation project in
%                       Giessen.

%% Initialize.
close all; clear;

%% Load the image data.
testImage = imread('image.jpeg');

%% Open the projector and set the channel settings.
%
% Turn on the projector and display anything to start.
initialScreenSetting = [0 0 0]';
[window windowRect] = OpenPlainScreen(initialScreenSetting);

% Set channel settings here. We loaded the settings from the saved data.
SetChannelSettings(channelSettings);

%% Make PTB image texture.
%
% We will use the same function that we used in the experiment to display
% the image.
[imageTexture imageWindowRect rng] = MakeImageTexture(testImage, window, windowRect, ...
    'addNoiseToImage', false, 'verbose', false);

%% Flip the PTB texture to display the image on the projector.
FlipImageTexture(imageTexture, window, imageWindowRect,'verbose',false);
disp('Image is now displaying...\n');
