classdef CM700 < handle
    % CM700 provides a Matlab interface to communicate with the
    % spectrophotometer CM-700d and CM-600d from Konika Minolta.
    % All functions are based on the Communication Specifications Rev. 1.33
    % from July 19, 2013 (KMSE A0E8-CS 0133E).
    %
    %   properties 
    %       s                   char array (serial port)
    %       device              CM700_Device object
    %       calibStatus         CM700_CalibStatus object
    %
    %   methods 
    %       CM700               Constructor, establishes connection, sets
    %                               date and time, and reads device info
    %       open                Establishes connection
    %       close               Disconnects device
    %       setTime             Sets date and time on device
    %
    %       getArea             Returns CM700_Area object
    %       getSpecular         Returns CM700_Specular object
    %       getDelay_sec        Returns float scalar (measurement delay)
    %       getNumAuto          Returns int scalar (number of measurements 
    %                               per trigger)
    %       getNumManual        Returns int scalar (number of trigger per 
    %                               measurement)
    %
    %       setSpecular         Sets current specular component setting
    %       setDelay_sec        Sets measurement delay setting
    %       setNumAuto          Sets number of measurements per trigger
    %       setNumManual        Sets number of triggers per measurement
    %
    %       measure             Returns CM700_Measurement object (triggers 
    %                               a measurement and reads measurement 
    %                               data, or reads a remotely triggered 
    %                               measurement)
    %
    %       enableSwitch        Enables measurement switch
    %       disableSwitch       Disables mesaurement switch
    %
    %       getNumSample        Returns int scalar (no. recorded samples)
    %       getSample           Returns CM700_Sample object (stored data)
    %       deleteSample        Deletes sample stored on device
    %       deleteAllSamples    Deletes all samples stored on device
    %
    %       zeroCalib           Performs dark calibration
    %       whiteCalib          Performs white calibration
    %       getCalib            Retruns CM700_Calib object (white calib.)
    %       setCalib            Sets white calibration data
    %       userCalibEnabled    Returns logical scalar (true if user 
    %                               calibration is enabled)
    %
    %       getDevice           Returns CM700_Device object
    %       getStatus           Returns struct (device status)
    %       getTime             Returns DateTime object
    %
    %       send                Returns cell array (of char arrays; sends a
    %                               commmand to the device and returns
    %                               its response)
    %
    %       Call the help of individual functions for details on the input
    %       and output parameters, and check the manual and communication
    %       specification document for more detailed information.
    %
    %   Example 
    %       cm700 = CM700;
    %       x = cm700.measure;
    %       x.reflectance.plot;
    
    properties (GetAccess = public, SetAccess = private)
        s
        device
        calibStatus
    end
    
    %PUBLIC METHODS
    methods (Access = public)

        % INITIALIZATION
        function obj = CM700(varargin)
            %CM700: Constructor. Establishes connection, sets date and
            %time, and reads device info.
            %
            %   Input:  char array (communcation port identifier)
            
            for i = 1 : nargin
                if ischar(varargin{i}) && ~exist('port', 'var')
                    port = varargin{i};
                elseif Misc.is(varargin{i}, 'CM700_Area', 'scalar') && ...
                        ~exist('area', 'var')
                    area = varargin{i};
                else
                    error('%s parameter is invalid.', ...
                        Misc.ordinalNumber(i));
                end
            end
            
            if ~exist('port', 'var')
                if ispc, port = 'COM5';
                elseif ismac || isunix, port = '/dev/tty.usbmodem1421';
                end
            end

            fprintf('Initializing CM700... ');
            obj.open(port);
            obj.setTime;
            fprintf('done.\n');
            obj.device = obj.getDevice;
            obj.device.print;
            
            readArea = obj.getArea.char;
            validArea = CM700_Area.valid;
            if nargin == 2 && ~Misc.is(area, 'CM700_Area', 'scalar')
                error('Second parameter must be a CM700_Area object.');
            end
            if numel(validArea) > 1
                if ~exist('area', 'var')
                    fprintf('\nWhich mask is mounted on the CM700?\n');
                    maskArea = Menu.basic(validArea);
                else
                    maskArea = area.char;
                end
                while ~isequal(readArea, maskArea)
                    input(sprintf(['Switch area slider to %s and ' ...
                        'press Enter.'], maskArea), 's');
                    readArea = obj.getArea.char;
                end
            end
        end
        
        function open(obj, port)
            %open establishes the USB connection to the device.
            %
            %   Input:  char array (communication port identifier)
            
            Misc.closeSerial(port);
            
            obj.s = serial(port);
            obj.s.BaudRate = 115200;
            obj.s.Terminator = 'CR/LF';
            obj.s.InputBufferSize = 1024;
            obj.s.BytesAvailableFcnMode = 'terminator';
            obj.s.Timeout = 60;                                             %maximum measurement time of CM700 is 240 sec.
            
            fopen(obj.s);
            
            obj.calibStatus = CM700_CalibStatus;
        end
        
        function close(obj)
            %close disconnects device.
            
            fclose(obj.s);
            obj.calibStatus.reset;
        end
        
        function setTime(obj, time)
            %setTime sets date and time on device.
            %
            %   Input:  DateTime object (opt.)
            
            if nargin == 1, time = DateTime(clock); end
            if ~Misc.is(time, 'DateTime', 'scalar')
                error('Input must be a DateTime object.');
            end
            obj.send(sprintf('DFS,0'));                                     %set date format to YYYY/MM/DD
            obj.send(sprintf('DTS,%04d,%02d,%02d,%02d,%02d,%02d', ...
                round(time.vec)));                                          %YYYY/MM/DD/HH/MM/SS
        end
        

        % CONDITION
        function x = getCondition(obj)
            %getCondition returns a CM700_Condition object that holds all
            %relevant measurement parameters as well as the current 
            %calibration.
            %
            %   Output: CM700_Condition object
            
            tmp = obj.getMeasParam;
            calib = obj.getCalib;
            x = CM700_Condition(CM700_Area(tmp(1)), ...
                CM700_Specular(tmp(2)), tmp(3), tmp(4), tmp(5), ...
                calib);
        end
        
        function setCondition(obj, x)
            %setCondition writes all relevant measurement parameters as 
            %well as the current calibration.
            %
            %   Input:  CM700_Condition object
            
            if ~Misc.is(x, 'CM700_Condition', 'scalar')
                error('Input must be an CM700_Condition object.');
            end
            
            if ~isequal(x, obj.getCondition)
                completed = false;
                while ~completed
                    if ~isequal(x.area, obj.getArea)
                        fprintf(sprintf(['Mount %s mask, set switch, ' ...
                            'and press Enter.'], x.area.char), 's');
                    else
                        completed = true;
                    end
                end

                obj.setMeasParam([x.area.int x.specular.int x.delay_sec ...
                    x.numAuto x.numManual]);
                obj.setCalib(x.calib);
                fprintf('Condition was set successfully.\n');
            else
                fprintf('Condition is up-to-date.\n');
            end
        end

        
        % GET PARAMETERS
        function x = getArea(obj)
            %getArea reads current measurement area from device.
            %Note: The actual measurement area is determined by the 
            %aperture attached to the device. The value returned by getArea
            %is determined by a manual switch on the device. 
            %
            %   Output: CM700_Area object
            
            tmp = obj.getMeasParam;
            x = CM700_Area(tmp(1));
        end
        
        function x = getSpecular(obj)
            %getSpecular reads specular component setting from device. 
            %This setting determines if the gloss trap is open or closed 
            %during measurement, i.e., if the specular component is 
            %included (SCI) or excluded (SCE). If both is selected 
            %(SCI+SCE), two measurements will be performed per trigger.
            %
            %   Output: CM700_Specular object
            
            tmp = obj.getMeasParam;
            x = CM700_Specular(tmp(2));
        end
        
        function x = getDelay_sec(obj)
            %getDelay_sec reads the the delay between trigger and start of
            %measurement.
            %
            %   Output: float scalar (delay in seconds)

            tmp = obj.getMeasParam;
            x = tmp(3);
        end
        
        function x = getNumAuto(obj)
            %getNumAuto reads number of measurements per trigger.
            %
            %   Ouput: int scalar
            
            tmp = obj.getMeasParam;
            x = tmp(4);
        end
                
        function x = getNumManual(obj)
            %getNumManual reads number of triggers per measurement.
            %
            %   Ouput: int scalar

            tmp = obj.getMeasParam;
            x = tmp(5);
        end

        
        % SET PARAMETERS
        function setSpecular(obj, x)
            %setSpecular sets specular component setting. This setting
            %determines if the gloss trap is open or closed during the
            %measurement, i.e., if the specular component is included (SCI)
            %or excluded (SCE). If both is selected (SCI+SCE), two
            %measurements will be performed per trigger.
            %
            %   Input:  CM700_Specular object
            
            if ~Misc.is(x, 'CM700_Specular', 'scalar')
                error('Input must be a CM700_Specular object.');
            end
            tmp = obj.getMeasParam';
            obj.setMeasParam([tmp(1), x.int, tmp(3 : 5)]);
        end
        
        function setDelay_sec(obj, x)
            %setDelay_sec sets the the delay between trigger and start of
            %measurement.
            %
            %   Input: float scalar (delay in sec; 0 to 3 in steps of 0.1)

            tmp = obj.getMeasParam';
            obj.setMeasParam([tmp(1 : 2), x, tmp(4 : 5)]);
        end
        
        function setNumAuto(obj, x)
            %setNumAuto sets number of measurements performed per
            %trigger. Data will be averaged.
            %
            %   Input:  int scalar (in [1 10])
            
            tmp = obj.getMeasParam';
            obj.setMeasParam([tmp(1 : 3), x, tmp(5)]);
        end
        
        function setNumManual(obj, x)
            %setNumManual sets number of triggers performed per 
            %measurement. Data will be averaged.
            %
            %   Input:  int scalar (in [1 30])
            
            tmp = obj.getMeasParam';
            obj.setMeasParam([tmp(1 : 4), x]);
        end
        
        
        % MEASURE
        function x = measure(obj, varargin)
            %measure triggers a measurement and reads dara, or reads data 
            %of a previously (remotely) triggered measurement.
            %
            %   Input:  Optional parameter pairs (key, value)
            %               num     int scalar (num. of measurements)
            %               name    char array (name of measurement)
            %               color   logical scalar (true = color values
            %                           will be read out; Warning: slow!
            %                           def = false)
            %               remote  logical scalar (true = data of 
            %                           remotely triggered measurement will
            %                           be read, def = false)
            %   Output: CM700_Measurement object
            
            %read measurement conditions
            cond = obj.getCondition;
            if ~obj.calibStatus.get(cond)
                error('White calibration required.');
            end
            
            status = obj.getStatus;
            if ~isequal(status.calib, 'OK')
                warning('CM700:CalibWarning', status.calib);
            end
            
            name = '';
            readColor = false;
            remote = false;
            num = 1;                                                        %number of measurements
            
            if mod(numel(varargin), 2)
                error('Parameters must be defined in key / value pairs.');
            end
            for i = 1 : 2 : numel(varargin)
                if ~ischar(varargin{i})
                    error('Odd parameters must be char arrays.');
                end
                if isequal(varargin{i}, 'num')
                    num = varargin{i + 1};
                    if ~Misc.is(num, 'pos', 'int', 'scalar')
                        error(['Parameter num must be a positive int ' ...
                            'scalar.']);
                    end
                elseif isequal(varargin{i}, 'name')
                    name = varargin{i + 1};
                elseif isequal(varargin{i}, 'color')
                    readColor = logical(varargin{i + 1});
                elseif isequal(varargin{i}, 'remote')
                    remote = logical(varargin{i + 1});
                else
                    error('Unknown parameter %s.', varargin{i});
                end
            end
            if remote && num ~= 1
                error(['No explicit measurement repetitions for ' ...
                    'manually triggered measurements.']);
            end
            
            reflectance = Spectrum.empty;
            if readColor
                color = CM700_Color.empty;
                if remote, commandC = 'RCR';
                else, commandC = 'COR';
                end
                dim = CM700_Color.getDim;                                   %color dim: colorimetric value x observer x illuminant
            end
            
            if remote, commandR = 'RDR';
            else, commandR = 'MDR'; 
            end
            
            c = '';
            fprintf('Measuring... ');
            
            for h = 1 : num
                if num > 1
                    fprintf(repmat('\b', [1, numel(c)]));
                    c = sprintf('%d of %d', h, num);
                    fprintf(c);
                end
                
                t(h) = DateTime(clock);                                     %#ok. Get current date and time

                if ~remote
                    obj.send('MES,1');                                      %start measurement

                    %wait until measurement is completed
                    completed = false;
                    while ~completed
                        pause(.5);
                        try
                            obj.send('STR');
                            completed = true;
                        catch ME
                            if ~isequal(ME.identifier, ...
                                    'CM700:MeasInProgress')
                                error(ME.message);
                            end
                        end
                    end
                end

                %read color data - must be read prior to reflectance
                if readColor
                    clear data
                    m = 1;

                    for i = 1 : cond.specular.count                         %specular mode of measurement
                        for j = 1 : dim(2)                                  %2° or 10° observer
                            for k = 1 : dim(3)                              %illumination - reflectance itself does not have a color
                                for l = 1 : dim(1)                          %colorimetric value
                                    data(l, j, k) = str2double(...
                                        obj.send(sprintf(...
                                        '%s,%d,%d,%02d,%02d', ...
                                        commandC, i, j, k, l)));            %#ok
                                    m = m + 1;
                                end
                            end
                        end
                        color(end + 1) = CM700_Color(data);                 %#ok
                    end
                end
                
                %construct output
                wavelength = obj.getWavelength;
                for i = 1 : cond.specular.count
                    reflectance(end + 1) = Spectrum(wavelength, ...
                        str2double(obj.send(sprintf('%s,%d', commandR, ...
                        i))) / 10^4);                                       %#ok
                end
            end

            fprintf([repmat('\b', [1, numel(c)]) 'done.\n']);
            
            dim = [cond.specular.count num];
            if readColor
                x = CM700_Measurement(name, t, obj.device, cond, ...
                    reshape(reflectance, dim), obj.calibStatus, ...
                    reshape(color, dim));
            else
                x = CM700_Measurement(name, t, obj.device, cond, ...
                    reshape(reflectance, dim), obj.calibStatus);
            end                
        end
        
        
        %MEASURING SWITCH
        function enableSwitch(obj)
            %enableSwitch enables the measuring switch to trigger the
            %measurement manually.
            
            obj.send('SWS,1');
        end
        
        function disableSwitch(obj)
            %disableSwitch disables the measuring switch.
            
            obj.send('SWS,0');
        end
        
        
        % STORED MEASUREMENTS
        function x = getNumSample(obj)
            %getNumSample reads the number of stored samples.
            %
            %   Output: int scalar
            
            x = obj.getStatus.sampleCount;
        end
        
        function x = getSample(obj, idx)
            %getSample reads measurement data from device memory.
            %Note: Color and calib values cannot be retrieved from stored 
            %measurements. 
            %
            %   Input:  int array (sample index)
            %   Output: CM700_Sample object

            obj.checkSampleIndex(idx);

            for i = 1 : numel(idx)
                tmp = obj.send(sprintf('SPR,%d', idx(i)));
                name = tmp{11};
                
                tmp = str2double(tmp(1 : 10));
                cond = CM700_SampleCondition(CM700_Area(tmp(1)), ...
                    CM700_Specular(tmp(2)), tmp(3), tmp(10));
                t = DateTime(tmp(4 : 9));
                
                clear reflectance
                for j = 1 : cond.specular.count
                    reflectance(j, 1) = Spectrum(obj.getWavelength, ...
                        str2double(obj.send(sprintf('SDR,%05d,%d', ...
                        idx(i), j))) / 1e4);                                %#ok
                end
                
                x(i) = CM700_Sample(name, t, obj.device, cond, ...
                    reflectance);                                           %#ok
            end
        end
        
        function deleteSample(obj, idx)
            %deleteSample deletes specified sample(s).
            %
            %   Input:  int array (sample index)
            
            obj.checkSampleIndex(idx);
            if Menu.basic(['Do you really want to delete the ' ...
                    'selected samples?'], 'response', 'yn', 'default', 'n')
                for i = 1 : numel(idx), obj.send('SDD,%d', idx(i)); end
            end
        end
        
        function deleteAllSamples(obj)
            %deleteAllSamples deletes all samples in the device memory.
            
            if Menu.basic(['Do you really want to delete all stored ' ...
                'samples?'], 'response', 'yn', 'default', 'n')
                obj.send('SAD');
            end
        end
        
        
        % CALIB FUNCTIONS
        function zeroCalib(obj)
            %zeroCalib performs a dark (zero) calibration. Place the Zero 
            %Calibration Box CM-A182 on the CM-700d.
            
            obj.send('ZRC');
        end
        
        function whiteCalib(obj)
            %whiteCalib calibrates the illumination. Based on user 
            %calibration if user calibration is enabled.
            
            cond = obj.getCondition;
            time = DateTime(clock);
            
            fprintf('Calibrating... ');
            if cond.calib.userCalib, obj.send('USC');
            else, obj.send('CAL');
            end
            fprintf('done.\n');
            
            obj.calibStatus.set(cond, time);
        end
        
        function x = getCalib(obj)
            %getCalib returns the currently active calibration.
            %
            %   Output: CM700_Calib object
            
            userCalib = obj.userCalibEnabled;
            wavelength = obj.getWavelength;

            if userCalib, command = 'UCR';
            else, command = 'CDR';
            end
            
            spectrum = Spectrum.empty;
            for iarea = 1 : 2
                for ispecular = 1 : 2
                    spectrum(end + 1) = Spectrum(...
                        wavelength, str2double(obj.send(sprintf(...
                        '%s,%d,%d', command, iarea, ispecular))) / 1e5);    %#ok
                end
            end
            
            ID = cell2mat(obj.send('CIR'));
            x = CM700_Calib(ID, userCalib, reshape(spectrum, [2, 2]));
        end
        
        function setCalib(obj, x)
            %setCalib sets the current calibration.
            %
            %   Input: CM700_Calib object

            if ~Misc.is(x, 'CM700_Calib', 'scalar')
                error('Input must be a CM700_Calib object.');
            end
            
            fprintf('Writing calibration %s... ', x.ID);
            if x.userCalib, command = 'UCS';
            else, command = 'CDS'; 
            end
            
            area = CM700_Area.valid;
            specular = CM700_Specular.valid;
            wavelength = obj.getWavelength;
            
            for i = 1 : numel(area)
                for j = 1 : 2
                    tmp = x.reflectance.(area{i}).(specular{j});
                    tmp = tmp.setDomain(wavelength);
                    obj.send(sprintf(['%s,%d,%d' repmat(',%06d', ...
                        [1 31])], command, i, j, ...
                        round(tmp.value * 1e5)));
                end
            end
            
            obj.send(sprintf('CIS,%s', x.ID));                              %set calibration plate ID / name
            obj.send(sprintf('USS,%d', x.userCalib));                       %en/disable user calib
            obj.calibStatus.set(obj.getCondition);                          %update calibration status

            fprintf('done.\n');
        end
        
        function x = userCalibEnabled(obj)
            %userCalibEnabled returns true if user calibration is
            %enabled.
            %
            %   Output: logical scalar
            
            x = str2double(obj.send('USR')) == 1;
        end
        
        
        %INFO
        function x = getDevice(obj)
            %getDevice reads the device information.
            %
            %   Output: CM700_Device object
            
            data = obj.send('IDR');
            
            if isequal(data{1}, '0100'), model = 'CM-700d';
            elseif isequal(data{1}, '0100'), model = 'CM-600d';
            else, error('Unknown model identifier %s.', data{1});
            end
            if isequal(data{4}, '0'), geometry = 'di:8°/de:8°';
            else, error('Unknown geometry %s.', data{4});
            end
            
            ROM = str2double(data{2});
            serial = str2double(data{3});
            x = CM700_Device(model, ROM, serial, geometry);
        end
        
        function x = getStatus(obj)
            %getStatus reads the status information from the device.
            %
            %   Output: Struct with the fields
            %               voltage         char array (normal, warning, 
            %                                   error)
            %               calib           char array (info about missing 
            %                                   or outdated calibration)
            %               dataCapacity    int scalar (max. sample number)
            %               sampleCount     int scalar (no. saved samples)
            %               targetCount     int scalar (no. saved targets)
            %               custom          logical scalar (true = custom, 
            %                                   false = standard)
                 
            tmp = str2double(obj.send('STR'));
            
            x.flashReady = tmp(1) == 1;
            if tmp(2) == 0, x.voltage = 'normal';
            elseif tmp(2) == 1, x.voltage = 'warning';
            elseif tmp(2) == 2, x.voltage = 'error';
            end
            
            if tmp(3) == 0
                x.calib = 'No calibration performed';
            elseif tmp(3) == 1
                x.calib = 'White calibration missing';
            elseif tmp(3) == 2
                x.calib = 'User calibration missing';
            elseif tmp(3) == 3
                if tmp(8) == 0
                    x.calib = 'OK';
                elseif tmp(8) == 1
                    x.calib = 'Re-calibration recommended';
                end
            end
            
            x.dataCapacity = tmp(4);
            x.sampleCount = tmp(5);
            x.targetCount = tmp(6);
            x.custom = tmp(7) == 1;
        end
        
        function x = getTime(obj)
            %getTime reads date and time from the device.
            %
            %   Output: DateTime object
            
            x = DateTime(str2double(obj.send('DTR'))');
        end
        
        
        %SEND COMMANDS, GET DATA
        function x = send(obj, command)
            %send sends a command and reads the response.
            %
            %   Input:  char array (command)
            %   Output: cell array (of char arrays, response)
            
            if nargin == 2, fprintf(obj.s, command); end
            x = strread(fscanf(obj.s), '%s', 'delimiter', ',');             %#ok
            CM700.errorCheck(x{1});
            x = x(2 : end);
        end
    end
    
    
    %PRIVATE METHODS
    methods (Access = private)
        function x = getWavelength(obj)
            %getWavelength returns wavelength array of device.
            %
            %   Output: int array (wavelength in nm)
            
            tmp = obj.send('IDR');
            tmp = str2double(tmp(5 : 7));
            x = tmp(1) : tmp(3) : tmp(2);
        end
        
        function x = getMeasParam(obj)
            %getMeasParam returns integer measurement parameters. 
            %
            %   Output: 1 x 5 float array (coding [measurement area, 
            %               specular mode, delay [sec], num. automatic 
            %               meas., num. manual meas.])
    
            x = str2double(obj.send('CPR'));
            x(3) = x(3) / 10;
        end
        
        function setMeasParam(obj, x)
            %setMeasParam sets measurement parameters.
            %
            %   Input: 1 x 5 float array (coding [measurement area, 
            %               specular mode, delay [sec], num. automatic 
            %               meas., num. manual meas.])
            
            if ~Misc.is(x, 'float', {'numel', 5})
                error('Input must be a 1 x 5 float array.');
            end
            CM700_Condition(x(1), x(2), x(3), x(4), x(5));                  %construct to test for errors
            x(3) = round(x(3) * 10);
            obj.send(sprintf('CPS,%d,%d,%02d,%02d,%02d', x));
        end
        
        function checkSampleIndex(obj, idx)
            %checkSampleIndex throws an error if input does contain invalid
            %sample indices. 
            %   
            %   Input:  int array
            
            n = obj.getNumSample;
            if ~Misc.is(idx, 'int', [1, n])
                error('Sample indices must be an int array in [1 %d].', n);
            end
        end
    end

    
    methods (Static, Hidden)
        function errorCheck(errorCode)
            %errorCheck translates device error code to a matlab warning or
            %error.
            %
            %   Input:  char array (device error code)
            
            iOK = [0, 2, 3, 4, 9] + 1;
            OK.idf(iOK) = ...
                {'CM700:OK' ...
                'CM700:WeakLamp' ...
                'CM700:LowBattery' ...
                'CM700:LowLampOrBattery' ...
                'CM700:ReflectanceTooHigh'};
            OK.msg(iOK) = ...
                {'Command was processed normally.' ...
                'Low xenon lamp illumination.' ...
                'Battery power of instrument is getting low.' ...
                'Low xenon lamp illumination / low battery power.' ...
                'Spectral reflectance exceeds the measurement range.'};
            
            iER = [0, 2, 3, 5, 7, 8, 10, 11, 13, 17, 20, 22, 24, 25, ...
                27, 28, 35, 36, 69] + 1;
            ER.idf(iER) = ...
                {'CM700:InvalCommand' ...
                'CM700:TooLowBattery' ...
                'CM700:InvalParam' ...
                'CM700:LampError' ...
                'CM700:CalibMissing' ...
                'CM700:ComError' ...
                'CM700:NoData' ...
                'CM700:CalibFailed' ...
                'CM700:AD_Error' ...
                'CM700:ClockError' ...
                'CM700:WriteError' ...
                'CM700:UserCalibData' ...
                'CM700:WhiteCalibMissing' ...
                'CM700:WrongArea' ...
                'CM700:ChargeError' ...
                'CM700:PrepInProcess' ...
                'CM700:MeasInProgress' ...
                'CM700:UserCalibIncomplete' ...
                'CM700:TargetProtection'};
            ER.msg(iER) = ...
                {'Invalid command string received.' ...
                'Battery power is too low for measurements.' ...
                'Input parameter error.' ...
                'Xenon lamp flash error.' ...
                ['Zero calibration and white calibration have not ' ...
                'been performed.'] ...
                'Communication error.' ...
                'No data present.' ...
                'Calibration not performed correctly.' ...
                'A/D conversion error.' ...
                'Clock error.' ...
                'Data write error.' ...
                'No user calibration data.' ...
                'White calibration not performed.' ...
                ['Input measurement area and instrument measuring ' ...
                'area setting do not match.'] ...
                'Charge circuit error.' ...
                ['Preparations for next measurement have not been ' ...
                'completed.'] ...
                'Measurement in progress.' ...
                'User calibration not completed.' ...
                'Target data protection status is on.'};
            
            id = str2double(errorCode(3 : 4)) + 1;
            
            if isequal(errorCode(1 : 2), 'OK')
                if ~isempty(OK.idf{id}) && Misc.is(id, [2, numel(OK.idf)])
                    warning(OK.idf{id}, OK.msg{id});
                elseif id ~= 1
                    error('Unknown error check code %s.', errorCode);
                end
                
            elseif isequal(errorCode(1 : 2), 'ER')
                if id <= numel(ER.idf) && ~isempty(ER.idf{id})
                    error(ER.idf{id}, ER.msg{id});
                else
                    error('Unknown error check code %s.', errorCode);
                end
                
            else
                error('Unknown error check code %s.', errorCode);
            end
        end
    end
end

