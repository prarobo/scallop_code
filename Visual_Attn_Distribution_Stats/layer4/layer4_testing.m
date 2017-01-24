function [ layer4Data, params ] = layer4_testing( params, fileInfo, statData, distributionData, ...
                                                    confIntervalData, scallopLookupParams )
%LAYER4_TESTING Summary of this function goes here
%   Detailed explanation goes here

%% Initialization

numImages = params.numImages;
scallopVerdictThreshold = params.scallopVerdictThreshold; %7 %5.5; %5.7; %4.1;
matchMetric = params.matchMetric;
metricType = params.metricType;
storeLayer4Data = params.storeLayer4Data;

% detectionStats = statData.detectionStats;
objList = distributionData.objList;
dataPointMatch = distributionData.dataPointMatch;
filename = fileInfo.filename;
foldername = fileInfo.foldername;

checkStat = cell(numImages, 1);
imageFilterSteps = cell(numImages, 1);
filterVerdict = cell(numImages, 1);

params.layer4IntersectThresholdPercent = 0.3;

numInputObjects = 0;
numOutputObjects = 0;

%% Filtering positive objects

for imageI=1:numImages
    
    fprintf('Processing layer 4, image %d ...', imageI);
    numObj = size( objList{imageI}, 1 );
    checkStat{imageI} = cell(numObj, 1);
    imageFilterSteps{imageI} = cell(numObj, 1);
    filterVerdict{imageI} = false(numObj, 1);
    
    for objI=1:numObj
        if( (strcmp( metricType, 'lesserTheBetter') && ...
                dataPointMatch{imageI}{objI}.(matchMetric) <= scallopVerdictThreshold) || ...
            (strcmp( metricType, 'greaterTheBetter') && ...
                dataPointMatch{imageI}{objI}.(matchMetric) >= scallopVerdictThreshold) )
            
            [currCheckStat, currImageFilterSteps, currFilterVerdict]  = checkObject( imageI, objI, filename{imageI}, foldername, ...
                                            params, objList{imageI}, confIntervalData, scallopLookupParams );
            
            checkStat{imageI}{objI} = currCheckStat;
            imageFilterSteps{imageI}{objI} = currImageFilterSteps;
            
            numInputObjects = numInputObjects + 1;
            if currFilterVerdict && (currCheckStat.percentIntersect >= params.layer4IntersectThresholdPercent)
                filterVerdict{imageI}(objI) = true;
                numOutputObjects = numOutputObjects + 1;
            end
        else
            % error('Invalid metric check in layer4, error in function %s', mfilename);
        end        
    end
    fprintf('done\n');
end

%% Quick Display

% for imageI = 1:numImages
%     numObj = size( objList{imageI}, 1 );
% 
%     for objI=1:numObj
%         layer4DisplayQuickCheck( imageFilterSteps{imageI}{objI} );
%     end
% end

%% Layer 4 results

layer4Data.checkStat = checkStat;
layer4Data.filterVerdict = filterVerdict;

if storeLayer4Data
    layer4Data.imageFilterSteps = imageFilterSteps;
end

end

%% checkObject function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [checkStat, imageFilterSteps, filterVerdict] = checkObject( imageI, objI, filename, foldername, params, objList, ...
                                                                        confIntervalData, scallopLookupParams )

%% Initialization

currImage = imread( fullfile(foldername, filename) );
currObj = objList(objI,:);
imageSize = params.imageSize;
storeLayer4Data = params.storeLayer4Data;
resizeImageSize = params.resizeImageSize;

currObjX = round( currObj(1) );
currObjY = round( currObj(2) );
currObjRad = round( currObj(3)*params.radiusConstrictionFactor );

imageFilterSteps = struct;
checkStat = struct;

ind = sub2ind( size(confIntervalData.confInterval), currObjY, currObjX );
% currConfIntervals = confIntervalData.confInterval(ind);
currIsValidConf = confIntervalData.isValid(ind);
currStddevConf = confIntervalData.stddevPoints{ind};
currMeanConf = confIntervalData.meanPoints{ind};

