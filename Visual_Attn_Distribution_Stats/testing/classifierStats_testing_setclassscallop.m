function [ classData, detectionStats, params ] ...
    = classifierStats_testing_setclassscallop( params, statData, distributionData, segmentData, fixationData )
%CLASSIFIERSTATS Computes classifier thresholds

%% Initialization

% startDistrNum = 300;
% endDistrNum = 600;
% polyFitIntervalLen = 50;
% polyFitIntervalMat = startDistrNum:polyFitIntervalLen:endDistrNum;

numImages = params.numImages;

scallopDistrMatchCounts = [];
nonScallopDistrMatchCounts = [];
skippedScallopDistrMatchCounts = [];

numScallopDataAvailable = 0;
numScallopDataUnavailable = 0;
numNonScallopDataAvailable = 0;
numNonScallopDataUnavailable = 0;
numSkippedScallopDataAvailable = 0;
numSkippedScallopDataUnavailable = 0;

% params.matchMetric = 'matchVal';
% params.matchMetric = 'matchInvStddevWeightVal';
% params.matchMetric = 'matchTopStddevWeightVal';
params.matchMetric = 'matchTemplateVal';
% params.matchMetric = 'matchRadiusWtTemplateVal';

detectionStats = statData.detectionStats;

%% Classification Lists

for imageI=1:numImages
    numObj = size( distributionData.objList{imageI}, 1 );
    for objI=1:numObj
        
        switch statData.categoryStats(imageI).objects(objI)
            case 1
                if distributionData.dataAvailable{imageI}(objI)
                    numScallopDataAvailable = numScallopDataAvailable + 1;
                    scallopDistrMatchCounts = ...
                        [scallopDistrMatchCounts distributionData.dataPointMatch{imageI}{objI}.(params.matchMetric) ];
                else
                    numScallopDataUnavailable = numScallopDataUnavailable + 1;
                end
            case 0
                if distributionData.dataAvailable{imageI}(objI)
                    numNonScallopDataAvailable = numNonScallopDataAvailable + 1;
                    nonScallopDistrMatchCounts = ...
                        [nonScallopDistrMatchCounts distributionData.dataPointMatch{imageI}{objI}.(params.matchMetric)];
                else
                    numNonScallopDataUnavailable = numNonScallopDataUnavailable + 1;
                end
            case -1
                if distributionData.dataAvailable{imageI}(objI)
                    numSkippedScallopDataAvailable = numSkippedScallopDataAvailable + 1;
                    
                    skippedScallopDistrMatchCounts = ...
                        [skippedScallopDistrMatchCounts distributionData.dataPointMatch{imageI}{objI}.(params.matchMetric)];
                else
                    numSkippedScallopDataUnavailable = numSkippedScallopDataUnavailable + 1;
                end
        end
    end
end

numTotalObjectDataAvailable = numScallopDataAvailable + numNonScallopDataAvailable + numSkippedScallopDataAvailable;
numTotalObjectDataUnavailable = numScallopDataUnavailable + numNonScallopDataUnavailable + numSkippedScallopDataUnavailable;
numTotalObject = numTotalObjectDataAvailable + numTotalObjectDataUnavailable;

% scallopVerdictThreshold = max( scallopDistrMatchCounts(:) );
scallopVerdictThreshold = 5.5; %5.7; %4.1;
numGroundTruthScallops = sum( [visualAttnOutData.statData.groundTruth.numScallops]);

%% Set scallops classified

for imageI=1:numImages
    numScallops = length(detectionStats(imageI).scallop);
    for scallopI=1:numScallops
        detectionStats(imageI).scallop{scallopI}.classifiedScallop = false;
    end
end

for imageI=1:numImages
    numObj = size( distributionData.objList{imageI}, 1 );
    for objI=1:numObj
        if statData.categoryStats(imageI).objects(objI) == 1
            if distributionData.dataPointMatch{imageI}{objI}.(params.matchMetric) <= scallopVerdictThreshold
                scallopID = statData.categoryStats(imageI).scallopID(objI);
                detectionStats(imageI).scallop{scallopID}.classifiedScallop = true;
            end
        end
    end
end

%% Classification Results

classificationResults.scallopVerdictThreshold = scallopVerdictThreshold;

