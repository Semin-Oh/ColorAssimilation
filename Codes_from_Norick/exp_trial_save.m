function exp_trial_save( epar, tn )
%EXP_SAVE_TRIAL Summary of this function goes here
%   Detailed explanation goes here

fid = fopen(epar.log_file,'a');
fprintf(fid,'%d\t%d\t%d\t%d\t%.2f\t%.5f\n',...
    epar.experiment,...
    epar.subject,...
    epar.block,...
    tn,...
    epar.trial.sf(tn),...
   epar.trial.responses(tn));
fclose(fid);
