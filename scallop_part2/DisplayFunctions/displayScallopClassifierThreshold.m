function displayScallopClassifierThreshold(scallopTesting)
%SCALLOPTESTINGCLASSIFIER Classifier to set threshold for HOG-EMD distances
%it also collates all results from other layers

%% Initialization
params = scallopTesting.params;
hogComparison = scallopTesting.hogComparison;
classData = scallopTesting.classData; 
segmentData = scallopTesting.segmentData;

numImages = params.numImages;

numScallopHogAvailable = 0;
numScallopHogNotAvailable = 0;
numNonScallopHogAvailable = 0;
numNonScallopHogNotAvailable = 0;
numSkippedScallopHogAvailable = 0;
numSkippedScallopHogNotAvailable = 0;

scallopDistrMatchCounts = [];
nonScallopDistrMatchCounts = [];
skippedScallopDistrMatchCounts = [];

%% Classification Match Values

for imageI=1:numImages
    numObjects = size(segmentData.circList{imageI}, 1);
    
    for objI=1:numObjects        
        hogAvailable = hogComparison.hogLearningAvailable{imageI}(objI) & hogComparison.hogTestingAvailable{imageI}(objI);
        currMatchVal = hogComparison.hogEmdDistances{imageI}{objI};
        
        switch classData.segmentCategoryStats(imageI).objects(objI)
            
            % Scallops that have a segmented object near them
            case 1
                if hogAvailable
                    numScallopHogAvailable = numScallopHogAvailable + 1;
                    scallopDistrMatchCounts = [scallopDistrMatchCounts currMatchVal];
                else
                    numScallopHogNotAvailable = numScallopHogNotAvailable + 1;
                end
            
            % Segmented objects that have no scallops near them    
            case 0
                if hogAvailable
                    numNonScallopHogAvailable = numNonScallopHogAvailable + 1;
                    nonScallopDistrMatchCounts = [nonScallopDistrMatchCounts currMatchVal];
                else
                    numNonScallopHogNotAvailable = numNonScallopHogNotAvailable + 1;
                end
                
            % Scallops that are not counted because there are better
            % matches
            case -1
                if hogAvailable
                    numSkippedScallopHogAvailable = numSkippedScallopHogAvailable + 1;                   
                    skippedScallopDistrMatchCounts = [skippedScallopDistrMatchCounts currMatchVal];
                else
                    numSkippedScallopHogNotAvailable = numSkippedScallopHogNotAvailable + 1;
                end
        end
    end
end

%% Verify scallop counts
% imageObjects = cellfun(@size, scallopTesting.segmentData.circList, num2cell(ones(scallopTesting.params.numImages,1)));
% totalObjects = sum(imageObjects);
% numScallopHogAvailable
% numScallopHogNotAvailable
% numNonScallopHogAvailable
% numNonScallopHogNotAvailable
% numSkippedScallopHogAvailable
% numSkippedScallopHogNotAvailable
% totalObjectsCounts = numScallopHogAvailable + numScallopHogNotAvailable + ...
%                         numNonScallopHogAvailable + numNonScallopHogNotAvailable + ...
%                         numSkippedScallopHogAvailable + numSkippedScallopHogNotAvailable

%% Set threshold
thresh = 3;
scallopThreshCounts = sum( scallopDistrMatchCounts <= thresh );
nonScallopThreshCounts = sum( nonScallopDistrMatchCounts <= thresh );

%% Classification match values plots
subplot(131); title('Scallop match');
hist(scallopDistrMatchCounts);

subplot(132); title('Non-Scallop match');
hist(nonScallopDistrMatchCounts);

subplot(133); title('Skipped-Scallop match');
hist(skippedScallopDistrMatchCounts);

%% Precision-Recall curve parameters
numIntervals = 100;
intervalVect = linspace( 0, max( max(scallopDistrMatchCounts), max(nonScallopDistrMatchCounts) ), numIntervals );
numScallops = length( scallopDistrMatchCounts );

scallopCounts = zeros(1, numIntervals);
nonScallopCounts = zeros(1,numIntervals);

%% Computing Interval Values

for intervalI = 1:numIntervals
    scallopCounts(intervalI) = sum( scallopDistrMatchCounts <= intervalVect(intervalI) );
    nonScallopCounts(intervalI) = sum( nonScallopDistrMatchCounts <= intervalVect(intervalI) );
end

detectionCounts = scallopCounts./numScallops;
precisionCounts = scallopCounts./(scallopCounts+nonScallopCounts);

%% Plots

figure('Name', sprintf('Scallop counts = %d, Non-scallop counts = %d', scallopThreshCounts, nonScallopThreshCounts));
subplot(211)
plot(intervalVect, scallopCounts,'red');
hold on
plot(intervalVect, nonScallopCounts,'green');
hold off
xlabel('Template match value');
title('scallop/non-scallop counts');
legend('scallop', 'non-scallop');

subplot(212)
plot(intervalVect, detectionCounts,'red');
hold on
plot(intervalVect, precisionCounts,'green');
hold off
xlabel('Template match value');
title('recall/precision rates');
legend('recall rate', 'precision rate');

hold on
plot(thresh*ones(10,1), linspace(0,1,10))
hold off

end


