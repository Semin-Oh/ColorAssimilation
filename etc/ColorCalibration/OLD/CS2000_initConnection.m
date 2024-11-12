function CS2000_initConnection(comPort)

if nargin < 1
    comPort = 'COM5';
end

global s

if ~isempty(instrfind)
    fclose(instrfind);
    delete(instrfind);
end

try
    s = serial(comPort);
    
    s.Terminator = 'LF';
    s.InputBufferSize = 1024;
    s.BytesAvailableFcnMode = 'terminator';
    s.BytesAvailableFcn = @instrcallback;
    s.Timeout = 240;
    
    fopen(s);
    fprintf(s,'RMTS,1');
    ErrorCheckCode = fscanf(s);
    [tf, errOutput] = CS2000_errMessage(ErrorCheckCode);
    
    if tf == 1
        disp('connected');
    else
        disp(errOutput);
    end
    
    fprintf(s,'MSWE,0');
    ErrorCheckCode = fscanf(s);
    [tf, errOutput] = CS2000_errMessage(ErrorCheckCode);
    
    if tf == 1
        disp('Measuring switch disabled.');
    else
        disp(errOutput);
    end
catch err
    disp(err.message)
    disp('Sorry, no connection.');
    disp('Please choose another COM or make sure that instrument is connected.');
end