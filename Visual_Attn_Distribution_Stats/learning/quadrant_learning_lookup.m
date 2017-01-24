function [ quadrantData, params ] = quadrant_learning_lookup( params, argNumWidthQuadrants, argNumHeightQuadrants )
%QUADRANT_LEARNING Quadrant based clustering of scallops

%% Initialization

switch nargin
    case 1
        numWidthQuadrants = 1;
        numHeightQuadrants = 1;
    case 2
        numWidthQuadrants = argNumWidthQuadrants;
        numHeightQuadrants = 1;
    case 3
        numWidthQuadrants = argNumWidthQuadrants;
        numHeightQuadrants = argNumHeightQuadrants;
    otherwise
        error('Hip hip ho, I am closing! Incompatible arguments! Error in function %s', mfilename);
end

params.numWidthQuadrants = numWidthQuadrants;
params.numHeightQuadrants = numHeightQuadrants;
params.numQuadrants = numWidthQuadrants * numHeightQuadrants;

quadrantData.quadrantInfo = createQuadrants( params );

%% Loading Data and Correction

[attributeData, scallopInfoData, params] = dataCorrection_linear( params );

%% Segragating Quadrant Based Scallops

quadrantData.loc = scallopInfoData.loc;
quadrantData.scallopQuadrant = computeQuadrant( params, quadrantData.loc, quadrantData.quadrantInfo );
quadrantData.quadrantID = computeScallopStatistics( params, attributeData, quadrantData.scallopQuadrant );

%% Selecting Specific Quadrant Attributes

% quadrantData.quadrantID = computeSelectedQuadrantAttributes( params, quadrantData );

end

%% Function to compute quadrant limits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function quadrants = createQuadrants( params )

%% Initialization
quadrantWidth = floor( params.imageSize(2)/params.numWidthQuadrants );
quadrantHeight = floor( params.imageSize(1)/params.numHeightQuadrants );
quadrants = zeros(params.numQuadrants, 4);

%% Quadrant Creation
quadrantI = 0;
for quadrantHeightI = 1:params.numHeightQuadrants
    for quadrantWidthI = 1:params.numWidthQuadrants
        quadrantI = quadrantI+1;
        quadrants(quadrantI,1) = (quadrantWidthI-1) * quadrantWidth + 1;
        quadrants(quadrantI,2) = (quadrantHeightI-1) * quadrantHeight + 1;
        
        if quadrantWidthI == params.numWidthQuadrants
            quadrants(quadrantI,3) = params.imageSize(2) - quadrants(quadrantI,1) + 1;
        else
            quadrants(quadrantI,3) = quadrantWidth;
        end
        
        if quadrantHeightI == params.numHeightQuadrants
            quadrants(quadrantI,4) = params.imageSize(1) - quadrants(quadrantI,2) + 1;
        else
            quadrants(quadrantI,4) = quadrantHeight;
        end
    end
end

end

%% Function to assign scallops to quadrants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function scallopQuadrant = computeQuadrant( params, loc, quadrantInfo )

numScallops = size(loc,1);
scallopQuadrant = zeros(numScallops,1);

for scallopI = 1:numScallops
    for quadrantI = 1:params.numQuadrants
        if (loc(scallopI,1) >= quadrantInfo(quadrantI,1) && loc(scallopI,1) < quadrantInfo(quadrantI,1)+quadrantInfo(quadrantI,3) &&...
            loc(scallopI,2) >= quadrantInfo(quadrantI,2) && loc(scallopI,2) < quadrantInfo(quadrantI,2)+quadrantInfo(quadrantI,4))
                scallopQuadrant(scallopI) = quadrantI;
                break;
        end
    end
end
end

%% Function to compute scallop statistics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function quadrantID = computeScallopStatistics( params, attributeData, scallopQuadrant )

%% Initialization
quadrantID(params.numQuadrants) = struct;
quadrantIDTemp(params.numQuadrants) = struct;
numResizeImageSize = params.resizeImageSize;
numFeatures = 1;
numQuadrants = params.numQuadrants;
numScallops = size(attributeData,1);
numBins = numResizeImageSize*numResizeImageSize*numFeatures;

for quadrantI = 1:numQuadrants    
    quadrantIDTemp(quadrantI).X = zeros(1,numBins);
    quadrantIDTemp(quadrantI).X2 = zeros(1,numBins);
    quadrantIDTemp(quadrantI).mean = zeros(1,numBins);
    quadrantIDTemp(quadrantI).stddev = zeros(1,numBins);
    quadrantIDTemp(quadrantI).num = 0;
    quadrantID(quadrantI).meanScallop = zeros(numResizeImageSize, numResizeImageSize );
    quadrantID(quadrantI).stddevScallop = zeros(numResizeImageSize, numResizeImageSize );
end

%% Mean and Variance computation
for scallopI = 1:numScallops
    quadrantIDTemp( scallopQuadrant(scallopI) ).X = quadrantIDTemp( scallopQuadrant(scallopI) ).X + attributeData(scallopI,:);
    quadrantIDTemp( scallopQuadrant(scallopI) ).X2 = quadrantIDTemp( scallopQuadrant(scallopI) ).X2 + (attributeData(scallopI,:).^2);
    quadrantIDTemp( scallopQuadrant(scallopI) ).num = quadrantIDTemp( scallopQuadrant(scallopI) ).num + 1;
end

