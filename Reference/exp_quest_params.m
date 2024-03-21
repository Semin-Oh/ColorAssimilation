%This sets up QUEST parameters. It'll ultimately output a single variable
%(Quest) that is a nested structure with organized according to the
%following;

%Quest...
%Position...
%Spatial Freqeuncy

%All quest parameters for the corrosponding combination of SF and Position
%will be contained within the single variable, Quest.

%% Organize Quest Names
try
    %Position Names
    PosNames = fliplr(epar.LocNames); %Needs to be flipped for some reason?

    %SF Names (Based off epar.AllSF, but tweaked to be cpd
    for aa = 1:numel(epar.ALLSF)

        if epar.ALLSF(aa) == 0.1
            SFNames{aa} = 'SF01';
        elseif epar.ALLSF(aa) == 0.3
            SFNames{aa} = 'SF03';
        elseif epar.ALLSF(aa) == 0.5
            SFNames{aa} = 'SF05';
        elseif epar.ALLSF(aa) == 1
            SFNames{aa} = 'SF1';
        elseif epar.ALLSF(aa) == 3
            SFNames{aa} = 'SF3';
        elseif epar.ALLSF(aa) == 5
            SFNames{aa} = 'SF5';
        elseif epar.ALLSF(aa) == 10
            SFNames{aa} = 'SF10';
        end

    end

    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%% Set Priors %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % load(sprintf('data/e%dv%d_Priors/data.mat',epar.experiment,epar.subject),'Prior'); %Load priors acquired by method-of-adjustment (These are old and what were used during the pilot. Now just use the pilot results as these priors
  
    %Load priors from Pilot results
    load(sprintf('/home/gegenfurtner/Desktop/FRL/Wide-Field-CSF/data/QUESTPriors/E%d_Prior.mat',epar.experiment) );

    %Universal Components (These can be changed to individual if needed, but
    %they shouldn't need to be, see if priors are close enough)
    pThreshold = 0.75; %Threshold of response == 1, universal
    beta = 3; %Slope, universal
    delta = 0.01; %Lapse, universal
    gamma = 0.5; %Floor of responses (0.5 for 2AFC), unversal
    Grain = round(1/(2^epar.bitdepth),4); %Smallest step size for stimuli (based on 10-bit)
    RangeVal = 2;

    %Check to make sure there's enough priors given (in case more positions are
    %added later!)
    if numel(Prior.Const) ~= numel(PosNames) || numel(Prior.GuessSD) ~= numel(PosNames)
        error('Not enough priors given to QUEST, check QuestParams and update')
        sca
        close all
    end

    %% Build Quest Variables (1 structure per position, 1 field per SF)
    for aa = 1:numel(PosNames) %Loop through positions
        for bb = 1:numel(SFNames) %Loop through SF
            eval( sprintf( 'Quest.%s.%s = QuestCreate(Prior.Const{aa}(bb),Prior.GuessSD{aa}(bb),pThreshold,beta,delta,gamma,Grain,RangeVal,0);',PosNames{aa},SFNames{bb} ) );
        end
    end
catch %in case error, exist screen
    sca
    close all
    rethrow(lasterror)
end
