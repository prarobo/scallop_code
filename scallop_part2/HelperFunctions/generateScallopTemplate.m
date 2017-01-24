function [ templateAvailable, templateMeanScallop, templateStddevScallop ] = generateScallopTemplate( scallopX, scallopY, ...
                                                                            testRadius, scallopPosition, groundTruth, ...
                                                                            templateRadiusExtnPercent, foldername )
%GENERATESCALLOPTEMPLATE Generate template based on scallop position

%% Get scallop quadrant representatives
currScallopIndices = scallopPosition.indices{scallopY, scallopX};
if ~isempty(currScallopIndices)
    scallopXList = round(groundTruth.X(currScallopIndices));
    scallopYList = round(groundTruth.Y(currScallopIndices));
    scallopRadList = round(groundTruth.radius(currScallopIndices));
    filenamesList = groundTruth.ImageName(currScallopIndices);
    testRadius = round(testRadius);
    
    % Median representative scallop
    [ ~, templateAvailable, templateMeanScallop, templateStddevScallop ] ...
                                = getQuadrantScallopTemplate( scallopXList, scallopYList, scallopRadList, testRadius, ...
                                                                    templateRadiusExtnPercent, foldername, filenamesList);
else
    templateAvailable = false;
    templateMeanScallop = 0;
    templateStddevScallop = 0;
end

end

