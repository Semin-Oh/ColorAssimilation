%NRB I changed this to be based off of epar.bitdepth

screenNumber=max(Screen('Screens'));
[w r]=Screen('OpenWindow', screenNumber, 0,[],32,2);
gamma(:,1) = 0:((2^epar.bitdepth)-1);
gamma(:,2) = 0:((2^epar.bitdepth)-1);
gamma(:,3) = 0:((2^epar.bitdepth)-1);
gamma = gamma./((2^epar.bitdepth)-1);
Screen('LoadNormalizedGammaTable',w,gamma);
Screen('Close',w);