if ~currIsValidConf
    return;
end

%% Compute bounding box and cropping image

rect = zeros(1,4);
rect(1) = max(1, currObjX-currObjRad);
rect(2) = max(1, currObjY-currObjRad);
rect(3) = min( imageSize(2), currObjX+currObjRad ) - rect(1);
rect(4) = min( imageSize(1), currObjY+currObjRad ) - rect(2);

cropImage = imcrop(currImage, rect);
if storeLayer4Data
    imageFilterSteps.cropImage = cropImage;
end

%% Custom Threshold Image

[threshImage, imageFilterSteps, filterVerdict] = customThreshold( cropImage, imageFilterSteps, storeLayer4Data );

if ~filterVerdict
    return;
end

%% Filter Blobs

[filterImage, imageFilterSteps, filterVerdict] = customBlobFilter( threshImage, imageFilterSteps, storeLayer4Data );

if ~filterVerdict
    return;
end

%% Resizing Image
resizeImage = logical( imresize( filterImage, [resizeImageSize resizeImageSize] ) );
if storeLayer4Data
    imageFilterSteps.resizeImage = resizeImage;
end

filterVerdict = logical(sum(resizeImage(:)));
if ~filterVerdict
    return;
end

%% Conf Interval Mask

[confIntervalImage, imageFilterSteps, filterVerdict] = customConfIntervalMask( params, currStddevConf, currMeanConf, ...
                                                                    imageFilterSteps, storeLayer4Data );

if ~filterVerdict
    return;
end

%% Conf Interval Intersect

intersectImage = confIntervalImage & resizeImage;

filterVerdict = logical(sum(intersectImage(:)));
if ~filterVerdict
    return;
end

checkStat.numMeanConfPix = sum( confIntervalImage(:) );
checkStat.numIntersectPix = sum( intersectImage(:) );
checkStat.percentIntersect = checkStat.numIntersectPix/checkStat.numMeanConfPix;

if storeLayer4Data
    imageFilterSteps.intersectImage = intersectImage;
end


%% Quick Display

%layer4DisplayQuickCheck( imageFilterSteps );

end

%% Display routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = layer4DisplayQuickCheck( imageFilterSteps )

% grayImage = rgb2gray(cropImage);
% threshImage = im2bw( grayImage, graythresh(grayImage) );
% edgeImage = edge(grayImage);

% numSegments = 2;
% [labelImage,~,~,~,~,~] = NcutImage( grayImage, numSegments);

if( any( strcmp( fieldnames(imageFilterSteps), 'cropImage' ) ) )
    subplot(231)
    imshow(imageFilterSteps.cropImage);
end

if( any( strcmp( fieldnames(imageFilterSteps), 'threshImage' ) ) )
    subplot(232)
    imshow(imageFilterSteps.threshImage);
end

if( any( strcmp( fieldnames(imageFilterSteps), 'filterImage' ) ) )
    subplot(233)
    imshow(imageFilterSteps.filterImage);
end

if( any( strcmp( fieldnames(imageFilterSteps), 'resizeImage' ) ) )
    subplot(234)
    imshow(imageFilterSteps.resizeImage);
end

if( any( strcmp( fieldnames(imageFilterSteps), 'confIntervalImage' ) ) )
    subplot(235)
    imshow(imageFilterSteps.confIntervalImage);
end

if( any( strcmp( fieldnames(imageFilterSteps), 'intersectImage' ) ) )
    subplot(236)
    imshow(imageFilterSteps.intersectImage);
end

end

%% Function customThreshold
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [threshImage, imageFilterSteps, filterVerdict] = customThreshold( image, imageFilterSteps, storeLayer4Data )

%% Initilization

grayImage = rgb2gray(image);
% redMask = true( size(image, 1), size(image, 1) );
% greenMask = true( size(image, 1), size(image, 1) );
% blueMask = true( size(image, 1), size(image, 1) );



%% Clear very bright objects if present

redMask = (image(:,:,1) > 100);
greenMask = (image(:,:,2) > 140);
blueMask = (image(:,:,3) > 120);

