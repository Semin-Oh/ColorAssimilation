function [epar] = exp_show_image(epar,el)

KbName('UnifyKeyNames')
Screen('TextSize', epar.window, 20);
Screen('TextFont', epar.window, 'Arial');

%% Show the initial Screen

Screen('DrawTexture',epar.window,epar.gabor.id_back );
baseRect = [0 0 0.3/epar.XPIX2DEG 0.3/epar.XPIX2DEG]; %% Define size of rectangle ;
centeredRect = CenterRectOnPointd(baseRect,epar.x_center,epar.y_center); %% Center it in the middle
Screen('FillOval',epar.window,epar.red,centeredRect)
Screen('Flip',epar.window);
if epar.EL
    Eyelink('Message','TRIAL_BEGIN');
end

%% Have random FixDuration
WaitSecs(epar.present_frame);

%% Check Fixation
% [X_pos Y_pos] = exp_el_eye_pos (el,epar); %  eye position on screen;
Early_Trial = 0;
if abs(X_pos) > epar.fix_tol
    
    Screen('FillRect',epar.window,epar.gray)
    DrawFormattedText(epar.window, 'Please keep fixating at center till target appears', 'center',epar.SCREEN_Y_PIX/2, epar.red);
    Screen('Flip',epar.window);
    WaitSecs(1)
    Eyelink('Message','Error');
    Eyelink('Message','Error');
    
    Early_Trial = 1;
end

%% Now present the Stimulus for some time
if Early_Trial == 0
    Screen('DrawTexture',epar.window,epar.gabor.id_stim);
%     Screen('FillOval',epar.window,epar.red,centeredRect)
    Screen('Flip',epar.window);
    if epar.EL
        Eyelink('Message','Stim Shown');
    end
    
end;
WaitSecs(epar.Duration); 
if epar.EL% End the Trial
    Eyelink('Message','TRIAL_END');
end;

Screen('DrawTexture',epar.window,epar.gabor.id_back);
Screen('Flip',epar.window);
WaitSecs(0.2);


Screen('FillRect',epar.window,epar.gray);
Screen('Flip',epar.window);


epar.response = 0; 

