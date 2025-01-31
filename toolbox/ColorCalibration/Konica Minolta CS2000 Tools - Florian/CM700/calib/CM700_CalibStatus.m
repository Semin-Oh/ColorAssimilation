classdef CM700_CalibStatus < handle
    %CM700_CalibStatus encapsulates the calibration status of the Konica
    %Minolta CM-700d. It is usd in class CM700 to verify that the
    %calibration is up-to-date.
    %
    %   properties
    %       calib               CM700_Calibration object
    %       time                Struct with fields SAV and MAV, each of 
    %                               which have subfields SCI and SCE which 
    %                               hold a DateTime object
    %
    %   methods
    %       CM700_CalibStatus   Constructor
    %       reset               Sets properties to empty
    %       set                 Sets properties
    %       get                 Returns logical scalar (true = calib match)
    
    properties (GetAccess = public, SetAccess = private)
        calib
        time
    end
    
    methods
        function obj = CM700_CalibStatus
            %CM700_CalibStatus: Constructor.
            %
            %   Output: CM700_CalibStatus object
            
            obj.reset;
        end
        
        function reset(obj)
            %reset clears properties calib and time.
            
            obj.calib = CM700_Calib.empty;
            obj.resetTime;
        end
        
        function set(obj, cond, time_)
            %set sets the calibration status for the given condition.
            %
            %   Input:  CM700_Condition object
            %           DateTime object (optional; if white calib was
            %               performed)
            
            if ~Misc.is(cond, 'CM700_Condition', 'scalar')
                error('First parameter must be a CM700_Condition object.');
            elseif nargin == 3 && ~Misc.is(time_, 'DateTime', 'scalar')
                error('Second parameter must be a DateTime object.');
            end
            
            if ~isequal(cond.calib, obj.calib)
                obj.resetTime;
            end
            if nargin == 3
                if cond.specular.int == 3
                    obj.time.(cond.area.char).SCI = time_;
                    obj.time.(cond.area.char).SCE = time_;
                else
                    obj.time.(cond.area.char).(cond.specular.char) = time_; 
                end
            end
            obj.calib = cond.calib;
        end
        
        function x = get(obj, cond)
            %get returns calibration status for given condition.
            %
            %   Input:  CM700_Condition
            %   Output: logical scalar (true = calibrated)
            
            if ~Misc.is(cond, 'CM700_Condition', 'scalar')
                error('First parameter must be a CM700_Condition object.');
            end
            
            if ~isequal(cond.calib, obj.calib)
                x = false;
            elseif cond.specular.int == 3
                x = ~isempty(obj.time.(cond.area.char).SCI) && ...
                    ~isempty(obj.time.(cond.area.char).SCE);
            else
                x = ~isempty( ...
                    obj.time.(cond.area.char).(cond.specular.char));
            end
        end
    end
    
    methods(Access = private)
        function resetTime(obj)
            %resetTime sets property time to empty.

            tmp = struct('SCI', DateTime.empty, 'SCE', DateTime.empty);
            obj.time = struct('SAV', tmp, 'MAV', tmp);
        end
    end
end
