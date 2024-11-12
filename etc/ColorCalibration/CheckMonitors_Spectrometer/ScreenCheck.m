try

    clear all;
    close all;
    clc;

    addpath(genpath('/home/gegenfurtner/Desktop/FRL/Wide-Field-CSF'));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NOTES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %ISOLUMINATE TESTS (New. Done Sep 25th, 2023)



    Low = 150;
    High = 158;

    Michelson = (High-Low) / (High+Low)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NOTES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set the contrast to validate that it works
    Box_Contrast = 0.5;
     %Change color of central square to check with spectrometer
    Condition =  2; % 1 for lum, 2 for red-green, 3 for blue-yellow
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

    SCREEN_X_PIX = 5120;
    SCREEN_Y_PIX = 1440;
    screen_x_cm  = 119.2;
    screen_y_cm  = 33.5;

    RectSize = [0 0 750 750];
    StimRectL_l = CenterRectOnPoint(RectSize,SCREEN_X_PIX/2-1000,SCREEN_Y_PIX/2); % Make two squares so you can measure Contrast
    StimRectL_r = CenterRectOnPoint(RectSize,SCREEN_X_PIX/2+1000,SCREEN_Y_PIX/2);
    StimRectC_l = CenterRectOnPoint(RectSize,SCREEN_X_PIX/2-1000+SCREEN_X_PIX,SCREEN_Y_PIX/2); % Make two squares so you can measure Contrast
    StimRectC_r = CenterRectOnPoint(RectSize,SCREEN_X_PIX/2+1000+SCREEN_X_PIX,SCREEN_Y_PIX/2);
    StimRectR_l = CenterRectOnPoint(RectSize,SCREEN_X_PIX/2-1000+SCREEN_X_PIX+SCREEN_X_PIX,SCREEN_Y_PIX/2); % Make two squares so you can measure Contrast
    StimRectR_r = CenterRectOnPoint(RectSize,SCREEN_X_PIX/2+1000+SCREEN_X_PIX+SCREEN_X_PIX,SCREEN_Y_PIX/2);
    WinSize = [0 0 SCREEN_X_PIX SCREEN_Y_PIX];
    WinRectL = CenterRectOnPoint(WinSize , (SCREEN_X_PIX*1)-(SCREEN_X_PIX/2) , SCREEN_Y_PIX/2);
    WinRectC = CenterRectOnPoint(WinSize , (SCREEN_X_PIX*2)-(SCREEN_X_PIX/2) , SCREEN_Y_PIX/2);
    WinRectR = CenterRectOnPoint(WinSize , (SCREEN_X_PIX*3)-(SCREEN_X_PIX/2) , SCREEN_Y_PIX/2);


    FileC = load('LUT_CenterMonitor_1_27_23.mat');
    %FileC = load('LUT_CenterMonitor_1_27_23_Modified_R975.mat');
    FileL = load('LUT_LeftMonitor_1_20_23.mat');
    FileR = load('LUT_RightMonitor_1_24_23.mat');

    load('/home/gegenfurtner/Desktop/FRL/LUTFolder/monxyY.mat');

    global LUT
    global monxyY

    GAMMA_TABLEC = FileC.Gammas;
    LUTL = FileL.LUT;
    LUTC = FileC.LUT;
    LUTR = FileR.LUT;
    LUT = []; %swap this out with LRC as needed before calling correct



    %% Copied from exp_mon_init
    %     PsychImaging('PrepareConfiguration');
    %     PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer',['disableDithering',1]);
    %     PsychImaging('AddTask', 'General', 'FloatingPoint16Bit');
    % PsychImaging('AddTask','General','EnableHDR');

    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer',['disableDithering',1]);
    PsychImaging('AddTask', 'General', 'FloatingPoint16Bit');
    PsychImaging('PrepareConfiguration');

    ScreenNums = Screen('screens');
    CWin = ScreenNums(1);

    [windowC screenRect] =PsychImaging('OpenWindow',  CWin,0.5);



    Screen('ColorRange', windowC, 1);
    black=BlackIndex(windowC);
    white=WhiteIndex(windowC);
    MonitorL = 'LeftMonitor';
    MonitorR = 'RightMonitor';
    MonitorC = 'CenterMonitor';


    if 1
        Low_Contrast = [0.5-Box_Contrast/2];
        High_Contrast = [0.5+Box_Contrast/2];

        if Condition == 1

            %%% AG adjusted Correct function to reduce reliance on global
            %%% variables, feel free to change

            %Left
            LUT = LUTL;
            grayL = Correct([0.5 0.5 0.5],10,LUTL);
            LeftL = Correct([Low_Contrast Low_Contrast Low_Contrast],10,LUTL);
            RightL = Correct([High_Contrast High_Contrast High_Contrast],10,LUTL);
            LUT = [];

            %Center
            LUT = LUTC;
            grayC = Correct([0.5 0.5 0.5],10,LUTC);
            LeftC = Correct([Low_Contrast Low_Contrast Low_Contrast],10,LUTC);
            RightC = Correct([High_Contrast High_Contrast High_Contrast],10,LUTC);
            LUT = [];

            %Right
            LUT = LUTR;
            grayR = Correct([0.5 0.5 0.5],10,LUTR);
            LeftR = Correct([Low_Contrast Low_Contrast Low_Contrast],10,LUTR);
            RightR = Correct([High_Contrast High_Contrast High_Contrast],10,LUTR);
            LUT = [];

        elseif Condition ==2

            % For now assume the same color correction for all monitors

            RGB_Left= squeeze(single(DKL2RGBMAT(0,0, Low_Contrast-0.5))); % Make it 3D
            RGB_Right= squeeze(single(DKL2RGBMAT(0,0, High_Contrast-0.5))); % Make it 3D

            % Build stimuli
            grayL = Correct([0.5 0.5 0.5],10,LUTL);
            grayC = Correct([0.5 0.5 0.5],10,LUTC);
            grayR = Correct([0.5 0.5 0.5],10,LUTR);

            LeftC = Correct([RGB_Left'],10,LUTC);
            RightC = Correct([RGB_Right'],10,LUTC);
            LeftL = Correct([RGB_Left'],10,LUTL);
            RightL = Correct([RGB_Right'],10,LUTL);
            LeftR = Correct([RGB_Left'],10,LUTR);
            RightR = Correct([RGB_Right'],10,LUTR);

        elseif Condition == 3

            % For now assume the same color correction for all monitors
            RGB_Left= squeeze(single(DKL2RGBMAT(0,90, Low_Contrast-0.5))); % Make it 3D
            RGB_Right= squeeze(single(DKL2RGBMAT(0,90, High_Contrast-0.5))); % Make it 3D

            grayL = Correct([0.5 0.5 0.5],10,LUTL);
            grayC = Correct([0.5 0.5 0.5],10,LUTC);
            grayR = Correct([0.5 0.5 0.5],10,LUTR);

            LeftC = Correct([RGB_Left'],10,LUTC);
            RightC = Correct([RGB_Right'],10,LUTC);
            LeftL = Correct([RGB_Left'],10,LUTL);
            RightL = Correct([RGB_Right'],10,LUTL);
            LeftR = Correct([RGB_Left'],10,LUTR);
            RightR = Correct([RGB_Right'],10,LUTR);



        else
            sca;
            error ('Enter a valid condition')

        end



        %     white=Correct([1 1 1],10);
    else
        gray=[0.5 0.5 0.5];
    end
    red = [(2^10)-1 0 0];

    Screen('TextFont', windowC, 'Arial');
    Screen('TextSize', windowC, 12);
    if 1
        initmon();
    else
        newGamma = NaN;
        oldGamma = NaN;
    end
    HideCursor;


    %% Show stuff (mostly copied from exp_show_image

    KbName('UnifyKeyNames')
    Screen('TextSize', windowC, 20);
    Screen('TextFont', windowC, 'Arial');
    addpath(genpath('./FastCSF_Functions/'));

    % Fixation Screen
    Screen('FillRect',windowC,grayL, WinRectL);
    Screen('FillRect',windowC,grayC, WinRectC);
    Screen('FillRect',windowC,grayR, WinRectR);
    %Screen('FillRect',windowC,grayC);

    %Make circles with specified color
    Screen('FillOval',windowC,LeftL,StimRectL_l)
    Screen('FillOval',windowC,RightL,StimRectL_r)
    Screen('FillOval',windowC,LeftC,StimRectC_l)
    Screen('FillOval',windowC,RightC,StimRectC_r)
    Screen('FillOval',windowC,LeftR,StimRectR_l)
    Screen('FillOval',windowC,RightR,StimRectR_r)
    DrawFormattedText(windowC, sprintf('Center, Contrast :%.2f',Box_Contrast), 'center',SCREEN_Y_PIX/2+300, white);


    Screen('Flip',windowC);



    while 1 %wait for keypress
        [keysDown,secs,keyCode] = KbCheck; %Constantly check for keypress
        %If left or right arrow, record response and break

        if keyCode(KbName('Space'))
            sca
            close all
            break
        end
    end

catch %In case things get bonked
    sca
    close all
    lasterror
end

%Figure to compare all the LUT`s
%load('LUT_LeftMonitor_1_27_23.mat')
%LUTL = LUT;
%load('LUT_CenterMonitor_1_20_23.mat')
%LUTC = LUT;
%load('LUT_RightMonitor_1_24_23.mat')
%LUTR = LUT;

%Compare the 4 channels
%figure;
%subplot(4,1,1)
%plot(LUTL(:,1));
%hold on
%plot(LUTC(:,1));
%hold on
%plot(LUTR(:,1));
%title('Red')
%legend('Left','Center','Right','Location','Best')
%xlim([0 1023])
%ylim([0 1023])

%subplot(4,1,2)
%plot(LUTL(:,2));
%hold on
%plot(LUTC(:,2));
%hold on
%plot(LUTR(:,2));
%title('Green')
%xlim([0 1023])
%ylim([0 1023])

%subplot(4,1,3)
%plot(LUTL(:,3));
%hold on
%plot(LUTC(:,3));
%hold on
%plot(LUTR(:,3));
%title('Blue')
%xlim([0 1023])
%ylim([0 1023])

%subplot(4,1,4)
%plot(LUTL(:,4));
%hold on
%plot(LUTC(:,4));
%hold on
%plot(LUTR(:,4));
%title('Gray')
%xlim([0 1023])
%ylim([0 1023])

%Compare the 3 monitors
%figure;
%subplot(3,1,1);
%plot(LUTL(:,1),'r');
%hold on
%plot(LUTL(:,2),'g');
%hold on
%plot(LUTL(:,3),'b');
%hold on
%plot(LUTL(:,4),'k');
%title('Left')
%xlim([0 1023])
%ylim([0 1023])

%subplot(3,1,2)
%plot(LUTC(:,1),'r');
%hold on
%plot(LUTC(:,2),'g');
%hold on
%plot(LUTC(:,3),'b');
%hold on
%plot(LUTC(:,4),'k');
%title('Center')
%xlim([0 1023])
%ylim([0 1023])


%subplot(3,1,3)
%plot(LUTR(:,1),'r');
%hold on
%plot(LUTR(:,2),'g');
%hold on
%plot(LUTR(:,3),'b');
%hold on
%plot(LUTR(:,4),'k');
%title('Right');
%xlim([0 1023])
%ylim([0 1023])
