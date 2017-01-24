function [ visualAttnOutData ] = finalResultsCompute( visualAttnInData )
%FINALRESULTSCOMPUTE Compute results from different stages

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

visualAttnOutData = visualAttnInData;
% visualAttnOutData.params.fixationWindowSize = [400 400];
%% Fixation Results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fixationResults = computeFixationResults( visualAttnOutData );
fixationResults = computeWindowLength( fixationResults, ...
    min( visualAttnOutData.params.fixationWindowSize(:))/2, sum( [visualAttnOutData.statData.groundTruth.numScallops] ) ); 

%     hist(fixationResults.windowVect);
%     windowStat = histc(fixationResults.windowVect, 1:visualAttnOutData.params.fixationWindowSize(:))/2);
%     cumVal = (cumsum(windowStat)./sum( [visualAttnOutData.statData.groundTruth.numScallops]).*100;
%     plot(1:fixationWindowLength,cumVal);

%% Segmentation Results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

segmentResults = computeSegmentationResults( visualAttnOutData.statData.detection );

%% Computing results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

totalImages = visualAttnOutData.params.numImages
numGroundTruthScallops = sum( [visualAttnOutData.statData.groundTruth.numScallops] )
numSegmentObjects = visualAttnOutData.segmentData.totalObjects
numBGObjects = visualAttnOutData.classData.results.totalBG

numScallopsAfterVisual = fixationResults.foundScallopCounter
percentScallopsAfterVisual = fixationResults.foundScallopCounter/numGroundTruthScallops

numScallopsAfterSegment = visualAttnOutData.classData.results.totalScallops
percentScallopsAfterSegment = visualAttnOutData.classData.results.totalScallops/numGroundTruthScallops

numScallopsAfterClassifier = visualAttnOutData.classData.results.positiveScallops
percentScallopsAfterClassifier = visualAttnOutData.classData.results.positiveScallops/numGroundTruthScallops

numNonScallopsAfterClassifier = visualAttnOutData.classData.results.positiveNonScallops
percentNonScallopsAfterClassifier = visualAttnOutData.classData.results.positiveNonScallops/numSegmentObjects

scallopsBGMatchLost = visualAttnOutData.statData.scallopBGDistrMatchNum
percentScallopsBGMatchLost = visualAttnOutData.statData.scallopBGDistrMatchNum/numGroundTruthScallops

%% Saving results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
visualAttnOutData.finalResults.fixStats = fixationResults;
visualAttnOutData.finalResults.segStats = segmentResults;

visualAttnOutData.finalResults.totalImages = totalImages;
visualAttnOutData.finalResults.numGroundTruthScallops = numGroundTruthScallops;
visualAttnOutData.finalResults.numSegmentObjects = numSegmentObjects;
visualAttnOutData.finalResults.numBGObjects = numBGObjects;

visualAttnOutData.finalResults.numScallopsAfterVisual = numScallopsAfterVisual;
visualAttnOutData.finalResults.percentScallopsAfterVisual = percentScallopsAfterVisual;

visualAttnOutData.finalResults.numScallopsAfterSegment = numScallopsAfterSegment;
visualAttnOutData.finalResults.percentScallopsAfterSegment = percentScallopsAfterSegment;

visualAttnOutData.finalResults.numScallopsAfterClassifier = numScallopsAfterClassifier;
visualAttnOutData.finalResults.percentScallopsAfterClassifier = percentScallopsAfterClassifier;

visualAttnOutData.finalResults.numNonScallopsAfterClassifier = numNonScallopsAfterClassifier;
visualAttnOutData.finalResults.percentNonScallopsAfterClassifier = percentNonScallopsAfterClassifier;

visualAttnOutData.finalResults.scallopsBGMatchLost = scallopsBGMatchLost;
visualAttnOutData.finalResults.percentScallopsBGMatchLost = percentScallopsBGMatchLost;

end


%% Fixation Results Compute Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fixationResults = computeFixationResults( visualAttnOutData )

numImages = visualAttnOutData.params.numImages;

foundScallopCounter = 0;
distFixScallop = cell(numImages,1);

for imageI=1:numImages
    numScallops = visualAttnOutData.statData.groundTruth(imageI).numScallops;
    numFixations = visualAttnOutData.fixationData.fixationsVar(imageI);
    distFixScallop{imageI} = -ones(numScallops,1);
    
    for scallopI=1:numScallops
        foundScallop = false;
        currDist = Inf;
        scallopX = visualAttnOutData.statData.groundTruth(imageI).loc(scallopI,1);
        scallopY = visualAttnOutData.statData.groundTruth(imageI).loc(scallopI,2);
        scallopRad = visualAttnOutData.statData.groundTruth(imageI).loc(scallopI,3);
        
        for fixI=1:numFixations
            fixX = visualAttnOutData.fixationData.fixations{imageI}(fixI,2);
            fixY = visualAttnOutData.fixationData.fixations{imageI}(fixI,1);
            if( euclideanDistance(fixX, fixY, scallopX, scallopY) + scallopRad <= min( visualAttnOutData.params.fixationWindowSize(:))/2 )
            %if( euclideanDistance(fixX, fixY, scallopX, scallopY) <= 50 )
                if euclideanDistance(fixX, fixY, scallopX, scallopY) + scallopRad < currDist
                    currDist = euclideanDistance(fixX, fixY, scallopX, scallopY) + scallopRad;
                end
                if ~foundScallop
                    foundScallopCounter = foundScallopCounter+1;
                    foundScallop = true;
                end
                % break;
            end
        end
        distFixScallop{imageI}(scallopI) = currDist;
    end
end

fixationResults.foundScallopCounter = foundScallopCounter;
fixationResults.distFixScallop = distFixScallop;

end

%% Computing windowlength statistics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fixationResults = computeWindowLength( fixationResults, fixationWindowLength, numGroundScallops )
    numImages = length( fixationResults.distFixScallop );
    windowVect = [];
    for imageI = 1:numImages
        numScallops = length( fixationResults.distFixScallop{imageI} );
        for scallopI =1:numScallops
            if fixationResults.distFixScallop{imageI}(scallopI) ~= -1 && ~isinf(fixationResults.distFixScallop{imageI}(scallopI))
                windowVect = [windowVect fixationResults.distFixScallop{imageI}(scallopI)];
            end
        end             
    end
%         hist(windowVect);
%         windowStat = histc(windowVect, 1:fixationWindowLength);
%         cumVal = (cumsum(windowStat)./numGroundScallops).*100;
%         plot(1:fixationWindowLength,cumVal);
end

%% Segmentation Results Compute Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function segmentResults = computeSegmentationResults( detectionScallop )
    
% Initialization
radiusErrorVect = [];
centerErrorVect = [];
totalErrorVect = [];
numImages = length( detectionScallop );

for imageI = 1:numImages
    numScallops = detectionScallop(imageI).numScallops;
    for scallopI = 1:numScallops
        currScallop = detectionScallop(imageI).scallop{scallopI};
        if currScallop.foundScallop
            radiusErrorVect = [radiusErrorVect currScallop.errorScallop(2)];
            centerErrorVect = [centerErrorVect currScallop.errorScallop(1)];
            totalErrorVect = [totalErrorVect currScallop.errorScallop(3)];
        end
    end
end

segmentResults.radiusErrorVect = radiusErrorVect;
segmentResults.centerErrorVect = centerErrorVect;
segmentResults.totalErrorVect = totalErrorVect;
            
end









    
    
    
    