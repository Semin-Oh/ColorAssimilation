% CA_DataAnalysis.
%
% This routine is for analyzing the data.
%
% See also:
%    CA_RunExperiment.

% History:
%    09/09/24    smo    - Started on it.
%    10/09/24    smo    - Now load the experiment data from the Dropbox.

%% Initialize.
close all; clear;

%% Choose how we analyze the data.

%% Get subject names with the data.
sysInfo = GetComputerInfo();

% Set the file dir differently depending on the computer.
switch sysInfo.userShortName
    case 'semin'
        % Semin office computer.
        baseFiledir = '/Users/semin/Dropbox (Personal)/Giessen/projects';
    otherwise
        % Semin's laptop.
        baseFiledir = 'C:\Users\ohsem\Dropbox (Personal)\Giessen\projects';
end

% Set repository name.
projectName = 'ColorAssimilation';
testFiledir = fullfile(baseFiledir,projectName,'data');

% Get available data. We will read out only non-hidden files.
subjectNameContent = dir(testFiledir);
subjectNameList = {subjectNameContent.name};
subjectNames = subjectNameList(~startsWith(subjectNameList,'.'));

%% Load the exp data to analyze.
%
% Define which subject data to analyze.
idxSubject = 1;
subjectName = subjectNames{idxSubject};

% Set the directory.
dataFiledir = fullfile(testFiledir,subjectName);

% Set experimental mode either 'periphery' or 'fovea'.
expModeOptions = {'periphery','fovea'};
expMode = expModeOptions{1};

% Choose which primary session.
whichPrimaryOptions = {'red','green','blue'};
whichPrimary = whichPrimaryOptions{1};

% Read out all avaialble data over different primary color.
olderDate = 0;
dataFilename = GetMostRecentFileName(dataFiledir,sprintf('%s_%s_%s',subjectName,expMode,whichPrimary),'olderDate',olderDate);
rawData = load(dataFilename);

%% Rearrange the experiment results.
%
% Test images were displayed in a random order, so the raw data is
% sorted in the same random order. Here, we sort out the results.

% Read out some variables.
nRepeat = rawData.data.expParams.nRepeat;
nTestImages = rawData.data.expParams.nTestImages;

% Get the index to sort out the results.
[randOrderSorted idxOrder_sorted] = sort(rawData.data.expParams.randOrder);

% Sort out the results.
matchingIntensityColorCorrect_sorted = rawData.data.matchingIntensityColorCorrect(idxOrder_sorted);

% Mean results.
meanMatchingIntensityColorCorrect = mean(matchingIntensityColorCorrect_sorted,2);

%% Load the corresponding image profile.
%
% We will analyze the date based on the color profile on the u'v'
% coordinates. Corresponding image profile should have the same date on its
% file name.
imageProfileDir = fullfile(baseFiledir,projectName,'image','TestImageProfiles');
filename = rawData.data.imageParams.testImageFilename;

% Extract date of the experiment.
date_pattern = '\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}';
date = regexp(filename, date_pattern, 'match');

% Load the image profile here. The array should be the number of test
% images x the number of test points (color correction). For example, if we
% used 5 test images and 20 color correction points per image, the cell
% array shold look like 5x20. In each cell array, there are two image
% profiles, one being the test image with stripes and the other being the
% color corrected image.
imageProfilename = fullfile(imageProfileDir,sprintf('TestImageProfiles_%s_%s_%s',...
    rawData.data.imageParams.testImageType, rawData.data.imageParams.whichColorStripes, date{:}));
imageProfile = load(imageProfilename);
imageProfile = imageProfile.testImageProfile;

%% Plot the results.
%
% X-axis as test images.
xaxisTestImages = linspace(1,nTestImages,nTestImages);

% Set marker color over different primaries.
switch whichPrimary
    case 'red'
        markerFaceColor = 'r';
    case 'green'
        markerFaceColor = 'g';
    case 'blue'
        markerFaceColor = 'b';
end