classificationResults.scallopsDetected = sum( scallopDistrMatchCounts <= scallopVerdictThreshold );
classificationResults.nonScallopsDetected = sum( nonScallopDistrMatchCounts <= scallopVerdictThreshold );
classificationResults.scallopsMissed = sum( scallopDistrMatchCounts > scallopVerdictThreshold );
classificationResults.nonScallopsMissed = sum( nonScallopDistrMatchCounts > scallopVerdictThreshold );
classificationResults.skippedScallopsDetected = sum( skippedScallopDistrMatchCounts <= scallopVerdictThreshold );
classificationResults.skippedScallopsMissed = sum( skippedScallopDistrMatchCounts > scallopVerdictThreshold );

%% Fixation Results

fixationResults = computeFixationResults( params, fixationData, statData.groundTruth );
fixationResults = computeWindowLength( fixationResults, ...
    min( params.fixationWindowSize(:))/2, numGroundTruthScallops ); 

% hist(fixationResults.windowVect);
% windowStat = histc(fixationResults.windowVect, 1:visualAttnOutData.params.fixationWindowSize(:)/2);
% cumVal = (cumsum(windowStat)./sum( [visualAttnOutData.statData.groundTruth.numScallops])).*100;
% plot(1:fixationWindowLength,cumVal);

%% Segmentation Results

segmentResults = computeSegmentationResults( statData.detectionStats );

%% Computing results

totalImages = numImages
numGroundTruthScallops = sum( [visualAttnOutData.statData.groundTruth.numScallops] )
numSegmentObjects = visualAttnOutData.segmentData.totalObjects
numBGObjects = classificationResults.totalBG

numScallopsAfterVisual = fixationResults.foundScallopCounter
percentScallopsAfterVisual = fixationResults.foundScallopCounter/numGroundTruthScallops

numScallopsAfterSegment = classificationResults.totalScallops
percentScallopsAfterSegment = classificationResults.totalScallops/numGroundTruthScallops

numScallopsAfterClassifier = classificationResults.positiveScallops
percentScallopsAfterClassifier = classificationResults.positiveScallops/numGroundTruthScallops

numNonScallopsAfterClassifier = classificationResults.positiveNonScallops
percentNonScallopsAfterClassifier = classificationResults.positiveNonScallops/numSegmentObjects

scallopsBGMatchLost = visualAttnOutData.statData.scallopBGDistrMatchNum
percentScallopsBGMatchLost = visualAttnOutData.statData.scallopBGDistrMatchNum/numGroundTruthScallops

%% Final results

% finalResults = [];
finalResults.totalImages = numImages;
finalResults.numGroundTruthScallops = sum( [statData.groundTruth.numScallops]);
finalResults.numSegmentObjects = numTotalObject;
finalResults.numBGObjects = numTotalObject - segmentResults.totalSegmented;

finalResults.numScallopsAfterVisual = fixationResults.foundScallopCounter;
finalResults.percentScallopsAfterVisual = fixationResults.foundScallopCounter/numGroundTruthScallops;

finalResults.numScallopsAfterSegment = segmentResults.totalSegmented;
finalResults.percentScallopsAfterSegment = segmentResults.totalSegmented/numGroundTruthScallops;

finalResults.numScallopsAfterClassifier = classificationResults.scallopsDetected;
finalResults.percentScallopsAfterClassifier = classificationResults.scallopsDetected/numGroundTruthScallops;

finalResults.numNonScallopsAfterClassifier = classificationResults.nonScallopsDetected;
finalResults.percentNonScallopsAfterClassifier = classificationResults.nonScallopsDetected/numGroundTruthScallops;

%% Plots

yLimit = 20;
subplot(131)
hist( scallopDistrMatchCounts(:),100 );
ylim([0 yLimit])
title('Scallop Matches');
xlabel('Number of matches');
ylabel('Number of objects');

subplot(132)
hist( nonScallopDistrMatchCounts(:),100 );
ylim([0 yLimit])
title('Non-Scallop Matches');
xlabel('Number of matches');
ylabel('Number of objects');

subplot(133)
hist( skippedScallopDistrMatchCounts(:),100 );
ylim([0 yLimit])
title('Skipped Scallop Matches');
xlabel('Number of matches');
ylabel('Number of objects');

%% Outputs

