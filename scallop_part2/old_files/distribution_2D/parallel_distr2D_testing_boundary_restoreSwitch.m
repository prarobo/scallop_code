function [ distributionData, params] ...
    = parallel_distr2D_testing_boundary_restoreSwitch( params, ...
                                                        fileInfo, ...
                                                        fixationData, ...
                                                        segmentData, ...
                                                        confIntervalData, ...
                                                        scallopLookupParams, ...
                                                        discretOn, checkOn, writeOn, restoreOn,...
                                                        radiusDistr, ...
                                                        distributionData )
%parallel_distr2D_testing_linear Reads scallop pixels from test data set

%% Initialization

switch nargin
    case 11
        fprintf('Distribution data not available\n');
    case 12
        fprintf('Partial Distribution data available\n');
    otherwise
        error('Phew! I am screwed! Incompatible arguments in function %s', mfilename);
end    

params.percentTopStddevFeatures = 0.25;
params.percentBottomStddevFeatures = 0.25;
params.templateShiftDist  = 1;
params.resizeImageSize = scallopLookupParams.resizeImageSize;
params.radiusConstrictionFactor = scallopLookupParams.radiusConstrictionFactor;
params.globalAdjustOn = scallopLookupParams.globalAdjustOn;
params.localAdjustOn = scallopLookupParams.localAdjustOn;
params.numDiscretizationBins = scallopLookupParams.numDiscretizationBins;
params.quadrantCircleRad = scallopLookupParams.quadrantCircleRad;
params.quadrantCircleCenter = scallopLookupParams.quadrantCircleCenter;
numImages = params.numImages;
foldername = fileInfo.foldername;
filename = fileInfo.filename;
objFixList = segmentData.reducedCircList;
numAttributes = params.resizeImageSize^2;
   
dataPoint = cell(numImages,1);
dataPointCheck = cell(numImages,1);
dataPointMatch = cell(numImages,1);
dataAvailable =  cell(numImages,1);

if discretOn
    windowRect = calcRect( fixationData.fixations, params.imageSize, params.fixationWindowSize );
    [objList, origObjList] = generateObjList( windowRect, objFixList, fixationData.fixationsVar, params );
end

% if matlabpool('size') == 0
%     matlabpool open local 7
% end

imageStatusComplete = false(numImages, 1);
imageCounter = 0;

%% Discretization

if discretOn
    
    % Restoring data if available
    if restoreOn
        [imageStatusComplete, dataPoint] = restorePointHandler_discretization( params, imageStatusComplete, dataPoint );
    end
    
    for imageI=1:numImages

        % Processing unprocessed images only
        if( ~imageStatusComplete(imageI) )

            if restoreOn
                if imageCounter == params.restoreInterval
                    [imageStatusComplete, dataPoint] = restorePointHandler_discretization( params, imageStatusComplete, dataPoint );
                    imageCounter = 1;
                else
                    imageCounter = imageCounter + 1;
                end
            end

            fprintf('Computing image discretization %d of %d ...', imageI, numImages);
            currFilename = fullfile( foldername, filename{imageI} );
            currObjList = objList{imageI};
            dataPoint{imageI} = parallelImageProcessing( currFilename, currObjList, params, imageI );
            fprintf('done\n');
        end
    end
else
    dataPoint = distributionData.dataPoint;
    objList = distributionData.objList;
    origObjList = distributionData.origObjList;
end

%% Checking

if checkOn
%     if matlabpool('size') ~= 7
%         matlabpool close
%         matlabpool open local 7
%     end
    
    for imageI=1:numImages
        numObj = length( dataPoint{imageI} );
        currDataPointCheck = cell(numObj,1);
        currDataPointMatch = cell(numObj,1);
        currDataPoint = dataPoint{imageI};
        
        ind = sub2ind( size(confIntervalData.confInterval), round(objList{imageI}(:,2)), round(objList{imageI}(:,1)) );
        currConfIntervals = confIntervalData.confInterval(ind);  
        currIsValidConf = confIntervalData.isValid(ind);
        currStddevConf = confIntervalData.stddevPoints(ind);
        currMeanConf = confIntervalData.meanPoints(ind);
        currImageWidth = fileInfo.imageWidth(imageI);
        currObjList = objList{imageI};
        
        for objI = 1:numObj
            if currIsValidConf(objI)
                currRadius = currObjList(objI,3);
                [currDataPointCheck{objI}, currDataPointMatch{objI}] ...
                    = checkDataPoint_linear_metadata( currDataPoint{objI}, currConfIntervals{objI}, ...
                    currStddevConf{objI}, currMeanConf{objI}, ...
                    currImageWidth, radiusDistr, currRadius, ...
                    params, objI, numObj, imageI, numImages);
            else
                currDataPointCheck{objI} = [];
                currDataPointMatch{objI} = [];
            end
        end
        dataPointCheck{imageI} = currDataPointCheck;
        dataPointMatch{imageI} = currDataPointMatch;
        dataAvailable{imageI} = currIsValidConf;
    end
    %     matlabpool close
