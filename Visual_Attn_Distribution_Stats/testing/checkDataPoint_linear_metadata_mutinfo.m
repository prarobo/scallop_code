function [ currDataPointCheck, currDataPointMatch ] ...
    = checkDataPoint_linear_metadata_mutinfo( currDataPoint, currDataPointUnstretch, ...
                                         currRedDataPoint, currRedDataPointUnstretch, ...
                                         currGreenDataPoint, currGreenDataPointUnstretch, ...
                                         currBlueDataPoint, currBlueDataPointUnstretch, ...
                                         currConfintervals, ...
                                         currStddevConf, currMeanConf, ...
                                         currImageWidth, radiusDistr, currRadius, ...
                                         params, objI, numObj, imageI, numImages )
%CHECKDATAPOINT_LINEAR_METADATA Compute match measures

%% Initialization
resizeImageSize = params.resizeImageSize;
numDiscretizationBins = params.numDiscretizationBins;
quadrantCircleRad = params.quadrantCircleRad;
quadrantCircleCenter = params.quadrantCircleCenter;
percentTopStddevFeatures = params.percentTopStddevFeatures;
percentBottomStddevFeatures = params.percentBottomStddevFeatures;
templateShiftDist = params.templateShiftDist;

numAttr = resizeImageSize^2;
currDataPointCheck = false( 1, numAttr );

% if sum(sum(currDataPoint < 1 | currDataPoint > 10))
%     error('Bloody bonkers! Datapoint value not within 1-10 value, error in function %s', mfilename);
% end

fprintf('Computing image check %d of %d, object %d of %d ...', imageI, numImages, objI, numObj);

%% Conf Interval Match
for attrI = 1:numAttr
    if currConfintervals( currDataPoint(attrI), attrI )
        currDataPointCheck(attrI) = true;
    end
end

%% Weighting Matrices and Masks
confMatchMat = transpose( reshape( currDataPointCheck, resizeImageSize, resizeImageSize ) );

% Inverse standard deviation masks
[invStddevMask, invStddevWeightVect] = computeInvStddevWeightMat( currStddevConf, resizeImageSize, ...
                                                                 numDiscretizationBins, quadrantCircleRad, quadrantCircleCenter );

% Top Standard Deviation Matches
[topStddevMask, topStddevWeightVect] = computeTopStddevWeightMat( currStddevConf, resizeImageSize, ...
                                                                  numDiscretizationBins, quadrantCircleRad, quadrantCircleCenter, ...
                                                                  percentTopStddevFeatures );

% Template Matching                                                              
[ templateMatchList ] = computeTemplateMatches( currDataPoint, currStddevConf, currMeanConf, resizeImageSize, ...
                                          numDiscretizationBins, quadrantCircleRad, quadrantCircleCenter, ...
                                          percentBottomStddevFeatures, templateShiftDist );
% Radius Weight
[ radiusWeight ] = computeRadiusWeight( params, currRadius, currImageWidth, radiusDistr );

% Mutual Information
[ mutualInfoScores ] = computeMutualInfoScore ( params, ...
                    currDataPoint, currDataPointUnstretch, ...
                    currRedDataPoint, currRedDataPointUnstretch, ...
                    currGreenDataPoint, currGreenDataPointUnstretch, ...
                    currBlueDataPoint, currBlueDataPointUnstretch, ...
                    currStddevConf, currMeanConf);

%% Match Metric
currDataPointMatch.matchVal = sum(confMatchMat(invStddevMask));
currDataPointMatch.matchInvStddevWeightVal = sum(confMatchMat(invStddevMask).*invStddevWeightVect);
currDataPointMatch.matchTopStddevWeightVal = sum(confMatchMat(topStddevMask).*topStddevWeightVect);
currDataPointMatch.invStddevMask = invStddevMask;
currDataPointMatch.topStddevMask = topStddevMask;
currDataPointMatch.confMatchMat = confMatchMat;

currDataPointMatch.templateMatchList = templateMatchList;
[currDataPointMatch.matchTemplateVal, currDataPointMatch.matchTemplateLoc] = min(templateMatchList(:));

currDataPointMatch.radiusWt = radiusWeight;
currDataPointMatch.matchRadiusWtTemplateVal = radiusWeight*currDataPointMatch.matchTemplateVal;

