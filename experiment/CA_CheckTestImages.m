% CA_CheckTestImages.
%
% This is to check the test images generated fine.
%
% See also:
%    CA_MakeTestImages.

% History.
%    12/02/24    smo    - Wrote it.

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
stripeColor = 'blue';

%% Load test images
testImageFilename = GetMostRecentFileName(testImageFiledir,sprintf('TestImages_%s_%s',expMode,stripeColor));
images = load(testImageFilename);

% Find the date part in the filename.
pattern = '\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}';
str_dateTestImages = regexp(testImageFilename , pattern, 'match');

%% Load test image profiles.
testImageProfilename = GetMostRecentFileName(testImageProfileDir,sprintf('TestImageProfiles_%s_%s',expMode,stripeColor));

% Check if the date matches as the test image file.
dateStr_TestImageProfiles = regexp(testImageProfilename , pattern, 'match');

if ~strcmp(str_dateTestImages,dateStr_TestImageProfiles)
    error('Date mismatch between the test image and image profiles!');
end

% Load the image profile here.
imageProfiles = load(testImageProfilename);
imageProfiles = imageProfiles.testImageProfile;

%% Read out some values.
nTestImages = length(images.imageParams.testImageFilenames);
nTestPoints = images.imageParams.nTestPoints;

%% Check chromaticity and mean luminance over color corrections.
%
% Planckian locus.
load T_xyzJuddVos
T_XYZ = T_xyzJuddVos;
T_xy = [T_XYZ(1,:)./sum(T_XYZ); T_XYZ(2,:)./sum(T_XYZ)];
T_uv = xyTouv(T_xy);

for ii = 1:nTestImages
    % Get chromaticity of a striped image.
    uvY_testImageStripe_temp = imageProfiles{ii,1}.uvY_testImageStripe;
    mean_uvY_testImageStripe_temp = mean(uvY_testImageStripe_temp,2);
    
    % Collect the luminanc
    luminance(ii) = mean_uvY_testImageStripe_temp(3);

    % Make a new figure per test image.
    figure; hold on;
    sgtitle(sprintf('Test image = (%s) / lum = %.2f cd/m2',...
        images.imageParams.testImageFilenames{ii},mean_uvY_testImageStripe_temp(3)));
    
    for tt = 1:nTestPoints
        uvY_colorCorrectedImage_temp = imageProfiles{ii,tt}.uvY_colorCorrectedImage;
        mean_uvY_colorCorrectedImage_temp = mean(uvY_colorCorrectedImage_temp,2);

        % Plot the chromaticity of color corrected image.
        subplot(4,ceil(nTestPoints/4),tt); hold on;
        plot(uvY_colorCorrectedImage_temp(1,:),uvY_colorCorrectedImage_temp(2,:),'.');

        % Plot Planckian locus.
        plot([T_uv(1,1:65) T_uv(1,1)], [T_uv(2,1:65) T_uv(2,1)], 'k-');

        % Figure stuff.
        xlim([0 0.7]);
        ylim([0 0.7]);
        xlabel('CIE u-prime','fontsize',13);
        ylabel('CIE v-prime','fontsize',13);
        title(sprintf('c = %.4f',images.imageParams.intensityColorCorrect(tt)));
        subtitle(sprintf('Lum = %.2f cd/m2',mean_uvY_colorCorrectedImage_temp(3)));
    end
end

mean(luminance)
std(luminance)