brightMask = redMask & greenMask & blueMask;

connComp = bwconncomp(brightMask);
stats = regionprops(connComp,'Area', 'PixelIdxList');

largeBrightRegMask = false( size(brightMask) );
for regI = 1:length(stats)
    if stats(regI).Area > 500
        largeBrightRegMask(stats(regI).PixelIdxList) = true;
    end
end

smallBrightRegMask = ~largeBrightRegMask & brightMask;

brightClearImage = grayImage;
brightClearImage(smallBrightRegMask) = round( 0.8 * mean(grayImage(:)));

%% Threshold

threshOrigImage = im2bw( brightClearImage, graythresh(brightClearImage) );
threshImage = ~largeBrightRegMask & threshOrigImage;

filterVerdict = logical(sum(threshImage(:)));

%% Filter Steps

if storeLayer4Data
    imageFilterSteps.grayImage = grayImage;
    imageFilterSteps.redMask = redMask;
    imageFilterSteps.greenMask = greenMask;
    imageFilterSteps.blueMask = blueMask;
    imageFilterSteps.brightMask = brightMask;
    imageFilterSteps.smallBrightRegMask = smallBrightRegMask;
    imageFilterSteps.largeBrightRegMask = largeBrightRegMask;
    imageFilterSteps.brightClearImage = brightClearImage;
    imageFilterSteps.threshOrigImage = threshOrigImage;
    imageFilterSteps.threshImage = threshImage;
end

end

%% Function customBlobFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [filterImage, imageFilterSteps, filterVerdict] = customBlobFilter( image, imageFilterSteps, storeLayer4Data )

%% Initilization

%filterImage = image;

%% Clear Small Blobs

clearSmallRegionsImage = bwareaopen( image, 20 );
clearSmallRegionsImage = bwareaopen( ~clearSmallRegionsImage, 20 );

%% Removing Large Regions

clearLargeRegionsImage = bwareaopen( clearSmallRegionsImage, 6000 );
filterImage = ~clearLargeRegionsImage & clearSmallRegionsImage;

filterVerdict = logical(sum(filterImage(:)));

%% Filter Steps

if storeLayer4Data
    imageFilterSteps.clearSmallRegionsImage = clearSmallRegionsImage;
    imageFilterSteps.clearLargeRegionsImage = clearLargeRegionsImage;
    imageFilterSteps.filterImage = filterImage;
end

end

%% Function customConfIntervalMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [confIntervalImage, imageFilterSteps, filterVerdict] = customConfIntervalMask( params, currStddevConf, currMeanConf, ...
                                                                    imageFilterSteps, storeLayer4Data )

%% Computing threshold

numTopStddevFeatures = round(params.percentTopStddevFeatures*numel(currStddevConf) );
refStddevMat = sort( currStddevConf(:) );
threshVal = refStddevMat(numTopStddevFeatures);

%% Reshaping matrices

currStddevConf = transpose( reshape( currStddevConf, params.resizeImageSize, params.resizeImageSize));
% currMeanConf = transpose( reshape( currMeanConf, params.resizeImageSize, params.resizeImageSize));

%% Creating Mask
stdDevMask = (currStddevConf <= threshVal );

%% Keeping the largest blob

% connComp = bwconncomp(stdDevMask);
% numPixels = cellfun(@numel,connComp.PixelIdxList);
% [~,idx] = max(numPixels);
% 
% confIntervalImage = false( size(stdDevMask) );
% confIntervalImage(connComp.PixelIdxList{idx}) = true;
confIntervalImage = stdDevMask;

filterVerdict = logical(sum(confIntervalImage(:)));

% currMeanConf = round((currMeanConf - min( currMeanConf(:) )) * (255/range( currMeanConf(:) )));
% currMeanConf = uint8( currMeanConf );
% threshMeanConf = ~im2bw(currMeanConf, graythresh( currMeanConf ));

if storeLayer4Data
    imageFilterSteps.stdDevMask = stdDevMask;
    imageFilterSteps.confIntervalImage = confIntervalImage;
end

end                                                                












