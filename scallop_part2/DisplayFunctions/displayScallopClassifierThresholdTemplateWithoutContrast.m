function displayScallopClassifierThresholdTemplateWithoutContrast(scallopTesting)
%SCALLOPTESTINGCLASSIFIER Classifier to set threshold for HOG-EMD distances
%it also collates all results from other layers

%% Initialization
params = scallopTesting.params;
templateData = scallopTesting.templateData;
classData = scallopTesting.classData; 

numScallopAvailable = 0;
numScallopNotAvailable = 0;
numNonScallopAvailable = 0;
numNonScallopNotAvailable = 0;
numSkippedScallopAvailable = 0;
numSkippedScallopNotAvailable = 0;

scallopCorrDistrMatchCounts = [];
nonScallopCorrDistrMatchCounts = [];
skippedScallopCorrDistrMatchCounts = [];

scallopCorrWtDistrMatchCounts = [];
nonScallopCorrWtDistrMatchCounts = [];
skippedScallopCorrWtDistrMatchCounts = [];

scallopSsdDistrMatchCounts = [];
nonScallopSsdDistrMatchCounts = [];
skippedScallopSsdDistrMatchCounts = [];

scallopSsdWtDistrMatchCounts = [];
nonScallopSsdWtDistrMatchCounts = [];
skippedScallopSsdWtDistrMatchCounts = [];

%% Classification Match Values
    
for objI=1:params.numObjects
    templateAvailable = templateData.templateAvailable(objI);
    corrMatchVal = templateData.templateMatchNumbers{objI};
    corrWtMatchVal = templateData.templateMatchNumbers{objI};
    ssdMatchVal = templateData.templateMatchNumbers{objI};
    ssdWtMatchVal = templateData.templateMatchNumbers{objI};
    
    switch classData.segmentCategoryStats(imageI).objects(objI)
        
        % Scallops that have a segmented object near them
        case 1
            if templateAvailable
                numScallopAvailable = numScallopAvailable + 1;
                scallopCorrDistrMatchCounts = [scallopCorrDistrMatchCounts corrMatchVal];
                scallopCorrWtDistrMatchCounts = [scallopCorrWtDistrMatchCounts corrWtMatchVal];
                scallopSsdDistrMatchCounts = [scallopSsdDistrMatchCounts ssdMatchVal];
                scallopSsdWtDistrMatchCounts = [scallopSsdWtDistrMatchCounts ssdWtMatchVal];
            else
                numScallopNotAvailable = numScallopNotAvailable + 1;
            end
            
            % Segmented objects that have no scallops near them
        case 0
            if templateAvailable
                numNonScallopAvailable = numNonScallopAvailable + 1;
                nonScallopCorrDistrMatchCounts = [nonScallopCorrDistrMatchCounts corrMatchVal];
                nonScallopCorrWtDistrMatchCounts = [nonScallopCorrWtDistrMatchCounts corrWtMatchVal];
                nonScallopSsdDistrMatchCounts = [nonScallopSsdDistrMatchCounts ssdMatchVal];
                nonScallopSsdWtDistrMatchCounts = [nonScallopSsdWtDistrMatchCounts ssdWtMatchVal];
            else
                numNonScallopNotAvailable = numNonScallopNotAvailable + 1;
            end
            
            % Scallops that are not counted because there are better
            % matches
        case -1
            if templateAvailable
                numSkippedScallopAvailable = numSkippedScallopAvailable + 1;
                skippedScallopCorrDistrMatchCounts = [skippedScallopCorrDistrMatchCounts corrMatchVal];
                skippedScallopCorrWtDistrMatchCounts = [skippedScallopCorrWtDistrMatchCounts corrWtMatchVal];
                skippedScallopSsdDistrMatchCounts = [skippedScallopSsdDistrMatchCounts ssdMatchVal];
                skippedScallopSsdWtDistrMatchCounts = [skippedScallopSsdWtDistrMatchCounts ssdWtMatchVal];
            else
                numSkippedScallopNotAvailable = numSkippedScallopNotAvailable + 1;
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

scallopDistrMatchCounts = scallopSsdDistrMatchCounts;
nonScallopDistrMatchCounts = nonScallopSsdDistrMatchCounts;
skippedScallopDistrMatchCounts = skippedScallopSsdDistrMatchCounts;

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


