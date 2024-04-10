function [canvas] = MakeImageCanvas(testImage,options)
% Make an image canvas with given input image.
%
% Syntax:
%    [canvas] = MakeImageCanvas(image)
%
% Description:
%    This routine generates an image canvas based on the image that is
%    given as an input. The output canvas contains three images in parallel
%    horizontally where each image is either mixed with stripes or color
%    corrected.
%
%    We wrote this routine to generate test stimuli for Color Assimilation
%    project.
%
% Inputs:
%    image                    - An input image to generate a canvas.
%
% Outputs:
%    canvas                   - Output image with three corrected images.
%                               This image should be ready to present using
%                               psychtoolbox for the project.
%
% Optional key/value pairs:
%    testImageSize            - Decide the size of the test images. It
%                               is decided by the ratio of the height of
%                               the canvas. Default to 0.15.
%    whichCenterImage         - Decide which image to place at the center
%                               of the canvas. For the experiment, we will
%                               put either the input image with stripes
%                               ('stripes') on or color corrected image
%                               ('color'). Default to 'color'.
%   stripe_height_pixel       - Define the height of each horizontal stripe
%                               on the background of the cavas. It's in
%                               pixel unit and default to 5.
%   whichColorStripes         - Define the color of stripes to place on top
%                               of the image. This will make color
%                               assimilation phenomena. Choose among 'red',
%                               'green', 'blue'. Default to 'red'.
%   position_leftImage_x      - Define the position of the left sided image
%                               on the canvas. This will decide the
%                               positions of all three images on the
%                               canvas. Choose between 0 to 1, where 0.5
%                               means the center of the canvas, 0 is the
%                               left end and 1 is the right end. Default to
%                               0.1
%   sizeCanvas                - Decide the size of the canvas to generate.
%                               It may be matched with the screen size that
%                               you want to present the image. Default to
%                               [1920 1080] as [width height] of the
%                               screen in pixe.
%   verbose                   - Control the plot and alarm messages.
%                               Default to false.
%
% See also:
%    MakeImageCanvas_demo.

% History:
%    04/09/24    smo    - Made it as a function.

%% Set variables.
arguments
    testImage
    options.testImageSize = 0.15
    options.whichCenterImage = 'color'
    options.stripe_height_pixel (1,1) = 5
    options.whichColorStripes = 'red'
    options.position_leftImage_x (1,1) = 0.1
    options.verbose (1,1) = false
    options.sizeCanvas (1,2) = [1920 1080]
end

% Define the size of the canvas.
canvas_width = options.sizeCanvas(1);
canvas_height = options.sizeCanvas(2);

%% Create a canvas to place images on.
%
% Create a blank canvas.
canvas = zeros(canvas_height, canvas_width, 3);

% Get the size of original input image.
[originalImage_height originalImage_width ~] = size(testImage);
ratioWidthToHeight_original = originalImage_width/originalImage_height;

% Define the size of the test image. For now, we keep the original
% height:width ratio.
testImage_height = canvas_height * options.testImageSize;
testImage_width = testImage_height * ratioWidthToHeight_original;

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
position_testImage_x = options.position_leftImage_x;
position_testImage_y = 0.5;
testImage_x = floor((canvas_width - testImage_width) * position_testImage_x) + 1;
testImage_y = floor((canvas_height - testImage_height) * position_testImage_y) + 1;

%% Add stripes on the background.
%
% Generate the background with horizontal stripes
for i = 1 : options.stripe_height_pixel : canvas_height
    if mod(floor(i/options.stripe_height_pixel), 3) == 0
        canvas(i:i+options.stripe_height_pixel-1, :, 1) = 255; % Red
    elseif mod(floor(i/options.stripe_height_pixel), 3) == 1
        canvas(i:i+options.stripe_height_pixel-1, :, 2) = 255; % Green
    else
        canvas(i:i+options.stripe_height_pixel-1, :, 3) = 255; % Blue
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
if strcmp(options.whichCenterImage, 'stripes')
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
for i = 1 : options.stripe_height_pixel : canvas_height
    switch options.whichColorStripes
        case 'red'
            if mod(floor(i/options.stripe_height_pixel), 3) == 0
                canvas(i:i+options.stripe_height_pixel-1, :, 1) = 255;
                canvas(i:i+options.stripe_height_pixel-1, :, 2) = 0;
                canvas(i:i+options.stripe_height_pixel-1, :, 3) = 0;
            end
        case 'green'
            if mod(floor(i/options.stripe_height_pixel), 3) == 1
                canvas(i:i+options.stripe_height_pixel-1, :, 1) = 0;
                canvas(i:i+options.stripe_height_pixel-1, :, 2) = 255;
                canvas(i:i+options.stripe_height_pixel-1, :, 3) = 0;
            end
        case 'blue'
            if mod(floor(i/options.stripe_height_pixel), 3) == 2
                canvas(i:i+options.stripe_height_pixel-1, :, 1) = 0;
                canvas(i:i+options.stripe_height_pixel-1, :, 2) = 0;
                canvas(i:i+options.stripe_height_pixel-1, :, 3) = 255;
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
if (options.verbose)
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
if strcmp(options.whichCenterImage,'color')

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

%% Change the class of the canvas to uint8.
canvas = uint8(canvas);

%% Display the final image canvas.
if (options.verbose)
    figure;
    imshow(canvas);
    title('Simulated screen image')
end
