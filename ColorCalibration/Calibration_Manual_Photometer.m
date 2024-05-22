%This code will bring up a square and leave it up until you measure the
%luminance and write it down. Pressing space will step to the next setting.
%This will do the same thing on all monitors simultaneously.

clear all; clc; %close all

%Note: Try to measure monitors individually and determine if Psychtoolbox
%is the culprit. Also try to measure patches in photoshop or something
%instead of using Psychtoolbox. 

%Record the room name and the monitor being measured
room = 'Periphery';
monitor = 'LeftMonitor';

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

PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer');
% PsychImaging('AddTask', 'General', 'FloatingPoint16Bit');

LWin = ScreenNums(5);
CWin = ScreenNums(3);
RWin = ScreenNums(4);
Dummy = ScreenNums(2);
[windowC screenRectC] =PsychImaging('OpenWindow',  CWin,0.5);
[windowR screenRectR] =PsychImaging('OpenWindow',  RWin,0.5);
[windowL screenRectL] =PsychImaging('OpenWindow',  LWin,0.5);
% [windowD screenRectD] =PsychImaging('OpenWindow',  Dummy,0.5);
Screen('ColorRange', windowC, 1);
Screen('ColorRange', windowL, 1);
Screen('ColorRange', windowR, 1);
black=BlackIndex(windowC);
white=WhiteIndex(windowC);

Screen('TextSize', windowC, 20);
Screen('TextFont', windowC, 'Arial');
Screen('TextSize', windowL, 20);
Screen('TextFont', windowL, 'Arial');
Screen('TextSize', windowR, 20);
Screen('TextFont', windowR, 'Arial');ScreenNums=Screen('Screens')


HideCursor;
%Is this causing the left screen to be darker for some reason?
% %%%% try measuring zero C
% Screen('FillRect',windowC,gray);
% Screen('FillRect',windowC,zeros(1,3),StimRect);
% Screen('DrawText',windowC,'Measure Zero',screenRectC(3)-200,screenRectC(4)-200,[255 255 255]);
% Screen('Flip',windowC);
% WaitSecs(0.05);
% 
% %%%% try measuring zero L
% Screen('FillRect',windowL,gray);
% Screen('FillRect',windowL,zeros(1,3),StimRect);
% Screen('DrawText',windowL,'Measure Zero',screenRectL(3)-200,screenRectL(4)-200,[255 255 255]);
% Screen('Flip',windowL);
% WaitSecs(0.05);
% 
% %%%% try measuring zero R
% Screen('FillRect',windowR,gray);black=BlackIndex(windowC);

% Screen('FillRect',windowR,zeros(1,3),StimRect);
% Screen('DrawText',windowR,'Measure Zero',screenRectR(3)-200,screenRectR(4)-200,[255 255 255]);
% Screen('Flip',windowR);
% WaitSecs(0.05);
% 
% 
% while 1 %Wait until space is pressed
%     [keysDown,secs,keyCode] = KbCheck; %Constantly check for keypress
%     if keyCode(KbName('Space'))
%         break
%     elseif keyCode(KbName('Escape'))
%         sca
%         close all
%         error('Program Closed')
%     end
% end
% 
% Screen('FillRect',windowC,gray);
% Screen('DrawText',windowC,'',screenRectC(3)-200,screenRectC(4)-200,[255 255 255]);
% Screen('FillRect',windowL,gray);
% Screen('DrawText',windowL,'',screenRectL(3)-200,screenRectL(4)-200,[255 255 255]);
% Screen('FillRect',windowR,gray);
% Screen('DrawText',windowR,'',screenRectR(3)-200,screenRectR(4)-200,[255 255 255]);
% Screen('Flip',windowC);
% WaitSecs(0.05);
% Screen('Flip',windowL);
% WaitSecs(0.05);
% Screen('Flip',windowR);
% WaitSecs(0.05);



