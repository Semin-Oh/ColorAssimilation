addpath(genpath('C:\Users\exp\Desktop\SequenceTasks\ColorCalibration\Konica Minolta CS2000 Tools - Florian'))


comport='COM4';
cs2000 = CS2000(comport);

% % speed = CS2000_Speed('Manual',CS2000_InternalND('Off'),12.2);
% % cs2000.setSpeed(speed)

speed = CS2000_Speed('Normal',CS2000_InternalND('Off'));
cs2000.setSpeed(speed)

% % [monitorFlipInterval, ~, ~]=Screen('GetFlipInterval',ScreenNumber,100);
monitorFlipInterval = 1/60
sync = CS2000_Sync('Internal', 1/monitorFlipInterval);     %create synchronizaton setting object(60 Hz)
cs2000.setSync(sync); 

X = cs2000.measure;