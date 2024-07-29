function [xc y1c y2c] = commondomain(x1, y1, x2, y2)
%COMMONDOMAIN  Interpolate and determine common domain of two ranges
%
%[XC Y1C Y2C] = COMMONDOMAIN(X1, Y1, X2, Y2)
%For two mappings of in domain x1 with range y1, and domain x2 with range
%y2, determine the common domain XC of X1 and X2 and the corresponding
%values of Y1 and Y2 for this domain.
%
% Before the domains are matched, the domains are interpolated for each
% whole number. The function COMMONDOMAIN works only if X1 and X2 are
% strictly monotonically increasing lists of whole numbers.   
%
% Example:
% Judd color matching functions Y1 given between 370 and 770 nm, at 10nm
% interval, i.e, X1 = [370:10:770].
% Spectra Y2 as returned by the PR650 Photometer are between 380 and 780 nm
% in steps of 4nm, i.e., X2 = [380:4:780];  
% COMMONDOMAIN(X1, Y1, X2, Y2) then returns values in the domain 370 to
% 770 nm at 1nm resolution.
%
% Thorsten Hansen 2009-10-15
  
% History
% 2009-10-15 fix of different return formats (row vs. column vector)
%            depending on the number of rows in Y2 (thanks to Martin
%            Giesel for reporting inconsistencies); subfunction
%            interpolate_if_necessary added; help added  
% 2009-09    half way fix of return formats 
% 2007       first edit
  


% interpolate y1 and y2 at 1nm interval if not already given at 1nm interval
%disp('1')
%disp('size of y1 before interpolate if necessary'), size(y1)
[x1 y1] = interpolate_if_necessary(x1, y1);
%disp('size of y1 AFTER interpolate if necessary'),size(y1)

%size(y2)
%disp('2')
[x2 y2] = interpolate_if_necessary(x2, y2);
%size(y2)


% determine common range xc
% (e.g., the wavelengths common to x1 and x2)
xc = [max([x1(1) x2(1)]):min([x1(end) x2(end)])];

% determine common domains y1c and y2c
% (e.g., the corresponding spectra)
%size(y1)
if size(y1, 1) == 1
  error('Internal error: y2 should be a column vector after ''interpolate_if_necessary'' .')
else
%   y1c = y1(ismember(x1, (xc)), :);
    y1c = y1(ismember(x1, round(xc)), :); % round add : MT 29/11/2015
end

if size(y2, 1) == 1
  error('Internal error: y2 should be a column vector after ''interpolate_if_necessary'' .')
else
  y2c = y2(ismember(x2, xc), :);
end


%rangestr(xc)
%diff(x1)
%diff(x2)


% ------------------------------------------------------------------------------
function [x y] = interpolate_if_necessary(x, y)
% ------------------------------------------------------------------------------
if max(diff(x)) > 1
  % disp('interp1')
  xi = x(1):x(end);
  y = interp1(x, y, xi, 'spline');
  x = xi;
end
% force of column vector, but only if not a matrix
if min(size(y)) == 1, y = y(:); end


% force of column vector cannot be done like this...
% if y is matrix, it would be flattened to a vector...
% y = y(:); % force column vector
% pre 2010-03-11 version:
% $$$ if size(y, 1) == 1 % row vector: transpose
% $$$   y = y';
% $$$ end


