function [] = displaySegmentationEdgeGraphComparison( visualAttnData )
%DISPLAYSEGMENTATIONEDGEGRAPHCOMPARISON Evaluates the segmentation
%performance between edge detection and circles and graph-cut based
%segmentation

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

params = visualAttnData.params;
numGroundTruthScallops = sum( [visualAttnData.statData.groundTruth.numScallops] );
numEdgeScallops = visualAttnData.classData.results.totalScallopsEdge;
numGraphScallops = visualAttnData.classData.results.totalScallopsGraph;

%% Compute dist vectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Edge distance
[edgeRadDistVect, edgeCenterDistVect, edgeTotalDistVect] ...
    = computeDistVect( visualAttnData.statData.category, visualAttnData.statData.detection, params );

% Graph distance
[graphRadDistVect, graphCenterDistVect, graphTotalDistVect] ...
    = computeDistVect( visualAttnData.statData.categoryGraph, visualAttnData.statData.detectionGraph, params );

%% Visualization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

displayGraphEdgeStats( edgeRadDistVect, edgeCenterDistVect, edgeTotalDistVect, numEdgeScallops, ...
                            graphRadDistVect, graphCenterDistVect, graphTotalDistVect, numGraphScallops, numGroundTruthScallops);
                        
end

%% Compute Dist Vectors Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [radDistVect, centerDistVect, totalDistVect] = computeDistVect( category, detection, params )

% Initialization
numImages = params.numImages;
radDistVect = [];
centerDistVect = [];
totalDistVect = [];

% Dist vector computation
for imageI = 1:numImages
    for scallopI = 1:detection(imageI).numScallops
        numCirc = length( detection(imageI).scallop{scallopI}.circList );
        
        for circI=1:numCirc
            currFix = detection(imageI).scallop{scallopI}.circList(circI,7);
            currObj = detection(imageI).scallop{scallopI}.circList(circI,8);
            
            if (category(imageI).fixations{currFix}(currObj) == 1) ...
                    && (detection(imageI).scallop{scallopI}.circList(circI,6) < params.distScallopThreshold)
                radDistVect = [radDistVect detection(imageI).scallop{scallopI}.circList(circI,5)];
                centerDistVect = [centerDistVect detection(imageI).scallop{scallopI}.circList(circI,4)];
                totalDistVect = [totalDistVect detection(imageI).scallop{scallopI}.circList(circI,6)];
            end            
        end        
    end
end

end

%% Visualization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayGraphEdgeStats( edgeRadDistVect, edgeCenterDistVect, edgeTotalDistVect, numEdgeScallops, ...
                            graphRadDistVect, graphCenterDistVect, graphTotalDistVect, numGraphScallops, numGroundTruthScallops)
subplot(231)
hist( edgeRadDistVect, 100 );
legend( sprintf('mean = %f\n std dev = %f', mean(edgeRadDistVect), sqrt(var(edgeRadDistVect)) ));
title(sprintf('Edge radius (Detected = %f)', numEdgeScallops/numGroundTruthScallops) );

subplot(232)
hist( edgeCenterDistVect, 100 );
legend( sprintf('mean = %f\n std dev = %f', mean(edgeCenterDistVect), sqrt(var(edgeCenterDistVect)) ));
title('Edge center');

subplot(233)
hist( edgeTotalDistVect, 100 );
legend( sprintf('mean = %f\n std dev = %f', mean(edgeTotalDistVect), sqrt(var(edgeTotalDistVect)) ));
title('Edge total');

subplot(234)
hist( graphRadDistVect, 100 );
legend( sprintf('mean = %f\n std dev = %f', mean(graphRadDistVect), sqrt(var(graphRadDistVect)) ));
title(sprintf('Graph radius (Detected = %f)', numGraphScallops/numGroundTruthScallops) );

subplot(235)
hist( graphCenterDistVect, 100 );
legend( sprintf('mean = %f\n std dev = %f', mean(graphCenterDistVect), sqrt(var(graphCenterDistVect)) ));
title('Graph center');

subplot(236)
hist( graphTotalDistVect, 100 );
legend( sprintf('mean = %f\n std dev = %f', mean(graphTotalDistVect), sqrt(var(graphTotalDistVect)) ));
title('Graph total');

end







