function [ imgFilter, processVal, imgFilterSteps, centroid ] = customScallopBinaryFilters( img, regionFilterParams )
%REGION_FILTER Filters the binary image to remove small regions
%   Uses convex hull to analyse the neighbourhood of small regions and
%   replaces them with the appropriate neighbourhood pixels.


%% Setting Defaults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgFilter=img;
processVal=true;
centroid = [0 0];

addpath('Filtering_files/CircFit');

%% Checking Aspect Ratio
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if regionFilterParams.checkAspectRatio && processVal
    aspectRatio = size(img,2)/size(img,1);
    if aspectRatio > regionFilterParams.minWidthToHeightRatio || 1/aspectRatio > regionFilterParams.minHeightToWidthRatio
        processVal=false;
        imgFilter(:)=0;
    end
end

imgFilterSteps.aspectRatio = imgFilter;
%% Removing small and large regions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if regionFilterParams.checkRegionSize && processVal
    imgLargeReg = ~bwareaopen( img, regionFilterParams.maxRegionSize, 4 );
    % figure;imshow(img_large_reg);
    imgReg = imgLargeReg & bwareaopen( imgFilter, regionFilterParams.minRegionSize, 4 );
    % figure;imshow(img_reg);
    imgFilter = imgReg;
    
    imgFilterSteps.imgLargeRegions = imgLargeReg;
    imgFilterSteps.imgLargeSmallRegions = imgReg;
end

%% Multiple regions calculations and filtering and sub region solidity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgReg = imgFilter;
if regionFilterParams.checkSubRegions && processVal
    regStats = regionprops( imgReg, 'Area', 'BoundingBox', 'ConvexArea', 'ConvexHull', 'PixelList', 'Solidity','PixelIdxList');
    numBlobs = length(regStats);
    
    for i=1:numBlobs
        if regStats(i).BoundingBox(3)<regStats(i).BoundingBox(4)
            imgReg(regStats(i).PixelIdxList)=0;
        elseif regStats(i).BoundingBox(3)/regStats(i).BoundingBox(4) >  regionFilterParams.minWidthToHeightRatio
            imgReg(regStats(i).PixelIdxList)=0;
        elseif regStats(i).Solidity >  regionFilterParams.minSolidity
            if regionFilterParams.checkSolidity
                imgReg(regStats(i).PixelIdxList)=0;
            end
        end
    end
    % imshow(img_reg);
    
    connComp = bwconncomp( imgReg );
    numPixels = cellfun(@numel,connComp.PixelIdxList);
    [~,idx] = max(numPixels);
    
    imgFilter(:) = 0;
    imgFilter(connComp.PixelIdxList{idx}) = 1;
    % imshow(img_filter)
    
    if connComp.NumObjects == 0
        processVal=false;
    end   
end
imgFilterSteps.subRegions = imgFilter;

%% Checking for circle fit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if regionFilterParams.checkCircleFit && processVal
    regStats = regionprops( imgFilter, 'Centroid', 'PixelList','PixelIdxList');
    
    [xc,yc,R,a] = circfit(regStats.PixelList(:,1),regStats.PixelList(:,2));
    
    if regStats.Centroid(2) > yc
        imgFilter(regStats.PixelIdxList)=0;
        processVal = false;
    else
        centroid(1) = regStats.Centroid(1);
        centroid(2) = regStats.Centroid(2);
    end   
end

imgFilterSteps.circFit = imgFilter;

%% Final Filtered Image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgFilterSteps.imgFilter = imgFilter;

