%This code will bring up a square and leave it up until you measure the
%luminance and write it down. Pressing space will step to the next setting.
%This will do the same thing on all monitors simultaneously.

clear all; clc; %close all

%Note: Try to measure monitors individually and determine if Psychtoolbox
%is the culprit. Also try to measure patches in photoshop or something
%instead of using Psychtoolbox.

%Record the room name and the monitor being measured
room = 'Periphery';
monitor = 'ExtendedWindow_Left_2_2_23';

SCREEN_X_PIX = 5120;
SCREEN_Y_PIX = 1440;
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
PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer',['disableDithering',1]);
PsychImaging('AddTask', 'General', 'FloatingPoint16Bit');

CWin = ScreenNums(1);
[windowC screenRectC] =PsychImaging('OpenWindow',  CWin,0.5);
Screen('ColorRange', windowC, 1);
black=BlackIndex(windowC);
white=WhiteIndex(windowC);

Screen('TextSize', windowC, 20);
Screen('TextFont', windowC, 'Arial');

BRCornerR = screenRectC(3)-200;
BRCornerC = screenRectC(3)-200 - SCREEN_X_PIX;
BRCornerL = screenRectC(3)-200 - SCREEN_X_PIX - SCREEN_X_PIX;


HideCursor;

values = [2,4,8,16,32,64,round(linspace(128,1024,14))]./1024;
BitdepthTestVals = [507:517]./1024;
values = sort([values BitdepthTestVals]);
Colors = 'RGBK';
try
    for ch=1:4
        Intensity{ch} = [1:1024].*NaN;
        for v = 1:length(values)

    InputCnt = 0; %input counter

            col=zeros(1,3);
            if ch<4
                col(ch)=values(v);
            else
                col=col+values(v);
            end

            value10bit = round(values(v).*1024);
            CurrentValue = sprintf('%s: %d',Colors(ch),value10bit);

            ThisI = []; %blank input value

            while 1
                if isempty(ThisI)

                    ResponseGiven = 0;

                    %Left
                    Screen('FillRect',windowC,gray);
                    Screen('FillRect',windowC,col,StimRectL);
                    Screen('DrawText',windowC,sprintf('Left, %s',CurrentValue),BRCornerL,screenRectC(4)-200,[1023,1023,1023]);

                    %Center
                    Screen('FillRect',windowC,col,StimRectC);
                    Screen('DrawText',windowC,sprintf('Center, %s',CurrentValue),BRCornerC,screenRectC(4)-200,[1023,1023,1023]);

                    %Right
                    Screen('FillRect',windowC,col,StimRectR);
                    Screen('DrawText',windowC,sprintf('Right, %s',CurrentValue),BRCornerR,screenRectC(4)-200,[1023,1023,1023]);
                    Screen('Flip',windowC);


                    %Hang here and wait for input value
                    fprintf('\n');
                    ThisI = input(''); %Wait for input value

                    %Display input value in corner of screen

                    %Left
                    Screen('FillRect',windowC,gray); %background
                    Screen('FillRect',windowC,col,StimRectL); %Stim (text stuff below)
                    Screen('DrawText',windowC,sprintf('%s',CurrentValue),BRCornerL-200,screenRectC(4)-200,[1023,1023,1023]);
                    Screen('DrawText',windowC,sprintf('%.4f: Y (Space) or N (Esc)?',ThisI),BRCornerL-200,screenRectC(4)-100,[255 255 255]);

                    %Center
                    Screen('FillRect',windowC,col,StimRectC);
                    Screen('DrawText',windowC,sprintf('%s',CurrentValue),BRCornerC-200,screenRectC(4)-200,[1023,1023,1023]);
                    Screen('DrawText',windowC,sprintf('%.4f: Y (Space) or N (Esc)?',ThisI),BRCornerC-200,screenRectC(4)-100,[1023,1023,1023]);

                    %Right
                    Screen('FillRect',windowC,col,StimRectR);
                    Screen('DrawText',windowC,sprintf('%s',CurrentValue),BRCornerR-200,screenRectC(4)-200,[1023,1023,1023]);
                    Screen('DrawText',windowC,sprintf('%.4f: Y (Space) or N (Esc)?',ThisI),BRCornerR-200,screenRectC(4)-100,[1023,1023,1023]);
                    Screen('Flip',windowC);

                    while ResponseGiven == 0 %Wait until confirmation
                        [keysDown,secs,keyCode] = KbCheck; %Constantly check for keypress

                        if keyCode(KbName('Space'))
                            Intensity{ch}( value10bit ) = ThisI;
                            ResponseGiven = 1;
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
            WaitSecs(0.5);
        end
    end
catch
    sca
    close all
end
sca
close all
Date_Time = datetime;
AllValues = round(values.*1024);
save(sprintf('Calibration_%s_%sMonitor.mat',room,monitor),'Intensity','Date_Time','AllValues');
