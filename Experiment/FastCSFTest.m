clear all; close all; clc;
load('./FastCSFTest_12-6-23.mat');

%% Establish Struct

   %     epar.LocNames = fliplr({'Deg0','Deg15','Deg45','Deg60','Deg75','Deg90'}); %Edit these by hand for naming purposes
    PosNames = epar.LocNames; %Flip it to go from small to larger eccentricity
    PosNames = fliplr(PosNames);

    load('data/FastCSFPriors/FastCSFPriors.mat'); %Load priors acquired by N=3 QUEST Tests
    epar.FastCSFParams.Range = 0.5; %The +/- around the mean to use (50%)
    Range = epar.FastCSFParams.Range; %The +/- around the mean to use (50%)

    %Save Get Priors for current experiment
    if epar.experiment == 1
        ExpName = 'Ach';
    elseif epar.experiment == 2
        ExpName = 'RG';
    elseif epar.experiment == 3
        ExpName = 'YV';
    end

    %Place these parameters into epar struct
    eval(sprintf('epar.FastSFParams.PS = PS_%s;',ExpName));
    eval(sprintf('epar.FastSFParams.PF = PF_%s;',ExpName));
    eval(sprintf('epar.FastSFParams.BW = BW_%s;',ExpName));
    eval(sprintf('epar.FastSFParams.SG = SG_%s;',ExpName));

%     %Save simplified variables + ranges for FastFull (Min <-> Max)
    PS = 1./epar.FastSFParams.PS;
    PS = log10([(PS-(PS*Range)) , (PS+(PS*Range))]); %Convert sens -> contrast
    PF = epar.FastSFParams.PF;
    PF = log10([(PF-(PF*Range)) , (PF+(PF*Range))]);
    BW = epar.FastSFParams.BW;
    BW = log10([(BW-(BW*Range)) , (BW+(BW*Range))]);
    SG = epar.FastSFParams.SG;
    SG = log10([(SG-(SG*Range)) , (SG+(SG*Range))]);
    Scaling = -1; %defining type of data for FastFull  

        %Save simplified variables + ranges for FastFull (Mean +/- SD)
