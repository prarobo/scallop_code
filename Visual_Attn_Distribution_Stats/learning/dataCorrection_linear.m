function [ attributeData, scallopInfoData, params ] = dataCorrection_linear( params )
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
    numTotalFeatures = params.resizeImageSize^2;
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

% Removing Scallops cut off by boundaries
keepIndex = (scallopInfoData.diff(:,1) == 0) & (scallopInfoData.diff(:,2) == 0);
attributeData = attributeData(keepIndex,:);
scallopInfoData.loc = scallopInfoData.loc(keepIndex,:);
scallopInfoData.filename = scallopInfoData.filename(keepIndex,:);
scallopInfoData.rect = scallopInfoData.rect(keepIndex,:);
scallopInfoData.diff = scallopInfoData.diff(keepIndex,:);

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

