classdef CM700_MeasurementData < handle
    %CM700_MeasurementData encapsulates measurement data of the CM-700d 
    %both for normal and stored measurements. CM700_MeasurementData is the
    %base class of CM700_Measurement and CM700_Sample.
    %
    %   properties
    %       name                char array (name of measurement or sample)
    %       time                DateTime object
    %       device              CM700_Device object
    %       condition           CM700_BaseCondition (subclass) object
    %       reflectance         Struct with fields 
    %                               SCI         Spectrum array
    %                               SCE         Spectrum array
    %
    %   public methods
    %       CM700_Measurement   Constructor
    

    properties (GetAccess = public, SetAccess = private)
        name
        time
        device
        condition 
        reflectance
    end
    
    methods
        function obj = CM700_MeasurementData(name_, time_, device_, ...
                condition_, reflectance_)
            %CM700_MeasurementData: Constructor.
            %
            %   Input:  char array (name of sample)
            %           DateTime array
            %           CM700_Device array
            %           CM700_BaseCondition (subclass) object
            %           Spectrum or CM700_Color array
            %   Output: CM700_MeasurementData object
            
            if ~ischar(name_)
                error('First parameter must be a char array.');
            elseif ~Misc.is(time_, 'DateTime', '~isempty')
                error(['Second parameter must be a non-empty DateTime ' ...
                    'array.']);
            elseif ~Misc.is(device_, 'CM700_Device', 'scalar')
                error('Third parameter must be a CM700_Device object.');
            elseif ~Misc.is(condition_, {'isa', 'CM700_BaseCondition'}, ...
                    'scalar')
                error(['Fourth parameter must be a ' ...
                    'CM700_BaseCondition subclass object.']);
            end

            obj.name = name_;
            obj.time = time_;
            obj.device = device_;
            obj.condition = condition_;
            obj.reflectance = obj.toStruct(reflectance_);
            
            %check if number of measurements is equal
            if ~isempty(obj.reflectance.SCI), field = 'SCI';
            else, field = 'SCE';
            end
            if numel(obj.time) ~= obj.reflectance.(field).count
                error(['Incongruent number of measurements for the ' ...
                    'properties time and reflectance (and, if ' ...
                    'defined, color).']);
            end
        end
    end
    
    methods (Access = protected)
        function x = toStruct(obj, x)
            %toStruct transforms property reflectance or color into a 
            %struct with fields SCI and SCE.
            %
            %   Input:  Spectrum OR CM700_Color array
            
            nSpec = obj.condition.specular.count;
            if ~(Misc.is(x, 'CM700_Color') || ...
                    Misc.is(x, 'Spectrum', {'size', 1, nSpec}))
                    error(['Input must be a %d x n CM700_Color or ' ...
                        'Spectrum array.'], nSpec);
            end
            
            %merge measurements
            if size(x, 2) > 1                                               %if there are measurement repetitions
                if nSpec == 1
                    x = Spectrum.merge(x);
                else
                    if Misc.is(x, 'CM700_Color'), tmp = CM700_Color.empty;
                    else, tmp = Spectrum.empty; 
                    end
                    for i = 1 : nSpec
                        tmp(i) = Spectrum.merge(x(i, :));
                    end
                    x = tmp;
                end
            end
            
            %create struct
            if isequal(obj.condition.specular.char, 'SCI')
                x = struct('SCI', x, 'SCE', []);
            elseif isequal(obj.condition.specular.char, 'SCE')
                x = struct('SCI', [], 'SCE', x);
            elseif isequal(obj.condition.specular.char, 'SCI+SCE')
                x = struct('SCI', x(1), 'SCE', x(2));
                if x.SCI.count ~= x.SCE.count
                    error(['Inconsistent number of measurements for ' ...
                        'fields SCI and SCE.']);
                end
            end
        end
    end
end