currDataPointMatch.miData = mutualInfoScores.dataPt;
currDataPointMatch.miDataUnstretch = mutualInfoScores.dataPtUnstretch;

currDataPointMatch.miRedData = mutualInfoScores.redDataPt;
currDataPointMatch.miRedDataUnstretch = mutualInfoScores.redDataPtUnstretch;

currDataPointMatch.miGreenData = mutualInfoScores.greenDataPt;
currDataPointMatch.miGreenDataUnstretch = mutualInfoScores.greenDataPtUnstretch;

currDataPointMatch.miBlueData = mutualInfoScores.blueDataPt;
currDataPointMatch.miBlueDataUnstretch = mutualInfoScores.blueDataPtUnstretch;

fprintf('done\n');

end

%% Function to compute weight mat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [mask, weightVect] = computeInvStddevWeightMat( currStddevConf, resizeImageSize, ...
                                            numDiscretizationBins, quadrantCircleRad, quadrantCircleCenter )
    
%% Circular Mask Generation
whiteRadius = quadrantCircleRad;
persistent circMask;
if isempty(circMask)
    shapeInserterWhite = vision.ShapeInserter('Shape','Circles','Fill',true,'FillColor','White','Opacity',1);
    circlesWhite = int32([quadrantCircleCenter(1) quadrantCircleCenter(2) whiteRadius]);
    circMask = logical(step(shapeInserterWhite, zeros(resizeImageSize, resizeImageSize), circlesWhite));
end

%% Std dev based weights
stddevMat = transpose( reshape( currStddevConf, resizeImageSize, resizeImageSize ) );
stddevVect = stddevMat(circMask);
% stddevVect = stddevVect - min( stddevVect(:) );
% if max( stddevVect(:) ) ~= 0
%     stddevVect = stddevVect./ max( stddevVect(:) );
% end
% stddevVect = stddevVect./numDiscretizationBins;
stddevVect = stddevVect./sum(stddevVect);
weightVect = abs(1-stddevVect)./length(stddevVect);
mask = circMask;
% weightVect = 0;

end

%% Function to compute selective stddev features
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [mask, weightVect] = computeTopStddevWeightMat( currStddevConf, resizeImageSize, ...
                                                         numDiscretizationBins, quadrantCircleRad, quadrantCircleCenter, ...
                                                         percentTopStddevFeatures )

%% Circular Mask Generation

persistent circMask;
if isempty(circMask)
    whiteRadius = quadrantCircleRad;
    shapeInserterWhite = vision.ShapeInserter('Shape','Circles','Fill',true,'FillColor','White','Opacity',1);
    circlesWhite = int32([quadrantCircleCenter(1) quadrantCircleCenter(2) whiteRadius]);
    circMask = logical(step(shapeInserterWhite, zeros(resizeImageSize, resizeImageSize), circlesWhite));
    % diamondSE = strel('diamond',1);
    % circMask = imdilate(circMask, diamondSE) & (~bwperim(true(size(circMask))));
end
[gridCol, gridRow] = meshgrid( 1:resizeImageSize, 1:resizeImageSize );

%% Std dev based weights
stddevMat = transpose( reshape( currStddevConf, resizeImageSize, resizeImageSize ) );
stddevVect = stddevMat(circMask);
maskGridRow = gridRow(circMask);
maskGridCol = gridCol(circMask);
% stddevVect = stddevVect./numDiscretizationBins;
% stddevVect = stddevVect./sum(stddevVect);

maskMat = [ stddevVect(:) maskGridRow(:) maskGridCol(:) ];
maskMat = sortrows( maskMat, 1);

if numDiscretizationBins > size(maskMat,1)
    error('Bloody bullocks! Number of required attributes less than available attributes, error in function %s', mfilename);
end

numTopStddevFeatures = round(percentTopStddevFeatures*size(maskMat,1));
maskMat = maskMat(1:numTopStddevFeatures, :);
mask = sub2ind( size(stddevMat), maskMat(:,2), maskMat(:,3) );
weightVect = 1./(maskMat(:,2)+1);
% weightVect = ones(numTopStddevFeatures,1);

end

