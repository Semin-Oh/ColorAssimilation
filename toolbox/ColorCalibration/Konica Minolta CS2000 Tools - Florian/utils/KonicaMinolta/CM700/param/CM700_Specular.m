classdef CM700_Specular < KonicaMinoltaParam
    %CM700_Specular encapsulates the specular mode parameter of the Konica 
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
    %       CM700_Specular  Constructor
    %       count           Returns number of specular modi (1 or 2)
    %
    %   inherited methods
    %       isValid         Returns logical scalar
    %       toInt           Returns int scalar
    %       toChar          Returns char array

    properties (Constant)
        valid = {'SCI', 'SCE', 'SCI+SCE'};
    end
    
    methods
        function obj = CM700_Specular(x)
            %CM700_Specular: Constructor.
            %
            %   Input:  int scalar or char array
            %   Output: CM700_Specular object
            
            obj = obj@KonicaMinoltaParam(x);
        end
        
        function x = count(obj)
            %count returns 2 for 'SCI+SCE', and 1 for 'SCI' or 'SCE'.
            %
            %   Output: int scalar
        
            x = ceil(obj.int / 2);
        end
    end
end

