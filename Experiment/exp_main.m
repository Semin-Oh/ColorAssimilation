% exp_main
%
% This is a main experiment running code for color assimilation. This
% routine is based on the previous routine for measuing contrast
% sensitivity at peripheral vision done by Noric. The very first version of
% this routine is from Alex.
%
% See also:
%    exp_main.m
% 
% History:
%    03/21/24  smo  - Started on it.

%% Initialize.
clear all; close all; clc;

try
    %%% Experiment to measure CSF in the far periphery. This experiment can use
    %%% either QUEST or the FastCSF method to measure contrast sensitivity.
    %%% This experiment can also run with fixed-cycle or fixed-siye gabors
    %%% (currently fixed-size is chosen). First, this experiment uses
    %%% method-of-adjustment to obtain priors for either CSF method (QUEST or
    %%% FastCSF) before running that method. The toggles can be found below at
    %%% line 22. When the experiment begins the experimenter inputs the
    %%% experiment (1: achromatic, 2: red-green, 3: blue-yellow), subject#, and
    %%% block#) so it can create the correct folder QUEST and FastCSF will
    %%% iterate automatically based on the inputs from the previous folders.
    cd('./');
    addpath(genpath('./'));
    %     addpath('_lib');
    %     addpath('edf-converter-master');
    %     addpath('Dkl2RGBconversion');
    %     addpath(genpath('/home/gegenfurtner/Desktop/FRL/Wide-Field-CSF/FastCSF_Functions'));
    warning off

    %Toggles to change what's running (only one of these should be on!)
    QUEST = 1; %CSF estimation using QUEST
    PRIOR = 0; %Prior estimator using method-of-adjustment (For us with QUEST)
    FASTCSF = 0; %Fast CSF

    % Set eyelink
    epar.EL = 1;    %1: Eyelink active; 0: No eyelink
    
    % Set gabor size. : Fixed size, 1 = Fixed cycle
    GaborType = 0; 

    %% INIT EXPERIMENT
    rng('Shuffle'); %NRB: no need for a fancy rng seed. Just do local time.
    epar.experiment=input('Experiment:');
    epar.subject=input('Subject:');
    epar.block=input('Block:');
    epar.GaborType = GaborType; %Toggle fixed cycle gabor (1) or fixed size gabor (0) NRB Added

    %Check compatibility
    if QUEST && PRIOR || FASTCSF && PRIOR
        error('Cannot estimate CSF and Priors simultaneouly, check toggles');
    end
    cd('/home/gegenfurtner/Desktop/FRL/Wide-Field-CSF');

    %% Settings
    exp_settings; % --> EyeTracker & Monitor Calibration

    %% Define Paths
    epar.exp_path = sprintf('%se%dv%db%d', epar.save_path, epar.experiment, epar.subject, epar.block');
    if exist(epar.exp_path)==7  &&  numel(dir([epar.exp_path]))>2  &&  (QUEST || FASTCSF) %If already directory exists, is not empty, and experiment trials are on (AKA this blocks already been done)...
        error('Directory already exists! Please check experiment, subject and block number!') % ...throw error...
    elseif QUEST || FASTCSF % ...otherwise, if experiment trials are on ...
        mkdir ([epar.exp_path]); % ...make the directory (just overwrite it if it already exists but IS empty) ...
    elseif PRIOR % ...unless you're measuring priors ...
        epar.exp_path = sprintf('%s/e%dv%d_Priors', epar.save_path, epar.experiment, epar.subject);
        mkdir ([epar.exp_path]); % ...in which case make a directory for the priors.
    end
    epar.log_file=sprintf('%s/e%dv%db%d.log', epar.exp_path, epar.experiment, epar.subject, epar.block);

    %% INIT DISPLAY
    epar = exp_mon_init(epar);

    %% Init Experiment --> Trial Structure & Conditions
    exp_settings_1

    %% Show Instruction
    % exp_instruction(epar,epar.experiment)

    %% INIT EYELINK
    if epar.EL
        el = exp_el_init(epar);
    else
        el = NaN;
    end

    %% CALIBRATE EYELINK
    if epar.EL
        result=EyelinkDoTrackerSetup(el);
        if result==el.TERMINATE_KEY
            return;
        end
        Eyelink('message', 'Block_Start');
        Eyelink('WaitForModeReady', 500);
    end

    %% Initialize FAST CSF / QUEST (Create Toggle)
    if epar.block == 1 && QUEST  %If first block
        % if exist(sprintf('%s/e%dv%d_Priors', epar.save_path,
        % epar.experiment, epar.subject)) == 7 %If prior folder exists (Commneted, only applicable during pilot)
        exp_quest_params %Create QUEST params (1 per position, per SF)
        % else
        %     error('Must estimate priors before beginning experiment');
        %     close all
        %     sca
        % end

    elseif epar.block ~= 1 && QUEST %If previous blocks have been run, load previous Quest Priors
        load( sprintf('./data/e%dv%db%d/data.mat',epar.experiment,epar.subject,(epar.block-1)),'Quest')

    elseif epar.block == 1 && FASTCSF
        exp_fastcsf_params;

    elseif epar.block ~= 1 && FASTCSF %If previous blocks have been run, load previous FStruct
        load( sprintf('./data/e%dv%db%d/data.mat',epar.experiment,epar.subject,(epar.block-1)),'FStruct')
    end

    %Cone Contrast Adjustments (Just for FastCSF)
    load('/home/gegenfurtner/Desktop/FRL/Wide-Field-CSF/Analysis Scripts/Fits-and-Models/ConeContrast/ConeContrastTransfer.mat'); %This is organized Experiment RG-YV-Ach, don't mix it up
    epar.SlopeColor = Slope_Color; %Remember: (RG,YV,Ach)!

    %% EXP
    Grain = round(1/(2^epar.bitdepth),3); %Smallest step in contrast possible
    epar.Grain = Grain;

    %Simulate FastCSF trials that we know are invisible
    if epar.experiment == 1
        Consttmp = 1*epar.SlopeColor(3);
    elseif epar.experiment == 2
        Consttmp = 1*epar.SlopeColor(1);
    elseif epar.experiment == 3
        Consttmp = 1*epar.SlopeColor(2);
    end

    if FASTCSF
        AllLocNames = [epar.LocNames fliplr(epar.LocNames)];
        for aa = 1:length(epar.trial.sim.sf)
            Resptmp = randi([0 1]); %Random correct/incorrect

            ThisLoc = AllLocNames{find(epar.trial.sim.loc(aa)==epar.AllLocPx)};
            eval( sprintf( 'FStruct.%s = fastUpdate(FStruct.%s, [epar.trial.sim.sf(aa), Consttmp, Resptmp]);',ThisLoc,ThisLoc));
        end
    end

    t = 0; %loop var
    while t < epar.trial.num % Run through the trial loop

        t = t+1; %iterate

        % Initialize the trial
        TimeOn = tic; %record length of trials

        %Set SF for this trial
        epar.ThisSF = epar.trial.sf(t);

        %Set location for this trial
        epar.ThisLoc = epar.trial.loc(t);

        if QUEST %Specify which QUEST to update (Have to do this by hand)

            if epar.ThisSF == 0.1
                ThisSF = 'SF01';
            elseif epar.ThisSF == 0.3
                ThisSF = 'SF03';
            elseif epar.ThisSF == 0.5
                ThisSF = 'SF05';
            elseif epar.ThisSF == 1
                ThisSF = 'SF1';
            elseif epar.ThisSF == 3
                ThisSF = 'SF3';
            elseif epar.ThisSF == 5
                ThisSF = 'SF5';
            elseif epar.ThisSF == 10
                ThisSF = 'SF10';
            end

            AllLocNames = [epar.LocNames fliplr(epar.LocNames)];
            ThisLoc = AllLocNames{find(epar.ThisLoc==epar.AllLocPx)};
            eval( sprintf('epar.ThisContrast = round(QuestQuantile(Quest.%s.%s),3);',ThisLoc,ThisSF) );

        elseif FASTCSF %Specify which FastCSF to update (Have to do this by hand)
            AllLocNames = [epar.LocNames fliplr(epar.LocNames)];
            ThisLoc = AllLocNames{find(epar.ThisLoc==epar.AllLocPx)};

            eval(sprintf('ThisContrast = fastChooseY(FStruct.%s , epar.ThisSF);',ThisLoc)); %Gives results as log10(Sens)
            epar.ThisContrast = 10^ThisContrast;

            %Just for FastCSF, change from cone contrasts to 8/10 bpc values! %Remember: Slope_Color(RG,YV,Ach)!
            if FASTCSF && epar.experiment == 1
                epar.ThisContrast = epar.ThisContrast/epar.SlopeColor(3); % Divide: Cone Contrast -> bpc Contrast
            elseif FASTCSF && epar.experiment == 2
                epar.ThisContrast= epar.ThisContrast/epar.SlopeColor(1);
            elseif FASTCSF && epar.experiment == 3
                epar.ThisContrast = epar.ThisContrast/epar.SlopeColor(2);
            end

        end

        if PRIOR
            epar.ThisContrast = Grain;
        end


        %Fix contrast & SF (mostly for debugging stuff)
        %epar.ThisContrast = 1;
        %epar.trial.sf(t) = 0.3;

        %If contrast estimate from Quest is < 0
        if epar.ThisContrast < Grain
            epar.ThisContrast = Grain; %Make it minimum
        end

        %If contrast estimate from Quest is > 1
        if epar.ThisContrast > 1
            epar.ThisContrast = 1;
        end

        %Save all trial contrasts
        epar.trial.contrasts(t) = epar.ThisContrast;

        %Set orientation for this trial %fixed to vertical
        epar.orientation = 90;

        %Record orientation of this trial (This is for L/R detection)
        if epar.ThisLoc < epar.x_center %if left
            epar.trial.LR(t)= 1;
        else %if right
            epar.trial.LR(t)= 2;
        end

        % Prepare the stimulus
        epar = exp_trial_init(epar,t,QUEST,FASTCSF,PRIOR);

        %% Check EyeLink
        if epar.EL
            %Check for fifty trials or so toggle this on correctdrift
            if mod(t,50) == 0
                exp_el_start( el, t, epar.x_center, epar.y_center, 1);
                Screen('FillRect',epar.windowC,epar.grayC,epar.WinRectC);
                Screen('FillRect',epar.windowC,epar.grayL,epar.WinRectL);
                Screen('FillRect',epar.windowC,epar.grayR,epar.WinRectR);
                baseRect = round([0 0 0.05/epar.XPIX2DEG 0.05/epar.YPIX2DEG]); %% Define size of rectangle ;
                FixationRect = CenterRectOnPointd(baseRect,epar.x_center,epar.y_center);
                Screen('FillOval',epar.windowC,epar.blackC,FixationRect)
                Screen('Flip',epar.windowC);
                WaitSecs(0.3);
            else
                exp_el_start( el, t, epar.x_center, epar.y_center, 0);
            end
        end

        %% Present things
        epar = exp_show_image(epar,el,t,QUEST,FASTCSF,PRIOR);

        %% if Abort
        if epar.abort
            Screen('Close',epar.windowC);
            close all
            clc
            warning('Experiment Aborted')
            break

            if epar.EL %Exit Eyelink stuff
                %
                WaitSecs(0.05);
                Eyelink('StopRecording');
                error = Eyelink('CheckRecording');
                fprintf('Stop Recording: %d; ',error);
                Eyelink('SetOfflineMode');
                WaitSecs(0.05);
            end
        end

        %% End Eyelink Recording
        if epar.EL
            %
            WaitSecs(0.05);
            Eyelink('StopRecording');
            error = Eyelink('CheckRecording');
            fprintf('Stop Recording: %d; ',error);
            Eyelink('SetOfflineMode');
            WaitSecs(0.05);
        end

        %% Save the trial information
        %     exp_trial_save(epar,t);
        TimeOff = toc(TimeOn);
        epar.trial.timeoff(t) = TimeOff; %Record overall length of trials
        PutABreakHereToLookAtTimeOff = 1; %do as the variable says
        % save('./TMP.mat','epar');

        %Trial Cleanup of Textures
        if ~PRIOR
            Screen('Close',epar.gabor.ramptextures)
        end

        %% Response of detection
        if epar.trial.LR(t) == epar.trial.responses(t)
            epar.trial.correct(t) = 1;
        elseif epar.trial.LR(t) ~= epar.trial.responses(t)
            epar.trial.correct(t) = 0;
        end

        %Check for bad trial
        if epar.trial.badtrials(t) == 0

            %% Update Fast CSF / QUEST
            if QUEST

                eval( sprintf( 'Quest.%s.%s = QuestUpdate(Quest.%s.%s,%.4f,%d);',ThisLoc,ThisSF,ThisLoc,ThisSF, epar.ThisContrast, epar.trial.correct(t) ) );

            elseif FASTCSF

                %Just for FastCSF, change from bpc values back to cone contrasts! %Remember: Slope_Color(RG,YV,Ach)!
                if epar.experiment == 1
                    FStruct_Contrast = epar.ThisContrast*epar.SlopeColor(3); % Multiply:  bpc Contrast -> Cone Contrast
                elseif epar.experiment == 2
                    FStruct_Contrast = epar.ThisContrast*epar.SlopeColor(1);
                elseif epar.experiment == 3
                    FStruct_Contrast = epar.ThisContrast*epar.SlopeColor(2);
                end
                eval( sprintf( 'FStruct.%s = fastUpdate(FStruct.%s, [epar.ThisSF, log10(FStruct_Contrast), epar.trial.correct(t)]);',ThisLoc,ThisLoc));

            end
        else
            %Framework for tacking on bad trials onto the end, this is put into place
            %before the eyetracker is present, so it still needs to be
            %tested.

            TrialFields = fieldnames(epar.trial);

            for ii = 1:numel(TrialFields)

                if ~strcmp(TrialFields{ii},'sim') && ~strcmp(TrialFields{ii},'num') && ~strcmp(TrialFields{ii},'Windows')  %Don't count these variables


                    eval( sprintf( 'Trialtmp = epar.trial.%s(t)',TrialFields{ii} ) );

                    %Remove this trial
                    if ~strcmp(TrialFields{ii},'Xpos') && ~strcmp(TrialFields{ii},'Ypos') && ~strcmp(TrialFields{ii},'badtrials')  %...unless it's the eye position/badtrials, keep that
                        eval( sprintf( 'epar.trial.%s(t) = NaN',TrialFields{ii} ) );
                    end

                    %Append to end
                    eval( sprintf( 'epar.trial.%s(end+1) = Trialtmp',TrialFields{ii}) ) ;

                end
            end

            %Increase total trials
            epar.trial.num = epar.trial.num+1;
            epar.trial.badtrials(end+1) = NaN;

        end
    end

    %% FINISH

    save('./TMP_WORKSPACE.mat'); %Save the entire workspace after a trial is complete in case things get bonked on shutdown

    % Save mat file with necessary stuff
    if QUEST
        save(sprintf('%s/data.mat',epar.exp_path),'epar','Quest'); %Save epar & QUEST structs file for analysis -NRB
        if ~exist(sprintf('%s/data (copy).mat',epar.exp_path))
            save(sprintf('%s/data (copy).mat',epar.exp_path),'epar','Quest'); %Save a copy if one doesn'T already exist -NRB
        end
    elseif FASTCSF
        save(sprintf('%s/data.mat',epar.exp_path),'epar','FStruct'); %Save epar & FStruct structs file for analysis -NRB
        if ~exist(sprintf('%s/data (copy).mat',epar.exp_path))
            save(sprintf('%s/data (copy).mat',epar.exp_path),'epar','FStruct'); %Save a copy if one doesn'T already exist -NRB
        end
    elseif PRIOR

        %Get stuff per trial
        Locations = epar.trial.loc';
        Frequencies = epar.trial.sf';
        PriorsEst = epar.trial.priors;

        %Get all measurements regardless of trials
        AllLocations = epar.AllLocPx; %Keep in mind this is weird to sort since we go to another monitor
        AllSF = sort(unique(Frequencies));

        %Create prior structures organized as
        for aa = 1:numel(AllLocations) %loop through locations
            for bb = 1:numel(AllSF) %loop through frequencies
                idx = intersect( find(Frequencies == AllSF(bb)) , find(Locations == AllLocations(aa)) ); %Idx for this Loc/SF/PriorEst
                Const{aa}(bb) =  PriorsEst(idx)./2; %Note: Due to consistent overestimation, take half the prior
                if PriorsEst(idx) <= 0.1
                    GuessSD{aa}(bb) = 0.2;
                elseif PriorsEst(idx) > 0.1 && PriorsEst(idx) <= 0.5
                    GuessSD{aa}(bb) = 0.4;
                elseif PriorsEst(idx) > 0.5
                    GuessSD{aa}(bb) = 0.6;
                end
                if Const{aa}(bb) <= 0 %if contrast is zero
                    Const{aa}(bb) = 0.1;
                end
            end

        end

        Prior.Const = Const;
        Prior.GuessSD = GuessSD;

        if exist(sprintf('%s/data.mat',epar.exp_path)) == 2 %If prior file already exists
            warning('OVERWRITING PRIORS')
        end
        save(sprintf('%s/data.mat',epar.exp_path),'epar','Prior'); %Save epar & QUEST structs file for analysis -NRB

    end

    exp_mon_exit(epar);
    sca
    Screen('CloseAll')
    %

    % Convert the edf Data  into MAT
    if epar.EL
        % ReadoutTrials
        exp_el_exit(epar);
    end

catch
    sca
    Screen('CloseAll')
    tmpE = lasterror;
end
