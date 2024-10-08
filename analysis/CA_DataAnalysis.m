% CA_DataAnalysis.
%
% This routine is for analyzing the data.
%
% See also:
%    CA_RunExperiment.

% History:
%    09/09/24    smo    - Started on it.

%% Initialize.
close all; clear;

%% Choose how we analyze the data.

%% Get subject names with the data.
sysInfo = GetComputerInfo();

% Set the file dir differently depending on the computer.
switch sysInfo.userShortName
    case 'semin'
        % Office computer.
        baseFiledir = '~/Documents/MATLAB';

        % SET THE NAME OF THE LINUX COMPUTER HERE.
    case 'gegenfurtner'
        % Lap Linux computer.
        baseFiledir = '/home/gegenfurtner/Desktop/SEMIN';
    otherwise
        % This is for Semin's laptop.
        baseFiledir = 'C:\Users\ohsem\Documents\MATLAB';
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

% Read out all avaialble data over different primary color.
dataFilename_red = GetMostRecentFileName(dataFiledir,sprintf('%s_red',subjectName));
dataFilename_green = GetMostRecentFileName(dataFiledir,sprintf('%s_green',subjectName));
dataFilename_blue = GetMostRecentFileName(dataFiledir,sprintf('%s_blue',subjectName));

data_red = load(dataFilename_red);
data_green = load(dataFilename_green);
data_blue = load(dataFilename_blue);

%% Read out some variables.
nRepeat = data_red.data.expParams.nRepeat;
nTestImages = data_red.data.expParams.nTestImages;

%% Rearrange the experiment results.
%
% Test images were displayed in a random order, so the raw data is
% sorted in the same random order. Here, we sort out the results.

% Get the index to sort out the results. 
for rr = 1:nRepeat
    for ii = 1:nTestImages
        idxOrder(ii,rr) = find(data_red.data.expParams.randOrder(:,rr) == ii);
    end
end

% Sort out the results.
matchingIntensityColorCorrect_sorted = data_red.data.matchingIntensityColorCorrect(idxOrder);

% Mean results.
mean_red = mean(matchingIntensityColorCorrect_sorted,2);

%% Plot the results.

%% Save out something if you want.
