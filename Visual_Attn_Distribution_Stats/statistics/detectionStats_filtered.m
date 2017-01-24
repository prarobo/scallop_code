function [ visualAttnOutData ] = detectionStats_filtered( visualAttnInData )
%DETECTIONSTATS Compute detection stats

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

visualAttnOutData = visualAttnInData;
numImages = visualAttnOutData.params.numImages;
visualAttnOutData.statData.detection(numImages) = struct;
visualAttnOutData.params.centerWt = 1;
visualAttnOutData.params.radiusWt = 0.5;
visualAttnOutData.params.distScallopThreshold = 20;
visualAttnOutData.params.distCenterThreshold = 10;
visualAttnOutData.params.percentRadiusThreshold = 0.30;
% visualAttnOutData.segmentData.totalObjects = 0;

windowRect = calcRect( visualAttnOutData.fixationData.fixations, ...
    visualAttnOutData.params.imageSize, visualAttnOutData.params.fixationWindowSize );

%% Computing closest circle to actual scallop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for imageI=1:numImages
    visualAttnOutData.statData.detection(imageI).numScallops = visualAttnOutData.statData.groundTruth(imageI).numScallops;
    visualAttnOutData.statData.detection(imageI).scallop = cell( visualAttnOutData.statData.detection(imageI).numScallops, 1 );
    for scallopI = 1:visualAttnOutData.statData.detection(imageI).numScallops
        numFixations = length(visualAttnOutData.segmentData.reducedCircList(imageI).fixation);
        numCirc = cellfun( @size, visualAttnOutData.segmentData.reducedCircList(imageI).fixation, num2cell(ones(numFixations,1)) );
        numCirc = sum(numCirc(:));
        visualAttnOutData.statData.detection(imageI).scallop{scallopI}.circList = zeros(numCirc, 8);
        visualAttnOutData.statData.detection(imageI).scallop{scallopI}.origCirc = visualAttnOutData.statData.groundTruth(imageI).loc(scallopI,:);
        origCircList = zeros(numCirc,8);
        
        ind = 1;
        for fixI=1:numFixations
            for objI=1:size(visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI}, 1)
                origCircList(ind, 1) = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,1) + windowRect{imageI}(fixI,1) - 1;
                origCircList(ind, 2) = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,2) + windowRect{imageI}(fixI,2) - 1;
                origCircList(ind, 3) = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,3);
                
                origCircList(ind, 4) = euclideanDistance( visualAttnOutData.statData.detection(imageI).scallop{scallopI}.origCirc(1), ...
                    visualAttnOutData.statData.detection(imageI).scallop{scallopI}.origCirc(2), ...
                    origCircList(ind, 1), origCircList(ind, 2) );
                origCircList(ind, 5) = visualAttnOutData.statData.detection(imageI).scallop{scallopI}.origCirc(3) - ...
                    origCircList(ind, 3);
                origCircList(ind, 6) = visualAttnOutData.params.centerWt * abs( origCircList(ind, 4) )+ ...
                    visualAttnOutData.params.radiusWt * abs( origCircList(ind, 5) );
                origCircList(ind, 7) = fixI;
                origCircList(ind, 8) = objI;
                ind = ind + 1;
            end
        end
        visualAttnOutData.statData.detection(imageI).scallop{scallopI}.circList = sortrows( origCircList, 6 );
    end
    
end

