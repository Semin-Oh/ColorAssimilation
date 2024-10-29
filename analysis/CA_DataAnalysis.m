% CA_DataAnalysis.
%
% This routine is for analyzing the data.
%
% See also:
%    CA_RunExperiment.

% History:
%    09/09/24    smo    - Started on it.
%    10/09/24    smo    - Now load the experiment data from the Dropbox.
%    10/23/24    smo    - Now we can get a result of all test images and
%                         all primaries at once.

%% Initialize.
close all; clear;

%% Set variables to analyze the data.
%
% Get computer info.
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

% Set variables from here. We may make a loop to do everything at once.
% Decide which subject.
idxSubject = 1;
subjectName = subjectNames{idxSubject};

% Choose how recent data to load. Set this 0 to load the most recent data
% from the subject.
olderDate = 1;

% Set experimental mode either 'periphery' or 'fovea'.
expModeOptions = {'periphery','fovea'};
idxExpMode = 1;
expMode = expModeOptions{idxExpMode};

% Primaries.
whichPrimaryOptions = {'red','green','blue'};
nPrimaries = length(whichPrimaryOptions);

% We will fit all results on one figure.
figure; hold on;
figurePosition = [0 0 1200 500];
set(gcf,'Position',figurePosition);

% Make a loop for analyzing for all primaries.
for pp = 1:nPrimaries
    idxWhichPrimary = pp;
    whichPrimary = whichPrimaryOptions{idxWhichPrimary};

    % Set marker color over different primaries.
    switch whichPrimary
        case 'red'
            markerFaceColor = 'r';
        case 'green'
            markerFaceColor = 'g';
        case 'blue'
            markerFaceColor = 'b';
    end

    %% Load the exp data to analyze.
    %
    % Set the directory name per subject.
    dataFiledir = fullfile(testFiledir,subjectName);

    % Read out all avaialble data over different primary color.
    dataFilename = GetMostRecentFileName(dataFiledir,sprintf('%s_%s_%s',subjectName,expMode,whichPrimary),'olderDate',olderDate);
    rawData = load(dataFilename);

    % Display gamut.
    switch rawData.data.imageParams.whichDisplay
        case 'curvedDisplay'
            xyY_displayPrimary = [0.6781 0.2740 0.1574; 0.3084 0.6616 0.0648; 17.0886 61.3867 6.1283];
            M_RGB2XYZ = xyYToXYZ(xyY_displayPrimary);
            gamma = 2.2669;
    end
    uv_displayPrimary = xyTouv(xyY_displayPrimary(1:2,:));
    uv_displayTargetPrimary = uv_displayPrimary(:,idxWhichPrimary);

    %% Rearrange the experiment results.
    %
    % Test images were displayed in a random order, so the raw data is
    % sorted in the same random order. Here, we sort out the results.

    % Read out some variables.
    nRepeat = rawData.data.expParams.nRepeat;
    nTestImages = rawData.data.expParams.nTestImages;
    nColorPoints = rawData.data.imageParams.nTestPoints;
    colorPoints = rawData.data.imageParams.intensityColorCorrect;
    for tt = 1:nTestImages
        [filepath testImageNameTemp ext] = fileparts(rawData.data.imageParams.testImageFilenames{tt});
        testImageNames{tt} = strrep(testImageNameTemp,'_','-');
    end

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

    %% Calculate the color assimiliation index (AI).
    %
    % Make a loop for the test images.
    for tt = 1:nTestImages
        idxTestImage = tt;

        % Load out chromaticity coordinates.
        %
        % Read out the first column of the image profile array which is the zero
        % color corrected image, which means the chromaticity coordinates of the
        % color corrected image is actually the same as the raw image.
        idxColorCorrectRaw = 1;
        imageProfile_raw = imageProfile{idxTestImage,idxColorCorrectRaw};

        % Raw test image on the u'v' coordinates.
        uvY_testImageRaw = imageProfile_raw.uvY_colorCorrectedImage;

        % We will process the image with NaN components excluded.
        idxValidPixels = ~any(isnan(uvY_testImageRaw));
        uvY_testImageRaw = uvY_testImageRaw(:,idxValidPixels,1);

        % Test image with stripes on the u'v' coordinates.
        uvY_testImageStripe = imageProfile_raw.uvY_testImageStripe;
        uvY_testImageStripe = uvY_testImageStripe(:,~any(isnan(uvY_testImageStripe),1));

        % Color corrected test image on the u'v' coordinates. This is decided based
        % on the experiment results. We will calculate it based on the mean results
        % of the matching intensity of color correction.
        meanMatchingIntensityColorCorrect_target = meanMatchingIntensityColorCorrect(idxTestImage);
        uv_colorCorrectImage = MakeImageShiftChromaticity(uvY_testImageRaw(1:2,:),uv_displayTargetPrimary,meanMatchingIntensityColorCorrect_target);
        
        % THIS PART NEEDS TO BE FIGURED OUT.
        %
        % Set the luminace of the color corrected image the same as the
        % striped image.
        uvY_colorCorrectImage = zeros(size(uvY_testImageStripe));
        uvY_colorCorrectImage(3,:) = uvY_testImageStripe(3,:);
        uvY_colorCorrectImage(1:2,idxValidPixels) = uv_colorCorrectImage(:,idxValidPixels);

        % Quantize the color corrected image.
        XYZ_colorCorrectImage = uvYToXYZ(uvY_colorCorrectImage);
        RGB_colorCorrectImage = XYZToRGB(XYZ_colorCorrectImage,M_RGB2XYZ,gamma);
        XYZ_colorCorrectImage = RGBToXYZ(RGB_colorCorrectImage,M_RGB2XYZ,gamma);
        uvY_colorCorrectImage = XYZTouvY(XYZ_colorCorrectImage);

        % COMMENTED OUT AS IT DIDN'T WORK.
        % % Get the chromaticity coordinats of the color corrected images for all
        % % test points per the target test image. This will contain from the raw
        % % test image to the most saturated color corrected image.
        % for ii = 1:nColorPoints
        %     uvY_colorCorrectedImage_oneImage_temp = imageProfile{idxTestImage,ii}.uvY_colorCorrectedImage;
        % 
        %     % Make sure every number is finite.
        %     columns_NaN = any(isnan(uvY_colorCorrectedImage_oneImage_temp),1);
        %     uvY_colorCorrectedImage_oneImage_temp = uvY_colorCorrectedImage_oneImage_temp(:,~columns_NaN);
        % 
        %     % Calculate mean coordinates.
        %     mean_uvY_colorCorrectedImage(:,ii) = mean(uvY_colorCorrectedImage_oneImage_temp,2);
        % end
        % 
        % % Find the mean chromaticity coordinates that corresponds the mean matching
        % % color correct values from the experiment. This is one way to do it, maybe
        % % we can directly calculates this from the image profile later on, but for
        % % now, we do it in this way.
        % %
        % % Set data points.
        % x = mean_uvY_colorCorrectedImage(1,:);
        % y = mean_uvY_colorCorrectedImage(2,:);
        % z = rawData.data.imageParams.intensityColorCorrect;
        % 
        % % Create the interpolant.
        % F = scatteredInterpolant(x', y', z', 'natural');
        % 
        % % Define the z value you're searching for
        % z_target = meanMatchingIntensityColorCorrect_target;
        % 
        % % Define an objective function to minimize the absolute difference.
        % obj = @(p) abs(F(p(1), p(2)) - z_target);
        % 
        % % Initial guess for [xi, yi].
        % z0 = [mean(x), mean(y)];
        % 
        % % Use fminsearch to find the xi, yi that gives zi_target
        % z_found = fminsearch(obj, z0);
        % 
        % % Extract the results
        % x_found = z_found(1);
        % y_found = z_found(2);
        % mean_uvY_colorCorrectImage = [x_found; y_found];

        % Calculate the Color Assimiliation index (AI) here.
        %
        % Reference: Shinoda, H., & Ikeda, M. (2004). Color assimilation on grating
        % affected by its apparent stripe width. Color Research & Application,
        % 29(3), 187-195.
        %
        % IMPORTANT: We collected 'matchingIntensityColorCorrect' as a raw data.
        % Itself does not represent how much color assmiliation happened per each
        % test image. The results should be compared in AI index, which is relative
        % mean chromaticity shift, which reflects the color assmiliation.
        %
        % Mean color coordinates. The result of the color corrected image is
        % calculated from the above.
        mean_uvY_testImageRaw = mean(uvY_testImageRaw,2);
        mean_uvY_testImageStripe = mean(uvY_testImageStripe,2);
        mean_uvY_colorCorrectImage = mean(uvY_colorCorrectImage,2);

        % 'a' is the distance from the original to the image with the stripes and
        % 'm' is the distance from the original to the matched color.
        m = norm(mean_uvY_colorCorrectImage(1:2)-mean_uvY_testImageRaw(1:2));
        a = norm(mean_uvY_testImageStripe(1:2)-mean_uvY_testImageRaw(1:2));

        % The 'AI' value should be zero if there is no color assimiliation effect.
        AI(tt) = m/a;

        %% Plot the results.
        %
        subplot(nPrimaries,nTestImages,tt + nTestImages*(pp-1)); hold on;

        % Plot the image profiles.
        plot(uvY_testImageRaw(1,:),uvY_testImageRaw(2,:),'k.');
        plot(uvY_testImageStripe(1,:),uvY_testImageStripe(2,:),'k.','MarkerEdgeColor',[1 1 0]);
        % plot(uvY_colorCorrectImage(1,:),uvY_colorCorrectImage(2,:),'r.');

        % Plot the mean chromaticity.
        plot(mean_uvY_testImageRaw(1),mean_uvY_testImageRaw(2),'o','MarkerFaceColor','k','markeredgecolor','k');
        plot(mean_uvY_testImageStripe(1),mean_uvY_testImageStripe(2),'o','MarkerFaceColor',[1 1 0],'markeredgecolor','k');
        plot(mean_uvY_colorCorrectImage(1),mean_uvY_colorCorrectImage(2),'o','MarkerFaceColor',markerFaceColor,'markeredgecolor','k');

        % Plot the Plackian locus.
        load T_xyzJuddVos
        T_XYZ = T_xyzJuddVos;
        T_xy = [T_XYZ(1,:)./sum(T_XYZ); T_XYZ(2,:)./sum(T_XYZ)];
        T_uv = xyTouv(T_xy);
        plot([T_uv(1,:) T_uv(1,1)], [T_uv(2,:) T_uv(2,1)], 'k-');
        
        % Plot the display gamut with the target primary highlighted.
        plot([uv_displayPrimary(1,:) uv_displayPrimary(1,1)], [uv_displayPrimary(2,:) uv_displayPrimary(2,1)],'k-');
        plot(uv_displayTargetPrimary(1),uv_displayTargetPrimary(2),'^','markerfacecolor',markerFaceColor,'markeredgecolor','k','MarkerSize',8);
        
        % TEMP - Trajectory when we fit to find the mean chromaticity of
        % the color corrected image.
        % plot(x,y,'-','LineWidth',2,'Color',markerFaceColor);

        % Figure stuff.
        xlim([0 0.7]);
        ylim([0 0.7]);
        xlabel('CIE u-prime','fontsize',13);
        ylabel('CIE v-prime','fontsize',13);
        % legend('raw','stripes','matched','Mean(raw)','Mean(stripes)','Mean(matched)',...
        %     'Location','southeast','fontsize',11);
        legend('raw','stripes','Mean(raw)','Mean(stripes)','Mean(matched)',...
            'Display','Target Primary','Location','southeast','fontsize',11);
        title(sprintf('Test Image %d (AI = %.2f) \n Image = (%s)',tt,AI(tt),testImageNames{tt}));

        % Show the progress
        fprintf('Progress - Primary (%d/%d) / Test image (%d/%d) \n',pp,nPrimaries,tt,nTestImages);
    end

    % Save out the assmiliation index (AI) results.
    switch pp
        case 1
            AI_all.red = AI;
        case 2
            AI_all.green = AI;
        case 3
            AI_all.blue = AI;
    end
end

% %% Plot the results.
% %
% % X-axis as test images.
% xaxisTestImages = linspace(1,nTestImages,nTestImages);
%
% % Comparison of the mean chosen color correction over different test
% % images.
% figure; hold on;
% plot(xaxisTestImages,meanMatchingIntensityColorCorrect,'o','MarkerFaceColor',markerFaceColor,'MarkerEdgeColor','k');
% plot(xaxisTestImages,matchingIntensityColorCorrect_sorted,'k.');
% xlabel('Test Image');
% ylabel('Matching intensity');
% xlim([1 nTestImages]);
% xticks(xaxisTestImages);
% xticklabels(rawData.data.imageParams.testImageFilenames);
% ylim([0 0.6]);
% legend(sprintf('Mean (N=%d)',nRepeat),'Raw Data');
% title(sprintf('Primary = (%s) / Experiment mode = (%s) / Subject = (%s)',whichPrimary,expMode,subjectName));

%% Save out something if you want.
SAVETHERESULTS = false;

if (SAVETHERESULTS)
end
