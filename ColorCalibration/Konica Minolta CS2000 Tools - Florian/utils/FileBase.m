classdef (Abstract) FileBase < matlab.mixin.Heterogeneous & handle
    %FileBase is an abstract base class for classes which instances are 
    %supposed to be saved. Base classes are matlab.mixin.Heterogeneous and 
    %handle.
    %
    %   properties
    %       time                DateTime object
    %       path                FilePath object
    %
    %   methods
    %       FileBase            Constructor
    %       reduce              Replaces FileBase props with FilePath obj
    %       getUnreduced        Returns FileBase array
    %       load                Loads FilePath properties
    %       save                Replaces FileBase properties with FilePath 
    %                               objects and saves object

    properties (GetAccess = public, SetAccess = private)
        time
        path
    end
    
    methods (Access = public)
        function obj = FileBase(filename, folder)
            %FileBase: Constructor.
            %
            %   Input:  char array (filename, opt.)
            %           char array (folder, opt.)
            %   Output: FileBase object

            obj.time = DateTime(now);                                       %set property time
            if nargin < 2
                folder = sprintf('%sdata/', FilePath.removeRoot( ...
                    Misc.getPath(class(obj)))); 
            end
            if nargin < 1
                filename = sprintf('%s_%s.mat', class(obj), ...
                    obj.time.toFilename);
            end
            
            %set property path
            obj.path = FilePath(folder, filename);
        end

        function reduce(obj, prop)
            %reduce replaces FileBase properties with FilePath objects.
            %
            %   Input:  (cell of) char array(s)  (properties, def = all)

            allProp = properties(obj);                                      %all property names of object
            valid = ~ismember(allProp, 'path');
            allProp = allProp(valid);                                       %remove property path
            isFilePath = false(1, numel(allProp));                          %true = property is of type FilePath
            isFileBase = false(1, numel(allProp));                          %true = property is of type FileBase
            for i = 1 : numel(allProp)
                if isobject(obj.(allProp{i}))
                    isFilePath(i) = isa(obj.(allProp{i}), 'FilePath');
                    isFileBase(i) = isa(obj.(allProp{i}), 'FileBase');
                end
            end
            
            if nargin > 1
                if ischar(prop), prop = {prop}; end
                if ~(ismember(prop, ...
                        allProp(isFileBase | isFilePath)) && ...
                        numel(prop) == numel(unique(prop)))
                    error(['Input must be one of the following char ' ...
                        'arrays / a unique cell array containing one ' ...
                        'of the following char arrays: %s.'], ...
                        Misc.cellToList( ...
                        allProp(isFileBase | isFilePath), 'and'));
                end
                valid = ismember(prop, allProp(isFileBase));
                prop = prop(valid);                                         %discard names of property which are of type FileBase
            else
                prop = allProp(isFileBase);
            end    
            
            for i = 1 : numel(prop), obj.toggle(prop{i}); end
        end
        
        function save(obj)
            %save calls reduce and saves the object under the path returned
            %by getPath.

            %replace FileBase properties with FilePath arrays
            obj.reduce;

            %determine size of object in bytes
            if Misc.getSize(obj) < 2 * 1024 ^ 3, tag = '-v6';               %< 2GB: save uncompressed (larger file, but faster saving and loading)
            else, tag = '-v7.3';                                            %>= 2GB: save compressed (only option, otherwise error)
            end

            fprintf('Saving %s... ', obj.path.abs);
            obj.path.createFolder;
            save(obj.path.abs, 'obj', tag);
            fprintf('done.\n');
        end
    end
    
    methods (Sealed)
        function x = getUnreduced(obj, x)
            %getUnreduced returns all unique FileBase subclass objects. 
            %Works recursively, i.e., also objects from 
            %sub-(...)-properties will be returned. Called by load.
            %
            %   Input:  arbitrary type
            %           FileBase subclass array (for internal use only)
            %   Output: FileBase subclass array
            
            if nargin < 2, x = FileBase.empty;
            else, x = x(:);
            end
            
            n = numel(obj);
            if n > 1
                for i = 1 : n, x = obj(i).getUnreduced(x); end
            else            
                prop = properties(obj);
                for i = 1 : numel(prop)
                    if isa(obj.(prop{i}), 'FileBase') && ...
                            ~isempty(obj.(prop{i}))
                        x_ = obj.(prop{i});
                        x = [x(:); x_(:)];
                        p = [x.path];
                        relPath = p.rel;
                        if iscell(relPath)
                            [~, iuq] = unique(relPath);                     %unique cannot be directly applied on x because it can be an hetereogeneous array
                            x = x(iuq);                                     %discard redundancies
                        end
                        x = obj.(prop{i}).getUnreduced(x);                  %recursive call
                    end
                end
            end
        end
        
        function unreduced = load(obj, varargin)
            %load loads FilePath properties. Works with arrays.
            %
            %Features:
            %   - selective loading of FilePath properties
            %   - recursive loading (i.e., also sub-(...)-properties)
            %   - selective recursive loading
            %   - copy-by-reference of pre-defined redundant objects
            %   - automatic copy-by-reference of redundant objects in 
            %       recursive loading
            %
            %   Input:      OPTIONAL, IN ARBITRARY ORDER
            %           (cell array of) char array(s) (names of props to  
            %               load; def = all FilePath props except of path)
            %           logical scalar (true = recursive loading, i.e.,
            %               subproperties will be loaded as well, if prop.
            %               names are defined, only those will be loaded 
            %               recursively; def = true)
            %           FileBase array (unreduced objects to be copied by 
            %               reference instead of loading redundant objects,
            %               used for recursive loading only)
            %   Output: FileBase array (unreduced objects, if demanded)
            
            if numel(obj) > 1
                unreduced = FileBase.empty;
                for i = 1 : numel(obj)
                    unreduced = obj(i).load(varargin{:}, unreduced);
                end
                return;
            end

            for i = 1 : numel(varargin)
                errMsg = sprintf('%s parameter is invalid.', ...
                    Misc.ordinalNumber(i));
                if (ischar(varargin{i}) || ...
                        Misc.isCellOf(varargin{i}, 'char'))
                    prop = varargin{i};                                     %no error check here; when property name does not exist, no error is thrown. Allows to define property names that exist in subproperties only
                    if ischar(prop), prop = {prop}; end
                elseif Misc.is(varargin{i}, 'logical', 'scalar')
                    if exist('recursive', 'var'), error(errMsg); end        %#ok
                    recursive = varargin{i};
                elseif isa(varargin{i}, 'FileBase')
                    if exist('unreduced', 'var'), error(errMsg); end        %#ok
                    unreduced = varargin{i}(:);
                else
                    error(errMsg);                                          %#ok
                end
            end

            loadAll = ~exist('prop', 'var');
            if loadAll, prop = properties(obj); end

            if ~exist('recursive', 'var'), recursive = true; end
            if ~exist('unreduced', 'var')
                unreduced = obj.getUnreduced;                               %unreduced Filebase subclass objects are those recursively found in object
            else
                unreduced = obj.getUnreduced(unreduced);                    %... plus those defined as input parameter
            end
            
            for i = 1 : numel(prop)
                if isprop(obj, (prop{i})) && ...
                        ~isequal(prop{i}, 'path') && ...
                        Misc.is(obj.(prop{i}), 'FilePath', '~isempty')
                    if isempty(unreduced)                                   %no unreduced obects found
                        obj.toggle(prop{i});                                 %call toggle to set (= to load) property
                        if recursive
                            unreduced = [unreduced; obj.(prop{i})(:)];       %#ok. Append loaded property to unreduced array
                        end
                    else                                                    %unreduced FileBase objects were defined as input parameter
                        [isInUnreduced, iUnreduced] = ...
                            obj.(prop{i}).isMember([unreduced.path]);       %isInUnreduced: logical array, true if FileBase object to be loaded already exists in unreduced; iUnreduced: corresponding indices in unreduced
                        iUnreduced = iUnreduced(iUnreduced > 0);
                        iLoad = find(~isInUnreduced);                       %indices of elements in value to be loaded (do not exist in unreduced)

                        %load elements of value not contained in unreduced
                        value = FileBase.empty;
                        for j = 1 : numel(iLoad)
                            value(j) = Misc.load(FilePath.appendToRoot( ...
                                 obj.(prop{i})(iLoad(j)).rel), 'FileBase');
                        end
                        if recursive
                            unreduced = [unreduced; value(:)];              %#ok. Append loaded elements of value to unreduced array
                        end

                        value = [value(:); unreduced(iUnreduced)];          %append elements which already existed in unreduced
                        value([iLoad(:); ...
                            Misc.flat(find(isInUnreduced))]) = value;       %#ok. sort value into correct order
                        obj.toggle(prop{i}, value);                         %call toggle to set property to value
                    end
                end
            end
            
            if recursive
                for i = 1 : numel(prop)
                    if isprop(obj, prop{i}) && ...
                            isa(obj.(prop{i}), 'FileBase')
                        for j = 1 : numel(obj.(prop{i}))
                            if loadAll
                                unreduced = ...
                                    obj.(prop{i})(j).load(unreduced);       %load all subproperties (or copy them by reference from unreduced)
                            else
                                unreduced = obj.(prop{i})(j).load(prop, ...
                                    unreduced);                             %load only specified subproperties (or copy them by reference from unreduced)
                            end
                        end
                    end
                end
            end
            
            if nargout == 0, clear unreduced, end                           %clear unreduced to avoid unwanted output on command window
        end
    end
    
    methods (Access = protected)
        function setFolder(obj, folder)
            %setFolder sets path.folder.
            %
            %   Input:  char array (relative or absolute folder)

            obj.path = FilePath(folder, obj.path.filename, true);
        end
        
        function setFilename(obj, filename)
            %setFilename sets property filename.
            %
            %   Input:  char array (filename)
            
            obj.path = FilePath(obj.path.folder, filename, true);
        end

        function setTime(obj, time_)
            %setTime sets property time. Consider using
            %updateTimeAndFilename instead.
            %
            %   Input:  DateTime object
            
            if ~Misc.is(time_, 'DateTime', 'scalar')
                error('Input must be a DateTime object.');
            end
            obj.time = time_;
        end
        
        function updateTimeAndFilename(obj, time_)
            %updateTimeAndFilename sets properties time and filename.
            %
            %   Input:  DateTime object (optional, def = now)

            if nargin < 2, time_ = DateTime(now); end
            if ~Misc.is(time_, 'DateTime', 'scalar')
                error('Input must be a DateTime object.');
            end
            
            obj.time = time_;
            obj.path = FilePath(obj.path.folder, sprintf('%s_%s.mat', ...
                class(obj), obj.time.toFilename));
        end
        
        function val = getToggled(obj, prop, val)
            %getToggled returns the toggled value of a property of type
            %FileBase or FilePath. Toggled means that if the property is a
            %FileBase array, a FilePath array will be returned, and vice 
            %versa. getToggled is called from subclass function toggle, 
            %which has the required permissions to actually toggle (= set) 
            %the corresponding property's value.
            %
            %   Input:  char array (property name)
            %           FileBase subclass array (property value, opt.)
            %   Output: FileBase subclass array (if prop. is FilePath)
            %               OR FilePath array (if property is FileBase)
            
            
            if ~(isprop(obj, prop) && (isa(obj.(prop), 'FileBase') || ...
                     isa(obj.(prop), 'FilePath')))
                error('Input is not a valid property name.');
            end
            
            if isa(obj.(prop), 'FileBase')                                  %FileBase -> FilePath
                if nargin == 3
                    warning('Second parameter is ignored.');
                end
                
                for i = 1 : numel(obj.(prop))
                    if ~exist(obj.(prop)(i).path.abs, 'file')
                        obj.(prop)(i).save;                                 %save elements of property to disk
                    end
                end
                val = [obj.(prop).path];
            else                                                            %FilePath -> FileBase
                if nargin == 3                                              
                    if ~(isa(val, 'FileBase') && ...
                            isequal(obj.(prop), [val.path]))
                        error('Second parameter is invalid.');
                    end
                else
                    val = FileBase.empty;
                    for i = 1 : numel(obj.(prop))
                        val(i) = Misc.load(obj.(prop)(i).abs, 'FileBase');
                    end
                end
            end
        end        
    end
end