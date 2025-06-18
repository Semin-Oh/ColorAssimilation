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

%% Set display type.
displayType = 'EIZO';
switch displayType
    case 'EIZO'
        M_RGBToXYZ =  [62.1997 22.8684 19.2310;
            28.5133 78.5446 6.9256;
            0.0739 6.3714 99.5962];
        gamma = 2.1904;
end
XYZw = sum(M_RGBToXYZ,2);

%% Load and preprocess image.
testImagedir = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/ColorAssimilation/images_illusion';
imageFileList = dir(testImagedir);
imageFilenameList = {imageFileList.name};
imageFilenameList = imageFilenameList(~startsWith(imageFilenameList,'.'));
nImages = length(imageFilenameList);

% Choose which image to play with.
idxImage = 1;

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

% Reshape to image format.
Jp_img = reshape(Jp, H, W);
ap_img = reshape(ap, H, W);
bp_img = reshape(bp, H, W);

%% Apply color assimilation on a'b' in CAM16-UCS.
%
% Set parameters.
sigma = 13;
e = 0.2;

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

%% CAM16 inverse calculations.
XYZ_assim = JCHToXYZ(JCH_assim, XYZw, LA);
RGB_assim = XYZToRGB(XYZ_assim, M_RGBToXYZ, gamma);

% Reshape back to image.
image_assim = reshape(RGB_assim', imageSize);

%% Plot it.
%
% Original image and model edited image.
figure;
subplot(2,2,1); imshow(image); title('Original Illusion');
subplot(2,2,2); imshow(image_assim); title('CAM16-UCS Assimilation Output');

% Heat map of amplifying layer.
subplot(2,2,3:4);
imagesc(W_map);
axis image off;
colormap('hot');  % or try 'parula', 'jet', etc.
colorbar;
title(sprintf('Assimilation Weight Map (\\sigma = %.2f, exp = %.2f)', sigma, e));
