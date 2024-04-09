%% MakeImageCanvas_demo.
%
% This routine generates the image canvas to test color assimilation
% phenomena.

% History:
%    04/08/24    smo    - Started on it.

%% Initialize.
clear; close all;

%% Set variables.
%
% Choose which image to display at the center either 'stripes' or
% 'color'.
whichCenterImage = 'color';

% Define the size of the stripes
stripe_height_pixel = 5;

% Choose the color among 'red', 'green', 'blue'.
whichColorStripes = 'red';

% Set the position of the image on the left. This would decide the
% locations of all images on the canvas.
position_leftImage_x = 0.1;

% Control plot and text output.
verbose = false;

% Define the size of the canvas.
canvas_width = 1920;
canvas_height = 1080;

%% Load a test image.
testImage = imread('Semin.png');

%% Create a canvas to place images on.
%
% Create a blank canvas.
canvas = zeros(canvas_height, canvas_width, 3);

% Define the size of the test image.
testImage_width = canvas_width * 0.1;
testImage_height = canvas_height * 0.3;

% Resize the test image to fit in the canvas.
resized_testImage = imresize(testImage, [testImage_height, testImage_width]);

% Find the location where the image content exist. The idea here is to
% treat the black (0, 0, 0) part as a background and it will be excluded in
% this index.
idxImageHeight = [];
idxImageWidth = [];
bgSetting = 0;
for hh = 1:testImage_height
    for ww = 1:testImage_width
        sum = resized_testImage(hh,ww,1)+resized_testImage(hh,ww,2)+resized_testImage(hh,ww,3);
        if ~(sum == bgSetting)
            idxImageHeight(end+1) = hh;
            idxImageWidth(end+1) = ww;
        end
    end
end

% Set the position to place the original image. The locations of the
% following images will be automatically updated based on this. For now, we
% always put all images at the center of the horizontal axis (set
% position_testImage_y to 0.5).
position_testImage_x = position_leftImage_x;
position_testImage_y = 0.5;
testImage_x = floor((canvas_width - testImage_width) * position_testImage_x) + 1;
testImage_y = floor((canvas_height - testImage_height) * position_testImage_y) + 1;

%% Add stripes on the background.
%
% Generate the background with horizontal stripes
for i = 1:stripe_height_pixel:canvas_height
    if mod(floor(i/stripe_height_pixel), 3) == 0
        canvas(i:i+stripe_height_pixel-1, :, 1) = 255; % Red
    elseif mod(floor(i/stripe_height_pixel), 3) == 1
        canvas(i:i+stripe_height_pixel-1, :, 2) = 255; % Green
    else
        canvas(i:i+stripe_height_pixel-1, :, 3) = 255; % Blue
    end
end

% Place the main image onto the canvas
for ii = 1:length(idxImageHeight)
    canvas(testImage_y+idxImageHeight(ii)-1, testImage_x+idxImageWidth(ii)-1, :) = resized_testImage(idxImageHeight(ii),idxImageWidth(ii),:);
end

%% We will add the same image with stripes at the center if we want.
%
% Put another image before the next section so that both images could place
% before the lines.
if strcmp(whichCenterImage, 'stripes')
    % Set the image location.
    position_centerImage_x = 0.5;
    position_centerImage_y = 0.5;
    centerImage_x = floor((canvas_width - testImage_width) * position_centerImage_x) + 1;
    centerImage_y = floor((canvas_height - testImage_height) * position_centerImage_y) + 1;

    % Place the main image onto the canvas
    for ii = 1:length(idxImageHeight)
        canvas(centerImage_y+idxImageHeight(ii)-1, centerImage_x+idxImageWidth(ii)-1, :) = resized_testImage(idxImageHeight(ii),idxImageWidth(ii),:);
    end
end

%% Draw one color of the stripes on top of the image.
%
% This part will simulate the color assimilation phenomena.
%
% Add stripe on top of the image here.
for i = 1:stripe_height_pixel:canvas_height
    switch whichColorStripes
        case 'red'
            if mod(floor(i/stripe_height_pixel), 3) == 0
                canvas(i:i+stripe_height_pixel-1, :, 1) = 255;
                canvas(i:i+stripe_height_pixel-1, :, 2) = 0;
                canvas(i:i+stripe_height_pixel-1, :, 3) = 0;
            end
        case 'green'
            if mod(floor(i/stripe_height_pixel), 3) == 1
                canvas(i:i+stripe_height_pixel-1, :, 1) = 0;
                canvas(i:i+stripe_height_pixel-1, :, 2) = 255;
                canvas(i:i+stripe_height_pixel-1, :, 3) = 0;
            end
        case 'blue'
            if mod(floor(i/stripe_height_pixel), 3) == 2
                canvas(i:i+stripe_height_pixel-1, :, 1) = 0;
                canvas(i:i+stripe_height_pixel-1, :, 2) = 0;
                canvas(i:i+stripe_height_pixel-1, :, 3) = 255;
            end
    end