classData.numberStats.scallopDistrMatchCounts = scallopDistrMatchCounts;
classData.numberStats.nonScallopDistrMatchCounts = nonScallopDistrMatchCounts;
classData.numberStats.skippedScallopDistrMatchCounts = skippedScallopDistrMatchCounts;

classData.numberStats.numScallopDataAvailable = numScallopDataAvailable;
classData.numberStats.numScallopDataUnavailable = numScallopDataUnavailable;
classData.numberStats.numNonScallopDataAvailable = numNonScallopDataAvailable;
classData.numberStats.numNonScallopDataUnavailable = numNonScallopDataUnavailable;
classData.numberStats.numSkippedScallopDataAvailable = numSkippedScallopDataAvailable;
classData.numberStats.numSkippedScallopDataUnavailable = numSkippedScallopDataUnavailable;

classData.numberStats.numTotalObjectDataAvailable = numTotalObjectDataAvailable;
classData.numberStats.numTotalObjectDataUnavailable = numTotalObjectDataUnavailable;
classData.numberStats.numTotalObject = numTotalObject;

classData.fixationResults = fixationResults;
classData.segmentResults = segmentResults;
classData.classificationResults = classificationResults;
classData.finalResults = finalResults;

end



%% Fixation Results Compute Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fixationResults = computeFixationResults( params, fixationData, groundTruth )

%% Initialization
numImages = params.numImages;
foundScallopCounter = 0;
distFixScallop = cell(numImages,1);

for imageI=1:numImages
    numScallops = groundTruth(imageI).numScallops;
    numFixations = fixationData.fixationsVar(imageI);
    distFixScallop{imageI} = -ones(numScallops,1);
    
    for scallopI=1:numScallops
        foundScallop = false;
        currDist = Inf;
        scallopX = groundTruth(imageI).loc(scallopI,1);
        scallopY = groundTruth(imageI).loc(scallopI,2);
        scallopRad = groundTruth(imageI).loc(scallopI,3);
        
        for fixI=1:numFixations
            fixX = fixationData.fixations{imageI}(fixI,2);
            fixY = fixationData.fixations{imageI}(fixI,1);
            tempDist = euclideanDistance(fixX, fixY, scallopX, scallopY) + scallopRad;
            if( tempDist <= min( params.fixationWindowSize(:))/2 )
                if tempDist < currDist
                    currDist = tempDist;
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

function segmentResults = computeSegmentationResults( detectionStats )
    
% Initialization
radiusErrorVect = [];
centerErrorVect = [];
totalErrorVect = [];
radiusMissedErrorVect = [];
centerMissedErrorVect = [];
totalMissedErrorVect = [];
totalSegmented = 0;
totalMissed = 0;
totalSkipped = 0;
numImages = length( detectionStats );

for imageI = 1:numImages
    numScallops = detectionStats(imageI).numScallops;
    for scallopI = 1:numScallops
        currScallop = detectionStats(imageI).scallop{scallopI};
        if currScallop.foundScallop
            radiusErrorVect = [radiusErrorVect currScallop.errorScallop(2)];
            centerErrorVect = [centerErrorVect currScallop.errorScallop(1)];
            totalErrorVect = [totalErrorVect currScallop.errorScallop(3)];
            totalSegmented = totalSegmented + 1;
        else
            if ~currScallop.skipScallop
                radiusMissedErrorVect = [radiusMissedErrorVect currScallop.errorScallop(2)];
                centerMissedErrorVect = [centerMissedErrorVect currScallop.errorScallop(1)];
                totalMissedErrorVect = [totalMissedErrorVect currScallop.errorScallop(3)];
                totalMissed = totalMissed + 1;
            else
                totalSkipped = totalSkipped + 1;
            end
        end
    end
end

segmentResults.radiusErrorVect = radiusErrorVect;
segmentResults.centerErrorVect = centerErrorVect;
segmentResults.totalErrorVect = totalErrorVect;
segmentResults.totalSegmented = totalSegmented;

segmentResults.radiusMissedErrorVect = radiusMissedErrorVect;
segmentResults.centerMissedErrorVect = centerMissedErrorVect;
segmentResults.totalMissedErrorVect = totalMissedErrorVect;
segmentResults.totalMissed = totalMissed;

segmentResults.totalSkipped = totalSkipped;
            
end









    
    
    
    


