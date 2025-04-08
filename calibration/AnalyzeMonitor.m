% AnalyzeMonitor.
%
% This routine checks and shows the basic characteristics of the display.
% This is written to test the EIZO monitor for Natural CAM project.
%
% See also:
%    AnalyzeCurvedDisplay.m.

% History:
%    04/08/25    smo    - Copied from 'AnalyzeCurvedDisplay.m' and made it
%                         for EIZO display.

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
displayType = 'EIZO';
testFiledir = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/calibration';
testFilename = sprintf('spd_%s',displayType);
testFilenameSpd = GetMostRecentFileName(testFiledir,testFilename);
rawData = load(testFilenameSpd);

% Read out some variables.
spds = rawData.data.spectra;
channelOptions = rawData.data.describe.measuredChannels;
nChannels = length(channelOptions);
markerColorOptions = {'r','g','b','k'};
S = [380 1 401];
wls = SToWls(S);

%% Calculate CIE XYZ values and set gamma table.
%
% Read out color matching functions.
load T_xyzJuddVos
T_XYZ = T_xyzJuddVos;

% Match the size of the array.
T_XYZ = interp1(SToWls(S_xyzJuddVos),T_XYZ',wls)';

% Calculate the CIE XYZ values. Each result array has four cells, red,
% green, blue, and gray channels, respectively.
for cc = 1:nChannels
    XYZ{cc} = 683 * T_XYZ * spds{cc}(:,:);
end

% Gamma table.
%
% Input settings.
gammatable_input = rawData.data.describe.targetScreenSettings;

% Output. We read out Y values from the XYZ array.
for cc = 1:nChannels
    gammatable_output{cc} = XYZ{cc}(2,:);
end

%% Plot the spectra.
%
% Measurements for all channels with all steps.
if (verbose)
    figureSize = [0 0 800 300];
    figure; hold on;
    set(gcf,'Position',figureSize);
    sgtitle(sprintf('Display = (%s)',displayType));
    for cc = 1:nChannels
        subplot(1,nChannels,cc);
        spdTemp = spds{cc};
        plot(wls,spdTemp(:,:),'-','color',markerColorOptions{cc});
        xlabel('Wavelength (nm)');
        ylabel('Spectral power');
        xlim([380 780]);
        title(sprintf('Channel = (%s)',channelOptions{cc}));
        legend(channelOptions{cc},'Location','northeast');
        axis square;
    end
end

% Spectra of primaries.
figure; hold on;
plot(wls,spds{1}(:,end),'r-');
plot(wls,spds{2}(:,end),'g-');
plot(wls,spds{3}(:,end),'b-');
xlabel('Wavelength (nm)');
ylabel('Spectral power');
xlim([380 780]);
legend('Red','Green','Blue');
axis square;

%% Chromaticity diagram.
%
% Black correction if you want.
BLACKCORRECTION = true;
if (BLACKCORRECTION)
    for cc = 1:nChannels
        % Set the black levels here. For convinience, we set the black as
        % the lowest value per each channel.
        XYZ_black_temp = XYZ{cc}(:,1);

        % Black correction happens here.
        XYZ{cc} = XYZ{cc} - XYZ_black_temp;
    end
end

% Calculate the CIE xy coordinates.
for cc = 1:nChannels
    xyY{cc} = XYZToxyY(XYZ{cc});
end

% Get the display gamut coordinates.
xyY_displayGamut = [xyY{1}(:,end) xyY{2}(:,end) xyY{3}(:,end)];
xyY_displayWhite = xyY{4}(:,end);
xyY_D65 = [0.3127 0.3290];

% Plot it.
if (verbose)
    figure; hold on;
    figureSize = [0 0 1000 300];
    set(gcf,'position',figureSize);

    % Display gamma.
    p_displayGamut = plot([xyY_displayGamut(1,:) xyY_displayGamut(1,1)], [xyY_displayGamut(2,:) xyY_displayGamut(2,1)],'b.:','LineWidth',2);

    % Display white point.
    p_displayWP = plot(xyY_displayWhite(1),xyY_displayWhite(2),'o','MarkerFaceColor','b','MarkerEdgeColor','k');

    % sRGB.
    xyY_sRGB = [0.6400 0.3000 0.1500; 0.3300 0.6000 0.0600; 0.2126 0.7152 0.0722];
    p_sRGB = plot([xyY_sRGB(1,:) xyY_sRGB(1,1)], [xyY_sRGB(2,:) xyY_sRGB(2,1)],'k-','LineWidth',1);

    % D65 white poitn.
    p_d65 = plot(xyY_D65(1),xyY_D65(2),'ko','MarkerFaceColor','k');

    % Planckian locus.
    T_xy = [T_XYZ(1,:)./sum(T_XYZ); T_XYZ(2,:)./sum(T_XYZ)];
    p_planckian = plot([T_xy(1,:) T_xy(1,1)], [T_xy(2,:) T_xy(2,1)], 'k-');

    xlabel('CIE x');
    ylabel('CIE y');
    xlim([0 1]);
    ylim([0 1]);
    title('Display gamut');
    axis square;
    legend([p_displayGamut p_sRGB p_planckian p_displayWP],'Display','sRGB','Planckian locus','Display white');
end

%% Gamma curves.
%
% Make a loop to calculate each channel.
if (verbose)
    figure; hold on;
end
for cc = 1:nChannels
    % Match the array size of the output as the same number of the input
    % settings.
    output_gammatable_temp = gammatable_output{cc};

    % Normalize the output.
    output_gammatable_temp = output_gammatable_temp./max(output_gammatable_temp);

    % Calculate the gamma.
    gamma_temp = CalculateGamma(gammatable_input,output_gammatable_temp);

    % Save out the gamma values.
    gamma(cc) = gamma_temp;

    % Plot it.
    if (verbose)
        subplot(2,nChannels/2,cc); hold on;
        plot(gammatable_input,output_gammatable_temp,'.-','Color',markerColorOptions{cc});
        xlabel('Input settings');
        ylabel('Output');
        xlim([0 1]);
        ylim([0 1]);
        sprintf('center (G=%.2f)',gamma_temp,'Location','northwest');
        title(sprintf('%s (gamma = %.2f)',channelOptions{cc},gamma_temp));
    end
end

%% 3x3 conversion matrix from RGB to XYZ.
XYZ_red = XYZ{1}(:,end);
XYZ_green = XYZ{2}(:,end);
XYZ_blue = XYZ{3}(:,end);
M_RGBToXYZ = [XYZ_red XYZ_green XYZ_blue];
