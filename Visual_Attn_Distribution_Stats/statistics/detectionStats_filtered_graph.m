function [ visualAttnOutData ] = detectionStats_filtered_graph( visualAttnInData )
%DETECTIONSTATS Compute detection stats

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

visualAttnOutData = visualAttnInData;
numImages = visualAttnOutData.params.numImages;
visualAttnOutData.statData.detection(numImages) = struct;
visualAttnOutData.params.centerWt = 1;
visualAttnOutData.params.radiusWt = 1;
visualAttnOutData.params.distScallopThreshold = 25;

windowRect = calcRect( visualAttnOutData.fixationData.fixations, ...
    visualAttnOutData.params.imageSize, visualAttnOutData.params.fixationWindowSize );

%% Edge image detection stats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[visualAttnOutData.statData.detection, ...
    visualAttnOutData.statData.category,...
    visualAttnOutData.segmentData.totalObjects, ...
    visualAttnOutData.statData.scallopBGDistrMatchNum] ...
    ...
    = detectionStatsCompute(   visualAttnOutData.params, ...
                            visualAttnOutData.statData.groundTruth, ...
                            visualAttnOutData.segmentData.reducedCircList,...
                            visualAttnOutData.distributionData.dataPointCheck,...
                            numImages, windowRect );

%% Graph images detection stats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[visualAttnOutData.statData.detectionGraph, ...
    visualAttnOutData.statData.categoryGraph,...
    visualAttnOutData.segmentData.totalObjectsGraph, ...
    visualAttnOutData.statData.scallopBGDistrMatchNumGraph] ...
    ...
    = detectionStatsCompute(   visualAttnOutData.params, ...
                            visualAttnOutData.statData.groundTruth, ...
                            visualAttnOutData.segmentData.reducedCircListGraph,...
                            visualAttnOutData.distributionData.dataPointCheckGraph,...
                            numImages, windowRect );

end

%% Detection Stats Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [detection, category, totalObjects, scallopBGDistrMatchNum] ...
    = detectionStatsCompute( params, groundTruth, reducedCircList, dataPointCheck, numImages, windowRect )

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

detection(numImages) = struct;
category(numImages) = struct;
totalObjects = 0;

%% Computing closest circle to actual scallop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for imageI=1:numImages
    detection(imageI).numScallops = groundTruth(imageI).numScallops;
    detection(imageI).scallop = cell( detection(imageI).numScallops, 1 );
    
    for scallopI = 1:detection(imageI).numScallops
        numFixations = length(reducedCircList(imageI).fixation);
        numCirc = cellfun( @size, reducedCircList(imageI).fixation, num2cell(ones(numFixations,1)) );
        numCirc = sum(numCirc(:));
        detection(imageI).scallop{scallopI}.circList = zeros(numCirc, 8);
        detection(imageI).scallop{scallopI}.origCirc = groundTruth(imageI).loc(scallopI,:);
        origCircList = zeros(numCirc,8);
        
        ind = 1;
        for fixI=1:numFixations
            for objI=1:size(reducedCircList(imageI).fixation{fixI}, 1)
                origCircList(ind, 1) = reducedCircList(imageI).fixation{fixI}(objI,1) + windowRect{imageI}(fixI,1) - 1;
                origCircList(ind, 2) = reducedCircList(imageI).fixation{fixI}(objI,2) + windowRect{imageI}(fixI,2) - 1;
                origCircList(ind, 3) = reducedCircList(imageI).fixation{fixI}(objI,3);
                
                origCircList(ind, 4) = euclideanDistance( detection(imageI).scallop{scallopI}.origCirc(1), ...
                                        detection(imageI).scallop{scallopI}.origCirc(2), ...
                                        origCircList(ind, 1), origCircList(ind, 2) );
                origCircList(ind, 5) = abs( detection(imageI).scallop{scallopI}.origCirc(3) - ...
                                        origCircList(ind, 3) );
                origCircList(ind, 6) = params.centerWt * origCircList(ind, 4) + ...
                                        params.radiusWt * origCircList(ind, 5);
                origCircList(ind, 7) = fixI;
                origCircList(ind, 8) = objI;
                ind = ind + 1;
            end
        end
        detection(imageI).scallop{scallopI}.circList = sortrows( origCircList, 6 );
    end    
