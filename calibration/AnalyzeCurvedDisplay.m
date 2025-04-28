% AnalyzeCurvedDisplay.
%
% This routine checks and shows the basic characteristics of the display.

% History:
%    07/29/24    smo    - Started on it.
%    07/30/24    smo    - Now plotting spectra, CIE xy coordinates, gamma
%                         curve, and also optimizing gamma.
%    04/08/25    smo    - Routine name changed from 'CalDisplay'.

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
testFiledir = '/Users/semin/Documents/MATLAB/ColorAssimilation/etc/ColorCalibration/rawdata';
testFilenameSpd = fullfile(testFiledir,'spectra.mat');
spdData = load(testFilenameSpd);

% Load the photometer data.
testFilenameGammatable = fullfile(testFiledir,'gammatable.mat');
gammatableData = load(testFilenameGammatable);

%% Spectra.
spd_left = spdData.spd.left;
spd_right = spdData.spd.right;
spd_center = spdData.spd.center;
displayOptions = {'left','right','center'};
nDisplays = length(displayOptions);

% Define channels. We will use this for plotting the results with different
% colors for both spectra and gamma curves.
channelOptions = {'red','green','blue','gray'};
markerColorOptions = {'r','g','b','k'};
nChannels = length(channelOptions);
S = [380 1 401];
wls = SToWls(S);

% Plot it.
if (verbose)
    figureSize = [0 0 800 800];
    figure;
    set(gcf,'Position',figureSize);

    % Make a subplot of the spectra per each channel and a display.
    for ii = 1:nChannels
        % Left.
        subplot(nChannels,nDisplays,1+nDisplays*(ii-1)); hold on;
        plot(wls,spd_left(:,:,ii),'-','color',markerColorOptions{ii});
        xlabel('Wavelength (nm)');
        ylabel('Spectral power');
        xlim([380 780]);
        title(sprintf('Display = (%s)',displayOptions{1}));
        legend(channelOptions{ii},'Location','northeast');

        % Center.
        subplot(nChannels,nDisplays,2+nDisplays*(ii-1)); hold on;
        plot(wls,spd_center(:,:,ii),'-','color',markerColorOptions{ii});
        xlabel('Wavelength (nm)');
        ylabel('Spectral power');
        xlim([380 780]);
        title(sprintf('Display = (%s)',displayOptions{2}));
        legend(channelOptions{ii},'Location','northeast');

        % Right.
        subplot(nChannels,nDisplays,3+nDisplays*(ii-1)); hold on;
        plot(wls,spd_right(:,:,ii),'-','color',markerColorOptions{ii});
        xlabel('Wavelength (nm)');
        ylabel('Spectral power');
        xlim([380 780]);
        title(sprintf('Display = (%s)',displayOptions{3}));
        legend(channelOptions{ii},'Location','northeast');
    end
end

%% Spectra of primaries.
intensity_dRGB = 255;
figure; hold on;

% Center.
plot(wls,spd_center(:,intensity_dRGB,1),'r-');
plot(wls,spd_center(:,intensity_dRGB,2),'g-');
plot(wls,spd_center(:,intensity_dRGB,3),'b-');
xlabel('Wavelength (nm)');
ylabel('Spectral power');
xlim([min(wls) max(wls)]);
legend('Red','Green','Blue');

% % Left.
% plot(wls,spd_left(:,intensity_dRGB,1),'r-');
% plot(wls,spd_left(:,intensity_dRGB,2),'g-');
% plot(wls,spd_left(:,intensity_dRGB,3),'b-');
%
% % Right.
% plot(wls,spd_right(:,intensity_dRGB,1),'r-');
% plot(wls,spd_right(:,intensity_dRGB,2),'g-');
% plot(wls,spd_right(:,intensity_dRGB,3),'b-');

%% Chromaticity diagram.
load T_xyzJuddVos
T_XYZ = T_xyzJuddVos;

