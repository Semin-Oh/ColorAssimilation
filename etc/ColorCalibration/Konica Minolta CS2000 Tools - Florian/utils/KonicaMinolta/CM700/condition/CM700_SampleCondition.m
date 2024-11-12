classdef CM700_SampleCondition < CM700_BaseCondition
    %CM700_SampleCondition encapsulates the measurement conditions for
    %stored measurements of the Konica Minolta CM-700d. 
    %
    %   properties
    %       target                  int scalar in [1 1000]
    %       custom                  int scalar (0: Standard, 1: Custom)
    %       
    %   inherited properties
    %       area                    CM700_Area object
    %       specular                CM700_Specular object
    %
    %   methods
    %       CM700_SampleCondition   Constructor
    
    properties (GetAccess = public, SetAccess = private)
        target
        custom
    end    
    
    methods
        function obj = CM700_SampleCondition(area_, specular_, target_, ...
                custom_)
            %CM700_SampleCondition: Constructor.
            %
            %   Input:  CM700_Area object
            %           CM700_Specular object
            %           int scalar (target, [1 1000])
            %           int scalar (0 = Standard, 1 = Custom)
            %   Output: CM700_SampleCondition object
            
            obj = obj@CM700_BaseCondition(area_, specular_);
            if ~Misc.is(target_, 'int', 'scalar', [1, 1000])
                error(['Third parameter must be an int scalar in ' ...
                    '[1 1000].']);
            elseif ~Misc.is(custom_, 'int', 'scalar', [0, 1])
                error(['Fourth parameter must be either 0 (standard) ' ...
                    'or 1 (custom).']);
            end
            
            obj.target = target_;
            obj.custom = custom_;
        end
    end
end

