%% CAM16_TestingTool.
%
% This routine checks the CAM16 calculation routines.

% History:
%    06/17/25    smo      - Wrote it.

%% Initialize.
clear; close all;

%% Set display setting.
%
% 3x3 matrix.
M_RGBToXYZ =  [62.1997 22.8684 19.2310;...
    28.5133 78.5446 6.9256;...
    0.0739 6.3714 99.5962];

% White point.
XYZw = sum(M_RGBToXYZ,2);

% Monitor gamma.
gamma = 2.1904;

%% Load the image.
image = imread("confetti.ppm");
imageSize = size(image);

% Resize it and then back to the image format without any treatment. Just
% check if that affects the image itself.
image_cal = reshape(image,[3 imageSize(1)*imageSize(2)]);
imageSize_cal = length(image_cal);

image_return = reshape(image_cal,imageSize);

%% CAM16 Forward model.
%
% Set adapting luminance.
LA = 0.2 * XYZw(2);

XYZ = RGBToXYZ(image,M_RGBToXYZ,gamma);
JCH = XYZToJCH(XYZ,XYZw,LA);

%% CAM16 Inverse model.
XYZ_back = JCHToXYZ(JCH(1:3,:),XYZw,LA);
RGB_back = XYZToRGB(XYZ,M_RGBToXYZ,gamma);

% Get image back. Important thing is that the RGB matrix should look like
% N x 3 to retreat the image info by reshaping it. Thus, here we transpose
% it for this step.
image_return2 = reshape(RGB_back',imageSize);

%% Plot it.
figure;
subplot(1,3,1);
imshow(image);
title('Original');

subplot(1,3,2);
imshow(image_return);
title('Retreated after just resizing');

subplot(1,3,3);
imshow(image_return2);
title('Retreated after CAM16 calculation')
