clear all; clc;close all

%%% check com port number before running!
%%%
room = 'Lab103';

% Make sure the script is running on Psychtoolbox-3:
AssertOpenGL;


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
[monitorFlipInterval]=Screen('GetFlipInterval',window);
% [window rect] = Screen('OpenWindow',  ScreenNumber,0);
HideCursor;

%% Port
addpath(genpath('C:\Users\exp\Desktop\SequenceTasks\ColorCalibration\Konica Minolta CS2000 Tools - Florian'))
comport='COM4';

cs2000 = CS2000(comport);
% % speed = CS2000_Speed('Manual',CS2000_InternalND('Off'),12);
% % cs2000.setSpeed(speed)
sync = CS2000_Sync('Internal', 1/monitorFlipInterval);     %create synchronizaton setting object(60 Hz)
cs2000.setSync(sync); 
speed = CS2000_Speed('Normal',CS2000_InternalND('Off'));
cs2000.setSpeed(speed)



%%%% try measuring zero
Screen('FillRect',window,0);
Screen('Flip',window);
WaitSecs(2);
intercept=cs2000.measure;
sound(snd,40000);


% sca
% error pd

values=linspace(0,1,1024);
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
        Screen('FillRect',window,col);
        Screen('Flip',window);
        WaitSecs(2);
        tmp=cs2000.measure;
        SPECTRA(:,v,ch)=tmp.radiance.value;
        time=clock;
        save(['SPECTRA_' room '_' date],'SPECTRA','intercept','time')
%         sound(snd,40000);
    end
end
sca
