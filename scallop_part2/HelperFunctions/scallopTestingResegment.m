function [ params, resegmentData ] = scallopTestingResegment( params, fileInfo, objectList, ...
                                                              learningParams,  groundTruth, scallopPosition)
%SCALLOPLEARNINGRESEGMENT Performs a 2-region graphcut segmentation using
%the ground truth data as foreground seeds for graphcut.

%% Initialization
params.numObjects = size(objectList,1);
params.resegmentWindowSize = learningParams.resegmentWindowSize;
params.bgRadiusPercent = learningParams.bgRadiusPercent;
params.resegRadiusExtnPercent = learningParams.resegRadiusExtnPercent;
params.horzBoundary = learningParams.horzBoundary;
params.vertBoundary = learningParams.vertBoundary;
params.useSmoothImages = learningParams.useSmoothImages;
params.scallopMaskThickness = learningParams.scallopMaskThickness;
params.crescentAngle = learningParams.crescentAngle;

numObjects = params.numObjects;
imageWidth = params.imageSize(2);
imageHeight = params.imageSize(1);
resegmentWindowSize = params.resegmentWindowSize;
bgRadiusPercent = params.bgRadiusPercent;
resegRadiusExtnPercent = params.resegRadiusExtnPercent;
scallopMaskThickness = params.scallopMaskThickness;
crescentAngle = params.crescentAngle;
horzBoundary = params.horzBoundary;
vertBoundary = params.vertBoundary;
imageName = fileInfo.filename;

if params.useSmoothImages
    imageFolder = params.imageFolder;
else
    imageFolder = params.imageFolderUnsmooth;
end

segmentMask = cell(numObjects,1);
resegAvailable = true(numObjects,1);
statNumbers = cell(numObjects,1);
scallopVerdict = false(numObjects,1);

%% Parallel thread creation
global poolobj numPoolWorkers;
if isempty(poolobj)
    poolobj = parpool(numPoolWorkers);
else
    if poolobj.NumWorkers == 0
        poolobj = parpool(numPoolWorkers);
    end    
end
parfor_progress(numObjects);

%% Main loop
parfor objectI = 1:numObjects
    fprintf('Resegmenting objects %d ...\n', objectI);
    
    % Current object information
    currObject = objectList(objectI,:);
    currX = round(currObject(1));
    currY = round(currObject(2));
    currRadius = round(currObject(3));
    currImageName = imageName{currObject(6)};
    filename = sprintf('%s/%s', imageFolder, currImageName);
    currImage = imread(filename);
    
    % Compute BB and crop image
    bb = computeBB(currX, currY, resegmentWindowSize, resegmentWindowSize, imageWidth, imageHeight);
    cropImage = imcrop(currImage, bb);
    cropX = currX-bb(1)+1;
    cropY = currY-bb(2)+1;
    cropWindowWidth = size(cropImage, 2);
    cropWindowHeight = size(cropImage, 1);
    
    % Skipping boundary scallops
    if isBoundaryScallop(currX, currY, horzBoundary, vertBoundary, imageWidth, imageHeight)
        resegAvailable(objectI) = false;
        continue;
    end
    
    % Create FG masks
    [resegAvailable(objectI), fgMask, objectCircleMask, ~, ~] = generateFGMask(currX, currY, cropX, cropY, cropWindowWidth, cropWindowHeight, ...
                                                                                        currRadius, scallopPosition, groundTruth, ...
                                                                                        resegRadiusExtnPercent, scallopMaskThickness, ...
                                                                                        crescentAngle, imageFolder);
    
   if resegAvailable(objectI)
       % Create BG masks
       bgMask = generateBGMask(cropWindowWidth, cropWindowHeight, bgRadiusPercent, fgMask);

       % Graphcut segmentation
       [tempSegmentMask, ~, ~, ~, ~]=GraphCutSeedMex(im2double(cropImage), fgMask, bgMask);
       segmentMask{objectI} = filterBW(tempSegmentMask);
       
       % Statistics
       [scallopVerdict(objectI), statNumbers{objectI}] = computeResegStat(params, segmentMask{objectI}, ...
                                                                                fgMask, bgMask, objectCircleMask);

       % Display
       % displayResegmentation(fgMask, bgMask, tempSegmentMask, objectCircleMask, cropImage);
   end
   parfor_progress;
end
parfor_progress(0);

%% Output
resegmentData.segmentMask = segmentMask;
resegmentData.resegAvailable = resegAvailable;
resegmentData.scallopVerdict = scallopVerdict;
resegmentData.statNumbers = statNumbers;

end

%% Function to display segmentation results
function displayResegmentation(fgMask, bgMask, segmentMask, objectCircleMask, cropImage)    
    segmentImage = cropImage;
    fgImage = cropImage;
    bgImage = cropImage;
    scallopCircleImage = cropImage;
    for i=1:3
        segmentImage(:,:,i) = segmentImage(:,:,i).*uint8(segmentMask);
        fgImage(:,:,i) = fgImage(:,:,i).*uint8(fgMask);
        bgImage(:,:,i) = bgImage(:,:,i).*uint8(bgMask);
        scallopCircleImage(:,:,i) = scallopCircleImage(:,:,i).*uint8(objectCircleMask);
    end
    
    subplot(241); imshow(fgMask);
    subplot(242); imshow(bgMask);
    subplot(243); imshow(segmentMask);
    subplot(244); imshow(objectCircleMask);
    subplot(245); imshow(fgImage);
    subplot(246); imshow(bgImage);
    subplot(247); imshow(segmentImage);
    subplot(248); imshow(scallopCircleImage);
end





