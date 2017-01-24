function displayImageHistComparison( im1, im2, colorSpace )
%DISPLAYIMAGEHISTCOMPARISON Displays colorspace histograms of two images

%% Initialize
switch nargin
    case 2
        colorSpace = 'hsv';
    case 3
    otherwise
        error('Bloody hell! Incompatible argeuments in funstion %s, exiting', mfilename);
end

nChannels = 3;

%% RGB case
if strcmpi('rgb',colorSpace)
    for chI = 1:nChannels
        subplot(2, nChannels, chI); imhist(im1(:,:,chI));
        subplot(2, nChannels, chI+nChannels); imhist(im2(:,:,chI));
    end
    
elseif strcmpi('rgb',colorSpace)
    im1Hsv = rgb2hsv(im1);
    im2Hsv = rgb2hsv(im2);
    for chI = 1:nChannels
        subplot(2, nChannels, chI); imhist(im1Hsv(:,:,chI));
        subplot(2, nChannels, chI+nChannels); imhist(im2Hsv(:,:,chI));
    end    
end    

end

