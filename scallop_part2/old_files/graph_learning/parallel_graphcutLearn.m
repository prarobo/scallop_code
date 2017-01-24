function [ visualAttnOutData ] = parallel_graphcutLearn( visualAttnInData )
%PARALLEL_GRAPHCUT_LEARN Computes graph cut based learning on scallops

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

params = visualAttnInData.params;
groundTruth = visualAttnInData.statData.groundTruth;
labelData = visualAttnInData.graphData.labelData;
fixationData = visualAttnInData.fixationData;
numImages = params.numImages;
fixationsVar = fixationData.fixationsVar;

%% Iteration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calculate fixation wondow rectangles
rect = calcRect( fixationData.fixations, params.imageSize, params.fixationWindowSize );

if matlabpool('size') == 0
    matlabpool open local 8
end

parfor imageI = 1:numImages
    for fixI = 1:fixationsVar(imageI)       
        
        % Check scallop presence in fixation
        [numScallops, scallopLoc] = checkScallopPresence( rect{imageI}(fixI,:), groundTruth(imageI) );
        for scallopI = 1:numScallops

            % Transform scallop location
            currScallopLoc = scallopLoc(scallopI,:);
            currScallopLoc(1) = currScallopLoc(1) - rect{imageI}(fixI,1) + 1;
            currScallopLoc(2) = currScallopLoc(2) - rect{imageI}(fixI,2) + 1;

            % Get the graph cut region that contains the scallop
            scallopReg = computeScallopRegion( currScallopLoc, labelData(imageI).fixation{fixI}, params );
            
            % Get graph cut region stats
            graphLearnStats = computeGraphLearnStats( scallopReg, currScallopLoc );
        end
    end
end

end

%% Check Scallop Presence in Fixation function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [outNumScallops, outScallopLoc] = checkScallopPresence( rect, groundTruth )
    outNumScallops = 0;
    outScallopLoc = [];
    
    for scallopI = 1:groundTruth.numScallops
        currScallopLoc = groundTruth.loc(scallopI,:);
        
        if ( currScallopLoc(1)-currScallopLoc(3) >= rect(1) && currScallopLoc(1)+currScallopLoc(3) <= rect(1)+rect(3) && ...
                currScallopLoc(2)-currScallopLoc(3) >= rect(2) && currScallopLoc(2)+currScallopLoc(3) <= rect(2)+rect(3) )
            outNumScallops = outNumScallops + 1;
            outScallopLoc = [ outScallopLoc ; currScallopLoc ];
        end
    end
end

%% Function to compute graph cut region that contains the scallop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ scallopReg ] = computeScallopRegion( scallopLoc, labelImage, params )

% Initialization
areaThresholdPercent = params.contourGraphAreaThresholdPercent;
scallopReg = false( size(labelImage) );

% Creating circle mask
[x,y]=meshgrid(-(scallopLoc(1)-1):(size(labelImage,2)-scallopLoc(1)),-(scallopLoc(2)-1):(size(labelImage,1)-scallopLoc(2)));
circleMask=((x.^2+y.^2)<=scallopLoc(3)^2);

% Area Filter
regPoints = labelImage(circleMask);
maskArea = numel(regPoints);
maxReg = mode(regPoints);
maxRegArea = sum( regPoints == maxReg );

% Rejecting circles not belonging to a region and computing principal
% region
if maxRegArea < areaThresholdPercent * maskArea
    return;
else
    scallopReg = (labelImage == maxReg);
    % figure; imshow(scallopReg);
end

end

