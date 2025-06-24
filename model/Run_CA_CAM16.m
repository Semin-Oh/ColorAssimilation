% Run_CA_CAM16.
%
% Context-Aware CAM16-UCS model to simulate color assimilation
%
% This adapted model Context Awared (CA) CAM16 model is to explain the
% effect of color assimilation. The idea behind it is to use a wrapper
% function to consider the local context on the perception of the target.

% History:
%    06/17/25    smo    - Started on it.

%% Initialize.
clear; close all;

%% Set variables.
%
% Choose which image to play with.
idxImage = 5;

% Set CA-CAM16 parameters here.
sigma = 12;
e = 0.7;

% Plotting options.
heatmap = true;
colorcoords = false;

%% Set display type.
displayType = 'sRGB';
switch displayType
    case 'EIZO'
        M_RGBToXYZ =  [62.1997 22.8684 19.2310;
            28.5133 78.5446 6.9256;
            0.0739 6.3714 99.5962];
        gamma = 2.1904;
    case 'sRGB'
        M_RGBToXYZ = [0.4124564, 0.3575761, 0.1804375;
            0.2126729, 0.7151522, 0.0721750;
            0.0193339, 0.1191920, 0.9503041]*100;
        gamma = 2.2;
end
XYZw = sum(M_RGBToXYZ,2);

%% Load and preprocess image.
testImagedir = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/ColorAssimilation/images_illusion';
imageFileList = dir(testImagedir);
imageFilenameList = {imageFileList.name};
imageFilenameList = imageFilenameList(~startsWith(imageFilenameList,'.'));
nImages = length(imageFilenameList);

% Load the image.
testImagefilename = fullfile(testImagedir,imageFilenameList{idxImage});
image = im2double(imread(testImagefilename));
image = uint8(image .* 255);

% Get image size.
imageSize = size(image);
H = imageSize(1);
W = imageSize(2);

% Calculate XYZ from RGB.
XYZ = RGBToXYZ(image, M_RGBToXYZ, gamma);

%% CAM16 forward calculations.
LA = 0.2 * XYZw(2);
JCH = XYZToJCH(XYZ, XYZw, LA);

%% Convert CAM16 to CAM16-UCS.
J = JCH(1,:);
C = JCH(2,:);
h = deg2rad(JCH(3,:));

% Coefficient from Luo et al.
c1 = 0.007;
c2 = 0.0228;

Jp = (1 + 100 * c1) .* J ./ (1 + c1 * J);
ap = c2 * C .* cos(h);
bp = c2 * C .* sin(h);

% Save out the original coordiates here to plot.
ap_raw = ap;
bp_raw = bp;

% Reshape to image format.
Jp_img = reshape(Jp, H, W);
ap_img = reshape(ap, H, W);
bp_img = reshape(bp, H, W);

%% Apply color assimilation on a'b' in CAM16-UCS.
%
% Add Gaussian filter to each a and b axis on CAM16 UCS. The sigma value
% defines how much pooling happens from the adjacent area.
ap_blur = imgaussfilt(ap_img, sigma);
bp_blur = imgaussfilt(bp_img, sigma);

% Add an amplifying layer. Effect is equal across the pixels (1) if e is
% set to 0.
W_map = sqrt((ap_img - ap_blur).^2 + (bp_img - bp_blur).^2);
W_map = W_map ./ max(W_map(:));
W_map = W_map .^ e;

% Get the new axes after applying the effect of assimilation.
ap_assim = ap_img + W_map .* (ap_blur - ap_img);
bp_assim = bp_img + W_map .* (bp_blur - bp_img);

% Reshape back to vector.
Jp = Jp_img(:)';
ap = ap_assim(:)';
bp = bp_assim(:)';

%% Convert CAM16-UCS back to CAM16.
J = (Jp .* (1 + 100 * c1)) ./ (1 + c1 * Jp);
C = sqrt(ap.^2 + bp.^2) / c2;
h = atan2d(bp, ap);
h(h < 0) = h(h < 0) + 360;
JCH_assim = [J; C; h];

%% This is temp processing to match the brightness level before and after applying the model.
JCH_assim(1,:) = JCH(1,:);

%% CAM16 inverse calculations.
XYZ_assim = JCHToXYZ(JCH_assim, XYZw, LA);
RGB_assim = XYZToRGB(XYZ_assim, M_RGBToXYZ, gamma);

