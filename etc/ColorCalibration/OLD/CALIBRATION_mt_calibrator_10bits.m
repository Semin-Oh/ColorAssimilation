clear all; clc;close all

%%% check com port number before running! %%%
room = 'Periphery';
SCREEN_X_PIX = 5120;
SCREEN_Y_PIX = 1440;
RectSize = [0 0 1125 1125];
StimRect = CenterRectOnPoint(RectSize,SCREEN_X_PIX/2,SCREEN_Y_PIX/2); % Make two squares so you can measure Contrast
gray=[0.75 0.75 0.75]; %Rough approximation of neutral gray based on 8-bit assumption of 192

% Make sure the script is running on Psychtoolbox-3:
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1);

WaitSecs(2);
t = 0:1/40000:.2;
snd = sin(2*pi*3000*t);
sound(snd,40000);

Screens=Screen('Screens');
ScreenNumber=max(Screens);

PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible'); % CHECK CHECK CHECK
PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer');
[window rect] = PsychImaging('OpenWindow',  ScreenNumber,0);
% [window rect] = Screen('OpenWindow',  ScreenNumber,0);

HideCursor;


CS2000_initConnection('COM3');

%%%% try measuring zero
Screen('FillRect',window,1);
Screen('Flip',window);
WaitSecs(2);
intercept=CS2000_measure();
% sound(snd,40000);


% sca
% error pd


values=linspace(0,1,1024);
% values=linspace(0,1,2);
values=values(2:end);
SPECTRA=nan(401,length(values),4);

for ch=1:4
    for v= 1:length(values)
%         if ch == 1 || ch == 2 || (ch == 3 && v < 921)
%             tmp = 0; %don't do anything in this case
%         else
            col=zeros(1,3);
            if ch<4
                col(ch)=values(v);
            else
                col=col+values(v);
            end
            Screen('FillRect',window,col);
            Screen('DrawText',window,num2str(v),rect(3)-100,rect(4)-100,[255 255 255]);
            Screen('Flip',window);
            WaitSecs(2);
            tmp=CS2000_measure();
            SPECTRA(:,v,ch)=tmp.spectralData;
            time=clock;
            save(['SPECTRA_' room '_' date],'SPECTRA','intercept','time')
            %         sound(snd,40000);
%         end
    end
end
sca
