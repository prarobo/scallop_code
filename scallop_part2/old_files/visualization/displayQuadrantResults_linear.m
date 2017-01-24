function [] = displayQuadrantResults_linear( params, quadrantID )
%DISPLAYQUADRANTRESULTS Function to display quadrant results

%% Initialization

colorBarLimits = computeColorBarLimits( params, quadrantID );

numQuadrants = params.numQuadrants;
numFeatures = 1;
numWidthQuadrants = params.numWidthQuadrants;
numHeightQuadrants = params.numHeightQuadrants;

figure;

for quadrantI = 1:numQuadrants
    subplot(numHeightQuadrants, numWidthQuadrants, quadrantI)
    imagesc( quadrantID(quadrantI).meanScallop );
    axis off
    %caxis manual
    %caxis([colorBarLimits(1) colorBarLimits(2)])
end

figure;

for quadrantI = 1:numQuadrants
    subplot(numHeightQuadrants, numWidthQuadrants, quadrantI)
    imagesc( quadrantID(quadrantI).stddevScallop );
    axis off
    %caxis manual
    %caxis([colorBarLimits(3) colorBarLimits(4)])
end

% elseif showAllFeatures

% subplot(121)
% polarcont( radVect, thetaVect, quadrantID(quadrantI).meanScallop(:,:,featI) );
% caxis manual
% caxis([colorBarLimits(featI,1) colorBarLimits(featI,2)])
% colorbar
% title( sprintf('Mean map: Feature %s Quadrant %d %d', params.featureMatCaps{featI}, quadrantRow, quadrantCol) );
% 
% subplot(122)
% polarcont( radVect, thetaVect, quadrantID(quadrantI).stddevScallop(:,:,featI) );
% caxis manual
% caxis([colorBarLimits(featI,3) colorBarLimits(featI,4)])
% colorbar
% title( sprintf('Stddev map: Feature %s Quadrant %d %d', params.featureMatCaps{featI}, quadrantRow, quadrantCol) );

end

%% Function to Compute colorbar limits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function colorBarLimits = computeColorBarLimits( params, quadrantID )    
    numFeatures = 1;
    numQuadrants = params.numQuadrants;
    colorBarLimits = zeros( numFeatures, 4 );
    
    for featI = 1:numFeatures
        minLimitMean = inf;
        maxLimitMean = -inf;
        minLimitStddev = inf;
        maxLimitStddev = -inf;
        
        for quadrantI = 1:numQuadrants
            currMat = quadrantID(quadrantI).meanScallop(:,:,featI);
            maxLimitMean = max( max(currMat(:)), maxLimitMean );
            minLimitMean = min( min(currMat(:)), minLimitMean );

            currMat = quadrantID(quadrantI).stddevScallop(:,:,featI);
            maxLimitStddev = max( max(currMat(:)), maxLimitStddev );
            minLimitStddev = min( min(currMat(:)), minLimitStddev );
        end
        
        colorBarLimits(featI,:) = [minLimitMean maxLimitMean minLimitStddev maxLimitStddev];
    end
end


