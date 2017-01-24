function [resegAvailable, fgMask, scallopCircleMask, sliverMask, repScallop, repScallopThresh, centerMask] ...
                                        = generateFGMask( scallopX, scallopY, cropX, cropY, ...
                                                            cropWindowWidth, cropWindowHeight, ...
                                                            testRadius, scallopPosition, groundTruth, ...
                                                            resegRadiusExtnPercent, scallopMaskThicknessPercent, ...
                                                            crescentAngle, centerRadiusPercent, foldername)
%GENERATEFGMASK Function to generate Foreground Mask

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
    repScallop = 0;
end

sliverMask = 0;
scallopCircleMask = 0;
repScallopThresh = 0;
fgMask = 0;
centerMask = 0;

%% Thresholding representative scallop and combine with circular mask
if resegAvailable
    % Representative scallop thresholding
    grayImageInv = imcomplement(repScallop);
    thresh = graythresh(grayImageInv);
    threshImage = im2bw(grayImageInv, thresh);
    bwImage = filterBWImage(threshImage);
    
    extnTestDia = round(2*testRadius*(1+resegRadiusExtnPercent));
    extnTestRad = round(extnTestDia/2);
    bbScallop = computeBB_xylim(cropX, cropY, extnTestDia, extnTestDia, cropWindowWidth, cropWindowHeight);
    bbScallopWidth = bbScallop(2)-bbScallop(1)+1;
    bbScallopHeight = bbScallop(4)-bbScallop(3)+1;
    
    % Combining representative scallop with circle mask
    if ~(abs(bbScallopWidth-extnTestDia) > 2 || abs(bbScallopHeight-extnTestDia) > 2)
        
        repScallop = imresize(repScallop, [bbScallopHeight, bbScallopWidth]);
        bwImage = logical(imresize(bwImage, [bbScallopHeight, bbScallopWidth]));
        
        % Inner, outer and upper scallop masks
        scallopOuterMask = getCircMask(round(bbScallopWidth/2), round(bbScallopHeight/2), extnTestRad, bbScallopWidth, bbScallopHeight);
        scallopInnerMask = getCircMask(round(bbScallopWidth/2), ...
                                        round(bbScallopHeight/2), ...
                                        round(extnTestRad*(1-scallopMaskThicknessPercent)), ...
                                        bbScallopWidth, bbScallopHeight);
        scallopUpperMask = true(bbScallopHeight, bbScallopWidth);
        scallopUpperMask(round(0.75*bbScallopHeight):end,:) = false;
        
        % Circular scallop sliver mask
        sliverMask = logical(imresize(scallopOuterMask & ~scallopInnerMask & scallopUpperMask, [bbScallopHeight, bbScallopWidth]));
        sliverArea = sum(sliverMask(:));
        
        % Scallop sliver combined with threshold
        combinedSliverMask = imfill(bwImage & sliverMask, 'holes');
        combinedSliverMask = filterBWImage(combinedSliverMask);
        
        % Sliver thresholding
        repScallopSliver = repScallop.*uint8(combinedSliverMask);
        sliverThresh =  smartThreshold(repScallopSliver, combinedSliverMask, sliverArea, crescentAngle);
        crescentMask = ~im2bw(repScallopSliver, sliverThresh) & combinedSliverMask;
        crescentMask = filterBWImage(crescentMask);
        
        fgMask = false(cropWindowHeight, cropWindowWidth);
        fgMask(bbScallop(1):bbScallop(2), bbScallop(3):bbScallop(4)) = crescentMask;
        
        scallopCircleMask = false(cropWindowHeight, cropWindowWidth);
        scallopCircleMask(bbScallop(1):bbScallop(2), bbScallop(3):bbScallop(4)) = scallopOuterMask;
        
        repScallopThresh = false(cropWindowHeight, cropWindowWidth);
        repScallopThresh(bbScallop(1):bbScallop(2), bbScallop(3):bbScallop(4)) = bwImage;
        
        % Center mask
        halfMask = true(bbScallopHeight, bbScallopWidth);
        halfMask(round(0.5*bbScallopHeight):end,:) = false;
        centerRadius = round(centerRadiusPercent*testRadius);
        centerScallopMask = getCircMask(round(bbScallopWidth/2), round(bbScallopHeight/2), centerRadius, bbScallopWidth, bbScallopHeight);
        centerScallopMask = centerScallopMask & halfMask;
        centerMask = false(cropWindowHeight, cropWindowWidth);
        centerMask(bbScallop(1):bbScallop(2), bbScallop(3):bbScallop(4)) = centerScallopMask;
    end
end
end

%% Function to compute threshold value that will cover a fixed number of pixels
function threshVal = smartThreshold(inImage, sliverMask, sliverArea, crescentAngle)
    
    % Area of crescent to capture
    threshArea = (crescentAngle/360)*sliverArea;
    threshAreaError = 5;
    numIter = 20;
    
    % Initializing thresholds for newton-raphson
    threshOld1 = graythresh(inImage(sliverMask));    
    threshImage = filterBWImage(~im2bw(inImage, threshOld1) & sliverMask);
    numPixOld1 = sum(threshImage(:));
    if abs(numPixOld1-threshArea) < threshAreaError
        threshVal = threshOld1;
        return;
    end
    
    if numPixOld1>threshArea
        threshOld2 = 0.001;
    else
        threshOld2 = 1;
    end

    threshImage = filterBWImage(~im2bw(inImage, threshOld2) & sliverMask);
    numPixOld2 = sum(threshImage(:));
    if abs(numPixOld2-threshArea) < threshAreaError
        threshVal = threshOld2;
        return;
    end
    
    threshNew = (threshOld1+threshOld2)/2;
    
    for i=1:numIter
        threshImage = filterBWImage(~im2bw(inImage, threshNew) & sliverMask);
        numPixNew = sum(threshImage(:));
                
        if abs(numPixOld1-numPixOld2) < threshAreaError || abs(numPixNew-threshArea) < threshAreaError
            threshVal = threshNew;
            return;
        end
        
        if (numPixOld1 < threshArea && numPixOld2 < threshArea) || (numPixOld1 > threshArea && numPixOld2 > threshArea)
            error('Newton-raphson limits on same side');
        end
        
        if numPixNew > threshArea
            threshOld1 = min(threshOld1,threshOld2);
            numPixOld1 = min(numPixOld1, numPixOld2);
        else
            threshOld1 = max(threshOld1,threshOld2);
            numPixOld1 = max(numPixOld1, numPixOld2);
        end
        
        threshOld2 = threshNew;
        numPixOld2 = numPixNew;
        threshNew = (threshOld1+threshOld2)/2;    
    end
    
    if abs(numPixOld1-threshArea) < abs(numPixOld2-threshArea)
        threshVal = threshOld1;
    else
        threshVal = threshOld2;
    end
end
