function displayScallopClassifierThresholdLayer4(scallopTesting)
%SCALLOPTESTINGCLASSIFIER Classifier to set threshold for HOG-EMD distances
%it also collates all results from other layers

%% Initialization
params = scallopTesting.params;
templateMatchNumbers = scallopTesting.templateData.templateMatchNumbers;
templateAvailable = scallopTesting.templateData.templateAvailable;
dataPointMatch = scallopTesting.segmentData.dataPointMatch;
segmentCategoryStats = vertcat(scallopTesting.classData.segmentCategoryStats.objects); 

%% Getting layer 3 template match values
totalObjects = sum(cellfun(@numel,dataPointMatch));
templateMatchValuesLayer3 = zeros(totalObjects,1);
ind = 1;

for imageI=1:params.numImages
    numObjects = numel(dataPointMatch{imageI});
    for objI = 1:numObjects        
        templateMatchValuesLayer3(ind) = dataPointMatch{imageI}{objI}.matchTemplateVal;
        ind = ind+1;
    end
end

layer3Scallops = (templateMatchValuesLayer3<7 & segmentCategoryStats ~= -1);

%% Separating scallops and non-scallops Layer 4
scallopIndicesLayer4 = (segmentCategoryStats == 1 & templateAvailable & layer3Scallops);
nonScallopIndicesLayer4 = (segmentCategoryStats == 0 & templateAvailable & layer3Scallops);

scallopMatchValuesLayer4 = cell2mat(templateMatchNumbers(scallopIndicesLayer4));
nonScallopMatchValuesLayer4 = cell2mat(templateMatchNumbers(nonScallopIndicesLayer4));
                                                                            
%% Classification
matchMetric = 'corrWtVal';

scallopDistrMatchCounts = [scallopMatchValuesLayer4.(matchMetric)];
nonScallopDistrMatchCounts = [nonScallopMatchValuesLayer4.(matchMetric)];

%% Set threshold
thresh = 0.0002222;
scallopThreshCounts = sum( scallopDistrMatchCounts >= thresh );
nonScallopThreshCounts = sum( nonScallopDistrMatchCounts >= thresh );

%% Classification match values plots
subplot(121); title('Scallop match');
hist(scallopDistrMatchCounts);

subplot(122); title('Non-Scallop match');
hist(nonScallopDistrMatchCounts);

%% Precision-Recall curve parameters
numIntervals = 100;
% intervalVect = linspace( min( min(scallopDistrMatchCounts), min(nonScallopDistrMatchCounts) ), ...
%                         max( max(scallopDistrMatchCounts), max(nonScallopDistrMatchCounts) ), numIntervals );
intervalVect = linspace(-0.002,0.002,numIntervals);
numScallops = length( scallopDistrMatchCounts );

scallopCounts = zeros(1, numIntervals);
nonScallopCounts = zeros(1,numIntervals);

%% Computing Interval Values

for intervalI = 1:numIntervals
    scallopCounts(intervalI) = sum( scallopDistrMatchCounts >= intervalVect(intervalI) );
    nonScallopCounts(intervalI) = sum( nonScallopDistrMatchCounts >= intervalVect(intervalI) );
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
% set(gca, 'Xdir', 'reverse')

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
% set(gca, 'Xdir', 'reverse')
end


