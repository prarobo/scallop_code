function [ currDataPointCheck, currDataPointMatch ] = checkDataPoint_linear( currDataPoint, currConfintervals, ...
                                                        currStddevConf, currMeanConf,...
                                                        params, objI, numObj, imageI, numImages )
%CHECKDATAPOINT_LINEAR Check confidence intervals

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

%% Match Metric
currDataPointMatch.matchVal = sum(confMatchMat(invStddevMask));
currDataPointMatch.matchInvStddevWeightVal = sum(confMatchMat(invStddevMask).*invStddevWeightVect);
currDataPointMatch.matchTopStddevWeightVal = sum(confMatchMat(topStddevMask).*topStddevWeightVect);
currDataPointMatch.invStddevMask = invStddevMask;
currDataPointMatch.topStddevMask = topStddevMask;
currDataPointMatch.confMatchMat = confMatchMat;
currDataPointMatch.templateMatchList = templateMatchList;
[currDataPointMatch.matchTemplateVal, currDataPointMatch.matchTemplateLoc] = min(templateMatchList(:));


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




