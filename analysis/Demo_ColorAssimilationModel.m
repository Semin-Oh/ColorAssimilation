% Demo_colorAssimilation.
%
% Demo script for Ulucan et al. (2024) color assimilation + constancy model

% Clear environment
clear; close all;

% Read input image
imageFilename = 'image1.png';
I = imread(imageFilename);

% Run color assimilation + constancy model
opts.singleIllum = false;  
O = colorAssimilationCC(I, opts);

% Display results
figure('Name','Color Assimilation Demo','Color','w');
subplot(1,2,1); imshow(I); title('Original Illusion','FontSize',14);
subplot(1,2,2); imshow(O); title('Model Output','FontSize',14);
