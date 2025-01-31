classdef FilePath
    %FilePath encapsulates folder and filename of a file that contains
    %a FileBase object. It is used as a property of class FileBase, and
    %replaces a FileBase property after FileBase.reduce was called.
    %
    %   properties
    %       folder          char array (folder rel. to Matlab directory)
    %       filename        char array
    %
    %   methods
    %       FilePath        Constructor
    %       abs             Returns char array array (abs. path)
    %       rel             Returns (cell array of) char array(s) (path 
    %                           rel. to MATLAB directory)
    %       createFolder    Creates folder
    %       isUnique        Returns logical scalar
    %       isMember        Returns logical and int array
    %
    %   operators
    %       ==              Returns logical array
    %       ~=              Returns logical array
    %
    %   static methods
    %       getRoot         Returns char array (path to MATLAB dir)
    %       removeRoot      Returns char array (path without root)
    %       appendToRoot    Returns char array
    %       unique          Returns unique elements of FilePath array
    

    properties (GetAccess = public, SetAccess = private)
        folder
        filename
    end
    
    methods
        function obj = FilePath(folder_, filename_, removeRoot_)
            %FilePath: Constructor.
            %
            %   Input:  char array (folder)
            %           char array (filename)
            %           logical scalar (true = remove Matlab root, 
            %               def = false)
            %   Output: FilePath object

            if nargin < 3, removeRoot_ = false; end
            if ~Misc.isValidFoldername(folder_)
                error(['First parameter must be a non-empty, folder ' ...
                    'name compatible char array.']);
            elseif ~Misc.isValidFilename(filename_, true)
                error(['Second parameter must be a non-empty, ' ...
                    'filename compatible char array with filename ' ...
                    'extension.']);
            elseif ~Misc.is(removeRoot_, 'logical', 'scalar')
                error('Third parameter must be a logical scalar.');
            end
            
            folder_(folder_ == '\') = '/';
            if folder_(end) ~= '/', folder_(end + 1) = '/'; end
            if removeRoot_, folder_ = FilePath.removeRoot(folder_); end

            obj.folder = folder_;
            obj.filename = filename_;
        end
        
        function x = abs(obj)
            %abs returns the full path to the object's file. Works with
            %arrays.
            %
            %   Output: (cell array of) char array(s)
            
            n = numel(obj);
            if n == 1
                x = sprintf('%s%s', FilePath.getRoot, obj.rel);
            else
                x = cell(1, n);
                for i = 1 : n
                    x{i} = sprintf('%s%s', FilePath.getRoot, obj(i).rel);
                end
            end
        end        
        
        function x = rel(obj)
            %rel returns the path to the object's file relative to folder 
            %MATLAB. Works with arrays.
            %
            %   Output: (cell array of) char array(s)
            
            n = numel(obj);
            if n == 1
                x = sprintf('%s%s', obj.folder, obj.filename);
            else
                x = cell(1, n);
                for i = 1 : n
                    x{i} = sprintf('%s%s', obj(i).folder, obj(i).filename);
                end
            end
        end
        
        function createFolder(obj)
            %createFolder creates the folder defined in property folder.
            folder_ = FilePath.appendToRoot(obj.folder);
            if ~exist(folder_, 'dir'), mkdir(folder_); end
        end
        
        function x = isUnique(obj)
            %isUnique returns true if FilePath array does not contain 
            %redundant elements.
            %
            %   Output: logical scalar
            
            if numel(obj) == 1
                x = true;
            else
                relPath = obj.rel;
                x = numel(unique(relPath)) == numel(relPath);
            end
        end
        
        function [found, idx] = isMember(obj, b)
            %isMember wraps the basic functionality of Matlab built-in
            %function ismember to make it work with TetraStim subclass
            %arrays.
            %
            %   Input:  FilePath array
            %   Output: logical array (true = is element)
            %           int array (indices, 0 if not found)
            
            if ~isa(b, 'FilePath')
                error('Input must be a FilePath array.');
            end
            dim = size(obj);
            found = false(dim);
            idx = zeros(dim);
            if ~isempty(b)
                for i = 1 : prod(dim)
                    [found(i), idx(i)] = ismember(obj(i), b);               %the Matlab-builtin ismember function works only element wise here
                end
            end
        end        

        function x = eq(a, b)
            %eq is the == operator.
            %
            %   Input: FilePath array
            
            dim_a = size(a);
            dim_b = size(b); 
            
            if isequal(dim_a, [1, 1]) && prod(dim_b) > 0
                x = false(dim_b);
                for i = 1 : numel(b), x(i) = isequal(a, b(i)); end
            elseif isequal(dim_b, [1, 1]) && prod(dim_a) > 0
                x = false(dim_a);
                for i = 1 : numel(a), x(i) = isequal(b, a(i)); end
            elseif isequal(dim_a, dim_b)
                x = false(dim_a);
                for i = 1 : numel(a), x(i) = isequal(a(i), b(i)); end
            else
                error('Matrix dimensions must agree')
            end
        end
        
        function x = ne(a, b)
            %ne is the ~= operator.
            %
            %   Input: TetraStim subclass array
            
            x = ~(a == b);
        end
    end        
    
    methods (Static)
        function x = getRoot
            %getRoot returns the path to folder MATLAB.
            %
            %   Output: char array
            
            x = Misc.getPath('FilePath.m');
            root = 'MATLAB/';
            i = strfind(x, root);
            x = x(1 : i + numel(root) - 1);
        end
        
        function x = removeRoot(x)
            %removeRoot deletes the root from a path.
            %
            %   Input:  char array (path)
            
            root = FilePath.getRoot;
            x = Misc.minPath(x);
            i = strfind(x, root);
            if isempty(i), return;
            elseif i == 1, x = x(numel(root) + 1 : end);
            else, error('Invalid path %s.', x);
            end
        end
        
        function x = appendToRoot(x)
            %appendToRoot append a char array to the MATLABT root. 
            %
            %   Input:  char array (path relative to root)
            %   Output: char array (full path)
            
            if ~Misc.isValidFoldername(x)
                error(['Input must be a non-empty, folder name ' ...
                    'compatible char array.']); 
            end
            
            x = sprintf('%s%s', FilePath.getRoot, x);
        end
        
        function [x, i] = unique(x)
            %unique returns the unique elements of a FilePath array.
            %
            %   Input:  FilePath array
            %           int array (indices of unique elements)
            %   Output: FilePath array
            
            if ~Misc.is(x, 'FilePath', '~isempty')
                error('Input must be a non-empty FilePath array.');
            end
            
            if numel(x) > 1
                [~, i] = unique(x.abs);
                x = x(i);
            else
                i = 1;
            end
        end
    end
end

