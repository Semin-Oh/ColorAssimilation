% MakeTestImages.
%
% This routine makes test images prior to running the experiment.
%
% See also:
%    RunExperiment.

% History:
%    08/28/24  smo    - Started on it.

%% Initialize.
close all; clear;

%% Set variables.
%
% Screen variables. This part shouldn't be changed.
screenParams.screen_x_pixel = 5120;
screenParams.screen_y_pixel = 1440;
screenParams.screen_x_cm  = 119.2;
screenParams.screen_y_cm  = 33.5;
screenParams.screenDistance_cm = 100;
screenParams.screenGap_cm = 2.5;

% Image variables.
imageParams.displayType = 'curvedisplay';
switch imageParams.displayType
    case 'curvedisplay'
        imageParams.sizeCanvans = [5120 1440];
    case 'laptop'
        imageParams.sizeCanvans = [1920 1080];
end
imageParams.testImageSize = 0.5;
imageParams.position_leftImage_x = 0.35;
imageParams.stripeHeightPixel = 5;
imageParams.nChannelsColorCorrect = 1;
imageParams.whichCenterImage = 'none';

% Set the range of different intensity to correct the test image. Default
% to ~0.33 when it's set to empty.
imageParams.nTestPoints = 10;
imageParams.intensityColorCorrect = linspace(0,1,imageParams.nTestPoints);

% etc.
verbose = false;
SAVETHEIMAGES = true;

%% Add the directory to the path.
sysInfo = GetComputerInfo();

% Set the file dir differently depending on the computer.
switch sysInfo.userShortName
    case 'semin'
        % Office computer.
        baseFiledir = '~/Documents/MATLAB';
    case 'gegenfurtner'
        % Linux at the lab.
        baseFiledir = '/home/gegenfurtner/Desktop/semin';
    otherwise
        % This is for Semin's laptop.
        baseFiledir = 'C:\Users\ohsem\Documents\MATLAB';
end

% Set repository name including the above path.
projectName = 'ColorAssimilation';
testFiledir = fullfile(baseFiledir,projectName);

% Add repository to the path.
if isfolder(testFiledir)
    addpath(testFiledir);
    fprintf('Following directory has been added to the path: %s \n',testFiledir);
else
    error('No such directory exist: %s \n',testFiledir);
end

%% Load raw test images.
%
% Set the directory where the images are saved. We will read out all raw
% images stored in the directory, so we have to make sure all the images
% are used in the experiment when we run it.
imageFormat = '.png';
imageFiledir = fullfile(testFiledir,'image','RawImages');
testImageFileList = dir(fullfile(imageFiledir,append('*',imageFormat)));
testImageFilenames = {testImageFileList.name};

% Load images here.
nTestImages = length(testImageFilenames);
for ii = 1:nTestImages
    images{ii} = imread(fullfile(imageFiledir,testImageFilenames{ii}));
end

% Show the raw images if you want.
if (verbose)
    figure;
    sgtitle('Raw test images');
    for ii = 1:nTestImages
        subplot(2,ceil(nTestImages/2),ii);
        imshow(images{ii});
    end
end

%% Make the test images.
%
% We will make a loop for each stripe color. The test images will saved as
% separate files over different color of the stripes.
colorStripeOptions = {'red','green','blue'};
nColorStripeOptions = length(colorStripeOptions);

for cc = 1:nColorStripeOptions
    % Set the stripe color here.
    imageParams.whichColorStripes = colorStripeOptions{cc};

    % Make a null stimulus. This is basically only background image without
    % test images on it.
    nullImage = MakeImageCanvas([],'sizeCanvas',imageParams.sizeCanvans,'testImageSize',imageParams.testImageSize,...
        'position_leftImage_x',imageParams.position_leftImage_x,'whichColorStripes',imageParams.whichColorStripes,'whichCenterImage',imageParams.whichCenterImage,...
        'stripeHeightPixel',imageParams.stripeHeightPixel,'nChannelsColorCorrect',imageParams.nChannelsColorCorrect,'verbose',false);

    % Make test stimulus.
    %
    % Loop for different images.
    for ii = 1:nTestImages
        imageTemp = images{ii};

        % Loop for different level of color corrections.
        for tt = 1:imageParams.nTestPoints
            intensityColorCorrectTemp = imageParams.intensityColorCorrect(tt);
            testImage{ii,tt} = MakeImageCanvas(imageTemp,'sizeCanvas',imageParams.sizeCanvans,'testImageSize',imageParams.testImageSize,...
                'position_leftImage_x',imageParams.position_leftImage_x,'whichColorStripes',imageParams.whichColorStripes,'whichCenterImage',imageParams.whichCenterImage,...
                'stripeHeightPixel',imageParams.stripeHeightPixel,'nChannelsColorCorrect',imageParams.nChannelsColorCorrect,'intensityColorCorrect',intensityColorCorrectTemp,'verbose',false);
        end

        % Show progress.
        fprintf('Test image (%s) has been made - (%d/%d) \n',imageParams.whichColorStripes,ii,nTestImages);
    end

    % Save the images.
    if (SAVETHEIMAGES)
        % Set the directory to save the images.
        testImageFiledir = fullfile(testFiledir,'image','TestImages');

        % Save the images here.
        dayTimestr = datestr(now,'yyyy-mm-dd_HH-MM-SS');
        saveFilename = fullfile(testImageFiledir,...
            sprintf('TestImages_%s_%s',imageParams.whichColorStripes,dayTimestr));
        save(saveFilename,'nullImage','testImage','imageParams');
        fprintf('Test images have been saved successfully! - (%s) \n',imageParams.whichColorStripes);
    end
end