for quadrantI = 1:numQuadrants
    if quadrantIDTemp(quadrantI).num ~= 0
        quadrantIDTemp(quadrantI).meanScallop = quadrantIDTemp(quadrantI).X./quadrantIDTemp(quadrantI).num;
    quadrantIDTemp(quadrantI).stddevScallop = (quadrantIDTemp(quadrantI).X2./quadrantIDTemp(quadrantI).num)...
                                                -quadrantIDTemp(quadrantI).meanScallop.^2;        
    else
       quadrantIDTemp(quadrantI).meanScallop = 0;
       quadrantIDTemp(quadrantI).stddevScallop = 0;
    end
end

%% Reshaping Matrices
newDims = 2;
for quadrantI = 1:numQuadrants
        currMeanMat = quadrantIDTemp(quadrantI).meanScallop;
        currStddevMat = quadrantIDTemp(quadrantI).stddevScallop;
        
        if quadrantIDTemp(quadrantI).num ~= 0
            quadrantID(quadrantI).meanScallop = transpose( reshape( currMeanMat, numResizeImageSize, numResizeImageSize ) );
            quadrantID(quadrantI).stddevScallop = transpose( reshape( currStddevMat, numResizeImageSize, numResizeImageSize ) );
        else
            quadrantID(quadrantI).meanScallop = 0;
            quadrantID(quadrantI).stddevScallop = 0;
        end
        
        quadrantID(quadrantI).numScallops = quadrantIDTemp(quadrantI).num;
        quadrantID(quadrantI).attributeData = attributeData( scallopQuadrant == quadrantI, : );
        quadrantID(quadrantI).scallopID = find( scallopQuadrant == quadrantI );
        
        % PCA reduction
        %         if ~isempty( quadrantID(quadrantI).attributeData )
        %             [quadrantID(quadrantI).mappedData, quadrantID(quadrantI).mapping] = pcaReduction( quadrantID(quadrantI).attributeData, newDims );
        %         else
        %             quadrantID(quadrantI).mappedData = 0;
        %             quadrantID(quadrantI).mapping = 0;
        %         end
        % scatter( quadrantID(quadrantI).mappedData(:,1), quadrantID(quadrantI).mappedData(:,2) );
end

end

%% Function to compute selective scallop attributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function quadrantID = computeSelectedQuadrantAttributes( params, quadrantData )

%% Initialization
quadrantID = quadrantData.quadrantID;
numQuadrants = params.numWidthQuadrants * params.numHeightQuadrants;

%% Circular Mask Generation
whiteRadius = params.quadrantCircleRad;
persistent shapeInserterWhite;
if isempty(shapeInserterWhite)
     shapeInserterWhite = vision.ShapeInserter('Shape','Circles','Fill',true,'FillColor','White','Opacity',1);
end
circlesWhite = int32([params.quadrantCircleCenter(1) params.quadrantCircleCenter(2) whiteRadius]);
mask = logical( step(shapeInserterWhite, zeros(params.resizeImageSize, params.resizeImageSize), circlesWhite) );

%% Extracting selected points

numSelAttributes = params.quadrantNumTopVarPoints + params.quadrantNumBottomVarPoints;
for quadrantI=1:numQuadrants
    quadrantID(quadrantI).numScallopsQuadrant = size(quadrantID(quadrantI).attributeData, 1);
    quadrantID(quadrantI).selAttributeData = zeros( quadrantID(quadrantI).numScallopsQuadrant, numSelAttributes );
    quadrantID(quadrantI).selAttributeGridRow = zeros( quadrantID(quadrantI).numScallopsQuadrant, numSelAttributes );
    quadrantID(quadrantI).selAttributeGridCol = zeros( quadrantID(quadrantI).numScallopsQuadrant, numSelAttributes );
    
    for scallopI=1:quadrantID(quadrantI).numScallopsQuadrant
        currScallop = transpose( reshape( quadrantID(quadrantI).attributeData(scallopI,:), ...
                            params.resizeImageSize, params.resizeImageSize ) );
        [gridCol, gridRow] = meshgrid( 1:params.resizeImageSize, 1:params.resizeImageSize );
        
        maskCurrScallop = currScallop(mask);
        maskGridRow = gridRow(mask);
        maskGridCol = gridCol(mask);
        
        maskMat = [ maskCurrScallop(:) maskGridRow(:) maskGridCol(:) ];
        maskMat = sortrows( maskMat, 1);
        
        if numSelAttributes > size(maskMat,1)
            error('Bloody bullocks! Number of required attributes less than available attributes, error in function %s', mfilename);
        end
        
        maskMatIndex = [1:params.quadrantNumBottomVarPoints size(maskMat,1)-params.quadrantNumTopVarPoints+1:size(maskMat,1)];
        quadrantID(quadrantI).selAttributeData(scallopI, :) = ( maskMat(maskMatIndex, 1) )';
        quadrantID(quadrantI).selAttributeGridRow(scallopI, :) = ( maskMat(maskMatIndex, 2) )';
        quadrantID(quadrantI).selAttributeGridCol(scallopI, :) = ( maskMat(maskMatIndex, 3) )';
        
        [quadrantID(quadrantI).mappedDataSel, quadrantID(quadrantI).mappingSel] ...
            = pcaReduction( quadrantID(quadrantI).selAttributeData, 2 );
        %         checkMat = false( params.resizeImageSize );
        %         currInd = sub2ind( size(checkMat), ...
        %             quadrantID(quadrantI).selAttributeGridRow(scallopI, :), quadrantID(quadrantI).selAttributeGridCol(scallopI, :) );
        %         checkMat(currInd) = true;
        %         imshow(checkMat);
    end        
end


end









