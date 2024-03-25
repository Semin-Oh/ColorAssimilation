function exp_el_start( el, t, x, y, correctdrift )
%EXP_EL_START Summary of this function goes here
%   Detailed explanation goes here

Eyelink('command','set_idle_mode');
WaitSecs(0.05);
if correctdrift == 1
    drift_success = EyelinkDoDriftCorrection(el, x, y, 1, 1);

    if drift_success ~= 1
        disp(drift_success);
    end
end
Eyelink('command','set_idle_mode');
WaitSecs(0.05);
Eyelink('StartRecording');




Eyelink('command','mark_playback_start');
Eyelink('message', ['TrialID' sprintf('%d',t)]);
WaitSecs(0.1);