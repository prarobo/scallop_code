function [ filterImage, imgFilterSteps ] = scallopFilter_enhance( workImage, imgFilterSteps )
%SCALLOPFILTER Filters fixation windows

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filterParams = createRegionFilterParams;

%% Color Filtering and Edge Image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isvector(workImage) == 1 || ismatrix(workImage)
    grayImage = workImage;
elseif ndims(workImage) == 3
    grayImage = rgb2gray(workImage);
else
    error('Image dimensions (1 0r 2 0r 3) can only be handles, error in function %s', mfilename);
end
% figure; imshow(grayImage);

enhanceImage = imadjust(grayImage);
% figure; imshow(enhanceImage);

edgeImage = edge(enhanceImage, 'sobel');
% edgeImage = edge(enhanceImage, 'canny');
% figure; imshow(edgeImage);

cleanImage = bwmorph(edgeImage, 'clean');
% figure; imshow(cleanImage);

dilateImage = imdilate(cleanImage, strel('disk', 3) );
% figure; imshow(dilateImage);

[filterImage, imgFilterSteps] = bwFilter( dilateImage, filterParams, imgFilterSteps );

imgFilterSteps.gray = grayImage;
imgFilterSteps.edge = edgeImage;
imgFilterSteps.clean = cleanImage;
imgFilterSteps.dilate = dilateImage;
imgFilterSteps.orig = workImage;

end
