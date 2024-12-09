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
addImageRight = false;
saveImages = true;

%% Load images.
testFiledir = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/ColorAssimilation/image/RawImages';
testImagename = 'rudolf.png';
image = imread(fullfile(testFiledir,testImagename));

%% Make image canvas.
%
% Generate the test images with different levels of color corrections to
% see how the color coordinates change over the power of color correction.
targetIntensityColorCorrect = [0:0.1:0.6];
nTargets = length(targetIntensityColorCorrect);

for ii = 1:nTargets
    close all;
    canvas = MakeImageCanvas(image,'verbose',verbose,'intensityColorCorrect',targetIntensityColorCorrect(ii),...
        'addImageRight',addImageRight);

    % Save it if you want.
    if (saveImages)
        saveFiledir = '~/Desktop/';
        saveFilename = sprintf('foveal_%d.png',ii);
        saveas(figure(1),fullfile(saveFiledir,saveFilename));
        saveFilename2 = sprintf('chromaticity_%d.png',ii);
        saveas(figure(4),fullfile(saveFiledir,saveFilename2));
    end
end
