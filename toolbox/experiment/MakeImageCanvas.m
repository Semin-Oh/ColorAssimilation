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
%    image                    - An input image to generate a canvas. This
%                               can be empty ('[]') if you want to generate
%                               canvas without image.
%
% Outputs:
%    canvas                   - Output image with three corrected images.
%                               This image should be ready to present using
%                               psychtoolbox for the project.
%
% Optional key/value pairs:
%    testImageSize            - Decide the size of the test images. It
%                               is decided by the ratio of the height of
%                               the canvas. Default to 0.40.
%    addImageRight            - When it sets to true, add a mirrored image
%                               on the right side of the canvas and place
%                               the color corrected image on the center.
%                               Default to false.
%    stripeHeightPixel        - Define the height of each horizontal stripe
%                               on the background of the cavas. It's in
%                               pixel unit and default to 5.
%    whichColorStripes        - Define the color of stripes to place on top
%                               of the image. This will make color
%                               assimilation phenomena. Choose among 'red',
%                               'green', 'blue'. Default to 'red'.
%    intensityStripe          - Decide the intensity of the stripe in
%                               pixel. For now, it is decided on 8-bit
%                               system, so it should be within the range of
%                               0-255. Default to 255, the maximum.
%    position_leftImage_x     - Define the position of the left sided image
%                               on the canvas. This will decide the
%                               positions of all three images on the
%                               canvas. Choose between 0 to 1, where 0.5
%                               means the center of the canvas, 0 is the
%                               left end and 1 is the right end. Default to
%                               0.1
%    sizeCanvas               - Decide the size of the canvas to generate.
%                               It may be matched with the screen size that
%                               you want to present the image. Default to
%                               [1920 1080] as [width height] of the
%                               screen in pixe.
%    colorCorrectMethod       - Decide the color correcting method that
%                               corresponds to the test image with stripes
%                               on. Default to 'mean'.
%    nChannelsColorCorrect    - The number of channels to correct when
%                               generating color corrected image. You can
%                               set this value to 1 if you want to correct
%                               only the targeting channel, otherwise it
%                               will correct all three channels. Default to
%                               1.
%    intensityColorCorrect    - Decide the color correction power on
%                               the test image. If it sets to empty, the
%                               amount of color correction would be solely
%                               decided by the ratio of the stripes on the
%                               image with stripes. Default to empty.
%    verbose                  - Control the plot and alarm messages.
%                               Default to false.
%
% See also:
%    MakeImageCanvas_demo.

% History:
%    04/09/24    smo    - Made it as a function.
%    04/16/24    smo    - Added a new color correction method after meeting
%                         with Karl.
%    04/25/24    smo    - Added an option to make a canvas without image so
%                         that we can generate a null canvas with only
%                         stripes.
%    06/19/24    smo    - Added an option to control the intensity of the
%                         color correction after meeting with Karl.
%    07/29/24    smo    - Substituting the part converting from the digital
%                         RGB to the CIE XYZ values with the function.
%    09/23/24    smo    - Now we can either put two or three images on the
%                         canvas.
%    10/01/24    smo    - Added a color correction on the u'v' coordinates.

%% Set variables.
arguments
    testImage
    options.whichDisplay = 'curvedDisplay'
    options.testImageSize = 0.40
    options.addImageRight = false;
    options.stripeHeightPixel (1,1) = 5
    options.whichColorStripes = 'red'
    options.intensityStripe (1,1) = 255
    options.position_leftImage_x (1,1) = 0.1
    options.verbose (1,1) = false
    options.sizeCanvas (1,2) = [1920 1080]
    options.colorCorrectMethod = 'uv'
    options.nChannelsColorCorrect (1,1) = 1
    options.intensityColorCorrect = []
end

% Define the size of the canvas.
canvas_width = options.sizeCanvas(1);
canvas_height = options.sizeCanvas(2);

% Define the index of the color stripes. This index will control when we
% generate a color corrected image.
colorStripeOptions = {'red','green','blue'};
idxColorStripe = find(strcmp(colorStripeOptions, options.whichColorStripes));

