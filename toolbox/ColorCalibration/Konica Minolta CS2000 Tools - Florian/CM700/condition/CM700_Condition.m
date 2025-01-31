classdef CM700_Condition < CM700_BaseCondition
    %CM700_Condition encapsulates the measurement conditions for the Konica
    %Minolta CM-700d. 
    %
    %   properties
    %       delay_sec           float scalar (delay in sec)
    %       numAuto             int scalar (number of automatic 
    %                               measurements; one trigger results in 
    %                               numAuto exposures, result is averaged 
    %                               across exposures)
    %       numManual           int scalar (number of manual measurements; 
    %                               one exposure per trigger, result is 
    %                               averaged after numManual triggers have 
    %                               been done. This allows to move the 
    %                               CM700 between exposures, so that the 
    %                               sample can be measured at different 
    %                               locations or from different directions)
    %       calib               CM700_Calib object
    %
    %   inherited properties
    %       area                CM700_Area object
    %       specular            CM700_Specular object
    %
    %   methods
    %       CM700_Condition     Constructor
    
    properties (GetAccess = public, SetAccess = private)
        delay_sec
        numAuto
        numManual
        calib
    end    
    
    methods
        function obj = CM700_Condition(area_, specular_, ...
                delay_sec_, numAuto_, numManual_, calib_)
            %CM700_Condition: Constructor.
            %
            %   Input:  CM700_Area object
            %           CM700_Specular object
            %           float scalar (delay in sec, [0 3] in 0.1 sec)
            %           int scalar (num. of automatic meas. [1 10])
            %           int scalar (num. of manual meas. [1 30])
            %           CM700_Calib object
            %   Output: CM700_Condition object
            
            obj = obj@CM700_BaseCondition(area_, specular_);
            
            if ~Misc.is(delay_sec_, 'float', 'scalar', [0, 3])
                error('Third parameter must be a float scalar in [0 3].');
            elseif ~Misc.is(numAuto_, 'int', 'scalar', [1, 10])
                error('Fourth parameter must be an int scalar in [1 10].');
            elseif ~Misc.is(numManual_, 'int', 'scalar', [1, 30])
                error('Fifth parameter must be an int scalar in [1 30].');
            elseif ~Misc.is(calib_, 'CM700_Calib', 'scalar')
                error('Sixth parameter must be a CM700_Calib object.');
            end
            
            obj.delay_sec = round(delay_sec_ * 10)/ 10;
            obj.numAuto = numAuto_;
            obj.numManual = numManual_;
            obj.calib = calib_;
        end
    end
end

