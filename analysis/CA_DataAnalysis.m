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
%    11/12/24    smo    - Big updates to plot the results.

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
        baseFiledir = '/Users/semin/Dropbox (Personal)/JLU/2) Projects';
        % Lab Linux computer.
    case 'gegenfurtner'
        baseFiledir = '/home/gegenfurtner/Dropbox/JLU/2) Projects';
    otherwise
        % Semin's laptop.
        baseFiledir = 'C:\Users\ohsem\Dropbox (Personal)\JLU\2) Projects';
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
exclSubjectNames = {'Laysa','Elef','Jacob','Jette'};
targetSubjectsNames = subjectNames(~ismember(subjectNames,exclSubjectNames));
% targetSubjectsNames = {'Semin'};
nSubjects = length(targetSubjectsNames);

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
    subjectName = targetSubjectsNames{ss};
    fprintf('Data loading - Subject = (%s) / Number of subjects (%d/%d) \n',subjectName,ss,nSubjects);

    % Loop for both experimental mode periphery and foveal.
    for ee = 1:nExpModes
        % Set experimental mode.
        expMode = expModeOptions{ee};

        % Make a plot to fit all results per experimental mode.
        figure; hold on;
        figurePosition = [0 0 1200 500];
        set(gcf,'Position',figurePosition);
        sgtitle(sprintf('Subject = (%s) / Experiment mode = (%s)',subjectName,expMode));
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
                % a = norm(uv_displayPrimary(1:2,idxWhichPrimary)-mean_uvY_testImageRaw(1:2));

                % The 'AI' value should be zero if there is no color assimiliation effect.
                AI(tt) = m/a;

                % Here, we calculate the assimilation index (AI) in a
                % couple different ways.
                %
                % AI in XYZ space. This is the original way to calculate
                % the AI value. We will simply convert the mean uvY values
                % into XYZ values to calculate.
                mean_XYZ_testImageRaw = uvYToXYZ(mean_uvY_testImageRaw);
                mean_XYZ_testImageStripe = uvYToXYZ(mean_uvY_testImageStripe);
                mean_XYZ_colorCorrectImage = uvYToXYZ(mean_uvY_colorCorrectImage);
                XYZ_displayPrimary = xyYToXYZ(xyY_displayPrimary);

                m = norm(mean_XYZ_colorCorrectImage-mean_XYZ_testImageRaw);
                a = norm(mean_XYZ_testImageStripe-mean_XYZ_testImageRaw);
                % a = norm(XYZ_displayPrimary(:,idxWhichPrimary)-mean_XYZ_testImageRaw);

                AI_XYZ(tt) = m/a;

                % AI in CIELAB.
                whitePoint = sum(XYZ_displayPrimary,2);
                mean_Lab_testImageRaw = XYZToLab(uvYToXYZ(mean_uvY_testImageRaw),whitePoint);
                mean_Lab_testImageStripe = XYZToLab(uvYToXYZ(mean_uvY_testImageStripe),whitePoint);
                mean_Lab_colorCorrectImage = XYZToLab(uvYToXYZ(mean_uvY_colorCorrectImage),whitePoint);
                Lab_displayPrimary = XYZToLab(XYZ_displayPrimary,whitePoint);

                m = norm(mean_Lab_colorCorrectImage-mean_Lab_testImageRaw);
                a = norm(mean_Lab_testImageStripe-mean_Lab_testImageRaw);
                % a = norm(Lab_displayPrimary(:,idxWhichPrimary)-mean_Lab_testImageRaw);

                AI_Lab(tt) = m/a;

                %% Plot the results.
                subplot(nPrimaries,nTestImages,tt + nTestImages*(pp-1)); hold on;

                % Plot the image profiles.
                plot(uvY_testImageRaw(1,:),uvY_testImageRaw(2,:),'.','MarkerEdgeColor',[0.5 0.5 0.5]);
                % plot(uvY_testImageStripe(1,:),uvY_testImageStripe(2,:),'k.','MarkerEdgeColor',[1 1 0]);
                plot(uvY_colorCorrectImage(1,:),uvY_colorCorrectImage(2,:),'.','MarkerEdgeColor',markerFaceColor);

                % Plot the mean chromaticity.
                f_meanRaw = plot(mean_uvY_testImageRaw(1),mean_uvY_testImageRaw(2),'o','MarkerFaceColor',[0.2 0.2 0.2],'markeredgecolor','k');
                f_meanStripes = plot(mean_uvY_testImageStripe(1),mean_uvY_testImageStripe(2),'o','MarkerFaceColor',[1 1 0],'markeredgecolor','k');
                f_meanColorCorrect = plot(mean_uvY_colorCorrectImage(1),mean_uvY_colorCorrectImage(2),'o','MarkerFaceColor',markerFaceColor,'markeredgecolor','k');

                % Plot the display gamut with the target primary highlighted.
                plot([uv_displayPrimary(1,:) uv_displayPrimary(1,1)], [uv_displayPrimary(2,:) uv_displayPrimary(2,1)],'k-');
                f_targetPrimary = plot(uv_displayTargetPrimary(1),uv_displayTargetPrimary(2),'^','markerfacecolor',markerFaceColor,'markeredgecolor','k','MarkerSize',8);

                % Plot the Plackian locus.
                load T_xyzJuddVos
                T_XYZ = T_xyzJuddVos;
                T_xy = [T_XYZ(1,:)./sum(T_XYZ); T_XYZ(2,:)./sum(T_XYZ)];
                T_uv = xyTouv(T_xy);
                plot([T_uv(1,1:65) T_uv(1,1)], [T_uv(2,1:65) T_uv(2,1)], 'k-');

                % Figure stuff.
                xlim([0 0.7]);
                ylim([0 0.7]);
                xlabel('CIE u-prime','fontsize',13);
                ylabel('CIE v-prime','fontsize',13);
                title(sprintf('Test Image %d (AI = %.2f) \n Image = (%s)',tt,AI(tt),testImageNames{tt}));

                % Adding legend once per each primary.
                if tt == nTestImages
                    legend([f_meanRaw f_meanStripes f_meanColorCorrect f_targetPrimary],...
                        'Mean(raw)','Mean(stripes)','Mean(matched)','Stripe',...
                        'Location','southeast','fontsize',11);
                    % legend('raw','matched','Mean(raw)','Mean(stripes)','Mean(matched)',...
                    %     'Display','Target Primary','Location','southeast','fontsize',11);
                    % legend('raw','stripes','matched','Mean(raw)','Mean(stripes)','Mean(matched)',...
                    %     'Display','Target Primary','Location','southeast','fontsize',11);
                end
            end

            % Display the progress.
            fprintf('Progress - Primary (%d/%d) \n',pp,nPrimaries);

            % Save out the assmiliation index (AI) results.
            switch pp
                case 1
                    AI_all.red = AI;
                    AI_XYZ_all.red = AI_XYZ;
                    c_raw_all.red = matchingIntensityColorCorrect_sorted;
                    c_all.red = meanMatchingIntensityColorCorrect;
                    AI_Lab_all.red = AI_Lab;
                case 2
                    AI_all.green = AI;
                    AI_XYZ_all.green = AI_XYZ;
                    c_raw_all.green = matchingIntensityColorCorrect_sorted;
                    c_all.green = meanMatchingIntensityColorCorrect;
                    AI_Lab_all.green = AI_Lab;
                case 3
                    AI_all.blue = AI;
                    AI_XYZ_all.blue = AI_XYZ;
                    c_raw_all.blue = matchingIntensityColorCorrect_sorted;
                    c_all.blue = meanMatchingIntensityColorCorrect;
                    AI_Lab_all.blue = AI_Lab;
            end

            % Save out the raw exp data.
        end

        % Save out the AI results over different experimental mode.
        switch expMode
            case 'periphery'
                AI_periphery{ss} = AI_all;
                AI_XYZ_periphery{ss} = AI_XYZ_all;
                c_raw_periphery{ss} = c_raw_all;
                c_periphery{ss} = c_all;
                AI_Lab_periphery{ss} = AI_Lab_all;
            case 'fovea'
                AI_fovea{ss} = AI_all;
                AI_XYZ_fovea{ss} = AI_XYZ_all;
                c_raw_fovea{ss} = c_raw_all;
                c_fovea{ss} = c_all;
                AI_Lab_fovea{ss} = AI_Lab_all;
        end
    end
