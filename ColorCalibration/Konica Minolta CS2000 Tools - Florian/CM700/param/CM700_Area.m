classdef CM700_Area < KonicaMinoltaParam
    %CM700_Area encapsulates the measurement area parameter of the Konica
    %Minolta CM-700d. Base class is KonicaMinoltaParam.
    %
    %   constant properties
    %       valid           cell array (of char arrays)
    %
    %   inherited properties
    %       int             int scalar
    %       char            char array
    %
    %   methods
    %       CM700_Area      Constructor
    %
    %   inherited methods
    %       isValid         Returns logical scalar
    %       toInt           Returns int scalar
    %       toChar          Returns char array
    
    properties (Constant)
        valid = {'SAV', 'MAV'};
    end
    
    methods
        function obj = CM700_Area(x)
            %CM700_Area: Constructor.
            %
            %   Input:  int scalar OR char array
            %   Output: CM700_Area object
            
            obj = obj@KonicaMinoltaParam(x);
        end
    end
end

