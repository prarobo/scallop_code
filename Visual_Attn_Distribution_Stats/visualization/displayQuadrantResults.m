function [] = displayQuadrantResults( params, quadrantID )
%DISPLAYQUADRANTRESULTS Function to display quadrant results

%% Initialization

featI = 1;
quadrantI = 1;
numFeatures = params.numFeatures;
numQuadrants = params.numQuadrants;
showAllQuadrants = false;
showAllFeatures = false;
meanstddevSwitch = 1;

colorBarLimits = computeColorBarLimits( params, quadrantID );

figure;

%% User Interface to toggle between features and quadrants

while true
    displayNow( params, quadrantID, featI, quadrantI, showAllQuadrants, showAllFeatures, meanstddevSwitch, colorBarLimits );
    
    ch = waitforbuttonpress;
    if ch == 1
        key = get(gcf,'CurrentCharacter');
        switch key
            case 's'               
                if featI ~=1
                    featI=featI-1;
                else
                    featI = numFeatures;
                end
            case 'w'                
                if featI ~= numFeatures
                    featI = featI+1;
                else
                    featI = 1;
                end
            case 'a'               
                if quadrantI ~=1
                    quadrantI=quadrantI-1;
                else
                    quadrantI = numQuadrants;
                end
            case 'd'                
                if quadrantI ~= numQuadrants
                    quadrantI = quadrantI+1;
                else
                    quadrantI = 1;
                end
            case 'r'               
                showAllQuadrants = ~showAllQuadrants;
                if showAllFeatures
                    showAllFeatures = false;
                end
            case 'f'                
                showAllFeatures = ~showAllFeatures;
                if showAllQuadrants
                    showAllQuadrants = false;
                end
            case 't'
                if meanstddevSwitch == 1
                    meanstddevSwitch = 2;
                else
                    meanstddevSwitch = 1;
                end
            case 'q'
                close(gcf);
                break;
            otherwise
                disp('w/s-next/previous feature, d/a-next/previous quadrant, q-quit');
        end
    else
        disp('w/s-next/previous feature, d/a-next/previous quadrant, q-quit');
    end
end

end

%% Display now function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayNow( params, quadrantID, featI, quadrantI, showAllQuadrants, showAllFeatures, meanstddevSwitch, colorBarLimits )

maxRadius = params.radiusConstrictionFactor;
minRadius = 1-abs(1-params.radiusConstrictionFactor);
quadrantRow = floor(quadrantI/params.numWidthQuadrants)+1;
quadrantCol = mod( quadrantI, params.numWidthQuadrants );
if quadrantCol == 0
    quadrantCol = params.numWidthQuadrants;
    quadrantRow = quadrantRow-1;
end
numQuadrants = params.numQuadrants;
numFeatures = params.numFeatures;
numWidthQuadrants = params.numWidthQuadrants;
numHeightQuadrants = params.numHeightQuadrants;

radVect = linspace(minRadius, maxRadius, params.numRadBins+1);
thetaVect = linspace(0,2*pi, params.numThetaBins+1);

if showAllQuadrants
    for quadrantI = 1:numQuadrants
        subplot(numHeightQuadrants, numWidthQuadrants, quadrantI)
        if meanstddevSwitch == 1
            polarcont( radVect, thetaVect, quadrantID(quadrantI).meanScallop(:,:,featI) );
        else
            polarcont( radVect, thetaVect, quadrantID(quadrantI).stddevScallop(:,:,featI) );
        end
        caxis manual
        caxis([colorBarLimits(featI,3) colorBarLimits(featI,4)])        
    end
% elseif showAllFeatures
else
subplot(121)
polarcont( radVect, thetaVect, quadrantID(quadrantI).meanScallop(:,:,featI) );
caxis manual
caxis([colorBarLimits(featI,1) colorBarLimits(featI,2)])
colorbar
title( sprintf('Mean map: Feature %s Quadrant %d %d', params.featureMatCaps{featI}, quadrantRow, quadrantCol) );

subplot(122)
polarcont( radVect, thetaVect, quadrantID(quadrantI).stddevScallop(:,:,featI) );
caxis manual
caxis([colorBarLimits(featI,3) colorBarLimits(featI,4)])
colorbar
title( sprintf('Stddev map: Feature %s Quadrant %d %d', params.featureMatCaps{featI}, quadrantRow, quadrantCol) );
end

end

%% Function to Compute colorbar limits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function colorBarLimits = computeColorBarLimits( params, quadrantID )
    colorBarLimits = zeros( params.numFeatures, 4 );
    numFeatures = params.numFeatures;
    numQuadrants = params.numQuadrants;
    
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


