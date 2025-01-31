function CS2000_terminateConnection()
global s

CS2000_setNDFilter(0);

fclose(s);
delete(s);

disp('disconnected');