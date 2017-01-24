function [ skelFilterImage, imgFilterSteps ] = scallopFilter_graph( filterImage, labelImage, imgFilterSteps )
%SCALLOPFILTER_GRAPH Uses graphcut regions to filter blobs into skeletons

skelFilterImage = false( size(filterImage) );
connComp = bwconncomp( filterImage );

for numRegI =1:connComp.NumObjects
    % currRegCombination = dec2bin(numRegI, connComp.NumObjects);
    numZeros = connComp.NumObjects - numRegI;
    currRegCombination = sprintf('%d', 10^(numRegI-1));
    for zeroI=1:numZeros
        currRegCombination = sprintf('0%s', currRegCombination);
    end
    
    currImage = regionCombinations( connComp, currRegCombination );
    % imshow(currImage);
    
    [rowI, colI] = find( currImage );
    [circleList(numRegI,1), circleList(numRegI,2), circleList(numRegI,3), ~] = circfit(colI,rowI);
    
    % Area Filter
    regPoints = labelImage(currImage);
    maskArea = numel(regPoints);
    maxReg = mode(regPoints);
    maxRegArea = sum( regPoints == maxReg );
    
    % Rejecting circles not belonging to a region
    if maxRegArea < 10
        continue;
    end
    
    % Principle region
    regionMask = (labelImage == maxReg);
    regionMask = bwperim( regionMask );
    boundaryMask = bwperim( true( size( regionMask ) ) );
    regionMask = regionMask & (~boundaryMask);
    regionIntersect = regionMask & currImage;
    % imgFilterSteps(numRegI).regionIntersect = regionIntersect;
    % figure; imshow(regionMask);
    
    skelFilterImage = skelFilterImage | regionIntersect;
end

end

%% Region Combination Image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function currImage = regionCombinations( connComp, currRegCombination )
    currImage = false(connComp.ImageSize);
    for regI = 1:connComp.NumObjects
        if( str2double(currRegCombination(regI) ) )
            currImage((connComp.PixelIdxList{regI})) = true;
        end
    end
end