end

%% Writing Feature Attributes and Saving Scallop Information to CSV file
fid = fopen( params.attrFile_testing, 'w' );
fclose(fid);
fid = fopen( params.objInfoFile, 'w' );
fclose(fid);

if writeOn
    for imageI=1:numImages
        numObj = length( dataPoint{imageI} );
        for objI = 1:numObj
            writeAttrCSV_testing_linear( params.attrFile_testing, dataPoint{imageI}{objI}, imageI, numImages, objI, numObj, numAttributes);
        end
    end
end

%% Outputs
distributionData.dataPoint = dataPoint;
distributionData.dataPointCheck = dataPointCheck;
distributionData.dataPointMatch = dataPointMatch;
distributionData.objList = objList;
distributionData.origObjList = origObjList;
distributionData.dataAvailable = dataAvailable;

end

%% Parallel function discretization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ currDataPointCum ] = parallelImageProcessing( currFilename, currObjList, params, imageI )

numImages = params.numImages;
currImage = imread( currFilename );

%% Feature Channels

if params.globalAdjustOn
    currImage = imadjust( currImage, stretchlim(currImage) );
end
currGrayImage = rgb2gray( currImage );
% imshow(currGrayImage);

numObj = size( currObjList, 1 );
currDataPointCum = cell(numObj, 1);

for objI = 1:numObj
    % fprintf('Computing image discretization %d of %d, object %d of %d ...', imageI, numImages, objI, numObj);

    centerX = currObjList(objI,1);
    centerY = currObjList(objI,2);
    radius = currObjList(objI,3);
      
    %% Distributions of pixels
    
    currDataPoint.grayMap = bin2DScallop_linear_testing(currGrayImage,...
        centerX,...
        centerY,...
        radius,...
        params);
    
    currDataPointCum{objI} = reshape(currDataPoint.grayMap',1,numel(currDataPoint.grayMap));
    % fprintf('done\n');
end
end

%% Generate Object List
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [objList, origObjList] = generateObjList( windowRect, objFixList, fixationsVar, params )

%% Initialization
numImages = params.numImages;
objList = cell(numImages,1);
origObjList = cell(numImages,1);

%% Generate object list
for imageI=1:numImages
    numFixations = fixationsVar(imageI);
    numObjList = cellfun(@size, objFixList(imageI).fixation, num2cell(ones(numFixations,1)) );
    currObjList=zeros( sum(numObjList(:)), 5 );
    currIndex = 1;
    
    for fixI=1:numFixations
        numFixObj = numObjList(fixI);
        currObjList(currIndex:currIndex+numFixObj-1,1) = objFixList(imageI).fixation{fixI}(:,1) + windowRect{imageI}(fixI,1) - 1;
        currObjList(currIndex:currIndex+numFixObj-1,2) = objFixList(imageI).fixation{fixI}(:,2) + windowRect{imageI}(fixI,2) - 1;
        currObjList(currIndex:currIndex+numFixObj-1,3) = objFixList(imageI).fixation{fixI}(:,3);
        currObjList(currIndex:currIndex+numFixObj-1,4) = fixI;
        
        currIndex = currIndex + numFixObj;
    end
    
    filterObjList = filterCircles_boundary( currObjList, params.imageSize, params );
    numObjects = size( filterObjList, 1 );
    filterObjList(:,5) = (1:numObjects)';
    objList{imageI} = filterObjList;
    origObjList{imageI} = currObjList;
end

end