% Reshape back to image.
image_assim = reshape(RGB_assim', imageSize);

%% Crop the target image part only.
%
% Here we will find the pixel locations where the target images are placed.
% We take the pixel location using the original image.
switch idxImage
    case 1
        targetRGB = [255 182 129];
    case 2
        targetRGB = [255 0 0];
    case 3
        targetRGB = [202 7 86];
    case 4
        targetRGB = [241 241 241];
    case 5
        targetRGB = [0 255 0];
        targetRGB = [255 0 0];
    otherwise
        targetRGB = [255 255 255];
end

% Cropping happens here. We fill find the pixels that matches the target
% RGB values.
idxImageHeight = [];
idxImageWidth = [];
for hh = 1:H
    for ww = 1:W
        areAllEqual = (image(hh,ww,1)==targetRGB(1)) & (image(hh,ww,2)==targetRGB(2)) & (image(hh,ww,3)==targetRGB(3));
        if areAllEqual
            idxImageHeight(end+1) = hh;
            idxImageWidth(end+1) = ww;
        end
    end
end

% Get the cropped target image.
croppedImage = uint8(zeros(imageSize));
for ii = 1:length(idxImageHeight)
    croppedImage(idxImageHeight(ii),idxImageWidth(ii),1) = targetRGB(1);
    croppedImage(idxImageHeight(ii),idxImageWidth(ii),2) = targetRGB(2);
    croppedImage(idxImageHeight(ii),idxImageWidth(ii),3) = targetRGB(3);
end

% Get the cropped target image after assimilation.
croppedImage_assim = uint8(zeros(imageSize));
for ii = 1:length(idxImageHeight)
    croppedImage_assim(idxImageHeight(ii),idxImageWidth(ii),1) = image_assim(idxImageHeight(ii),idxImageWidth(ii),1);
    croppedImage_assim(idxImageHeight(ii),idxImageWidth(ii),2) = image_assim(idxImageHeight(ii),idxImageWidth(ii),2);
    croppedImage_assim(idxImageHeight(ii),idxImageWidth(ii),3) = image_assim(idxImageHeight(ii),idxImageWidth(ii),3);

    foo(1,ii) = image_assim(idxImageHeight(ii),idxImageWidth(ii),1);
    foo(2,ii) = image_assim(idxImageHeight(ii),idxImageWidth(ii),2);
    foo(3,ii) = image_assim(idxImageHeight(ii),idxImageWidth(ii),3);
end

%% Plot it.
%
% Set the number of subplots.
if ~heatmap
    nSubplots = 4;
else
    nSubplots = 6;
end

% Original image and model edited image.
figure;
subplot(nSubplots/2,2,1);
imshow(image);
title('Original Illusion');

subplot(nSubplots/2,2,2);
imshow(image_assim);
title('CA-CAM16 Output');

subplot(nSubplots/2,2,3);
imshow(croppedImage);
title('Original Target');

subplot(nSubplots/2,2,4);
imshow(croppedImage_assim);
title('CA-CAM16 Output (Target)');

sgtitle(sprintf('CA-CAM16: \\sigma = (%.2f) / e = (%.2f)',sigma,e));

% Heat map of amplifying layer.
if heatmap
    subplot(nSubplots/2,2,5:6);
    imagesc(W_map);
    axis image off;
    colormap('hot');  % or try 'parula', 'jet', etc.
    colorbar;
    title(sprintf('Assimilation Weight Map (\\sigma = %.2f, e = %.2f)', sigma, e));
end

% Plot it on CAM16-UCS a'b' plane.
if (colorcoords)
    figure;
    subplot(1,2,1);
    plot(ap_raw,bp_raw,'k.');
    xlabel('CAM16-UCS a');
    ylabel('CAM16-UCS b');
    xRange = [-3 3];
    yRange = [-3 3];
    xlim(xRange);
    ylim(yRange);
    axis square;
    grid on;
    title('Original image');

    subplot(1,2,2);
    plot(ap_assim,bp_assim,'g.');
    xlabel('CAM16-UCS a');
    ylabel('CAM16-UCS b');
    xlim(xRange);
    ylim(yRange);
    axis square;
    grid on;
    title('Processed image');
end
