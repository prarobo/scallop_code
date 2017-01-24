function [ surfFeatures, surfPoints ] = computeSurfFeature( params, grayImage )
%COMPUTESURFFEATURE Computes surf features

points = detectSURFFeatures( grayImage );
selectedPoints = points.selectStrongest( params.numInterestPoints );

[surfFeatures, surfPoints] = extractFeatures(grayImage, selectedPoints);

% imshow(grayImage); hold on;
% plot(surfPoints); 

end

