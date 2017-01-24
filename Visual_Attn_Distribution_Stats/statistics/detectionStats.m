function [ visualAttnOutData ] = detectionStats( visualAttnInData )
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
                origCircList(ind, 5) = abs( visualAttnOutData.statData.detection(imageI).scallop{scallopI}.origCirc(3) - ...
                    origCircList(ind, 3) );
                origCircList(ind, 6) = visualAttnOutData.params.centerWt * origCircList(ind, 4) + ...
                    visualAttnOutData.params.radiusWt * origCircList(ind, 5);
                origCircList(ind, 7) = fixI;
                origCircList(ind, 8) = objI;
                ind = ind + 1;
            end
        end
        visualAttnOutData.statData.detection(imageI).scallop{scallopI}.circList = sortrows( origCircList, 6 );
    end
    
end

%% Computing non-scallop object circles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for imageI=1:numImages
    numFixations = length(visualAttnOutData.segmentData.reducedCircList(imageI).fixation);
    visualAttnOutData.statData.category(imageI).fixations = cell(numFixations,1);
    
    for fixI=1:numFixations
        numObj = size(visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixI},1);
        visualAttnOutData.statData.category(imageI).fixations{fixI} = zeros(numObj,1);
    end
    for fixI=1:numFixations
        for scallopI=1:visualAttnOutData.statData.detection(imageI).numScallops
            tempCircList = visualAttnOutData.statData.detection(imageI).scallop{scallopI}.circList;
            if tempCircList( 1, 6 ) < visualAttnOutData.params.distScallopThreshold                
                visualAttnOutData.statData.category(imageI).fixations{tempCircList(1, 7)}(tempCircList(1, 8)) = 1;
            end
            for circI=2:size(tempCircList,1)
                if tempCircList( circI, 6 )< visualAttnOutData.params.distScallopThreshold
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

