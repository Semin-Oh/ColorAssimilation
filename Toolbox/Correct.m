function [Out] = Correct(In,BitDepth,LUT)
%% Input needs to be RGB Value from 0 to 1

% Adjusted by AG 
% Lookup table now as input into function to avoid potential confusion with
% global variables 

% global LUT

% NRB: Replaced BitRange with BitRange variable
BitRange= ((2^BitDepth)-1);
% tic
%% Check Dimensionality
Out = zeros(size(In)); 
if length(size(In)) ==2

    Out = [LUT(round(BitRange*In(:,1)+1.1),1) LUT(round(BitRange*In(:,2)+1.2),2) LUT(round(BitRange*In(:,3)+1.3),3)]/BitRange;

elseif length(size(In)) ==3
%     for aa =1:3
%         if aa == 1

Mat = round(BitRange*In(:,:,1)+1.1);
Corr= LUT(Mat(:),1)./BitRange;
Out(:,:,1) = reshape(Corr,[size(In,1) size(In,2)]);

Mat = round(BitRange*In(:,:,2)+1.2);
Corr= LUT(Mat(:),2)./BitRange;
Out(:,:,2) = reshape(Corr,[size(In,1) size(In,2)]);

Mat = round(BitRange*In(:,:,3)+1.3);
Corr= LUT(Mat(:),3)./BitRange;
Out(:,:,3) = reshape(Corr,[size(In,1) size(In,2)]);




%             Out(:,:,1) = LUT(round(BitRange*In(:,:,1)+1.1),1)./BitRange;
% %         elseif aa == 2
%             Out(:,:,2) =     LUT(round(BitRange*In(:,:,2)+1.2),2)./BitRange;
% %         elseif aa == 3
%             Out(:,:,3) =    LUT(round(BitRange*In(:,:,3)+1.3),3)./BitRange;
%         end
    end
%    toc 
end

