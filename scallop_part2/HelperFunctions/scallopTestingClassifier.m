function [ params, classData ] = scallopTestingClassifier( scallopTesting )
%SCALLOPTESTINGCLASSIFIER Classifier to learn from negative and positive
%instances of HOG descriptors and do classification

%% Initialization
params = scallopTesting.params;
templateMatchNumbers = scallopTesting.templateData.templateMatchNumbers;
templateAvailable = scallopTesting.templateData.templateAvailable;

%% Separating scallops and non-scallops
segmentCategoryStats = vertcat(scallopTesting.classData.segmentCategoryStats.objects); 

scallopIndices = (segmentCategoryStats == 1 & templateAvailable);
nonScallopIndices = (segmentCategoryStats == 0 & templateAvailable);

scallopMatchValues = cell2mat(templateMatchNumbers(scallopIndices));
nonScallopMatchValues = cell2mat(templateMatchNumbers(nonScallopIndices));
                                                                            
%% Classification
matchMetric = 'corrWtVal';

scallopMatchMetricValues = [scallopMatchValues.(matchMetric)];
nonScallopMatchMetricValues = [nonScallopMatchValues.(matchMetric)];
threshold = 0;

numScallopsCounted = sum(scallopMatchMetricValues>threshold);
numScallopsNotCounted = sum(scallopMatchMetricValues<=threshold);
percentScallopsCounted = numScallopsCounted/(numScallopsCounted+numScallopsNotCounted);

numNonScallopsCounted = sum(nonScallopMatchMetricValues>threshold);
numNonScallopsNotCounted = sum(nonScallopMatchMetricValues<=threshold);
percentNonScallopsCounted = numNonScallopsCounted/(numNonScallopsCounted+numNonScallopsNotCounted);

%% Results
classData = scallopTesting.classData;
classData.finalNumbers.numScallopsCounted = numScallopsCounted;
classData.finalNumbers.numScallopsNotCounted = numScallopsNotCounted;
classData.finalNumbers.percentScallopsCounted = percentScallopsCounted;

classData.finalNumbers.numNonScallopsCounted = numNonScallopsCounted;
classData.finalNumbers.numNonScallopsNotCounted = numNonScallopsNotCounted;
classData.finalNumbers.percentNonScallopsCounted = percentNonScallopsCounted;
