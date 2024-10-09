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

%% Load the data to analyze.
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
whichPrimary = whichPrimaryOptions{3};

% Read out all avaialble data over different primary color.
dataFilename = GetMostRecentFileName(dataFiledir,sprintf('%s_%s_%s',subjectName,expMode,whichPrimary));
rawData = load(dataFilename);

%% Read out some variables.
nRepeat = rawData.data.expParams.nRepeat;
nTestImages = rawData.data.expParams.nTestImages;

%% Rearrange the experiment results.
%
% Test images were displayed in a random order, so the raw data is
% sorted in the same random order. Here, we sort out the results.

% Get the index to sort out the results.
for rr = 1:nRepeat
    for ii = 1:nTestImages
        idxOrder(ii,rr) = find(rawData.data.expParams.randOrder(:,rr) == ii);
    end
end

% Sort out the results.
matchingIntensityColorCorrect_sorted = rawData.data.matchingIntensityColorCorrect(idxOrder);

% Mean results.
meanMatchingIntensityColorCorrect = mean(matchingIntensityColorCorrect_sorted,2);

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

% Plot happens here.
figure; hold on;
plot(xaxisTestImages,matchingIntensityColorCorrect_sorted,'k.');
plot(xaxisTestImages,meanMatchingIntensityColorCorrect,'o','MarkerFaceColor',markerFaceColor,'MarkerEdgeColor','k');
xlabel('Test Image');
ylabel('Matching intensity');
xlim([1 nTestImages]);
xticks(xaxisTestImages);
ylim([0 0.5]);
title(sprintf('Primary = (%s) / Experiment mode = (%s) / Subject = (%s)',whichPrimary,expMode,subjectName));

%% Save out something if you want.