end

%% Assigning scallop/non-scallop object circles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for imageI=1:numImages
    numFixations = length(reducedCircList(imageI).fixation);
    category(imageI).fixations = cell(numFixations,1);
    
    for fixI=1:numFixations
        numObj = size(reducedCircList(imageI).fixation{fixI},1);
        category(imageI).fixations{fixI} = zeros(numObj,1);
        totalObjects = totalObjects + numObj;
    end
    for fixI=1:numFixations
        for scallopI=1:detection(imageI).numScallops
            tempCircList = detection(imageI).scallop{scallopI}.circList;
            if tempCircList( 1, 6 ) < params.distScallopThreshold                
                category(imageI).fixations{tempCircList(1, 7)}(tempCircList(1, 8)) = 1;
            end
            for circI=2:size(tempCircList,1)
                if tempCircList( circI, 6 )< params.distScallopThreshold
                    if category(imageI).fixations{tempCircList(circI, 7)}(tempCircList(circI, 8)) ~= 1
                        category(imageI).fixations{tempCircList(circI, 7)}(tempCircList(circI, 8)) = -1;
                    end
                else
                    break;
                end
            end                        
        end
    end
end

%% Circle Nearness Filter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for imageI=1:numImages
    numFixations = length(reducedCircList(imageI).fixation);
    
    for fixI=1:numFixations
        numObj = size(reducedCircList(imageI).fixation{fixI},1);
        for objI = 1:numObj
            if(category(imageI).fixations{fixI}(objI) == 0)
                currX = reducedCircList(imageI).fixation{fixI}(objI,1) + windowRect{imageI}(fixI,1) - 1;
                currY = reducedCircList(imageI).fixation{fixI}(objI,2) + windowRect{imageI}(fixI,2) - 1;
                currRad = reducedCircList(imageI).fixation{fixI}(objI,3);
                breakCondition = false;
                
                for nFixI=1:numFixations
                    if nFixI < fixI
                        continue;
                    end
                    
                    nNumObj = size(reducedCircList(imageI).fixation{nFixI},1);
                    
                    for nObjI = 1:nNumObj
                        if nFixI == fixI && nObjI <= objI
                            continue;
                        end
                        
                        nCurrX = reducedCircList(imageI).fixation{nFixI}(nObjI,1) + windowRect{imageI}(nFixI,1) - 1;
                        nCurrY = reducedCircList(imageI).fixation{nFixI}(nObjI,2) + windowRect{imageI}(nFixI,2) - 1;
                        nCurrRad = reducedCircList(imageI).fixation{nFixI}(nObjI,3);
                        
                        centerDist = euclideanDistance(currX, currY, nCurrX, nCurrY);
                        radDist = abs(currRad - nCurrRad);
                        totalDist = params.centerWt * centerDist + params.radiusWt * radDist;
                        
                        if totalDist < params.distScallopThreshold
                            category(imageI).fixations{fixI}(objI) = -1;
                            breakCondition = true;
                            break;
                        end
                    end
                    if breakCondition
                        break;
                    end
                end               
            end
        end
    end
end

%% Computing background object circles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scallopBGDistrMatchNum = 0;
for imageI=1:numImages
    numFixations = length(reducedCircList(imageI).fixation);
    
    for fixI=1:numFixations
        numObj = size(reducedCircList(imageI).fixation{fixI},1);
        for objI = 1:numObj
            if(category(imageI).fixations{fixI}(objI) ~= -1)
                currScallopMatch = dataPointCheck{imageI}{fixI}{objI}.scallopMatchPoints;
                currBGMatch = dataPointCheck{imageI}{fixI}{objI}.bgMatchPoints;
                if currBGMatch > currScallopMatch
                    if category(imageI).fixations{fixI}(objI) == 1
                        scallopBGDistrMatchNum = scallopBGDistrMatchNum + 1;
                    end
                    category(imageI).fixations{fixI}(objI) = 2;
                end
            end
        end
    end
end

end
