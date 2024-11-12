classdef CM700_Color
    %CM700_Color encapsulates the color information provided by the CM700-d
    %from Konika Minolta.
    %
    %   properties
    %       unit            cell array of char arrays (colorimetric unit)
    %       observer        cell array of char arrays (observer function)
    %       illuminant      cell array of char arrays (illuminant)
    %       data            16 x 2 x 11 float array (colorimetric values 
    %                           for all observer functions and illuminants)
    %
    %   public methods
    %       getData         float scalar
    %       merge           Merges multiple CM700_color objects into one
    %       count           Returns int scalar (number of measurements)
    %       XYZ             Returns 3 x 1 float (X, Y, Z)
    %       xyY             Returns 3 x 1 float (x, y, Y)
    %       Lab             Returns 3 x 1 float (L, a*, *b*)
    %       LCh             Returns 3 x 1 float (L, C*, h)
    %       Hunter_Lab      Returns 3 x 1 float (Hunter L, a*, b*)
    %       Munsell_HVC     Returns 3 x 1 float (Munsell hue, val., chroma)
    
    
    properties (GetAccess = public, SetAccess = private)
        unit = {'X', 'Y', 'Z', 'x', 'y', 'L*', 'a*', 'b*', 'C*', 'h', ...
            'Hunter L', 'Hunter a', 'Hunter b', ...
            'Munsell Hue', 'Munsell Value', 'Munsell Chroma'};
        observer = {'2°', '10°'};
        illuminant = {'A', 'C', 'D50', 'D65', 'F2', 'F6', 'F7', 'F8', ...
            'F10', 'F11', 'F12'};
        data
    end
    
        
    methods (Static, Hidden)
        function dim = getDim
            dim = [16, 2, 11];                                              %colorimetric unit, observer function, illuminant
        end
    end
    
    
    methods (Access = public)
        function obj = CM700_Color(data_)
            %CM700_Color: Constructor.
            %
            %   Input:  16 x 2 x 11 float (colorimetric values)
            %   Output: CM700_Color object
            
            dim = CM700_Color.getDim;
            if ~isequal(size(data_), dim)
                error('Input must be a %d x %d x %d float array.', dim);
            end
            
            obj.data = data_;
        end
        
        function obj = merge(obj)
            %merge merges multiple CM700_Color objects into one.
            %
            %   Input:  CM700_Color array
            %   Output: CM700_Color object
            
            if numel(obj) > 1
                data_ = obj(1).data;
                for i = 2 : numel(obj)
                    data_(:, :, :, end + (1 : obj(i).count)) = obj(i).data;
                end
                obj = CM700_Color(data_);
            end
        end
        
        function x = count(obj)
            %count returns size of the fourth dimension of property data, 
            %i.e, the number of measurements.
            %
            %   Output: int scalar
            
            x = size(obj.data, 4);
        end
    
        function x = getData(obj, unit_, observer_, illuminant_)
            %getData returns the demanded colorimetric unit for the 
            %specified type of observer and illuminant.
            %
            %   Input:  char array (unit; X, Y, Z, x, y, L*, a*, b*, C*, 
            %               h, Hunter L, Hunter a, Hunter b, Munsell Hue, 
            %               Munsell Value, Munsell Chroma)
            %           char array (observer; 2°, 10°)
            %           char array (illuminant; A, C, D50, D65, F2, F6, F7,
            %               F8, F10, F11, F12)
            %   Output: float scalar (colorimetric value)
            
            x = obj.data(obj.getIndexUnit(unit_),...
                obj.getIndexObserver(observer_), ...
                obj.getIndexIlluminant(illuminant_));
        end
        
        function x = XYZ(obj, observer_, illuminant_)
            %getData returns the triplet X, Y, Z for the specified type of 
            %observer and illuminant.
            %
            %   Input:  char array (observer; 2°, 10°)
            %           char array (illuminant; A, C, D50, D65, F2, F6, F7,
            %               F8, F10, F11, F12)
            %   Output: 3 x 1 float
            
            x = obj.data(1 : 3, ...
                obj.getIndexObserver(observer_), ...
                obj.getIndexIlluminant(illuminant_));
        end
        
        function x = xyY(obj, observer_, illuminant_)
            %xyY returns the triplet x, y, Y for the specified type of 
            %observer and illuminant.
            %
            %   Input:  char array (observer; 2°, 10°)
            %           char array (illuminant; A, C, D50, D65, F2, F6, F7,
            %               F8, F10, F11, F12)
            %   Output: 3 x 1 float
            
            x = obj.data([4, 5, 2], ...
                obj.getIndexObserver(observer_), ...
                obj.getIndexIlluminant(illuminant_));
        end
        
        function x = Lab(obj, observer_, illuminant_)
            %Lab returns the triplet L*, a*, b* for the specified type of 
            %observer and illuminant.
            %
            %   Input:  char array (observer; 2°, 10°)
            %           char array (illuminant; A, C, D50, D65, F2, F6, F7,
            %               F8, F10, F11, F12)
            %   Output: 3 x 1 float
            
            x = obj.data(6 : 8, ...
                obj.getIndexObserver(observer_), ...
                obj.getIndexIlluminant(illuminant_));
        end
        
        function x = LCh(obj, observer_, illuminant_)
            %LCh returns the triplet L*, C*, h for the specified type of 
            %observer and illuminant.
            %
            %   Input:  char array (observer; 2°, 10°)
            %           char array (illuminant; A, C, D50, D65, F2, F6, F7,
            %               F8, F10, F11, F12)
            %   Output: 3 x 1 float
            
            x = obj.data([6, 9, 10], ...
                obj.getIndexObserver(observer_), ...
                obj.getIndexIlluminant(illuminant_));
        end
        
        function x = Hunter_Lab(obj, observer_, illuminant_)
            %Hunter_Lab returns the triplet Hunter L*, a*, b* for the
            %specified type of observer and illuminant.
            %
            %   Input:  char array (observer; 2°, 10°)
            %           char array (illuminant; A, C, D50, D65, F2, F6, F7,
            %               F8, F10, F11, F12)
            %   Output: 3 x 1 float

            x = obj.data(11 : 13, ...
                obj.getIndexObserver(observer_), ...
                obj.getIndexIlluminant(illuminant_));
        end
        
        function x = Munsell_HVC(obj, observer_, illuminant_)
            %Munsell_HVC returns Munsell Hue, Value, Chroma for the 
            %specified type of observer and illuminant.
            %
            %   Input:  char array (observer; 2°, 10°)
            %           char array (illuminant; A, C, D50, D65, F2, F6, F7,
            %               F8, F10, F11, F12)
            %   Output: 3 x 1 float
            
            x = obj.data(14 : 16, ...
                obj.getIndexObserver(observer_), ...
                obj.getIndexIlluminant(illuminant_));
        end
    end
    
    
    methods (Access = private)
        function i = getIndexUnit(obj, unit_)
            %getIndexUnit returns an index of property unit.
            %
            %   Input:  char array
            %   Output: int scalar
            
            [b, i] = Misc.isInCell(unit_, obj.unit);
            if ~b, error('Invalid colorimetric identifier.'); end
        end
        
        function i = getIndexObserver(obj, observer_)
            %getIndexObserver returns an index of property observer.
            %
            %   Input:  char array
            %   Output: int scalar
            
            [b, i] = Misc.isInCell(observer_, obj.observer); 
            if ~b, error('Invalid observer identifier.'); end
        end
        
        function i = getIndexIlluminant(obj, illuminant_)
            %getIndexIlluminant returns an index of property illuminant.
            %
            %   Input:  char array
            %   Output: int scalar
            
            [b, i] = Misc.isInCell(illuminant_, obj.illuminant);
            if ~b, error('Invalid illuminant identifier.'); end
        end
    end 
end

