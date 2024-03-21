%% Create gaussian blob stimuli with different average brightness in top and bottom
clear all
close all
warning off;
%% Display settings
epar.SCREEN_X_PIX = 3840;
epar.SCREEN_Y_PIX = 2160;
epar.screen_x_cm  = 60;
epar.screen_y_cm  = 32;
epar.vp_dist_cm   = 70;

epar.x_center=epar.SCREEN_X_PIX/2;
epar.y_center=epar.SCREEN_Y_PIX/2;
epar.XPIX2DEG = atand ((epar.screen_x_cm / epar.SCREEN_X_PIX) / epar.vp_dist_cm);
epar.YPIX2DEG = atand ((epar.screen_y_cm / epar.SCREEN_Y_PIX) / epar.vp_dist_cm);


%% gabor settings
epar.gabor.size = 801;
epar.gabor.sd = 1; % deg
epar.gabor.exponent = 2;
epar.gabor.sf = 0;
epar.gabor.orient = 0;
epar.gabor.phase = 0;
epar.gabor.contrast = 1;

% Manipulation
bright_up = 0.53; 
bright_down = 0.5; 
bright_sd = 0.1; 
bright_back = 0.25; 

Back = bright_sd*randnd(-1,[epar.SCREEN_Y_PIX epar.SCREEN_X_PIX])+bright_back;
% Check Pink noise
X = fft2(Back);


Back_rand = bright_sd*randn(epar.SCREEN_Y_PIX,epar.SCREEN_X_PIX)+bright_back; 

%% Stim position
Stim_Position_x = epar.x_center+10/epar.XPIX2DEG;
Stim_Position_y = epar.y_center;

%% Create Matrix
x(1,:) =(1:epar.gabor.size)-epar.gabor.size/2;
x = repmat(x,[epar.gabor.size 1]);
y = x';
x = x.*epar.XPIX2DEG;
y = y.*epar.YPIX2DEG;
r = hypot(x,y);

if epar.gabor.sf==0
    sin_data = ones(size(x));
else
    sin_data = cos(2.*pi.*((x.*cos(epar.gabor.orient)+y.*sin(epar.gabor.orient)+epar.gabor.phase).*epar.gabor.sf));
end

gauss_data = exp(-0.5 .* ((r - 0)./epar.gabor.sd).^epar.gabor.exponent) ./ (sqrt(2*pi) .* epar.gabor.sd);
gauss_data = gauss_data./max(gauss_data(:))*0.5*epar.gabor.contrast;
%gauss_data{time} = normpdf(r,0,epar.gabor.sd)./normpdf(0,0,epar.gabor.sd).*0.5.*epar.gabor.contrast(time); %% Ganzen Term quadrieren fuer steileren Abfall
gabor_data = (sin_data.*gauss_data)+0.5;

figure;subplot(1,2,1); hold on; imshow(gabor_data); 

%% Now split the stimulus in half 

% Find the stimulus 
comb_up = find(gabor_data(1:floor(size(gabor_data,1)/2),:) >= 0.60); 
comb_down = find(gabor_data(round(size(gabor_data,1)/2):end,:) >= 0.60); 
Gabor_up = gabor_data(1:floor(size(gabor_data,1)/2),:);
Gabor_down = gabor_data(round(size(gabor_data,1)/2):end,:);

% Use the background


Upper_half = Back(1+Stim_Position_y-size(Gabor_up,1):Stim_Position_y,1+Stim_Position_x-size(Gabor_up,2)/2:Stim_Position_x+size(Gabor_up,2)/2);
Lower_half = Back(1+Stim_Position_y:Stim_Position_y+size(Gabor_down,1),1+Stim_Position_x-size(Gabor_down,2)/2:Stim_Position_x+size(Gabor_down,2)/2);
% 
% Upper_half = bright_sd.*randn(size(Gabor_up))+bright_back;
% Lower_half = bright_sd.*randn(size(Gabor_down))+bright_back;



Upper_half(comb_up)= Gabor_up(comb_up).*(bright_sd.*randn(length(comb_up),1)+bright_up);
Lower_half(comb_down)= Gabor_down(comb_down).*(bright_sd.*randn(length(comb_down),1)+bright_down);


Gabor_new= [Upper_half;bright_sd*randn(size(Upper_half,2),2)'+bright_back;Lower_half];

subplot(1,2,2); hold on; imshow(Gabor_new); 

figure; 
hold on; 
histogram(Upper_half(comb_up),'Normalization','probability','FaceColor','b'); 
plot([mean(Upper_half(comb_up)) mean(Upper_half(comb_up))],[0 0.07],'b-','LineWidth',2)
hold on; 
histogram(Lower_half(comb_down),'Normalization','probability','FaceColor','r'); 
plot([mean(Lower_half(comb_down)) mean(Lower_half(comb_down))],[0 0.07],'r-','LineWidth',2)




%% Add Stimulus to background

Back(1+Stim_Position_y-size(Gabor_new,1)/2:Stim_Position_y+size(Gabor_new,1)/2,1+Stim_Position_x-size(Gabor_new,2)/2:Stim_Position_x+size(Gabor_new,2)/2) = Gabor_new; 


figure; imshow(Back)




