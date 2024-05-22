% Set the contrast to validate that it works
Box_Contrast = 0.25; %Change color of central square to check with spectrometer
Condition = 3; % 1 for lum, 2 for red-green, 3 for blue-yellow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Center = 1;
Left = 0;
Right =1; 
Dummy = 0; 


SCREEN_X_PIX = 5120;
SCREEN_Y_PIX = 1440;
screen_x_cm  = 119.2;
screen_y_cm  = 33.5;

RectSize = [0 0 750 750];
StimRect_l = CenterRectOnPoint(RectSize,SCREEN_X_PIX/2-1000,SCREEN_Y_PIX/2); % Make two squares so you can measure Contrast
StimRect_r = CenterRectOnPoint(RectSize,SCREEN_X_PIX/2+1000,SCREEN_Y_PIX/2);


PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint16Bit');
PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer');
% PsychImaging('AddTask','General','EnableHDR');
ScreenNums = Screen('screens'); %Note: Screen 0 is whole desktop, 1 is center, 2 is left, 3 is right (this isn't the same as Windows->Display Settings!)
% LWin = ScreenNums(4); % Before change by AG
% CWin = ScreenNums(3);
% RWin = ScreenNums(5);
% Dummy = ScreenNums(2);
LWin = ScreenNums(3);
CWin = ScreenNums(2);
RWin = ScreenNums(4);
Dummy = ScreenNums(3);

if Center
[windowC screenRect] =PsychImaging('OpenWindow',  CWin,0.5);
end 
if Right
[windowR screenRectR] =PsychImaging('OpenWindow',  RWin,0.5);
end
if Left
[windowL screenRectL] =PsychImaging('OpenWindow',  LWin,0.5);
end
if Dummy
[windowDumb screenRectD] =PsychImaging('OpenWindow',  Dummy,0.5);
end
Screen('ColorRange', windowC, 1);
% Screen('ColorRange', windowL, 1);
% Screen('ColorRange', windowR, 1);
% black=BlackIndex(windowC);
white=[1 1 1];
MonitorL = 'LeftMonitor';
MonitorR = 'RightMonitor';
MonitorC = 'CenterMonitor';


Low_Contrast = [0.5-Box_Contrast/2];
High_Contrast = [0.5+Box_Contrast/2];

grayL = [0.5 0.5 0.5];
LeftL= [Low_Contrast Low_Contrast Low_Contrast];
RightL =[High_Contrast High_Contrast High_Contrast];

grayC = [0.5 0.5 0.5];
LeftC= [Low_Contrast Low_Contrast Low_Contrast];
RightC =[High_Contrast High_Contrast High_Contrast];

grayR = [0.5 0.5 0.5];
LeftR= [Low_Contrast Low_Contrast Low_Contrast];
RightR =[High_Contrast High_Contrast High_Contrast];


KbName('UnifyKeyNames')
Screen('TextSize', windowC, 20);
Screen('TextFont', windowC, 'Arial');
addpath(genpath('./FastCSF_Functions/'));

% Fixation Screen
if Center 
Screen('FillRect',windowC,grayC );
Screen('FillOval',windowC,LeftC,StimRect_l)
Screen('FillOval',windowC,RightC,StimRect_r)
DrawFormattedText(windowC, sprintf('Center, Contrast :%.2f',Box_Contrast), 'center',SCREEN_Y_PIX/2+300, white);

Screen('Flip',windowC);
end 
if Left 
Screen('FillRect',windowL,grayL );
Screen('FillOval',windowL,RightL,StimRect_r)
Screen('FillOval',windowL,LeftL,StimRect_l)
DrawFormattedText(windowL, sprintf('Left, Contrast :%.2f',Box_Contrast), 'center',SCREEN_Y_PIX/2+300, white);
Screen('Flip',windowL);
end 

if Right 
Screen('FillRect',windowR,grayR );
Screen('FillOval',windowR,LeftR,StimRect_l)
Screen('FillOval',windowR,RightR,StimRect_r)
DrawFormattedText(windowR, sprintf('Right, Contrast :%.2f',Box_Contrast), 'center',SCREEN_Y_PIX/2+300, white);
Screen('Flip',windowR);

end

%Make circles with specified color




while 1 %wait for keypress
    [keysDown,secs,keyCode] = KbCheck; %Constantly check for keypress
    %If left or right arrow, record response and break

    if keyCode(KbName('Space'))
        sca
        close all
        break
    end
end


