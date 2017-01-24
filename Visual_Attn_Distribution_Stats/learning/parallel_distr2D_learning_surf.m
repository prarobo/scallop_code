function [ distributionData, scallopInfo, params ] = parallel_distr2D_learning_surf( params, fileInfo, groundTruth )
%read_scallop_pixel_test Reads scallop pixels from test data set

%% Initialization
params.numFeatures = length(params.featureMatCaps);
numImages = params.numImages;
foldername = fileInfo.foldername;
filename = fileInfo.filename;
globalAdjustOn = params.globalAdjustOn;
localAdjustOn = params.localAdjustOn;
   
dataPoint = cell(numImages,1);

cform = makecform('srgb2lab');

if matlabpool('size') == 0
    matlabpool open local 7
end

%% 2D Feature Maps of Scallops
for imageI=1:numImages    
    if groundTruth(imageI).numScallops ~= 0
        currFilename = fullfile( foldername, filename{imageI} );
        % dataPoint{imageI} = parallelImageProcessing( groundTruth(imageI), currFilename, params, imageI, cform, adjustOn);
        dataPoint{imageI} = parallelImageProcessingSurf( groundTruth(imageI), currFilename, params, imageI, cform, globalAdjustOn, localAdjustOn );
    end
end

%     matlabpool close

%% Writing Feature Attributes and Saving Scallop Information to CSV file
fid = fopen( params.attrFile, 'w' );
fclose(fid);
fid = fopen( params.scallopInfoFile, 'w' );
fclose(fid);

for imageI=1:numImages    
    if groundTruth(imageI).numScallops ~= 0
        writeAttrCSV_learning( params, dataPoint{imageI}, imageI );
    end
end
[scallopInfo, params] = writeScallopInfo_learning( params, fileInfo, groundTruth );

distributionData.dataPoint = dataPoint;

end

%% Parallel function discretization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ currDataPointCum ] = parallelImageProcessing( currGroundTruth, currFilename, params, imageI, cform, adjustOn )

numFeatures = length(params.featureMatCaps);
numImages = params.numImages;
currImage = imread( currFilename );

%% Feature Channels

currSample = computeFeatureMaps( currImage, params, cform, adjustOn );

numScallops = currGroundTruth.numScallops;
currDataPointCum = cell(numScallops, 1);

for scallopI = 1:numScallops
    fprintf('Computing image discretization %d of %d, scallop %d of %d ...', imageI, numImages, scallopI, numScallops);
    
    centerX = currGroundTruth.loc(scallopI, 1);
    centerY = currGroundTruth.loc(scallopI, 2);
    radius = currGroundTruth.loc(scallopI, 3);
    % radius = currGroundTruth.loc(scallopI, 3) * params.radiusConstrictionFactor;
    
    %% Distributions of pixels
    
    for f=1:numFeatures
        featureMap = sprintf('%sMap', params.featureMatSmall{f});
        featureFeature = sprintf('%sFeature', params.featureMatCaps{f});
        
        currDataPoint.(featureFeature) = bin2DScallop_median_annulus(currSample.(featureMap),...
            centerX,...
            centerY,...
            radius,...
            params);
        
    end
    
    currDataPointCum{scallopI} = currDataPoint;
    fprintf('done\n');
end

end

%% Parallel function discretization (Surf)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ currDataPointCum ] = parallelImageProcessingSurf( currGroundTruth, currFilename, params, imageI, cform, globalAdjustOn, localAdjustOn )

% numFeatures = length(params.featureMatCaps);
numImages = params.numImages;
currImage = imread( currFilename );

%% Feature Channels

currSampleTemp.currRGBImage = currImage;
if globalAdjustOn
    currSampleTemp.currRGBImage = imadjust( currSampleTemp.currRGBImage, stretchlim(currSampleTemp.currRGBImage) );
end

currSampleTemp.currHSVImage = rgb2hsv( currSampleTemp.currRGBImage );
currSampleTemp.valChannel = currSampleTemp.currHSVImage(:,:,3);

