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
%    11/06/24    smo    - Now it works on Lab Linux computer.

%% Initialize.
close all; clear;

%% Get available subject info.
%
% Get computer info.
sysInfo = GetComputerInfo();

% Set the file dir differently depending on the computer.
switch sysInfo.userShortName
    % Semin office computer.
    case 'semin'
        baseFiledir = '/Users/semin/Dropbox (Personal)/Giessen/projects';
        % Lab Linux computer.
    case 'gegenfurtner'
        baseFiledir = '/home/gegenfurtner/Dropbox/Giessen/projects';
    otherwise
        % Semin's laptop.
        baseFiledir = 'C:\Users\ohsem\Dropbox (Personal)\Giessen\projects';
end

% Set repository name.
projectName = 'ColorAssimilation';
testFiledir = fullfile(baseFiledir,projectName,'data');

% Get available subject names.
subjectNameContent = dir(testFiledir);
subjectNameList = {subjectNameContent.name};
subjectNames = subjectNameList(~startsWith(subjectNameList,'.'));

%% Set variables to analyze the data.
%
% Choose which subjects to analyze. For now, we will run for every subject
% available.
targetSubjects = subjectNames;
nSubjects = length(targetSubjects);

% Choose how recent data to load. Set this 0 to load the most recent data
% from each subject.
olderDate = 0;

% Set experimental mode either 'periphery' or 'fovea'.
expModeOptions = {'periphery','fovea'};
nExpModes = length(expModeOptions);

% Primaries.
whichPrimaryOptions = {'red','green','blue'};
nPrimaries = length(whichPrimaryOptions);

% We will save out all the data here.
AI_periphery = [];
AI_fovea = [];

