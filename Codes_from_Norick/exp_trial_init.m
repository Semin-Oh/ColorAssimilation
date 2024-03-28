function [epar] = exp_trial_init( epar, tn,QUEST,FASTCSF,PRIOR)
%EXP_TRIAL_INIT Summary of this function goes here
%   Detailed explanation goes here

epar.eye_name = sprintf('%s//trial%d.dat',epar.exp_path, tn);

epar.gabor.direction = epar.orientation*pi/180;

%Pick envelope from list (gotta check to make sure these are correct
ThisEnvelope = find(epar.ALLSF==epar.trial.sf(tn));
global LUT;

%Put fixation dot up
Screen('FillRect',epar.windowC,epar.grayC,epar.WinRectC);
Screen('FillRect',epar.windowC,epar.grayL,epar.WinRectL);
Screen('FillRect',epar.windowC,epar.grayR,epar.WinRectR);
baseRect = round([0 0 0.05/epar.XPIX2DEG 0.05/epar.YPIX2DEG]); %% Define size of rectangle ;
FixationRect = CenterRectOnPointd(baseRect,epar.x_center,epar.y_center);
Screen('FillOval',epar.windowC,epar.blackC,FixationRect)
Screen('Flip',epar.windowC);

%% Create Texture
clear x; %If debugging x will iterate every time this is ran and eventually make huge arrays. This clear will prevent that.
x(1,:) = (1:epar.gabor.size)-epar.gabor.size/2;
x = repmat(x,[epar.gabor.size 1]);
y = x';
x = x.*epar.XPIX2DEG;
y = y.*epar.XPIX2DEG;
r = hypot(x,y);
% sin_data = cos(2.*pi.*((x.*cos(epar.gabor.direction)+y.*sin(epar.gabor.direction)+epar.gabor.phase).*epar.trial.sf(tn))); % Sine Grating NRB: The phase setting was in the wrong place, I think I fixed it.
sin_data = cos(2.*pi.*((x.*cos(epar.gabor.direction)+y.*sin(epar.gabor.direction)).*epar.trial.sf(tn))+epar.gabor.phase);

%Random reversal of phase
FlipPhase = randi(0:1);
if FlipPhase
    sin_data = -sin_data;
end
epar.trial.PhaseFlip(tn) = FlipPhase;

if epar.GaborType %if fixed cycle gabor
    SD_Win = (epar.gabor.sd(ThisEnvelope))/(epar.gabor.size/2); 
else %if fixed size gabor
    SD_Win = epar.gabor.sd;
end
gauss_data_original = exp(-0.5 .* ((r - 0)./SD_Win).^epar.gabor.exponent) ./ (sqrt(2*pi) .* SD_Win); % Gaussian envelope (copied from above!)
epar.gabor.rect = [0 0 epar.gabor.size epar.gabor.size];
epar.rect = CenterRectOnPoint(epar.gabor.rect, 0/epar.XPIX2DEG+epar.x_center, epar.y_center);

% gauss_data = exp(-0.5 .* ((r - 0)./epar.gabor.sd(ThisEnvelope)).^epar.gabor.exponent) ./ (sqrt(2*pi) .* epar.gabor.sd(ThisEnvelope)); % Gaussian envelope
% gauss_data = exp(-0.5 .* ((r - 0)./SD_Win).^epar.gabor.exponent) ./ (sqrt(2*pi) .* SD_Win); % Gaussian envelope
% 1D in order to check the size of the stimulus:
% gauss_data1D = exp(-0.5 .* ((x(1,:) - 0)./SD_Win).^epar.gabor.exponent) ./ (sqrt(2*pi) .* SD_Win); % Gaussian envelope
% gauss_data1D = (gauss_data1D./max(gauss_data1D(:)));
% Center = sum(gauss_data1D(find(x(1,:)> -SD_Win & x(1,:) < SD_Win)))/sum(gauss_data1D); %THIS IS 68%!!!
% gauss_data = exp(-0.5 .* ((r - 0)./(7/650)).^epar.gabor.exponent) ./ (sqrt(2*pi) .* (7/650)); % Gaussian envelope
% gauss_data = gauss_data./max(gauss_data(:));

%% Prior VS QUEST Trial
Timeon = tic; %Just to check the timings of stuff
if QUEST || FASTCSF %If actual trials

    %Temporal gaussian window for presentation (normalized)
    time = [-(epar.gabor.ramp/2) : 1/epar.MONITOR_FREQ : (epar.gabor.ramp/2)];
    Temporal_SD = 0.15;
    RampGauss = exp(-0.5 .* ((time - 0)./Temporal_SD).^epar.gabor.exponent) ./ (sqrt(2*pi) .* Temporal_SD); % Gaussian envelope
    RampGauss = RampGauss./max(RampGauss(:));

    %Generate textures in a gaussian time envelope
    CurrGabor_3D = single(zeros(size(sin_data,1),size(sin_data,2),3));

    for aa = 1:ceil(length(time)/2) % because the last frame is 100% contrast, redundant with stim
        ContrastAdj = (epar.ThisContrast*RampGauss(aa));
        gauss_data = (gauss_data_original./max(gauss_data_original(:)))*0.5*ContrastAdj;
        CurrGabor = ( ((sin_data).*gauss_data)+0.5);
        CurrGabor = CurrGabor.';

        if epar.experiment == 1 % Achromatic
            CurrGabor_3D = single(repmat(CurrGabor,[1,1,3])); % Make it 3D
        elseif epar.experiment == 2 % Red-Green
            CurrGabor_3D = single(DKL2RGBMAT(0,0, CurrGabor-0.5)); % Make it 3D
        elseif epar.experiment == 3 % Blue-Yellow
            CurrGabor_3D = single(DKL2RGBMAT(0,90, CurrGabor-0.5)); % Make it 3D
        end

        if epar.GAMMA % If Gamma Correction

            if ~isempty(find(find(epar.trial.loc(tn)==epar.AllLocPx) == epar.RI)) %Right monitor
                CurrGabor_3D = Correct(CurrGabor_3D,epar.bitdepth,epar.LUTR); % Correct it

            elseif ~isempty(find(find(epar.trial.loc(tn)==epar.AllLocPx) == epar.LI)) %Left monitor
                CurrGabor_3D = Correct(CurrGabor_3D,epar.bitdepth,epar.LUTL); % Correct it

            else %Center monitor
                CurrGabor_3D = Correct(CurrGabor_3D,epar.bitdepth,epar.LUTC); % Correct it

            end

        else
            CurrGabor_3D = double(CurrGabor_3D);
        end


        %Make and save textures
        if ~isempty(find(find(epar.trial.loc(tn)==epar.AllLocPx) == epar.RI)) %Make texture for right monitor
            epar.gabor.ramptextures(aa) = Screen('MakeTexture', epar.windowC,  CurrGabor_3D,[],[],1);
            epar.trial.Windows(tn) = 'R';
        elseif ~isempty(find(find(epar.trial.loc(tn)==epar.AllLocPx) == epar.LI)) %Make texture for left monitor
            epar.gabor.ramptextures(aa) = Screen('MakeTexture', epar.windowC,  CurrGabor_3D,[],[],1);
            epar.trial.Windows(tn) = 'L';
        else %Make texture for center monitor
            epar.gabor.ramptextures(aa) = Screen('MakeTexture', epar.windowC,  CurrGabor_3D,[],[],1);
            epar.trial.Windows(tn) = 'C';
        end

    end

elseif PRIOR %if prior estimate

    %Just save gauss and sine info and then adjust on the fly in exp_show_image
    epar.gabor.sin_data = sin_data;
    epar.gabor.gauss_data = gauss_data_original;

    %Make and save textures
    if ~isempty(find(find(epar.trial.loc(tn)==epar.AllLocPx) == epar.RI)) %Make texture for right monitor
        epar.trial.Windows(tn) = 'R';
    elseif ~isempty(find(find(epar.trial.loc(tn)==epar.AllLocPx) == epar.LI)) %Make texture for left monitor
        epar.trial.Windows(tn) = 'L';
    else %Make texture for center monitor
        epar.trial.Windows(tn) = 'C';
    end

end

Timeoff = toc(Timeon);
PutABreakHereToLookAtTimeOff = 1; %do as the variable says
