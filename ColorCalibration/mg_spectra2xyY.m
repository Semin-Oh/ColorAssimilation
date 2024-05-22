function Result=mg_spectra2xyY(spectra,which_color_matching_function)
%SPECTRA2XYY  Convert spectra to xy chromaticity values and luminance Y.
%
% Thorsten Hansen 2008-06-05
% modified by mg
   
  switch which_color_matching_function
   case {'judd' 'Judd'}
    cmf_filename ='ciexyzj.txt';%from http://www.cvrl.org/
   case {'cie1931' 'CIE1931'}
    cmf_filename ='ciexyz31_1.txt';%from http://www.cvrl.org/
   case {'cie1964' 'CIE1964'}
    cmf_filename ='ciexyz64_1.txt';%from http://www.cvrl.org/
   otherwise
    error(['Unknown color matching function ' which_color_matching_function '.'])
  end
 
[wavelength x_bar y_bar z_bar]=textread(cmf_filename, '', 'delimiter', ',');
 
x1=wavelength;
y1=[x_bar y_bar z_bar];
wavelength_spectra=spectra(:,1);
spectra_measured=spectra(:,2:end);
 
[wavelength_common xyz_common spectra_measured_common]=commondomain(x1,y1,wavelength_spectra,spectra_measured);
 
%XYZ=spectra_measure_common'*xyz_common;
XYZ=683.*spectra_measured_common' *xyz_common;%mg
xyY=thXYZToxyY(XYZ')';
%xyY(:,3)=xyY(:,3)*683;%radiance to candela
 
Result.x=xyY(:,1);
Result.y=xyY(:,2);
Result.z=1-xyY(:,1)-xyY(:,2);
Result.X=XYZ(:,1);
Result.Y=XYZ(:,2);
Result.Z=XYZ(:,3);
Result.xyY=xyY;
Result.XYZ=XYZ;