classdef CM700_BaseCondition
    %CM700_BaseCondition encapsulates the measurement conditions
    %measurement area and specular mode of the Konica Minolta CM-700d.
    %CM700_BaseCondition is base class of CM700_Condition and
    %CM700_SampleCondition.
    %
    %   properties
    %       area                    CM700_Area object
    %       specular                CM700_Specular object
    %       
    %   methods
    %       CM700_BaseCondition     Constructor
    
    properties (GetAccess = public, SetAccess = protected)
        area
        specular
    end    
    
    methods
        function obj = CM700_BaseCondition(area_, specular_)
            %CM700_BaseCondition: Constructor.
            %
            %   Input:  CM700_Area object
            %           CM700_Specular object
            %   Output: CM700_BaseCondition object
            
            if ~Misc.is(area_, 'CM700_Area', 'scalar')
                error('First parameter must be a CM700_Area object.');
            elseif ~Misc.is(specular_, 'CM700_Specular', 'scalar')
                error('Second parameter must be a CM700_Specular object.');
            end
            
            obj.area = area_;
            obj.specular = specular_;
        end
    end
end

