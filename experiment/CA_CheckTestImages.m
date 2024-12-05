% CA_CheckTestImages.
%
% This is to check the test images generated fine.

% History.
%    12/02/24   smo    - Wrote it.

%% Initiate.
clear; close all;

%% Set repository to load test images.
sysInfo = GetComputerInfo();

% Set the file dir differently depending on the computer.
switch sysInfo.userShortName
    case 'semin'
        % Office computer.
        baseFiledir = '~/Dropbox (Personal)/JLU/2) Projects';
    otherwise
        % This is for Semin's laptop.
        baseFiledir = 'C:\Users\ohsem\Dropbox (Personal)\JLU\2) Projects';
end

% Set repository name including the above path.
projectName = 'ColorAssimilation';
testFiledir = fullfile(baseFiledir,projectName);
testImageFiledir = fullfile(testFiledir,'image','TestImages');
testImageProfileDir = fullfile(testFiledir,'image','TestImageProfiles');

%% Set variables.
expModeOptions = {'periphery','fovea'};
stripeColorOptions = {'red','green','blue'};
expMode = 'periphery';
stripeColor = 'red';

%% Load test images
testImageFilename = GetMostRecentFileName(testImageFiledir,sprintf('TestImages_%s_%s',expMode,stripeColor));
images = load(testImageFilename);

% Find the date part in the filename.
pattern = '\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}';
str_dateTestImages = regexp(testImageFilename , pattern, 'match');

%% Load test image profiles.
testImageProfilename = GetMostRecentFileName(testImageProfileDir,sprintf('TestImageProfiles_%s_%s',expMode,stripeColor));

% Check if the date matches as the test image file.
str_dateTestImageProfiles = regexp(testImageProfilename , pattern, 'match');

if ~strcmp(str_dateTestImages,str_dateTestImageProfiles)
    error('Date mismatch between the test image and image profiles!');
end

% Load the image profile here.
imageProfiles = load(testImageProfilename);
imageProfiles = imageProfiles.testImageProfile;

%% 

