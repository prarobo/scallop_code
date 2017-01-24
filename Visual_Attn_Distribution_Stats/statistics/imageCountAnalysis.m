function [ classData, params ] = imageCountAnalysis( params, distributionData, groundTruth, classData )
%IMAGECOUNTANALYSIS Summary of this function goes here
%   Detailed explanation goes here

%% Initialization
classThreshold = classData.classificationResults.scallopVerdictThreshold;
trueScallopsImageCount = 0;
falseScallopsImageCount = 0;
numImages = params.numImages;

for imageI=1:numImages
    numObj = size( distributionData.objList{imageI}, 1 );
    scallopsPresent = true;
    
    if groundTruth(imageI).numScallops == 0
        scallopsPresent = false;
    end
    
    for objI=1:numObj
        if distributionData.dataPointMatch{imageI}{objI}.(params.matchMetric) <= classThreshold
            if scallopsPresent
                trueScallopsImageCount = trueScallopsImageCount + 1;
            else
                falseScallopsImageCount = falseScallopsImageCount + 1;
            end
            break;
        end
    end

classData.imageCountResults.trueScallopsImageCount = trueScallopsImageCount;
classData.imageCountResults.falseScallopsImageCount = falseScallopsImageCount;

end
