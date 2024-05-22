%This code will bring up a square and leave it up until you measure the
%luminance and write it down. Pressing space will step to the next setting.
%This will do the same thing on all monitors simultaneously.
clear all; clc; close all

%Note: Try to measure monitors individually and determine if Psychtoolbox
%is the culprit. Also try to measure patches in photoshop or something
%instead of using Psychtoolbox.

%Record the room name and the monitor being measured
room = 'EyeTracking';
monitor = 'ColorCalibrated';

SCREEN_X_PIX = 5120;
SCREEN_Y_PIX = 1440;
BitDepth = 8;
RectSize = [0 0 1125 1125];
StimRectL = CenterRectOnPoint(RectSize,SCREEN_X_PIX/2,SCREEN_Y_PIX/2);
StimRectC = CenterRectOnPoint(RectSize, (SCREEN_X_PIX/2 + SCREEN_X_PIX) ,SCREEN_Y_PIX/2);
StimRectR = CenterRectOnPoint(RectSize,  (SCREEN_X_PIX/2 + SCREEN_X_PIX + SCREEN_X_PIX) ,SCREEN_Y_PIX/2);
gray=[0.75 0.75 0.75]; %Rough approximation of ne\Users\ExpComputer\Desktop\FRL\Wide-Field-CSFutral gray based on 8-bit assumption of 192
KbName('UnifyKeyNames');


% Make sure the script is running on Psychtoolbox-3:
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1);

ScreenNums=Screen('Screens');

PsychImaging('PrepareConfiguration');
% PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer',['disableDithering',1]);
% PsychImaging('AddTask', 'General', 'FloatingPoint16Bit');

CWin = ScreenNums(1);
[windowC screenRectC] =PsychImaging('OpenWindow',  CWin,0.5);
Screen('ColorRange', windowC, 1);
black=BlackIndex(windowC);
white=WhiteIndex(windowC);

Screen('TextSize', windowC, 20);
Screen('TextFont', windowC, 'Arial');

BRCornerL = screenRectC(3)-200 - SCREEN_X_PIX - SCREEN_X_PIX;


HideCursor;

values = ([0 4 8 16 24 32 64 96 128 140 150 160 170 180 190 200 210 220 230 240 250 255])./(2^BitDepth);
% BitdepthTestVals = [507:517]./1024; no need for depth test
% values = sort([values BitdepthTestVals]);
Colors = 'RGBK';
try
    for ch=1:4
        Intensity{ch} = [1:(2^BitDepth)].*NaN;
        XVals{ch} = [1:(2^BitDepth)].*NaN;
        YVals{ch} = [1:(2^BitDepth)].*NaN;

        for v = 1:length(values)

            col=zeros(1,3);
            if ch<4
                col(ch)=values(v);
            else
                col=col+values(v);
            end

            valuebit = round(values(v) .* (2^BitDepth));
            CurrentValue = sprintf('%s: %d',Colors(ch),valuebit);

            InputCnt = 1; %input counter

            while InputCnt < 4
                ThisI = []; %blank input value
                while 1
                    if isempty(ThisI)

                        ResponseGiven = 0;

                        % Display Stuff
                        Screen('FillRect',windowC,gray);
                        Screen('FillRect',windowC,col,StimRectL);
                        if InputCnt == 1
                            Screen('DrawText',windowC,sprintf('Lum, %s',CurrentValue),BRCornerL,screenRectC(4)-200,[1023,1023,1023]);
                        elseif InputCnt == 2
                            Screen('DrawText',windowC,sprintf('X, %s',CurrentValue),BRCornerL,screenRectC(4)-200,[1023,1023,1023]);
                        elseif InputCnt == 3
                            Screen('DrawText',windowC,sprintf('Y, %s',CurrentValue),BRCornerL,screenRectC(4)-200,[1023,1023,1023]);
                        else
                            error
                        end

                        Screen('Flip',windowC);


                        %Hang here and wait for input value
                        fprintf('\n');
                        ThisI = input(''); %Wait for input value

                        %Display input value in corner of screen
                        Screen('FillRect',windowC,gray); %background
                        Screen('FillRect',windowC,col,StimRectL); %Stim (text stuff below)
                        if InputCnt == 1
                            Screen('DrawText',windowC,sprintf('Lum, %s',CurrentValue),BRCornerL-200,screenRectC(4)-200,[1023,1023,1023]);
                        elseif InputCnt == 2
                            Screen('DrawText',windowC,sprintf('X, %s',CurrentValue),BRCornerL-200,screenRectC(4)-200,[1023,1023,1023]);
                        elseif InputCnt == 3
                            Screen('DrawText',windowC,sprintf('Y, %s',CurrentValue),BRCornerL-200,screenRectC(4)-200,[1023,1023,1023]);
                        end
                        Screen('DrawText',windowC,sprintf('%.4f: Y (Space) or N (Esc)?',ThisI),BRCornerL-200,screenRectC(4)-100,[255 255 255]);
                        Screen('Flip',windowC);


                        while ResponseGiven == 0 %Wait until confirmation
                            [keysDown,secs,keyCode] = KbCheck; %Constantly check for keypress

                            if keyCode(KbName('Space'))

                                %Record input values into matrix
                                if InputCnt == 1
                                    Intensity{ch}( valuebit+1 ) = ThisI;
                                elseif InputCnt == 2
                                    XVals{ch}( valuebit+1 ) = ThisI;
                                elseif InputCnt == 3
                                    YVals{ch}( valuebit+1 ) = ThisI;
                                end
                                ResponseGiven = 1;
                                InputCnt = InputCnt +1;
                                break
                            elseif keyCode(KbName('Escape'))

                                ThisI = []; %Blank and go back to input
                                ResponseGiven = 1;

                            end

                        end
                    else
                        break %break if an input is given
                    end
                end

                Screen('FillRect',windowC,gray);
                Screen('Flip',windowC);
                WaitSecs(0.1);

            end
        end
    end
catch
    sca
    close all
end
sca
close all
Date_Time = datetime;
AllValues = values.*(2^BitDepth); %Bit Values
save(sprintf('Calibration_%s_%sMonitor.mat',room,monitor),'Intensity','XVals','YVals','Date_Time','AllValues');
