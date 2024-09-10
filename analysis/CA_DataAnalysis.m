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
