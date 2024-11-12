classdef CM700_Sample < CM700_MeasurementData
    %CM700_Sample encapsulates sample (stored measurement) data of the
    %Konica Minolta CM700-d.
    %
    %   inherited properties
    %       name            char array (name of measurement or sample)
    %       time            DateTime object
    %       device          CM700_Device object
    %       condition       CM700_SampleCondition object
    %       reflectance     Spectrum object
    %
    %   public methods
    %       CM700_Sample   Constructor
    

    methods
        function obj = CM700_Sample(name_, time_, device_, ...
                condition_, reflectance_)
            %CM700_Sample: Constructor.
            %
            %   Input:  char array (name of sample)
            %           DateTime object
            %           CM700_Device object
            %           CM700_Condition object
            %           Spectrum object
            %   Output: CM700_Sample object
            

            obj = obj@CM700_MeasurementData(name_, time_, device_, ...
                condition_, reflectance_);
            if ~Misc.is(obj.condition, 'CM700_SampleCondition', 'scalar')
                error(['Fourth parameter must be a ' ...
                    'CM700_SampleCondition object.']);
            end
        end
    end
end