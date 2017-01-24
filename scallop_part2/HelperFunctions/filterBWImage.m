function outImage = filterBWImage(inImage)
%FILTERBW Function to filter binary image to remove noise

inImage = imfill(inImage, 'holes');
if sum(inImage(:)) == 0
    outImage = inImage;
    return;
else
    regProps = regionprops(inImage, 'Area', 'PixelIdxList');
    [~,maxReg] = max([regProps.Area]);
    outImage = false(size(inImage));
    outImage(regProps(maxReg).PixelIdxList) = true;
end
