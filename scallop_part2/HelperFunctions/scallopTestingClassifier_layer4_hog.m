function [ params, classData ] = scallopTestingClassifier_layer4_hog( scallopTesting )
%SCALLOPTESTINGCLASSIFIER Classifier to learn from negative and positive
%instances of HOG descriptors and do classification

%% Initialization
params = scallopTesting.params;
% templateMatchNumbers = scallopTesting.templateData.templateMatchNumbers;
% templateAvailable = scallopTesting.templateData.templateAvailable;
dataPointMatch = scallopTesting.segmentData.dataPointMatch;
segmentCategoryStats = vertcat(scallopTesting.classData.segmentCategoryStats.objects); 
hogEmdDistances = scallopTesting.hogComparison.hogEmdDistances;
hogAvailable = cell2mat(scallopTesting.hogComparison.hogLearningAvailable) & cell2mat(scallopTesting.hogComparison.hogTestingAvailable);

%% Getting hog emd values
totalObjects = sum(cellfun(@numel,hogEmdDistances));
hogEmd = zeros(totalObjects,1);
ind = 1;

for imageI=1:params.numImages
    numObjects = numel(hogEmdDistances{imageI});
    for objI = 1:numObjects
        if isempty(hogEmdDistances{imageI}{objI})
            hogEmd(ind) = 0;
        else
            hogEmd(ind) = hogEmdDistances{imageI}{objI};
        end
        ind = ind+1;
    end
end

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

%% Separating scallops and non-scallops Layer 3
scallopIndicesLayer3 = (segmentCategoryStats == 1 & layer3Scallops);
nonScallopIndicesLayer3 = (segmentCategoryStats == 0 & layer3Scallops);

%% Separating scallops and non-scallops Layer 4
scallopIndicesLayer4 = (segmentCategoryStats == 1 & hogAvailable & layer3Scallops);
nonScallopIndicesLayer4 = (segmentCategoryStats == 0 & hogAvailable & layer3Scallops);

scallopMatchValuesLayer4 = hogEmd(scallopIndicesLayer4);
nonScallopMatchValuesLayer4 = hogEmd(nonScallopIndicesLayer4);
                                                                            
%% Classification
matchMetric = 'corrWtVal';

scallopMatchMetricValues = scallopMatchValuesLayer4;
nonScallopMatchMetricValues = nonScallopMatchValuesLayer4;
threshold = 2.816;

numScallopsCounted = sum(scallopMatchMetricValues<=threshold);
numScallopsNotCounted = sum(scallopMatchMetricValues>threshold);
percentScallopsCounted = numScallopsCounted/(numScallopsCounted+numScallopsNotCounted);

numNonScallopsCounted = sum(nonScallopMatchMetricValues<=threshold);
numNonScallopsNotCounted = sum(nonScallopMatchMetricValues>threshold);
percentNonScallopsCounted = numNonScallopsCounted/(numNonScallopsCounted+numNonScallopsNotCounted);

truePositivesAfterLayer3 = sum(scallopIndicesLayer3);
falsePositivesAfterLayer3 = sum(nonScallopIndicesLayer3);

truePositivesAfterLayer4 = numScallopsCounted;
falsePositivesAfterLayer4 = numNonScallopsCounted;

%% Results

classData = scallopTesting.classData;
classData.finalNumbers.numScallopsCounted = numScallopsCounted;
classData.finalNumbers.numScallopsNotCounted = numScallopsNotCounted;
classData.finalNumbers.percentScallopsCounted = percentScallopsCounted;

classData.finalNumbers.numNonScallopsCounted = numNonScallopsCounted;
classData.finalNumbers.numNonScallopsNotCounted = numNonScallopsNotCounted;
classData.finalNumbers.percentNonScallopsCounted = percentNonScallopsCounted;

classData.layer4.truePositivesAfterLayer3 = truePositivesAfterLayer3;
classData.layer4.falsePositivesAfterLayer3 = falsePositivesAfterLayer3;

classData.layer4.truePositivesAfterLayer4 = truePositivesAfterLayer4;
classData.layer4.falsePositivesAfterLayer4 = falsePositivesAfterLayer4;



