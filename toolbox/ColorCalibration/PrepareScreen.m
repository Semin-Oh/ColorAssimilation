%% 10 or 8 bits
%%%%%%%%%%%%%%%%%%%%%%%%
% UNCHECK FOR 10 BITS
DEBUGGING=0;

%% Screen colour and positions
%%%%%%%
% hard-coded stimulus parameters from previous experiment
% before this was 127 127 127 - but not gamma corrected. Changed to 50 50
% 50 to make it look more consistent?
BgColor     = [0 0 0]/(255); %(1 + (1-DEBUGGING)*254); % mean displayable luminance should be about 50 cd/m^2 (comment from Florian about the screen he used, actual luminance would need to be computed)
BgColor_c = [LUT(round(1023*BgColor(1))+1,1 ) LUT(round(1023*BgColor(2))+1,2 ) LUT(round(1023*BgColor(3))+1,3 )]/1023;
% BgColor_c= [BgColor(1).^(1/rgamma)  BgColor(2).^(1/ggamma)  BgColor(3).^(1/bgamma) ];


if DEBUGGING==1
    BgColor_c=uint8(255*BgColor_c);
end

%% Screen prepare
if DEBUGGING==0
 %     Screen('Preference', 'SkipSyncTests', 1);
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible'); % CHECK CHECK CHECK
    PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer');
    [w, r] = PsychImaging('OpenWindow',  max(Screen('screens')),BgColor_c);
  else
    Screen('Preference', 'SkipSyncTests', 1);
    [w, r] = Screen('OpenWindow',0,BgColor_c*255);
    Screen('DrawText',w,'WARNING::: 8 BITS VERSION!',400,400,[255 0 0])
    Screen('Flip',w)
    WaitSecs(1)
end
HideCursor
