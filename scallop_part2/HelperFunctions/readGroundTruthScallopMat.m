function [ params, groundTruth, fileInfo ] = readGroundTruthScallopMat( params, groundTruthFile, imageFolder, numImages, imageSize )
%readGroundTruthScallopMat Reads groundtruth in mat format. This is used to
%read from the user labeled groundtruth scallop instances

%% Read list of files
fileList =  dir(imageFolder);
fileList = fileList(3:end);
if numImages == Inf
    numImages = length(fileList);
end

%% Load groundTruth
inGroundTruth = goodLoad(groundTruthFile);

%% Gathering file information
imagesWithScallop = ~cellfun(@isempty, inGroundTruth.objRect);
numImagesWithScallop = sum(imagesWithScallop(:));
fileInfo.filename = {fileList.name}';
fileInfo.foldername = imageFolder;

%% Gathering scallop information
groundTruthImageName = fileInfo.filename(imagesWithScallop);
groundTruthRect = inGroundTruth.objRect(imagesWithScallop);
numImageScallops = cellfun(@size, groundTruthRect, num2cell(ones(numImagesWithScallop,1)));
numScallops = sum(numImageScallops(:));
groundTruth.X = zeros(numScallops,1);
groundTruth.Y = zeros(numScallops,1);
groundTruth.radius = zeros(numScallops,1);
groundTruth.ImageName = cell(numScallops,1);
ind = 1;

for imageI = 1:numImagesWithScallop
    for scallopI = 1:numImageScallops(imageI)
        groundTruth.X(ind) = groundTruthRect{imageI}(scallopI,1);
        groundTruth.Y(ind) = groundTruthRect{imageI}(scallopI,2);
        groundTruth.radius(ind) = groundTruthRect{imageI}(scallopI,3);
        groundTruth.ImageName{ind} = groundTruthImageName{imageI};
        ind = ind + 1;
    end
end

%% Image size and magnification
tempImage = imread(fullfile(fileInfo.foldername, fileInfo.filename{1}));
tempImageSize = size(tempImage);
tempImageSize = tempImageSize(1:2);
dimRatios = imageSize./tempImageSize;

if dimRatios(1) ~= dimRatios(2)
    error('Image dimension ratios different in X and Y direction\n');
end
resizeFactor = dimRatios(1);

groundTruth.X = groundTruth.X.*resizeFactor;
groundTruth.Y = groundTruth.Y.*resizeFactor;
groundTruth.radius = groundTruth.radius.*resizeFactor;

%% Imagewise groundtruth
imageWise(numImages) = struct;
for imageI = 1:numImages
    ind = find(cellfun(@strcmp, groundTruth.ImageName, repmat(fileInfo.filename(imageI), numScallops,1)));
    numCurrScallops = length(ind);
    imageWise(imageI).numScallops = numCurrScallops;
    imageWise(imageI).numBoundaryScallops = 0;
    imageWise(imageI).loc = zeros( numCurrScallops, 3 );
    imageWise(imageI).boundaryScallop = false( numCurrScallops, 1);
    
    for scallopI = 1:numCurrScallops
        imageWise(imageI).loc(scallopI,1) = groundTruth.X(ind(scallopI));
        imageWise(imageI).loc(scallopI,2) = groundTruth.Y(ind(scallopI));
        imageWise(imageI).loc(scallopI,3) = groundTruth.radius(ind(scallopI));
    
        currScallopLoc = imageWise(imageI).loc(scallopI,:);
        
        % Checking if boundary scallop
        if (currScallopLoc(1) <= round(params.boundaryCropPercent*imageSize(2)) || ...
                currScallopLoc(1) >= imageSize(2) - round(params.boundaryCropPercent*imageSize(2)) || ...
                currScallopLoc(2) <= round(params.boundaryCropPercent*imageSize(1)) || ...
                currScallopLoc(2) >= imageSize(1) - round(params.boundaryCropPercent*imageSize(1)))
            imageWise(imageI).boundaryScallop(scallopI) = true;
            imageWise(imageI).numBoundaryScallops = imageWise(imageI).numBoundaryScallops + 1;
        end
    end
end
groundTruth.imageWise = imageWise;

%% Updating params
params.numImages = numImages;
params.imageSize = imageSize;
params.numScallops = numScallops;
params.resizeFactor = resizeFactor;
