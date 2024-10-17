% GetSolidColorImage
%
% Foo contains the image and Fee contains the converted image with a solid
% color.
idxImageHeight = [];
idxImageWidth = [];
bgSetting = squeeze(foo(1,1,:));

[testImage_height testImage_width ~] = size(foo)
% Here, we will extract the pixels that does not match with the color
% of the background, which is the actual image.
for hh = 1:testImage_height
    for ww = 1:testImage_width
        areAllEqual = (foo(hh,ww,1)==bgSetting(1)) & (foo(hh,ww,2)==bgSetting(2)) & (foo(hh,ww,3)==bgSetting(3));
        if ~(areAllEqual)
            idxImageHeight(end+1) = hh;
            idxImageWidth(end+1) = ww;
        end
    end
end

fee = foo;
for ii = 1:length(idxImageHeight)
    fee(idxImageHeight(ii),idxImageWidth(ii),1) = 255;
    fee(idxImageHeight(ii),idxImageWidth(ii),2) = 192;
    fee(idxImageHeight(ii),idxImageWidth(ii),3) = 141;
end