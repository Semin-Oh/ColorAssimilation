%This sets up QUEST parameters. It'll ultimately output a single variable
%(Quest) that is a nested structure with organized according to the
%following;

%Quest...
%Position...
%Spatial Freqeuncy

%All quest parameters for the corrosponding combination of SF and Position
%will be contained within the single variable, Quest.
%% Organize FastCSF Names
try
    %Position Names
    %     epar.LocNames = fliplr({'Deg0','Deg15','Deg45','Deg60','Deg75','Deg90'}); %Edit these by hand for naming purposes
    PosNames = epar.LocNames; %Flip it to go from small to larger eccentricity
    PosNames = fliplr(PosNames);

    cd('/home/gegenfurtner/Desktop/FRL/Wide-Field-CSF/');

    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%% Set Priors %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        load('data/FastCSFPriors/FastCSFPriors.mat'); MEANSTUFF = 0; %Load priors acquired by N=3 QUEST Tests
%     load('./data/FastCSFPriors/FastCSFPriors_MEAN.mat'); MEANSTUFF = 1; %Load mean priors across experiments acquired by N=3 QUEST Tests
    epar.FastCSFParams.Range = 0.5; %The +/- around the mean to use
    Range = epar.FastCSFParams.Range; %The +/- around the mean to use 

    %Save Get Priors for current experiment
    if epar.experiment == 1
        ExpName = 'Ach';
    elseif epar.experiment == 2
        ExpName = 'RG';
    elseif epar.experiment == 3
        ExpName = 'YV';
    end

    %Place these parameters into epar struct
    if MEANSTUFF == 0 %Use actual priors
        eval(sprintf('epar.FastCSFParams.PS = PS_%s;',ExpName));
        eval(sprintf('epar.FastCSFParams.PF = PF_%s;',ExpName));
        eval(sprintf('epar.FastCSFParams.BW = BW_%s;',ExpName));
        eval(sprintf('epar.FastCSFParams.SG = SG_%s;',ExpName));
        eval(sprintf('epar.FastCSFParams.LG = LG_%s;',ExpName));
    else %Priors are means across the three experiments (for stress-testing FastCSF)
        epar.FastCSFParams.PS = PS_Mean;
        epar.FastCSFParams.PF = PF_Mean;
        epar.FastCSFParams.BW = BW_Mean;
        epar.FastCSFParams.SG = SG_Mean;
        epar.FastCSFParams.LG = LG_Mean;
    end

    %Save simplified variables + ranges for FastFull %NRB Note: CHANGED THE RANGE TO BE +/- 100% INSTEAD OF 50, TO ALLOW IT TO VARY MORE
    PS = 1./10.^epar.FastCSFParams.PS; %Convert sens -> contrast
    PS = log10( [PS-(PS*Range) , PS+(PS*Range)] ); % This as the second variable sets highest contrast to 1 (0 sens): repmat(1,length(PS),1)] 
    PF = epar.FastCSFParams.PF; %These are not log!
    PF = log10([(PF-(PF*Range)) , (PF+(PF*Range))]);
    BW = 1./epar.FastCSFParams.BW; %This needs to be inverse bandwidth
    BW = log10([(BW-(BW*Range)) , (BW+(BW*Range))]);
    SG = epar.FastCSFParams.SG;
    SG = log10([(SG-(SG*Range)) , (SG+(SG*Range))]);
    LG = 1./(10.^epar.FastCSFParams.LG);
    LG = log10([(LG-(LG*Range)) , (LG+(LG*Range))]);
    Scaling = -1; %defining type of data for FastFull

%Try changing to +/- 1 log unit and redo the data! %NRB note: This seemed
%really bad, the contrast was WAY too high all the time.
%     PS = log10(1./10.^epar.FastCSFParams.PS); %Convert sens -> contrast
%     PS = [PS-1 , PS+1]; % 
%     PF = log10(epar.FastCSFParams.PF); 
%     PF = [PF-1 , PF+1]; % 
%     BW = log10(1./epar.FastCSFParams.BW); %This needs to be inverse bandwidth
%     BW = [BW-1 , BW+1]; % 
%     SG = log10(epar.FastCSFParams.SG);
%     SG = [SG-1 , SG+1]; % 
%     LG = log10(1./(10.^epar.FastCSFParams.LG));
%     LG = [LG-1 , LG+1]; % 
%     Scaling = -1; %defining type of data for FastFull

    if ~isempty(find(SG<0)) %Slope can't be less than 0 (only appears in far periphery for YV)
        SG(find(SG<0)) = 0.01;
    end

    for aa = 1:length(PosNames)

        %FastCSF Parameters (Note that first input of cell '-1' indicates linear
        %scale with upper and lower bounds, '1' indicates logarithmic with +- SD)
        PeakSens = [Scaling PS(aa,:)];
        PeakFreq = [Scaling PF(aa,:)];
        BandwidthGuess = [Scaling BW(aa,:)];
        Slopeguess = [Scaling SG(aa,:)];
        YCrit = [Scaling 0.75 0.75]; % 75% critical threshold value
        Ledge_Guess = [Scaling LG(aa,:)]; %Don't attenaute at low SF (basically turn this off, but keep Guido's other edits(?) in there. (Note that this is also ignored in the funCSF_Ledge function)


        %Should this be detection or 2AFC
        eval(sprintf('FStruct.%s = fastFull(2,''funcCSF_Ledge'',''psyNormal'',{PeakSens,PeakFreq,BandwidthGuess,Ledge_Guess,YCrit,Slopeguess});',PosNames{aa}));
    end



catch
    error('Cannot establish FastCSF Struct. Check exp_fastcsf_params.m')
end
