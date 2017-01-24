function [params, hogComparison] = scallopTestingHOGCompare(params, segmentData, objectHOG, scallopLearning)
%SCALLOPTESTINGHOGCOMPARE Compare HOG descriptors of learning and testing
%data

%% Initialization
numImages = params.numImages;
hogLearningAvailable = cell(numImages,1);
hogTestingAvailable = cell(numImages,1);
hogEmdDistances = cell(numImages,1);

scallopLearningParams = scallopLearning.params;
scallopPosition = scallopLearning.scallopPosition;
scallopHOG = scallopLearning.scallopHOG;
objectHOGDes = objectHOG.hogDes;
objectHOGAvailable = objectHOG.hogAvailable;
circList = segmentData.circList;

%% Parallel thread creation
global poolobj numPoolWorkers;
if isempty(poolobj)
    poolobj = parpool(numPoolWorkers);
else
    if poolobj.NumWorkers == 0
        poolobj = parpool(numPoolWorkers);
    end    
end

%% Main Loop
parfor imageI = 1:numImages
    fprintf('Processing HOG Comparison Image  %d of %d ...\n', imageI, numImages);
    numObjects = size(circList{imageI},1);
    hogLearningAvailable{imageI} = true(numObjects,1);
    hogTestingAvailable{imageI} = true(numObjects,1);
    hogEmdDistances{imageI} = cell(numObjects,1);
    
    for objI = 1:numObjects
        fprintf('Processing HOG Comparison Image %d of %d, object %d of %d ...\n', ...
                    imageI, numImages, objI, numObjects);
        
        % Object information
        currObjectX = round(segmentData.circList{imageI}(objI,1));
        currObjectY = round(segmentData.circList{imageI}(objI,2));
        
        % Learning information
        [ ~, hogLearningAvailable{imageI}(objI), hogLearningDes, ~ ] ...
            = getQuadrantHOG( scallopLearningParams, scallopPosition, ...
                                scallopHOG, currObjectY, currObjectX);
        
        % Testing information
        hogTestingDes = objectHOGDes{imageI}{objI}';
        hogTestingAvailable{imageI}(objI) = objectHOGAvailable{imageI}(objI);
        
        if hogLearningAvailable{imageI}(objI) && hogTestingAvailable{imageI}(objI)
            hogEmdDistances{imageI}{objI} = hogEmdCompute(hogTestingDes, hogLearningDes);
        end
    end   
end

%% Outputs
hogComparison.hogLearningAvailable = hogLearningAvailable;
hogComparison.hogTestingAvailable = hogTestingAvailable;
hogComparison.hogEmdDistances = hogEmdDistances;

end

%% Function to compute hog emd distances
function emdDistances = hogEmdCompute(hogTestingDes, hogLearningDes)

% Combine HOG learning features
hogLearningCombinedDes = combineHOGLearningDes(hogLearningDes);

% Testing feature vector and weights
testingF = reshape(1:length(hogTestingDes), [], 1);
testingW = reshape(double(hogTestingDes), [], 1);

% Learning feature vector and weights
learningF = reshape(1:length(hogLearningCombinedDes), [], 1);
learningW = reshape(double(hogLearningCombinedDes), [], 1);

% Emd calculation
[~, emdDistances] = emd(learningF, testingF, learningW, testingW, @gdf);

end

%% Function to compute learning histogram
function hogLearningCombinedDes = combineHOGLearningDes(hogLearningDes)
    hogLearningCombinedDes = mean(hogLearningDes);
end
