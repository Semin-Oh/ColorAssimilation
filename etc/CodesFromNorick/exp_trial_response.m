function [ epar ] = exp_trial_response( epar, t, demo )

if epar.experiment == 1
    
    if epar.get_response
        
        KbName('UnifyKeyNames')
        
        Screen('FillRect',epar.window,epar.gray)
        Screen('TextSize', epar.window, 30);
        Screen('TextFont', epar.window, 'Arial');
        DrawFormattedText(epar.window, 'Which half of the stimulus was brighter?', 'center',epar.SCREEN_Y_PIX/2-200, epar.red);
        DrawFormattedText(epar.window, 'Upper Half', 'center',epar.SCREEN_Y_PIX/2+200, epar.red);
        DrawFormattedText(epar.window, 'Lower Half', 'center',epar.SCREEN_Y_PIX/2+300, epar.red);
        Screen( 'Flip',  epar.window);
        
        %% Get the response
        while 1
            
            [keysDown,secs,keyCode] = KbCheck;
            
            if epar.trial.StandLocation(t) == 90
                if keyCode(KbName('UpArrow'))
                    epar.response = 1;
                    break
                elseif keyCode(KbName('DownArrow'))
                    epar.response = 0;
                    break
                end
            elseif epar.trial.StandLocation(t) == 270
                if keyCode(KbName('UpArrow'))
                    epar.response = 0;
                    break
                elseif keyCode(KbName('DownArrow'))
                    epar.response = 1;
                    break
                end
            end
        end
        
        %% Adjust the response to brighter
        if epar.response ==1
            if epar.trial.contTarget(t) < epar.standard_contrast
                epar.response = 0;
            end
        end
    end
    
else
    epar.response = 0;
end

end
