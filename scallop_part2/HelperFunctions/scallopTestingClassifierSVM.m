function [ params, classData ] = scallopTestingClassifierSVM( scallopTesting )
%SCALLOPTESTINGCLASSIFIER Classifier to learn from negative and positive
%instances of HOG descriptors and do classification

%% Initialization
params = scallopTesting.params;
segmentCategoryStats = scallopTesting.classData.segmentCategoryStats; 
segmentData = scallopTesting.segmentData;
hogDes = scallopTesting.objectHOG.hogDes;
hogAvailable = scallopTesting.objectHOG.hogAvailable;

numImages = params.numImages;
positiveInstances = cell(numImages,1);
negativeInstances = cell(numImages,1);

%% Positive instances and negative instances
for imageI=1:numImages
    positiveIndices = find(segmentCategoryStats(imageI).objects == 1 & hogAvailable{imageI});
    negativeIndices = find(segmentCategoryStats(imageI).objects == 0 & hogAvailable{imageI});
    
    if ~isempty(positiveIndices)
        positiveInstances{imageI} = cellfun(@transpose, hogDes{imageI}(positiveIndices, :), 'UniformOutput', false);
    end
    if ~isempty(negativeIndices)
        negativeInstances{imageI} = cellfun(@transpose, hogDes{imageI}(negativeIndices, :), 'UniformOutput', false);
    end
end

positiveInstancesFilter = ~cellfun(@isempty, positiveInstances);
positiveInstances = positiveInstances(positiveInstancesFilter);
positiveInstances = cellfun(@cell2mat, positiveInstances, 'UniformOutput', false);

negativeInstancesFilter = ~cellfun(@isempty, negativeInstances);
negativeInstances = negativeInstances(negativeInstancesFilter);
negativeInstances = cellfun(@cell2mat, negativeInstances, 'UniformOutput', false);

positiveInstancesMat = cell2mat(positiveInstances);
negativeInstancesMat = cell2mat(negativeInstances);

%% Generate SVM
tic
numPositiveInstances  = size(positiveInstancesMat,1);
numNegativeInstances  = size(negativeInstancesMat,1);
instancesMat = [positiveInstancesMat ; negativeInstancesMat];
groupLabels = zeros(numPositiveInstances+numNegativeInstances,1);
groupLabels(1:numPositiveInstances) = 1;

scallopSVM = svmtrain(instancesMat,groupLabels,'kernel_function','linear');
objectGroup = svmclassify(scallopSVM,instancesMat);
toc