%% Data analysis happens from here
%
% Loop for all subjects.
for ss = 1:nSubjects
    % Get the subject name to load the raw data. For now, the raw data is
    % saved in the folder with subject's name. We will update it later on.
    subjectName = subjectNames{ss};
    fprintf('Data loading - Subject = (%s) / Number of subjects (%d/%d) \n',subjectName,ss,nSubjects);

    % Loop for both experimental mode periphery and foveal.
    for ee = 1:nExpModes
        % Set experimental mode.
        expMode = expModeOptions{ee};

        % Make a plot to fit all results per experimental mode.
        figure; hold on;
        figurePosition = [0 0 1200 500];
        set(gcf,'Position',figurePosition);
        sgtitle(sprintf('Experiment mode = (%s)',expMode));
        fprintf('Now starting to analyze the data - (%s) \n',expMode);

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

            % Sort out the results. Array should look [TestImages x
            % Repeatitions]. For example, if you used 5 test images and 10
            % repeatitions per each test image, the array will look like 5x10.
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
                % Load out chromaticity coordinates of the test images.
                %
                % Read out the first column of the image profile array which is the zero
                % color corrected image, which means the chromaticity coordinates of the
                % color corrected image is actually the same as the raw image.
                idxColorCorrectRaw = 1;
                imageProfile_raw = imageProfile{idxTestImage,idxColorCorrectRaw};

                % Get the raw and striped test image on the u'v' coordinates.
                uvY_testImageRaw = imageProfile_raw.uvY_colorCorrectedImage;
                uvY_testImageStripe = imageProfile_raw.uvY_testImageStripe;

                % Color corrected test image on the u'v' coordinates. This is decided based
                % on the experiment results. We will calculate it based on the mean results
                % of the matching intensity of color correction.
                matchingIntensityColorCorrect_target = meanMatchingIntensityColorCorrect(idxTestImage);
                % matchingIntensityColorCorrect_target = matchingIntensityColorCorrect_sorted(idxTestImage,rr);
                uv_colorCorrectImage = MakeImageShiftChromaticity(uvY_testImageRaw(1:2,:),uv_displayTargetPrimary,matchingIntensityColorCorrect_target);

                % Set the luminace of the color corrected image the same as the
                % striped image.
                uvY_colorCorrectImage = zeros(size(uvY_testImageStripe));
                uvY_colorCorrectImage(1:2,:) = uv_colorCorrectImage;
                uvY_colorCorrectImage(3,:) = uvY_testImageStripe(3,:);

                % Find out valid components that are not 'NaN'.
                %
                % We will process the image with NaN components excluded. Some
                % images contain NaN components for some reason, but not so much.
                idxValidPixels = ~any(isnan(uvY_testImageRaw));

                % Set each each with only vaild pixels without NaN components.
                uvY_testImageRaw = uvY_testImageRaw(:,idxValidPixels);
                uvY_testImageStripe = uvY_testImageStripe(:,idxValidPixels);
                uvY_colorCorrectImage = uvY_colorCorrectImage(:,idxValidPixels);

                % Quantize the color corrected image.
                XYZ_colorCorrectImage = uvYToXYZ(uvY_colorCorrectImage);
                RGB_colorCorrectImage = XYZToRGB(XYZ_colorCorrectImage,M_RGB2XYZ,gamma);
                XYZ_colorCorrectImage = RGBToXYZ(RGB_colorCorrectImage,M_RGB2XYZ,gamma);
                uvY_colorCorrectImage = XYZTouvY(XYZ_colorCorrectImage);

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
                %
                % Thus, 'a' does not change within the same test image, and 'm'
                % changes, which results in different 'AI' values over different
                % levels of color corrections.
                m = norm(mean_uvY_colorCorrectImage(1:2)-mean_uvY_testImageRaw(1:2));
                a = norm(mean_uvY_testImageStripe(1:2)-mean_uvY_testImageRaw(1:2));

                % The 'AI' value should be zero if there is no color assimiliation effect.
                AI(tt) = m/a;

                %% Plot the results.
                %
                subplot(nPrimaries,nTestImages,tt + nTestImages*(pp-1)); hold on;

                % Plot the image profiles.
                plot(uvY_testImageRaw(1,:),uvY_testImageRaw(2,:),'.','MarkerEdgeColor',[0.5 0.5 0.5]);
                % plot(uvY_testImageStripe(1,:),uvY_testImageStripe(2,:),'k.','MarkerEdgeColor',[1 1 0]);
                plot(uvY_colorCorrectImage(1,:),uvY_colorCorrectImage(2,:),'.','MarkerEdgeColor',markerFaceColor);

                % Plot the mean chromaticity.
                plot(mean_uvY_testImageRaw(1),mean_uvY_testImageRaw(2),'o','MarkerFaceColor',[0.2 0.2 0.2],'markeredgecolor','k');
                plot(mean_uvY_testImageStripe(1),mean_uvY_testImageStripe(2),'o','MarkerFaceColor',[1 1 0],'markeredgecolor','k');
                plot(mean_uvY_colorCorrectImage(1),mean_uvY_colorCorrectImage(2),'o','MarkerFaceColor',markerFaceColor,'markeredgecolor','k');

                % Plot the display gamut with the target primary highlighted.
                plot([uv_displayPrimary(1,:) uv_displayPrimary(1,1)], [uv_displayPrimary(2,:) uv_displayPrimary(2,1)],'k-');
                plot(uv_displayTargetPrimary(1),uv_displayTargetPrimary(2),'^','markerfacecolor',markerFaceColor,'markeredgecolor','k','MarkerSize',8);

                % Plot the Plackian locus.
                load T_xyzJuddVos
                T_XYZ = T_xyzJuddVos;
                T_xy = [T_XYZ(1,:)./sum(T_XYZ); T_XYZ(2,:)./sum(T_XYZ)];
                T_uv = xyTouv(T_xy);
                plot([T_uv(1,:) T_uv(1,1)], [T_uv(2,:) T_uv(2,1)], 'k-');

                % Figure stuff.
                xlim([0 0.7]);
                ylim([0 0.7]);
                xlabel('CIE u-prime','fontsize',13);
                ylabel('CIE v-prime','fontsize',13);
                title(sprintf('Test Image %d (AI = %.2f) \n Image = (%s)',tt,AI(tt),testImageNames{tt}));

                % Adding legend once per each primary.
                if tt == nTestImages
                    legend('raw','matched','Mean(raw)','Mean(stripes)','Mean(matched)',...
                        'Display','Target Primary','Location','southeastoutside','fontsize',11);
                    % legend('raw','stripes','matched','Mean(raw)','Mean(stripes)','Mean(matched)',...
                    %     'Display','Target Primary','Location','southeast','fontsize',11);
                end

                % Show the progress.
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

        % Save out the AI results over different experimental mode.
        switch expMode
            case 'periphery'
                AI_periphery{ss} = AI_all;
            case 'fovea'
                AI_fovea{ss} = AI_all;
        end
    end
end

%% Save out something if you want.
SAVETHERESULTS = false;

if (SAVETHERESULTS)
end
