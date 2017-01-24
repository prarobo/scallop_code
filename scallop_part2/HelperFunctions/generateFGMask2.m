function [resegAvailable, fgMask, scallopCircleMask, repScallop, repScallopThresh] = generateFGMask2( scallopX, scallopY, cropX, cropY, ...
                                                                                                    cropWindowWidth, cropWindowHeight, ...
                                                                                                    testRadius, scallopPosition, groundTruth, ...
                                                                                                    resegRadiusExtnPercent, foldername)
%GENERATEFGMASK Function to generate Foreground Mask. This function
%includes advanced filtering after thresholding to improve selection of
%foreground seeds

%% Get scallop quadrant representatives
currScallopIndices = scallopPosition.indices{scallopY, scallopX};
if ~isempty(currScallopIndices)
    scallopXList = round(groundTruth.X(currScallopIndices));
    scallopYList = round(groundTruth.Y(currScallopIndices));
    scallopRadList = round(groundTruth.radius(currScallopIndices));
    filenamesList = groundTruth.ImageName(currScallopIndices);
    testRadius = round(testRadius);
    
    % Median representative scallop
    [ ~, resegAvailable, repScallop ] = getQuadrantScallop( scallopXList, scallopYList, scallopRadList, testRadius, ...
                                                            resegRadiusExtnPercent, foldername, filenamesList);
else
    resegAvailable = false;
end

%% Thresholding representative scallop and combine with circular mask
if ~resegAvailable
    repScallop = 0;
    scallopCircleMask = 0;
    repScallopThresh = 0;
    fgMask = 0;
else
    % Representative scallop thresholding
    grayImageInv = imcomplement(repScallop);
    threshImage = smartThresholder(grayImageInv);
    bwImage = filterBW(threshImage);
    
    extnTestDia = round(2*testRadius*(1+resegRadiusExtnPercent));
    bbScallop = computeBB_xylim(cropX, cropY, extnTestDia, extnTestDia, cropWindowWidth, cropWindowHeight);
    bbScallopWidth = bbScallop(2)-bbScallop(1)+1;
    bbScallopHeight = bbScallop(4)-bbScallop(3)+1;
    
    % Combining representative scallop with circle mask
    if abs(bbScallopWidth-extnTestDia) > 2 || abs(bbScallopHeight-extnTestDia) > 2
        resegAvailable = false;
        repScallop = 0;
        scallopCircleMask = 0;
        repScallopThresh = 0;
        fgMask = 0;
    else
        bwImage = logical(imresize(bwImage, [bbScallopHeight, bbScallopWidth]));
        
        scallopMask = getCircMask(round(bbScallopWidth/2), round(bbScallopHeight/2), round(extnTestDia/2), bbScallopWidth, bbScallopHeight);
        scallopMask = logical(imresize(scallopMask, [bbScallopHeight, bbScallopWidth]));
        
        combinedMask = imfill(bwImage & scallopMask, 'holes');
        combinedMask = filterBW(combinedMask);
        
        fgMask = false(cropWindowHeight, cropWindowWidth);
        fgMask(bbScallop(1):bbScallop(2), bbScallop(3):bbScallop(4)) = combinedMask;
        
        scallopCircleMask = false(cropWindowHeight, cropWindowWidth);
        scallopCircleMask(bbScallop(1):bbScallop(2), bbScallop(3):bbScallop(4)) = scallopMask;
        
        repScallopThresh = false(cropWindowHeight, cropWindowWidth);
        repScallopThresh(bbScallop(1):bbScallop(2), bbScallop(3):bbScallop(4)) = bwImage;
    end
end
