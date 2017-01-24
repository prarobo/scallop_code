function [ quadrantData, params ] = quadrant_learning_linear( params, argNumWidthQuadrants, argNumHeightQuadrants )
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
for quadrantWidthI = 1:params.numWidthQuadrants
    for quadrantHeightI = 1:params.numHeightQuadrants
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

scallopQuadrant = zeros(params.numScallops,1);
for scallopI = 1:params.numScallops
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
numRadBins = params.numRadBins+1;
numThetaBins = params.numThetaBins+1;
numFeatures = params.numFeatures;
numQuadrants = params.numQuadrants;
numScallops = params.numScallops;
numRadThetaFeatBins = numRadBins*numThetaBins*numFeatures;
numRadThetaBins = numRadBins*numThetaBins;

for quadrantI = 1:numQuadrants    
    quadrantIDTemp(quadrantI).X = zeros(1,numRadThetaFeatBins);
    quadrantIDTemp(quadrantI).X2 = zeros(1,numRadThetaFeatBins);
    quadrantIDTemp(quadrantI).mean = zeros(1,numRadThetaFeatBins);
    quadrantIDTemp(quadrantI).stddev = zeros(1,numRadThetaFeatBins);
    quadrantIDTemp(quadrantI).num = 0;
    quadrantID(quadrantI).meanScallop = zeros(numRadBins, numThetaBins, numFeatures);
    quadrantID(quadrantI).stddevScallop = zeros(numRadBins, numThetaBins, numFeatures);
end

%% Mean and Variance computation
for scallopI = 1:numScallops
    quadrantIDTemp( scallopQuadrant(scallopI) ).X = quadrantIDTemp( scallopQuadrant(scallopI) ).X + attributeData(scallopI,:);
    quadrantIDTemp( scallopQuadrant(scallopI) ).X2 = quadrantIDTemp( scallopQuadrant(scallopI) ).X2 + (attributeData(scallopI,:).^2);
    quadrantIDTemp( scallopQuadrant(scallopI) ).num = quadrantIDTemp( scallopQuadrant(scallopI) ).num + 1;
end

for quadrantI = 1:numQuadrants    
    quadrantIDTemp(quadrantI).meanScallop = quadrantIDTemp(quadrantI).X./quadrantIDTemp(quadrantI).num;
    quadrantIDTemp(quadrantI).stddevScallop = (quadrantIDTemp(quadrantI).X2./quadrantIDTemp(quadrantI).num)...
                                                -quadrantIDTemp(quadrantI).meanScallop.^2;
end

%% Reshaping Matrices
for quadrantI = 1:numQuadrants
    for featI = 1:numFeatures
        currMeanMat = quadrantIDTemp(quadrantI).meanScallop( (featI-1)*numRadThetaBins+1:featI*numRadThetaBins );
        currStddevMat = quadrantIDTemp(quadrantI).stddevScallop( (featI-1)*numRadThetaBins+1:featI*numRadThetaBins );
        
        quadrantID(quadrantI).meanScallop(:,:,featI) = transpose( reshape( currMeanMat, numThetaBins, numRadBins ) );
        quadrantID(quadrantI).stddevScallop(:,:,featI) = transpose( reshape( currStddevMat, numThetaBins, numRadBins ) );
    end
end

end



