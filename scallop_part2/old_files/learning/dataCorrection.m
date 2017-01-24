function [ attributeData, scallopInfoData, params ] = dataCorrection( params )
%DATACORRECTION Summary of this function goes here
%   Detailed explanation goes here

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin ~= 1
    error('Boo! Incompatible arguments in function %s', mfilename );
end
% params.attrDiscardThreshold = 0.2;
params.attrDiscardThreshold = 0;
params.missingAttrReplacementVal = params.numDiscretizationBins;

if params.attrDiscardThreshold ~= 0
    error('Could cause errors in circular reconstruction, error in function %s', mfilename );
end

%% Loading Attributes and ScallopInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if exist(params.attrFile, 'file')
    numTotalFeatures = (params.numRadBins+1) * (params.numThetaBins+1) * params.numFeatures;
    attributeData = loadAttributeData( params.attrFile, numTotalFeatures );
else
    error('Zombies ate my brains! I cannot find cluster attributes file! Error in function %s', mfilename);
end

if exist(params.scallopInfoFile, 'file')
    scallopInfoData = loadScallopInfoData( params.scallopInfoFile );
else
    error('Zombies ate my brains! I cannot find scallop info file! Error in function %s', mfilename);
end

%% Data Correction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Removing attributes with insufficient points
attrVect = true(1, size(attributeData,2) );
for colI = 1:size(attributeData,2)
    if numel( find(attributeData( :,colI )~=-1 ) )  < params.attrDiscardThreshold * size(attributeData,1)
        attrVect(colI) = false;
    end
end
index = 1;
newAttrData = zeros( size(attributeData,1), sum( attrVect(:) ) );
for colI = 1:size(attributeData,2)
    if attrVect(colI)
        newAttrData(:,index) = attributeData(:,colI);
        index = index + 1;
    end
end
attributeData = newAttrData;

% Replacing missing values
for colI = 1:size(attributeData,2)
    currColData = attributeData(:,colI);
    nonZeroAttrData = currColData( currColData ~= -1 );
    if ~isempty(nonZeroAttrData)
        currColMean = mean( nonZeroAttrData );
        attributeData(:,colI) = round( currColData + (currColData == -1).*currColMean );
    else
        attributeData(:,colI) = params.missingAttrReplacementVal;
    end
end

attributeData( attributeData > params.numDiscretizationBins ) = params.numDiscretizationBins;

end