%% Choose which diplay to use.
switch options.whichDisplay
    case 'sRGB'
        % Matrix to convert from the linear RGB to XYZ.
        xyY_displayPrimary = [0.6400 0.3000 0.1500; 0.3300 0.6000 0.0600; 0.2126 0.7152 0.0722];
        M_RGB2XYZ = [0.4124 0.3576 0.1805; 0.2126 0.7152 0.0722; 0.0193 0.1192 0.9505];
        gamma = 2.2;

    case 'curvedDisplay'
        % Gamma and the 3x3 matrix are set based on the RGB channel
        % on the centered display. See detailed calibration results
        % in the routine 'CalDisplay.m'. The values from the
        % routine.
        xyY_displayPrimary = [0.6781 0.2740 0.1574; 0.3084 0.6616 0.0648; 17.0886 61.3867 6.1283];
        M_RGB2XYZ = xyYToXYZ(xyY_displayPrimary);
        gamma = 2.2669;
end

% Get white point.
XYZ_white = sum(M_RGB2XYZ,2);

%% Create a canvas to place images on.
%
% Create a blank canvas.
canvas = zeros(canvas_height, canvas_width, 3);

% Get the size of original input image.
if ~isempty(testImage)
    [originalImage_height originalImage_width ~] = size(testImage);
    ratioWidthToHeight_original = originalImage_width/originalImage_height;

    % Define the size of the test image. For now, we keep the original
    % height:width ratio. We will round up so that we make sure image size
    % in integer number in pixel.
    testImage_height = ceil(canvas_height * options.testImageSize);
    testImage_width = ceil(testImage_height * ratioWidthToHeight_original);

    % Resize the test image to fit in the canvas.
    testImageRaw = imresize(testImage, [testImage_height, testImage_width]);

    % Find the location where the image content exist. The idea here is to
    % treat the black (0, 0, 0) part as a background and it will be excluded in
    % this index. Therefore, the number of pixels of the image content is the
    % same as the length of either 'idxImageHeight' or 'idxImageWidth'.
    idxImageHeight = [];
    idxImageWidth = [];
    bgSetting = 0;
    for hh = 1:testImage_height
        for ww = 1:testImage_width
            summation = testImageRaw(hh,ww,1)+testImageRaw(hh,ww,2)+testImageRaw(hh,ww,3);
            if ~(summation == bgSetting)
                idxImageHeight(end+1) = hh;
                idxImageWidth(end+1) = ww;
            end
        end
    end

    %% Image on the left.
    %
    % Set the position to place the original image. The locations of the
    % following images will be automatically updated based on this. For now, we
    % always put all images at the center of the horizontal axis (set
    % position_testImage_y to 0.5).
    position_testImage_x = options.position_leftImage_x;
    position_testImage_y = 0.5;
    testImage_x = floor((canvas_width - testImage_width) * position_testImage_x) + 1;
    testImage_y = floor((canvas_height - testImage_height) * position_testImage_y) + 1;
end

%% Add stripes on the background.
%
% Generate the background with horizontal stripes
for i = 1 : options.stripeHeightPixel : canvas_height
    if mod(floor(i/options.stripeHeightPixel), 3) == 0
        % Red
        canvas(i:i+options.stripeHeightPixel-1, :, 1) = options.intensityStripe;
    elseif mod(floor(i/options.stripeHeightPixel), 3) == 1
        % Green.
        canvas(i:i+options.stripeHeightPixel-1, :, 2) = options.intensityStripe;
    else
        % Blue.
        canvas(i:i+options.stripeHeightPixel-1, :, 3) = options.intensityStripe;
    end
end

% Place the main image onto the canvas
if ~isempty(testImage)
    for ii = 1:length(idxImageHeight)
        canvas(testImage_y+idxImageHeight(ii)-1, testImage_x+idxImageWidth(ii)-1, :) = testImageRaw(idxImageHeight(ii),idxImageWidth(ii),:);
    end
end

