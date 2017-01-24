function [ params, resegmentData ] = scallopLearningResegment( params, groundTruth, scallopPosition)
%SCALLOPLEARNINGRESEGMENT Performs a 2-region graphcut segmentation using
%the ground truth data as foreground seeds for graphcut.

%% Initialization
numScallops = params.numScallops;
imageWidth = params.imageSize(2);
imageHeight = params.imageSize(1);
groundTruthX = groundTruth.X;
groundTruthY = groundTruth.Y;
groundTruthRad = groundTruth.radius;
groundTruthImageName = groundTruth.ImageName;
resegmentWindowSize = params.resegmentWindowSize;
bgRadiusPercent = params.bgRadiusPercent;
resegRadiusExtnPercent = params.resegRadiusExtnPercent;
scallopMaskThicknessPercent = params.scallopMaskThicknessPercent;
crescentAngle = params.crescentAngle;
centerRadiusPercent = params.centerRadiusPercent;
horzBoundary = params.horzBoundary;
vertBoundary = params.vertBoundary;

if params.useSmoothImages
    imageFolder = params.imageFolder;
else
    imageFolder = params.imageFolderUnsmooth;
end

segmentCrescentMask = cell(numScallops,1);
segmentCenterMask = cell(numScallops,1);
resegAvailable = true(numScallops,1);
statNumbers = cell(numScallops,1);

%% Parallel thread creation
% global poolobj numPoolWorkers;
% if isempty(poolobj)
%     poolobj = parpool(numPoolWorkers);
% else
%     if poolobj.NumWorkers == 0
%         poolobj = parpool(numPoolWorkers);
%     end    
% end
% parfor_progress(numScallops);

%% Main loop
for scallopI = 1:numScallops
    fprintf('Resegmenting scallops %d ...\n', scallopI);
    
    % Current scallop information
    currX = round(groundTruthX(scallopI));
    currY = round(groundTruthY(scallopI));
    currRadius = round(groundTruthRad(scallopI));
    currImageName = groundTruthImageName{scallopI};
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
        resegAvailable(scallopI) = false;
        continue;
    end
    
    % Create FG masks
    [resegAvailable(scallopI), fgMask, scallopCircleMask, sliverMask, repScallop, ~, centerMask] ...
                                            = generateFGMask(currX, currY, cropX, cropY, ...
                                                                cropWindowWidth, cropWindowHeight, ...
                                                                currRadius, scallopPosition, groundTruth, ...
                                                                resegRadiusExtnPercent, scallopMaskThicknessPercent, ...
                                                                crescentAngle, centerRadiusPercent, imageFolder);
                                                            
   if resegAvailable(scallopI)
       % Create BG masks
       bgMask = generateBGMask(cropWindowWidth, cropWindowHeight, bgRadiusPercent, scallopCircleMask);

       % Graphcut crescent segmentation
       [tempSegmentMask, ~, ~, ~, ~]=GraphCutSeedMex(im2double(cropImage), fgMask, bgMask);
       segmentCrescentMask{scallopI} = filterBWImage(tempSegmentMask);
       
       % Graphcut center segmentation
       [tempSegmentMask, ~, ~, ~, ~]=GraphCutSeedMex(im2double(cropImage), centerMask, bgMask);
       segmentCenterMask{scallopI} = filterBWImage(tempSegmentMask);
             
       % Statistics
       statNumbers{scallopI} = computeResegStat(params, segmentCrescentMask{scallopI}, ...
                                                    segmentCenterMask{scallopI}, ...
                                                    fgMask, centerMask, bgMask, scallopCircleMask);

       % Display
       displayResegmentation(fgMask, bgMask, centerMask, segmentCrescentMask{scallopI}, segmentCenterMask{scallopI}, sliverMask, cropImage, repScallop);
   end
%    parfor_progress;
end
% parfor_progress(0);

%% Output
resegmentData.segmentCrescentMask = segmentCrescentMask;
resegmentData.segmentCenterMask = segmentCenterMask;
resegmentData.resegAvailable = resegAvailable;
resegmentData.statNumbers = statNumbers;

end

%% Function to display segmentation results
function displayResegmentation(fgMask, bgMask, centerMask, segmentCrescentMask, segmentCenterMask, sliverMask, cropImage, repScallop)    
    segmentCrescentImage = cropImage;
    segmentCenterImage = cropImage;
    fgImage = cropImage;
    bgImage = cropImage;
    centerImage = cropImage;
    scallopSliverImage = repScallop;
    
    for i=1:3
        segmentCrescentImage(:,:,i) = segmentCrescentImage(:,:,i).*uint8(segmentCrescentMask);
        segmentCenterImage(:,:,i) = segmentCenterImage(:,:,i).*uint8(segmentCenterMask);
        fgImage(:,:,i) = fgImage(:,:,i).*uint8(fgMask);
        bgImage(:,:,i) = bgImage(:,:,i).*uint8(bgMask);
        centerImage(:,:,i) = centerImage(:,:,i).*uint8(centerMask);
    end
    scallopSliverImage = scallopSliverImage.*uint8(sliverMask);
    
    numCols = 7;
    
    k=1;
    subplot(2,numCols,k); imshow(cropImage);
    subplot(2,numCols,k+numCols); imshow(repScallop);
    
    k=2;
    subplot(2,numCols,k); imshow(sliverMask);    
    subplot(2,numCols,k+numCols); imshow(scallopSliverImage);
    
    k=3;
    subplot(2,numCols,k); imshow(fgMask);
    subplot(2,numCols,k+numCols); imshow(fgImage);

    k=4;
    subplot(2,numCols,k); imshow(centerMask);
    subplot(2,numCols,k+numCols); imshow(centerImage);
    
    k=5;
    subplot(2,numCols,k); imshow(bgMask);
    subplot(2,numCols,k+numCols); imshow(bgImage);
    
    k=6;
    subplot(2,numCols,k); imshow(segmentCrescentMask);
    subplot(2,numCols,k+numCols); imshow(segmentCrescentImage);

    k=7;
    subplot(2,numCols,k); imshow(segmentCenterMask);
    subplot(2,numCols,k+numCols); imshow(segmentCenterImage);
end