% Comparison of the mean chosen color correction over different test
% images.
figure; hold on;
plot(xaxisTestImages,meanMatchingIntensityColorCorrect,'o','MarkerFaceColor',markerFaceColor,'MarkerEdgeColor','k');
plot(xaxisTestImages,matchingIntensityColorCorrect_sorted,'k.');
xlabel('Test Image');
ylabel('Matching intensity');
xlim([1 nTestImages]);
xticks(xaxisTestImages);
xticklabels(rawData.data.imageParams.testImageFilenames);
ylim([0 0.6]);
legend(sprintf('Mean (N=%d)',nRepeat),'Raw Data');
title(sprintf('Primary = (%s) / Experiment mode = (%s) / Subject = (%s)',whichPrimary,expMode,subjectName));

%% The mean results on the u'v' coordinates.
figure; hold on;

% Get image profiles of the stripes and color corrected on the u'v'
% coordinates. This is fixed, not changing within the same test image.
whichTestImage = 2;
whichColorCorrect = 15;
oneImageProfile = imageProfile{whichTestImage,whichColorCorrect};
uvY_colorCorrectImage = oneImageProfile.uvY_colorCorrectedImage;

oneImageProfile_raw = imageProfile{whichTestImage,1};
uvY_testImageRaw = oneImageProfile_raw.uvY_colorCorrectedImage;
uvY_testImageStripe = oneImageProfile_raw.uvY_testImageStripe;

% Mean color coordinates.
mean_uvY_testImageRaw = mean(uvY_testImageRaw,2);
mean_uvY_testImageStripe = mean(uvY_testImageStripe,2);
mean_uvY_colorCorrectImage = mean(uvY_colorCorrectImage,2);

% Calculate the Color Assimiliation index (AI). Reference: Shinoda, H., &
% Ikeda, M. (2004). Color assimilation on grating affected by its apparent
% stripe width. Color Research & Application, 29(3), 187-195.
%
% 'a' is the distance from the original to the image with the stripes and
% 'm' is the distance from the original to the matched color.
%
% The 'AI' value should be zero if there is no color assimiliation effect.
%
% IMPORTANT: We collected 'matchingIntensityColorCorrect' as a raw data.
% Itself does not represent how much color assmiliation happened per each
% test image. The results should be compared in AI index, which is relative
% mean chromaticity shift, which reflects the situation better.
m = norm(mean_uvY_colorCorrectImage(1:2)-mean_uvY_testImageRaw(1:2));
a = norm(mean_uvY_testImageStripe(1:2)-mean_uvY_testImageRaw(1:2));
AI = m/a;

% Plot the image profiles.
plot(uvY_testImageRaw(1,:),uvY_testImageRaw(2,:),'k.');
plot(uvY_testImageStripe(1,:),uvY_testImageStripe(2,:),'k.','MarkerEdgeColor',[1 1 0]);
plot(uvY_colorCorrectImage(1,:),uvY_colorCorrectImage(2,:),'ro');

% Plot the mean chromaticity.
plot(mean_uvY_testImageRaw(1),mean_uvY_testImageRaw(2),'o','MarkerFaceColor','k','markeredgecolor','k');
plot(mean_uvY_testImageStripe(1),mean_uvY_testImageStripe(2),'o','MarkerFaceColor',[1 1 0],'markeredgecolor','k');
plot(mean_uvY_colorCorrectImage(1),mean_uvY_colorCorrectImage(2),'o','MarkerFaceColor','r','markeredgecolor','k');

% Plot the Plackian locus.
load T_xyzJuddVos
T_XYZ = T_xyzJuddVos;
T_xy = [T_XYZ(1,:)./sum(T_XYZ); T_XYZ(2,:)./sum(T_XYZ)];
T_uv = xyTouv(T_xy);
plot([T_uv(1,:) T_uv(1,1)], [T_uv(2,:) T_uv(2,1)], 'k-');

% Display gamut.


% Figure stuff.
xlim([0 0.7]);
ylim([0 0.7]);
xlabel('CIE u-prime','fontsize',13);
ylabel('CIE v-prime','fontsize',13);
legend('raw','stripes','matched','Mean(raw)','Mean(stripes)','Mean(matched)',...
    'Location','southeast','fontsize',11);
title(sprintf('Mean image profile on the CIE uv-prime (AI = %.2f)',AI));

%% Save out something if you want.
