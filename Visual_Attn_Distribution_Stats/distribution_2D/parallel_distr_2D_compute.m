function [ visualAttnOutData ] = parallel_distr_2D_compute( visualAttnInData, scallopDistribution, discretOn, checkOn )
%read_scallop_pixel_test Reads scallop pixels from test data set

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numRadThetaBins = [scallopDistribution.params.numRadBins-1 scallopDistribution.params.numThetaBins-1];
numImages = visualAttnInData.params.numImages;
    
visualAttnOutData = visualAttnInData;

visualAttnOutData.params.radiusExtn = scallopDistribution.params.radiusExtn;
visualAttnOutData.params.radiusConstrictionFactor = scallopDistribution.params.radiusConstrictionFactor;
visualAttnOutData.params.numDiscretizationBins = scallopDistribution.params.numDiscretizationBins;
visualAttnOutData.params.numRadBins = numRadThetaBins(1);
visualAttnOutData.params.numThetaBins = numRadThetaBins(2);
visualAttnOutData.params.featureMatCaps = scallopDistribution.params.featureMatCaps;
visualAttnOutData.params.featureMatSmall = scallopDistribution.params.featureMatSmall;

dataPointCheck = cell(numImages,1);
dataPoint = cell(numImages,1);

numFeatures = length(visualAttnOutData.params.featureMatCaps);

windowRect = calcRect( visualAttnOutData.fixationData.fixations, ...
    visualAttnOutData.params.imageSize, visualAttnOutData.params.fixationWindowSize );

%% Scallop masking and pixel isolation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cform = makecform('srgb2lab');
params = visualAttnOutData.params;
percentilePoints = visualAttnOutData.distributionData.percentilePoints;
fixationsVar = visualAttnOutData.fixationData.fixationsVar;
stdDevMaps = scallopDistribution.stddevFeatureMaps;

if discretOn
    if matlabpool('size') == 0
        matlabpool open local 8
    end
    parfor imageI=1:numImages
        dataPoint{imageI} = parallelImageProcessing( visualAttnOutData, imageI, cform, numFeatures, windowRect, numImages);
    end
    %     matlabpool close
else
    dataPoint = visualAttnOutData.distributionData.dataPoint;
end


if checkOn
    if matlabpool('size') == 0
        matlabpool open local 7
    end
    parfor imageI=1:numImages
        dataPointCheck{imageI} = parallelChecking( params, percentilePoints, fixationsVar, dataPoint{imageI}, imageI, numImages, stdDevMaps )
    end
    %     matlabpool close
end

visualAttnOutData.distributionData.dataPoint = dataPoint;
visualAttnOutData.distributionData.dataPointCheck = dataPointCheck;
visualAttnOutData.distributionData.stdDevMaps = stdDevMaps;

end

%% Parallel function discretization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ currDataPointCum ] = parallelImageProcessing( visualAttnOutData, imageI, cform, numFeatures, windowRect, numImages )

    % visualAttnOutData.distributionData.dataPoint{imageI} = cell(visualAttnOutData.fixationData.fixationsVar(imageI),1);
    currDataPointCum = cell(visualAttnOutData.fixationData.fixationsVar(imageI),1);
    
    currSample.currRGBImage = imread(sprintf('%s/%s',visualAttnOutData.fileInfo.foldername,visualAttnOutData.fileInfo.filename{imageI}));
    currSample.currRGBImage = imadjust( currSample.currRGBImage, stretchlim(currSample.currRGBImage) );
    currSample.currHSVImage = rgb2hsv( currSample.currRGBImage );
    currSample.currLABImage = lab2uint8(applycform( currSample.currRGBImage, cform ));
    
    currSample.redChannel = currSample.currRGBImage(:,:,1);
    currSample.greenChannel = currSample.currRGBImage(:,:,2);
    currSample.blueChannel = currSample.currRGBImage(:,:,3);
    
    currSample.hueChannel = currSample.currHSVImage(:,:,1);
    currSample.satChannel = currSample.currHSVImage(:,:,2);
    currSample.valChannel = currSample.currHSVImage(:,:,3);
    
    currSample.lumChannel = currSample.currLABImage(:,:,1);
    currSample.alocChannel = currSample.currLABImage(:,:,2);
    currSample.blocChannel = currSample.currLABImage(:,:,3);
    
    for f=1:numFeatures
        featureImage = sprintf('%sImage', visualAttnOutData.params.featureMatSmall{f});
        featureChannel = sprintf('%sChannel', visualAttnOutData.params.featureMatSmall{f});
        
        currSample.(featureImage) = im2double(currSample.(featureChannel));
    end
   
    for fixI = 1:visualAttnOutData.fixationData.fixationsVar(imageI)
        numObj = size(visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI},1);
        % visualAttnOutData.distributionData.dataPoint{imageI}{fixI} = cell(numObj, 1);
        currDataPointCum{fixI} = cell(numObj, 1);
        
        for objI = 1:numObj
            fprintf('Computing image discretization %d of %d, fixation %d of %d, object %d of %d ...', imageI, numImages, ...
                            fixI, visualAttnOutData.fixationData.fixationsVar(imageI), ...
                            objI, numObj);

            centerX = windowRect{imageI}(fixI,1) - 1 + visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,1);
            centerY = windowRect{imageI}(fixI,2) - 1 + visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,2);
            radius = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,3)*visualAttnOutData.params.radiusConstrictionFactor;
                        
            %% Distributions of pixels
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
            for f=1:numFeatures
                featureImage = sprintf('%sImage', visualAttnOutData.params.featureMatSmall{f});
                FeatureColor = sprintf('%sColor', visualAttnOutData.params.featureMatCaps{f});
                
                currDataPoint.(FeatureColor) = bin2DScallop(currSample.(featureImage),...
                                                 centerX,...
                                                 centerY,...
                                                 radius,...
                                                 [visualAttnOutData.params.numRadBins ...
                                                 visualAttnOutData.params.numThetaBins ...
                                                 visualAttnOutData.params.numDiscretizationBins]);
                                             
            end
            
            currDataPointCum{fixI}{objI} = currDataPoint;
            
            % visualAttnOutData.distributionData.dataPoint{imageI}{fixI}{objI} = currDataPoint;
            %             currDataPointCheck{fixI}{objI} ...
            %                         = checkDataPoint(currDataPoint, visualAttnOutData.params, visualAttnOutData.distributionData.percentilePoints);
            fprintf('done\n');
        end
    end    
end

%% Parallel function discretization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ currDataPointCheck ] = parallelChecking( params, percentilePoints, fixationsVar, currDataPoint, imageI, numImages, stdDevMaps )
    currDataPointCheck = cell(fixationsVar(imageI),1);
    
    for fixI = 1:fixationsVar(imageI)
        numObj = length( currDataPoint{fixI} );
        currDataPointCheck{fixI} = cell(numObj, 1);
        
        for objI = 1:numObj
            fprintf('Computing image check %d of %d, fixation %d of %d, object %d of %d ...', imageI, numImages, fixI, fixationsVar(imageI), ...
                objI, numObj);
            
            currDataPointCheck{fixI}{objI} = checkDataPoint_boost(currDataPoint{fixI}{objI}, params, percentilePoints, stdDevMaps);
            fprintf('done\n');            
        end
    end
end