end

%% Make color corrected image.
%
% Here, we generate a color corrected image that has the same average RGB
% values as the image with colored stripe on it.
testImageCrop = canvas(testImage_y:testImage_y+testImage_height-1, testImage_x:testImage_x+testImage_width-1, :);

% Get the part of the image where single stripe on.
testImageOneStripe = zeros(size(testImageCrop));
for ii = 1:length(idxImageHeight)
    testImageOneStripe(idxImageHeight(ii),idxImageWidth(ii),:) = testImageCrop(idxImageHeight(ii), idxImageWidth(ii), :);
end

% Extract color information per each channel.
%
% Original image.
for ii = 1:length(idxImageHeight)
    red_testImage(ii)   = resized_testImage(idxImageHeight(ii),idxImageWidth(ii),1);
    green_testImage(ii) = resized_testImage(idxImageHeight(ii),idxImageWidth(ii),2);
    blue_testImage(ii)  = resized_testImage(idxImageHeight(ii),idxImageWidth(ii),3);
end

% Image with stripes.
for ii = 1:length(idxImageHeight)
    red_testImageOneStripe(ii)   = testImageOneStripe(idxImageHeight(ii),idxImageWidth(ii),1);
    green_testImageOneStripe(ii) = testImageOneStripe(idxImageHeight(ii),idxImageWidth(ii),2);
    blue_testImageOneStripe(ii)  = testImageOneStripe(idxImageHeight(ii),idxImageWidth(ii),3);
end

% Get the color correction coefficient per each channel. Here, we simply
% match the mean R, G, B values independently.
coeffColorCorrect_red   = mean(red_testImageOneStripe)/mean(red_testImage);
coeffColorCorrect_green = mean(green_testImageOneStripe)/mean(green_testImage);
coeffColorCorrect_blue  = mean(blue_testImageOneStripe)/mean(blue_testImage);

% Color correct the original image.
colorCorrected_testImage = resized_testImage;
colorCorrected_testImage(:,:,1) = colorCorrected_testImage(:,:,1).*coeffColorCorrect_red;
colorCorrected_testImage(:,:,2) = colorCorrected_testImage(:,:,2).*coeffColorCorrect_green;
colorCorrected_testImage(:,:,3) = colorCorrected_testImage(:,:,3).*coeffColorCorrect_blue;

% Display the images
if (verbose)
    % Make a new figure.
    figure;

    % Original image.
    subplot(1,3,1);
    imshow(uint8(resized_testImage));
    title('Original');

    % Image with stripes.
    subplot(1,3,2);
    imshow(uint8(testImageOneStripe));
    title('From the canvas');

    % Color corrected image.
    subplot(1,3,3);
    imshow(uint8(colorCorrected_testImage));
    title('Color correction');
end

%% Now add the color corrected image to the canvas.
%
% Set the position to place the corrected image.
position_correctedImage_x = 1-position_testImage_x;
position_correctedImage_y = 0.5;
correctedImage_x = floor((canvas_width - testImage_width) * position_correctedImage_x) + 1;
correctedImage_y = floor((canvas_height - testImage_height) * position_correctedImage_y) + 1;

% Place the image onto the canvas.
for ii = 1:length(idxImageHeight)
    canvas(correctedImage_y+idxImageHeight(ii)-1, correctedImage_x+idxImageWidth(ii)-1, :) = ...
        colorCorrected_testImage(idxImageHeight(ii),idxImageWidth(ii),:);
end

%% Fianlly, add a test image at the center.
%
% We will place either an original image with stripes or color corrected
% image at the center to evaluate. Here, we add color corrected image at
% the center.
if strcmp(whichCenterImage,'color')
    
    % Set the position to place the corrected image.
    position_centerImage_x = 0.5;
    position_centerImage_y = 0.5;
    centerImage_x = floor((canvas_width - testImage_width) * position_centerImage_x) + 1;
    centerImage_y = floor((canvas_height - testImage_height) * position_centerImage_y) + 1;

    % Place the main image onto the canvas
    for ii = 1:length(idxImageHeight)
        canvas(centerImage_y+idxImageHeight(ii)-1, centerImage_x+idxImageWidth(ii)-1, :) = ...
            colorCorrected_testImage(idxImageHeight(ii),idxImageWidth(ii),:);
    end
end

%% Display the final image canvas.
figure;
imshow(uint8(canvas));
title('Simulated screen image')
