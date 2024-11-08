% GenerateFigures.
%
% This is for making some images that help to visualize the test images
% that we used for the project.

% History:
%    11/08/24    smo    - Wrote it.

%% Initiate.
clear all; close all;

%% Load images.
image = imread("rudolf.png");

%% Make image canvas.
%
% Generate the test images with different levels of color corrections to
% see how the color coordinates change over the power of color correction.
%
canvas = MakeImageCanvas(image,'verbose',true);

%% Plot it.


%% Save out the figures. 