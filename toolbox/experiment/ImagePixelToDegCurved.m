function [hAngle, vAngle] = ImagePixelToDegCurved(xStart, yStart, widthPixels, heightPixels)
% imageToVisualAngleCurved converts the pixel coordinates of an image
% on a cylindrical curved display to visual angles for the entire image.
%
% Inputs:
%   xStart - starting horizontal pixel position of the image
%   yStart - starting vertical pixel position of the image
%   widthPixels  - width of the image in pixels
%   heightPixels - height of the image in pixels
%
% Outputs:
%   hAngle - horizontal visual angle range (degrees)
%   vAngle - vertical visual angle range (degrees)

% History:
%    11/11/24    smo    - Wrote it.

%% Display specifications
totalWidthPixels = 15360;    % Total horizontal resolution
totalHeightPixels = 1457;    % Total vertical resolution
horizontalFOV = 180;         % Total horizontal FOV in degrees
screenHeightMeters = 0.335;  % Physical height of the screen in meters
observerDistance = 1;        % Distance from the screen to the observer in meters

%% Calculate the horizontal visual angle per pixel
hAnglePerPixel = horizontalFOV / totalWidthPixels; % degrees per pixel

% Calculate the total vertical field of view (flat-plane approximation)
totalVerticalFOV = 2 * atand((screenHeightMeters / 2) / observerDistance); % degrees
vAnglePerPixel = totalVerticalFOV / totalHeightPixels; % degrees per vertical pixel

% Calculate the horizontal visual angle range for the image
relativeStartX = xStart - (totalWidthPixels / 2);
relativeEndX = (xStart + widthPixels) - (totalWidthPixels / 2);

hAngle = (relativeEndX - relativeStartX) * hAnglePerPixel;

% Calculate the vertical visual angle range for the image
relativeStartY = yStart - (totalHeightPixels / 2);
relativeEndY = (yStart + heightPixels) - (totalHeightPixels / 2);

vAngle = (relativeEndY - relativeStartY) * vAnglePerPixel;

% Display the results.
fprintf('Image center FOV (Horizontal, Vertical): (%.2f, %.2f) degrees\n', hAngle, vAngle);
end
