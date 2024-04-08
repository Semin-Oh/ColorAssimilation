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

% Calculate the position to place the main image at the center
main_image_x = floor((canvas_width - testImage_width) * 0.5) + 1;
main_image_y = floor((canvas_height - testImage_height) * 0.5) + 1;

% Place the main image onto the canvas
canvas(main_image_y:main_image_y+testImage_height-1, main_image_x:main_image_x+testImage_width-1, :) = resized_testImage;

%% Define the size of the stripes
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
    canvas(main_image_y+idxImageHeight(ii)-1, main_image_x+idxImageWidth(ii)-1, :) = resized_testImage(idxImageHeight(ii),idxImageWidth(ii),:);
end

%% Now draw one color of the stripe on top of the image.
chooseColor = 'Red';
for i = 1:stripe_height:canvas_height
    switch chooseColor
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

%% Display the final image
figure;
imshow(uint8(canvas));