%% We will add the same image with stripes on the right if we want.
%
% Put another image before the next section so that both images could place
% before the lines.
if ~isempty(testImage)
    if (options.addImageRight)
        % Set the image location.
        position_centerImage_x = 1-position_testImage_x;
        position_centerImage_y = 0.5;
        centerImage_x = floor((canvas_width - testImage_width) * position_centerImage_x) + 1;
        centerImage_y = floor((canvas_height - testImage_height) * position_centerImage_y) + 1;

        % Place the main image onto the canvas
        for ii = 1:length(idxImageHeight)
            canvas(centerImage_y+idxImageHeight(ii)-1, centerImage_x+idxImageWidth(ii)-1, :) = testImageRaw(idxImageHeight(ii),idxImageWidth(ii),:);
        end
    end

    %% Draw one color of the stripes on top of the image.
    %
    % This part will simulate the color assimilation phenomena.
    %
    % Add stripe on top of the image here.
    for i = 1 : options.stripeHeightPixel : canvas_height
        switch options.whichColorStripes
            case 'red'
                if mod(floor(i/options.stripeHeightPixel), 3) == 0
                    canvas(i:i+options.stripeHeightPixel-1, :, 1) = options.intensityStripe;
                    canvas(i:i+options.stripeHeightPixel-1, :, 2) = 0;
                    canvas(i:i+options.stripeHeightPixel-1, :, 3) = 0;
                end
            case 'green'
                if mod(floor(i/options.stripeHeightPixel), 3) == 1
                    canvas(i:i+options.stripeHeightPixel-1, :, 1) = 0;
                    canvas(i:i+options.stripeHeightPixel-1, :, 2) = options.intensityStripe;
                    canvas(i:i+options.stripeHeightPixel-1, :, 3) = 0;
                end
            case 'blue'
                if mod(floor(i/options.stripeHeightPixel), 3) == 2
                    canvas(i:i+options.stripeHeightPixel-1, :, 1) = 0;
                    canvas(i:i+options.stripeHeightPixel-1, :, 2) = 0;
                    canvas(i:i+options.stripeHeightPixel-1, :, 3) = options.intensityStripe;
                end
        end
    end

    %% Make color corrected image.
    %
    % Get the cropped part of the test image. This image still has the stripes
    % on the background.
    testImageCrop = canvas(testImage_y:testImage_y+testImage_height-1, testImage_x:testImage_x+testImage_width-1, :);

    % Extract the test image where single stripe on. This image does not have
    % the stripes on the background, only the part where the test image exist.
    % The size of the images are the same.
    testImageStripe = zeros(size(testImageCrop));
    for ii = 1:length(idxImageHeight)
        testImageStripe(idxImageHeight(ii),idxImageWidth(ii),:) = testImageCrop(idxImageHeight(ii), idxImageWidth(ii), :);
    end

    % Extract color information per each channel.
    %
    % Original image.
    for ii = 1:length(idxImageHeight)
        red_testImage(ii)   = testImageRaw(idxImageHeight(ii),idxImageWidth(ii),1);
        green_testImage(ii) = testImageRaw(idxImageHeight(ii),idxImageWidth(ii),2);
        blue_testImage(ii)  = testImageRaw(idxImageHeight(ii),idxImageWidth(ii),3);
    end

    % Image with stripes.
    for ii = 1:length(idxImageHeight)
        red_testImageStripe(ii)   = testImageStripe(idxImageHeight(ii),idxImageWidth(ii),1);
        green_testImageStripe(ii) = testImageStripe(idxImageHeight(ii),idxImageWidth(ii),2);
        blue_testImageStripe(ii)  = testImageStripe(idxImageHeight(ii),idxImageWidth(ii),3);
    end

    % We color correct the original image. We get the resized original
    % image and correct color in the next step to this image.
    testImageColorCorrect = testImageRaw;

    % Here we choose which method to color correct the image.
    switch options.colorCorrectMethod
        % For this method, get the color correction coefficient per each channel.
        % Here, we simply match the mean R, G, B values independently.
        case 'meanRGB'
            coeffColorCorrect_red   = mean(red_testImageStripe)/mean(red_testImage);
            coeffColorCorrect_green = mean(green_testImageStripe)/mean(green_testImage);
            coeffColorCorrect_blue  = mean(blue_testImageStripe)/mean(blue_testImage);

            % Here, we can either correct one target channel or all channels.
            %
            % For example, when we generate red corrected image, we can either only
            % correct the red channel or all three channels. Still thinking about
            % what's more logical way to do.
            if options.nChannelsColorCorrect == 1
                % Correct only the targeting channel, while the others remain the same.
                switch options.whichColorStripes
                    case 'red'
                        testImageColorCorrect(:,:,1) = testImageColorCorrect(:,:,1).*coeffColorCorrect_red;
                    case 'green'
                        testImageColorCorrect(:,:,2) = testImageColorCorrect(:,:,2).*coeffColorCorrect_green;
                    case 'blue'
                        testImageColorCorrect(:,:,3) = testImageColorCorrect(:,:,3).*coeffColorCorrect_blue;
                end
            else
                % Correct all three channels.
                testImageColorCorrect(:,:,1) = testImageColorCorrect(:,:,1).*coeffColorCorrect_red;
                testImageColorCorrect(:,:,2) = testImageColorCorrect(:,:,2).*coeffColorCorrect_green;
                testImageColorCorrect(:,:,3) = testImageColorCorrect(:,:,3).*coeffColorCorrect_blue;
            end

        case 'addRGB'
            % Calculate the proportion of the pixels that are stripes within
            % the image. This should be close to 1/3 (~33%) as we place three
            % different stripes - red, green, and blue - repeatedly.
            switch options.whichColorStripes
                case 'red'
                    targetCh_testImageStripe = red_testImageStripe;
                case 'green'
                    targetCh_testImageStripe = green_testImageStripe;
                case 'blue'
                    targetCh_testImageStripe = blue_testImageStripe;
            end

            % Find the number of the intensity of the stripes within the image.
            % 'ratioStripes' should be close to 1/3 (~33%).
            ratioStripes = length(find(targetCh_testImageStripe == options.intensityStripe))./length(targetCh_testImageStripe);

            % Color correction happens here. Here we only correct one
            % targeting channel. The final scale ('ratioColorCorrect')
            % should be within the range 0-1.
            if ~isempty(options.intensityColorCorrect)
                ratioColorCorrect = options.intensityColorCorrect;
            else
                ratioColorCorrect = ratioStripes;
            end

            % Check if the scaling factor is within the range 0-1.
            maxRatioColorCorrect = 1;
            minRatioColorCorrect = 0;
            if ratioColorCorrect > maxRatioColorCorrect
                ratioColorCorrect = maxRatioColorCorrect;
            elseif ratioColorCorrect < minRatioColorCorrect
                ratioColorCorrect = minRatioColorCorrect;
            end

            % Color correction happens here.
            %
            % Target channel.
            colorCorrectionPerPixelOneChannel = ratioColorCorrect .* (options.intensityStripe - testImageRaw(:,:,idxColorStripe));
            testImageColorCorrect(:,:,idxColorStripe) = testImageColorCorrect(:,:,idxColorStripe) + colorCorrectionPerPixelOneChannel;

            % The other channels. Commented out for now, we can think about
            % correcting the other channels as well. When we also correct
            % the other channels, it basically gives the same result as the
            % above 'mean' method. It makes the test image a little too
            % saturated by eye. The number 2 and 3 should be updated below
            % to make it work correctly per different target channel.
            %
            % colorCorrectionPerPixelOneChannel = ratioColorCorrect .* resized_testImage(:,:,2);
            % colorCorrected_testImage(:,:,2) = colorCorrected_testImage(:,:,2) - colorCorrectionPerPixelOneChannel;
            %
            % colorCorrectionPerPixelOneChannel = ratioColorCorrect .* resized_testImage(:,:,3);
            % colorCorrected_testImage(:,:,3) = colorCorrected_testImage(:,:,3) - colorCorrectionPerPixelOneChannel;

        case 'uv'
            % Convert the original test image from dRGB to u'v'.
            RGB_testImage = [red_testImage; green_testImage; blue_testImage];
            XYZ_testImage = RGBToXYZ(RGB_testImage,M_RGB2XYZ,gamma);
            uvY_testImage = XYZTouvY(XYZ_testImage);

            % Color correction happens here on the u'v' coordinates. We will
            % correct the color of each pixel in the image proportinally to the
            % primary on the u'v' coordinates.
            %
            % Get the base array in u'v' of the original test image.
            uvY_colorCorrectedImage = uvY_testImage;

            % Get u'v' coordinates of the target primary. We will correct
            % the color based on this anchor.
            uv_displayPrimary = xyTouv(xyY_displayPrimary(1:2,:));
            uv_targetColorStripe = uv_displayPrimary(:,idxColorStripe);

            % Color correction happens here. We correct pixel by pixel
            % proportionally from one to the primary anchor by desired
            % ratio. The intensity of color correction could be customized
            % as it's set as an option. The luminance of each pixel will be
            % the same as the original, only chromaticity will be
            % modulated. The variable 'options.intensityColorCorrect'
            % should be within 0-1 and 1 means all chromaticity becomes the
            % same as the primary anchor.
            uvY_colorCorrectedImage(1:2,:) = uvY_testImage(1:2,:) + options.intensityColorCorrect * (uv_targetColorStripe - uvY_testImage(1:2,:));

            % Calculate the digital RGB values from the u'v' coordinates to
            % convert it to the color corrected image.
            XYZ_testImage_correct = uvYToXYZ(uvY_colorCorrectedImage);
            RGB_testImage_correct = XYZToRGB(XYZ_testImage_correct,M_RGB2XYZ,gamma);

            % Back to the image. Idea here is getting the original test
            % image as a base array and update the pixels where actual
            % images are.
            testImageColorCorrect = testImageRaw;
            for ii = 1:length(idxImageHeight)
                testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),1) = RGB_testImage_correct(1,ii);
                testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),2) = RGB_testImage_correct(2,ii);
                testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),3) = RGB_testImage_correct(3,ii);
            end
    end

    % Remove the background of the color corrected image.
    testImageColorCorrect_temp = zeros(size(testImageColorCorrect));
    for ii = 1:length(idxImageHeight)
        testImageColorCorrect_temp(idxImageHeight(ii),idxImageWidth(ii),:) = testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),:);
    end
    testImageColorCorrect = testImageColorCorrect_temp;

    % Get color information of the color corrected image for comparison.
    for ii = 1:length(idxImageHeight)
        red_colorCorrectedImage(ii)   = testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),1);
        green_colorCorrectedImage(ii) = testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),2);
        blue_colorCorrectedImage(ii)  = testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),3);
    end

    % Display the images if you want.
    if (options.verbose)
        % Make a new figure.
        figure;

        % Original image.
        subplot(1,3,1);
        imshow(uint8(testImageRaw));
        title('Original');

        % Image with stripes.
        subplot(1,3,2);
        imshow(uint8(testImageStripe));
        title('From the canvas');

        % Color corrected image.
        subplot(1,3,3);
        imshow(uint8(testImageColorCorrect));
        title('Color correction');
    end

    %% Now add the color corrected image to the canvas.
    %
    % Set the position to place the corrected image. We can choose to place
    % the color corrected image in the middle on the right side of the
    % canvas.
    if (~options.addImageRight)
        position_correctedImage_x = 1-position_testImage_x;
        position_correctedImage_y = 0.5;
        correctedImage_x = floor((canvas_width - testImage_width) * position_correctedImage_x) + 1;
        correctedImage_y = floor((canvas_height - testImage_height) * position_correctedImage_y) + 1;

        % Place the image onto the canvas.
        for ii = 1:length(idxImageHeight)
            canvas(correctedImage_y+idxImageHeight(ii)-1, correctedImage_x+idxImageWidth(ii)-1, :) = ...
                testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),:);
        end
    end

    %% Add a striped image on the center if you want.
    %
    % We will place either an original image with stripes or color corrected
    % image at the center to evaluate. Here, we add color corrected image at
    % the center.
    if (options.addImageRight)
        % Set the position to place the corrected image.
        position_centerImage_x = 0.5;
        position_centerImage_y = 0.5;
        centerImage_x = floor((canvas_width - testImage_width) * position_centerImage_x) + 1;
        centerImage_y = floor((canvas_height - testImage_height) * position_centerImage_y) + 1;

        % Place the main image onto the canvas
        for ii = 1:length(idxImageHeight)
            canvas(centerImage_y+idxImageHeight(ii)-1, centerImage_x+idxImageWidth(ii)-1, :) = ...
                testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),:);
        end
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

