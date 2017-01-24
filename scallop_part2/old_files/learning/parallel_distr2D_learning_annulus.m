function [ distributionData, scallopInfo, params ] = parallel_distr2D_learning_annulus( params, fileInfo, groundTruth )
%read_scallop_pixel_test Reads scallop pixels from test data set

%% Initialization
params.numFeatures = length(params.featureMatCaps);
numImages = params.numImages;
foldername = fileInfo.foldername;
filename = fileInfo.filename;
adjustOn = params.adjustOn;
   
dataPoint = cell(numImages,1);

cform = makecform('srgb2lab');

if matlabpool('size') == 0
    matlabpool open local 7
end

%% 2D Feature Maps of Scallops
parfor imageI=1:numImages    
    if groundTruth(imageI).numScallops ~= 0
        currFilename = fullfile( foldername, filename{imageI} );
        dataPoint{imageI} = parallelImageProcessing( groundTruth(imageI), currFilename, params, imageI, cform, adjustOn);
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

function outMap = scaleMap( inMap )
    outMap = inMap - min(inMap(:));
    outMap = outMap./max(outMap(:));
end
