function [epar] = exp_show_image(epar,el,tn,QUEST,FASTCSF,PRIOR)

KbName('UnifyKeyNames')
Screen('TextSize', epar.windowC, 20);
Screen('TextFont', epar.windowC, 'Arial');

% Fixation Screen
Screen('FillRect',epar.windowC,epar.grayC,epar.WinRectC);
Screen('FillRect',epar.windowC,epar.grayL,epar.WinRectL);
Screen('FillRect',epar.windowC,epar.grayR,epar.WinRectR);

baseRect = round([0 0 0.05/epar.XPIX2DEG 0.05/epar.YPIX2DEG]); %% Define size of rectangle ;
FixationRect = CenterRectOnPointd(baseRect,epar.x_center,epar.y_center);
Screen('FillOval',epar.windowC,epar.blackC,FixationRect)
if tn == 1 %Wait for key press for frist trial to begin
    DrawFormattedText(epar.windowC, ['Press Space to Begin'], 'center',epar.y_center-100, epar.blackC);
end

%Blank other screens
Screen('FillOval',epar.windowC,epar.blackC,FixationRect)
Screen('Flip',epar.windowC);

if tn == 1 %if first trial, wait for space bar to begin
    while 1
        [keysDown,secs,keyCode] = KbCheck; %Constantly check for keypress

        %If left or right arrow, record response and break
        if keyCode(KbName('Space'))
            break
        end
    end
end

if epar.EL
    Eyelink('Message','Fixation');
end

WaitSecs(0.025);

% %Get 5 seconds of eye position to test
% Start = GetSecs; 
% End = GetSecs;
% bb =1; 
% while End- Start < 5
%     End = GetSecs;
% [X_pos(bb) Y_pos(bb)] = exp_el_eye_pos (el,epar); %  eye position on screen;
% bb =bb+1; 
% end
% sca 
% keyboard