%% Assigning scallop/non-scallop object circles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for imageI=1:numImages
    numFixations = length(visualAttnOutData.segmentData.reducedCircList(imageI).fixation);
    visualAttnOutData.statData.category(imageI).fixations = cell(numFixations,1);
    
    for fixI=1:numFixations
        numObj = size(visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI},1);
        visualAttnOutData.statData.category(imageI).fixations{fixI} = zeros(numObj,1);
        % visualAttnOutData.segmentData.totalObjects = visualAttnOutData.segmentData.totalObjects + numObj;
    end
    for fixI=1:numFixations
        for scallopI=1:visualAttnOutData.statData.detection(imageI).numScallops
            tempCircList = visualAttnOutData.statData.detection(imageI).scallop{scallopI}.circList;
            visualAttnOutData.statData.detection(imageI).scallop{scallopI}.foundScallop = false;
            visualAttnOutData.statData.detection(imageI).scallop{scallopI}.errorScallop = zeros(1,3);
            
            if ~isempty(tempCircList)
                % if tempCircList( 1, 6 ) < visualAttnOutData.params.distScallopThreshold
                if abs( tempCircList( 1, 4 ) )< visualAttnOutData.params.distCenterThreshold && ...
                   abs( tempCircList( 1, 5 ) )< visualAttnOutData.params.percentRadiusThreshold ...
                   * visualAttnOutData.statData.detection(imageI).scallop{scallopI}.origCirc(3)    
               
                    visualAttnOutData.statData.category(imageI).fixations{tempCircList(1, 7)}(tempCircList(1, 8)) = 1;
                    visualAttnOutData.statData.detection(imageI).scallop{scallopI}.foundScallop = true;
                    visualAttnOutData.statData.detection(imageI).scallop{scallopI}.errorScallop = tempCircList( 1, 4:6 );
                end
                for circI=2:size(tempCircList,1)
                    % if tempCircList( circI, 6 )< visualAttnOutData.params.distScallopThreshold
                    if abs( tempCircList( 1, 4 ) )< visualAttnOutData.params.distCenterThreshold && ...
                            abs( tempCircList( 1, 5 ) )< visualAttnOutData.params.percentRadiusThreshold ...
                            * visualAttnOutData.statData.detection(imageI).scallop{scallopI}.origCirc(3)
                        
                        if visualAttnOutData.statData.category(imageI).fixations{tempCircList(circI, 7)}(tempCircList(circI, 8)) ~= 1
                            visualAttnOutData.statData.category(imageI).fixations{tempCircList(circI, 7)}(tempCircList(circI, 8)) = -1;
                        end
                    else
                        break;
                    end
                end
            end
        end
    end
end

%% Circle Nearness Filter to reduce non scallop circles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for imageI=1:numImages
    numFixations = length(visualAttnOutData.segmentData.reducedCircList(imageI).fixation);
    
    for fixI=1:numFixations
        numObj = size(visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI},1);
        for objI = 1:numObj
            if(visualAttnOutData.statData.category(imageI).fixations{fixI}(objI) == 0)
                currX = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,1) + windowRect{imageI}(fixI,1) - 1;
                currY = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,2) + windowRect{imageI}(fixI,2) - 1;
                currRad = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,3);
                breakCondition = false;
                
                for nFixI=1:numFixations
                    if nFixI < fixI
                        continue;
                    end
                    
                    nNumObj = size(visualAttnOutData.segmentData.reducedCircList(imageI).fixation{nFixI},1);
                    
                    for nObjI = 1:nNumObj
                        if nFixI == fixI && nObjI <= objI
                            continue;
                        end
                        
                        nCurrX = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{nFixI}(nObjI,1) + windowRect{imageI}(nFixI,1) - 1;
                        nCurrY = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{nFixI}(nObjI,2) + windowRect{imageI}(nFixI,2) - 1;
                        nCurrRad = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{nFixI}(nObjI,3);
                        
                        centerDist = euclideanDistance(currX, currY, nCurrX, nCurrY);
                        radDist = abs(currRad - nCurrRad);
                        totalDist = visualAttnOutData.params.centerWt * centerDist + visualAttnOutData.params.radiusWt * radDist;
                        
                        if totalDist < visualAttnOutData.params.distScallopThreshold
                            visualAttnOutData.statData.category(imageI).fixations{fixI}(objI) = -1;
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
    numFixations = length(visualAttnOutData.segmentData.reducedCircList(imageI).fixation);
    
    for fixI=1:numFixations
        numObj = size(visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI},1);
        for objI = 1:numObj
            if(visualAttnOutData.statData.category(imageI).fixations{fixI}(objI) ~= -1)
                currScallopMatch = visualAttnOutData.distributionData.dataPointCheck{imageI}{fixI}{objI}.scallopMatchPoints;
                currBGMatch = visualAttnOutData.distributionData.dataPointCheck{imageI}{fixI}{objI}.bgMatchPoints;
                if currBGMatch > currScallopMatch
                    if visualAttnOutData.statData.category(imageI).fixations{fixI}(objI) == 1
                        scallopBGDistrMatchNum = scallopBGDistrMatchNum + 1;
                    end
                    visualAttnOutData.statData.category(imageI).fixations{fixI}(objI) = 2;
                end
            end
        end
    end
end

visualAttnOutData.statData.scallopBGDistrMatchNum = scallopBGDistrMatchNum;

end

