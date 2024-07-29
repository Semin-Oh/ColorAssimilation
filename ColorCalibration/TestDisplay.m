% TestDisplay.
%
% This routine checks and shows the basic characteristics of the display.

% History:
%    07/29/24    smo    - Started on it.

%% Initialize.
clear all; close all;

%% Set variables.
verbose = true;

%% Load the calibration data.
%
% Note that it seems the measurements for the gamma was measured in 10-bit,
% but the spectra was measured in 8-bit system.
%
% Load the spectrum data.
testFiledir = '/Users/semin/Documents/MATLAB/ColorAssimilation/ColorCalibration/rawdata';
testFilenameSpd = fullfile(testFiledir,'spectra.mat');
spdData = load(testFilenameSpd);

% Load the photometer data.
testFilenameGammatable = fullfile(testFiledir,'gammatable.mat');
gammatableData = load(testFilenameGammatable);

%% Spectra.

%% Chromaticity diagram.

%% Additivity test.


%% Gamma curves.
%
% Read out the data.
inputSettings_gammatable = gammatableData.gammatable.inputSettings;
output_gammatable_left = gammatableData.gammatable.output.left;
output_gammatable_right = gammatableData.gammatable.output.right;
output_gammatable_center = gammatableData.gammatable.output.center;

if (verbose)
    figure; hold on;
   
end
