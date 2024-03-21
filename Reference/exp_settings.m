
epar.save_path=('./data/'); 
epar.running_path=('.');

%% Eyelink settings

epar.SAMP_FREQ = 1000;
epar.CALIB_TRIALS = 180;
epar.CALIB_X = 5;
epar.CALIB_Y = 3;

%% Screen settings

epar.GAMMA = 1; %1: Gamma correction; 0: No correction
global monxyY 

if epar.GAMMA
    FileC = load('/home/gegenfurtner/Desktop/FRL/LUTFolder/LUT_CenterMonitor_1_27_23.mat');
    FileL = load('/home/gegenfurtner/Desktop/FRL/LUTFolder/LUT_LeftMonitor_1_20_23.mat');
    FileR = load('/home/gegenfurtner//Desktop/FRL/LUTFolder/LUT_RightMonitor_1_24_23.mat');
    load('/home/gegenfurtner//Desktop/FRL/LUTFolder/monxyY.mat');
    epar.GAMMA_TABLEC = FileC.Gammas;
    epar.GAMMA_TABLEL = FileL.Gammas;
    epar.GAMMA_TABLER = FileR.Gammas;

    epar.LUTC = FileC.LUT;
    epar.LUTL = FileL.LUT;
    epar.LUTR = FileR.LUT;
    LUT = [];
    monxyY = monxyY;
end

epar.EXPNAME='CSF';
epar.abort = 0; %Abort flag

%% Monitor Settings 
epar.MONITOR_FREQ = 120;
epar.SCREEN_X_PIX = 5120;
epar.SCREEN_Y_PIX = 1440;
epar.screen_x_cm  = 119.2; %% Update based on manual/curvature
epar.screen_y_cm  = 33.5;
epar.vp_dist_cm   = 100; %Based on chinrest to center
epar.bitdepth = 10; %Bit depth
epar.SCREEN_GAP_cm = 2.5; %Gap between the screens in cm (measured by hand)

%Quick calculation for adjustment from one screen to the next
PXperCM = epar.SCREEN_X_PIX/epar.screen_x_cm; %number of pixels in 1cm
epar.SCREEN_GAP_px = round(epar.SCREEN_GAP_cm * PXperCM);

epar.x_center = (epar.SCREEN_X_PIX/2)*3; % *3 to account for the whole extended window
epar.y_center = epar.SCREEN_Y_PIX/2;

%Window locations for each monitor
WinSize = [0 0 epar.SCREEN_X_PIX epar.SCREEN_Y_PIX];
epar.WinRectL = CenterRectOnPoint(WinSize , (epar.SCREEN_X_PIX*1)-(epar.SCREEN_X_PIX/2) , epar.SCREEN_Y_PIX/2);
epar.WinRectC = CenterRectOnPoint(WinSize , (epar.SCREEN_X_PIX*2)-(epar.SCREEN_X_PIX/2) , epar.SCREEN_Y_PIX/2);
epar.WinRectR = CenterRectOnPoint(WinSize , (epar.SCREEN_X_PIX*3)-(epar.SCREEN_X_PIX/2) , epar.SCREEN_Y_PIX/2);

%% Compute Conversion to visual degree 
epar.XPIX2DEG = atand ((epar.screen_x_cm / epar.SCREEN_X_PIX) / epar.vp_dist_cm);
epar.YPIX2DEG = atand ((epar.screen_y_cm / epar.SCREEN_Y_PIX) / epar.vp_dist_cm);

%% Fixation settings
epar.fixsize = round([0.5 0.6]./epar.XPIX2DEG); % [0.15 0.6]
epar.fix_min = 0.5;
epar.fix_max = 1;
epar.fix_tol = 3;


%% Testing positions for compatibility, comment this
% Screen1_Half = (5120/2 : 5120);
% ScreenGap = 5121:5120+epar.SCREEN_GAP_px;
% Screen2 = ScreenGap(end)+1:(ScreenGap(end)+1)+5120;
% 
% TestRange_R = Screen1_Half(1): Screen2(end);
% TestRange_Deg = length(TestRange_R)*epar.XPIX2DEG;
% TotalRange_Deg = ((5120*3)+(epar.SCREEN_GAP_px*2)) * epar.XPIX2DEG;
% StimSize = 1125; %epar.gabor.size
% StimNum = 6; %6 with 15deg steps, 8 with 10deg steps
% 
% %Stimuli has to be able to be placed in locations that do not exceed edge
% %of screen OR overlap with ScreenGap
% 
% %First, with 10deg steps, the second screen needs to be put at
% %10deg-screengap and not be less than 1! So:
% round(10/epar.XPIX2DEG) - (StimSize/2) - epar.SCREEN_GAP_px; %Has to be more than 1, which is is, so this works!
% 
% %If it works for 10, it'll work for 15. So that's fine.
% 
% %Need to make sure it will fit at edge of screen, for 10deg it does for the
% %first monitor, and it'll be shifted even further left on monitor 2, so
% %that's fine, but what about for fifteen degrees. 
% round(90/epar.XPIX2DEG) - round(epar.SCREEN_X_PIX/2) - epar.SCREEN_GAP_px + (StimSize/2); %rightward edge of stim, has to be less than epar.SCREEN_X_PIX which it is!
% %(Pixel where center of stim is) - (half of first monitor) + (half stim size)
% %Redo it backward (3518 is answer of above):
%  (4642 + epar.SCREEN_GAP_px + (5120/2) - (StimSize/2)) * epar.XPIX2DEG;
% 
% %So it looks like steps of fifteen lets us get out to 90deg with 6 stim
% %positions. Now lets look at timing for QUEST:
% 12*7*3; %Stimpositions (left and right) *  SF's * repetitions
% ceil(50/3); %Number of blocks needed for 100 trials q each position
% 252*17; %Number of trials * number of blocks (so total trials)
% 4284*4; %Total trials * seconds per trial (Number of seconds for total experiment)
% 17136/60; %convert to minutes
% 285.6/60; %Convert to hours

%About 5ish hours for the entire experiment