%% Show the Stimulus
if QUEST || FASTCSF %If actual trials (might need to seperate these two but I don't think so)

    %NRB adjust position based on trial
    ThisRect = CenterRectOnPointd(epar.gabor.rect,epar.trial.loc(tn),epar.y_center);

    %Display Ramp Up -NRB
    for aa = 1:numel(epar.gabor.ramptextures)
        %Put up grays
        Screen('FillRect',epar.windowC,epar.grayC,epar.WinRectC);
        Screen('FillRect',epar.windowC,epar.grayL,epar.WinRectL);
        Screen('FillRect',epar.windowC,epar.grayR,epar.WinRectR);
        Screen('DrawTexture',epar.windowC,epar.gabor.ramptextures(aa),[],ThisRect);
        Screen('Flip',epar.windowC);
    end

    SamplePos = 0;
    %Display Ramp Down -NRB
    for aa = 1:numel(epar.gabor.ramptextures);

        if SamplePos == 0 %Get a sample of the eye trace
            try %if you can't get a sample, just assume bad and move on
                [epar.trial.Xpos(tn),epar.trial.Ypos(tn)] = exp_el_eye_pos (el,epar); %  eye position on screen;
                SamplePos = 1;
            catch
                epar.trial.Xpos(tn) = 1500; %about 20deg
                epar.trial.Ypos(tn) = 1500;
            end

        end

        %Put up grays
        Screen('FillRect',epar.windowC,epar.grayC,epar.WinRectC);
        Screen('FillRect',epar.windowC,epar.grayL,epar.WinRectL);
        Screen('FillRect',epar.windowC,epar.grayR,epar.WinRectR);
        Screen('DrawTexture',epar.windowC,epar.gabor.ramptextures(end-(aa-1)),[],ThisRect);
        Screen('Flip',epar.windowC);
    end

    %This is a debugging code to bring up a gabor on all windows and keep it in
    %place until ESC is pressed in order to check locations Comment above and
    %uncomment this to use %THIS NO LOGER WORKS! NEED TO MAKE EACH GABOR
    %INDIVIDUALLY FOR EACH SCREEN IN ORDER TO CORRECT IT THE RIGHT WAY
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     for aa = 1:length(epar.AllLocPx)
    %         ThisRect = CenterRectOnPointd(epar.gabor.rect,epar.AllLocPx(aa),epar.y_center);
    %         Screen('DrawTexture',epar.windowC,epar.gabor.ramptextures(end),[],ThisRect);
    %     end
    %
    %     Screen('Flip',epar.windowC);
    %
    %     while 1
    %         [keysDown,secs,keyCode] = KbCheck; %Constantly check for keypress
    %         %If left or right arrow, record response and break
    %         if keyCode(KbName('Escape'))
    %             sca
    %             epar.abort = 1;
    %             break
    %         end
    %
    %     end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Check Eye Position
    Dist = sqrt( ((epar.x_center - epar.trial.Xpos(tn))^2) + ((epar.y_center - epar.trial.Ypos(tn))^2) );

    if Dist > 188 %189 is just about 2.5 degree. 189*epar.XPIX2DEG
        epar.trial.badtrials(tn) = 1;
    else
        epar.trial.badtrials(tn) = 0;
    end

    %% Get Response
    %Put up grays
    Screen('FillRect',epar.windowC,epar.grayC,epar.WinRectC);
    Screen('FillRect',epar.windowC,epar.grayL,epar.WinRectL);
    Screen('FillRect',epar.windowC,epar.grayR,epar.WinRectR);
    Screen('FillOval',epar.windowC,epar.blackC,FixationRect) %Keep fixation on
    DrawFormattedText(epar.windowC, 'Left or Right', 'center',epar.y_center+100, epar.blackC);
    if tn ~= 1 %if the last trial was bad, make the text saying the remaining trials red
        if epar.trial.badtrials(tn) == 0 
            DrawFormattedText(epar.windowC, sprintf('Trial %d/%d',tn,length(epar.trial.sf)), 'center',epar.y_center+650, epar.blackC);
        else
            DrawFormattedText(epar.windowC, sprintf('Trial %d/%d',tn,length(epar.trial.sf)), 'center',epar.y_center+650, [(2^epar.bitdepth)*0.75,0,0]);
        end
    end
    Screen('Flip',epar.windowC);

    %Start counter for response time
    epar.trial.respstart(tn) = GetSecs;

    while 1

        [keysDown,secs,keyCode] = KbCheck; %Constantly check for keypress

        %If left or right arrow, record response and break
        if keyCode(KbName('LeftArrow'))
            epar.trial.responses(tn) = 1;

            %Put up grays
            Screen('FillRect',epar.windowC,epar.grayC,epar.WinRectC);
            Screen('FillRect',epar.windowC,epar.grayL,epar.WinRectL);
            Screen('FillRect',epar.windowC,epar.grayR,epar.WinRectR);
            Screen('FillOval',epar.windowC,epar.blackC,FixationRect) %Keep fixation on
            Screen('Flip',epar.windowC);
            break
        elseif keyCode(KbName('RightArrow'))
            epar.trial.responses(tn) = 2;

            %Put up grays
            Screen('FillRect',epar.windowC,epar.grayC,epar.WinRectC);
            Screen('FillRect',epar.windowC,epar.grayL,epar.WinRectL);
            Screen('FillRect',epar.windowC,epar.grayR,epar.WinRectR);
            Screen('FillOval',epar.windowC,epar.blackC,FixationRect) %Keep fixation on
            Screen('Flip',epar.windowC);
            break
        elseif keyCode(KbName('Escape'))
            epar.abort = 1;
            break
        end

    end

elseif PRIOR %If PRIOR estimate

    %NRB adjust position based on trial
    ThisRect = CenterRectOnPointd(epar.gabor.rect,epar.trial.loc(tn),epar.y_center);

    %Flip original texture
    gauss_data = (epar.gabor.gauss_data./max(epar.gabor.gauss_data(:)))*0.5*0; %zero contrast originally
    CurrGabor = ( ((epar.gabor.sin_data).*gauss_data)+0.5);

    % 3D, Color, and Gamma stuff
    if epar.experiment == 1 % Achromatic
        CurrGabor_3D = single(repmat(CurrGabor,[1,1,3])); % Make it 3D
    elseif epar.experiment == 2 % Red-Gren
        CurrGabor_3D = single(DKL2RGBMAT(0,0, CurrGabor-0.5));
    elseif epar.experiment == 3 % Blue-Yellow
        CurrGabor_3D = single(DKL2RGBMAT(0,90, CurrGabor-0.5));
    end

    if epar.GAMMA % If Gamma Correction
        if strcmp(epar.trial.Windows(tn),'C')
            CurrGabor_3D = Correct(CurrGabor_3D,epar.bitdepth,epar.LUTC); % Correct it
        elseif strcmp(epar.trial.Windows(tn),'L')
            CurrGabor_3D = Correct(CurrGabor_3D,epar.bitdepth,epar.LUTL); % Correct it
        elseif strcmp(epar.trial.Windows(tn),'R')
            CurrGabor_3D = Correct(CurrGabor_3D,epar.bitdepth,epar.LUTR); % Correct it
        else
            error
        end
    end
    GaborTexture = Screen('MakeTexture', epar.windowC,  CurrGabor_3D,[],[],1);
    Screen('Flip',epar.windowC);

    %Put up grays
    Screen('FillRect',epar.windowC,epar.grayC,epar.WinRectC);
    Screen('FillRect',epar.windowC,epar.grayL,epar.WinRectL);
    Screen('FillRect',epar.windowC,epar.grayR,epar.WinRectR);

    Screen('FillOval',epar.windowC,epar.blackC,FixationRect) %Keep fixation on
    Screen('DrawTexture',epar.windowC,GaborTexture,[],ThisRect);
    Screen('Flip',epar.windowC);

    %Init
    BigStep = 0.02;
    SmallStep = 0.002;
    CurrContrast = epar.ThisContrast;

    while 1 %hold until space bar is pressed to go to next trial (or escape to break out)

        [keysDown,secs,keyCode] = KbCheck; %Constantly check for keypress
        ScreenFlip = 0; %only flip if a button is pressed
	WaitSecs(0.025); %Hold for about 3 frame, sometimes it'll crash

        %If left or right arrow, record response and break
        if keyCode(KbName('LeftArrow')) %Coarse down
            CurrContrast = CurrContrast - BigStep;
            ScreenFlip = 1;
        elseif keyCode(KbName('RightArrow')) %Coarse up
            CurrContrast = CurrContrast + BigStep;
            ScreenFlip = 1;
        elseif keyCode(KbName('DownArrow')) %Fine down
            CurrContrast = CurrContrast - SmallStep;
            ScreenFlip = 1;
        elseif keyCode(KbName('UpArrow')) %Fine up
            CurrContrast = CurrContrast + SmallStep;
            ScreenFlip = 1;
        elseif keyCode(KbName('Space'))
            epar.trial.priors(tn) = CurrContrast;
            break
        elseif keyCode(KbName('Escape'))
            epar.abort = 1;
            break
        end

        %Adjust for out-of-bounds values
        if CurrContrast > 1; CurrContrast = 1; end
        if CurrContrast < 0; CurrContrast = 0; end

        %Make CurrGabor based on contrast adjustments
        gauss_data = (epar.gabor.gauss_data./max(epar.gabor.gauss_data(:)))*0.5*CurrContrast; %zero contrast originally
        CurrGabor = ( ((epar.gabor.sin_data).*gauss_data)+0.5);
        CurrGabor = CurrGabor.';


        % 3D, Color, and Gamma stuff
        if epar.experiment == 1 % Achromatic
            CurrGabor_3D = single(repmat(CurrGabor,[1,1,3])); % Make it 3D
        elseif epar.experiment == 2 % Red-Gren
            CurrGabor_3D = single(DKL2RGBMAT(0,0, CurrGabor-0.5));
        elseif epar.experiment == 3 % Blue-Yellow
            CurrGabor_3D = single(DKL2RGBMAT(0,90, CurrGabor-0.5));
        end

        if epar.GAMMA % If Gamma Correctionblack
            if strcmp(epar.trial.Windows(tn),'C')
                CurrGabor_3D = Correct(CurrGabor_3D,epar.bitdepth,epar.LUTC); % Correct it
            elseif strcmp(epar.trial.Windows(tn),'L')
                CurrGabor_3D = Correct(CurrGabor_3D,epar.bitdepth,epar.LUTL); % Correct it
            elseif strcmp(epar.trial.Windows(tn),'R')
                CurrGabor_3D = Correct(CurrGabor_3D,epar.bitdepth,epar.LUTR); % Correct it
            else
                error
            end
        end
       

        %Make and save textures
        if ScreenFlip
            %Put up grays
            Screen('FillRect',epar.windowC,epar.grayC,epar.WinRectC);
            Screen('FillRect',epar.windowC,epar.grayL,epar.WinRectL);
            Screen('FillRect',epar.windowC,epar.grayR,epar.WinRectR);
            Screen('FillOval',epar.windowC,epar.blackC,FixationRect) %Keep fixation on
            GaborTexture = Screen('MakeTexture', epar.windowC,  CurrGabor_3D,[],[],1);
            Screen('DrawTexture',epar.windowC,GaborTexture,[],ThisRect);
            if CurrContrast == 1
                DrawFormattedText(epar.windowC, 'Maximum Contrast', 'center',epar.y_center+100, epar.blackC);
            elseif CurrContrast == 0
                DrawFormattedText(epar.windowC, 'Minimum Contrast', 'center',epar.y_center+100, epar.blackC);
            end
            
                                        %This was a test to save the gabor RIGHT before it's put onto the
        %screen to make sure it's correct
       %  if CurrContrast > 0.99
            %save('./0.1GaborStuff.mat','CurrGabor','epar','CurrContrast','CurrGabor_3D');
            %baseRecttmp = round([0 0 1 1125]); %% Define size of rectangle ;
%FixationRecttmp = CenterRectOnPointd(baseRecttmp,epar.trial.loc(tn),epar.y_center);
%Screen('FillRect',epar.windowC,epar.grayC,FixationRecttmp);
%save('./RECTANGLES.mat','baseRecttmp','FixationRecttmp');
        % end
            
            Screen('Flip',epar.windowC);
    
        end

    end


end



%End trial for EyeLink
if epar.EL
    Eyelink('Message','TRIAL_END');
end

%Record response time
epar.trial.respend(tn) = GetSecs;






