function colordata = CS2000_measure()

global s

ERROR_OCCURRED = 0;

% start measurement
fprintf(s,'MEAS,1');
answer = fscanf(s);
ErrorCheckCode = strsplit(answer,',');
[tf, errOutput] = CS2000_errMessage(ErrorCheckCode);
if tf == 1
    ErrorCheckCode = fscanf(s,'%s');
    [tf, errOutput] = CS2000_errMessage(ErrorCheckCode);
    if tf == 1
        disp('');
    else
        disp(errOutput);
    end
else
    disp(errOutput);
end

% read spectral data 380...780nm from instrument
p = 1;
spectralData = zeros(401,1);
for n = 1:4
	fprintf(s,['MEDR,1,0,', num2str(n)]);
	answer = fscanf(s);
    spectrum = strsplit(answer,',');
    [tf, errOutput] = CS2000_errMessage(spectrum{1});
    if tf ~= 1
        disp(errOutput);
    else
        if n == 4
            l = 101;
        else
            l = 100;
        end
        for m = 1:l
            spectralData(p+m-1) = str2double(spectrum{m+1});
        end
    end
    p = p+100;
end

if length(spectralData) < 401
    ERROR_OCCURRED = 1;
    disp('error reading spectral data');
end

% Read Colorimetric data
fprintf(s,'MEDR,2,0,00');
answer = fscanf(s);
color = strsplit(answer,',');
[tf, errOutput] = CS2000_errMessage(color{1});
if tf ~= 1
    disp(errOutput);
end

if ~ERROR_OCCURRED
    colordata = struct('Le', str2double(color{2}),...
                       'Lv', str2double(color{3}),...
                       'X', str2double(color{4}),...
                       'Y', str2double(color{5}),...
                       'Z', str2double(color{6}),...
                       'x', str2double(color{7}),...
                       'y', str2double(color{8}),...
                       'u', str2double(color{9}),...
                       'v', str2double(color{10}),...
                       'T', str2double(color{11}),...
                       'delta_uv', str2double(color{12}),...
                       'lambda_d', str2double(color{13}),...
                       'Pe', str2double(color{14}),...
                       'X10', str2double(color{15}),...
                       'Y10', str2double(color{16}),...
                       'Z10', str2double(color{17}),...
                       'x10', str2double(color{18}),...
                       'y10', str2double(color{19}),...
                       'u10', str2double(color{20}),...
                       'v10', str2double(color{21}),...
                       'T10', str2double(color{22}),...
                       'delta_uv10', str2double(color{23}),...
                       'lambda_d10', str2double(color{24}),...
                       'Pe10', str2double(color{25}),...
                       'spectralData',spectralData);
else
    disp('error');
end