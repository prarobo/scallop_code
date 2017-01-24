function [ skelFilterImage, imgFilterSteps ] = scallopFilter_skel( workImage, imgFilterSteps )
%SCALLOPFILTER Filters fixation windows

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filterParams = createRegionFilterParams;

%% Color Filtering and Edge Image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

grayImage = rgb2gray(workImage);
% figure; imshow(grayImage);

enhanceImage = imadjust(grayImage);
% figure; imshow(enhanceImage);

edgeImage = edge(enhanceImage, 'sobel');
% figure; imshow(edgeImage);

cleanImage = bwmorph(edgeImage, 'clean');
% figure; imshow(cleanImage);

dilateImage = imdilate(cleanImage, strel('disk', 3) );
% figure; imshow(dilateImage);

[filterImage, imgFilterSteps] = bwFilter( dilateImage, filterParams, imgFilterSteps );

[skelFilterImage, imgFilterSteps] = skelFilter( filterImage, imgFilterSteps );

imgFilterSteps.gray = grayImage;
imgFilterSteps.edge = edgeImage;
imgFilterSteps.clean = cleanImage;
imgFilterSteps.dilate = dilateImage;
imgFilterSteps.orig = workImage;

end

%% Function to do skeleton based filtering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [skelFilterImage, imgFilterSteps ] = skelFilter( workImage, imgFilterSteps )

% figure; imshow(workImage);

skelImage = bwmorph( workImage, 'skel', inf );
% figure; imshow(skelImage);

skelFilterImage = skelImage;
imgFilterSteps.skel = skelFilterImage;

end
