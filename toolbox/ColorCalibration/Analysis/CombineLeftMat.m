clear;clc
load ('SPECTRA_Samsung wide_left_R_upto13_01-Aug-2022.mat');
SPECTRA1 = SPECTRA;
load ('SPECTRA_Samsung wide_left_01-Aug-2022.mat');
SPECTRA2 = SPECTRA;

clear SPECTRA;
SPECTRA = SPECTRA2;
SPECTRA(:,1:13,1) = SPECTRA1(:,1:13,1);

save(['SPECTRA_Samsung wide_left_combined_01-Aug-2022.mat'],'SPECTRA','intercept','time')





