%% Initialze.
clear all; close all

%%
instrfind

%%% check com port number before running!
%%%
room = 'CurvedDisplay';

Screens=Screen('Screens');
ScreenNumber=0;

% PsychImaging('PrepareConfiguration');
% PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible'); % CHECK CHECK CHECK
% PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer');
% [window rect] = PsychImaging('OpenWindow',  ScreenNumber,0);
[window rect] = Screen('OpenWindow',  ScreenNumber,0);

HideCursor;
CS2000_initConnection('/dev/ttyACM0');

%%%% try measuring zero
intercept=CS2000_measure();
Screen('FillRect',window,0);
Screen('Flip',window);

% sca
% error pd

values=linspace(0,255,2^8);
% values=155:255;

% values=linspace(0,1,5);
values=values(2:end);
SPECTRA=nan(401,length(values),4);

for ch=1:4
    for v= 1:length(values)
        col=zeros(1,3);
        if ch<4
            col(ch)=values(v);
        else
            col=col+values(v);
        end
        Screen('FillRect',window,uint8(col));
        Screen('Flip',window);

        tmp=CS2000_measure();
        SPECTRA(:,v,ch)=tmp.spectralData;
        time=clock;
        save(['SPECTRA_' room '_' date],'SPECTRA','intercept','time')
        
        sound(snd,40000);
    end
end
sca
