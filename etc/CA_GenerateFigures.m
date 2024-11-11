% CA_GenerateFigures.
%
% This is for making some images that help to visualize the test images
% that we used for the project.

% History:
%    11/08/24    smo    - Wrote it.

%% Initiate.
clear all; close all;

%% Set variables.
verbose = true;

%% Load images.
testFiledir = '/Users/semin/Dropbox (Personal)/Giessen/projects/ColorAssimilation/image/RawImages';
testImagename = 'rudolf.png';
image = imread(fullfile(testFiledir,testImagename));

%% Make image canvas.
%
% Generate the test images with different levels of color corrections to
% see how the color coordinates change over the power of color correction.
targetIntensityColorCorrect = [0:0.1:1];
nTargets = length(targetIntensityColorCorrect);

for ii = 1:nTargets
    canvas = MakeImageCanvas(image,'verbose',verbose,'intensityColorCorrect',targetIntensityColorCorrect(ii));

    % Save it.
    saveFiledir = '~/Desktop/';
    saveFilename = sprintf('temp_%d.png',ii);
    saveas(gcf,fullfile(saveFiledir,saveFilename));
end
