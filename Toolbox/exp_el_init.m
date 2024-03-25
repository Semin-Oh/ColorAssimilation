function [ el ] = exp_el_init( epar )
%EXP_INIT_EL Summary of this function goes here
%   Detailed explanation goes here


if EyelinkInit(0)~= 1
    return;
end

% Provide Eyelink with details about the graphics environment
% and perform some initializations. The information is returned
% in a structure that also contains useful defaults
% and control codes (e.g. tracker state bit and Eyelink key values).
el=EyelinkInitDefaults(epar.windowC);
el.backgroundcolour=epar.grayC;
el.foregroundcolour=epar.red;
el.calibrationtargetsize = epar.fixsize(1);%round((0.6./(epar.SCREEN_X_PIX.*epar.XPIX2DEG))*100);
el.calibrationtargetwidth = epar.fixsize(2);%round((0.03./(epar.SCREEN_X_PIX.*epar.XPIX2DEG))*100);
el.targetbeep = 0;
el.feedbackbeep = 0;
EyelinkUpdateDefaults(el);

%%DEFINE CALIBRATION
x = epar.x_center;
% x = epar.SCREEN_X_PIX/2;
y = epar.y_center;
x_off = round(epar.CALIB_X/epar.XPIX2DEG);
y_off = round(epar.CALIB_Y/epar.YPIX2DEG);
calib = sprintf('%d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d',...
    x,y,...
    x,y-y_off,...
    x,y+y_off,...
    x-x_off,y,...
    x+x_off,y,...
    x-x_off,y-y_off,...
    x+x_off,y-y_off,...
    x-x_off,y+y_off,...
    x+x_off,y+y_off);

% %NRB Edited here
Eyelink('command','screen_write_prescale = 1');
Eyelink('command','calibration_type = HV9');
Eyelink('command', 'generate_default_targets = NO');
Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0,0, (epar.SCREEN_X_PIX*3), epar.SCREEN_Y_PIX); %Added
Eyelink('command', sprintf('calibration_targets = %s',calib));
Eyelink('command', sprintf('validation_targets = %s',calib));
Eyelink('command','button_function 1 ''accept_target_fixation''');


% Eyelink('command', 'calibration_area_proportion 0.2 0.2'); %Eyelink has a minimum value as a proportion!
% Eyelink('command', 'validation_area_proportion 0.2 0.2');
% Eyelink('command','generate_default_targets = NO'); %NRB commented these three
% Eyelink('command',sprintf('calibration_targets = %s',calib));
% Eyelink('command',sprintf('validation_targets = %s',calib));
% Eyelink('command','button_function 1 ''accept_target_fixation''');

%%DEFINE DATA TO GET FROM EYELINK
% Eyelink('command','file_sample_data=LEFT, RIGHT, GAZE, AREA');
edfFile=sprintf('e%dv%db%d.edf', epar.experiment,epar.subject,epar.block);
Eyelink('OpenFile', edfFile);
Eyelink('WaitForModeReady', 1000);