end

%% Plot some more results here.
%
% Color correction coefficient (c). This is the raw data from the
% experiment.
PLOTRAWDATAPERSUB = false;
xAxisImages = linspace(1,nTestImages,nTestImages);
if (PLOTRAWDATAPERSUB)
    for ss = 1:nSubjects
        subjectName = targetSubjectsNames{ss};

        figure; hold on;
        sgtitle(sprintf('Subject = (%s)',subjectName));

        % Red.
        subplot(nPrimaries,1,1); hold on;
        f_1 = plot(xAxisImages,c_raw_periphery{ss}.red','k.');
        f_2 = plot(xAxisImages,c_raw_fovea{ss}.red','k*');
        f_3 = plot(xAxisImages,mean(c_raw_periphery{ss}.red,2)','o','markerfacecolor','r','markeredgecolor','k');
        f_4 = plot(xAxisImages,mean(c_raw_fovea{ss}.red,2)','^','markerfacecolor','r','markeredgecolor','k');
        ylim([0 0.6]);
        xlabel('Test Images','FontSize',13);
        xticks(xAxisImages);
        xticklabels(testImageNames);
        ylabel('Coefficient c','FontSize',13);
        legend([f_1(1) f_2(1) f_3 f_4], 'Raw (peripheral)','Raw (foveal)','Mean (peripheral)','Mean (foveal)','Location','southeastoutside');
        title('Primary = (Red)');

        % Green.
        subplot(nPrimaries,1,2); hold on;
        f_1 = plot(xAxisImages,c_raw_periphery{ss}.green','k.');
        f_2 = plot(xAxisImages,c_raw_fovea{ss}.green','k*');
        f_3 = plot(xAxisImages,mean(c_raw_periphery{ss}.green,2)','o','markerfacecolor','g','markeredgecolor','k');
        f_4 = plot(xAxisImages,mean(c_raw_fovea{ss}.green,2)','^','markerfacecolor','g','markeredgecolor','k');
        ylim([0 0.6]);
        xlabel('Test Images','FontSize',13);
        xticks(xAxisImages);
        xticklabels(testImageNames);
        ylabel('Coefficient c','FontSize',13);
        legend([f_1(1) f_2(1) f_3 f_4], 'Raw (peripheral)','Raw (foveal)','Mean (peripheral)','Mean (foveal)','Location','southeastoutside');
        title('Primary = (Green)');

        % Blue.
        subplot(nPrimaries,1,3); hold on;
        f_1 = plot(xAxisImages,c_raw_periphery{ss}.blue','k.');
        f_2 = plot(xAxisImages,c_raw_fovea{ss}.blue','k*');
        f_3 = plot(xAxisImages,mean(c_raw_periphery{ss}.blue,2)','o','markerfacecolor','b','markeredgecolor','k');
        f_4 = plot(xAxisImages,mean(c_raw_fovea{ss}.blue,2)','^','markerfacecolor','b','markeredgecolor','k');
        ylim([0 0.6]);
        xlabel('Test Images','FontSize',13);
        xticks(xAxisImages);
        xticklabels(testImageNames);
        ylabel('Coefficient c','FontSize',13);
        legend([f_1(1) f_2(1) f_3 f_4], 'Raw (peripheral)','Raw (foveal)','Mean (peripheral)','Mean (foveal)','Location','southeastoutside');
        title('Primary = (Blue)');
    end
end

%% Compare c vs AI values.
%
% Set the Y axis range.
numYaxisLimits = [0 1.8];

figure; hold on;
for ss = 1:nSubjects
    subplot(3,ceil(nSubjects/3),ss); hold on;
    plot(c_periphery{ss}.red, AI_periphery{ss}.red, 'r.');
    plot(c_periphery{ss}.green, AI_periphery{ss}.green, 'g.');
    plot(c_periphery{ss}.blue, AI_periphery{ss}.blue, 'b.');
    xlabel('Coefficient c');
    ylabel('Assimilation index (AI)');
    xlim([0 0.6]);
    ylim(numYaxisLimits);
    axis square;
    title(sprintf('Subject = (%s)',targetSubjectsNames{ss}));
end

%% Compare the AI values over using different color spaces.
%
% uv vs. XYZ.
figure; hold on;
for ss = 1:nSubjects
    % Fovea.
    plot(AI_fovea{ss}.red, AI_XYZ_fovea{ss}.red, 'r.','markersize',8);
    plot(AI_fovea{ss}.green, AI_XYZ_fovea{ss}.green, 'g.','markersize',8);
    plot(AI_fovea{ss}.blue, AI_XYZ_fovea{ss}.blue, 'b.','markersize',8);

    % Periphery.
    plot(AI_periphery{ss}.red, AI_XYZ_periphery{ss}.red, 'r.','markersize',8);
    plot(AI_periphery{ss}.green, AI_XYZ_periphery{ss}.green, 'g.','markersize',8);
    plot(AI_periphery{ss}.blue, AI_XYZ_periphery{ss}.blue, 'b.','markersize',8);
end
plot([0 10],[0 10],'k-');
xlim(numYaxisLimits);
ylim(numYaxisLimits);
xlabel('AI (uv)');
ylabel('AI (XYZ)');
title('Mean AI value: uv vs XYZ');
axis square;

% uv vs. CIELAB.
figure; hold on;
for ss = 1:nSubjects
    % Fovea.
    plot(AI_fovea{ss}.red, AI_Lab_fovea{ss}.red, 'r.','markersize',8);
    plot(AI_fovea{ss}.green, AI_Lab_fovea{ss}.green, 'g.','markersize',8);
    plot(AI_fovea{ss}.blue, AI_Lab_fovea{ss}.blue, 'b.','markersize',8);

    % Periphery.
    plot(AI_periphery{ss}.red, AI_Lab_periphery{ss}.red, 'r.','markersize',8);
    plot(AI_periphery{ss}.green, AI_Lab_periphery{ss}.green, 'g.','markersize',8);
    plot(AI_periphery{ss}.blue, AI_Lab_periphery{ss}.blue, 'b.','markersize',8);
end
plot([0 10],[0 10],'k-');
xlim(numYaxisLimits);
ylim(numYaxisLimits);
xlabel('AI (uv)');
ylabel('AI (CIELAB)');
title('Mean AI value: uv vs CIELAB');
axis square;

%% Plot the AI results.
%
% Choose which AI values to use.
whichCalAI = 'uv';
switch whichCalAI
    case 'XYZ'
        AI_periphery_plot = AI_XYZ_periphery;
        AI_fovea_plot = AI_XYZ_fovea;
    case 'Lab'
        AI_periphery_plot = AI_Lab_periphery;
        AI_fovea_plot = AI_Lab_fovea;
    case 'uv'
        AI_periphery_plot = AI_periphery;
        AI_fovea_plot = AI_fovea;
end

% Rearrange the data array.
for ss = 1:nSubjects
    AI_periphery_all_red(ss,:) = AI_periphery_plot{ss}.red;
    AI_periphery_all_green(ss,:) = AI_periphery_plot{ss}.green;
    AI_periphery_all_blue(ss,:) = AI_periphery_plot{ss}.blue;

    AI_fovea_all_red(ss,:) = AI_fovea_plot{ss}.red;
    AI_fovea_all_green(ss,:) = AI_fovea_plot{ss}.green;
    AI_fovea_all_blue(ss,:) = AI_fovea_plot{ss}.blue;
end

% Calculate the mean AI.
mean_AI_periphery_red = mean(AI_periphery_all_red,1);
mean_AI_periphery_green = mean(AI_periphery_all_green,1);
mean_AI_periphery_blue = mean(AI_periphery_all_blue,1);

mean_AI_fovea_red = mean(AI_fovea_all_red,1);
mean_AI_fovea_green = mean(AI_fovea_all_green,1);
mean_AI_fovea_blue = mean(AI_fovea_all_blue,1);

% Calculate the standard error.
stdError_AI_periphery_red = std(AI_periphery_all_red)./sqrt(nSubjects);
stdError_AI_periphery_green = std(AI_periphery_all_green)./sqrt(nSubjects);
stdError_AI_periphery_blue = std(AI_periphery_all_blue)./sqrt(nSubjects);

stdError_AI_fovea_red = std(AI_fovea_all_red)./sqrt(nSubjects);
stdError_AI_fovea_green = std(AI_fovea_all_green)./sqrt(nSubjects);
stdError_AI_fovea_blue = std(AI_fovea_all_blue)./sqrt(nSubjects);

% Plot here.
figure; hold on;
sgtitle(sprintf('Mean AI results for all subjects (N=%d)',nSubjects));

% Set the Y axis range.
numYaxisLimits = [0.9 1.8];

% Red.
subplot(nPrimaries,1,1); hold on;
f_1=plot(xAxisImages,AI_periphery_all_red,'k.');
f_2=plot(xAxisImages,AI_fovea_all_red,'k*');
f_3=plot(xAxisImages,mean_AI_periphery_red,'o','markerfacecolor','r','markeredgecolor','k');
f_4=plot(xAxisImages,mean_AI_fovea_red,'^','markerfacecolor','r','markeredgecolor','k');
ylim(numYaxisLimits);
xlabel('Test Images','FontSize',13);
xticks(xAxisImages);
xticklabels(testImageNames);
ylabel('AI','FontSize',13);
legend([f_1(1) f_2(1) f_3 f_4], 'AI (peripheral)','AI (foveal)',...
    sprintf('Mean (peripheral), N=%d',nSubjects),sprintf('Mean (foveal), N=%d',nSubjects),...
    'Location','southeastoutside');
title('Primary = (Red)');

% Green.
subplot(nPrimaries,1,2); hold on;
f_1=plot(xAxisImages,AI_periphery_all_green,'k.');
f_2=plot(xAxisImages,AI_fovea_all_green,'k*');
f_3=plot(xAxisImages,mean_AI_periphery_green,'o','markerfacecolor','g','markeredgecolor','k');
f_4=plot(xAxisImages,mean_AI_fovea_green,'^','markerfacecolor','g','markeredgecolor','k');
ylim(numYaxisLimits);
xlabel('Test Images','FontSize',13);
xticks(xAxisImages);
xticklabels(testImageNames);
ylabel('AI','FontSize',13);
legend([f_1(1) f_2(1) f_3 f_4], 'AI (peripheral)','AI (foveal)',...
    sprintf('Mean (peripheral), N=%d',nSubjects),sprintf('Mean (foveal), N=%d',nSubjects),...
    'Location','southeastoutside');
title('Primary = (Green)');

% Blue.
subplot(nPrimaries,1,3); hold on;
f_1=plot(xAxisImages,AI_periphery_all_blue,'k.');
f_2=plot(xAxisImages,AI_fovea_all_blue,'k*');
f_3=plot(xAxisImages,mean_AI_periphery_blue,'o','markerfacecolor','b','markeredgecolor','k');
f_4=plot(xAxisImages,mean_AI_fovea_blue,'^','markerfacecolor','b','markeredgecolor','k');
ylim(numYaxisLimits);
xlabel('Test Images','FontSize',13);
xticks(xAxisImages);
xticklabels(testImageNames);
ylabel('AI','FontSize',13);
legend([f_1(1) f_2(1) f_3 f_4], 'AI (peripheral)','AI (foveal)',...
    sprintf('Mean (peripheral), N=%d',nSubjects),sprintf('Mean (foveal), N=%d',nSubjects),...
    'Location','southeastoutside');
title('Primary = (Blue)');

%% Plot averaged Pripheral vs. Foveal.
%
% Extract the mean AI results for the faces. We will highlight them in the
% figure.
idxFaceImages = ~(or(strcmp(testImageNames,'potato'),strcmp(testImageNames,'whiteegg')));

% Plot happens here.
figure; hold on;
title(sprintf('AI (%s): Peripheral vs. Foveal (N=%d)',whichCalAI,nSubjects));
subtitle('Non-face image is marked with bigger circle');

% Add standard error bar.
errorbar(mean_AI_periphery_red,mean_AI_fovea_red,...
    stdError_AI_fovea_red,stdError_AI_fovea_red,...
    stdError_AI_periphery_red,stdError_AI_periphery_red,...
    'LineStyle','none','Color','r');

errorbar(mean_AI_periphery_green,mean_AI_fovea_green,...
    stdError_AI_fovea_green,stdError_AI_fovea_green,...
    stdError_AI_periphery_green,stdError_AI_periphery_green,...
    'LineStyle','none','Color','g');

errorbar(mean_AI_periphery_blue,mean_AI_fovea_blue,...
    stdError_AI_fovea_blue,stdError_AI_fovea_blue,...
    stdError_AI_periphery_blue,stdError_AI_periphery_blue,...
    'LineStyle','none','Color','b');

% Mean AI results (ALL).
f_1=plot(mean_AI_periphery_red,mean_AI_fovea_red,'o','markerfacecolor','r','markeredgecolor','k','MarkerSize',5);
f_2=plot(mean_AI_periphery_green,mean_AI_fovea_green,'o','markerfacecolor','g','markeredgecolor','k','MarkerSize',5);
f_3=plot(mean_AI_periphery_blue,mean_AI_fovea_blue,'o','markerfacecolor','b','markeredgecolor','k','MarkerSize',5);

% Mean AI results (FACES).
% f_4=plot(mean_AI_periphery_red(idxFaceImages),mean_AI_fovea_red(idxFaceImages),'ro','MarkerSize',8);
% f_5=plot(mean_AI_periphery_green(idxFaceImages),mean_AI_fovea_green(idxFaceImages),'go','MarkerSize',8);
% f_6=plot(mean_AI_periphery_blue(idxFaceImages),mean_AI_fovea_blue(idxFaceImages),'bo','MarkerSize',8);

% Mean AI (NON-FACES).
f_4=plot(mean_AI_periphery_red(~idxFaceImages),mean_AI_fovea_red(~idxFaceImages),'ro','MarkerSize',9,'linewidth',1);
f_5=plot(mean_AI_periphery_green(~idxFaceImages),mean_AI_fovea_green(~idxFaceImages),'go','MarkerSize',9);
f_6=plot(mean_AI_periphery_blue(~idxFaceImages),mean_AI_fovea_blue(~idxFaceImages),'bo','MarkerSize',9);

% 45-deg line.
f_7=plot([0 10],[0 10],'k-');

% Figure stuff.
xlabel('AI (Peripheral)','fontsize',13);
ylabel('AI (Foveal)','fontsize',13);
xlim(numYaxisLimits);
ylim(numYaxisLimits);
xticks([numYaxisLimits(1):0.1:numYaxisLimits(2)]);
yticks([numYaxisLimits(1):0.1:numYaxisLimits(2)]);
legend([f_1 f_2 f_3],sprintf('Red (N=%d)',nSubjects),sprintf('Green (N=%d)',nSubjects),...
    sprintf('Blue (N=%d)',nSubjects),'location','southeast');
grid on;
axis square;

%% Plot individual AI comparison peripheral vs. foveal.
%
figure; hold on;
title('Individual AI: Peripheral vs. Foveal');

for ss = 1:nSubjects
    subplot(4,ceil(nSubjects/4),ss); hold on;

    % All test images.
    f_1=plot(AI_periphery_all_red(ss,:), AI_fovea_all_red(ss,:),'o','markerfacecolor','r','markeredgecolor','k','MarkerSize',4);
    f_2=plot(AI_periphery_all_green(ss,:), AI_fovea_all_green(ss,:),'o','markerfacecolor','g','markeredgecolor','k','MarkerSize',4);
    f_3=plot(AI_periphery_all_blue(ss,:), AI_fovea_all_blue(ss,:),'o','markerfacecolor','b','markeredgecolor','k','MarkerSize',4);

    % Face images.
    plot(AI_periphery_all_red(ss,idxFaceImages), AI_fovea_all_red(ss,idxFaceImages),'ro','MarkerSize',8);
    plot(AI_periphery_all_green(ss,idxFaceImages), AI_fovea_all_green(ss,idxFaceImages),'go','MarkerSize',8);
    plot(AI_periphery_all_blue(ss,idxFaceImages), AI_fovea_all_blue(ss,idxFaceImages),'bo','MarkerSize',8);

    % 45-deg line.
    f_7=plot([0 10],[0 10],'k-');

    % Calculate correlation here.
    %
    % Periphery.
    oneSubject_AI_periphery_RGB = [AI_periphery_all_red(ss,:)';AI_periphery_all_green(ss,:)';AI_periphery_all_blue(ss,:)'];
    mean_AI_periphery_RGB = [mean_AI_periphery_red';mean_AI_periphery_green';mean_AI_periphery_blue'];
    
    % Fovea.
    oneSubject_AI_fovea_RGB = [AI_fovea_all_red(ss,:)';AI_fovea_all_green(ss,:)';AI_fovea_all_blue(ss,:)'];
    mean_AI_fovea_RGB = [mean_AI_fovea_red';mean_AI_fovea_green';mean_AI_fovea_blue'];
    
    % Correlation coefficient.
    r = corr([oneSubject_AI_periphery_RGB; oneSubject_AI_fovea_RGB], [mean_AI_periphery_RGB; mean_AI_fovea_RGB]);

    % Figure stuff.
    title(sprintf('Subject = (%s) / r = (%.2f)',targetSubjectsNames{ss},r));
    xlabel('AI (Peripheral)','fontsize',13);
    ylabel('AI (Foveal)','fontsize',13);
    xlim(numYaxisLimits);
    ylim(numYaxisLimits);
    xticks([numYaxisLimits(1):0.1:numYaxisLimits(2)]);
    yticks([numYaxisLimits(1):0.1:numYaxisLimits(2)]);
    legend([f_1 f_2 f_3],'red','green','blue','location','southeast');
    grid on;
    axis square;
end