%% Function to compute template matching
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ templateMatchList ] = computeTemplateMatches( currDataPoint, currStddevConf, currMeanConf, resizeImageSize, ...
                                          numDiscretizationBins, quadrantCircleRad, quadrantCircleCenter,...
                                          percentBottomStddevFeatures, templateShiftDist)

    %% Initialization
    if (resizeImageSize-1)/2 < templateShiftDist
        error('Oops! template shift toolarge for current resize image size, error in function %s', mfilename);
    end
    dimLength = 2*templateShiftDist+1;    
    templateMatchList = zeros( dimLength, dimLength );
    
    %% Creating masks
    persistent circMaskList circCenterMaskList;
    if isempty(circMaskList)
        circMaskList = cell( dimLength, dimLength );
        circCenterMaskList = cell( dimLength, dimLength );
        whiteRadius = quadrantCircleRad;
        shapeInserterWhite = vision.ShapeInserter('Shape','Circles','Fill',true,'FillColor','White','Opacity',1);

        for rowI = 1:dimLength
            for colI = 1:dimLength
                currCenterX = quadrantCircleCenter(1)-templateShiftDist-1+colI;
                currCenterY = quadrantCircleCenter(2)-templateShiftDist-1+rowI;
                circlesWhite = int32([currCenterX currCenterY whiteRadius]);
                circMaskList{rowI, colI} = logical(step(shapeInserterWhite, zeros(resizeImageSize, resizeImageSize), circlesWhite));

                rowShift = quadrantCircleCenter(1) - currCenterY;
                colShift = quadrantCircleCenter(1) - currCenterX;
                circCenterMaskList{rowI,colI} = createCenterMask( circMaskList{rowI, colI}, rowShift, colShift );                    
            end
        end
    end
    
    %% Computing template matches
    currDataPoint = transpose( reshape( currDataPoint, resizeImageSize, resizeImageSize ));
    currMeanPoint = transpose( reshape( currMeanConf, resizeImageSize, resizeImageSize ));
    currStddevPoint = transpose( reshape( currStddevConf, resizeImageSize, resizeImageSize ));
    
    for rowI = 1:dimLength
        for colI = 1:dimLength
            
            % Applying masks
            currPoints = currDataPoint(circMaskList{rowI,colI});
            refMeanPoints = currMeanPoint(circCenterMaskList{rowI,colI});
            refStddevPoints = currStddevPoint(circCenterMaskList{rowI,colI});
            
            % Removing worst std deviation points
            numPoints = length(currPoints);
            if numPoints == 0
                error('Number of points in mask is 0! Bloody heavens I ate my hat, quitting in function %s', mfilename);
            end
            
            numBottomStddevFeatures = round(percentBottomStddevFeatures*numPoints);
            refStddevMat = [refStddevPoints (1:numPoints)'];
            refStddevMat = sortrows( refStddevMat, 1);
            selStddevVectInd = refStddevMat( 1:end-numBottomStddevFeatures ,2);
            
            selCurrPoints = currPoints(selStddevVectInd);
            selRefMeanPoints = refMeanPoints(selStddevVectInd);
            selStdDevPoints = refStddevPoints(selStddevVectInd);
            
            refRange = range(selRefMeanPoints);
            refMin = min(selRefMeanPoints);
            currRange = range(selCurrPoints);
            currMin = min(selCurrPoints);
            selCurrPoints = refMin + ((selCurrPoints-currMin).*(refRange/currRange));

            stddevVect = selStdDevPoints(:);
            % stddevVect = stddevVect./sum(stddevVect); 
            weightVect = 1./(stddevVect+1);
            
            %weightVect = ones(length(selCurrPoints),1);

            templateMatchList(rowI, colI) = (sum(sum(((abs(selCurrPoints-selRefMeanPoints)).^2).*weightVect))).^(0.5);
        end
    end
    
    % displayTemplateMatch( circMaskList, circCenterMaskList, currDataPoint, currMeanPoint, templateMatchList, dimLength );

end

%% Function to create center mask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function centerMask = createCenterMask( inMat, rowShift, colShift )

centerMask  = inMat;
if rowShift >= 0
    rowStart = 1;
    rowEndDiff = rowShift;
    rowAddBefore = rowShift;
    rowAddAfter = 0;
else
    rowStart = abs(rowShift)+1;
    rowEndDiff = 0;
    rowAddBefore = 0;
    rowAddAfter = abs(rowShift);
end

if colShift >= 0
    colStart = 1;
    colEndDiff = colShift;
    colAddBefore = colShift;
    colAddAfter = 0;
else
    colStart = abs(colShift)+1;
    colEndDiff = 0;
    colAddBefore = 0;
    colAddAfter = abs(colShift);
end

centerMask = padarray(centerMask,[rowAddBefore, colAddBefore], false, 'pre');
centerMask = padarray(centerMask,[rowAddAfter, colAddAfter], false, 'post');
centerMask = centerMask(rowStart:end-rowEndDiff, colStart:end-colEndDiff);

end

%% Function to display template match
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayTemplateMatch( circMaskList, circCenterMaskList, ...
                                currDataPoint, currMeanConf, templateMatchList, dimLength )
    

colorLimits = [0 10];
cmap = jet;

figure;
for rowI = 1:dimLength
    for colI = 1:dimLength
        subplot(dimLength, dimLength, (rowI-1)*dimLength+colI)
        imagesc( circMaskList{rowI,colI}.* currDataPoint );
        axis off
        % title('Mean reference');
        colormap(cmap);
        caxis manual
        caxis( colorLimits );
        colorbar
    end
end

figure;
for rowI = 1:dimLength
    for colI = 1:dimLength
        subplot(dimLength, dimLength, (rowI-1)*dimLength+colI)
        imagesc( circCenterMaskList{rowI,colI}.* currMeanConf );
        axis off
        % title('Mean reference');
        colormap(cmap);
        caxis manual
        caxis( colorLimits );
        colorbar
    end
end

end

%% Function to compute radius weight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function radiusWeight = computeRadiusWeight( params, currRadius, currImageWidth, radiusDistr )

%% Computing current radius in meters

currOrigRadius = currRadius * (currImageWidth/params.imageSize(2));

%% Computing the corresponding confidence interval for the current radius

ptDiff = abs( radiusDistr.mu - currOrigRadius );
sigmaNum = ptDiff/radiusDistr.sigma;
confInterval = erf( sigmaNum/sqrt(2) );

%% Radius weight

radiusWeight = confInterval;

end

%% Function to compute mutual information scores
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mutualInfoScores = computeMutualInfoScore( params, ...
                    currDataPoint, currDataPointUnstretch, ...
                    currRedDataPoint, currRedDataPointUnstretch, ...
                    currGreenDataPoint, currGreenDataPointUnstretch, ...
                    currBlueDataPoint, currBlueDataPointUnstretch, ...
                    currStddevConf, currMeanConf )


%% Mutual information calculations
mutualInfoScores.dataPt = mutualInfoAssist( currDataPoint, currMeanConf, params.resizeImageSize, params.numDiscretizationBins);
mutualInfoScores.dataPtUnstretch ...
    = mutualInfoAssist( currDataPointUnstretch, currMeanConf, params.resizeImageSize, params.numDiscretizationBins);

mutualInfoScores.redDataPt = mutualInfoAssist( currRedDataPoint, currMeanConf, params.resizeImageSize, params.numDiscretizationBins);
mutualInfoScores.redDataPtUnstretch ...
    = mutualInfoAssist( currRedDataPointUnstretch, currMeanConf, params.resizeImageSize, params.numDiscretizationBins);

mutualInfoScores.greenDataPt = mutualInfoAssist( currGreenDataPoint, currMeanConf, params.resizeImageSize, params.numDiscretizationBins);
mutualInfoScores.greenDataPtUnstretch ...
    = mutualInfoAssist( currGreenDataPointUnstretch, currMeanConf, params.resizeImageSize, params.numDiscretizationBins);

mutualInfoScores.blueDataPt = mutualInfoAssist( currBlueDataPoint, currMeanConf, params.resizeImageSize, params.numDiscretizationBins);
mutualInfoScores.blueDataPtUnstretch ...
    = mutualInfoAssist( currBlueDataPointUnstretch, currMeanConf, params.resizeImageSize, params.numDiscretizationBins);

end

%% Function to assist mutual info scores
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function miVal = mutualInfoAssist( vect1, vect2, resizeImageSize, numBins )

%% Initialize
if size(vect1) ~= size(vect2)
    error('Bloody bonker, I am going crazy. Cannot calculate mutual information for vectors of different sizes. Quitting in function %s', mfilename);
end

%% Reshaping matrices
vect1 = transpose( reshape( vect1, resizeImageSize, resizeImageSize ));
vect2 = transpose( reshape( vect2, resizeImageSize, resizeImageSize ));

%% Mutual Information
miVal = mi( vect1, vect2, numBins );

end