%% Check how color information is changed.
%
if ~isempty(testImage)
    % Get the mean RGB values of the original image.
    meanRed_testImage = mean(red_testImage);
    meanGreen_testImage = mean(green_testImage);
    meanBlue_testImage = mean(blue_testImage);
    meanRGB_testImage = [meanRed_testImage; meanGreen_testImage; meanBlue_testImage];

    % Image with stripes.
    meanRed_testImageStripe = mean(red_testImageStripe);
    meanGreen_testImageStripe = mean(green_testImageStripe);
    meanBlue_testImageStripe = mean(blue_testImageStripe);
    meanRGB_testImageStripe = [meanRed_testImageStripe; meanGreen_testImageStripe; meanBlue_testImageStripe];

    % Color corrected image.
    meanRed_colorCorrectedImage = mean(red_colorCorrectedImage);
    meanGreen_colorCorrectedImage = mean(green_colorCorrectedImage);
    meanBlue_colorCorrectedImage = mean(blue_colorCorrectedImage);
    meanRGB_colorCorrectedImage = [meanRed_colorCorrectedImage; meanGreen_colorCorrectedImage; meanBlue_colorCorrectedImage];

    % Plot the comparison results across images.
    if (options.verbose)
        % Compare the digital RGB values across the images in 3-D.
        figure;
        markerColorOptions = {'r','g','b'};
        sgtitle('Image profile comparison');
        subplot(1,4,1);
        scatter3(red_testImage,green_testImage,blue_testImage,'k+'); hold on;
        scatter3(red_testImageStripe,green_testImageStripe,blue_testImageStripe,'k.');
        scatter3(red_colorCorrectedImage,green_colorCorrectedImage,blue_colorCorrectedImage,append(markerColorOptions{idxColorStripe},'.'));
        xlabel('dR','fontsize',13);
        ylabel('dG','fontsize',13);
        zlabel('dB','fontsize',13);
        legend('Original','Stripes','Color-correct','Location','northeast','fontsize',11);
        xlim([0 255]);
        ylim([0 255]);
        zlim([0 255]);
        grid on;
        title('3D (dRGB)','fontsize',11);

        % Comparison in 2-D: dG vs. dR.
        subplot(1,4,2); hold on;
        plot(green_testImage,red_testImage,'k+');
        plot(green_testImageStripe,red_testImageStripe,'k.');
        plot(green_colorCorrectedImage,red_colorCorrectedImage,append(markerColorOptions{idxColorStripe},'.'));
        xlabel('dG','fontsize',13);
        ylabel('dR','fontsize',13);
        legend('Original','Stripes','Color-correct','Location','southeast','fontsize',11);
        xlim([0 255]);
        ylim([0 255]);
        grid on;
        title('2D (dG vs. dR)','fontsize',11);

        % Comparison in 2-D: dG vs. dB.
        subplot(1,4,3); hold on;
        plot(green_testImage,blue_testImage,'k+');
        plot(green_testImageStripe,blue_testImageStripe,'k.');
        plot(green_colorCorrectedImage,blue_colorCorrectedImage,append(markerColorOptions{idxColorStripe},'.'));
        xlabel('dG','fontsize',13);
        ylabel('dB','fontsize',13);
        legend('Original','Stripes','Color-correct','Location','southeast','fontsize',11);
        xlim([0 255]);
        ylim([0 255]);
        grid on;
        title('2D (dG vs. dB)','fontsize',11);

        % Comparison in 2-D: dR vs. dB.
        subplot(1,4,4); hold on;
        plot(red_testImage,blue_testImage,'k+');
        plot(red_testImageStripe,blue_testImageStripe,'k.');
        plot(red_colorCorrectedImage,blue_colorCorrectedImage,append(markerColorOptions{idxColorStripe},'.'));
        xlabel('dR','fontsize',13);
        ylabel('dB','fontsize',13);
        legend('Original','Stripes','Color-correct','Location','southeast','fontsize',11);
        xlim([0 255]);
        ylim([0 255]);
        grid on;
        title('2D (dR vs. dB)','fontsize',11);

        % Calculate the CIE coordinates here.
        %
        % Original image.
        xyY_testImage = XYZToxyY(XYZ_testImage);
        uvY_testImage = XYZTouvY(XYZ_testImage);

        % Image with stripes.
        RGB_testImageStripe = [red_testImageStripe; green_testImageStripe; blue_testImageStripe];
        XYZ_testImageStripe = RGBToXYZ(RGB_testImageStripe,M_RGB2XYZ,gamma);
        xyY_testImageStripe = XYZToxyY(XYZ_testImageStripe);
        uvY_testImageStripe = XYZTouvY(XYZ_testImageStripe);

        % Color corrected image.
        RGB_colorCorrectedImage =  [red_colorCorrectedImage; green_colorCorrectedImage; blue_colorCorrectedImage];
        XYZ_colorCorrectedImage = RGBToXYZ(RGB_colorCorrectedImage,M_RGB2XYZ,gamma);
        xyY_colorCorrectedImage = XYZToxyY(XYZ_colorCorrectedImage);
        uvY_colorCorrectedImage = XYZTouvY(XYZ_colorCorrectedImage);

        % Plot the color profiles on the u'v' coordinates.
        figure; hold on;
        plot(uvY_testImage(1,:),uvY_testImage(2,:),'k+');
        plot(uvY_testImageStripe(1,:),uvY_testImageStripe(2,:),'k.');
        plot(uvY_colorCorrectedImage(1,:),uvY_colorCorrectedImage(2,:),'r.');

        % Display gamut.
        plot([uv_displayPrimary(1,:) uv_displayPrimary(1,1)], [uv_displayPrimary(2,:) uv_displayPrimary(2,1)],'k-','LineWidth',1);

        % Plackian locus.
        load T_xyzJuddVos
        T_XYZ = T_xyzJuddVos;
        T_xy = [T_XYZ(1,:)./sum(T_XYZ); T_XYZ(2,:)./sum(T_XYZ)];
        T_uv = xyTouv(T_xy);
        plot([T_uv(1,:) T_uv(1,1)], [T_uv(2,:) T_uv(2,1)], 'k-');

        % Figure stuffs.
        xlim([0 0.7]);
        ylim([0 0.7]);
        xlabel('CIE u-prime','fontsize',13);
        ylabel('CIE v-prime','fontsize',13);
        legend('Original','Stripes','Color-correct','Display gamut',...
            'Location','southeast','fontsize',11);
        title('Image profile on CIE uv-prime coordinates');
    end
