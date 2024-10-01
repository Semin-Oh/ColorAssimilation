% CA_MakeTestImages.
%
% This routine makes test images prior to running the experiment. The image
% will be saved in the Dropbox, so it is recommended to use the computer
% that has the access to the Dropbox. That means, for this project, use
% either office laptop or personal laptop to run this code, not with the
% Linux at the curved display room.
%
% See also:
%    RunExperiment.

% History:
%    08/28/24  smo    - Started on it.
%    09/03/24  smo    - When loading the raw test images, it only reads out
%                       files that are not hidden. This prevents the break
%                       when running on Linux.
%    09/05/24  smo    - Now save the images on the Dropbox.
%    10/01/24  smo    - Added an option to make test images having either
%                       two or three images on the canvas.

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
imageParams.whichDisplay = 'curvedDisplay';
switch imageParams.whichDisplay
    case 'curvedDisplay'
        % For the curved display, we treat the three displays as one, so we
        % set the resoultion as 15360 (5120*3) in horizontal and 1457 in
        % vertical.
        imageParams.sizeCanvans = [15360 1457];
    case 'laptop'
        imageParams.sizeCanvans = [1920 1080];
end
imageParams.testImageSize = 0.8;
imageParams.position_leftImage_x = 0.36;
imageParams.stripeHeightPixel = 5;
imageParams.colorCorrectMethod = 'uv';
imageParams.nChannelsColorCorrect = 1;

% Set this 'true' to put three images on the canvas.
imageParams.addImageRight = false;

% Set the range of different intensity to correct the test image. Default
% to ~0.33 when it's set to empty.
maxIntensityColorCorrect = 0.6;
imageParams.nTestPoints = 20;
imageParams.intensityColorCorrect = linspace(0,maxIntensityColorCorrect,imageParams.nTestPoints);

% etc.
PLOTRAWIMAGES = false;
SAVETHEIMAGES = true;

%% Add the directory to the path.
sysInfo = GetComputerInfo();

% Set the file dir differently depending on the computer.
switch sysInfo.userShortName
    case 'semin'
        % Office computer.
        baseFiledir = '~/Dropbox (Personal)/Giessen/projects';
    otherwise
        % This is for Semin's laptop.
        baseFiledir = 'C:\Users\ohsem\Dropbox (Personal)\Giessen\projects';
end

% Set repository name including the above path.
projectName = 'ColorAssimilation';
testFiledir = fullfile(baseFiledir,projectName);

%% Load raw test images.
%
% Set the directory where the images are saved. We will read out all raw
% images stored in the directory, so we have to make sure all the images
% are used in the experiment when we run it.
imageFormat = '.png';
imageFiledir = fullfile(testFiledir,'image','RawImages');
testImageFileList = dir(fullfile(imageFiledir,append('*',imageFormat)));
testImageFilenames = {testImageFileList(~startsWith({testImageFileList.name},'.')).name};

% Load images here.
nTestImages = length(testImageFilenames);
for ii = 1:nTestImages
    images{ii} = imread(fullfile(imageFiledir,testImageFilenames{ii}));
end

% Show the raw images if you want.
if (PLOTRAWIMAGES)
    figure;
    sgtitle('Raw test images');
    for ii = 1:nTestImages
        subplot(2,ceil(nTestImages/2),ii);
        imshow(images{ii});
        fprintf('Raw test images have been loaded - (n = %d) \n',nTestImages);
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
    nullImage = MakeImageCanvas([],'whichDisplay',imageParams.whichDisplay,'sizeCanvas',imageParams.sizeCanvans,'testImageSize',imageParams.testImageSize,...
        'position_leftImage_x',imageParams.position_leftImage_x,'whichColorStripes',imageParams.whichColorStripes,'colorCorrectMethod',imageParams.colorCorrectMethod,....
        'stripeHeightPixel',imageParams.stripeHeightPixel,'nChannelsColorCorrect',imageParams.nChannelsColorCorrect,'verbose',false);
    disp('Null image has been successfully generated!');

    % Make test stimulus.
    %
    % Loop for different images.
    disp('Now we will start making test images...');
    for ii = 1:nTestImages
        imageTemp = images{ii};

        % Loop for different level of color corrections.
        for tt = 1:imageParams.nTestPoints
            intensityColorCorrectTemp = imageParams.intensityColorCorrect(tt);
            testImage{ii,tt} = MakeImageCanvas(imageTemp,'whichDisplay',imageParams.whichDisplay,'sizeCanvas',imageParams.sizeCanvans,'testImageSize',imageParams.testImageSize,...
                'position_leftImage_x',imageParams.position_leftImage_x,'whichColorStripes',imageParams.whichColorStripes,'colorCorrectMethod',imageParams.colorCorrectMethod,...
                'stripeHeightPixel',imageParams.stripeHeightPixel,'nChannelsColorCorrect',imageParams.nChannelsColorCorrect,'intensityColorCorrect',intensityColorCorrectTemp,'verbose',false);

            % Show progress every 5 images.
            if mod(tt,5) == 0
                fprintf('Test image (%s) making progress - Test points (%d/%d) \n',...
                    imageParams.whichColorStripes,tt,imageParams.nTestPoints);
            end
        end

        % Show progress.
        fprintf('Test image (%s) making progress - Different test images (%d/%d) \n',...
            imageParams.whichColorStripes,ii,nTestImages);
    end

    % Save the images.
    if (SAVETHEIMAGES)
        % Set the directory to save the images.
        testImageFiledir = fullfile(testFiledir,'image','TestImages');

        % Save the images here. The image file would be greater than 2GB,
        % so make it sure it saves in the m-file in its version 7.3 or
        % later. Here, we set it as version 7.3 and it should save it fine.
        dayTimestr = datestr(now,'yyyy-mm-dd_HH-MM-SS');
        saveFilename = fullfile(testImageFiledir,...
            sprintf('TestImages_%s_%s',imageParams.whichColorStripes,dayTimestr));
        mFileVer = '-v7.3';
        save(saveFilename,'nullImage','testImage','imageParams',mFileVer);
        fprintf('Test images have been saved successfully! - (%s) \n',imageParams.whichColorStripes);
    end
end
