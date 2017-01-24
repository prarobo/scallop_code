%% BW Filtering of image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [filterImage, imgFilterSteps] = bwFilter(img, regionFilterParams, imgFilterSteps )

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filterImage = img;

%% Checking Aspect Ratio
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if regionFilterParams.checkAspectRatio
    aspectRatio = size(img,2)/size(img,1);
    if aspectRatio > regionFilterParams.minAspectRatio || 1/aspectRatio > regionFilterParams.minAspectRatio
        filterImage(:)=0;
    end
end

imgFilterSteps.aspectRatio = filterImage;
%% Removing small and large regions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if regionFilterParams.checkRegionSize
    imgLargeReg = ~bwareaopen( img, regionFilterParams.maxRegionSize, 6 );
    % figure;imshow(imgLargeReg);
    imgReg = imgLargeReg & bwareaopen( filterImage, regionFilterParams.minRegionSize, 6 );
    % figure;imshow(imgReg);
    filterImage = imgReg;
    
    imgFilterSteps.imgLargeRegions = imgLargeReg;
    imgFilterSteps.imgLargeSmallRegions = imgReg;
end

%% Multiple regions calculations and filtering and sub region solidity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgReg = filterImage;
if regionFilterParams.checkSubRegions
    regStats = regionprops( imgReg, 'Area', 'BoundingBox', 'ConvexArea', 'ConvexHull', 'PixelList', 'Solidity','PixelIdxList');
    numBlobs = length(regStats);
    
    for i=1:numBlobs
        if regStats(i).BoundingBox(4)/regStats(i).BoundingBox(3) > regionFilterParams.maxHeightToWidthRatio
            imgReg(regStats(i).PixelIdxList)=0;
        end
    end
    imgFilterSteps.width = imgReg;
    
    for i=1:numBlobs
        if regStats(i).BoundingBox(3)/regStats(i).BoundingBox(4) >  regionFilterParams.minWidthToHeightRatio
            imgReg(regStats(i).PixelIdxList)=0;
        end
    end
    imgFilterSteps.widthheight = imgReg;
    
    for i=1:numBlobs
        if regStats(i).Solidity <  regionFilterParams.minSolidity
            if regionFilterParams.checkSolidity
                imgReg(regStats(i).PixelIdxList)=0;
            end
        end
    end
    imgFilterSteps.solid = imgReg;
    % imshow(img_reg);
    
    %% Getting the top k regions by Area
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    connComp = bwconncomp( imgReg );
    numPixels = cellfun(@numel,connComp.PixelIdxList);
    filterImage(:) = 0;
    
    if connComp.NumObjects > regionFilterParams.numRegions
        for compI=1:regionFilterParams.numRegions
            [~,idx] = max(numPixels);            
            filterImage(connComp.PixelIdxList{idx}) = 1;
            numPixels(idx)=0;
            % imshow(img_filter)
        end
    else
        filterImage = imgReg;
    end
    
    %     if connComp.NumObjects == 0
    %         processVal=false;
    %     end
end
imgFilterSteps.subRegions = filterImage;

%% Checking for circle fit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% if regionFilterParams.checkCircleFit
%     regStats = regionprops( filterImage, 'Centroid', 'PixelList','PixelIdxList');
%     
%     [xc,yc,R,a] = circfit(regStats.PixelList(:,1),regStats.PixelList(:,2));
%     
%     if regStats.Centroid(2) > yc
%         filterImage(regStats.PixelIdxList)=0;
%         processVal = false;
%     else
%         centroid(1) = regStats.Centroid(1);
%         centroid(2) = regStats.Centroid(2);
%     end   
% end
% 
% % imgFilterSteps.circFit = filterImage;

%% Final Filtered Image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgFilterSteps.final = filterImage;

end