% Match the size of the array.
T_XYZ = interp1(SToWls(S_xyzJuddVos),T_XYZ',wls)';

% Calculate the CIE XYZ values. Each result array has four cells, red,
% green, blue, and gray channels, respectively.
for ii = 1:nChannels
    XYZ_left{ii} = 683 * T_XYZ * spd_left(:,:,ii);
    XYZ_right{ii} = 683 * T_XYZ * spd_right(:,:,ii);
    XYZ_center{ii} = 683 * T_XYZ * spd_center(:,:,ii);
end

% Black correction if you want.
BLACKCORRECTION = true;
if (BLACKCORRECTION)
    for ii = 1:nChannels
        % Find the index for the black per each channel. For some channels,
        % the low input setting results show 'NaN' as it was not strong
        % enough to be measured with the spectrometer. Here, we find the
        % lowest measurable point to define it as a black. Check if all
        % entries are valid numbers.
        %
        % Left display.
        idx = 1;
        while 1
            % Check if the entry contains Nan.
            if ~isnan(XYZ_left{ii}(:,idx))
                % Check if any value is negative.
                if ~any(XYZ_left{ii}(:,idx)<0)
                    break
                end
            end

            % Move on to the next column to search.
            idx = idx + 1;
        end

        % Set the index here.
        idxBlack_left = idx;

        % Right display.
        idx = 1;
        while 1
            % Check if the entry contains Nan.
            if ~isnan(XYZ_right{ii}(:,idx))
                % Check if any value is negative.
                if ~any(XYZ_right{ii}(:,idx)<0)
                    break
                end
            end

            % Move on to the next column to search.
            idx = idx + 1;
        end

        % Set the index here.
        idxBlack_right = idx;

        % Center display.
        idx = 1;
        while 1
            % Check if the entry contains Nan.
            if ~isnan(XYZ_center{ii}(:,idx))
                % Check if any value is negative.
                if ~any(XYZ_center{ii}(:,idx)<0)
                    break
                end
            end

            % Move on to the next column to search.
            idx = idx + 1;
        end

        % Set the index here.
        idxBlack_center = idx;

        % Set the black levels here. For convinience, we set the black as
        % the lowest value per each channel.
        XYZ_left_black(:,ii) = XYZ_left{ii}(:,idxBlack_left);
        XYZ_right_black(:,ii) = XYZ_right{ii}(:,idxBlack_right);
        XYZ_center_black(:,ii) = XYZ_center{ii}(:,idxBlack_center);

        % Black correction happens here.
        XYZ_left{ii} = XYZ_left{ii} - XYZ_left_black(:,ii);
        XYZ_right{ii} = XYZ_right{ii} - XYZ_right_black(:,ii);
        XYZ_center{ii} = XYZ_center{ii} - XYZ_center_black(:,ii);
    end
end

% Calculate the CIE xy coordinates.
for ii = 1:nChannels
    xyY_left{ii} = XYZToxyY(XYZ_left{ii});
    xyY_right{ii} = XYZToxyY(XYZ_right{ii});
    xyY_center{ii} = XYZToxyY(XYZ_center{ii});
end

% Get the display gamut coordinates.
xyY_left_gamut = [xyY_left{1}(:,end) xyY_left{2}(:,end) xyY_left{3}(:,end)];
xyY_right_gamut = [xyY_right{1}(:,end) xyY_right{2}(:,end) xyY_right{3}(:,end)];
xyY_center_gamut = [xyY_center{1}(:,end) xyY_center{2}(:,end) xyY_center{3}(:,end)];

% Plot it.
if (verbose)
    figure; hold on;
    figureSize = [0 0 1000 300];
    set(gcf,'position',figureSize);

    % Make a loop to plot the same formatted figure for each display.
    for dd = 1:nDisplays
        subplot(1,nDisplays,dd); hold on;

        % Define which display to use.
        switch dd
            case 1
                xyY_temp = xyY_left;
            case 2
                xyY_temp = xyY_center;
            case 3
                xyY_temp = xyY_right;
        end

        % Make a loop for plotting all channels per each display.
        for ii = 1:nChannels
            plot(xyY_temp{ii}(1,:),xyY_temp{ii}(2,:),'o','color',markerColorOptions{ii});
        end
        xlabel('CIE x');
        ylabel('CIE y');
        xlim([0 1]);
        ylim([0 1]);
        title(sprintf('%s display',displayOptions{dd}));

        % Planckian locus.
        T_xy = [T_XYZ(1,:)./sum(T_XYZ); T_XYZ(2,:)./sum(T_XYZ)];
        plot([T_xy(1,:) T_xy(1,1)], [T_xy(2,:) T_xy(2,1)], 'k-');

        % sRGB.
        xyY_sRGB = [0.6400 0.3000 0.1500; 0.3300 0.6000 0.0600; 0.2126 0.7152 0.0722];
        plot([xyY_sRGB(1,:) xyY_sRGB(1,1)], [xyY_sRGB(2,:) xyY_sRGB(2,1)],'k-','LineWidth',1);
    end
end

%% Display gamut with white point.
if (verbose)
    % Display gamut.
    figure; hold on;

    % Center.
    uv_center_gamut = xyTouv(xyY_center_gamut(1:2,:));
    plot([uv_center_gamut(1,:) uv_center_gamut(1,1)], [uv_center_gamut(2,:) uv_center_gamut(2,1)],...
        'b-','markerfacecolor','k','markeredgecolor','k','LineWidth',1);
    % White point.
    xyY_center_whitepoint = xyY_center{4}(:,end);
    uv_center_whitepoint = xyTouv(xyY_center_whitepoint(1:2,:));
    plot(uv_center_whitepoint(1),uv_center_whitepoint(2),'o',...
        'MarkerFaceColor','b','MarkerEdgeColor','k')

    % % Left.
    % plot([xyY_left_gamut(1,:) xyY_left_gamut(1,1)], [xyY_left_gamut(2,:) xyY_left_gamut(2,1)],'o-','LineWidth',2);
    % % Right.
    % plot([xyY_right_gamut(1,:) xyY_right_gamut(1,1)], [xyY_right_gamut(2,:) xyY_left_gamut(2,1)],'*--','LineWidth',2);

    % sRGB.
    xyY_sRGB = [0.6400 0.3000 0.1500; 0.3300 0.6000 0.0600; 0.2126 0.7152 0.0722];
    uv_sRGB = xyTouv(xyY_sRGB(1:2,:));
    plot([uv_sRGB(1,:) uv_sRGB(1,1)], [uv_sRGB(2,:) uv_sRGB(2,1)],'k:','LineWidth',1);

    % D65.
    xy_D65 = [0.3127; 0.3290];
    uv_D65 = xyTouv(xy_D65);
    plot(uv_D65(1),uv_D65(2),'ko');

    % Planckian locus.
    T_xy = [T_XYZ(1,:)./sum(T_XYZ); T_XYZ(2,:)./sum(T_XYZ)];
    T_uv = xyTouv(T_xy);
    % plot([T_uv(1,:) T_uv(1,1)], [T_uv(2,:) T_uv(2,1)], 'k-');
    plot([T_uv(1,1:65) T_uv(1,1)], [T_uv(2,1:65) T_uv(2,1)], 'k-');

    xlabel('CIE u-prime');
    ylabel('CIE v-prime');
    xlim([0 1]);
    ylim([0 1]);
    title('Display gamut on the CIE uv-prime coordinates');
    % legend('Left','Right','Center','sRGB')
    legend('Display Gamut (center)','Display White Point','sRGB','D65');
end

%% Gamma curves.
%
% Read out the data. Note that each output of the gamma table contains four
% arrays, each being respectively, red, green, blue, and gray channels.
inputSettings_gammatable = gammatableData.gammatable.inputSettings;
output_gammatable_left = gammatableData.gammatable.output.left;
output_gammatable_right = gammatableData.gammatable.output.right;
output_gammatable_center = gammatableData.gammatable.output.center;

% Make a loop to calculate each channel.
if (verbose)
    figure; hold on;
end
for ii = 1:nChannels
    % Match the array size of the output as the same number of the input
    % settings.
    output_gammatable_left_temp = output_gammatable_left{ii}(inputSettings_gammatable);
    output_gammatable_right_temp = output_gammatable_right{ii}(inputSettings_gammatable);
    output_gammatable_center_temp = output_gammatable_center{ii}(inputSettings_gammatable);

    % Normalize the output.
    output_gammatable_left_temp = output_gammatable_left_temp./max(output_gammatable_left_temp);
    output_gammatable_right_temp = output_gammatable_right_temp./max(output_gammatable_right_temp);
    output_gammatable_center_temp = output_gammatable_center_temp./max(output_gammatable_center_temp);

    % Calculate the gamma.
    gamma_left = CalculateGamma(inputSettings_gammatable,output_gammatable_left_temp);
    gamma_right = CalculateGamma(inputSettings_gammatable,output_gammatable_right_temp);
    gamma_center = CalculateGamma(inputSettings_gammatable,output_gammatable_center_temp);

    % Save out the gamma values.
    gamma.left(ii) = gamma_left;
    gamma.right(ii) = gamma_right;
    gamma.center(ii) = gamma_center;

    % Plot it.
    if (verbose)
        % Gray.
        subplot(2,nChannels/2,ii); hold on;
        plot(inputSettings_gammatable,output_gammatable_left_temp,'o-','Color',markerColorOptions{ii});
        plot(inputSettings_gammatable,output_gammatable_right_temp,'*-','Color',markerColorOptions{ii});
        plot(inputSettings_gammatable,output_gammatable_center_temp,'.-','Color',markerColorOptions{ii});
        xlabel('Input settings');
        ylabel('Output');
        xlim([0 1024]);
        ylim([0 1]);
        legend(sprintf('left (G=%.2f)',gamma_left),...
            sprintf('right (G=%.2f)',gamma_right),...
            sprintf('center (G=%.2f)',gamma_center),'Location','northwest');
        title(sprintf('%s',channelOptions{ii}));
    end
end
