%Testing 10bit precision with linux
try
clear all; clc; %close all

%Record the room name and the monitor being measured
room = 'Periphery';
monitor = 'LeftMonitor';
ResponseGiven = 0 ; 

% Center 1024 values: R:24, G:121, B:9.5, K:154
% Left 1024 Values: 

SCREEN_X_PIX = 5120;
SCREEN_Y_PIX = 1440;
RectSize = [0 0 1125 1125];
StimRect = CenterRectOnPoint(RectSize,SCREEN_X_PIX/2,SCREEN_Y_PIX/2);
gray=[0.75 0.75 0.75]; %Rough approximation of ne\Users\ExpComputer\Desktop\FRL\Wide-Field-CSFutral gray based on 8-bit assumption of 192
KbName('UnifyKeyNames');


% Make sure the script is running on Psychtoolbox-3:
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1);
ScreenNums=Screen('Screens');

PsychImaging('PrepareConfiguration');% PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer');


CWin = ScreenNums(1);
[windowC screenRectC] =PsychImaging('OpenWindow',  CWin,0.5);
Screen('ColorRange', windowC, 1);

black=BlackIndex(windowC);
white=WhiteIndex(windowC);

Screen('TextSize', windowC, 20);
Screen('TextFont', windowC, 'Arial');

HideCursor;

   %Center
    Screen('FillRect',windowC,gray); %background
                    Screen('FillRect',windowC,[1024 1024 1024], StimRect); %Stim (text stuff below)
                    Screen('DrawText',windowC,sprintf('%s','NaN'),screenRectC(3)-400,screenRectC(4)-200,[255 255 255]);
                    Screen('Flip',windowC); %flip


                             while ResponseGiven == 0 %Wait until confirmation
                        [keysDown,secs,keyCode] = KbCheck; %Constantly check for keypress

                        if keyCode(KbName('Space'))
                            Intensity{ch}( values(v)*1024 ) = ThisI;
                            ResponseGiven = 1;
                            break
                        elseif keyCode(KbName('Escape'))
                            ThisI = []; %Blank and go back to input
                            ResponseGiven = 1;
                        end

                    end


catch
    sca
    close all
end