%     PS = 1./epar.FastSFParams.PS;
%     PS = log10([PS , (PS*Range)]); %Convert sens -> contrast
%     PF = epar.FastSFParams.PF;
%     PF = log10([PF , (PF*Range)]);
%     BW = epar.FastSFParams.BW;
%     BW = log10([BW , (BW*Range)]);
%     SG = epar.FastSFParams.SG;
%     SG = [SG , (SG*Range)];
% % SG = repmat([2, 0.5],[6,1]);
%     Scaling = -1; %defining type of data for FastFull  


    for aa = 1:length(PosNames)

        %FastCSF Parameters (Note that first input of cell '-1' indicates linear
        %scale with upper and lower bounds, '1' indicates logarithmic with +- SD)
        PeakSens = [Scaling PS(aa,:)];
        PeakFreq = [Scaling PF(aa,:)];
        BandwidthGuess = [Scaling BW(aa,:)];
        Slopeguess = [Scaling SG(aa,:)];
        YCrit = [Scaling 0.75 0.75]; % 75% critical threshold value
        Ledge_Guess = [1 log10(0.001) log10(0.002)]; %Don't attenaute at low SF (basically turn this off, but keep Guido's other edits(?) in there
        
        eval(sprintf('FStruct.%s = fastFull(2,''funcCSF_Ledge'',''psyNormal'',{PeakSens,PeakFreq,BandwidthGuess,Ledge_Guess,YCrit,Slopeguess});',PosNames{aa}));

    end


    %% Test (get a first contrast estimate for each SF/Location
for t=1:epar.trial.num % Run through the trial loop


    %Set SF for this trial
    epar.ThisSF = epar.trial.sf(t);

    %Set location for this trial
    epar.ThisLoc = epar.trial.loc(t);


    AllLocNames = [epar.LocNames fliplr(epar.LocNames)];
    ThisLoc = AllLocNames{find(epar.ThisLoc==epar.AllLocPx)};

    eval(sprintf('ThisSens = fastChooseY(FStruct.%s , epar.ThisSF);',ThisLoc)); %Gives results as log10(Sens)
    ThisContrast = 1./(10^ThisSens); %Convert to contrast

    if strcmp(ThisLoc,'Deg0')

        if epar.ThisSF == 0.1
            CSF0(1) = ThisContrast;
        elseif epar.ThisSF == 0.3
            CSF0(2) = ThisContrast;
        elseif epar.ThisSF == 0.5
            CSF0(3) = ThisContrast;
        elseif epar.ThisSF == 1
            CSF0(4) = ThisContrast;
        elseif epar.ThisSF == 3
            CSF0(5) = ThisContrast;
        elseif epar.ThisSF == 5
            CSF0(6) = ThisContrast;
        elseif epar.ThisSF == 10
            CSF0(7) = ThisContrast;
        end

    elseif strcmp(ThisLoc,'Deg15')

        if epar.ThisSF == 0.1
            CSF15(1) = ThisContrast;
        elseif epar.ThisSF == 0.3
            CSF15(2) = ThisContrast;
        elseif epar.ThisSF == 0.5
            CSF15(3) = ThisContrast;
        elseif epar.ThisSF == 1
            CSF15(4) = ThisContrast;
        elseif epar.ThisSF == 3
            CSF15(5) = ThisContrast;
        elseif epar.ThisSF == 5
            CSF15(6) = ThisContrast;
        elseif epar.ThisSF == 10
            CSF15(7) = ThisContrast;
        end

    elseif strcmp(ThisLoc,'Deg45')

        if epar.ThisSF == 0.1
            CSF45(1) = ThisContrast;
        elseif epar.ThisSF == 0.3
            CSF45(2) = ThisContrast;
        elseif epar.ThisSF == 0.5
            CSF45(3) = ThisContrast;
        elseif epar.ThisSF == 1
            CSF45(4) = ThisContrast;
        elseif epar.ThisSF == 3
            CSF45(5) = ThisContrast;
        elseif epar.ThisSF == 5
            CSF45(6) = ThisContrast;
        elseif epar.ThisSF == 10
            CSF45(7) = ThisContrast;
        end

    elseif strcmp(ThisLoc,'Deg60')

        if epar.ThisSF == 0.1
            CSF60(1) = ThisContrast;
        elseif epar.ThisSF == 0.3
            CSF60(2) = ThisContrast;
        elseif epar.ThisSF == 0.5
            CSF60(3) = ThisContrast;
        elseif epar.ThisSF == 1
            CSF60(4) = ThisContrast;
        elseif epar.ThisSF == 3
            CSF60(5) = ThisContrast;
        elseif epar.ThisSF == 5
            CSF60(6) = ThisContrast;
        elseif epar.ThisSF == 10
            CSF60(7) = ThisContrast;
        end

    elseif strcmp(ThisLoc,'Deg75')

        if epar.ThisSF == 0.1
            CSF75(1) = ThisContrast;
        elseif epar.ThisSF == 0.3
            CSF75(2) = ThisContrast;
        elseif epar.ThisSF == 0.5
            CSF75(3) = ThisContrast;
        elseif epar.ThisSF == 1
            CSF75(4) = ThisContrast;
        elseif epar.ThisSF == 3
            CSF75(5) = ThisContrast;
        elseif epar.ThisSF == 5
            CSF75(6) = ThisContrast;
        elseif epar.ThisSF == 10
            CSF75(7) = ThisContrast;
        end

    elseif strcmp(ThisLoc,'Deg90')

        if epar.ThisSF == 0.1
            CSF90(1) = ThisContrast;
        elseif epar.ThisSF == 0.3
            CSF90(2) = ThisContrast;
        elseif epar.ThisSF == 0.5
            CSF90(3) = ThisContrast;
        elseif epar.ThisSF == 1
            CSF90(4) = ThisContrast;
        elseif epar.ThisSF == 3
            CSF90(5) = ThisContrast;
        elseif epar.ThisSF == 5
            CSF90(6) = ThisContrast;
        elseif epar.ThisSF == 10
            CSF90(7) = ThisContrast;
        end

    end
end

%% Plot first estimates vs real data
load('./ThreshMat_FastCSFTest.mat');
ThreshMat = ThrematTmp; %Stupid typo here, but this is just the average across the subjects (nanmean(E1.AllThreshMat,3))

figure;
subplot(3,2,1) %Foveal
plot(SF,CSF0,'b','LineStyle','-','Marker','o');
hold on;
plot(SF,ThreshMat(:,1),'r','LineStyle','-','Marker','o');
title('Deg0');
legend('FastCSF','RealData','Location','Best');
xlim([0 10]);
xticks(SF)
xticklabels(QuestLevels);
xlabel('Spatial Frequency');
ylabel('Sensitivity (Cone Contrast)');

subplot(3,2,2) %15Deg
plot(SF,CSF15,'b','LineStyle','-','Marker','o');
hold on;
plot(SF,ThreshMat(:,2),'r','LineStyle','-','Marker','o');
title('Deg15');
xlim([0 10]);
xticks(SF)
xticklabels(QuestLevels);
xlabel('Spatial Frequency');
ylabel('Sensitivity (Cone Contrast)');

subplot(3,2,3) %45Deg
plot(SF,CSF45,'b','LineStyle','-','Marker','o');
hold on;
plot(SF,ThreshMat(:,3),'r','LineStyle','-','Marker','o');
title('Deg45');
xlim([0 10]);
xticks(SF)
xticklabels(QuestLevels);
xlabel('Spatial Frequency');
ylabel('Sensitivity (Cone Contrast)');

subplot(3,2,4) %60Deg
plot(SF,CSF60,'b','LineStyle','-','Marker','o');
hold on;
plot(SF,ThreshMat(:,4),'r','LineStyle','-','Marker','o');
title('Deg60');
xlim([0 10]);
xticks(SF)
xticklabels(QuestLevels);
xlabel('Spatial Frequency');
ylabel('Sensitivity (Cone Contrast)');

subplot(3,2,5) %75Deg
plot(SF,CSF75,'b','LineStyle','-','Marker','o');
hold on;
plot(SF,ThreshMat(:,5),'r','LineStyle','-','Marker','o');
title('Deg75');
xlim([0 10]);
xticks(SF)
xticklabels(QuestLevels);
xlabel('Spatial Frequency');
ylabel('Sensitivity (Cone Contrast)');

subplot(3,2,6) %90Deg
plot(SF,CSF90,'b','LineStyle','-','Marker','o');
hold on;
plot(SF,ThreshMat(:,6),'r','LineStyle','-','Marker','o');
title('Deg90');
xlim([0 10]);
xticks(SF)
xticklabels(QuestLevels);
xlabel('Spatial Frequency');
ylabel('Sensitivity (Cone Contrast)');

set(gcf,'units','normalized','outerposition',[0 0 0.33 1])

%KEEP IN MIND THAT THINGS ARE CONVERTED TO CONE CONTRAST AND FOR DISPLAYING
%THE STIMULI WE NEED 10-BIT VALUES!! DOESN'T MATTER FOR Ach BUT FOR RG AND
%YV IT WILL DRAMATICALLY CHANGE THINGS