values = [2,4,8,16,32,64,round(linspace(128,1024,14))]./1024;
Colors = 'RGBK';
try
    for ch=1:4
        Intensity{ch} = [1:1024].*NaN;
        for v = 1:length(values)
            %         if ch <= 2 %Change these lines and the else/end part to only run specific channels
            %             tmp = 0; %don't do anything in this case
            %         else
            col=zeros(1,3);
            if ch<4
                col(ch)=values(v);
            else
                col=col+values(v);
            end

            CurrentValue = sprintf('%s: %d',Colors(ch),round(values(v)*1024));


            ThisI = []; %blank input value

            while 1
                if isempty(ThisI)

                    ResponseGiven = 0;

                    %Center
                    Screen('FillRect',windowC,gray);
                    Screen('FillRect',windowC,col,StimRect);
                    Screen('DrawText',windowC,sprintf('Center, %s',CurrentValue),screenRectC(3)-200,screenRectC(4)-200,[255 255 255]);
                    Screen('Flip',windowC);
                    WaitSecs(0.05);
                    %Left
                    Screen('FillRect',windowL,gray);
                    Screen('FillRect',windowL,col,StimRect);
                    Screen('DrawText',windowL,sprintf('Left, %s',CurrentValue),screenRectL(3)-200,screenRectL(4)-200,[255 255 255]);
                    Screen('Flip',windowL);
                    WaitSecs(0.05);
                    %Right
                    Screen('FillRect',windowR,gray);
                    Screen('FillRect',windowR,col,StimRect);
                    Screen('DrawText',windowR,sprintf('Right, %s',CurrentValue),screenRectR(3)-200,screenRectR(4)-200,[255 255 255]);
                    Screen('Flip',windowR);
                    WaitSecs(0.05);

                    %Hang here and wait for input value
                    fprintf('\n');
                    ThisI = input(''); %Wait for input value

                    %Display input value in corner of screen
                    %Center

                    Screen('FillRect',windowC,gray); %background
                    Screen('FillRect',windowC,col,StimRect); %Stim (text stuff below)
                    Screen('DrawText',windowC,sprintf('%s',CurrentValue),screenRectC(3)-400,screenRectC(4)-200,[255 255 255]);
                    Screen('DrawText',windowC,sprintf('%.4f: Y (Space) or N (Esc)?',ThisI),screenRectC(3)-400,screenRectC(4)-100,[255 255 255]);
                    Screen('Flip',windowC); %flip
                    WaitSecs(0.05);
                    Screen('FillRect',windowL,gray);
                    Screen('FillRect',windowL,col,StimRect);
                    Screen('DrawText',windowL,sprintf('%s',CurrentValue),screenRectL(3)-400,screenRectL(4)-200,[255 255 255]);
                    Screen('DrawText',windowL,sprintf('%.4f: Y (Space) or N (Esc)?',ThisI),screenRectL(3)-400,screenRectL(4)-100,[255 255 255]);
                    Screen('Flip',windowL);
                    WaitSecs(0.05);
                    Screen('FillRect',windowR,gray);
                    Screen('FillRect',windowR,col,StimRect);
                    Screen('DrawText',windowR,sprintf('%s',CurrentValue),screenRectR(3)-400,screenRectR(4)-200,[255 255 255]);
                    Screen('DrawText',windowR,sprintf('%.4f: Y (Space) or N (Esc)?',ThisI),screenRectR(3)-400,screenRectR(4)-100,[255 255 255]);
                    Screen('Flip',windowR);
                    WaitSecs(0.05);

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
                else
                    break %break if an input is given
                end
            end

            Screen('FillRect',windowC,gray);
            Screen('FillRect',windowL,gray);
            Screen('FillRect',windowR,gray);
            Screen('Flip',windowC);
            WaitSecs(0.05);
            Screen('Flip',windowL);
            WaitSecs(0.05);
            Screen('Flip',windowR);

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
AllValues = round(values .* 1024);
save(sprintf('Calibration_%s_%sMonitor.mat',room,monitor),'Intensity','Date_Time','AllValues');

