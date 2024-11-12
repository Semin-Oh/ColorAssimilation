%% independent variables
% Settings for stimuli
epar.gabor.size = 1125; %epar.SCREEN_Y_PIX; %1360; % Size of the texture
epar.gabor.exponent = 4; % 2 for regular gaussian %NRB changed to 4 to make it broader
% epar.orient =[-45 45]; % Define the direction of the gabor
epar.orient = 0; %grating orientation (fixed for this experiment
epar.gabor.phase = pi/2;
epar.gabor.ramp = 0.6; %NRB Ramp duration in sec (convert to # of frames later)
epar.masktime = 0.25; %NRB Duration of mask in seconds (for WaitSecs) (Mask removed for this experiment)

epar.get_response = 1;

%This is -90:90 in 15deg steps but skips +/-30deg because screen edges
epar.LocNames = fliplr({'Deg0','Deg15','Deg45','Deg60','Deg75','Deg90'}); %Edit these by hand for naming purposes
Locations = [epar.x_center-(1125*6) , epar.x_center-(1125*5) , epar.x_center-(1125*4) , epar.x_center-(1125*3) , epar.x_center-1125 , epar.x_center-375 , ...
    epar.x_center+375, epar.x_center+1125 , epar.x_center+(1125*3) , epar.x_center+(1125*4) , epar.x_center+(1125*5) , epar.x_center+(1125*6)];
% Edit Locations variable ^ by hand. These are all relative to center
% monitor, center screen. Adjusting to other screens done below

%Change location variables to be relative to the appropriate screen
% LeftEdge = (epar.gabor.size/2); %For 3 seperate window setup, delete later
% RightEdge = epar.SCREEN_X_PIX - (epar.gabor.size/2);
LeftEdge = epar.x_center - (epar.SCREEN_X_PIX/2) + 1;
RightEdge = epar.x_center + (epar.SCREEN_X_PIX/2) - 1;

LI = find(Locations<LeftEdge); %Left screen positions
RI = find(Locations>RightEdge); %Right screen positions

%For 3 seperate window setup, delete later
% Locations(LI) = Locations(LI) + epar.SCREEN_GAP_px + epar.SCREEN_X_PIX;
% Locations(RI) = Locations(RI) - epar.SCREEN_GAP_px - epar.SCREEN_X_PIX ;

Locations(LI) = Locations(LI) + epar.SCREEN_GAP_px;
Locations(RI) = Locations(RI) - epar.SCREEN_GAP_px;

if PRIOR
    epar.repetitions = 1; %If using estimator then just do once
    epar.AllLocPx = Locations((length(Locations)/2)+1:end); %For prior you only need to do one side (rough estimation is fine)
    epar.ALLLoc = [1,2,3,4,5,6]; %
    epar.LI = [];
    [tmp, epar.RI] = intersect(epar.AllLocPx,Locations(RI));
else
    epar.repetitions = 5; %Number of repetitions for each SF && Location (Total trials will = NumSF * NumLoc * NumRep)
    epar.AllLocPx = Locations; %NRB this was calculated by hand. 1125px=15deg
    epar.ALLLoc = [1,2,3,4,5,6,7,8,9,10,11,12]; %15deg steps with 30deg skipped
    epar.LI = LI;
    epar.RI = RI;
end

epar.ALLSF = [0.1 0.3 0.5 1 3 5 10]; %Spatial frequencies chosen before and variable done by hand here

if epar.GaborType %if FCG gabor
    % Size of stim for 1 cycle
    SD_Deg = 1./epar.ALLSF; % #cycles in 1 deg
    SD_Px = round(SD_Deg./epar.XPIX2DEG);
    epar.gabor.sd = round( ((1./epar.ALLSF)./epar.XPIX2DEG).*4 ); %Size of the gaussian envelope in px (half the size of 1 cycle in px)
else
    epar.gabor.sd = 4; %Size of gaussian envelope (NRB: Changed to 4 to make it broaders)
end

%% create trial array
[epar.trial.sf,epar.trial.loc] = BalanceFactors(epar.repetitions,1,epar.ALLSF,epar.AllLocPx);
epar.trial.num = length(epar.trial.sf);

%Init trial stuff w/ NaN's -NRB
epar.trial.respstart = zeros(epar.trial.num,1).* NaN;
epar.trial.respend = zeros(epar.trial.num,1).* NaN;
epar.trial.responses = zeros(epar.trial.num,1).* NaN;
epar.trial.LR = zeros(epar.trial.num,1).* NaN;
epar.trial.correct = zeros(epar.trial.num,1).* NaN;
epar.trial.contrasts = zeros(epar.trial.num,1).* NaN;
epar.trial.Xpos = zeros(epar.trial.num,1).* NaN;
epar.trial.Ypos = zeros(epar.trial.num,1).* NaN;
epar.trial.PhaseFlip = zeros(epar.trial.num,1).* NaN;
epar.trial.badtrials = zeros(epar.trial.num,1).* NaN;
epar.trial.timeoff = zeros(epar.trial.num,1).* NaN;

%If FASTCSF then load up the bad combos and eliminate trials that don't
%work. (Do this for QUEST as well!)
% if FASTCSF 
    load('/home/gegenfurtner/Desktop/FRL/Wide-Field-CSF/data/FastCSFPriors/BadCombos.mat');

    if epar.experiment == 1
        TheseBadCombos = E1_BadCombos;
    elseif epar.experiment == 2
        TheseBadCombos = E2_BadCombos;
    elseif epar.experiment == 3
        TheseBadCombos = E3_BadCombos;
    end

    TMPLocs = [90 75 60 45 15 0 0 15 45 60 75 90]; %TMP locations for bad combos check

    for aa = 1:length(TheseBadCombos(1,:))

        BadEcc = TheseBadCombos(1,aa);
        BadSF = TheseBadCombos(2,aa);
        LocIdx = find(BadEcc == TMPLocs);

        DropIdx = find( epar.trial.sf == BadSF & ( epar.trial.loc == Locations(LocIdx(1)) | epar.trial.loc == Locations(LocIdx(2)) ) ); %Drop trials w/ bad combos

        %Save the bad trials in order to simulate them 
        SFTrials{aa} =  epar.trial.sf(DropIdx).';
        LocTrials{aa} = epar.trial.loc(DropIdx).';


        epar.trial.sf(DropIdx) = [];
        epar.trial.loc(DropIdx) = [];
        epar.trial.respstart(DropIdx) = [];
        epar.trial.respend(DropIdx) = [];
        epar.trial.LR(DropIdx) = [];
        epar.trial.correct(DropIdx) = [];
        epar.trial.responses(DropIdx) = [];
        epar.trial.contrasts(DropIdx) = [];
        epar.trial.Xpos(DropIdx) = [];
        epar.trial.Ypos(DropIdx) = [];
        epar.trial.PhaseFlip(DropIdx) = [];
        epar.trial.badtrials(DropIdx) = [];
        epar.trial.timeoff(DropIdx) = [];
        %Uncell
        epar.trial.sim.sf = cell2mat(SFTrials);
        epar.trial.sim.loc = cell2mat(LocTrials);
    end
    epar.trial.num = length(epar.trial.sf);
% end



%Reamining Trials:
% Experiment 1: 330 trials
% Experiment 2: 310 trials
% Experiment 2: 280 trials