end

%% Parts calculating CIECAM and CIELAB stats. Keep here for now as we are not using right now.
%
% Calculate the CIECAM02 stats and modify it as you want.
% LA = 20;
% JCH_testImage = XYZToJCH(XYZ_testImage,XYZ_white,LA);
% JCH_testImage_corrected = JCH_testImage;
% JCH_testImage_corrected(3,:) = JCH_testImage(3,:)-50;
% XYZ_testImage_correct = JCHToXYZ(JCH_testImage_corrected,XYZ_white,LA);
% RGB_testImage_correct = XYZToRGB(XYZ_testImage_correct,M_RGB2XYZ_sRGB,gamma_RGB);

% Calculate the CIELAB stats.
% lab_testImage = xyz2lab(XYZ_testImage','WhitePoint',XYZ_white');
% dRGB_steps = [1:1:255];
% dRGB_steps_zero = zeros(size(dRGB_steps));
% RGB_red = [dRGB_steps; dRGB_steps_zero; dRGB_steps_zero];
% RGB_green = [dRGB_steps_zero; dRGB_steps; dRGB_steps_zero];
% RGB_blue = [dRGB_steps_zero; dRGB_steps_zero; dRGB_steps];
% lab_red = xyz2lab(RGBToXYZ(RGB_red,M_RGB2XYZ_sRGB,gamma_RGB)','WhitePoint',XYZ_white');
% lab_green = xyz2lab(RGBToXYZ(RGB_green,M_RGB2XYZ_sRGB,gamma_RGB)','WhitePoint',XYZ_white');
% lab_blue = xyz2lab(RGBToXYZ(RGB_blue,M_RGB2XYZ_sRGB,gamma_RGB)','WhitePoint',XYZ_white');
% lab_testImage = lab_testImage';
% lab_testImage_corrected = lab_testImage;
% lab_testImage_corrected(2,:) = lab_testImage(2,:)+20;
% XYZ_testImage_correct = lab2xyz(lab_testImage_corrected','WhitePoint',XYZ_white');
% XYZ_testImage_correct = XYZ_testImage_correct';
% RGB_testImage_correct = XYZToRGB(XYZ_testImage_correct,M_RGB2XYZ_sRGB,gamma_RGB);

% Calculate the cone responses.
% M_XYZtoCones = [0.4002 0.7075 -0.0808; -0.2263 1.1653 0.0457; 0.0000 0.0000 0.9182];
% lms_testImage = M_XYZtoCones * XYZ_testImage;