numScallops = currGroundTruth.numScallops;
currDataPointCum = cell(numScallops, 1);

for scallopI = 1:numScallops
    fprintf('Computing image discretization %d of %d, scallop %d of %d ...', imageI, numImages, scallopI, numScallops);
    
    centerX = currGroundTruth.loc(scallopI, 1);
    centerY = currGroundTruth.loc(scallopI, 2);
    radius = currGroundTruth.loc(scallopI, 3);
    % radius = currGroundTruth.loc(scallopI, 3) * params.radiusConstrictionFactor;
    
    %% Surf Feature    
    
    currRect = subImageRect( params, centerX, centerY, radius );
    subImage = imcrop( currSampleTemp.valChannel, currRect );
    if localAdjustOn
        subImage = imadjust( subImage );
    end
    
    [currSample.surfMap, currSample.surfPoints] = computeSurfFeature( params, subImage );
    currDataPoint.surfFeature = currSample.surfMap;
    
    currDataPointCum{scallopI} = currDataPoint;
    fprintf('done\n');
end

end

%% Function to compute feature maps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function currSample = computeFeatureMaps(currImage, params, cform, adjustOn)

numFeatures = length(params.featureMatCaps);
currSample = struct;

currSampleTemp.currRGBImage = currImage;
if adjustOn
    currSampleTemp.currRGBImage = imadjust( currSampleTemp.currRGBImage, stretchlim(currSampleTemp.currRGBImage) );
end

currSampleTemp.currHSVImage = rgb2hsv( currSampleTemp.currRGBImage );
currSampleTemp.currLABImage = lab2uint8(applycform( currSampleTemp.currRGBImage, cform ));

currSampleTemp.redChannel = currSampleTemp.currRGBImage(:,:,1);
currSampleTemp.greenChannel = currSampleTemp.currRGBImage(:,:,2);
currSampleTemp.blueChannel = currSampleTemp.currRGBImage(:,:,3);

currSampleTemp.hueChannel = currSampleTemp.currHSVImage(:,:,1);
currSampleTemp.satChannel = currSampleTemp.currHSVImage(:,:,2);
currSampleTemp.valChannel = currSampleTemp.currHSVImage(:,:,3);

currSampleTemp.lumChannel = currSampleTemp.currLABImage(:,:,1);
currSampleTemp.alocChannel = currSampleTemp.currLABImage(:,:,2);
currSampleTemp.blocChannel = currSampleTemp.currLABImage(:,:,3);

[currSampleTemp.gradmagChannel, currSampleTemp.graddirChannel] = imgradient( currSampleTemp.valChannel );


for f=1:numFeatures
    featureMap = sprintf('%sMap', params.featureMatSmall{f});
    featureChannel = sprintf('%sChannel', params.featureMatSmall{f});
    
    currSample.(featureMap) = im2double(currSampleTemp.(featureChannel));
    currSample.(featureMap) = scaleMap( currSample.(featureMap) );
end

end

%% Map Normalization Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function outMap = scaleMap( inMap )
    outMap = inMap - min(inMap(:));
    outMap = outMap./max(outMap(:));
end

%% Function to compute sub image rect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rect = subImageRect( params, centerX, centerY, radius )

radius = radius * params.radiusConstrictionFactor;
xStart = round(centerX-radius);
xEnd = round(centerX+radius);
yStart = round(centerY-radius);
yEnd = round(centerY+radius);

xDiff = 0;
yDiff = 0;

if xStart < 1
    xDiff = abs(xStart)+1;
    xStart = 1;
end

if yStart < 1
    yDiff = abs(yStart)+1;
    yStart = 1;
end

if xEnd > params.imageSize(2)
    xDiff = -(xEnd-size(img,2));
    xEnd = size(img,2);
end

if yEnd > params.imageSize(1)
    yDiff = -(yEnd-size(img,1));
    yEnd = size(img,1);
end

% if xDiff ~= 0 && yDiff ~= 0 
%     yDiff = 0;
% end

rect = [xStart yStart xEnd-xStart+1 yEnd-yStart+1];

end
