classdef CM700_Device
    %CM700_Device encapsulats the basic device information of a Konica
    %Minolta CM-700d.
    %
    %   properties
    %       model           char array (device model)
    %       ROM             char array (ROM version)
    %       serial          int scalar (serial number)
    %       geometry        char array (Illumination and sensor geometry)
    %
    %   methods
    %       CM700_Device    Constructor
    %       print           Prints formatted properties in command window
    
    properties (GetAccess = public, SetAccess = private)
        model
        ROM
        serial
        geometry
    end
    
    methods
        function obj = CM700_Device(model_, ROM_, serial_, geometry_)
            %CM700_Device: Constructor.
            %
            %   Input:  char array (model)
            %           int scalar (variation)
            %           int scalar (7-digit serial number)
            %           char array (geometry)
            %   Output: CM700_Device object
            
            if ~Misc.is(model_,'char', '~isempty')
                error('First parameter must be a non-empty char array.');
            elseif ~Misc.is(ROM_, 'int', 'scalar', [1, 1e7 - 1])
                error(['Second parameter must be a positive 7-digit ' ...
                    'int scalar.']);
            elseif ~Misc.is(serial_, 'int', 'scalar', [0, 1e8 - 1])
                error(['Third parameter must be a positive 8-digit ' ...
                    'int scalar.']);
            elseif ~ischar(geometry_)
                error('Fourth parameter must be a char array.');
            end
            
            obj.model = model_;
            obj.ROM = sprintf('%c.%c%c.%c%c%c%c', num2str(ROM_));
            obj.serial = serial_;
            obj.geometry = geometry_;
        end
        
        function print(obj)
            %print prints the formatted device information in command 
            %window.
            
            fprintf(['Model:\t\t\t%s\nROM:\t\t\t%s\n' ...
                'Serial number:\t%d\nGeometry:\t\t%s\n'], ...
                obj.model, obj.ROM, obj.serial, obj.geometry);
        end
    end
end

