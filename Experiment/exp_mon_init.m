function [ epar ] = exp_mon_init( epar )

%% 10-Bit Screen
%
% Initialize the screen
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer',['disableDithering',1]);
PsychImaging('AddTask', 'General', 'FloatingPoint16Bit');
PsychImaging('PrepareConfiguration');

% PsychImaging('AddTask', 'General', 'FloatingPoint16Bit');
% PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer');
% PsychImaging('AddTask', 'General', 'EnableHDR'); %We don't need floatingpoint16bit or 10bitframebuffer with HDR according to Mario
% PsychImaging('AddTask','General','UseGPGPUCompute','GPUmat');

ScreenNums = Screen('screens');
CWin = ScreenNums(1);
[epar.windowC epar.screenRect] = PsychImaging('OpenWindow',CWin,0.5);
Screen('ColorRange', epar.windowC, 1);
% epar.black=BlackIndex(epar.windowC);
% epar.white=WhiteIndex(epar.windowC);

if epar.GAMMA
    epar.grayC = Correct([0.5 0.5 0.5],epar.bitdepth,epar.LUTC);
    epar.whiteC = Correct([1 1 1],epar.bitdepth,epar.LUTC);
    epar.blackC = Correct([0 0 0],epar.bitdepth,epar.LUTC);
    epar.grayL = Correct([0.5 0.5 0.5],epar.bitdepth,epar.LUTL);
    epar.whiteL = Correct([1 1 1],epar.bitdepth,epar.LUTL);
    epar.blackL = Correct([0 0 0],epar.bitdepth,epar.LUTL);
    epar.grayR = Correct([0.5 0.5 0.5],epar.bitdepth,epar.LUTR);
    epar.whiteR = Correct([1 1 1],epar.bitdepth,epar.LUTR);
    epar.blackR = Correct([0 0 0],epar.bitdepth,epar.LUTR);
else
    epar.gray=[0.5 0.5 0.5];
end
epar.red = [(2^epar.bitdepth)-1 0 0];

Screen('TextFont', epar.windowC, 'Arial');
Screen('TextSize', epar.windowC, 12);

% Commented out temporarily. 'initmon' is not recognized (as of 03/27/24,
% SMO).
% if epar.GAMMA
%     initmon();
% else
%     epar.newGamma = NaN;
%     epar.oldGamma = NaN;
% end

HideCursor;
