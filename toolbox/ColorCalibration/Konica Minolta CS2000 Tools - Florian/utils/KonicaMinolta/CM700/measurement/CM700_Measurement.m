classdef CM700_Measurement < CM700_MeasurementData
    %CM700_Measurement encapsulates measurement data of the Konica Minolta
    %CM700-d.
    %
    %   properties
    %       calibStatus         CM700_CalibStatus object
    %       color               Struct with fields 
    %                               SCI         CM700_Color array
    %                               SCE         CM700_Color array
    %
    %   inherited properties
    %       name                char array (name of measurement or sample)
    %       time                DateTime array
    %       device              CM700_Device object
    %       condition           CM700_Condition object
    %       reflectance         Struct with fields 
    %                               SCI         Spectrum array
    %                               SCE         Spectrum array
    %
    %   public methods
    %       CM700_Measurement   Constructor
    

    properties (GetAccess = public, SetAccess = private)
        calibStatus
        color
    end
    
    methods
        function obj = CM700_Measurement(name_, time_, device_, ...
                condition_, reflectance_, calibStatus_, color_)
            %CM700_Measurement: Constructor.
            %
            %   Input:  char array (name)
            %           DateTime array
            %           CM700_Device object
            %           CM700_Condition object
            %           Spectrum array
            %           CM700_color array (optional)
            %   Output: CM700_Measurement object
            

            obj = obj@CM700_MeasurementData(name_, time_, device_, ...
                condition_, reflectance_);

            if ~Misc.is(calibStatus_, 'CM700_CalibStatus', 'scalar')
                error('Sixth parameter must be CM700_CalibStatus object.');
            end
            
            obj.calibStatus = calibStatus_;
            if nargin == 7, obj.color = obj.toStruct(color_); end
            
            %check number of measurements
            if ~isempty(obj.reflectance(1).SCI), field = 'SCI';
            else, field = 'SCE';
            end
            n = [numel(obj.time), obj.reflectance(1).(field).count];
            if nargin == 7, n = [n, obj.color(1).(field).count]; end
            if numel(unique(n)) > 1
                error(['Incongruent number of measurements for the ' ...
                    'properties time and reflectance (and, if ' ...
                    'defined, color).']);
            end
        end
    end
end