%% MakeImageCanvas.
%
% This routine generates the image canvas to test color assimilation
% phenomena.

% History:
%    04/08/24    smo    - Started on it.

%% Initialize.
clear; close all;

%% Place a main image on the canvas.
%
% Load your main image
testImage = imread('Semin.png');

% Define the size of the canvas.
canvas_width = 1920;
canvas_height = 1080;

% Create a blank canvas
canvas = zeros(canvas_height, canvas_width, 3);

% Define the size of the main image
testImage_width = canvas_width*0.3;
testImage_height = canvas_height*0.4;

% Resize the main image to fit in the canvas
resized_testImage = imresize(testImage, [testImage_height, testImage_width]);
idxImageHeight = [];
idxImageWidth = [];
for hh = 1:testImage_height
    for ww = 1:testImage_width
        sum = resized_testImage(hh,ww,1)+resized_testImage(hh,ww,2)+resized_testImage(hh,ww,3);

        % Find the location where the image content exist.
        if ~(sum == 0)
            idxImageHeight(end+1) = hh;
            idxImageWidth(end+1) = ww;
        end
    end
end

% Calculate the position to place the image at the center
position_testImage_x = 0.2;
position_testImage_y = 0.5;
testImage_x = floor((canvas_width - testImage_width) * position_testImage_x) + 1;
testImage_y = floor((canvas_height - testImage_height) * position_testImage_y) + 1;

% Place the main image onto the canvas
canvas(testImage_y:testImage_y+testImage_height-1, testImage_x:testImage_x+testImage_width-1, :) = resized_testImage;

%% Add stripes on the background.
%
% Define the size of the stripes
stripe_height = 5;

% Generate the background with horizontal stripes
for i = 1:stripe_height:canvas_height
    if mod(floor(i/stripe_height), 3) == 0
        canvas(i:i+stripe_height-1, :, 1) = 255; % Red
    elseif mod(floor(i/stripe_height), 3) == 1
        canvas(i:i+stripe_height-1, :, 2) = 255; % Green
    else
        canvas(i:i+stripe_height-1, :, 3) = 255; % Blue
    end
end

% Place the main image onto the canvas
for ii = 1:length(idxImageHeight)
    canvas(testImage_y+idxImageHeight(ii)-1, testImage_x+idxImageWidth(ii)-1, :) = resized_testImage(idxImageHeight(ii),idxImageWidth(ii),:);
end

%% Draw one color of the stripes on top of the image.
%
% This part will simulate the color assimilation phenomena.

% Choose the color among 'Red', 'Green', 'Blue'.
whichColor = 'Red';

% Add stripe on top of the image here.
for i = 1:stripe_height:canvas_height
    switch whichColor
        case 'Red'
            if mod(floor(i/stripe_height), 3) == 0
                canvas(i:i+stripe_height-1, :, 1) = 255;
                canvas(i:i+stripe_height-1, :, 2) = 0;
                canvas(i:i+stripe_height-1, :, 3) = 0;
            end
        case 'Green'
            if mod(floor(i/stripe_height), 3) == 1
                canvas(i:i+stripe_height-1, :, 1) = 0;
                canvas(i:i+stripe_height-1, :, 2) = 255;
                canvas(i:i+stripe_height-1, :, 3) = 0;
            end
        case 'Blue'
            if mod(floor(i/stripe_height), 3) == 2
                canvas(i:i+stripe_height-1, :, 1) = 0;
                canvas(i:i+stripe_height-1, :, 2) = 0;
                canvas(i:i+stripe_height-1, :, 3) = 255;
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

% Get the color correction coefficient per each channel.
coeffColorCorrect_red   = mean(red_testImageOneStripe)/mean(red_testImage);
coeffColorCorrect_green = mean(green_testImageOneStripe)/mean(green_testImage);
coeffColorCorrect_blue  = mean(blue_testImageOneStripe)/mean(blue_testImage);

% Color correct the original image.
colorCorrected_testImage = resized_testImage;
colorCorrected_testImage(:,:,1) = colorCorrected_testImage(:,:,1).*coeffColorCorrect_red;
colorCorrected_testImage(:,:,2) = colorCorrected_testImage(:,:,2).*coeffColorCorrect_green;
colorCorrected_testImage(:,:,3) = colorCorrected_testImage(:,:,3).*coeffColorCorrect_blue;

% Display the images
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

%% Now add the color corrected image to the canvas.
%
% Set the position to place the corrected image.
position_correctedImage_x = 0.8;
position_correctedImage_y = 0.5;
correctedImage_x = floor((canvas_width - testImage_width) * position_correctedImage_x) + 1;
correctedImage_y = floor((canvas_height - testImage_height) * position_correctedImage_y) + 1;

% Place the main image onto the canvas
for ii = 1:length(idxImageHeight)
    canvas(correctedImage_y+idxImageHeight(ii)-1, correctedImage_x+idxImageWidth(ii)-1, :) = colorCorrected_testImage(idxImageHeight(ii),idxImageWidth(ii),:);
end

%% Display the final image canvas.
figure;
imshow(uint8(canvas));
title('Simulated screen image')
