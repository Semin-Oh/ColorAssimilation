clear all
% close all

load("SPECTRA_ColorLab_Station1_17-Jan-2022.mat") %the dates for these two files should be the same
filetosave = 'calibrationColorLab_Station1_17_01_22.mat';

wl = 380:780;
colnames={'r','g','b','k'};
cols=[1 0 0;
      0 1 0;
      0 0 1;
      1 1 1;
      ];

% compute intercept Lum
interceptL=mg_spectra2xyY([wl' intercept.spectralData ],'cie1931');
interceptL=interceptL.XYZ(2);
LUM=nan(1024,4);
LUM(1,:)=[interceptL interceptL interceptL interceptL];
% figure; hold on
for ch=1:4
%     subplot(1,4,ch)
    for val=1:1023
        col = cols(ch,:)*val/1023 ;
        spectrum = SPECTRA(:,val,ch);
%         spectrum = spectrum - SPECTRA(:,1,ch);
%         plot(wl,spectrum,'k-','color',col)
%         hold on
        
        Result=mg_spectra2xyY([wl' spectrum ],'cie1931'); % Sconvert from spectruq to threestimulus vqlues
        LUM(val+1,ch)=Result.XYZ(2);
        xyY(val+1,ch,:) = Result.xyY;
        
%         subplot(1,4,ch); hold on
%         plot(wl,spectrum,'k-','color',cols(ch,:).*val/1023)
    end
end

% units rqdiqnce on y wl on x

%%% Plot gammas
figure
for ch=1:4
    subplot(1,4,ch)
    
    plot(1:1024,LUM(:,ch),'k.')
    title(colnames{ch})
end
% save('rgbk_vals.txt','LUM','-ascii')

%%%
figure; hold on
for ch=1:4
%     subplot(1,4,ch)
    scatter(xyY(:,ch,1),xyY(:,ch,2),10,cols(ch,:))
end

figure; hold on
for ch=1:4
%     subplot(2,4,ch)
    subplot(1,2,1); hold on
    scatter(0:1023,xyY(:,ch,1),10,cols(ch,:))
    ylabel('x')
    xlabel('intensity')
%     subplot(2,4,ch+4)
    subplot(1,2,2); hold on
    scatter(0:1023,xyY(:,ch,2),10,cols(ch,:))
    ylabel('y')
    xlabel('intensity')
end





%% New part (LH)
% normalize LUM
LUMmod = LUM-min(LUM);
LUMmod = LUMmod./max(LUMmod);
LUMmod = LUMmod*1023;

% CALCULATING FITTED GAMMAS
inputVmain = [0:1:1023]/1023;
LUMnorm = LUMmod./1023;
g = fittype('x^(g)');
figure;
for i=1:4
    % method using offset (02/03/2022) (don't use -- should be only one 0 if normalized properly)
%     offset(i) = find(LUTnorm(:,i)>0,1)-1;   %last 0
%     inputV = [0:1:length(LUTnorm(offset(i):end,i))-1]/length(LUTnorm(offset(i):end,i)-1);
%     [fittedmodel{i} gof{i} o{i}] = fit(inputV',LUTnorm(offset(i):end,i),g);
%     firstFit = fittedmodel{i}(inputV);
%     displayGamma(i) = fittedmodel{i}.g;
%     subplot(1,3,i)
%     plot(inputVmain,LUTnorm(:,i),'.',inputVmain,[zeros(1,offset(i)-1) firstFit'],'--')
    
    % fitting without offset (best)
    [fittedmodel{i} gof{i} o{i}] = fit(inputVmain',LUMnorm(:,i),g);
    firstFit = fittedmodel{i}(inputVmain);
    subplot(1,4,i)
    plot(inputVmain,LUMnorm(:,i),'.',inputVmain,firstFit','--')
    displayGamma(i) = fittedmodel{i}.g;
    
    legend('Measures','Gamma model')
    title(sprintf('Gamma model x^{%.2f}',displayGamma(i)));
end
rgamma = displayGamma(1);
ggamma = displayGamma(2);
bgamma = displayGamma(3);
monGamma = reshape([rgamma ggamma bgamma],1,1,3);

% create new fitted LUMs
for ch=1:4
    LUMnew(:,ch) = fittedmodel{ch}(inputVmain)*1023;
end

% create LUT from fitted LUM curve
for ch=1:4
    for i=0:1023
        temp = abs(i-LUMnew(:,ch));   %get diff btw i and output
        ind = find(temp==min(temp));  %find ind where no diff btw i and output
        LUT(i+1,ch) = ind(1)-1;    %inds must start at 1, but outputs must start at 0
    end
end

figure;
for ch=1:4
    subplot(1,4,ch)
    plot(1:1024,LUT(:,ch),'.')
end

%create monitor xyY
monxyY = squeeze(xyY(end,1:3,:));




% save(filetosave,'monxyY','LUT','monGamma');
