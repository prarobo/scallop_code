function [ detectionStats, categoryStats, params ] = detectionStats_testing_boundary( params, groundTruth, distributionData )
%DETECTIONSTATS Compute detection stats

%% Initialization

numImages = params.numImages;
detectionStats(numImages) = struct;

params.centerWt = 1;
params.radiusWt = 10;
params.distScallopThreshold = 20;
params.distCenterThreshold = 12;
params.percentRadiusThreshold = 0.30;

%% Computing closest circle to actual scallop

for imageI=1:numImages
    numScallops = groundTruth(imageI).numScallops;
    detectionStats(imageI).numScallops = numScallops;
    detectionStats(imageI).scallop = cell( numScallops, 1 );
    currObjList = distributionData.objList{imageI};
    
    for scallopI = 1:numScallops
        numCirc = size(currObjList,1);
        currScallopLoc = groundTruth(imageI).loc(scallopI,:);
        detectionStats(imageI).scallop{scallopI}.origCirc = currScallopLoc;
        circList = zeros(numCirc,8);
        
        circList(:,1:3) = currObjList(:,1:3);
        circList(:,4) = euclideanDistance( currScallopLoc(1), currScallopLoc(2), circList(:, 1), circList(:, 2) );
        circList(:,5) = (currScallopLoc(3) - circList(:, 3))/currScallopLoc(3);
        circList(:,6) = params.centerWt .* abs( circList(:, 4) )+ params.radiusWt .* abs( circList(:, 5) );
        circList(:,7) = currObjList(:,4);
        circList(:,8) = currObjList(:,5);

        detectionStats(imageI).scallop{scallopI}.circList = sortrows( circList, 6 );
    end    
end

%% Assigning scallop/non-scallop object circles

categoryStats(numImages) = struct;

for imageI=1:numImages
    numScallops = groundTruth(imageI).numScallops;
    numObj = size(distributionData.objList{imageI},1);
    categoryStats(imageI).objects = zeros(numObj,1);
    categoryStats(imageI).scallopID = zeros(numObj,1);
    
    for scallopI=1:numScallops
        tempCircList = detectionStats(imageI).scallop{scallopI}.circList;
        detectionStats(imageI).scallop{scallopI}.foundScallop = false;
        detectionStats(imageI).scallop{scallopI}.errorScallop = zeros(1,3);
        detectionStats(imageI).scallop{scallopI}.skipScallop = false;
        
        if ~isempty(tempCircList) && ~groundTruth(imageI).boundaryScallop(scallopI)
            % if tempCircList( 1, 6 )< params.distScallopThreshold
            detectionStats(imageI).scallop{scallopI}.errorScallop(1) = tempCircList(1,4);
            detectionStats(imageI).scallop{scallopI}.errorScallop(2) = tempCircList(1,5);
            detectionStats(imageI).scallop{scallopI}.errorScallop(3) = tempCircList(1,6);

            if ( abs( tempCircList( 1, 4 ) )< params.distCenterThreshold && ...
                   abs( tempCircList( 1, 5 ) )< params.percentRadiusThreshold  )
                
                categoryStats(imageI).objects(tempCircList(1, 8)) = 1;
                categoryStats(imageI).scallopID(tempCircList(1, 8)) = scallopI;
                detectionStats(imageI).scallop{scallopI}.foundScallop = true;
                % detectionStats(imageI).scallop{scallopI}.errorScallop(1) = tempCircList(1,4);
                % detectionStats(imageI).scallop{scallopI}.errorScallop(2) = tempCircList(1,5);
                % detectionStats(imageI).scallop{scallopI}.errorScallop(3) = tempCircList(1,6);                
            end
            for circI=2:size(tempCircList,1)
                %if tempCircList( 1, 6 )< params.distScallopThreshold
                if ( abs( tempCircList( circI, 4 ) )< params.distCenterThreshold && ...
                       abs( tempCircList( circI, 5 ) )< params.percentRadiusThreshold )
                    
                    if categoryStats(imageI).objects(tempCircList(circI, 8)) ~= 1
                        categoryStats(imageI).objects(tempCircList(circI, 8)) = -1;
                    end
                else
                    break;
                end
            end
        else
            detectionStats(imageI).scallop{scallopI}.skipScallop = true;
        end
    end
end

%% Circle Nearness Filter to reduce non scallop circles

% for imageI=1:numImages
%     numFixations = length(visualAttnOutData.segmentData.reducedCircList(imageI).fixation);
%     
%     for fixI=1:numFixations
%         numObj = size(visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI},1);
%         for objI = 1:numObj
%             if(visualAttnOutData.statData.category(imageI).fixations{fixI}(objI) == 0)
%                 currX = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,1) + windowRect{imageI}(fixI,1) - 1;
%                 currY = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,2) + windowRect{imageI}(fixI,2) - 1;
%                 currRad = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,3);
%                 breakCondition = false;
%                 
%                 for nFixI=1:numFixations
%                     if nFixI < fixI
%                         continue;
%                     end
%                     
%                     nNumObj = size(visualAttnOutData.segmentData.reducedCircList(imageI).fixation{nFixI},1);
%                     
%                     for nObjI = 1:nNumObj
%                         if nFixI == fixI && nObjI <= objI
%                             continue;
%                         end
%                         
%                         nCurrX = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{nFixI}(nObjI,1) + windowRect{imageI}(nFixI,1) - 1;
%                         nCurrY = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{nFixI}(nObjI,2) + windowRect{imageI}(nFixI,2) - 1;
%                         nCurrRad = visualAttnOutData.segmentData.reducedCircList(imageI).fixation{nFixI}(nObjI,3);
%                         
%                         centerDist = euclideanDistance(currX, currY, nCurrX, nCurrY);
%                         radDist = abs(currRad - nCurrRad);
%                         totalDist = visualAttnOutData.params.centerWt * centerDist + visualAttnOutData.params.radiusWt * radDist;
%                         
%                         if totalDist < visualAttnOutData.params.distScallopThreshold
%                             visualAttnOutData.statData.category(imageI).fixations{fixI}(objI) = -1;
%                             breakCondition = true;
%                             break;
%                         end
%                     end
%                     if breakCondition
%                         break;
%                     end
%                 end               
%             end
%         end
%     end
% end

%% Computing background object circles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% scallopBGDistrMatchNum = 0;
% for imageI=1:numImages
%     numFixations = length(visualAttnOutData.segmentData.reducedCircList(imageI).fixation);
%     
%     for fixI=1:numFixations
%         numObj = size(visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI},1);
%         for objI = 1:numObj
%             if(visualAttnOutData.statData.category(imageI).fixations{fixI}(objI) ~= -1)
%                 currScallopMatch = visualAttnOutData.distributionData.dataPointCheck{imageI}{fixI}{objI}.scallopMatchPoints;
%                 currBGMatch = visualAttnOutData.distributionData.dataPointCheck{imageI}{fixI}{objI}.bgMatchPoints;
%                 if currBGMatch > currScallopMatch
%                     if visualAttnOutData.statData.category(imageI).fixations{fixI}(objI) == 1
%                         scallopBGDistrMatchNum = scallopBGDistrMatchNum + 1;
%                     end
%                     visualAttnOutData.statData.category(imageI).fixations{fixI}(objI) = 2;
%                 end
%             end
%         end
%     end
% end
% 
% visualAttnOutData.statData.scallopBGDistrMatchNum = scallopBGDistrMatchNum;

end

