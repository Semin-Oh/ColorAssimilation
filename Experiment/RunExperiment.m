% RunExperiment.
%
% This is a main experiment running code for color assimilation. This
% routine is based on the previous routine for measuing contrast
% sensitivity at peripheral vision done by Noric. The very first version of
% this routine is from Alex.
%
% (Note from the original code exp_main.m): Experiment to measure CSF in
% the far periphery. This experiment can use either QUEST or the FastCSF
% method to measure contrast sensitivity. This experiment can also run with
% fixed-cycle or fixed-siye gabors (currently fixed-size is chosen). First,
% this experiment uses method-of-adjustment to obtain priors for either CSF
% method (QUEST or FastCSF) before running that method.
%
% See also:
%    exp_main.m

% History:
%    03/21/24  smo  - Started on it.

%% Initialize.
clear all; close all; clc;

try
    % Toggles to change what's running (only one of these should be on!).
    %
    % Choose one among 'QUEST' (CSF estimation using QUEST), 'PRIOR'
    % (Prior estimator using method-of-adjustment using QUEST) / 'FASTCSF'.
    QUEST = 1;
    PRIOR = 0;
    FASTCSF = 0;

    % Set eyelink (1: Eyelink active; 0: No eyelink).
    % All the parameters will be saved in the object 'epar'.
    epar.EL = 0;

    % Set gabor size (0: Fixed size, 1= Fixed cycle).
    GaborType = 0;

    %% Set paramters.
    rng('Shuffle');
    epar.experiment = input('Experiment: [1: achromatic, 2: red-green, 3: blue-yellow]');
    epar.subject = input('Subject #:');
    epar.block = input('Block #:');
    epar.GaborType = GaborType;

    %% Settings for EyeTracker and Monitor calibration.
    exp_settings;

    %% INIT DISPLAY
    epar = exp_mon_init(epar);

    %% Init Experiment --> Trial Structure & Conditions
    exp_settings_1;

    %% INIT EYELINK
    if epar.EL
        el = exp_el_init(epar);
    else
        el = NaN;
    end

    %% CALIBRATE EYELINK.
    if epar.EL
        result=EyelinkDoTrackerSetup(el);
        if result==el.TERMINATE_KEY
            return;
        end
        Eyelink('message', 'Block_Start');
        Eyelink('WaitForModeReady', 500);
    end

    %% Initialize QUEST (Create Toggle)
    %
    % Create QUEST params (1 per position, per SF)
    if epar.block == 1 && QUEST
        exp_quest_params;
    end

    %% EXP
    Grain = round(1/(2^epar.bitdepth),3); %Smallest step in contrast possible
    epar.Grain = Grain;

    % Start a loop.
    t = 0;
    while t < epar.trial.num % Run through the trial loop
        % Iterate.
        t = t+1;

        % Initialize the trial. We will record length of trials.
        TimeOn = tic;

        % Set SF for this trial
        epar.ThisSF = epar.trial.sf(t);

        % Set location for this trial
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
        end

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

            % Exit Eyelink stuff.
            if epar.EL
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

        % Record overall length of trials
        epar.trial.timeoff(t) = TimeOff;

        % Do as the variable says
        PutABreakHereToLookAtTimeOff = 1;
        % save('./TMP.mat','epar');

        %% Response of detection
        if epar.trial.LR(t) == epar.trial.responses(t)
            epar.trial.correct(t) = 1;
        elseif epar.trial.LR(t) ~= epar.trial.responses(t)
            epar.trial.correct(t) = 0;
        end
    end

catch
    % If error occurs, close the screen.
    Screen('CloseAll')
    tmpE = lasterror;

    % Display the error message.
    tmpE.message
end
