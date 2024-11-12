classdef CM700_Calib
    %CM700_Calib encapsulates the calibration data of a calibration normal
    %for spectrometers CM-600d amd CM-700d from Konika Minolta.
    %
    %   properties
    %       ID              char array (calibration ID)
    %       userCalib       logical scalar (true = user calibration normal)
    %       reflectance     struct (with fields SAV and MAV, each of which 
    %                           have subfields SCI and SCE; contain
    %                           reflectance of calibration normal for both 
    %                           measurement areas and specular modes)
    %
    %   methods
    %       CM700_Calib     Constructor
    
    properties (GetAccess = public, SetAccess = private)
        ID
        userCalib
        reflectance
    end
    
    methods
        function obj = CM700_Calib(ID_, userCalib_, reflectance_)
            %CM700_Calib: Constructor. 
            %
            %   Input:  char array (ID, max. 8 char)
            %           logical scalar (true if user calibration flag)
            %               AND
            %           1 x 4 Spectrum (reflectance for each measurement 
            %               area and specular mode in the order SAV/SCI, 
            %               SAV/SCE, MAV/SCI, and MAV/SCE)
            %   Output: CM700_Calib object
            
            
            if ~Misc.is(ID_, 'char', {'numel', '<=', 8})
                error(['First parameter must be a char array with ' ...
                    '8 or less elements.']);
            elseif ~Misc.is(userCalib_, 'logical', 'scalar')
                error('Second parameter must be a single logical scalar.');
            elseif ~Misc.is(reflectance_, 'Spectrum', {'numel', 4})
                error('Third parameter must be a 1 x 4 Spectrum array.');
            end

            if userCalib_, lim = [.5, 1.5];   
            else, lim = [.8, 1.1];
            end
            for i = 1 : 4
                if reflectance_(i).count ~= 1
                    error(['Third parameter must contain only one ' ...
                        'Spectrum per element.']);
                elseif ~Misc.is(reflectance_(i).value, lim)
                    error(['Reflectance values must be in [%d %d].'], lim);
                end
            end
            
            obj.ID = ID_;
            obj.userCalib = userCalib_;
            obj.reflectance.SAV.SCI = reflectance_(1);
            obj.reflectance.SAV.SCE = reflectance_(2);
            obj.reflectance.MAV.SCI = reflectance_(3);
            obj.reflectance.MAV.SCE = reflectance_(4);
        end
    end
end

