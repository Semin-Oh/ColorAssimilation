clear all; clc;close all
Screens=Screen('Screens');
ScreenNumber=max(Screens);



PsychImaging('PrepareConfiguration') ;
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible'); % CHECK CHECK CHECK
PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer');


[window rect] = PsychImaging('OpenWindow',  ScreenNumber,0);
% [window rect] = Screen('OpenWindow',  ScreenNumber,0);


values= linspace(100,110,100);


values=values/255;
% values=uint8(values);


hstep=rect(3)/length(values);
for v=1:length(values)
    start=(v-1)*hstep;
    End=start+hstep;
    Screen('FillRect',window,values(v),[start 0 End rect(4)])
end
Screen('Flip',window);

KbWait;

sca