%measure with the CS2000 synced to a temporal frequency
cs2000 = CS2000;                        %check com port and call it with it, e.g. cs2000 = CS2000('COM7');
sync = CS2000_Sync('Internal', 60);     %create synchronizaton setting object(60 Hz)
cs2000.setSync(sync);                   %set synchronization
M = cs2000.measure;
M.radiance.plot;