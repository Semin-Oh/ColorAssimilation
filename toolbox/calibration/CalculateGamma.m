function [optimized_gamma] = CalculateGamma(x_points,y_points)
% Calculate the display gamma value.
%
% Syntax:
%    [optimized_gamma] = CalculateGamma(x_points,y_points)
%
% Description:
%    This routine calculates the gamma value using the given x and y data
%    points. It uses fmincon function inside and it would be useful when
%    calibrating the display.
%
% Inputs:
%    x_points           - Input RGB values. Either 8-bit or 10-bit works
%                         fine.
%    y_points           - Output measurement data points.
%
% Outputs:
%    optimized_gamma    - Optimized gamma value.

% History:
%    06/07/24    smo    - Started on it.

%% Set variables.
arguments
    x_points
    y_points
end

%% Calculation happens here.
%
% Normalize the input x and y data points.
x_points = x_points./max(x_points);
y_points = y_points./max(y_points);

% Define the objective function for fmincon
objective_function = @(gamma) sum((y_points - (x_points.^gamma)).^2);

% Initial guess for parameters [a, b]
initial_gamma = 1;

% Define the optimization options
options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp');

% Perform the optimization using fmincon
[optimized_gamma, ~] = fmincon(objective_function, initial_gamma, [], [], [], [], [], [], [], options);

end