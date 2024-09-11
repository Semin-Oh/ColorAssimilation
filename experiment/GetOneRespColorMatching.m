function [matchingIntensity] = GetOneRespColorMatching(images,idxImage,intensityColorCorrect,idxColorCorrectImage,nTestPoints, ...
    window,windowRect,options)
% This routine does one color matching trial.
%
% Syntax:
%    [matchingIntensity] = GetOneRespColorMatching(images,idxImage,intensityColorCorrect,idxColorCorrectImage,nTestPoints, ...
%    window,windowRect)
%
% Description:
%    dd
%
% Inputs:
%    N/A
%
% Outputs:
%    keyPress                   - dd
%
% Optional key/value pairs:
%    verbose                    - Boolean. Default true. Controls
%                                 printout.
%
% See also:
%    CA_RunExperiment.

% History:
%   09/11/24 smo                - Wrote it.

%% Set variables.
arguments
    images
    window (1,1)
    windowRect (1,4)
    options.imageFixationType = 'filled-circle';
    options.expKeyType = 'gamepad';
    options.postColorCorrectDelaySec = 0.5;
    options.verbose = true;
end

%% Color matching experiment happens here.
%
% Display the test image.
testImage = images.testImage{idxImage,idxColorCorrectImage};
[testImageTexture testImageWindowRect rng] = MakeImageTexture(testImage, window, windowRect,...
    'addFixationPointImage',options.imageFixationType,'verbose',false);
FlipImageTexture(testImageTexture,window,windowRect,'verbose',false);

% Close the other textures.
CloseImageTexture;

%% Set the available key options here over different key type either
% keyboard or gamepad.
switch options.expKeyType
    case 'gamepad'
        buttonDown = 'down';
        buttonUp = 'up';
        buttonDecide = 'right';
        buttonQuit = 'sideleft';
    case 'keyboard'
        buttonDown = 'LeftArrow';
        buttonUp = 'RightArrow';
        buttonDecide = 'DownArrow';
        buttonQuit = 'q';
end

%% This block completes a one evaluation. Get a key press.
while true
    % Get a key press here..
    switch options.expKeyType
        case 'gamepad'
            keyPressed = GetJSResp;
        case 'keyboard'
            keyPressed = GetKeyPress;
    end

    % Quit.
    if strcmp(keyPressed,buttonDecide)
        fprintf('A key pressed = (%s) \n',keyPressed);
        break;

        % Update the test image with less color correction.
    elseif strcmp(keyPressed,buttonDown)
        idxColorCorrectImage = idxColorCorrectImage - 1;

        % Set the index within the feasible range.
        if idxColorCorrectImage < 1
            idxColorCorrectImage = 1;
        elseif idxColorCorrectImage > nTestPoints
            idxColorCorrectImage = nTestPoints;
        end

        % Update the image here.
        testImage = images.testImage{idxImage,idxColorCorrectImage};
        [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImage, window, windowRect,...
            'addFixationPointImage',options.imageFixationType,'verbose', false);
        FlipImageTexture(testImageTexture, window, windowRect,'verbose',false);
        fprintf('Test image is now displaying: Color correct level (%d/%d) \n',idxColorCorrectImage,nTestPoints);

        % Close the other textures.
        CloseImageTexture;

        % Update the test image with stronger color correction.
    elseif strcmp(keyPressed,buttonUp)
        idxColorCorrectImage = idxColorCorrectImage + 1;

        % Set the index within the feasible range.
        if idxColorCorrectImage < 1
            idxColorCorrectImage = 1;
        elseif idxColorCorrectImage > nTestPoints
            idxColorCorrectImage = nTestPoints;
        end

        % Update the image here.
        testImage = images.testImage{idxImage,idxColorCorrectImage};
        [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImage, window, windowRect,'addFixationPointImage','filled-circle','verbose', false);
        FlipImageTexture(testImageTexture, window, windowRect,'verbose',false);
        fprintf('Test image is now displaying: Color correct level (%d/%d) \n',idxColorCorrectImage,images.imageParams.nTestPoints);

        % Close the other textures.
        CloseImageTexture;

    elseif strcmp(keyPressed,buttonQuit)
        % Close the PTB. Force quit the experiment.
        CloseScreen;
        break;
    else
        % Show a message to press a valid key press.
        fprintf('Press a key either (%s) or (%s) or (%s) \n',buttonDown,buttonUp,buttonDecide);
    end

    % Make a tiny time delay here so that we make sure we color
    % match in a unit step size. Without time delay, the color
    % matching would be executed in more than one step size if
    % we press the button too long.
    pause(options.postColorCorrectDelaySec);

    % Collect the key press data here.
    matchingIntensity = intensityColorCorrect(idxColorCorrectImage);
end
end
